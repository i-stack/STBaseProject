//
//  STRequest.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2018/12/10.
//

import Combine
import Foundation

private final class STCancellableBox {
    private let lock = NSLock()
    private var storage: AnyCancellable?

    func set(_ cancellable: AnyCancellable) {
        self.lock.lock()
        self.storage = cancellable
        self.lock.unlock()
    }

    func cancelAndClear() {
        self.lock.lock()
        let cancellable = self.storage
        self.storage = nil
        self.lock.unlock()
        cancellable?.cancel()
    }

    func clear() {
        self.lock.lock()
        self.storage = nil
        self.lock.unlock()
    }
}

public class STRequest {

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

    public init(maxRetryCount: Int = 0, retryDelay: TimeInterval = 1.0) {
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

public class STDataRequest: STRequest {

    private let responseSubject = CurrentValueSubject<STHTTPResponse?, Never>(nil)

    public var responsePublisher: AnyPublisher<STHTTPResponse, Never> {
        self.responseSubject
            .compactMap { $0 }
            .first()
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    public var dataPublisher: AnyPublisher<Data, Error> {
        self.responsePublisher.tryMap { resp -> Data in
            if let error = resp.error { throw error }
            guard let data = resp.data, !data.isEmpty else { throw STHTTPError.noData }
            return data
        }.eraseToAnyPublisher()
    }

    /// String 结果
    public var stringPublisher: AnyPublisher<String, Error> {
        self.dataPublisher.tryMap { data -> String in
            guard let string = String(data: data, encoding: .utf8) else {
                throw STHTTPError.decodingError
            }
            return string
        }.eraseToAnyPublisher()
    }

    /// Decodable 结果
    public func decodablePublisher<T: Decodable>(_ type: T.Type = T.self, decoder: JSONDecoder = JSONDecoder()) -> AnyPublisher<T, Error> {
        self.dataPublisher.tryMap { data -> T in
            guard let value = try? decoder.decode(T.self, from: data) else {
                throw STHTTPError.decodingError
            }
            return value
        }.eraseToAnyPublisher()
    }

    func didComplete(with response: STHTTPResponse) {
        self.transition(to: .finished)
        self.responseSubject.send(response)
    }

    public func serializingData() async throws -> Data {
        try await withTaskCancellationHandler(
            operation: { try await self.st_awaitPublisher(self.dataPublisher) },
            onCancel: { self.cancel() }
        )
    }

    public func serializingString(encoding: String.Encoding = .utf8) async throws -> String {
        try await withTaskCancellationHandler(
            operation: {
                try await self.st_awaitPublisher(
                    self.dataPublisher.tryMap { data -> String in
                        guard let s = String(data: data, encoding: encoding) else {
                            throw STHTTPError.decodingError
                        }
                        return s
                    }.eraseToAnyPublisher()
                )
            },
            onCancel: { self.cancel() }
        )
    }

    public func serializingDecodable<T: Decodable>( _ type: T.Type, decoder: JSONDecoder = JSONDecoder()) async throws -> T {
        try await withTaskCancellationHandler(
            operation: { try await self.st_awaitPublisher(self.decodablePublisher(type, decoder: decoder)) },
            onCancel: { self.cancel() }
        )
    }
}

public class STUploadRequest: STRequest {

    private let progressSubject = PassthroughSubject<STUploadProgress, Never>()
    private let responseSubject = CurrentValueSubject<STHTTPResponse?, Never>(nil)

    public var progressPublisher: AnyPublisher<STUploadProgress, Never> {
        self.progressSubject.receive(on: DispatchQueue.main).eraseToAnyPublisher()
    }

    public var responsePublisher: AnyPublisher<STHTTPResponse, Never> {
        self.responseSubject.compactMap { $0 }.first().receive(on: DispatchQueue.main).eraseToAnyPublisher()
    }

    public func decodablePublisher<T: Decodable>(_ type: T.Type = T.self, decoder: JSONDecoder = JSONDecoder()) -> AnyPublisher<T, Error> {
        self.responsePublisher.tryMap { resp -> T in
            if let error = resp.error { throw error }
            guard let data = resp.data, !data.isEmpty else { throw STHTTPError.noData }
            guard let value = try? decoder.decode(T.self, from: data) else {
                throw STHTTPError.decodingError
            }
            return value
        }.eraseToAnyPublisher()
    }

    func didUpdateProgress(_ progress: STUploadProgress) {
        self.progressSubject.send(progress)
    }

    func didComplete(with response: STHTTPResponse) {
        self.transition(to: .finished)
        self.responseSubject.send(response)
    }

    public func serializingResponse() async throws -> STHTTPResponse {
        try await withTaskCancellationHandler(
            operation: {
                try await self.st_awaitPublisher(
                    self.responsePublisher
                        .tryMap { resp -> STHTTPResponse in
                            if let error = resp.error { throw error }
                            return resp
                        }
                        .eraseToAnyPublisher()
                )
            },
            onCancel: { self.cancel() }
        )
    }
}

public class STDownloadRequest: STRequest {

    public typealias Destination = (URL, HTTPURLResponse) -> URL

    private let progressSubject = PassthroughSubject<STDownloadProgress, Never>()
    private let resultSubject = CurrentValueSubject<Result<URL, Error>?, Never>(nil)

    private(set) var destination: Destination?
    private(set) var downloadOptions: STDownloadOptions

    private let resumeLock = NSLock()
    private var _resumeData: Data?

    public var resumeData: Data? {
        self.resumeLock.lock()
        defer { self.resumeLock.unlock() }
        return self._resumeData
    }

    public func didReceiveResumeData(_ data: Data) {
        self.resumeLock.lock()
        self._resumeData = data
        self.resumeLock.unlock()
    }

    public init(
        destination: Destination? = nil,
        downloadOptions: STDownloadOptions = .default,
        maxRetryCount: Int = 0,
        retryDelay: TimeInterval = 1.0
    ) {
        self.destination = destination
        self.downloadOptions = downloadOptions
        super.init(maxRetryCount: maxRetryCount, retryDelay: retryDelay)
    }

    public var progressPublisher: AnyPublisher<STDownloadProgress, Never> {
        self.progressSubject
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    /// 成功时发出目标 URL，失败时 upstream error
    public var responsePublisher: AnyPublisher<URL, Error> {
        self.resultSubject
            .compactMap { $0 }
            .first()
            .tryMap { try $0.get() }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    func didUpdateProgress(_ progress: STDownloadProgress) {
        self.progressSubject.send(progress)
    }

    func didComplete(with result: Result<URL, Error>) {
        self.transition(to: .finished)
        self.resultSubject.send(result)
    }

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

    public func serializingURL() async throws -> URL {
        try await withTaskCancellationHandler(
            operation: { try await self.st_awaitPublisher(self.responsePublisher) },
            onCancel: { self.cancel() }
        )
    }
}

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

public class STDataStreamRequest: STRequest {

    private let stateLock2 = NSLock()
    private var _receivedFirstByte = false
    private var _httpResponse: HTTPURLResponse?
    private var _isFinished = false
    private var _terminalError: Error?
    private var sseBuffer = Data()

    private let dataSubject = PassthroughSubject<Data, Error>()
    private let eventSubject = PassthroughSubject<STServerSentEvent, Error>()

    public var hasReceivedFirstByte: Bool {
        self.stateLock2.lock()
        defer { self.stateLock2.unlock() }
        return self._receivedFirstByte
    }

    public var httpResponse: HTTPURLResponse? {
        self.stateLock2.lock()
        defer { self.stateLock2.unlock() }
        return self._httpResponse
    }

    /// 原始 chunk 流，完成或出错时终止
    public var dataPublisher: AnyPublisher<Data, Error> {
        self.dataSubject.eraseToAnyPublisher()
    }

    /// SSE 事件流，完成或出错时终止
    public var eventPublisher: AnyPublisher<STServerSentEvent, Error> {
        self.eventSubject.eraseToAnyPublisher()
    }

    func didReceiveHTTPResponse(_ response: HTTPURLResponse) {
        self.stateLock2.lock()
        self._httpResponse = response
        self.stateLock2.unlock()
    }

    public func didReceive(_ chunk: Data) {
        self.stateLock2.lock()
        self._receivedFirstByte = true
        self.sseBuffer.append(chunk)
        let events = STSSEParser.parse(buffer: &self.sseBuffer)
        self.stateLock2.unlock()

        self.dataSubject.send(chunk)
        events.forEach { self.eventSubject.send($0) }
    }

    public func didFinish(error: Error?) {
        self.stateLock2.lock()
        guard !self._isFinished else {
            self.stateLock2.unlock()
            return
        }
        self._isFinished = true
        self._terminalError = error
        self.stateLock2.unlock()

        self.transition(to: .finished)
        if let error = error {
            self.dataSubject.send(completion: .failure(error))
            self.eventSubject.send(completion: .failure(error))
        } else {
            self.dataSubject.send(completion: .finished)
            self.eventSubject.send(completion: .finished)
        }
    }

    public func bytes() -> AsyncThrowingStream<Data, Error> {
        return AsyncThrowingStream { continuation in
            let cancellableBox = STCancellableBox()
            let cancellable = self.dataSubject.sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished: continuation.finish()
                    case .failure(let error): continuation.finish(throwing: error)
                    }
                    cancellableBox.clear()
                },
                receiveValue: { continuation.yield($0) }
            )
            cancellableBox.set(cancellable)
            continuation.onTermination = { [weak self] _ in
                cancellableBox.cancelAndClear()
                self?.cancel()
            }
        }
    }

    public func events() -> AsyncThrowingStream<STServerSentEvent, Error> {
        return AsyncThrowingStream { continuation in
            let cancellableBox = STCancellableBox()
            let cancellable = self.eventSubject.sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished: continuation.finish()
                    case .failure(let error): continuation.finish(throwing: error)
                    }
                    cancellableBox.clear()
                },
                receiveValue: { continuation.yield($0) }
            )
            cancellableBox.set(cancellable)
            continuation.onTermination = { [weak self] _ in
                cancellableBox.cancelAndClear()
                self?.cancel()
            }
        }
    }
}

private extension STRequest {
    func st_awaitPublisher<T>(_ publisher: AnyPublisher<T, Error>) async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            let cancellableBox = STCancellableBox()
            var resumed = false
            let cancellable = publisher.sink(
                receiveCompletion: { completion in
                    guard !resumed else { return }
                    if case .failure(let error) = completion {
                        resumed = true
                        continuation.resume(throwing: error)
                    }
                    cancellableBox.clear()
                },
                receiveValue: { value in
                    guard !resumed else { return }
                    resumed = true
                    continuation.resume(returning: value)
                    cancellableBox.clear()
                }
            )
            cancellableBox.set(cancellable)
        }
    }
}
