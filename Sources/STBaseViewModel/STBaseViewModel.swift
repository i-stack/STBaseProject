//
//  STBaseViewModel.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2018/3/14.
//

import Combine
import CryptoKit
import Foundation

// MARK: - 错误类型枚举
public enum STBaseError: LocalizedError, Equatable {
    case success
    case networkError(String)
    case dataError(String)
    case validationError(String)
    case businessError(code: Int, message: String)
    case origin(error: Error)
    case originErrorDescription(reason: String)
    case unknown

    public var errorDescription: String? {
        switch self {
        case .success:
            return "success"
        case .networkError(let message):
            return "网络错误: \(message)"
        case .dataError(let message):
            return "数据错误: \(message)"
        case .validationError(let message):
            return "验证错误: \(message)"
        case .businessError(_, let message):
            return message
        case .origin(let error):
            return error.localizedDescription
        case .originErrorDescription(let reason):
            return reason
        case .unknown:
            return "未知错误"
        }
    }

    public var errorCode: Int {
        switch self {
        case .success:
            return 0
        case .networkError:
            return -1001
        case .dataError:
            return -1002
        case .validationError:
            return -1003
        case .businessError(let code, _):
            return code
        case .origin:
            return -1004
        case .originErrorDescription:
            return -1005
        case .unknown:
            return -9999
        }
    }

    public static func == (lhs: STBaseError, rhs: STBaseError) -> Bool {
        switch (lhs, rhs) {
        case (.success, .success),
             (.unknown, .unknown):
            return true
        case (.networkError(let l), .networkError(let r)),
             (.dataError(let l), .dataError(let r)),
             (.validationError(let l), .validationError(let r)),
             (.originErrorDescription(let l), .originErrorDescription(let r)):
            return l == r
        case (.businessError(let lc, let lm), .businessError(let rc, let rm)):
            return lc == rc && lm == rm
        case (.origin(let l), .origin(let r)):
            return (l as NSError) == (r as NSError)
        default:
            return false
        }
    }
}

// MARK: - 加载状态枚举
public enum STLoadingState: Equatable {
    case idle
    case loading
    case loaded
    case failed(STBaseError)
    case empty
}

// MARK: - 刷新状态枚举
public enum STRefreshState: Equatable {
    case idle
    case refreshing
    case noMoreData
    case failed(STBaseError)
}

// MARK: - 缓存配置
public struct STCacheConfig {
    public var enableCache: Bool
    public var cacheKey: String
    public var cacheExpiration: TimeInterval
    public var cachePolicy: STCachePolicy

    public enum STCachePolicy: Equatable {
        case memory
        case disk
        case both
    }

    public init(enableCache: Bool = false,
                cacheKey: String = "",
                cacheExpiration: TimeInterval = 300,
                cachePolicy: STCachePolicy = .memory) {
        self.enableCache = enableCache
        self.cacheKey = cacheKey
        self.cacheExpiration = cacheExpiration
        self.cachePolicy = cachePolicy
    }
}

open class STBaseViewModel: NSObject {

    public let loadingState = CurrentValueSubject<STLoadingState, Never>(.idle)
    public let refreshState = CurrentValueSubject<STRefreshState, Never>(.idle)
    public let errorPublisher = PassthroughSubject<STBaseError, Never>()
    public let dataUpdated = PassthroughSubject<Void, Never>()
    public var requestConfig = STRequestConfig()
    public var cacheConfig = STCacheConfig()
    public var httpSession: STHTTPSessionProviding = STHTTPSession.shared
    public var requestHeaders = STRequestHeaders()
    public var jsonDecoder = JSONDecoder()
    public var jsonEncoder = JSONEncoder()

    /// 订阅持有集合。对外保留公开只读可见性以兼容既有消费者；
    /// 内部存储一律走带锁的 `st_store(in:)` 扩展或 `st_storeCancellable`，请勿直接 `store(in:)` 以规避并发风险。
    public private(set) var cancellables = Set<AnyCancellable>()
    private let cache = NSCache<NSString, STMemoryCacheEntry>()
    private let stateLock = NSLock()
    /// 上传/下载等一次性订阅的注册表：以 UUID 为键、加锁存储 AnyCancellable。
    /// 回调仅捕获 UUID（不捕获 token/holder 本身），完成时按 UUID 删除，避免自持有环与同步竞态。
    private let cancellableRegistry = STCancellableRegistry()
    private var inflightRequests = [STDataRequest]()
    private var activeLoadingRequestCount = 0
    private var pendingLoadingFailure: STBaseError?

    deinit {
        #if DEBUG
        STLog("[STBaseViewModel] deinit: \(String(describing: type(of: self)))", level: .debug)
        #endif
    }

    override public init() {
        super.init()
        self.st_setupBindings()
    }

    /// 依赖注入构造器：用于测试或自定义 HTTP 会话替换默认单例。
    public convenience init(httpSession: STHTTPSessionProviding) {
        self.init()
        self.httpSession = httpSession
    }

