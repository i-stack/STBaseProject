//
//  STHTTPSession.swift
//  STBaseProject
//
//  Created by stack on 2018/12/10.
//

import UIKit
import Foundation
import Combine
import Network

// MARK: - HTTP 方法枚举
public enum STHTTPMethod: String {
    case connect = "CONNECT"
    case delete = "DELETE"
    case get = "GET"
    case head = "HEAD"
    case options = "OPTIONS"
    case patch = "PATCH"
    case post = "POST"
    case put = "PUT"
    case query = "QUERY"
    case trace = "TRACE"
}

// MARK: - 请求配置
public struct STRequestConfig {
    var retryCount: Int = 0
    var retryDelay: TimeInterval = 1.0
    var allowsCellularAccess: Bool = true
    var httpShouldHandleCookies: Bool = true
    var httpShouldUsePipelining: Bool = true
    var timeoutInterval: TimeInterval = 30
    var cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy
    var networkServiceType: URLRequest.NetworkServiceType = .default
    var headers: [String: String] = [:]
    var showLoading: Bool = true
    var showError: Bool = true

    public init(
        retryCount: Int = 0,
        retryDelay: TimeInterval = 1.0,
        timeoutInterval: TimeInterval = 30,
        allowsCellularAccess: Bool = true,
        httpShouldHandleCookies: Bool = true,
        httpShouldUsePipelining: Bool = true,
        networkServiceType: URLRequest.NetworkServiceType = .default,
        cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy,
        headers: [String: String] = [:],
        showLoading: Bool = true,
        showError: Bool = true) {
        self.cachePolicy = cachePolicy
        self.retryCount = retryCount
        self.retryDelay = retryDelay
        self.timeoutInterval = timeoutInterval
        self.networkServiceType = networkServiceType
        self.allowsCellularAccess = allowsCellularAccess
        self.httpShouldHandleCookies = httpShouldHandleCookies
        self.httpShouldUsePipelining = httpShouldUsePipelining
        self.headers = headers
        self.showLoading = showLoading
        self.showError = showError
    }
}

// MARK: - 请求头管理
public class STRequestHeaders {
    private var headers: [String: String] = [:]
    
    public init() {
        st_setupDefaultHeaders()
    }
    
    private func st_setupDefaultHeaders() {
        headers["Content-Type"] = "application/json; charset=utf-8"
        headers["Accept"] = "application/json"
        headers["User-Agent"] = "STBaseProject/1.0"
    }
    
    // MARK: - 公共方法
    public func st_setHeader(_ value: String, forKey key: String) {
        headers[key] = value
    }
    
    public func st_setHeaders(_ headers: [String: String]) {
        for (key, value) in headers {
            self.headers[key] = value
        }
    }
    
    public func st_removeHeader(forKey key: String) {
        headers.removeValue(forKey: key)
    }
    
    public func st_clearHeaders() {
        headers.removeAll()
        st_setupDefaultHeaders()
    }
    
    public func st_getHeaders() -> [String: String] {
        return headers
    }
    
    // MARK: - 便捷方法
    public func st_setAuthorization(_ token: String) {
        st_setHeader("Bearer \(token)", forKey: "Authorization")
    }
    
    public func st_setContentType(_ contentType: String) {
        st_setHeader(contentType, forKey: "Content-Type")
    }
    
    public func st_setAccept(_ accept: String) {
        st_setHeader(accept, forKey: "Accept")
    }
    
    public func st_setUserAgent(_ userAgent: String) {
        st_setHeader(userAgent, forKey: "User-Agent")
    }
}

// MARK: - 参数编码器
public class STParameterEncoder {
    
    public enum EncodingType {
        case url
        case json
        case formData
        case multipart
    }
    
    // MARK: - URL 编码
    public static func st_encodeURL(_ parameters: [String: Any]) -> String {
       var components: [(String, String)] = []
        
       for key in parameters.keys.sorted(by: <) {
           let value = parameters[key]!
            components += st_queryComponents(fromKey: key, value: value)
       }
        
       return components.map { "\($0)=\($1)" }.joined(separator: "&")
    }
    
