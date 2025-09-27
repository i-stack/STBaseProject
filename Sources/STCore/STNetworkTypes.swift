//
//  STNetworkTypes.swift
//  STBaseProject
//
//  Created by stack on 2018/12/10.
//

import Foundation
import UIKit

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
    public var retryCount: Int = 0
    public var retryDelay: TimeInterval = 1.0
    public var allowsCellularAccess: Bool = true
    public var httpShouldHandleCookies: Bool = true
    public var httpShouldUsePipelining: Bool = true
    public var timeoutInterval: TimeInterval = 30
    public var cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy
    public var networkServiceType: URLRequest.NetworkServiceType = .default
    public var showLoading: Bool = true
    public var showError: Bool = true

    public var enableEncryption: Bool = false
    public var encryptionKey: String?
    public var enableRequestSigning: Bool = false
    public var signingSecret: String?

    public init(
        retryCount: Int = 0,
        retryDelay: TimeInterval = 1.0,
        timeoutInterval: TimeInterval = 30,
        allowsCellularAccess: Bool = true,
        httpShouldHandleCookies: Bool = true,
        httpShouldUsePipelining: Bool = true,
        networkServiceType: URLRequest.NetworkServiceType = .default,
        cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy,
        showLoading: Bool = true,
        showError: Bool = true,
        enableEncryption: Bool = false,
        encryptionKey: String? = nil,
        enableRequestSigning: Bool = false,
        signingSecret: String? = nil) {
        self.cachePolicy = cachePolicy
        self.retryCount = retryCount
        self.retryDelay = retryDelay
        self.timeoutInterval = timeoutInterval
        self.networkServiceType = networkServiceType
        self.allowsCellularAccess = allowsCellularAccess
        self.httpShouldHandleCookies = httpShouldHandleCookies
        self.httpShouldUsePipelining = httpShouldUsePipelining
        self.showLoading = showLoading
        self.showError = showError
        self.enableEncryption = enableEncryption
        self.encryptionKey = encryptionKey
        self.enableRequestSigning = enableRequestSigning
        self.signingSecret = signingSecret
    }
}

// MARK: - 请求头管理
public struct STRequestHeaders {
    private var headers: [String: String]
    
    public init(headers: [String: String] = [:]) {
        self.headers = headers
    }
    
    public mutating func st_setHeader(_ value: String, forKey key: String) {
        headers[key] = value
    }
    
    public mutating func st_setHeaders(_ newHeaders: [String: String]) {
        for (key, value) in newHeaders {
            headers[key] = value
        }
    }
    
    public mutating func st_removeHeader(forKey key: String) {
        headers.removeValue(forKey: key)
    }
    
    public mutating func st_clearHeaders() {
        headers.removeAll()
    }
    
    public func st_getHeaders() -> [String: String] {
        return headers
    }
    
    /// 设置自定义认证方式
    public mutating func st_setAuthorization(_ token: String, type: STAuthorizationType) {
        switch type {
        case .bearer:
            st_setHeader("Bearer \(token)", forKey: "Authorization")
        case .basic:
            st_setHeader("Basic \(token)", forKey: "Authorization")
        case .custom(let prefix):
            st_setHeader("\(prefix) \(token)", forKey: "Authorization")
        case .tokenOnly:
            st_setHeader(token, forKey: "Authorization")
        }
    }
    
    /// 设置自定义认证头
    public mutating func st_setCustomAuthorization(_ value: String) {
        st_setHeader(value, forKey: "Authorization")
    }
    
    public mutating func st_setContentType(_ contentType: String) {
        st_setHeader(contentType, forKey: "Content-Type")
    }
    
    public mutating func st_setAccept(_ accept: String) {
        st_setHeader(accept, forKey: "Accept")
    }
    
    public mutating func st_setUserAgent(_ userAgent: String) {
        st_setHeader(userAgent, forKey: "User-Agent")
    }
}

// MARK: - HTTP 响应基础协议
public protocol STHTTPResponseProtocol {
    var data: Data? { get }
    var response: URLResponse? { get }
    var error: Error? { get }
}

// MARK: - HTTP 响应扩展
public extension STHTTPResponseProtocol {
    
    var statusCode: Int {
        if let httpResponse = response as? HTTPURLResponse {
            return httpResponse.statusCode
        }
        return 0
    }
    
    var headers: [String: String] {
        if let httpResponse = response as? HTTPURLResponse {
            var result: [String: String] = [:]
            for (key, value) in httpResponse.allHeaderFields {
                if let stringKey = key as? String, let stringValue = value as? String {
                    result[stringKey] = stringValue
                }
            }
            return result
        }
        return [:]
    }
    
    var isSuccess: Bool {
        guard let httpResponse = response as? HTTPURLResponse else { return false }
        return httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 && error == nil
    }
    
    var isNetworkError: Bool {
        return response == nil || error != nil
    }
    
    var isHTTPError: Bool {
        guard let httpResponse = response as? HTTPURLResponse else { return false }
        return httpResponse.statusCode >= 400
    }
    
    var hasData: Bool {
        return data != nil && !(data?.isEmpty ?? true)
    }
    
    var json: Any? {
        guard let data = data else { return nil }
        return try? JSONSerialization.jsonObject(with: data)
    }
    
    var string: String? {
        guard let data = data else { return nil }
        return String(data: data, encoding: .utf8)
    }
}

// MARK: - 统一响应处理
public struct STHTTPResponse: STHTTPResponseProtocol {
    public let data: Data?
    public let response: URLResponse?
    public let error: Error?
    
    public init(data: Data?, response: URLResponse?, error: Error?) {
        self.data = data
        self.response = response
        self.error = error
    }
}

// MARK: - 泛型响应处理
public struct STHTTPResponseWithModel<T: Codable>: STHTTPResponseProtocol {
    public let data: Data?
    public let response: URLResponse?
    public let error: Error?
    public let model: T?
    
    public init(data: Data?, response: URLResponse?, error: Error?, model: T? = nil) {
        self.data = data
        self.response = response
        self.error = error
        self.model = model
    }
}

// MARK: - 上传文件
public struct STUploadFile {
    public let data: Data
    public let name: String // 服务器定义：比如 file, jumped 等等
    public let fileName: String
    public let mimeType: String
    
    public init(data: Data, name: String, fileName: String, mimeType: String) {
        self.data = data
        self.name = name
        self.fileName = fileName
        self.mimeType = mimeType
    }
}

// MARK: - 上传进度
public struct STUploadProgress {
    public let bytesWritten: Int64
    public let totalBytes: Int64
    public let progress: Float
    
    public init(bytesWritten: Int64, totalBytes: Int64) {
        self.bytesWritten = bytesWritten
        self.totalBytes = totalBytes
        self.progress = totalBytes > 0 ? Float(bytesWritten) / Float(totalBytes) : 0.0
    }
}

// MARK: - 认证类型
public enum STAuthorizationType {
    case bearer
    case basic
    case custom(String)  // 自定义前缀，如 "Token"
    case tokenOnly       // 只发送 token，不加前缀
}

// MARK: - 网络可达性状态
public enum STNetworkReachabilityStatus {
    case unknown
    case notReachable
    case reachableViaWiFi
    case reachableViaCellular
}