    private func st_setupBindings() {
        self.loadingState
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.st_handleLoadingStateChange(state)
            }
            .st_store(in: self)

        self.refreshState
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.st_handleRefreshStateChange(state)
            }
            .st_store(in: self)
    }

    private func st_handleLoadingStateChange(_ state: STLoadingState) {
        switch state {
        case .loading:
            self.st_onLoading()
        case .loaded:
            self.st_onLoaded()
        case .failed(let error):
            self.st_onFailed(error)
        case .empty:
            self.st_onEmpty()
        case .idle:
            break
        }
    }

    private func st_handleRefreshStateChange(_ state: STRefreshState) {
        switch state {
        case .refreshing:
            self.st_onRefreshing()
        case .noMoreData:
            self.st_onNoMoreData()
        case .failed(let error):
            self.st_onRefreshFailed(error)
        case .idle:
            break
        }
    }

    // MARK: - 可重写的方法
    open func st_onLoading() {}
    open func st_onLoaded() {}
    open func st_onFailed(_ error: STBaseError) {
        self.errorPublisher.send(error)
    }
    open func st_onEmpty() {}
    open func st_onRefreshing() {}
    open func st_onNoMoreData() {}
    open func st_onRefreshFailed(_ error: STBaseError) {
        self.errorPublisher.send(error)
    }

    // MARK: - 网络请求核心方法
    public func st_requestPublisher<T: Codable>(url: String, method: STHTTPMethod = .get, parameters: [String: Any]? = nil, encodingType: STParameterEncoder.EncodingType = .json, responseType: T.Type) -> AnyPublisher<T, STBaseError> {
        return self.st_buildRequestPublisher(responseType: responseType) { [weak self] in
            guard let self = self else {
                return Just(STHTTPResponse(data: nil, response: nil, error: STBaseError.unknown)).eraseToAnyPublisher()
            }
            return self.st_dispatchRequestPublisher(url: url, method: method, parameters: parameters, encodingType: encodingType)
        }
    }

    open func st_dispatchRequestPublisher(url: String, method: STHTTPMethod, parameters: [String: Any]?, encodingType: STParameterEncoder.EncodingType) -> AnyPublisher<STHTTPResponse, Never> {
        let request = self.httpSession.request(url, method: method, parameters: parameters, encoding: encodingType, headers: self.requestHeaders, interceptor: nil, requestConfig: self.requestConfig)
        return self.st_responsePublisher(for: request)
    }

    open func st_dispatchRequestPublisher(_ request: URLRequest) -> AnyPublisher<STHTTPResponse, Never> {
        guard let httpSession = self.httpSession as? STHTTPURLRequestSessionProviding else {
            return Just(STHTTPResponse(
                data: nil,
                response: nil,
                error: STBaseError.originErrorDescription(reason: "当前 HTTP 会话不支持 URLRequest 请求")
            )).eraseToAnyPublisher()
        }
        let dataRequest = httpSession.request(request, interceptor: nil, requestConfig: self.requestConfig)
        return self.st_responsePublisher(for: dataRequest)
    }

    private func st_responsePublisher(for request: STDataRequest) -> AnyPublisher<STHTTPResponse, Never> {
        self.st_trackInflight(request)
        return request.responsePublisher
            .handleEvents(
                receiveCompletion: { [weak self] _ in
                    self?.st_untrackInflight(request)
                },
                receiveCancel: { [weak self] in
                    request.cancel()
                    self?.st_untrackInflight(request)
                }
            )
            .eraseToAnyPublisher()
    }

    public func st_getPublisher<T: Codable>(url: String, parameters: [String: Any]? = nil, responseType: T.Type) -> AnyPublisher<T, STBaseError> {
        self.st_requestPublisher(url: url, method: .get, parameters: parameters, responseType: responseType)
    }

    public func st_postPublisher<T: Codable>(url: String, parameters: [String: Any]? = nil, responseType: T.Type) -> AnyPublisher<T, STBaseError> {
        self.st_requestPublisher(url: url, method: .post, parameters: parameters, responseType: responseType)
    }

    public func st_putPublisher<T: Codable>(url: String, parameters: [String: Any]? = nil, responseType: T.Type) -> AnyPublisher<T, STBaseError> {
        self.st_requestPublisher(url: url, method: .put, parameters: parameters, responseType: responseType)
    }

    public func st_deletePublisher<T: Codable>(url: String, parameters: [String: Any]? = nil, responseType: T.Type) -> AnyPublisher<T, STBaseError> {
        self.st_requestPublisher(url: url, method: .delete, parameters: parameters, responseType: responseType)
    }

    public func st_requestPublisher<T: Codable>(_ request: URLRequest, responseType: T.Type) -> AnyPublisher<T, STBaseError> {
        guard request.url != nil else {
            return Fail(error: STBaseError.dataError("无效的 URL")).eraseToAnyPublisher()
        }
        return self.st_buildRequestPublisher(responseType: responseType) { [weak self] in
            guard let self = self else {
                return Just(STHTTPResponse(data: nil, response: nil, error: STBaseError.unknown)).eraseToAnyPublisher()
            }
            return self.st_dispatchRequestPublisher(request)
        }
    }

    /// 统一封装请求链：订阅时按需触发 loading 计数 -> 解析响应 -> 分发终态（loaded/failed/cancel）。
    /// 两个 `st_requestPublisher` 重载共享此实现，避免重复约 50 行的 Deferred 体。
    /// - Parameters:
    ///   - responseType: 目标解码类型。
    ///   - responsePublisherFactory: 惰性构造底层 `STHTTPResponse` 发布者（每次订阅才调用，确保 inflight 跟踪时序正确）。
    private func st_buildRequestPublisher<T: Codable>(
        responseType: T.Type,
        responsePublisherFactory: @escaping () -> AnyPublisher<STHTTPResponse, Never>
    ) -> AnyPublisher<T, STBaseError> {
        return Deferred { [weak self] () -> AnyPublisher<T, STBaseError> in
            guard let self = self else {
                return Fail(error: STBaseError.unknown).eraseToAnyPublisher()
            }
            let shouldShowLoading = self.requestConfig.showLoading
            if shouldShowLoading {
                self.st_beginLoadingRequest()
            }
            return responsePublisherFactory()
                .tryMap { [weak self] response -> T in
                    guard let self = self else {
                        throw STBaseError.unknown
                    }
                    let result = self.st_resultFromHTTPResponse(response, responseType: responseType)
                    switch result {
                    case .success(let value):
                        return value
                    case .failure(let error):
                        throw error
                    }
                }
                .mapError { error -> STBaseError in
                    if let baseError = error as? STBaseError {
                        return baseError
                    }
                    return STBaseError.origin(error: error)
                }
                .handleEvents(
                    receiveOutput: { [weak self] _ in
                        self?.dataUpdated.send()
                    },
                    receiveCompletion: { [weak self] completion in
                        guard shouldShowLoading else { return }
                        switch completion {
                        case .finished:
                            self?.st_finishLoadingRequest(.loaded)
                        case .failure(let error):
                            self?.st_finishLoadingRequest(.failed(error))
                        }
                    },
                    receiveCancel: { [weak self] in
                        guard shouldShowLoading else { return }
                        self?.st_cancelLoadingRequest()
                    }
                )
                .eraseToAnyPublisher()
        }
        .eraseToAnyPublisher()
    }

    // MARK: - 参数提取（用于 URLRequest）
    private func st_extractParameters(from request: URLRequest) -> [String: Any]? {
        if let httpMethod = request.httpMethod, httpMethod.uppercased() == "GET" {
            return self.st_extractQueryParameters(from: request.url)
        }
        if let httpBody = request.httpBody {
            return self.st_extractBodyParameters(from: httpBody)
        }
        return nil
    }

    private func st_extractQueryParameters(from url: URL?) -> [String: Any]? {
        guard let url = url,
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            return nil
        }
        var parameters: [String: Any] = [:]
        for item in queryItems {
            parameters[item.name] = item.value ?? ""
        }
        return parameters.isEmpty ? nil : parameters
    }

    private func st_extractBodyParameters(from data: Data) -> [String: Any]? {
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            return json
        }
        guard let string = String(data: data, encoding: .utf8) else {
            return nil
        }
        return self.st_parseFormData(string)
    }

    private func st_parseFormData(_ formString: String) -> [String: Any]? {
        let pairs = formString.components(separatedBy: "&")
        var parameters: [String: Any] = [:]
        for pair in pairs {
            let components = pair.components(separatedBy: "=")
            if components.count == 2 {
                let rawKey = components[0].replacingOccurrences(of: "+", with: " ")
                let rawValue = components[1].replacingOccurrences(of: "+", with: " ")
                let key = rawKey.removingPercentEncoding ?? rawKey
                let value = rawValue.removingPercentEncoding ?? rawValue
                parameters[key] = value
            }
        }
        return parameters.isEmpty ? nil : parameters
    }

    // MARK: - 响应处理
    private func st_decodeResponse<T: Codable>(_ httpResponse: STHTTPResponse, responseType: T.Type) -> Result<T, STBaseError> {
        guard let data = httpResponse.data, !data.isEmpty else {
            return .failure(.dataError("响应数据为空"))
        }
        do {
            return .success(try self.jsonDecoder.decode(responseType, from: data))
        } catch DecodingError.keyNotFound(let key, let context) {
            let message = "JSON解析失败：缺少必需的字段 '\(key.stringValue)'，路径：\(context.codingPath.map { $0.stringValue }.joined(separator: "."))"
            self.st_logDecodeError("keyNotFound", message: message, data: data)
            return .failure(.dataError(message))
        } catch DecodingError.valueNotFound(let value, let context) {
            let message = "JSON解析失败：字段 '\(context.codingPath.map { $0.stringValue }.joined(separator: "."))' 的值为空，期望类型：\(value)"
            self.st_logDecodeError("valueNotFound", message: message, data: data)
            return .failure(.dataError(message))
        } catch DecodingError.typeMismatch(let type, let context) {
            let message = "JSON解析失败：字段 '\(context.codingPath.map { $0.stringValue }.joined(separator: "."))' 类型不匹配，期望：\(type)，实际：\(context.debugDescription)"
            self.st_logDecodeError("typeMismatch", message: message, data: data)
            return .failure(.dataError(message))
        } catch DecodingError.dataCorrupted(let context) {
            let message = "JSON解析失败：数据损坏，路径：\(context.codingPath.map { $0.stringValue }.joined(separator: "."))，原因：\(context.debugDescription)"
            self.st_logDecodeError("dataCorrupted", message: message, data: data)
            return .failure(.dataError(message))
        } catch {
            let message = "JSON解析失败：\(error.localizedDescription)"
            self.st_logDecodeError("unknown", message: message, data: data)
            return .failure(.dataError(message))
        }
    }

    private func st_logDecodeError(_ tag: String, message: String, data: Data) {
        var log = "[st_decodeResponse][\(tag)] \(message)"
        if let jsonString = String(data: data, encoding: .utf8) {
            log += "\n原始数据: \(jsonString)"
        }
        STLog(log)
    }

    /// 统一的响应解析入口：成功则解码为 T，失败则转换为 STBaseError。
    /// 上传/下载与常规请求路径共用，避免维护两套错误处理逻辑。
    private func st_resultFromHTTPResponse<T: Codable>(_ httpResponse: STHTTPResponse, responseType: T.Type) -> Result<T, STBaseError> {
        if httpResponse.isSuccess {
            return self.st_decodeResponse(httpResponse, responseType: responseType)
        }
        return .failure(self.st_convertHTTPError(httpResponse.error))
    }

    private func st_convertHTTPError(_ error: Error?) -> STBaseError {
        if let baseError = error as? STBaseError {
            return baseError
        } else if let httpError = error as? STHTTPError {
            switch httpError {
            case .networkError(let networkError):
                return STBaseError.networkError(networkError.localizedDescription)
            case .serverError(let code):
                return STBaseError.networkError("服务器错误: \(code)")
            case .invalidURL:
                return STBaseError.dataError("无效的 URL")
            case .noData:
                return STBaseError.dataError("无数据返回")
            case .timeout:
                return STBaseError.networkError("请求超时")
            case .decodingError:
                return STBaseError.dataError("数据解码失败")
            case .cancelled:
                return STBaseError.networkError("请求已取消")
            }
        } else if let error = error {
            return STBaseError.origin(error: error)
        } else {
            return STBaseError.unknown
        }
    }

    // MARK: - 缓存管理
    /// 写入缓存。需要 `cacheConfig.enableCache == true` 且 key 非空。
    public func st_setCache<T: Codable>(_ object: T, forKey key: String) {
        guard self.cacheConfig.enableCache, !key.isEmpty else { return }
        guard let data = self.st_encodeCachePayload(object) else { return }

        let entry = STMemoryCacheEntry(data: data, expiration: Date().addingTimeInterval(self.cacheConfig.cacheExpiration))
        self.cache.setObject(entry, forKey: NSString(string: key))

        if self.cacheConfig.cachePolicy == .disk || self.cacheConfig.cachePolicy == .both {
            self.st_saveToDisk(data: data, expiration: entry.expiration, forKey: key)
        }
    }

    /// 读取缓存（解码为指定类型），过期或不存在返回 nil。
    public func st_getCache<T: Codable>(forKey key: String, as type: T.Type) -> T? {
        guard self.cacheConfig.enableCache, !key.isEmpty else { return nil }
        let nsKey = NSString(string: key)

        if let entry = self.cache.object(forKey: nsKey) {
            if entry.expiration > Date() {
                return self.st_decodeCachePayload(entry.data, as: type)
            }
            self.cache.removeObject(forKey: nsKey)
        }

        if self.cacheConfig.cachePolicy == .disk || self.cacheConfig.cachePolicy == .both,
           let payload = self.st_loadFromDisk(forKey: key) {
            if payload.expiration > Date() {
                self.cache.setObject(STMemoryCacheEntry(data: payload.data, expiration: payload.expiration), forKey: nsKey)
                return self.st_decodeCachePayload(payload.data, as: type)
            }
            self.st_removeFromDisk(forKey: key)
        }
        return nil
    }

    public func st_removeCache(forKey key: String) {
        guard !key.isEmpty else { return }
        self.cache.removeObject(forKey: NSString(string: key))
        if self.cacheConfig.cachePolicy == .disk || self.cacheConfig.cachePolicy == .both {
            self.st_removeFromDisk(forKey: key)
        }
    }

    public func st_clearCache() {
        self.cache.removeAllObjects()
        if self.cacheConfig.cachePolicy == .disk || self.cacheConfig.cachePolicy == .both {
            self.st_clearDiskCache()
        }
    }

    private func st_encodeCachePayload<T: Codable>(_ object: T) -> Data? {
        do {
            return try self.jsonEncoder.encode(object)
        } catch {
            STLog("[STBaseViewModel] 缓存编码失败: \(error.localizedDescription)")
            return nil
        }
    }

    private func st_decodeCachePayload<T: Codable>(_ data: Data, as type: T.Type) -> T? {
        do {
            return try self.jsonDecoder.decode(type, from: data)
        } catch {
            STLog("[STBaseViewModel] 缓存解码失败: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - 磁盘缓存
    private struct STDiskCachePayload: Codable {
        let data: Data
        let expiration: Date
    }

    /// 新命名空间缓存路径（带 `stvm_` 前缀）。internal 可见性以便测试验证命名空间契约。
    func st_diskCacheURL(forKey key: String) -> URL? {
        guard let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else { return nil }
        let safeName = self.st_safeCacheFileName(forKey: key)
        return cacheDirectory.appendingPathComponent("\(safeName).cache")
    }

    /// 升级前（无 `stvm_` 前缀）的旧缓存路径，仅用于一次性迁移回退。
    func st_legacyDiskCacheURL(forKey key: String) -> URL? {
        guard let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else { return nil }
        let digest = SHA256.hash(data: Data(key.utf8))
        let legacyName = digest.map { String(format: "%02x", $0) }.joined()
        return cacheDirectory.appendingPathComponent("\(legacyName).cache")
    }

    /// 文件名加 `stvm_` 命名空间前缀，避免与 App 内其他同样使用 `.cache` 后缀的模块互相误删。
    private func st_safeCacheFileName(forKey key: String) -> String {
        let digest = SHA256.hash(data: Data(key.utf8))
        return "stvm_" + digest.map { String(format: "%02x", $0) }.joined()
    }

    private func st_saveToDisk(data: Data, expiration: Date, forKey key: String) {
        guard let fileURL = self.st_diskCacheURL(forKey: key) else { return }
        let payload = STDiskCachePayload(data: data, expiration: expiration)
        do {
            let encoded = try self.jsonEncoder.encode(payload)
            try encoded.write(to: fileURL, options: .atomic)
        } catch {
            STLog("[STBaseViewModel] 磁盘缓存写入失败: \(error.localizedDescription)")
        }
    }

    private func st_loadFromDisk(forKey key: String) -> STDiskCachePayload? {
        // 优先读取新命名空间路径。
        if let newURL = self.st_diskCacheURL(forKey: key),
           let payload = self.st_decodeDiskCache(at: newURL) {
            return payload
        }
        // 回退读取升级前的旧路径（无 stvm_ 前缀），命中则迁移到新路径并删除旧文件。
        guard let legacyURL = self.st_legacyDiskCacheURL(forKey: key),
              let payload = self.st_decodeDiskCache(at: legacyURL) else {
            return nil
        }
        if let newURL = self.st_diskCacheURL(forKey: key) {
            do {
                try self.jsonEncoder.encode(payload).write(to: newURL, options: .atomic)
                try FileManager.default.removeItem(at: legacyURL)
            } catch {
                STLog("[STBaseViewModel] 磁盘缓存迁移失败: \(error.localizedDescription)")
            }
        }
        return payload
    }

    private func st_decodeDiskCache(at fileURL: URL) -> STDiskCachePayload? {
        do {
            let data = try Data(contentsOf: fileURL)
            return try self.jsonDecoder.decode(STDiskCachePayload.self, from: data)
        } catch {
            return nil
        }
    }

    private func st_removeFromDisk(forKey key: String) {
        guard let fileURL = self.st_diskCacheURL(forKey: key) else { return }
        do {
            try FileManager.default.removeItem(at: fileURL)
        } catch {
            STLog("[STBaseViewModel] 磁盘缓存删除失败: \(error.localizedDescription)")
        }
    }

    /// 本模块磁盘缓存文件特征：仅 `stvm_` 命名空间前缀可证明 ownership。
    /// 不再将「纯 64 位十六进制」的无前缀文件认定为可批量删除的本模块文件，
    /// 因为其他模块也可能采用 SHA-256 命名；遗留文件仅按调用方已知 key 计算出的确切旧路径迁移/删除。
    /// internal 可见性以便测试验证所有权判定（不触碰真实磁盘）。
    func st_isOwnedCacheFile(_ fileURL: URL) -> Bool {
        guard fileURL.pathExtension == "cache" else { return false }
        let base = fileURL.deletingPathExtension().lastPathComponent
        return base.hasPrefix("stvm_")
    }

    private func st_clearDiskCache() {
        guard let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            return
        }
        do {
            let cacheFiles = try FileManager.default.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
            cacheFiles.forEach { fileURL in
                guard self.st_isOwnedCacheFile(fileURL) else { return }
                do {
                    try FileManager.default.removeItem(at: fileURL)
                } catch {
                    STLog("[STBaseViewModel] 清理磁盘缓存失败: \(error.localizedDescription)")
                }
            }
        } catch {
            STLog("[STBaseViewModel] 读取缓存目录失败: \(error.localizedDescription)")
        }
    }

    // MARK: - 数据验证
    open func st_validateData<T>(_ data: T) -> Bool { true }
    open func st_validateResponse<T>(_ response: T) -> Bool { true }

    // MARK: - 工具方法
    public func st_createRequest(url: URL, method: String = "GET", body: Data? = nil) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = body
        request.timeoutInterval = self.requestConfig.timeoutInterval
        request.cachePolicy = self.requestConfig.cachePolicy
        request.allowsCellularAccess = self.requestConfig.allowsCellularAccess
        request.httpShouldHandleCookies = self.requestConfig.httpShouldHandleCookies
        request.httpShouldUsePipelining = self.requestConfig.httpShouldUsePipelining
        request.networkServiceType = self.requestConfig.networkServiceType
        let headers = self.requestHeaders.st_getHeaders()
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        return request
    }

    public func st_parseJSON<T: Codable>(_ data: Data, type: T.Type) -> Result<T, STBaseError> {
        let result = data.decodeResult(type, using: self.jsonDecoder)
        switch result {
        case .success(let decoded):
            return .success(decoded)
        case .failure(let error):
            return .failure(STBaseError.dataError("JSON解析失败: \(error.localizedDescription)"))
        }
    }

    public func st_toJSON<T: Codable>(_ object: T) -> Result<Data, STBaseError> {
        let result = object.encodeToJSONData(using: self.jsonEncoder)
        switch result {
        case .success(let data):
            return .success(data)
        case .failure(let error):
            return .failure(STBaseError.dataError("JSON编码失败: \(error.localizedDescription)"))
        }
    }

    // MARK: - 文件上传和下载
    public func st_upload<T: Codable>(url: String, parameters: [String: Any]? = nil, files: [STUploadFile], responseType: T.Type, progress: ((STUploadProgress) -> Void)? = nil, completion: @escaping (Result<T, STBaseError>) -> Void) {
        let shouldShowLoading = self.requestConfig.showLoading
        if shouldShowLoading {
            self.st_beginLoadingRequest()
        }
        let uploadRequest = self.httpSession.upload(url, files: files, parameters: parameters, headers: self.requestHeaders, interceptor: nil, requestConfig: self.requestConfig)
        if let progress = progress {
            var progressID: UUID?
            let progressSub = uploadRequest.progressPublisher
                .sink(receiveCompletion: { [weak self] _ in
                    self?.st_unregisterCancellable(progressID)
                }, receiveValue: progress)
            progressID = self.st_registerCancellable(progressSub)
        }
        var responseID: UUID?
        let responseSub = uploadRequest.responsePublisher
            .sink(receiveCompletion: { [weak self] _ in
                self?.st_unregisterCancellable(responseID)
            }, receiveValue: { [weak self] response in
                guard let self = self else { return }
                let result = self.st_resultFromHTTPResponse(response, responseType: responseType)
                self.st_applyTerminalState(result.map { _ in () }, shouldShowLoading: shouldShowLoading, sendDataUpdate: true)
                completion(result)
            })
        responseID = self.st_registerCancellable(responseSub)
    }

    /// 真正基于 URLSession download task 的下载，避免大文件全量入内存。
    /// 默认会写入到调用方提供的 destination；若未提供则使用临时目录中的随机文件。
    public func st_download(url: String, destination: URL? = nil, progress: ((STDownloadProgress) -> Void)? = nil, completion: @escaping (URL?, STBaseError?) -> Void) {
        let shouldShowLoading = self.requestConfig.showLoading
        if shouldShowLoading {
            self.st_beginLoadingRequest()
        }
        let targetURL = destination ?? FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let downloadRequest = self.httpSession.download(
            url,
            to: targetURL,
            method: .get,
            parameters: nil,
            encoding: .url,
            headers: self.requestHeaders,
            dispatch: STDownloadDispatch(
                options: .default,
                resumeData: nil,
                interceptor: nil,
                requestConfig: self.requestConfig
            )
        )
        if let progress = progress {
            var progressID: UUID?
            let progressSub = downloadRequest.progressPublisher
                .sink(receiveCompletion: { [weak self] _ in
                    self?.st_unregisterCancellable(progressID)
                }, receiveValue: progress)
            progressID = self.st_registerCancellable(progressSub)
        }
        var responseID: UUID?
        let responseSub = downloadRequest.responsePublisher
            .sink(receiveCompletion: { [weak self] state in
                self?.st_unregisterCancellable(responseID)
                guard let self = self else { return }
                if case .failure(let error) = state {
                    let baseError = self.st_convertHTTPError(error)
                    self.st_applyTerminalState(.failure(baseError), shouldShowLoading: shouldShowLoading, sendDataUpdate: false)
                    completion(nil, baseError)
                }
            }, receiveValue: { [weak self] fileURL in
                self?.st_unregisterCancellable(responseID)
                guard let self = self else { return }
                // 下载完成代表文件就绪而非 ViewModel 数据更新，故不发送 dataUpdated（与旧行为一致）。
                self.st_applyTerminalState(.success(()), shouldShowLoading: shouldShowLoading, sendDataUpdate: false)
                completion(fileURL, nil)
            })
        responseID = self.st_registerCancellable(responseSub)
    }

    /// 统一的加载终态分发，供上传/下载等非 Publisher 请求路径复用。
    /// 仅关心「成功或失败」终态，不携带具体值（故非泛型）。
    /// - shouldShowLoading: 仅当本次操作确实触发了 `st_beginLoadingRequest`（即 showLoading 为 true）才走并发计数式终态，
    ///   避免无 loading 的上传/下载干扰其他并发请求的 loading 计数。
    /// - sendDataUpdate: 是否额外发送 `dataUpdated`（上传成功代表数据变更，下载成功仅代表文件就绪，故分别传 true/false）。
    private func st_applyTerminalState(_ result: Result<Void, STBaseError>, shouldShowLoading: Bool, sendDataUpdate: Bool) {
        switch result {
        case .success:
            if shouldShowLoading {
                self.st_finishLoadingRequest(.loaded)
            }
            if sendDataUpdate {
                self.dataUpdated.send()
            }
        case .failure(let error):
            if shouldShowLoading {
                self.st_finishLoadingRequest(.failed(error))
            }
        }
    }

    // MARK: - 内存管理
    public func st_cleanup() {
        self.stateLock.lock()
        let requests = self.inflightRequests
        self.inflightRequests.removeAll()
        self.stateLock.unlock()
        requests.forEach { _ = $0.cancel() }

        self.st_removeAllCancellables()
        self.cancellableRegistry.removeAll()
        self.cache.removeAllObjects()
        self.loadingState.send(.idle)
        self.refreshState.send(.idle)
    }

    // MARK: - 内部辅助
    fileprivate func st_storeCancellable(_ cancellable: AnyCancellable) {
        self.stateLock.lock()
        self.cancellables.insert(cancellable)
        self.stateLock.unlock()
    }

    /// 注册一次性订阅并返回其 UUID；完成时调用 `st_unregisterCancellable(_:)` 按 UUID 精确移除。
    /// 回调只捕获 UUID，不持有 token 本身，故无自持有环，且 add/remove 均经锁原子化，规避同步/异步竞态。
    @discardableResult
    fileprivate func st_registerCancellable(_ cancellable: AnyCancellable) -> UUID {
        return self.cancellableRegistry.add(cancellable)
    }

    fileprivate func st_unregisterCancellable(_ id: UUID?) {
        guard let id = id else { return }
        self.cancellableRegistry.remove(id)
    }

    /// 以 UUID 为键、锁保护的临时订阅注册表。订阅只通过 add 进入、remove 离开，外部回调不引用其内部。
    private final class STCancellableRegistry {
        private let lock = NSLock()
        private var store: [UUID: AnyCancellable] = [:]
        func add(_ cancellable: AnyCancellable) -> UUID {
            let id = UUID()
            self.lock.lock()
            self.store[id] = cancellable
            self.lock.unlock()
            return id
        }
        func remove(_ id: UUID) {
            self.lock.lock()
            self.store.removeValue(forKey: id)
            self.lock.unlock()
        }
        func removeAll() {
            self.lock.lock()
            self.store.removeAll()
            self.lock.unlock()
        }
        var count: Int {
            self.lock.lock()
            let c = self.store.count
            self.lock.unlock()
            return c
        }
    }

    /// 当前 registry 中尚未移除的临时订阅数量（测试/诊断用）。
    var st_registeredCancellableCount: Int {
        return self.cancellableRegistry.count
    }

    private func st_trackInflight(_ request: STDataRequest) {
        self.stateLock.lock()
        self.inflightRequests.append(request)
        self.stateLock.unlock()
    }

    private func st_untrackInflight(_ request: STDataRequest) {
        self.stateLock.lock()
        if let index = self.inflightRequests.firstIndex(where: { $0 === request }) {
            self.inflightRequests.remove(at: index)
        }
        self.stateLock.unlock()
    }

    private func st_removeAllCancellables() {
        self.stateLock.lock()
        self.cancellables.removeAll()
        self.activeLoadingRequestCount = 0
        self.pendingLoadingFailure = nil
        self.stateLock.unlock()
    }

    private func st_beginLoadingRequest() {
        self.stateLock.lock()
        self.activeLoadingRequestCount += 1
        let shouldSendLoading = self.activeLoadingRequestCount == 1
        self.stateLock.unlock()

        if shouldSendLoading {
            self.loadingState.send(.loading)
        }
    }

    private func st_finishLoadingRequest(_ terminalState: STLoadingState) {
        self.stateLock.lock()
        if case .failed(let error) = terminalState {
            self.pendingLoadingFailure = error
        }
        if self.activeLoadingRequestCount > 0 {
            self.activeLoadingRequestCount -= 1
        }
        let shouldSendTerminalState = self.activeLoadingRequestCount == 0
        let stateToSend: STLoadingState
        if shouldSendTerminalState, let pendingLoadingFailure = self.pendingLoadingFailure {
            stateToSend = .failed(pendingLoadingFailure)
            self.pendingLoadingFailure = nil
        } else {
            stateToSend = terminalState
        }
        self.stateLock.unlock()

        if shouldSendTerminalState {
            self.loadingState.send(stateToSend)
        }
    }

    private func st_cancelLoadingRequest() {
        self.stateLock.lock()
        if self.activeLoadingRequestCount > 0 {
            self.activeLoadingRequestCount -= 1
        }
        let shouldSendIdle = self.activeLoadingRequestCount == 0
        if shouldSendIdle {
            self.pendingLoadingFailure = nil
        }
        self.stateLock.unlock()

        if shouldSendIdle {
            self.loadingState.send(.idle)
        }
    }
}