    private static func st_queryComponents(fromKey key: String, value: Any) -> [(String, String)] {
       var components: [(String, String)] = []
        
       if let dictionary = value as? [String: Any] {
            for (nestedKey, value) in dictionary {
                components += st_queryComponents(fromKey: "\(key)[\(nestedKey)]", value: value)
            }
       } else if let array = value as? [Any] {
            for value in array {
                components += st_queryComponents(fromKey: "\(key)[]", value: value)
            }
       } else if let value = value as? NSNumber {
            components.append((st_escape(key), st_escape("\(value)")))
       } else if let bool = value as? Bool {
            components.append((st_escape(key), st_escape(bool ? "1" : "0")))
       } else {
            components.append((st_escape(key), st_escape("\(value)")))
       }
        
       return components
    }
    
    private static func st_escape(_ string: String) -> String {
        let generalDelimitersToEncode = ":#[]@"
        let subDelimitersToEncode = "!$&'()*+,;="
        var allowedCharacterSet = CharacterSet.urlQueryAllowed
        allowedCharacterSet.remove(charactersIn: "\(generalDelimitersToEncode)\(subDelimitersToEncode)")
        
        return string.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet) ?? string
    }
    
    // MARK: - JSON 编码
    public static func st_encodeJSON(_ parameters: [String: Any]) -> Data? {
        return try? JSONSerialization.data(withJSONObject: parameters)
    }
    
    // MARK: - Form Data 编码
    public static func st_encodeFormData(_ parameters: [String: Any]) -> Data? {
        let queryString = st_encodeURL(parameters)
        return queryString.data(using: .utf8)
    }
}

// MARK: - 统一响应处理
public struct STHTTPResponse {
    let data: Data?
    let response: URLResponse?
    let error: Error?
    
    // MARK: - HTTP 层面属性
    var statusCode: Int {
        if let httpResponse = response as? HTTPURLResponse {
            return httpResponse.statusCode
        }
        return 0
    }
    
    var headers: [String: String] {
        if let httpResponse = response as? HTTPURLResponse {
            return httpResponse.allHeaderFields as? [String: String] ?? [:]
        }
        return [:]
    }
    
    var isSuccess: Bool {
        return statusCode >= 200 && statusCode < 300
    }
    
    var json: Any? {
        guard let data = data else { return nil }
        return try? JSONSerialization.jsonObject(with: data)
    }
    
    var string: String? {
        guard let data = data else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    // MARK: - 业务层面属性
    var businessCode: Int {
        if let json = json as? [String: Any] {
            return json["code"] as? Int ?? statusCode
        }
        return statusCode
    }
    
    var businessMessage: String {
        if let json = json as? [String: Any] {
            return json["message"] as? String ?? ""
        }
        return ""
    }
    
    var businessData: Any? {
        if let json = json as? [String: Any] {
            return json["data"]
        }
        return json
    }
    
    var businessTimestamp: TimeInterval {
        if let json = json as? [String: Any] {
            return json["timestamp"] as? TimeInterval ?? 0
        }
        return 0
    }
    
    var businessIsSuccess: Bool {
        if let json = json as? [String: Any] {
            let code = json["code"] as? Int ?? statusCode
            return code == 200 || code == 0
        }
        return isSuccess
    }
    
    // MARK: - 分页信息
    var paginationInfo: (page: Int, pageSize: Int, totalCount: Int, totalPages: Int, hasNextPage: Bool, hasPreviousPage: Bool)? {
        guard let data = businessData as? [String: Any] else {
            return nil
        }
        
        let page = data["page"] as? Int ?? 1
        let pageSize = data["pageSize"] as? Int ?? 20
        let totalCount = data["totalCount"] as? Int ?? 0
        let totalPages = data["totalPages"] as? Int ?? (pageSize > 0 ? (totalCount + pageSize - 1) / pageSize : 0)
        let hasNextPage = data["hasNextPage"] as? Bool ?? (page < totalPages)
        let hasPreviousPage = data["hasPreviousPage"] as? Bool ?? (page > 1)
        
        return (page, pageSize, totalCount, totalPages, hasNextPage, hasPreviousPage)
    }
}

// MARK: - 错误类型
public enum STHTTPError: LocalizedError {
    case invalidURL
    case networkError(Error)
    case httpError(Int, String)
    case noData
    case encodingError
    case decodingError
    
    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的 URL"
        case .networkError(let error):
            return "网络错误: \(error.localizedDescription)"
        case .httpError(let code, let message):
            return "HTTP 错误 [\(code)]: \(message)"
        case .noData:
            return "无数据返回"
        case .encodingError:
            return "参数编码失败"
        case .decodingError:
            return "数据解码失败"
        }
    }
}

