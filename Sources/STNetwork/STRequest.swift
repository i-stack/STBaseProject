//
//  STRequest.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2018/12/10.
//

import Foundation

open class STRequest {

    private let stateLock = NSLock()
    private var _state: STRequestState = .initialized

    public var state: STRequestState {
        self.stateLock.lock()
        defer { self.stateLock.unlock() }
        return self._state
    }

    public var isCancelled: Bool { self.state == .cancelled }
    public var isFinished: Bool { self.state == .finished }
    public var isResumed: Bool { self.state == .resumed }

    var urlRequest: URLRequest?
    var task: URLSessionTask?

    private(set) var retryCount: Int = 0
    let maxRetryCount: Int
    let retryDelay: TimeInterval

    weak var session: STHTTPSession?

    init(maxRetryCount: Int = 0, retryDelay: TimeInterval = 1.0) {
        self.maxRetryCount = maxRetryCount
        self.retryDelay = retryDelay
    }

    func transition(to newState: STRequestState) {
        self.stateLock.lock()
        let old = self._state
        self._state = newState
        self.stateLock.unlock()
        guard old != newState else { return }
        self.session?.eventMonitor.requestDidTransition(self, from: old, to: newState)
    }

    func incrementRetryCount() {
        self.stateLock.lock()
        self.retryCount += 1
        self.stateLock.unlock()
    }

    @discardableResult
    public func cancel() -> Self {
        self.stateLock.lock()
        guard self._state != .cancelled && self._state != .finished else {
            self.stateLock.unlock()
            return self
        }
        self._state = .cancelled
        self.stateLock.unlock()
        self.task?.cancel()
        self.session?.eventMonitor.requestDidCancel(self)
        return self
    }

    @discardableResult
    public func suspend() -> Self {
        self.stateLock.lock()
        guard self._state == .resumed else {
            self.stateLock.unlock()
            return self
        }
        self._state = .suspended
        self.stateLock.unlock()
        self.task?.suspend()
        self.session?.eventMonitor.requestDidSuspend(self)
        return self
    }

    @discardableResult
    public func resume() -> Self {
        self.stateLock.lock()
        guard self._state == .initialized || self._state == .suspended else {
            self.stateLock.unlock()
            return self
        }
        self._state = .resumed
        self.stateLock.unlock()
        self.task?.resume()
        self.session?.eventMonitor.requestDidResume(self)
        return self
    }
}

public final class STDataRequest: STRequest {

    public typealias ResponseHandler = (STHTTPResponse) -> Void

    private let handlersLock = NSLock()
    private var completionHandlers: [ResponseHandler] = []
    private var _response: STHTTPResponse?

    func didComplete(with response: STHTTPResponse) {
        self.handlersLock.lock()
        self._response = response
        let handlers = self.completionHandlers
        self.completionHandlers.removeAll()
        self.handlersLock.unlock()

        self.transition(to: .finished)
        handlers.forEach { $0(response) }
    }

    @discardableResult
    public func response(
        queue: DispatchQueue = .main,
        completionHandler: @escaping ResponseHandler
    ) -> Self {
        let wrapper: ResponseHandler = { resp in queue.async { completionHandler(resp) } }
        self.handlersLock.lock()
        if let existing = self._response {
            self.handlersLock.unlock()
            queue.async { completionHandler(existing) }
        } else {
            self.completionHandlers.append(wrapper)
            self.handlersLock.unlock()
        }
        return self
    }

    @discardableResult
    public func responseData(
        queue: DispatchQueue = .main,
        completionHandler: @escaping (Result<Data, Error>) -> Void
    ) -> Self {
        return self.response(queue: queue) { resp in
            if let error = resp.error {
                completionHandler(.failure(error))
            } else if let data = resp.data, !data.isEmpty {
                completionHandler(.success(data))
            } else {
                completionHandler(.failure(STHTTPError.noData))
            }
        }
    }

