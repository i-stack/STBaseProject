//
//  STHTTPSession.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2018/12/10.
//

import UIKit
import Network
import Foundation

public final class STParameterEncoder {

    public enum EncodingType {
        case url
        case json
        case formData
        case multipart
    }

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

    public static func st_encodeJSON(_ parameters: [String: Any]) -> Data? {
        return try? JSONSerialization.data(withJSONObject: parameters)
    }

    public static func st_encodeFormData(_ parameters: [String: Any]) -> Data? {
        let queryString = st_encodeURL(parameters)
        return queryString.data(using: .utf8)
    }
}

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
        case .invalidURL: return "Invalid URL"
        case .noData: return "No data received"
        case .decodingError: return "Data decoding error"
        case .networkError(let error): return "Network error: \(error.localizedDescription)"
        case .serverError(let code): return "Server error: \(code)"
        case .timeout: return "Request timeout"
        case .cancelled: return "Request cancelled"
        }
    }
}

public final class STNetworkReachabilityManager {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "STHTTPSession.Reachability")
    public private(set) var currentStatus: STNetworkReachabilityStatus = .unknown

    public init() {
        self.monitor.pathUpdateHandler = { [weak self] path in
            let status = Self.status(from: path)
            DispatchQueue.main.async { self?.currentStatus = status }
        }
        self.monitor.start(queue: self.queue)
    }

    private static func status(from path: NWPath) -> STNetworkReachabilityStatus {
        guard path.status == .satisfied else { return .notReachable }
        if path.usesInterfaceType(.wifi) { return .reachableViaWiFi }
        if path.usesInterfaceType(.cellular) { return .reachableViaCellular }
        return .reachableViaWiFi
    }

    deinit { self.monitor.cancel() }
}

open class STHTTPSession: NSObject {

    public static let shared = STHTTPSession()

    public var defaultRequestConfig: STRequestConfig
    public var defaultRequestHeaders: STRequestHeaders
    public let networkReachability: STNetworkReachabilityManager
    public var sslPinningConfig: STSSLPinningConfig
    public let interceptor: STInterceptor?
    public let eventMonitor: STCompositeEventMonitor

    private var urlSession: URLSession!
    private let delegateQueue: OperationQueue
    private let stateLock = NSLock()
    private var requestsByTaskID: [Int: STRequest] = [:]
    private var dataBuffersByTaskID: [Int: Data] = [:]
    private var contextByTaskID: [Int: TaskContext] = [:]
    private var pendingDownloadResults: [Int: Result<URL, Error>] = [:]

    private struct TaskContext {
        let interceptor: STRequestRetrier?
        let config: STRequestConfig
        let originalURLRequest: URLRequest
        let restart: () -> Void
    }

    @inline(__always)
    private func withStateLock<T>(_ action: () -> T) -> T {
        self.stateLock.lock()
        defer { self.stateLock.unlock() }
        return action()
    }

    public init(
        configuration: URLSessionConfiguration = .default,
        defaultRequestConfig: STRequestConfig = STRequestConfig(),
        defaultRequestHeaders: STRequestHeaders = STRequestHeaders(),
        interceptor: STInterceptor? = nil,
        eventMonitors: [STEventMonitor] = [],
        sslPinningConfig: STSSLPinningConfig = STSSLPinningConfig(enabled: false)
    ) {
        self.defaultRequestConfig = defaultRequestConfig
        self.defaultRequestHeaders = defaultRequestHeaders
        self.interceptor = interceptor
        self.eventMonitor = STCompositeEventMonitor(monitors: eventMonitors)
        self.networkReachability = STNetworkReachabilityManager()
        self.sslPinningConfig = sslPinningConfig

        configuration.httpCookieStorage = nil
        configuration.httpCookieAcceptPolicy = .never
        configuration.timeoutIntervalForRequest = defaultRequestConfig.timeoutInterval
        configuration.timeoutIntervalForResource = defaultRequestConfig.timeoutInterval * 2
        configuration.allowsCellularAccess = defaultRequestConfig.allowsCellularAccess
        configuration.httpShouldUsePipelining = defaultRequestConfig.httpShouldUsePipelining
        configuration.networkServiceType = defaultRequestConfig.networkServiceType

        let queue = OperationQueue()
        queue.name = "STHTTPSession.delegateQueue"
        queue.maxConcurrentOperationCount = 1
        self.delegateQueue = queue

        super.init()
        self.urlSession = URLSession(configuration: configuration, delegate: self, delegateQueue: self.delegateQueue)
    }

    deinit {
        self.urlSession.invalidateAndCancel()
    }