// MARK: - 网络状态监控
public enum STNetworkReachabilityStatus {
    case unknown
    case notReachable
    case reachable(connectionType: STConnectionType)
    
    public enum STConnectionType {
        case ethernetOrWiFi
        case cellular
    }
}

public class STNetworkReachabilityManager {
    private var pathMonitor: NWPathMonitor?
    private var monitorQueue = DispatchQueue(label: "NetworkMonitor")
    public var status = CurrentValueSubject<STNetworkReachabilityStatus, Never>(.unknown)
    
    public init() {
        setupReachability()
    }
    
    private func setupReachability() {
        pathMonitor = NWPathMonitor()
        pathMonitor?.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.updateStatus(path)
            }
        }
        pathMonitor?.start(queue: monitorQueue)
    }
    
    private func updateStatus(_ path: NWPath) {
        if path.status == .satisfied {
            if path.usesInterfaceType(.wifi) || path.usesInterfaceType(.wiredEthernet) {
                status.send(.reachable(connectionType: .ethernetOrWiFi))
            } else if path.usesInterfaceType(.cellular) {
                status.send(.reachable(connectionType: .cellular))
            } else {
                status.send(.reachable(connectionType: .ethernetOrWiFi))
            }
        } else {
            status.send(.notReachable)
        }
    }
    
    public func stopMonitoring() {
        pathMonitor?.cancel()
        pathMonitor = nil
    }
    
    deinit {
        stopMonitoring()
    }
}

// MARK: - 文件上传支持
public struct STUploadFile {
    let data: Data
    let fileName: String
    let mimeType: String
    let fieldName: String
    
    public init(data: Data, fileName: String, mimeType: String, fieldName: String = "file") {
        self.data = data
        self.fileName = fileName
        self.mimeType = mimeType
        self.fieldName = fieldName
    }
}

public struct STUploadProgress {
    let bytesUploaded: Int64
    let totalBytes: Int64
    let progress: Float
    
    public init(bytesUploaded: Int64, totalBytes: Int64) {
        self.bytesUploaded = bytesUploaded
        self.totalBytes = totalBytes
        self.progress = totalBytes > 0 ? Float(bytesUploaded) / Float(totalBytes) : 0.0
    }
}

// MARK: - 扩展 STParameterEncoder
extension STParameterEncoder {
    
    // MARK: - Multipart 编码
    public static func st_encodeMultipart(parameters: [String: Any], files: [STUploadFile]) -> Data? {
        let boundary = "Boundary-\(UUID().uuidString)"
        var body = Data()
        
        // 添加参数
        for (key, value) in parameters {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }
        
        // 添加文件
        for file in files {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(file.fieldName)\"; filename=\"\(file.fileName)\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: \(file.mimeType)\r\n\r\n".data(using: .utf8)!)
            body.append(file.data)
            body.append("\r\n".data(using: .utf8)!)
        }
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        return body
    }
}

open class STHTTPSession: NSObject {
    