private extension AnyCancellable {
    func st_store(in viewModel: STBaseViewModel) {
        viewModel.st_storeCancellable(self)
    }
}

/// 内存缓存条目（NSCache 要求 class 类型）
private final class STMemoryCacheEntry {
    let data: Data
    let expiration: Date
    init(data: Data, expiration: Date) {
        self.data = data
        self.expiration = expiration
    }
}

// MARK: - 便捷扩展
extension STBaseViewModel {
    public func st_bindLoadingState<T: AnyObject>(to object: T, keyPath: ReferenceWritableKeyPath<T, Bool>) {
        self.loadingState
            .map { state -> Bool in
                if case .loading = state { return true }
                return false
            }
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .assign(to: keyPath, on: object)
            .st_store(in: self)
    }

    public func st_bindError<T: AnyObject>(to object: T, keyPath: ReferenceWritableKeyPath<T, String?>) {
        self.errorPublisher
            .map { $0.errorDescription }
            .receive(on: DispatchQueue.main)
            .assign(to: keyPath, on: object)
            .st_store(in: self)
    }

    public func st_bindDataUpdate<T: AnyObject>(to object: T, action: @escaping (T) -> Void) {
        self.dataUpdated
            .receive(on: DispatchQueue.main)
            .sink { [weak object] _ in
                if let object = object {
                    action(object)
                }
            }
            .st_store(in: self)
    }