    @discardableResult
    public func request(
        _ urlString: String,
        method: STHTTPMethod = .get,
        parameters: [String: Any]? = nil,
        encoding: STParameterEncoder.EncodingType = .json,
        headers: STRequestHeaders? = nil,
        interceptor: STInterceptor? = nil,
        requestConfig: STRequestConfig? = nil
    ) -> STDataRequest {
        let config = requestConfig ?? self.defaultRequestConfig
        let dataRequest = STDataRequest(maxRetryCount: config.retryCount, retryDelay: config.retryDelay)
        dataRequest.session = self

        Task { [weak self] in
            await self?.startData(
                dataRequest,
                urlString: urlString,
                method: method,
                parameters: parameters,
                encoding: encoding,
                headers: headers ?? self?.defaultRequestHeaders ?? STRequestHeaders(),
                interceptor: interceptor,
                config: config
            )
        }
        return dataRequest
    }

    @discardableResult
    public func upload(
        _ urlString: String,
        files: [STUploadFile],
        parameters: [String: Any]? = nil,
        headers: STRequestHeaders? = nil,
        interceptor: STInterceptor? = nil,
        requestConfig: STRequestConfig? = nil
    ) -> STUploadRequest {
        let config = requestConfig ?? self.defaultRequestConfig
        let uploadRequest = STUploadRequest(maxRetryCount: config.retryCount, retryDelay: config.retryDelay)
        uploadRequest.session = self

        Task { [weak self] in
            await self?.startUpload(
                uploadRequest,
                urlString: urlString,
                files: files,
                parameters: parameters,
                headers: headers ?? self?.defaultRequestHeaders ?? STRequestHeaders(),
                interceptor: interceptor,
                config: config
            )
        }
        return uploadRequest
    }

    @discardableResult
    public func download(
        _ urlString: String,
        to destinationURL: URL,
        method: STHTTPMethod = .get,
        parameters: [String: Any]? = nil,
        encoding: STParameterEncoder.EncodingType = .url,
        headers: STRequestHeaders? = nil,
        interceptor: STInterceptor? = nil,
        options: STDownloadOptions = .default,
        resumeData: Data? = nil,
        requestConfig: STRequestConfig? = nil
    ) -> STDownloadRequest {
        let config = requestConfig ?? self.defaultRequestConfig
        let destination: STDownloadRequest.Destination = { _, _ in destinationURL }
        let downloadRequest = STDownloadRequest(
            destination: destination,
            downloadOptions: options,
            maxRetryCount: config.retryCount,
            retryDelay: config.retryDelay
        )
        downloadRequest.session = self
        if let resumeData = resumeData {
            downloadRequest.didReceiveResumeData(resumeData)
        }

        Task { [weak self] in
            await self?.startDownload(
                downloadRequest,
                urlString: urlString,
                method: method,
                parameters: parameters,
                encoding: encoding,
                headers: headers ?? self?.defaultRequestHeaders ?? STRequestHeaders(),
                interceptor: interceptor,
                config: config,
                resumeData: resumeData
            )
        }
        return downloadRequest
    }

    @discardableResult
    public func stream(
        _ urlString: String,
        method: STHTTPMethod = .get,
        parameters: [String: Any]? = nil,
        encoding: STParameterEncoder.EncodingType = .url,
        headers: STRequestHeaders? = nil,
        interceptor: STInterceptor? = nil,
        requestConfig: STRequestConfig? = nil
    ) -> STDataStreamRequest {
        let config = requestConfig ?? self.defaultRequestConfig
        let streamRequest = STDataStreamRequest(maxRetryCount: config.retryCount, retryDelay: config.retryDelay)
        streamRequest.session = self

        Task { [weak self] in
            await self?.startStream(
                streamRequest,
                urlString: urlString,
                method: method,
                parameters: parameters,
                encoding: encoding,
                headers: headers ?? self?.defaultRequestHeaders ?? STRequestHeaders(),
                interceptor: interceptor,
                config: config
            )
        }
        return streamRequest
    }

    private func startData(
        _ request: STDataRequest,
        urlString: String,
        method: STHTTPMethod,
        parameters: [String: Any]?,
        encoding: STParameterEncoder.EncodingType,
        headers: STRequestHeaders,
        interceptor: STInterceptor?,
        config: STRequestConfig
    ) async {
        guard !request.isCancelled else { return }
        guard let url = URL(string: urlString) else {
            request.didComplete(with: STHTTPResponse(data: nil, response: nil, error: STHTTPError.invalidURL))
            return
        }
        let initial = self.buildURLRequest(url: url, method: method, parameters: parameters, encoding: encoding, headers: headers, config: config)
        await self.executeData(request, initial: initial, interceptor: interceptor, config: config)
    }