    @discardableResult
    public func responseString(
        queue: DispatchQueue = .main,
        encoding: String.Encoding = .utf8,
        completionHandler: @escaping (Result<String, Error>) -> Void
    ) -> Self {
        return self.responseData(queue: queue) { result in
            switch result {
            case .success(let data):
                guard let string = String(data: data, encoding: encoding) else {
                    completionHandler(.failure(STHTTPError.decodingError))
                    return
                }
                completionHandler(.success(string))
            case .failure(let error):
                completionHandler(.failure(error))
            }
        }
    }

    @discardableResult
    public func responseDecodable<T: Decodable>(
        of type: T.Type = T.self,
        queue: DispatchQueue = .main,
        decoder: JSONDecoder = JSONDecoder(),
        completionHandler: @escaping (Result<T, Error>) -> Void
    ) -> Self {
        return self.responseData(queue: queue) { result in
            switch result {
            case .success(let data):
                do {
                    completionHandler(.success(try decoder.decode(T.self, from: data)))
                } catch {
                    completionHandler(.failure(STHTTPError.decodingError))
                }
            case .failure(let error):
                completionHandler(.failure(error))
            }
        }
    }

    public func serializingData() async throws -> Data {
        try await withTaskCancellationHandler(
            operation: {
                try await withCheckedThrowingContinuation { continuation in
                    self.responseData { continuation.resume(with: $0) }
                }
            },
            onCancel: { self.cancel() }
        )
    }

    public func serializingString(encoding: String.Encoding = .utf8) async throws -> String {
        try await withTaskCancellationHandler(
            operation: {
                try await withCheckedThrowingContinuation { continuation in
                    self.responseString(encoding: encoding) { continuation.resume(with: $0) }
                }
            },
            onCancel: { self.cancel() }
        )
    }

    public func serializingDecodable<T: Decodable>(
        _ type: T.Type,
        decoder: JSONDecoder = JSONDecoder()
    ) async throws -> T {
        try await withTaskCancellationHandler(
            operation: {
                try await withCheckedThrowingContinuation { continuation in
                    self.responseDecodable(of: type, decoder: decoder) { continuation.resume(with: $0) }
                }
            },
            onCancel: { self.cancel() }
        )
    }
}

public final class STUploadRequest: STRequest {

    public typealias ProgressHandler = (STUploadProgress) -> Void
    public typealias ResponseHandler = (STHTTPResponse) -> Void

    private let handlersLock = NSLock()
    private var progressHandlers: [ProgressHandler] = []
    private var completionHandlers: [ResponseHandler] = []
    private var _response: STHTTPResponse?

    func didUpdateProgress(_ progress: STUploadProgress) {
        self.handlersLock.lock()
        let handlers = self.progressHandlers
        self.handlersLock.unlock()
        DispatchQueue.main.async { handlers.forEach { $0(progress) } }
    }

    func didComplete(with response: STHTTPResponse) {
        self.handlersLock.lock()
        self._response = response
        let handlers = self.completionHandlers
        self.completionHandlers.removeAll()
        self.handlersLock.unlock()

        self.transition(to: .finished)
        handlers.forEach { $0(response) }
    }

    @discardableResult
    public func uploadProgress(
        queue: DispatchQueue = .main,
        handler: @escaping ProgressHandler
    ) -> Self {
        self.handlersLock.lock()
        self.progressHandlers.append({ p in queue.async { handler(p) } })
        self.handlersLock.unlock()
        return self
    }

    @discardableResult
    public func response(
        queue: DispatchQueue = .main,
        completionHandler: @escaping ResponseHandler
    ) -> Self {
        let wrapper: ResponseHandler = { resp in queue.async { completionHandler(resp) } }
        self.handlersLock.lock()
        if let existing = self._response {
            self.handlersLock.unlock()
            queue.async { completionHandler(existing) }
        } else {
            self.completionHandlers.append(wrapper)
            self.handlersLock.unlock()
        }
        return self
    }