    // MARK: - 属性
    public static let shared = STHTTPSession()
    
    // 全局默认配置
    public var defaultRequestConfig = STRequestConfig()
    public var defaultRequestHeaders = STRequestHeaders()
    
    // 网络状态监控
    public var networkReachability = STNetworkReachabilityManager()
    
    // Combine 订阅管理
    private var cancellables = Set<AnyCancellable>()
    
    // 当前请求的配置（每次请求时设置）
    private var currentRequestConfig: STRequestConfig?
    private var currentRequestHeaders: STRequestHeaders?
    
    private var currentRetryCount = 0
    private var currentRequest: URLRequest?
    private var currentCompletion: ((STHTTPResponse) -> Void)?
    
    // MARK: - 初始化
    private override init() {
        super.init()
        st_setupSession()
    }
    
    // MARK: - 设置
    private func st_setupSession() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = defaultRequestConfig.timeoutInterval
        configuration.timeoutIntervalForResource = defaultRequestConfig.timeoutInterval * 2
        configuration.allowsCellularAccess = defaultRequestConfig.allowsCellularAccess
        configuration.httpShouldUsePipelining = defaultRequestConfig.httpShouldUsePipelining
        configuration.networkServiceType = defaultRequestConfig.networkServiceType
        session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }
    
    private lazy var session: URLSession = {
        let configuration = URLSessionConfiguration.default
        return URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }()
    
    public func st_request(url: String,
                          method: STHTTPMethod = .get,
                          parameters: [String: Any]? = nil,
                          encodingType: STParameterEncoder.EncodingType = .json,
                          requestConfig: STRequestConfig? = nil,
                          requestHeaders: STRequestHeaders? = nil,
                          completion: @escaping (STHTTPResponse) -> Void) {
        
        guard let url = URL(string: url) else {
            let response = STHTTPResponse(data: nil, response: nil, error: STHTTPError.invalidURL)
            completion(response)
            return
        }
        let config = requestConfig ?? defaultRequestConfig
        let headers = requestHeaders ?? defaultRequestHeaders
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.timeoutInterval = config.timeoutInterval
        request.cachePolicy = config.cachePolicy
        request.allowsCellularAccess = config.allowsCellularAccess
        request.httpShouldHandleCookies = config.httpShouldHandleCookies
        request.httpShouldUsePipelining = config.httpShouldUsePipelining
        request.networkServiceType = config.networkServiceType
        let headerDict = headers.st_getHeaders()
        for (key, value) in headerDict {
            request.setValue(value, forHTTPHeaderField: key)
        }
        if let parameters = parameters {
            switch encodingType {
            case .url:
                if method == .get {
                    let queryString = STParameterEncoder.st_encodeURL(parameters)
                    if var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) {
                        urlComponents.query = queryString
                        request.url = urlComponents.url
                    }
                } else {
                    if let data = STParameterEncoder.st_encodeFormData(parameters) {
                        request.httpBody = data
                        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
                    }
                }
            case .json:
                if let data = STParameterEncoder.st_encodeJSON(parameters) {
                    request.httpBody = data
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                }
            case .formData:
                if let data = STParameterEncoder.st_encodeFormData(parameters) {
                    request.httpBody = data
                    request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
                }
            case .multipart:
                break
            }
        }
        st_executeRequest(request, completion: completion)
    }
    
    public func st_get(url: String,
                      parameters: [String: Any]? = nil,
                      requestConfig: STRequestConfig? = nil,
                      requestHeaders: STRequestHeaders? = nil,
                      completion: @escaping (STHTTPResponse) -> Void) {
        st_request(url: url, method: .get, parameters: parameters, encodingType: .url, requestConfig: requestConfig, requestHeaders: requestHeaders, completion: completion)
    }
    
    public func st_post(url: String,
                       parameters: [String: Any]? = nil,
                       encodingType: STParameterEncoder.EncodingType = .json,
                       requestConfig: STRequestConfig? = nil,
                       requestHeaders: STRequestHeaders? = nil,
                       completion: @escaping (STHTTPResponse) -> Void) {
        st_request(url: url, method: .post, parameters: parameters, encodingType: encodingType, requestConfig: requestConfig, requestHeaders: requestHeaders, completion: completion)
    }
    
    public func st_put(url: String,
                      parameters: [String: Any]? = nil,
                      encodingType: STParameterEncoder.EncodingType = .json,
                      requestConfig: STRequestConfig? = nil,
                      requestHeaders: STRequestHeaders? = nil,
                      completion: @escaping (STHTTPResponse) -> Void) {
        st_request(url: url, method: .put, parameters: parameters, encodingType: encodingType, requestConfig: requestConfig, requestHeaders: requestHeaders, completion: completion)
    }
    
    public func st_delete(url: String,
                         parameters: [String: Any]? = nil,
                         requestConfig: STRequestConfig? = nil,
                         requestHeaders: STRequestHeaders? = nil,
                         completion: @escaping (STHTTPResponse) -> Void) {
        st_request(url: url, method: .delete, parameters: parameters, encodingType: .url, requestConfig: requestConfig, requestHeaders: requestHeaders, completion: completion)
    }
    
    private func st_executeRequest(_ request: URLRequest, completion: @escaping (STHTTPResponse) -> Void) {
        currentRequest = request
        currentCompletion = completion
        currentRetryCount = 0
        
        st_performRequest(request, completion: completion)
    }
    
    private func st_performRequest(_ request: URLRequest, completion: @escaping (STHTTPResponse) -> Void) {
        let task = session.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.st_handleResponse(data: data, response: response, error: error, completion: completion)
            }
        }
        task.resume()
    }
    
    private func st_handleResponse(data: Data?, response: URLResponse?, error: Error?, completion: @escaping (STHTTPResponse) -> Void) {
        if let error = error {
            let httpResponse = STHTTPResponse(data: data, response: response, error: STHTTPError.networkError(error))
            self.st_handleError(httpResponse, completion: completion)
            return
        }
        
        if let httpResponse = response as? HTTPURLResponse {
            if httpResponse.statusCode < 200 || httpResponse.statusCode >= 300 {
                let error = STHTTPError.httpError(httpResponse.statusCode, "HTTP \(httpResponse.statusCode)")
                let httpResponse = STHTTPResponse(data: data, response: response, error: error)
                self.st_handleError(httpResponse, completion: completion)
                return
            }
        }
        let httpResponse = STHTTPResponse(data: data, response: response, error: nil)
        completion(httpResponse)
    }
    
    private func st_handleError(_ response: STHTTPResponse, completion: @escaping (STHTTPResponse) -> Void) {
        if currentRetryCount < defaultRequestConfig.retryCount {
            currentRetryCount += 1
            
            DispatchQueue.main.asyncAfter(deadline: .now() + defaultRequestConfig.retryDelay) { [weak self] in
                if let request = self?.currentRequest {
                    self?.st_performRequest(request, completion: completion)
                }
            }
        } else {
            completion(response)
        }
    }
    
    public func st_cancelAllRequests() {
        session.invalidateAndCancel()
        st_setupSession()
    }
    
    public func st_clearCache() {
        URLCache.shared.removeAllCachedResponses()
    }
}