    private func executeData(
        _ request: STDataRequest,
        initial: URLRequest,
        interceptor: STInterceptor?,
        config: STRequestConfig
    ) async {
        guard !request.isCancelled else { return }
        request.urlRequest = initial
        self.eventMonitor.request(request, didCreateURLRequest: initial)

        let adapted: URLRequest
        do {
            adapted = try await self.adapt(initial, interceptor: interceptor)
        } catch {
            request.didComplete(with: STHTTPResponse(data: nil, response: nil, error: error))
            return
        }
        if adapted != initial {
            self.eventMonitor.request(request, didAdaptURLRequest: initial, to: adapted)
        }
        request.urlRequest = adapted

        let task = self.urlSession.dataTask(with: adapted)
        request.task = task
        let restart: () -> Void = { [weak self] in
            Task { await self?.executeData(request, initial: initial, interceptor: interceptor, config: config) }
        }
        self.register(request, task: task, interceptor: interceptor, config: config, originalURLRequest: initial, restart: restart)
        self.logOutgoing(adapted, requestKind: "data")
        request.resume()
    }

    private func startUpload(
        _ request: STUploadRequest,
        urlString: String,
        files: [STUploadFile],
        parameters: [String: Any]?,
        headers: STRequestHeaders,
        interceptor: STInterceptor?,
        config: STRequestConfig
    ) async {
        guard !request.isCancelled else { return }
        guard let url = URL(string: urlString) else {
            request.didComplete(with: STHTTPResponse(data: nil, response: nil, error: STHTTPError.invalidURL))
            return
        }
        let boundary = "Boundary-\(UUID().uuidString)"
        let body = self.buildMultipartBody(boundary: boundary, files: files, parameters: parameters)
        var initial = URLRequest(url: url)
        initial.httpMethod = STHTTPMethod.post.rawValue
        self.applyConfig(config, to: &initial)
        self.applyHeaders(headers, to: &initial)
        initial.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        await self.executeUpload(request, initial: initial, body: body, interceptor: interceptor, config: config)
    }

    private func executeUpload(
        _ request: STUploadRequest,
        initial: URLRequest,
        body: Data,
        interceptor: STInterceptor?,
        config: STRequestConfig
    ) async {
        guard !request.isCancelled else { return }
        request.urlRequest = initial
        self.eventMonitor.request(request, didCreateURLRequest: initial)

        let adapted: URLRequest
        do {
            adapted = try await self.adapt(initial, interceptor: interceptor)
        } catch {
            request.didComplete(with: STHTTPResponse(data: nil, response: nil, error: error))
            return
        }
        if adapted != initial {
            self.eventMonitor.request(request, didAdaptURLRequest: initial, to: adapted)
        }
        request.urlRequest = adapted

        let task = self.urlSession.uploadTask(with: adapted, from: body)
        request.task = task
        let restart: () -> Void = { [weak self] in
            Task { await self?.executeUpload(request, initial: initial, body: body, interceptor: interceptor, config: config) }
        }
        self.register(request, task: task, interceptor: interceptor, config: config, originalURLRequest: initial, restart: restart)
        self.logOutgoing(adapted, requestKind: "upload")
        request.resume()
    }

    private func startDownload(
        _ request: STDownloadRequest,
        urlString: String,
        method: STHTTPMethod,
        parameters: [String: Any]?,
        encoding: STParameterEncoder.EncodingType,
        headers: STRequestHeaders,
        interceptor: STInterceptor?,
        config: STRequestConfig,
        resumeData: Data? = nil
    ) async {
        guard !request.isCancelled else { return }
        guard let url = URL(string: urlString) else {
            request.didComplete(with: .failure(STHTTPError.invalidURL))
            return
        }
        let initial = self.buildURLRequest(url: url, method: method, parameters: parameters, encoding: encoding, headers: headers, config: config)
        await self.executeDownload(request, initial: initial, interceptor: interceptor, config: config, resumeData: resumeData)
    }

    private func executeDownload(
        _ request: STDownloadRequest,
        initial: URLRequest,
        interceptor: STInterceptor?,
        config: STRequestConfig,
        resumeData: Data? = nil
    ) async {
        guard !request.isCancelled else { return }
        request.urlRequest = initial
        self.eventMonitor.request(request, didCreateURLRequest: initial)

        let adapted: URLRequest
        do {
            adapted = try await self.adapt(initial, interceptor: interceptor)
        } catch {
            request.didComplete(with: .failure(error))
            return
        }
        if adapted != initial {
            self.eventMonitor.request(request, didAdaptURLRequest: initial, to: adapted)
        }
        request.urlRequest = adapted

        let task: URLSessionDownloadTask
        if let resumeData = resumeData {
            task = self.urlSession.downloadTask(withResumeData: resumeData)
        } else {
            task = self.urlSession.downloadTask(with: adapted)
        }
        request.task = task
        let restart: () -> Void = { [weak self, weak request] in
            Task {
                guard let self = self, let request = request else { return }
                await self.executeDownload(request, initial: initial, interceptor: interceptor, config: config, resumeData: request.resumeData)
            }
        }
        self.register(request, task: task, interceptor: interceptor, config: config, originalURLRequest: initial, restart: restart)
        self.logOutgoing(adapted, requestKind: "download")
        request.resume()
    }

