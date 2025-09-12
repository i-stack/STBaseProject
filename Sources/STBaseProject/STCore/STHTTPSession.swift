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

// MARK: - HTTP 错误类型
public enum STHTTPError: Error, LocalizedError {
    case invalidURL
    case noData
    case decodingError
    case networkError(Error)
    case serverError(Int)
    case timeout
    case cancelled
    
    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .noData:
            return "No data received"
        case .decodingError:
            return "Data decoding error"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .serverError(let code):
            return "Server error: \(code)"
        case .timeout:
            return "Request timeout"
        case .cancelled:
            return "Request cancelled"
        }
    }
}

// MARK: - 网络可达性管理器
public class STNetworkReachabilityManager {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    public var currentStatus: STNetworkReachabilityStatus = .unknown
    
    public init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.currentStatus = self?.st_networkStatus(from: path) ?? .unknown
            }
        }
        monitor.start(queue: queue)
    }
    
    private func st_networkStatus(from path: NWPath) -> STNetworkReachabilityStatus {
        if path.status == .satisfied {
            if path.usesInterfaceType(.wifi) {
                return .reachableViaWiFi
            } else if path.usesInterfaceType(.cellular) {
                return .reachableViaCellular
            } else {
                return .reachableViaWiFi // 默认认为是 WiFi
            }
        } else {
            return .notReachable
        }
    }
    
    deinit {
        monitor.cancel()
    }
}

// MARK: - HTTP 会话管理器
open class STHTTPSession: NSObject {
    public static let shared = STHTTPSession()
    public var defaultRequestConfig = STRequestConfig()
    public var defaultRequestHeaders = STRequestHeaders()
    public var networkReachability = STNetworkReachabilityManager()
    private var cancellables = Set<AnyCancellable>()
    private var currentRequestConfig: STRequestConfig?
    private var currentRequestHeaders: STRequestHeaders?
    private var currentRetryCount = 0
    private var currentRequest: URLRequest?
    private var currentCompletion: ((STHTTPResponse) -> Void)?
    
    private override init() {
        super.init()
        st_setupSession()
    }
    
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
    
