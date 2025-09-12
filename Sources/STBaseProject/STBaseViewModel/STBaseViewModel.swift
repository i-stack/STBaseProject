//
//  STBaseViewModel.swift
//  STBaseProject
//
//  Created by stack on 2018/3/14.
//

import UIKit
import Foundation
import Combine

// MARK: - 错误类型枚举
public enum STBaseError: LocalizedError {
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
}

// MARK: - 加载状态枚举
public enum STLoadingState {
    case idle
    case loading
    case loaded
    case failed(STBaseError)
    case empty
}

// MARK: - 刷新状态枚举
public enum STRefreshState {
    case idle
    case refreshing
    case noMoreData
    case failed(STBaseError)
}

// MARK: - 缓存配置
public struct STCacheConfig {
    var enableCache: Bool = false
    var cacheKey: String = ""
    var cacheExpiration: TimeInterval = 300 // 5分钟
    var cachePolicy: STCachePolicy = .memory
    
    public enum STCachePolicy {
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
    
    public var loadingState = CurrentValueSubject<STLoadingState, Never>(.idle)
    public var refreshState = CurrentValueSubject<STRefreshState, Never>(.idle)
    public var error = PassthroughSubject<STBaseError, Never>()
    public var dataUpdated = PassthroughSubject<Void, Never>()
    public var requestConfig = STRequestConfig()
    public var cacheConfig = STCacheConfig()
    public var httpSession = STHTTPSession.shared
    public var requestHeaders = STRequestHeaders()
    
    private var cancellables = Set<AnyCancellable>()
    private var cache = NSCache<NSString, AnyObject>()
    private var retryCount = 0
    
    deinit {
        cancellables.removeAll()
        cache.removeAllObjects()
        STLog("🌈 -> \(self) 🌈 ----> 🌈 dealloc")
    }
    
    public override init() {
        super.init()
        st_setupBindings()
    }
    
    private func st_setupBindings() {
        loadingState.sink { [weak self] state in
            self?.st_handleLoadingStateChange(state)
        }.store(in: &cancellables)
        
        refreshState.sink { [weak self] state in
            self?.st_handleRefreshStateChange(state)
        }.store(in: &cancellables)
    }
    
    private func st_handleLoadingStateChange(_ state: STLoadingState) {
        switch state {
        case .loading:
            st_onLoading()
        case .loaded:
            st_onLoaded()
        case .failed(let error):
            st_onFailed(error)
        case .empty:
            st_onEmpty()
        case .idle:
            break
        }
    }
    
    private func st_handleRefreshStateChange(_ state: STRefreshState) {
        switch state {
        case .refreshing:
            st_onRefreshing()
        case .noMoreData:
            st_onNoMoreData()
        case .failed(let error):
            st_onRefreshFailed(error)
        case .idle:
            break
        }
    }
    
    // MARK: - 可重写的方法
    open func st_onLoading() {
        // 子类可以重写此方法
    }
    
    open func st_onLoaded() {
        // 子类可以重写此方法
    }
    
    open func st_onFailed(_ error: STBaseError) {
        // 子类可以重写此方法
        self.error.send(error)
    }
    
    open func st_onEmpty() {
        // 子类可以重写此方法
    }
    
    open func st_onRefreshing() {
        // 子类可以重写此方法
    }
    
    open func st_onNoMoreData() {
        // 子类可以重写此方法
    }
    
    open func st_onRefreshFailed(_ error: STBaseError) {
        // 子类可以重写此方法
        self.error.send(error)
    }
    
    // MARK: - 网络请求核心方法
    open func st_request<T: Codable>(url: String,
                                   method: STHTTPMethod = .get,
                                   parameters: [String: Any]? = nil,
                                   encodingType: STParameterEncoder.EncodingType = .json,
                                   responseType: T.Type,
                                   completion: @escaping (Result<T, STBaseError>) -> Void) {
        if requestConfig.showLoading {
            loadingState.send(.loading)
        }
        httpSession.st_request(url: url, 
                              method: method, 
                              parameters: parameters, 
                              encodingType: encodingType, 
                              requestConfig: requestConfig, 
                              requestHeaders: requestHeaders) { [weak self] response in
            guard let strongSelf = self else { return }
            strongSelf.st_handleHTTPResponse(response, responseType: responseType, completion: completion)
        }
    }
    