    private func startStream(
        _ request: STDataStreamRequest,
        urlString: String,
        method: STHTTPMethod,
        parameters: [String: Any]?,
        encoding: STParameterEncoder.EncodingType,
        headers: STRequestHeaders,
        interceptor: STInterceptor?,
        config: STRequestConfig
    ) async {
        guard !request.isCancelled else { return }
        guard let url = URL(string: urlString) else {
            request.didFinish(error: STHTTPError.invalidURL)
            return
        }
        var initial = self.buildURLRequest(url: url, method: method, parameters: parameters, encoding: encoding, headers: headers, config: config)
        // 流式响应不应被本地缓存
        initial.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        await self.executeStream(request, initial: initial, interceptor: interceptor, config: config)
    }

    private func executeStream(
        _ request: STDataStreamRequest,
        initial: URLRequest,
        interceptor: STInterceptor?,
        config: STRequestConfig
    ) async {
        guard !request.isCancelled else { return }
        request.urlRequest = initial
        self.eventMonitor.request(request, didCreateURLRequest: initial)

        let adapted: URLRequest
        do {
            adapted = try await self.adapt(initial, interceptor: interceptor)
        } catch {
            request.didFinish(error: error)
            return
        }
        if adapted != initial {
            self.eventMonitor.request(request, didAdaptURLRequest: initial, to: adapted)
        }
        request.urlRequest = adapted

        let task = self.urlSession.dataTask(with: adapted)
        request.task = task
        let restart: () -> Void = { [weak self, weak request] in
            Task {
                guard let self = self, let request = request else { return }
                await self.executeStream(request, initial: initial, interceptor: interceptor, config: config)
            }
        }
        self.register(request, task: task, interceptor: interceptor, config: config, originalURLRequest: initial, restart: restart)
        self.logOutgoing(adapted, requestKind: "stream")
        request.resume()
    }

    private func buildURLRequest(
        url: URL,
        method: STHTTPMethod,
        parameters: [String: Any]?,
        encoding: STParameterEncoder.EncodingType,
        headers: STRequestHeaders,
        config: STRequestConfig
    ) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        self.applyConfig(config, to: &request)
        self.applyHeaders(headers, to: &request)

        guard let parameters = parameters else { return request }