    // MARK: - 公共请求方法
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
        let request = st_buildRequest(url: url, method: method, parameters: parameters, 
                                    encodingType: encodingType, requestConfig: requestConfig, 
                                    requestHeaders: requestHeaders)
        currentRequestConfig = requestConfig ?? defaultRequestConfig
        currentRequestHeaders = requestHeaders ?? defaultRequestHeaders
        currentRequest = request
        currentCompletion = completion
        currentRetryCount = 0
        st_executeRequest(request, config: requestConfig ?? defaultRequestConfig, completion: completion)
    }
    
    // MARK: - 泛型请求方法（支持模型映射）
    public func st_request<T: Codable>(url: String,
                                      method: STHTTPMethod = .get,
                                      parameters: [String: Any]? = nil,
                                      encodingType: STParameterEncoder.EncodingType = .json,
                                      requestConfig: STRequestConfig? = nil,
                                      requestHeaders: STRequestHeaders? = nil,
                                      modelType: T.Type,
                                      completion: @escaping (STHTTPResponseWithModel<T>) -> Void) {
        
        guard let url = URL(string: url) else {
            let response = STHTTPResponseWithModel<T>(data: nil, response: nil, error: STHTTPError.invalidURL, model: nil)
            completion(response)
            return
        }
        let request = st_buildRequest(url: url, method: method, parameters: parameters, 
                                    encodingType: encodingType, requestConfig: requestConfig, 
                                    requestHeaders: requestHeaders)
        st_executeRequestWithModel(request, config: requestConfig ?? defaultRequestConfig, 
                                 modelType: modelType, completion: completion)
    }
    
    // MARK: - 构建请求的公共方法
    private func st_buildRequest(url: URL,
                               method: STHTTPMethod,
                               parameters: [String: Any]?,
                               encodingType: STParameterEncoder.EncodingType,
                               requestConfig: STRequestConfig?,
                               requestHeaders: STRequestHeaders?) -> URLRequest {
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
            var requestData: Data?
            switch encodingType {
            case .url:
                if method == .get {
                    let queryString = STParameterEncoder.st_encodeURL(parameters)
                    if var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) {
                        urlComponents.query = queryString
                        request.url = urlComponents.url
                    }
                } else {
                    requestData = STParameterEncoder.st_encodeFormData(parameters)
                    request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
                }
            case .json:
                requestData = STParameterEncoder.st_encodeJSON(parameters)
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            case .formData:
                requestData = STParameterEncoder.st_encodeFormData(parameters)
                request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            case .multipart:
                break
            }
            request.httpBody = requestData
        }
        return request
    }
    
    // MARK: - 执行请求
    private func st_executeRequest(_ request: URLRequest, config: STRequestConfig, completion: @escaping (STHTTPResponse) -> Void) {
        let task = session.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                let httpResponse = STHTTPResponse(data: data, response: response, error: error)
                if let self = self, self.st_shouldRetry(response: httpResponse, config: config) {
                    self.st_retryRequest(completion: completion)
                } else {
                    completion(httpResponse)
                }
            }
        }
        task.resume()
    }
    
    // MARK: - 执行泛型请求
    private func st_executeRequestWithModel<T: Codable>(_ request: URLRequest, 
                                                       config: STRequestConfig, 
                                                       modelType: T.Type, 
                                                       completion: @escaping (STHTTPResponseWithModel<T>) -> Void) {
        let task = session.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                var model: T?
                if let data = data {
                    do {
                        model = try JSONDecoder().decode(T.self, from: data)
                    } catch {
                        print("模型解析失败: \(error)")
                    }
                }
                let httpResponse = STHTTPResponseWithModel<T>(data: data, response: response, error: error, model: model)
                completion(httpResponse)
            }
        }
        task.resume()
    }
    
    // MARK: - 重试逻辑
    private func st_shouldRetry(response: STHTTPResponse, config: STRequestConfig) -> Bool {
        guard currentRetryCount < config.retryCount else { return false }
        if response.error != nil || (response.statusCode >= 500 && response.statusCode < 600) {
            return true
        }
        return false
    }
    
    private func st_retryRequest(completion: @escaping (STHTTPResponse) -> Void) {
        guard let request = currentRequest, let config = currentRequestConfig else {
            return
        }
        currentRetryCount += 1
        DispatchQueue.main.asyncAfter(deadline: .now() + config.retryDelay) { [weak self] in
            self?.st_executeRequest(request, config: config, completion: completion)
        }
    }
    
    // MARK: - 上传文件
    public func st_upload(url: String,
                         files: [STUploadFile],
                         parameters: [String: Any]? = nil,
                         requestConfig: STRequestConfig? = nil,
                         requestHeaders: STRequestHeaders? = nil,
                         progress: ((STUploadProgress) -> Void)? = nil,
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
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        var body = Data()
        for file in files {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(file.name)\"; filename=\"\(file.fileName)\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: \(file.mimeType)\r\n\r\n".data(using: .utf8)!)
            body.append(file.data)
            body.append("\r\n".data(using: .utf8)!)
        }
        if let parameters = parameters {
            for (key, value) in parameters {
                body.append("--\(boundary)\r\n".data(using: .utf8)!)
                body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
                body.append("\(value)\r\n".data(using: .utf8)!)
            }
        }
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body
        let headerDict = headers.st_getHeaders()
        for (key, value) in headerDict {
            request.setValue(value, forHTTPHeaderField: key)
        }
        let task = session.uploadTask(with: request, from: body) { data, response, error in
            DispatchQueue.main.async {
                let httpResponse = STHTTPResponse(data: data, response: response, error: error)
                completion(httpResponse)
            }
        }
        task.resume()
    }
    
    // MARK: - 网络状态检查
    public func st_checkNetworkStatus() -> STNetworkReachabilityStatus {
        return networkReachability.currentStatus
    }
}

// MARK: - URLSessionDelegate
extension STHTTPSession: URLSessionDelegate {
    public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        // SSL 证书验证逻辑可以在这里实现
        completionHandler(.performDefaultHandling, nil)
    }
}