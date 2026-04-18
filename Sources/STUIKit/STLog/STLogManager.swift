//
//  STLogManager.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2018/10/10.
//

import Foundation

protocol STLogHandler: AnyObject {
    func handle(record: STLogRecord)
    func flush()
}

final class STConsoleLogHandler: STLogHandler {
    func handle(record: STLogRecord) {
#if DEBUG
        print(record.formatted(multiline: true))
#endif
    }

    func flush() {}
}

final class STCloudLogHandler: STLogHandler {
    private let queue = DispatchQueue(label: "com.stbase.log.cloud", qos: .utility)
    private var buffer: [STLogRecord] = []
    private var isSending = false

    func handle(record: STLogRecord) {
        self.queue.async {
            self.buffer.append(record)
            self.flushIfNeeded(force: false)
        }
    }

    func flush() {
        self.queue.async {
            self.flushIfNeeded(force: true)
        }
    }

    private func flushIfNeeded(force: Bool) {
        guard let transport = STLogManager.configuration.cloudTransport else { return }
        guard !self.isSending else { return }
        guard force || self.buffer.count >= STLogManager.configuration.cloudBatchSize else { return }
        let batch = self.buffer
        self.buffer.removeAll()
        self.isSending = true
        transport.send(logs: batch) { result in
            self.queue.async {
                if case .failure = result {
                    self.buffer.insert(contentsOf: batch, at: 0)
                    let maxCount = STLogManager.configuration.maxCloudBufferCount
                    if self.buffer.count > maxCount {
                        self.buffer.removeFirst(self.buffer.count - maxCount)
                    }
                }
                self.isSending = false
                if self.buffer.count >= STLogManager.configuration.cloudBatchSize {
                    self.flushIfNeeded(force: true)
                }
            }
        }
    }
}

public final class STLogManager {
    public struct Configuration {
        public var minimumLevel: STLogLevel
        /// 控制 `STLog(...)` 是否默认写入本地持久化文件。
        /// `STPersistentLog(...)` 始终会落盘，不受此开关影响。
        public var persistDefaultLogs: Bool
        public var maxFileSize: Int
        public var maxArchivedFiles: Int
        public var retainedLogCountForDisplay: Int
        public var cloudTransport: STLogCloudTransport?
        public var cloudBatchSize: Int
        /// 云端上传失败时 buffer 的最大条数，超出后丢弃最旧的记录，防止持续失败时内存无限增长。
        public var maxCloudBufferCount: Int

        public init(
            minimumLevel: STLogLevel = .debug,
            persistDefaultLogs: Bool = false,
            maxFileSize: Int = 2 * 1024 * 1024,
            maxArchivedFiles: Int = 7,
            retainedLogCountForDisplay: Int = 2000,
            cloudTransport: STLogCloudTransport? = nil,
            cloudBatchSize: Int = 20,
            maxCloudBufferCount: Int = 500
        ) {
            self.minimumLevel = minimumLevel
            self.persistDefaultLogs = persistDefaultLogs
            self.maxFileSize = maxFileSize
            self.maxArchivedFiles = maxArchivedFiles
            self.retainedLogCountForDisplay = retainedLogCountForDisplay
            self.cloudTransport = cloudTransport
            self.cloudBatchSize = max(1, cloudBatchSize)
            self.maxCloudBufferCount = max(cloudBatchSize, maxCloudBufferCount)
        }
    }

    public static let didAppendRecordNotification = "com.notification.didAppendStructuredLog"

    static let shared = STLogManager()

    private static var currentConfiguration = Configuration()
    private let queue = DispatchQueue(label: "com.stbase.log.manager", qos: .utility)
    private var handlers: [STLogHandler] = []
    private var memoryBuffer: [STLogRecord] = []

    private init() {
        self.rebuildHandlers()
    }

    public static var configuration: Configuration {
        self.currentConfiguration
    }

    /// 在应用启动阶段配置日志系统。
    /// 建议在应用入口尽早调用一次。
    ///
    /// 本地持久化示例：
    /// ```swift
    /// STLogManager.bootstrap(.init(
    ///     minimumLevel: .debug,
    ///     persistDefaultLogs: true,
    ///     maxFileSize: 2 * 1024 * 1024,
    ///     maxArchivedFiles: 5,
    ///     retainedLogCountForDisplay: 1500
    /// ))
    /// ```
    ///
    /// 云端上传示例：
    /// ```swift
    /// let transport = STURLSessionLogCloudTransport(
    ///     endpoint: URL(string: "https://example.com/api/logs")!,
    ///     headers: ["Authorization": "Bearer <token>"]
    /// )
    ///
    /// STLogManager.bootstrap(.init(
    ///     minimumLevel: .info,
    ///     persistDefaultLogs: true,
    ///     cloudTransport: transport,
    ///     cloudBatchSize: 20
    /// ))
    /// ```
    public class func bootstrap(_ configuration: Configuration) {
        self.currentConfiguration = configuration
        self.shared.queue.async {
            self.shared.rebuildHandlers()
        }
    }

