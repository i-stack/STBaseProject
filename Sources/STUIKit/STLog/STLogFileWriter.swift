//
//  STLogFileWriter.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2018/10/10.
//

import Foundation

final class STLogFileWriter: STLogHandler {

    static let shared = STLogFileWriter()

    private let directoryName = "STLogs"
    private let activeFileName = "current.jsonl"
    private var config = STLogManager.configuration
    private let queue = DispatchQueue(label: "com.stbaseproject.logWriter", qos: .utility)

    private init() {}

    func updateConfiguration(_ configuration: STLogManager.Configuration) {
        self.queue.async {
            self.config = configuration
            self.cleanupArchivesIfNeeded()
        }
    }

    func handle(record: STLogRecord) {
        guard record.persistent else { return }
        self.queue.async {
            self.write(record: record)
        }
    }

    func flush() {
        self.queue.sync {}
    }

    func clearAllLogs() {
        self.queue.sync {
            STFileSystem.clearDirectory(at: logDirectory.path)
            STFileSystem.createFileIfNeeded(in: logDirectory.path, fileName: activeFileName)
        }
    }

    func allLogFilePaths() -> [String] {
        self.queue.sync {
            self.orderedLogFileURLs().map(\.path)
        }
    }

    func fetchRecords(skip: Int, limit: Int) -> [STLogRecord] {
        guard limit > 0 else { return [] }
        return self.queue.sync {
            self.enumerateNewestRecords(skip: skip, limit: limit, levels: Set(STLogLevel.allCases), searchText: nil)
        }
    }

    func searchRecords(searchText: String?, levels: Set<STLogLevel>, limit: Int, offset: Int) -> [STLogRecord] {
        guard limit > 0 else { return [] }
        return self.queue.sync {
            self.enumerateNewestRecords(skip: offset, limit: limit, levels: levels, searchText: searchText)
        }
    }

    private func write(record: STLogRecord) {
        guard let line = record.jsonLine(using: encoder),
              let data = line.data(using: .utf8) else {
            return
        }
        self.rotateIfNeeded(extraBytes: data.count)
        let path = self.activeFileURL.path
        if STFileSystem.fileStatus(at: path).exists {
            STFileSystem.appendContent(line, toFileAt: path)
        } else {
            STFileSystem.write(line, to: self.activeFileURL)
        }
    }

    private func rotateIfNeeded(extraBytes: Int) {
        let currentPath = self.activeFileURL.path
        let currentSize = Int(STFileSystem.fileSize(atPath: currentPath))
        guard currentSize + extraBytes > self.config.maxFileSize else { return }
        let archiveName = "log-\(Date().formatted("yyyyMMdd-HHmmss-SSS")).jsonl"
        let archivePath = self.logDirectory.appendingPathComponent(archiveName).path
        STFileSystem.moveItem(at: currentPath, to: archivePath)
        STFileSystem.createFileIfNeeded(in: logDirectory.path, fileName: self.activeFileName)
        self.cleanupArchivesIfNeeded()
    }

    private func cleanupArchivesIfNeeded() {
        let archives = self.archivedLogURLs()
        guard archives.count > self.config.maxArchivedFiles else { return }
        let staleFiles = archives.dropFirst(self.config.maxArchivedFiles)
        staleFiles.forEach { STFileSystem.removeItem(at: $0.path) }
    }

    private func orderedLogFileURLs() -> [URL] {
        [self.activeFileURL] + self.archivedLogURLs()
    }

    private func archivedLogURLs() -> [URL] {
        let urls = STFileSystem.fullPathsOfDirectory(at: logDirectory.path)
            .filter { $0.hasSuffix(".jsonl") && !$0.hasSuffix(activeFileName) }
            .map { URL(fileURLWithPath: $0) }
        return urls.sorted {
            let lhs = STFileSystem.modificationDate(atPath: $0.path) ?? .distantPast
            let rhs = STFileSystem.modificationDate(atPath: $1.path) ?? .distantPast
            return lhs > rhs
        }
    }

    private func enumerateNewestRecords(skip: Int, limit: Int, levels: Set<STLogLevel>,searchText: String?) -> [STLogRecord] {
        let normalizedSearch = searchText?.lowercased()
        var matched: [STLogRecord] = []
        var skipped = 0
        outerLoop: for fileURL in orderedLogFileURLs() {
            guard let content = STFileSystem.readString(from: fileURL), !content.isEmpty else { continue }
            let lines = content.split(whereSeparator: \.isNewline)
            for line in lines.reversed() {
                guard let record = STLogRecord.decode(from: String(line), using: self.decoder) else { continue }
                guard levels.contains(record.level) else { continue }
                if let normalizedSearch, !normalizedSearch.isEmpty, !record.searchableText.contains(normalizedSearch) {
                    continue
                }
                if skipped < skip {
                    skipped += 1
                    continue
                }
                matched.append(record)
                if matched.count >= limit {
                    break outerLoop
                }
            }
        }
        return matched
    }
    
    var activeFilePath: String {
        self.activeFileURL.path
    }
    
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }()
    
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
    
    private var logDirectory: URL {
        let root = STFileSystem.applicationSupportDirectoryPath.isEmpty ? STFileSystem.cachesDirectoryPath : STFileSystem.applicationSupportDirectoryPath
        let path = URL(fileURLWithPath: root).appendingPathComponent(directoryName, isDirectory: true)
        STFileSystem.createDirectoryIfNeeded(at: path.path)
        return path
    }

    private var activeFileURL: URL {
        let url = logDirectory.appendingPathComponent(activeFileName)
        if !STFileSystem.fileStatus(at: url.path).exists {
            STFileSystem.createFileIfNeeded(in: logDirectory.path, fileName: activeFileName)
        }
        return url
    }
}