    open func st_get<T: Codable>(url: String,
                                parameters: [String: Any]? = nil,
                                responseType: T.Type,
                                completion: @escaping (Result<T, STBaseError>) -> Void) {
        st_request(url: url, method: .get, parameters: parameters, responseType: responseType, completion: completion)
    }
    
    open func st_post<T: Codable>(url: String,
                                 parameters: [String: Any]? = nil,
                                 responseType: T.Type,
                                 completion: @escaping (Result<T, STBaseError>) -> Void) {
        st_request(url: url, method: .post, parameters: parameters, responseType: responseType, completion: completion)
    }
    
    open func st_put<T: Codable>(url: String,
                                parameters: [String: Any]? = nil,
                                responseType: T.Type,
                                completion: @escaping (Result<T, STBaseError>) -> Void) {
        st_request(url: url, method: .put, parameters: parameters, responseType: responseType, completion: completion)
    }
    
    open func st_delete<T: Codable>(url: String,
                                   parameters: [String: Any]? = nil,
                                   responseType: T.Type,
                                   completion: @escaping (Result<T, STBaseError>) -> Void) {
        st_request(url: url, method: .delete, parameters: parameters, responseType: responseType, completion: completion)
    }
    
    open func st_request<T: Codable>(_ request: URLRequest, responseType: T.Type, completion: @escaping (Result<T, STBaseError>) -> Void) {
        guard let url = request.url?.absoluteString else {
            completion(.failure(.dataError("无效的 URL")))
            return
        }
        let method = STHTTPMethod(rawValue: request.httpMethod ?? "GET") ?? .get
        let parameters = st_extractParameters(from: request)
        st_request(url: url, 
                  method: method, 
                  parameters: parameters, 
                  responseType: responseType, 
                  completion: completion)
    }
    
