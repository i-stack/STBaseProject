//
//  STBaseViewModel.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2018/3/14.
//

import UIKit
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
    public var httpSession = STHTTPSession.shared
    public var requestHeaders = STRequestHeaders()
    public var jsonDecoder: JSONDecoder = JSONDecoder()
    public var jsonEncoder: JSONEncoder = JSONEncoder()

    public private(set) var cancellables = Set<AnyCancellable>()
    private let cache = NSCache<NSString, STMemoryCacheEntry>()
    private let stateLock = NSLock()
    private var inflightRequests = [STDataRequest]()

    deinit {
        STLog("🌈 -> \(self) 🌈 ----> 🌈 dealloc")
    }

    public override init() {
        super.init()
        self.st_setupBindings()
    }

    private func st_setupBindings() {
        self.loadingState
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.st_handleLoadingStateChange(state)
            }
            .store(in: &self.cancellables)

        self.refreshState
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.st_handleRefreshStateChange(state)
            }
            .store(in: &self.cancellables)
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
        if self.requestConfig.showLoading {
            self.loadingState.send(.loading)
        }
        return self.st_dispatchRequestPublisher(url: url, method: method, parameters: parameters, encodingType: encodingType)
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
        }.mapError { error -> STBaseError in
            if let baseError = error as? STBaseError {
                return baseError
            }
            return STBaseError.origin(error: error)
        }.handleEvents(
            receiveOutput: { [weak self] _ in
                self?.loadingState.send(.loaded)
                self?.dataUpdated.send()
            },
            receiveCompletion: { [weak self] completion in
                guard let self = self else { return }
                if case .failure(let error) = completion {
                    self.loadingState.send(.failed(error))
                }
            }
        ).eraseToAnyPublisher()
    }

    public func st_request<T: Codable>(url: String, method: STHTTPMethod = .get, parameters: [String: Any]? = nil, encodingType: STParameterEncoder.EncodingType = .json, responseType: T.Type, completion: @escaping (Result<T, STBaseError>) -> Void) {
        var token: AnyCancellable?
        token = self.st_requestPublisher(url: url, method: method, parameters: parameters, encodingType: encodingType, responseType: responseType)
        .sink(
            receiveCompletion: { [weak self] state in
                if case .failure(let error) = state {
                    completion(.failure(error))
                }
                if let token = token {
                    self?.st_removeCancellable(token)
                }
            },
            receiveValue: { value in
                completion(.success(value))
            }
        )
        if let token = token {
            self.st_storeCancellable(token)
        }
    }

    open func st_dispatchRequestPublisher(url: String, method: STHTTPMethod, parameters: [String: Any]?, encodingType: STParameterEncoder.EncodingType) -> AnyPublisher<STHTTPResponse, Never> {
        let request = self.httpSession.request(url, method: method, parameters: parameters, encoding: encodingType, headers: self.requestHeaders, requestConfig: self.requestConfig)
        self.st_trackInflight(request)
        return request.responsePublisher
            .handleEvents(
                receiveCompletion: { [weak self] _ in
                    self?.st_untrackInflight(request)
                },
                receiveCancel: { [weak self] in
                    self?.st_untrackInflight(request)
                }
            )
            .eraseToAnyPublisher()
    }

    open func st_dispatchRequest(url: String, method: STHTTPMethod, parameters: [String: Any]?, encodingType: STParameterEncoder.EncodingType, completion: @escaping (STHTTPResponse) -> Void) {
        var token: AnyCancellable?
        token = self.st_dispatchRequestPublisher(url: url, method: method, parameters: parameters, encodingType: encodingType)
            .sink { [weak self] response in
                completion(response)
                if let token = token {
                    self?.st_removeCancellable(token)
                }
            }
        if let token = token {
            self.st_storeCancellable(token)
        }
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

    public func st_get<T: Codable>(url: String, parameters: [String: Any]? = nil, responseType: T.Type, completion: @escaping (Result<T, STBaseError>) -> Void) {
        self.st_request(url: url, method: .get, parameters: parameters, responseType: responseType, completion: completion)
    }

    public func st_post<T: Codable>(url: String, parameters: [String: Any]? = nil, responseType: T.Type, completion: @escaping (Result<T, STBaseError>) -> Void) {
        self.st_request(url: url, method: .post, parameters: parameters, responseType: responseType, completion: completion)
    }

    public func st_put<T: Codable>(url: String, parameters: [String: Any]? = nil, responseType: T.Type, completion: @escaping (Result<T, STBaseError>) -> Void) {
        self.st_request(url: url, method: .put, parameters: parameters, responseType: responseType, completion: completion)
    }

    public func st_delete<T: Codable>(url: String, parameters: [String: Any]? = nil, responseType: T.Type, completion: @escaping (Result<T, STBaseError>) -> Void) {
        self.st_request(url: url, method: .delete, parameters: parameters, responseType: responseType, completion: completion)
    }

    /// 直接基于已构造好的 URLRequest 发起请求；保留原始 headers / body / 超时等定制
    public func st_request<T: Codable>(_ request: URLRequest, responseType: T.Type, completion: @escaping (Result<T, STBaseError>) -> Void) {
        guard let url = request.url?.absoluteString else {
            completion(.failure(.dataError("无效的 URL")))
            return
        }
        let method = STHTTPMethod(rawValue: request.httpMethod ?? "GET") ?? .get
        let parameters = self.st_extractParameters(from: request)
        self.st_request(url: url, method: method, parameters: parameters, responseType: responseType, completion: completion)
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

    private func st_handleHTTPResponse<T: Codable>(_ httpResponse: STHTTPResponse, responseType: T.Type, completion: @escaping (Result<T, STBaseError>) -> Void) {
        let result = self.st_resultFromHTTPResponse(httpResponse, responseType: responseType)
        switch result {
        case .success(let value):
            self.st_handleSuccess(value, completion: completion)
        case .failure(let error):
            self.st_handleError(error, completion: completion)
        }
    }

    private func st_resultFromHTTPResponse<T: Codable>(_ httpResponse: STHTTPResponse, responseType: T.Type) -> Result<T, STBaseError> {
        if httpResponse.isSuccess {
            return self.st_decodeResponse(httpResponse, responseType: responseType)
        }
        return .failure(self.st_convertHTTPError(httpResponse.error))
    }

    private func st_convertHTTPError(_ error: Error?) -> STBaseError {
        if let httpError = error as? STHTTPError {
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

    private func st_handleSuccess<T>(_ result: T, completion: @escaping (Result<T, STBaseError>) -> Void) {
        self.loadingState.send(.loaded)
        completion(.success(result))
        self.dataUpdated.send()
    }

    private func st_handleError<T>(_ error: STBaseError, completion: @escaping (Result<T, STBaseError>) -> Void) {
        self.loadingState.send(.failed(error))
        completion(.failure(error))
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

    private func st_diskCacheURL(forKey key: String) -> URL? {
        guard let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else { return nil }
        let safeName = self.st_safeCacheFileName(forKey: key)
        return cacheDirectory.appendingPathComponent("\(safeName).cache")
    }

    private func st_safeCacheFileName(forKey key: String) -> String {
        let digest = SHA256.hash(data: Data(key.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
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
        guard let fileURL = self.st_diskCacheURL(forKey: key),
              let data = try? Data(contentsOf: fileURL),
              let payload = try? self.jsonDecoder.decode(STDiskCachePayload.self, from: data) else {
            return nil
        }
        return payload
    }

    private func st_removeFromDisk(forKey key: String) {
        guard let fileURL = self.st_diskCacheURL(forKey: key) else { return }
        try? FileManager.default.removeItem(at: fileURL)
    }

    private func st_clearDiskCache() {
        guard let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first,
              let cacheFiles = try? FileManager.default.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil) else {
            return
        }
        cacheFiles.forEach { fileURL in
            if fileURL.pathExtension == "cache" {
                try? FileManager.default.removeItem(at: fileURL)
            }
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
        if self.requestConfig.showLoading {
            self.loadingState.send(.loading)
        }
        let uploadRequest = self.httpSession.upload(url, files: files, parameters: parameters, headers: self.requestHeaders, requestConfig: self.requestConfig)
        if let progress = progress {
            uploadRequest.progressPublisher
                .sink(receiveValue: progress)
                .store(in: &self.cancellables)
        }
        var token: AnyCancellable?
        token = uploadRequest.responsePublisher.sink { [weak self] response in
            self?.st_handleHTTPResponse(response, responseType: responseType, completion: completion)
            if let token = token {
                self?.st_removeCancellable(token)
            }
        }
        if let token = token {
            self.st_storeCancellable(token)
        }
    }

    /// 真正基于 URLSession download task 的下载，避免大文件全量入内存。
    /// 默认会写入到调用方提供的 destination；若未提供则使用临时目录中的随机文件。
    public func st_download(url: String, destination: URL? = nil, progress: ((STDownloadProgress) -> Void)? = nil, completion: @escaping (URL?, STBaseError?) -> Void) {
        if self.requestConfig.showLoading {
            self.loadingState.send(.loading)
        }
        let targetURL = destination ?? FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let downloadRequest = self.httpSession.download(
            url,
            to: targetURL,
            method: .get,
            parameters: nil,
            encoding: .url,
            headers: self.requestHeaders,
            interceptor: nil,
            options: .default,
            resumeData: nil,
            requestConfig: self.requestConfig
        )
        if let progress = progress {
            downloadRequest.progressPublisher
                .sink(receiveValue: progress)
                .store(in: &self.cancellables)
        }
        var token: AnyCancellable?
        token = downloadRequest.responsePublisher.sink(receiveCompletion: { [weak self] state in
            if case .failure(let error) = state {
                let baseError = self?.st_convertHTTPError(error) ?? STBaseError.origin(error: error)
                self?.loadingState.send(.failed(baseError))
                completion(nil, baseError)
            }
            if let token = token {
                self?.st_removeCancellable(token)
            }
        }, receiveValue: { [weak self] fileURL in
            self?.loadingState.send(.loaded)
            completion(fileURL, nil)
        })
        if let token = token {
            self.st_storeCancellable(token)
        }
    }

    // MARK: - 内存管理
    public func st_cleanup() {
        self.stateLock.lock()
        let requests = self.inflightRequests
        self.inflightRequests.removeAll()
        self.stateLock.unlock()
        requests.forEach { _ = $0.cancel() }

        self.cancellables.removeAll()
        self.cache.removeAllObjects()
        self.loadingState.send(.idle)
        self.refreshState.send(.idle)
    }

    // MARK: - 内部辅助
    private func st_storeCancellable(_ cancellable: AnyCancellable) {
        self.stateLock.lock()
        self.cancellables.insert(cancellable)
        self.stateLock.unlock()
    }

    private func st_removeCancellable(_ cancellable: AnyCancellable) {
        self.stateLock.lock()
        self.cancellables.remove(cancellable)
        self.stateLock.unlock()
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
            .store(in: &self.cancellables)
    }

    public func st_bindError<T: AnyObject>(to object: T, keyPath: ReferenceWritableKeyPath<T, String?>) {
        self.errorPublisher
            .map { $0.errorDescription }
            .receive(on: DispatchQueue.main)
            .assign(to: keyPath, on: object)
            .store(in: &self.cancellables)
    }

    public func st_bindDataUpdate<T: AnyObject>(to object: T, action: @escaping (T) -> Void) {
        self.dataUpdated
            .receive(on: DispatchQueue.main)
            .sink { [weak object] _ in
                if let object = object {
                    action(object)
                }
            }
            .store(in: &self.cancellables)
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