// MARK: - URLSession 代理
extension STHTTPSession: URLSessionTaskDelegate {
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            let response = STHTTPResponse(data: nil, response: task.response, error: STHTTPError.networkError(error))
            currentCompletion?(response)
        }
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        completionHandler(request)
    }
}

// MARK: - 网络状态监控扩展
extension STHTTPSession {
    
    /// 网络是否可达
    public var isNetworkReachable: Bool {
        switch networkReachability.status.value {
        case .reachable:
            return true
        case .notReachable, .unknown:
            return false
        }
    }
    
    /// 检查网络状态
    public func st_checkNetworkStatus() -> STNetworkReachabilityStatus {
        return networkReachability.status.value
    }
    
    /// 等待网络可用
    public func st_waitForNetwork(completion: @escaping () -> Void) {
        if isNetworkReachable {
            completion()
        } else {
            networkReachability.status
                .filter { status in
                    if case .reachable = status {
                        return true
                    }
                    return false
                }
                .first()
                .sink { _ in
                    completion()
                }
                .store(in: &cancellables)
        }
    }
}

// MARK: - 文件上传、下载
extension STHTTPSession {
    
    public func st_upload(url: String,
                         parameters: [String: Any]? = nil,
                         files: [STUploadFile],
                         progress: ((STUploadProgress) -> Void)? = nil,
                         requestConfig: STRequestConfig? = nil,
                         requestHeaders: STRequestHeaders? = nil,
                         completion: @escaping (STHTTPResponse) -> Void) {
        
        guard let url = URL(string: url) else {
            let response = STHTTPResponse(data: nil, response: nil, error: STHTTPError.invalidURL)
            completion(response)
            return
        }
        let config = requestConfig ?? defaultRequestConfig
        let headers = requestHeaders ?? defaultRequestHeaders
        var request = URLRequest(url: url)
        request.httpMethod = STHTTPMethod.post.rawValue
        request.timeoutInterval = config.timeoutInterval
        let headerDict = headers.st_getHeaders()
        for (key, value) in headerDict {
            request.setValue(value, forHTTPHeaderField: key)
        }
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        if let bodyData = STParameterEncoder.st_encodeMultipart(parameters: parameters ?? [:], files: files) {
            request.httpBody = bodyData
        }
        st_executeUploadRequest(request, progress: progress, completion: completion)
    }
    