    @discardableResult
    public func responseDecodable<T: Decodable>(
        of type: T.Type = T.self,
        queue: DispatchQueue = .main,
        decoder: JSONDecoder = JSONDecoder(),
        completionHandler: @escaping (Result<T, Error>) -> Void
    ) -> Self {
        return self.response(queue: queue) { resp in
            if let error = resp.error {
                completionHandler(.failure(error))
                return
            }
            guard let data = resp.data, !data.isEmpty else {
                completionHandler(.failure(STHTTPError.noData))
                return
            }
            do {
                completionHandler(.success(try decoder.decode(T.self, from: data)))
            } catch {
                completionHandler(.failure(STHTTPError.decodingError))
            }
        }
    }

    public func serializingResponse() async throws -> STHTTPResponse {
        try await withTaskCancellationHandler(
            operation: {
                try await withCheckedThrowingContinuation { continuation in
                    self.response { resp in
                        if let error = resp.error {
                            continuation.resume(throwing: error)
                        } else {
                            continuation.resume(returning: resp)
                        }
                    }
                }
            },
            onCancel: { self.cancel() }
        )
    }
}

public final class STDownloadRequest: STRequest {

    public typealias ProgressHandler = (STDownloadProgress) -> Void
    public typealias Destination = (URL, HTTPURLResponse) -> URL
    public typealias CompletionHandler = (Result<URL, Error>) -> Void

    private let handlersLock = NSLock()
    private var progressHandlers: [ProgressHandler] = []
    private var completionHandlers: [CompletionHandler] = []
    private var _result: Result<URL, Error>?

    private(set) var destination: Destination?
    private(set) var downloadOptions: STDownloadOptions

    private let resumeLock = NSLock()
    private var _resumeData: Data?

    /// 上一次失败/取消产生的 resumeData，可用于下次断点续传。
    public var resumeData: Data? {
        self.resumeLock.lock()
        defer { self.resumeLock.unlock() }
        return self._resumeData
    }

    func didReceiveResumeData(_ data: Data) {
        self.resumeLock.lock()
        self._resumeData = data
        self.resumeLock.unlock()
    }

    init(
        destination: Destination? = nil,
        downloadOptions: STDownloadOptions = .default,
        maxRetryCount: Int = 0,
        retryDelay: TimeInterval = 1.0
    ) {
        self.destination = destination
        self.downloadOptions = downloadOptions
        super.init(maxRetryCount: maxRetryCount, retryDelay: retryDelay)
    }

    /// 取消并请求 URLSession 生成 resumeData，便于稍后续传。
    /// resumeData 既会回调给 handler，也会保存到 `self.resumeData`。
    @discardableResult
    public func cancel(byProducingResumeData handler: @escaping (Data?) -> Void) -> Self {
        guard let task = self.task as? URLSessionDownloadTask, !self.isCancelled, !self.isFinished else {
            handler(self.resumeData)
            return self
        }
        task.cancel(byProducingResumeData: { [weak self] data in
            if let data = data { self?.didReceiveResumeData(data) }
            handler(data)
        })
        self.transition(to: .cancelled)
        self.session?.eventMonitor.requestDidCancel(self)
        return self
    }

    func didUpdateProgress(_ progress: STDownloadProgress) {
        self.handlersLock.lock()
        let handlers = self.progressHandlers
        self.handlersLock.unlock()
        DispatchQueue.main.async { handlers.forEach { $0(progress) } }
    }

    func didComplete(with result: Result<URL, Error>) {
        self.handlersLock.lock()
        self._result = result
        let handlers = self.completionHandlers
        self.completionHandlers.removeAll()
        self.handlersLock.unlock()

        self.transition(to: .finished)
        handlers.forEach { $0(result) }
    }

    @discardableResult
    public func downloadProgress(
        queue: DispatchQueue = .main,
        handler: @escaping ProgressHandler
    ) -> Self {
        self.handlersLock.lock()
        self.progressHandlers.append({ p in queue.async { handler(p) } })
        self.handlersLock.unlock()
        return self
    }

    @discardableResult
    public func response(
        queue: DispatchQueue = .main,
        completionHandler: @escaping CompletionHandler
    ) -> Self {
        let wrapper: CompletionHandler = { result in queue.async { completionHandler(result) } }
        self.handlersLock.lock()
        if let existing = self._result {
            self.handlersLock.unlock()
            queue.async { completionHandler(existing) }
        } else {
            self.completionHandlers.append(wrapper)
            self.handlersLock.unlock()
        }
        return self
    }