        switch encoding {
        case .url:
            if method == .get {
                let query = STParameterEncoder.st_encodeURL(parameters)
                if var components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
                    components.query = query
                    request.url = components.url
                }
            } else {
                request.httpBody = STParameterEncoder.st_encodeFormData(parameters)
                request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            }
        case .json:
            request.httpBody = STParameterEncoder.st_encodeJSON(parameters)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        case .formData:
            request.httpBody = STParameterEncoder.st_encodeFormData(parameters)
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        case .multipart:
            break
        }
        return request
    }

    private func applyConfig(_ config: STRequestConfig, to request: inout URLRequest) {
        request.timeoutInterval = config.timeoutInterval
        request.cachePolicy = config.cachePolicy
        request.allowsCellularAccess = config.allowsCellularAccess
        request.httpShouldHandleCookies = config.httpShouldHandleCookies
        request.httpShouldUsePipelining = config.httpShouldUsePipelining
        request.networkServiceType = config.networkServiceType
    }

    private func applyHeaders(_ headers: STRequestHeaders, to request: inout URLRequest) {
        for (key, value) in headers.st_getHeaders() {
            request.setValue(value, forHTTPHeaderField: key)
        }
    }

    private func buildMultipartBody(boundary: String, files: [STUploadFile], parameters: [String: Any]?) -> Data {
        var body = Data()
        let crlf = "\r\n".data(using: .utf8)!
        for file in files {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(file.name)\"; filename=\"\(file.fileName)\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: \(file.mimeType)\r\n\r\n".data(using: .utf8)!)
            body.append(file.data)
            body.append(crlf)
        }
        if let parameters = parameters {
            for (key, value) in parameters {
                body.append("--\(boundary)\r\n".data(using: .utf8)!)
                body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
                body.append("\(value)\r\n".data(using: .utf8)!)
            }
        }
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        return body
    }

    private func adapt(_ urlRequest: URLRequest, interceptor: STRequestAdapter?) async throws -> URLRequest {
        if let interceptor = interceptor {
            return try await interceptor.adapt(urlRequest, for: self)
        }
        if let session = self.interceptor {
            return try await session.adapt(urlRequest, for: self)
        }
        return urlRequest
    }

    private func resolveRetrier(_ requestInterceptor: STRequestRetrier?, config: STRequestConfig) -> STRequestRetrier? {
        if let r = requestInterceptor { return r }
        if let r = self.interceptor { return r }
        if config.retryCount > 0 {
            return STRetryPolicy(retryLimit: config.retryCount, exponentialBackoffBase: 1, exponentialBackoffScale: config.retryDelay)
        }
        return nil
    }

    // MARK: - 任务注册

    private func register(
        _ request: STRequest,
        task: URLSessionTask,
        interceptor: STRequestRetrier?,
        config: STRequestConfig,
        originalURLRequest: URLRequest,
        restart: @escaping () -> Void
    ) {
        let retrier = self.resolveRetrier(interceptor, config: config)
        let context = TaskContext(interceptor: retrier, config: config, originalURLRequest: originalURLRequest, restart: restart)
        self.withStateLock {
            self.requestsByTaskID[task.taskIdentifier] = request
            self.contextByTaskID[task.taskIdentifier] = context
        }
    }

    private func consume(taskID: Int) -> (STRequest?, TaskContext?, Data?) {
        return self.withStateLock {
            let request = self.requestsByTaskID.removeValue(forKey: taskID)
            let context = self.contextByTaskID.removeValue(forKey: taskID)
            let buffer = self.dataBuffersByTaskID.removeValue(forKey: taskID)
            return (request, context, buffer)
        }
    }

    private func peek(taskID: Int) -> STRequest? {
        return self.withStateLock {
            self.requestsByTaskID[taskID]
        }
    }

    // MARK: - 重试
    private func handleCompletion(
        request: STRequest,
        context: TaskContext,
        response: HTTPURLResponse?,
        data: Data?,
        error: Error?,
        downloadResult: Result<URL, Error>?
    ) {
        let httpError = self.classifyError(error: error, response: response)
        // 流式请求：一旦已经吐出过字节，重试就没有意义（已经回调出去的 chunk 不能撤回）。
        let streamHasBytes = (request as? STDataStreamRequest)?.hasReceivedFirstByte == true
        if let httpError = httpError, let retrier = context.interceptor, !request.isCancelled, !streamHasBytes {
            request.incrementRetryCount()
            Task { [weak self] in
                guard let strongSelf = self else { return }
                let result = await retrier.retry(request, for: strongSelf, dueTo: httpError)
                switch result {
                case .retry:
                    context.restart()
                case .retryWithDelay(let delay):
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    context.restart()
                case .doNotRetry:
                    self?.deliver(request: request, response: response, data: data, error: httpError, downloadResult: downloadResult)
                case .doNotRetryWithError(let newError):
                    self?.deliver(request: request, response: response, data: data, error: newError, downloadResult: downloadResult.map { _ in .failure(newError) })
                }
            }
            return
        }
        self.deliver(request: request, response: response, data: data, error: httpError ?? error, downloadResult: downloadResult)
    }

    private func classifyError(error: Error?, response: HTTPURLResponse?) -> Error? {
        if let error = error {
            let nsError = error as NSError
            if nsError.domain == NSURLErrorDomain {
                switch nsError.code {
                case NSURLErrorTimedOut: return STHTTPError.timeout
                case NSURLErrorCancelled: return STHTTPError.cancelled
                default: return STHTTPError.networkError(error)
                }
            }
            return error
        }
        if let response = response, response.statusCode >= 400 {
            return STHTTPError.serverError(response.statusCode)
        }
        return nil
    }

    private func deliver(
        request: STRequest,
        response: URLResponse?,
        data: Data?,
        error: Error?,
        downloadResult: Result<URL, Error>?
    ) {
        self.logCompletion(request: request, response: response, data: data, error: error, downloadResult: downloadResult)
        if let dataRequest = request as? STDataRequest {
            dataRequest.didComplete(with: STHTTPResponse(data: data, response: response, error: error))
            self.eventMonitor.requestDidFinish(dataRequest)
        } else if let uploadRequest = request as? STUploadRequest {
            uploadRequest.didComplete(with: STHTTPResponse(data: data, response: response, error: error))
            self.eventMonitor.requestDidFinish(uploadRequest)
        } else if let streamRequest = request as? STDataStreamRequest {
            streamRequest.didFinish(error: error)
            self.eventMonitor.requestDidFinish(streamRequest)
        } else if let downloadRequest = request as? STDownloadRequest {
            if let result = downloadResult {
                downloadRequest.didComplete(with: result)
            } else if let error = error {
                downloadRequest.didComplete(with: .failure(error))
            } else {
                downloadRequest.didComplete(with: .failure(STHTTPError.noData))
            }
            self.eventMonitor.requestDidFinish(downloadRequest)
        }
    }

    public func st_checkNetworkStatus() -> STNetworkReachabilityStatus {
        return self.networkReachability.currentStatus
    }
}