    // MARK: - 参数提取（用于 URLRequest）
    private func st_extractParameters(from request: URLRequest) -> [String: Any]? {
        if let httpMethod = request.httpMethod, httpMethod.uppercased() == "GET" {
            return st_extractQueryParameters(from: request.url)
        }
        if let httpBody = request.httpBody {
            return st_extractBodyParameters(from: httpBody)
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
        do {
            let json = try JSONSerialization.jsonObject(with: data)
            return json as? [String: Any]
        } catch {
            if let string = String(data: data, encoding: .utf8) {
                return st_parseFormData(string)
            }
        }
        return nil
    }
    
    private func st_parseFormData(_ formString: String) -> [String: Any]? {
        let pairs = formString.components(separatedBy: "&")
        var parameters: [String: Any] = [:]
        for pair in pairs {
            let components = pair.components(separatedBy: "=")
            if components.count == 2 {
                let key = components[0].removingPercentEncoding ?? components[0]
                let value = components[1].removingPercentEncoding ?? components[1]
                parameters[key] = value
            }
        }
        return parameters.isEmpty ? nil : parameters
    }
    
    // MARK: - 响应处理
    private func st_decodeResponse<T: Codable>(_ httpResponse: STHTTPResponse, responseType: T.Type) -> T? {
        guard let data = httpResponse.data else { return nil }
        return try? JSONDecoder().decode(responseType, from: data)
    }
    
    private func st_handleHTTPResponse<T: Codable>(_ httpResponse: STHTTPResponse,
                                                 responseType: T.Type,
                                                 completion: @escaping (Result<T, STBaseError>) -> Void) {
        if httpResponse.isSuccess {
            if let result = st_decodeResponse(httpResponse, responseType: responseType) {
                st_handleSuccess(result, completion: completion)
            } else {
                let error = STBaseError.dataError("数据解析失败")
                st_handleError(error, completion: completion)
            }
        } else {
            let error = st_convertHTTPError(httpResponse.error)
            st_handleError(error, completion: completion)
        }
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
        loadingState.send(.loaded)
        completion(.success(result))
        dataUpdated.send()
    }
    
    private func st_handleError<T>(_ error: STBaseError, completion: @escaping (Result<T, STBaseError>) -> Void) {
        loadingState.send(.failed(error))
        completion(.failure(error))
        if retryCount < requestConfig.retryCount {
            retryCount += 1
        }
    }
    
    // MARK: - 缓存管理
    open func st_setCache(_ object: Any, forKey key: String) {
        let cacheKey = NSString(string: key)
        cache.setObject(object as AnyObject, forKey: cacheKey)
        if cacheConfig.cachePolicy == .disk || cacheConfig.cachePolicy == .both {
            st_saveToDisk(object: object, forKey: key)
        }
    }
    
    open func st_getCache(forKey key: String) -> Any? {
        let cacheKey = NSString(string: key)
        if let cachedObject = cache.object(forKey: cacheKey) {
            return cachedObject
        }
        if cacheConfig.cachePolicy == .disk || cacheConfig.cachePolicy == .both {
            return st_loadFromDisk(forKey: key)
        }
        return nil
    }
    
    open func st_removeCache(forKey key: String) {
        let cacheKey = NSString(string: key)
        cache.removeObject(forKey: cacheKey)
        if cacheConfig.cachePolicy == .disk || cacheConfig.cachePolicy == .both {
            st_removeFromDisk(forKey: key)
        }
    }
    
    open func st_clearCache() {
        cache.removeAllObjects()
        if cacheConfig.cachePolicy == .disk || cacheConfig.cachePolicy == .both {
            st_clearDiskCache()
        }
    }
    
    // MARK: - 磁盘缓存
    private func st_saveToDisk(object: Any, forKey key: String) {
        guard let data = try? JSONSerialization.data(withJSONObject: object) else { return }
        let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
        let fileURL = cacheDirectory?.appendingPathComponent("\(key).cache")
        if let fileURL = fileURL {
            try? data.write(to: fileURL)
        }
    }
    
    private func st_loadFromDisk(forKey key: String) -> Any? {
        let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
        let fileURL = cacheDirectory?.appendingPathComponent("\(key).cache")
        guard let fileURL = fileURL,
              let data = try? Data(contentsOf: fileURL),
              let object = try? JSONSerialization.jsonObject(with: data) else {
            return nil
        }
        return object
    }
    
    private func st_removeFromDisk(forKey key: String) {
        let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
        let fileURL = cacheDirectory?.appendingPathComponent("\(key).cache")
        if let fileURL = fileURL {
            try? FileManager.default.removeItem(at: fileURL)
        }
    }
    
    private func st_clearDiskCache() {
        let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
        let cacheFiles = try? FileManager.default.contentsOfDirectory(at: cacheDirectory!, includingPropertiesForKeys: nil)
        cacheFiles?.forEach { fileURL in
            if fileURL.pathExtension == "cache" {
                try? FileManager.default.removeItem(at: fileURL)
            }
        }
    }
    
    // MARK: - 数据验证
    open func st_validateData<T>(_ data: T) -> Bool {
        // 子类可以重写此方法进行数据验证
        return true
    }
    
    open func st_validateResponse<T>(_ response: T) -> Bool {
        // 子类可以重写此方法进行响应验证
        return true
    }
    
    // MARK: - 工具方法
    open func st_createRequest(url: URL, method: String = "GET", body: Data? = nil) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = body
        request.timeoutInterval = requestConfig.timeoutInterval
        request.cachePolicy = requestConfig.cachePolicy
        request.allowsCellularAccess = requestConfig.allowsCellularAccess
        request.httpShouldHandleCookies = requestConfig.httpShouldHandleCookies
        request.httpShouldUsePipelining = requestConfig.httpShouldUsePipelining
        request.networkServiceType = requestConfig.networkServiceType
        let headers = requestHeaders.st_getHeaders()
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        return request
    }
    
    open func st_parseJSON<T: Codable>(_ data: Data, type: T.Type) -> Result<T, STBaseError> {
        let result = data.st_decodeWithError(type)
        switch result {
        case .success(let decoded):
            return .success(decoded)
        case .failure(let error):
            return .failure(STBaseError.dataError("JSON解析失败: \(error.localizedDescription)"))
        }
    }
    