    private func st_executeUploadRequest(_ request: URLRequest,
                                       progress: ((STUploadProgress) -> Void)? = nil,
                                       completion: @escaping (STHTTPResponse) -> Void) {
        
        let task = session.uploadTask(with: request, from: request.httpBody) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.st_handleResponse(data: data, response: response, error: error, completion: completion)
            }
        }
        if let progress = progress {
            let observation = task.progress.observe(\.fractionCompleted) { progressValue, _ in
                let uploadProgress = STUploadProgress(
                    bytesUploaded: Int64(progressValue.fractionCompleted * Double(request.httpBody?.count ?? 0)),
                    totalBytes: Int64(request.httpBody?.count ?? 0)
                )
                DispatchQueue.main.async {
                    progress(uploadProgress)
                }
            }
            objc_setAssociatedObject(task, "progressObservation", observation, .OBJC_ASSOCIATION_RETAIN)
        }
        task.resume()
    }
    
    public func st_download(url: String,
                           progress: ((STUploadProgress) -> Void)? = nil,
                           requestConfig: STRequestConfig? = nil,
                           requestHeaders: STRequestHeaders? = nil,
                           completion: @escaping (URL?, STHTTPResponse) -> Void) {
        
        guard let url = URL(string: url) else {
            let response = STHTTPResponse(data: nil, response: nil, error: STHTTPError.invalidURL)
            completion(nil, response)
            return
        }
        let config = requestConfig ?? defaultRequestConfig
        let headers = requestHeaders ?? defaultRequestHeaders
        var request = URLRequest(url: url)
        request.timeoutInterval = config.timeoutInterval
        let headerDict = headers.st_getHeaders()
        for (key, value) in headerDict {
            request.setValue(value, forHTTPHeaderField: key)
        }
        st_executeDownloadRequest(request, progress: progress, completion: completion)
    }
    
    private func st_executeDownloadRequest(_ request: URLRequest,
                                         progress: ((STUploadProgress) -> Void)? = nil,
                                         completion: @escaping (URL?, STHTTPResponse) -> Void) {
        
        let task = session.downloadTask(with: request) { localURL, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    let httpResponse = STHTTPResponse(data: nil, response: response, error: STHTTPError.networkError(error))
                    completion(nil, httpResponse)
                } else if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
                        completion(localURL, STHTTPResponse(data: nil, response: response, error: nil))
                    } else {
                        let error = STHTTPError.httpError(httpResponse.statusCode, "HTTP \(httpResponse.statusCode)")
                        let httpResponse = STHTTPResponse(data: nil, response: response, error: error)
                        completion(nil, httpResponse)
                    }
                } else {
                    completion(localURL, STHTTPResponse(data: nil, response: response, error: nil))
                }
            }
        }
        if let progress = progress {
            let observation = task.progress.observe(\.fractionCompleted) { progressValue, _ in
                let downloadProgress = STUploadProgress(
                    bytesUploaded: Int64(progressValue.completedUnitCount),
                    totalBytes: Int64(progressValue.totalUnitCount)
                )
                DispatchQueue.main.async {
                    progress(downloadProgress)
                }
            }
            objc_setAssociatedObject(task, "progressObservation", observation, .OBJC_ASSOCIATION_RETAIN)
        }
        task.resume()
    }
    
    public func st_validateResponse(_ response: STHTTPResponse) -> Bool {
        return response.isSuccess
    }
    
    public func st_requestChain(url: String,
                               method: STHTTPMethod = .get,
                               parameters: [String: Any]? = nil,
                               encodingType: STParameterEncoder.EncodingType = .json,
                               validate: ((STHTTPResponse) -> Bool)? = nil,
                               completion: @escaping (STHTTPResponse) -> Void) {
        
        st_request(url: url, method: method, parameters: parameters, encodingType: encodingType) { response in
            if let validate = validate {
                if validate(response) {
                    completion(response)
                } else {
                    let error = STHTTPError.httpError(response.statusCode, "响应验证失败")
                    let failedResponse = STHTTPResponse(data: response.data, response: response.response, error: error)
                    completion(failedResponse)
                }
            } else {
                completion(response)
            }
        }
    }
}