// MARK: - URLSessionDelegate
extension STHTTPSession: URLSessionDelegate, URLSessionDataDelegate, URLSessionTaskDelegate, URLSessionDownloadDelegate {
    public func urlSession(_ session: URLSession,
                           didReceive challenge: URLAuthenticationChallenge,
                           completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.performDefaultHandling, nil)
            return
        }
        guard self.sslPinningConfig.enabled else {
            completionHandler(.performDefaultHandling, nil)
            return
        }
        if self.sslPinningConfig.allowInvalidCertificates {
            completionHandler(.useCredential, URLCredential(trust: serverTrust))
            return
        }
        if self.sslPinningConfig.validateHost {
            let host = challenge.protectionSpace.host as CFString
            let policy = SecPolicyCreateSSL(true, host)
            SecTrustSetPolicies(serverTrust, policy)
        }
        var trustError: CFError?
        let trusted = SecTrustEvaluateWithError(serverTrust, &trustError)
        guard trusted else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        if self.sslPinningConfig.certificates.isEmpty {
            completionHandler(.useCredential, URLCredential(trust: serverTrust))
            return
        }
        let serverCerts = self.serverCertificates(from: serverTrust)
        for serverCert in serverCerts {
            if self.sslPinningConfig.certificates.contains(serverCert) {
                completionHandler(.useCredential, URLCredential(trust: serverTrust))
                return
            }
        }
        completionHandler(.cancelAuthenticationChallenge, nil)
    }

    private func serverCertificates(from trust: SecTrust) -> [Data] {
        guard let chain = SecTrustCopyCertificateChain(trust) as? [SecCertificate] else { return [] }
        return chain.map { SecCertificateCopyData($0) as Data }
    }
    }

    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        if let request = self.peek(taskID: dataTask.taskIdentifier),
           let httpResponse = response as? HTTPURLResponse {
            self.eventMonitor.request(request, didReceiveHTTPResponse: httpResponse)
            if let stream = request as? STDataStreamRequest {
                stream.didReceiveHTTPResponse(httpResponse)
            }
        }
        completionHandler(.allow)
    }

    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        if let stream = self.peek(taskID: dataTask.taskIdentifier) as? STDataStreamRequest {
            stream.didReceive(data)
            return
        }

        let request: STRequest? = self.withStateLock {
            var buffer = self.dataBuffersByTaskID[dataTask.taskIdentifier] ?? Data()
            buffer.append(data)
            self.dataBuffersByTaskID[dataTask.taskIdentifier] = buffer
            return self.requestsByTaskID[dataTask.taskIdentifier]
        }

        if let dataRequest = request as? STDataRequest {
            self.eventMonitor.request(dataRequest, didReceiveData: data)
        }
    }

    public func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        guard let request = self.peek(taskID: task.taskIdentifier) as? STUploadRequest else { return }
        let progress = STUploadProgress(bytesWritten: totalBytesSent, totalBytes: totalBytesExpectedToSend)
        request.didUpdateProgress(progress)
        self.eventMonitor.request(request, didSendBytes: bytesSent, totalBytesSent: totalBytesSent, totalBytesExpected: totalBytesExpectedToSend)
    }

    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard let request = self.peek(taskID: downloadTask.taskIdentifier) as? STDownloadRequest else { return }
        let progress = STDownloadProgress(bytesWritten: bytesWritten, totalBytesWritten: totalBytesWritten, totalBytesExpectedToWrite: totalBytesExpectedToWrite)
        request.didUpdateProgress(progress)
        self.eventMonitor.request(request, didWriteData: bytesWritten, totalWritten: totalBytesWritten, totalExpected: totalBytesExpectedToWrite)
    }

    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let request = self.peek(taskID: downloadTask.taskIdentifier) as? STDownloadRequest else { return }
        guard let httpResponse = downloadTask.response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            return
        }
        let destination = request.destination?(location, httpResponse) ?? location
        let options = request.downloadOptions
        let result: Result<URL, Error>
        do {
            if options.createIntermediateDirectories {
                let dir = destination.deletingLastPathComponent()
                if !FileManager.default.fileExists(atPath: dir.path) {
                    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
                }
            }
            if options.removePreviousFile, FileManager.default.fileExists(atPath: destination.path) {
                try FileManager.default.removeItem(at: destination)
            }
            try FileManager.default.moveItem(at: location, to: destination)
            result = .success(destination)
        } catch {
            result = .failure(error)
        }
        self.withStateLock {
            self.dataBuffersByTaskID[downloadTask.taskIdentifier] = nil
            self.pendingDownloadResults[downloadTask.taskIdentifier] = result
        }
    }

    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        let taskID = task.taskIdentifier
        if let nsError = error as NSError?,
           let resumeData = nsError.userInfo[NSURLSessionDownloadTaskResumeData] as? Data,
           let downloadRequest = self.peek(taskID: taskID) as? STDownloadRequest {
            downloadRequest.didReceiveResumeData(resumeData)
        }
        let pendingDownload = self.withStateLock {
            self.pendingDownloadResults.removeValue(forKey: taskID)
        }
        let (request, context, buffer) = self.consume(taskID: taskID)
        guard let request = request, let context = context else { return }
        let httpResponse = task.response as? HTTPURLResponse
        self.handleCompletion(request: request, context: context, response: httpResponse, data: buffer, error: error, downloadResult: pendingDownload)
    }
}