    public func serializingURL() async throws -> URL {
        try await withTaskCancellationHandler(
            operation: {
                try await withCheckedThrowingContinuation { continuation in
                    self.response { continuation.resume(with: $0) }
                }
            },
            onCancel: { self.cancel() }
        )
    }
}

// MARK: - Server-Sent Event

public struct STServerSentEvent: Sendable {
    public let id: String?
    public let event: String?
    public let data: String
    public let retry: Int?

    public init(id: String? = nil, event: String? = nil, data: String, retry: Int? = nil) {
        self.id = id
        self.event = event
        self.data = data
        self.retry = retry
    }
}

enum STSSEParser {

    /// 从缓冲区中提取所有完整的 SSE 消息（以 \n\n 或 \r\n\r\n 分帧），
    /// 已消费的字节会从缓冲区中移除。
    static func parse(buffer: inout Data) -> [STServerSentEvent] {
        var events: [STServerSentEvent] = []
        let lf = "\n\n".data(using: .utf8)!
        let crlf = "\r\n\r\n".data(using: .utf8)!
        while true {
            let a = buffer.range(of: lf)
            let b = buffer.range(of: crlf)
            let end: Range<Data.Index>?
            if let a = a, let b = b {
                end = a.lowerBound < b.lowerBound ? a : b
            } else {
                end = a ?? b
            }
            guard let r = end else { break }
            let messageData = buffer.subdata(in: 0..<r.lowerBound)
            buffer.removeSubrange(0..<r.upperBound)
            if let event = self.parseMessage(messageData) {
                events.append(event)
            }
        }
        return events
    }

    private static func parseMessage(_ data: Data) -> STServerSentEvent? {
        guard let string = String(data: data, encoding: .utf8), !string.isEmpty else { return nil }
        var id: String?
        var name: String?
        var dataLines: [String] = []
        var retry: Int?
        for raw in string.split(separator: "\n", omittingEmptySubsequences: false) {
            var line = String(raw)
            if line.hasSuffix("\r") { line.removeLast() }
            if line.isEmpty || line.hasPrefix(":") { continue }
            let field: String
            var value: String
            if let colon = line.firstIndex(of: ":") {
                field = String(line[..<colon])
                value = String(line[line.index(after: colon)...])
                if value.hasPrefix(" ") { value.removeFirst() }
            } else {
                field = line
                value = ""
            }
            switch field {
            case "id": id = value
            case "event": name = value
            case "data": dataLines.append(value)
            case "retry": retry = Int(value)
            default: break
            }
        }
        guard !dataLines.isEmpty || id != nil || name != nil || retry != nil else { return nil }
        return STServerSentEvent(id: id, event: name, data: dataLines.joined(separator: "\n"), retry: retry)
    }
}

// MARK: - Data Stream Request

public final class STDataStreamRequest: STRequest {

    public typealias DataHandler = (Data) -> Void
    public typealias EventHandler = (STServerSentEvent) -> Void
    public typealias CompletionHandler = (Error?) -> Void

    private struct Sink<T> {
        let queue: DispatchQueue
        let handler: (T) -> Void
    }

    private let handlersLock = NSLock()
    private var dataHandlers: [Sink<Data>] = []
    private var eventHandlers: [Sink<STServerSentEvent>] = []
    private var completionHandlers: [Sink<Error?>] = []
    private var dataContinuations: [AsyncThrowingStream<Data, Error>.Continuation] = []
    private var eventContinuations: [AsyncThrowingStream<STServerSentEvent, Error>.Continuation] = []
    private var sseBuffer = Data()
    private var _receivedFirstByte = false
    private var _httpResponse: HTTPURLResponse?
    private var _isFinished = false
    private var _terminalError: Error?

    /// 是否已收到首字节。流式请求一旦开始吐数据，就不应再被自动重试。
    public var hasReceivedFirstByte: Bool {
        self.handlersLock.lock()
        defer { self.handlersLock.unlock() }
        return self._receivedFirstByte
    }