    /// 设置认证 Token
    public func st_setAuthToken(_ token: String, type: STAuthorizationType) {
        self.requestHeaders.st_setAuthorization(token, type: type)
    }

    /// 设置自定义认证头
    public func st_setCustomAuth(_ value: String) {
        self.requestHeaders.st_setCustomAuthorization(value)
    }

    /// 调试方法：打印原始响应数据。仅 DEBUG 编译生效，避免线上泄露敏感数据。
    public func st_debugResponse(_ response: STHTTPResponse) {
        #if DEBUG
        STLog("=== HTTP 响应调试信息 ===")
        STLog("状态码: \(response.statusCode)")
        STLog("是否成功: \(response.isSuccess)")
        STLog("响应头: \(response.headers)")
        if let data = response.data {
            STLog("数据大小: \(data.count) bytes")
            if let jsonString = String(data: data, encoding: .utf8) {
                STLog("原始 JSON: \(jsonString)")
            } else {
                STLog("数据不是有效的 UTF-8 字符串")
            }
        } else {
            STLog("响应数据为空")
        }
        if let error = response.error {
            STLog("错误信息: \(error.localizedDescription)")
        }
        #endif
    }

    /// 设置自定义请求头
    public func st_setCustomHeaders(_ headers: [String: String]) {
        self.requestHeaders.st_setHeaders(headers)
    }