// MARK: - cURL 调试输出
/// 接口日志策略。默认 `.off`，需要时显式开启：
/// `STHTTPSession.shared.logging = .default`
public struct STHTTPLogConfig {
    public enum Verbosity {
        /// 完全关闭。
        case off
        /// 仅 method + url + status + 耗时。
        case basic
        /// + 请求 / 响应头。
        case headers
        /// + 请求体（cURL 形式）+ 失败响应体（截断）。
        case body
    }

    public var verbosity: Verbosity
    /// 单条日志中 body 的最大字节数，超出截断。
    public var maxBodyLength: Int
    /// 这些请求头的值会被替换为 ***。默认空集合 —— cURL 可直接复制到终端复现请求。
    /// 上线/灰度环境可自行加入 `["Authorization", "Cookie", ...]`。
    public var redactedHeaders: Set<String>
    /// 成功响应是否打印响应体（默认 false，避免 PII 落盘）。
    public var logResponseBodyOnSuccess: Bool

    public static let off = STHTTPLogConfig(verbosity: .off)
    public static let `default` = STHTTPLogConfig(verbosity: .body)

    public init(
        verbosity: Verbosity,
        maxBodyLength: Int = 4096,
        redactedHeaders: Set<String> = [],
        logResponseBodyOnSuccess: Bool = false
    ) {
        self.verbosity = verbosity
        self.maxBodyLength = maxBodyLength
        self.redactedHeaders = redactedHeaders
        self.logResponseBodyOnSuccess = logResponseBodyOnSuccess
    }
}

public extension URLRequest {
    /// 生成 cURL 命令字符串
    /// - Parameters:
    ///   - redactedHeaders: 这些 header 的值替换为 ***。大小写不敏感。
    ///   - maxBodyLength: body 最大长度，超出截断。
    func st_cURLDescription(redactedHeaders: Set<String> = [], maxBodyLength: Int = 4096) -> String {
        guard let url = self.url else { return "$ curl <invalid request>" }
        var lines: [String] = ["$ curl -v"]
        let method = self.httpMethod ?? "GET"
        if method != "GET" {
            lines.append("-X \(method)")
        }
        let redactedLower = Set(redactedHeaders.map { $0.lowercased() })
        if let headers = self.allHTTPHeaderFields, !headers.isEmpty {
            for (key, value) in headers.sorted(by: { $0.key < $1.key }) {
                let display = redactedLower.contains(key.lowercased()) ? "***" : value
                let escaped = display.replacingOccurrences(of: "\"", with: "\\\"")
                lines.append("-H \"\(key): \(escaped)\"")
            }
        }
        if let body = self.httpBody, !body.isEmpty {
            let slice = body.prefix(maxBodyLength)
            if let str = String(data: slice, encoding: .utf8) {
                let escaped = str
                    .replacingOccurrences(of: "\\", with: "\\\\")
                    .replacingOccurrences(of: "\"", with: "\\\"")
                let suffix = body.count > maxBodyLength ? "...<truncated \(body.count - maxBodyLength) bytes>" : ""
                lines.append("-d \"\(escaped)\(suffix)\"")
            } else {
                lines.append("--data-binary <\(body.count) bytes>")
            }
        }
        lines.append("\"\(url.absoluteString)\"")
        return lines.joined(separator: " \\\n\t")
    }
}

