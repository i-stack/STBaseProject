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
    public var headers: [String: String] = [:]
    public var showLoading: Bool = true
    public var showError: Bool = true
    
    // 新增：加密配置
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
        headers: [String: String] = [:],
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
        self.headers = headers
        self.showLoading = showLoading
        self.showError = showError
        self.enableEncryption = enableEncryption
        self.encryptionKey = encryptionKey
        self.enableRequestSigning = enableRequestSigning
        self.signingSecret = signingSecret
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

// MARK: - 统一响应处理
public struct STHTTPResponse {
    public let data: Data?
    public let response: URLResponse?
    public let error: Error?
    
    // MARK: - HTTP 层面属性
    public var statusCode: Int {
        if let httpResponse = response as? HTTPURLResponse {
            return httpResponse.statusCode
        }
        return 0
    }
    
    public var headers: [String: String] {
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
    
    public var isSuccess: Bool {
        return statusCode >= 200 && statusCode < 300
    }
    
    // MARK: - 数据解析
    public var json: Any? {
        guard let data = data else { return nil }
        return try? JSONSerialization.jsonObject(with: data)
    }
    
    public var string: String? {
        guard let data = data else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    // MARK: - 业务层面属性
    public var businessCode: Int {
        guard let json = json as? [String: Any],
              let code = json["code"] as? Int else { return -1 }
        return code
    }
    
    public var businessMessage: String {
        guard let json = json as? [String: Any],
              let message = json["message"] as? String else { return "" }
        return message
    }
    
    public var businessData: Any? {
        guard let json = json as? [String: Any] else { return nil }
        return json["data"]
    }
    
    public var businessTimestamp: TimeInterval {
        guard let json = json as? [String: Any],
              let timestamp = json["timestamp"] as? TimeInterval else { return 0 }
        return timestamp
    }
    
    public var businessIsSuccess: Bool {
        return businessCode == 200 || businessCode == 0
    }
    
    // MARK: - 分页信息
    public var paginationInfo: [String: Any]? {
        guard let json = json as? [String: Any],
              let pagination = json["pagination"] as? [String: Any] else { return nil }
        return pagination
    }
    
    public init(data: Data?, response: URLResponse?, error: Error?) {
        self.data = data
        self.response = response
        self.error = error
    }
}

// MARK: - 上传文件
public struct STUploadFile {
    public let data: Data
    public let name: String
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

// MARK: - 网络可达性状态
public enum STNetworkReachabilityStatus {
    case unknown
    case notReachable
    case reachableViaWiFi
    case reachableViaCellular
}