    /// 动态替换云端日志传输器。
    /// 可在登录后补充鉴权头或按环境切换上传端点。
    ///
    /// 示例：
    /// ```swift
    /// let transport = STURLSessionLogCloudTransport(
    ///     endpoint: URL(string: "https://example.com/api/logs")!,
    ///     headers: ["Authorization": "Bearer <token>"]
    /// )
    /// STLogManager.setCloudTransport(transport)
    /// ```
    public class func setCloudTransport(_ transport: STLogCloudTransport?) {
        self.currentConfiguration.cloudTransport = transport
        self.shared.queue.async {
            self.shared.rebuildHandlers()
        }
    }

    /// 创建一个带默认 label / metadata 的 logger。
    public class func makeLogger(label: String, metadata: STLogger.Metadata = [:]) -> STLogger {
        STLogger(label: label, metadata: metadata)
    }

    func log(_ record: STLogRecord) {
        guard record.level >= Self.currentConfiguration.minimumLevel else { return }
        self.queue.async {
            self.memoryBuffer.append(record)
            if self.memoryBuffer.count > Self.currentConfiguration.retainedLogCountForDisplay {
                self.memoryBuffer.removeFirst(self.memoryBuffer.count - Self.currentConfiguration.retainedLogCountForDisplay)
            }

            self.handlers.forEach { $0.handle(record: record) }

            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: NSNotification.Name(rawValue: Self.didAppendRecordNotification),
                    object: record
                )
            }
        }
    }

    public class func flush() {
        self.shared.queue.async {
            self.shared.handlers.forEach { $0.flush() }
        }
    }

    /// 当前正在写入的活动日志文件路径。
    public class func logFilePath() -> String {
        STLogFileWriter.shared.activeFilePath
    }

    /// 当前文件和归档文件列表，按读取优先级返回。
    public class func allLogFilePaths() -> [String] {
        STLogFileWriter.shared.allLogFilePaths()
    }

    /// 清空内存和本地持久化日志。
    public class func clearAllLogs() {
        self.shared.queue.sync {
            self.shared.memoryBuffer.removeAll()
            STLogFileWriter.shared.clearAllLogs()
        }
    }

    public class func recentRecords(limit: Int) -> [STLogRecord] {
        let buffer = self.shared.queue.sync { self.shared.memoryBuffer.suffix(limit) }
        if buffer.count >= limit {
            return Array(Array(buffer).reversed())
        }
        return STLogFileWriter.shared.fetchRecords(skip: 0, limit: limit)
    }

    public class func records(page: Int, pageSize: Int, levels: Set<STLogLevel>? = nil, searchText: String? = nil) -> [STLogRecord] {
        let normalizedLevels = levels ?? Set(STLogLevel.allCases)
        let normalizedSearch = searchText?.trimmingCharacters(in: .whitespacesAndNewlines)
        let shouldSearch = !(normalizedSearch?.isEmpty ?? true) || normalizedLevels.count < STLogLevel.allCases.count
        if shouldSearch {
            return STLogFileWriter.shared.searchRecords(searchText: normalizedSearch, levels: normalizedLevels, limit: pageSize, offset: page * pageSize)
        }
        // 优先从 memoryBuffer 返回（含非持久化日志），超出内存范围再回落到磁盘
        let skip = page * pageSize
        let memorySlice: [STLogRecord] = self.shared.queue.sync {
            let all = Array(self.shared.memoryBuffer.reversed())
            guard skip < all.count else { return [] }
            return Array(all.dropFirst(skip).prefix(pageSize))
        }
        guard memorySlice.isEmpty else { return memorySlice }
        return STLogFileWriter.shared.fetchRecords(skip: skip, limit: pageSize)
    }

    public class func hasMoreRecords(page: Int, pageSize: Int, levels: Set<STLogLevel>? = nil, searchText: String? = nil) -> Bool {
        !self.records(page: page + 1, pageSize: 1, levels: levels, searchText: searchText).isEmpty
    }

    private func rebuildHandlers() {
        STLogFileWriter.shared.updateConfiguration(Self.currentConfiguration)
        let fileHandler = STLogFileWriter.shared
        let consoleHandler = STConsoleLogHandler()
        var newHandlers: [STLogHandler] = [consoleHandler, fileHandler]
        if Self.currentConfiguration.cloudTransport != nil {
            newHandlers.append(STCloudLogHandler())
        }
        self.handlers = newHandlers
    }
}