public extension STHTTPSession {
    /// 接口日志开关。默认关闭；建议在 App 启动时根据环境配置：
    /// `#if DEBUG STHTTPSession.shared.logging = .default #endif`
    var logging: STHTTPLogConfig {
        get { STHTTPSessionLogStorage.shared.config(for: self) }
        set { STHTTPSessionLogStorage.shared.set(newValue, for: self) }
    }
}

/// 用关联存储承载 logging 配置，避免在 STHTTPSession 主体里再加可变状态。
final class STHTTPSessionLogStorage {
    static let shared = STHTTPSessionLogStorage()
    private let lock = NSLock()
    private var configs: [ObjectIdentifier: STHTTPLogConfig] = [:]

    func config(for session: STHTTPSession) -> STHTTPLogConfig {
        self.lock.lock(); defer { self.lock.unlock() }
        return self.configs[ObjectIdentifier(session)] ?? .off
    }

    func set(_ config: STHTTPLogConfig, for session: STHTTPSession) {
        self.lock.lock()
        self.configs[ObjectIdentifier(session)] = config
        self.lock.unlock()
    }
}

extension STHTTPSession {

    /// 在 adapt 完成、即将提交 task 之前调用。
    func logOutgoing(_ urlRequest: URLRequest, requestKind: String) {
        let config = self.logging
        guard config.verbosity != .off else { return }
        let url = urlRequest.url?.absoluteString ?? ""
        let method = urlRequest.httpMethod ?? "GET"
        let metadata: STLogger.Metadata = [
            "kind": requestKind,
            "method": method,
            "url": url
        ]
        let body: String
        switch config.verbosity {
        case .off:
            return
        case .basic:
            body = "→ [\(method)] \(url)"
        case .headers:
            var lines = ["→ [\(method)] \(url)"]
            let redacted = Set(config.redactedHeaders.map { $0.lowercased() })
            for (k, v) in (urlRequest.allHTTPHeaderFields ?? [:]).sorted(by: { $0.key < $1.key }) {
                let display = redacted.contains(k.lowercased()) ? "***" : v
                lines.append("  \(k): \(display)")
            }
            body = lines.joined(separator: "\n")
        case .body:
            body = urlRequest.st_cURLDescription(redactedHeaders: config.redactedHeaders, maxBodyLength: config.maxBodyLength)
        }
        STPersistentLog(body, level: .debug, metadata: metadata)
    }

    /// 在 deliver 之前调用，统一打印请求结果。
    func logCompletion(request: STRequest, response: URLResponse?, data: Data?, error: Error?, downloadResult: Result<URL, Error>?) {
        let config = self.logging
        guard config.verbosity != .off else { return }
        let httpResponse = response as? HTTPURLResponse
        let status = httpResponse?.statusCode ?? -1
        let url = request.urlRequest?.url?.absoluteString ?? httpResponse?.url?.absoluteString ?? ""
        let method = request.urlRequest?.httpMethod ?? "GET"
        let isFailure = error != nil || (httpResponse.map { $0.statusCode >= 400 } ?? true)

        var metadata: STLogger.Metadata = [
            "method": method,
            "url": url,
            "status": String(status)
        ]
        if let data = data {
            metadata["bytes"] = String(data.count)
        }
        if case .success(let fileURL)? = downloadResult {
            metadata["file"] = fileURL.path
        }

        var lines: [String] = ["← [\(status >= 0 ? String(status) : "ERR")] \(method) \(url)"]

        if config.verbosity == .headers || config.verbosity == .body, let httpResponse = httpResponse {
            let redacted = Set(config.redactedHeaders.map { $0.lowercased() })
            for (rawKey, rawValue) in httpResponse.allHeaderFields {
                guard let k = rawKey as? String, let v = rawValue as? String else { continue }
                let display = redacted.contains(k.lowercased()) ? "***" : v
                lines.append("  \(k): \(display)")
            }
        }

        if let error = error {
            lines.append("  error: \(error.localizedDescription)")
            metadata["error"] = String(describing: error)
        }

        if config.verbosity == .body {
            // 失败：截断后落盘；成功：默认不打印 body，除非用户显式开启
            let shouldLogBody = isFailure || config.logResponseBodyOnSuccess
            if shouldLogBody, let data = data, !data.isEmpty {
                let slice = data.prefix(config.maxBodyLength)
                if let str = String(data: slice, encoding: .utf8) {
                    let suffix = data.count > config.maxBodyLength ? "...<truncated \(data.count - config.maxBodyLength) bytes>" : ""
                    lines.append("  body: \(str)\(suffix)")
                } else {
                    lines.append("  body: <\(data.count) bytes binary>")
                }
            }
        }

        let level: STLogLevel = isFailure ? .error : .info
        STPersistentLog(lines.joined(separator: "\n"), level: level, metadata: metadata)
    }
}