    public var httpResponse: HTTPURLResponse? {
        self.handlersLock.lock()
        defer { self.handlersLock.unlock() }
        return self._httpResponse
    }

    func didReceiveHTTPResponse(_ response: HTTPURLResponse) {
        self.handlersLock.lock()
        self._httpResponse = response
        self.handlersLock.unlock()
    }

    func didReceive(_ chunk: Data) {
        self.handlersLock.lock()
        self._receivedFirstByte = true
        let dataSinks = self.dataHandlers
        let eventSinks = self.eventHandlers
        let dataConts = self.dataContinuations
        let eventConts = self.eventContinuations
        var events: [STServerSentEvent] = []
        if !eventSinks.isEmpty || !eventConts.isEmpty {
            self.sseBuffer.append(chunk)
            events = STSSEParser.parse(buffer: &self.sseBuffer)
        }
        self.handlersLock.unlock()

        dataSinks.forEach { sink in sink.queue.async { sink.handler(chunk) } }
        for cont in dataConts { cont.yield(chunk) }
        for event in events {
            eventSinks.forEach { sink in sink.queue.async { sink.handler(event) } }
            for cont in eventConts { cont.yield(event) }
        }
    }

    func didFinish(error: Error?) {
        self.handlersLock.lock()
        guard !self._isFinished else {
            self.handlersLock.unlock()
            return
        }
        self._isFinished = true
        self._terminalError = error
        let cSinks = self.completionHandlers
        let dataConts = self.dataContinuations
        let eventConts = self.eventContinuations
        self.completionHandlers.removeAll()
        self.dataContinuations.removeAll()
        self.eventContinuations.removeAll()
        self.handlersLock.unlock()

        self.transition(to: .finished)
        cSinks.forEach { sink in sink.queue.async { sink.handler(error) } }
        for cont in dataConts {
            if let error = error { cont.finish(throwing: error) } else { cont.finish() }
        }
        for cont in eventConts {
            if let error = error { cont.finish(throwing: error) } else { cont.finish() }
        }
    }

    @discardableResult
    public func onData(queue: DispatchQueue = .main, handler: @escaping DataHandler) -> Self {
        self.handlersLock.lock()
        if !self._isFinished {
            self.dataHandlers.append(Sink(queue: queue, handler: handler))
        }
        self.handlersLock.unlock()
        return self
    }

    @discardableResult
    public func onEvent(queue: DispatchQueue = .main, handler: @escaping EventHandler) -> Self {
        self.handlersLock.lock()
        if !self._isFinished {
            self.eventHandlers.append(Sink(queue: queue, handler: handler))
        }
        self.handlersLock.unlock()
        return self
    }

    @discardableResult
    public func onComplete(queue: DispatchQueue = .main, handler: @escaping CompletionHandler) -> Self {
        self.handlersLock.lock()
        if self._isFinished {
            let error = self._terminalError
            self.handlersLock.unlock()
            queue.async { handler(error) }
            return self
        }
        self.completionHandlers.append(Sink(queue: queue, handler: handler))
        self.handlersLock.unlock()
        return self
    }

    public func bytes() -> AsyncThrowingStream<Data, Error> {
        return AsyncThrowingStream { continuation in
            self.handlersLock.lock()
            if self._isFinished {
                let error = self._terminalError
                self.handlersLock.unlock()
                if let error = error { continuation.finish(throwing: error) } else { continuation.finish() }
                return
            }
            self.dataContinuations.append(continuation)
            self.handlersLock.unlock()
            continuation.onTermination = { [weak self] _ in self?.cancel() }
        }
    }

    public func events() -> AsyncThrowingStream<STServerSentEvent, Error> {
        return AsyncThrowingStream { continuation in
            self.handlersLock.lock()
            if self._isFinished {
                let error = self._terminalError
                self.handlersLock.unlock()
                if let error = error { continuation.finish(throwing: error) } else { continuation.finish() }
                return
            }
            self.eventContinuations.append(continuation)
            self.handlersLock.unlock()
            continuation.onTermination = { [weak self] _ in self?.cancel() }
        }
    }
}