    /// 清除认证信息
    public func st_clearAuth() {
        self.requestHeaders.st_removeHeader(forKey: "Authorization")
    }

    /// 检查网络状态
    public func st_checkNetworkStatus() -> STNetworkReachabilityStatus {
        return self.httpSession.st_checkNetworkStatus()
    }

    /// 等待网络可用。
    /// - Parameters:
    ///   - timeout: 总超时秒数；默认 30 秒，超过后回调 `false` 而不再继续轮询。
    ///   - pollInterval: 轮询间隔，默认 1 秒。
    ///   - completion: `true` 表示网络已可达，`false` 表示超时或视图模型已释放。
    public func st_waitForNetwork(timeout: TimeInterval = 30, pollInterval: TimeInterval = 1.0, completion: @escaping (Bool) -> Void) {
        let deadline = Date().addingTimeInterval(timeout)
        self.st_pollNetwork(deadline: deadline, pollInterval: pollInterval, completion: completion)
    }

    private func st_pollNetwork(deadline: Date, pollInterval: TimeInterval, completion: @escaping (Bool) -> Void) {
        if self.httpSession.st_checkNetworkStatus() != .notReachable {
            completion(true)
            return
        }
        if Date() >= deadline {
            completion(false)
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + pollInterval) { [weak self] in
            guard let self = self else {
                completion(false)
                return
            }
            self.st_pollNetwork(deadline: deadline, pollInterval: pollInterval, completion: completion)
        }
    }
}