    open func st_toJSON<T: Codable>(_ object: T) -> Result<Data, STBaseError> {
        let result = object.st_toJSONDataWithError()
        switch result {
        case .success(let data):
            return .success(data)
        case .failure(let error):
            return .failure(STBaseError.dataError("JSON编码失败: \(error.localizedDescription)"))
        }
    }
    
    // MARK: - 文件上传和下载
    open func st_upload<T: Codable>(url: String,
                                   parameters: [String: Any]? = nil,
                                   files: [STUploadFile],
                                   responseType: T.Type,
                                   progress: ((STUploadProgress) -> Void)? = nil,
                                   completion: @escaping (Result<T, STBaseError>) -> Void) {
        
        if requestConfig.showLoading {
            loadingState.send(.loading)
        }
        
        httpSession.st_upload(url: url, files: files, parameters: parameters, requestConfig: requestConfig, requestHeaders: requestHeaders, progress: progress) { [weak self] response in
            self?.st_handleHTTPResponse(response, responseType: responseType, completion: completion)
        }
    }
    
    open func st_download(url: String,
                         progress: ((STUploadProgress) -> Void)? = nil,
                         completion: @escaping (URL?, STBaseError?) -> Void) {
        if requestConfig.showLoading {
            loadingState.send(.loading)
        }
        httpSession.st_request(url: url, method: .get, parameters: nil, encodingType: .json, requestConfig: requestConfig, requestHeaders: requestHeaders) { [weak self] response in
            if response.isSuccess, let data = response.data {
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
                do {
                    try data.write(to: tempURL)
                    self?.loadingState.send(.loaded)
                    completion(tempURL, nil)
                } catch {
                    let error = STBaseError.dataError("文件保存失败")
                    self?.loadingState.send(.failed(error))
                    completion(nil, error)
                }
            } else {
                let error = self?.st_convertHTTPError(response.error) ?? STBaseError.unknown
                self?.loadingState.send(.failed(error))
                completion(nil, error)
            }
        }
    }
    
    // MARK: - 内存管理
    open func st_cleanup() {
        cancellables.removeAll()
        cache.removeAllObjects()
        retryCount = 0
        loadingState.send(.idle)
        refreshState.send(.idle)
    }
}

// MARK: - 便捷扩展
extension STBaseViewModel {
    public func st_bindLoadingState<T: AnyObject>(to object: T, keyPath: ReferenceWritableKeyPath<T, Bool>) {
        loadingState
            .map { state in
                switch state {
                case .loading:
                    return true
                default:
                    return false
                }
            }
            .assign(to: keyPath, on: object)
            .store(in: &cancellables)
    }
    
    public func st_bindError<T: AnyObject>(to object: T, keyPath: ReferenceWritableKeyPath<T, String?>) {
        error
            .map { $0.errorDescription }
            .assign(to: keyPath, on: object)
            .store(in: &cancellables)
    }
    
    public func st_bindDataUpdate<T: AnyObject>(to object: T, action: @escaping (T) -> Void) {
        dataUpdated
            .sink { [weak object] _ in
                if let object = object {
                    action(object)
                }
            }
            .store(in: &cancellables)
    }
    
    /// 设置认证 Token
    public func st_setAuthToken(_ token: String) {
        requestHeaders.st_setAuthorization(token)
    }
    
    /// 设置自定义请求头
    public func st_setCustomHeaders(_ headers: [String: String]) {
        requestHeaders.st_setHeaders(headers)
    }
    
    /// 清除认证信息
    public func st_clearAuth() {
        requestHeaders.st_removeHeader(forKey: "Authorization")
    }
    
    /// 检查网络状态
    public func st_checkNetworkStatus() -> STNetworkReachabilityStatus {
        return httpSession.st_checkNetworkStatus()
    }
    
    /// 等待网络可用
    public func st_waitForNetwork(completion: @escaping () -> Void) {
        if httpSession.st_checkNetworkStatus() != .notReachable {
            completion()
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.st_waitForNetwork(completion: completion)
            }
        }
    }
}