// MARK: - 上传图片
public extension STHTTPSession {
    
    func st_uploadImage(url: String,
                       image: UIImage,
                       parameters: [String: Any]? = nil,
                       progress: ((STUploadProgress) -> Void)? = nil,
                       completion: @escaping (STHTTPResponse) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            let response = STHTTPResponse(data: nil, response: nil, error: STHTTPError.encodingError)
            completion(response)
            return
        }
        let uploadFile = STUploadFile(
            data: imageData,
            fileName: "image.jpg",
            mimeType: "image/jpeg"
        )
        st_upload(url: url, parameters: parameters, files: [uploadFile], progress: progress, completion: completion)
    }
    
    func st_uploadMultipleFiles(url: String,
                               parameters: [String: Any]? = nil,
                               files: [STUploadFile],
                               progress: ((STUploadProgress) -> Void)? = nil,
                               completion: @escaping (STHTTPResponse) -> Void) {
        st_upload(url: url, parameters: parameters, files: files, progress: progress, completion: completion)
    }
}

// MARK: - 响应扩展
public extension STHTTPResponse {
    
    /// 解码为指定类型
    func st_decode<T: Codable>(_ type: T.Type) -> T? {
        guard let data = data else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
    
    /// 获取响应头
    func st_getHeader(_ key: String) -> String? {
        return headers[key]
    }
    
    /// 检查是否为特定状态码
    func st_isStatusCode(_ code: Int) -> Bool {
        return statusCode == code
    }
    
    /// 检查是否为客户端错误
    var st_isClientError: Bool {
        return statusCode >= 400 && statusCode < 500
    }
    
    /// 检查是否为服务器错误
    var st_isServerError: Bool {
        return statusCode >= 500 && statusCode < 600
    }
    
    /// 获取分页信息
    var st_paginationInfo: (page: Int, pageSize: Int, totalCount: Int, totalPages: Int, hasNextPage: Bool, hasPreviousPage: Bool)? {
        return paginationInfo
    }
}
