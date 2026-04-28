//
//  STWebSocket.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2018/12/10.
//

import UIKit
import Network
import Foundation

public actor STWebSocket {

    private typealias WebSocketContinuation = AsyncStream<STWebSocketEvent>.Continuation

    public init(config: STWebSocketConfig) {
        self.config = config
    }

    deinit {
        self.receiveTask?.cancel()
        self.heartbeatTask?.cancel()
        self.pongTimeoutTask?.cancel()
        self.reconnectTask?.cancel()
        self.networkMonitorTask?.cancel()
        self.connection?.cancel()
    }

    /// 连接并返回事件流；多次调用会先断开旧连接再重新建立。
    public func connect() -> AsyncStream<STWebSocketEvent> {
        let stream = AsyncStream<STWebSocketEvent> { continuation in
            self.continuation = continuation
            continuation.onTermination = { [weak self] _ in
                Task { await self?.handleStreamTerminated() }
            }
        }
        Task { await self.startConnect() }
        return stream
    }

    /// 发送文本消息；若未连接则进入离线队列（如队列已满则丢弃最旧项）。
    public func send(text: String) async throws {
        guard let data = text.data(using: .utf8) else {
            throw STWebSocketError.encodingFailed
        }
        let metadata = NWProtocolWebSocket.Metadata(opcode: .text)
        let context = NWConnection.ContentContext(identifier: "text", metadata: [metadata])
        try await self.sendRaw(data: data, context: context, message: .text(text))
    }

    /// 发送二进制消息；若未连接则进入离线队列。
    public func send(data: Data) async throws {
        let metadata = NWProtocolWebSocket.Metadata(opcode: .binary)
        let context = NWConnection.ContentContext(identifier: "binary", metadata: [metadata])
        try await self.sendRaw(data: data, context: context, message: .data(data))
    }

    /// 主动断开，不再重连。
    public func disconnect() async {
        await self.teardown(reason: .clientInitiated, allowReconnect: false)
    }

    private var config: STWebSocketConfig
    private var connection: NWConnection?
    private var continuation: WebSocketContinuation?

    /// 当前连接状态
    private var state: STWebSocketState = .idle {
        didSet { self.continuation?.yield(.stateChanged(self.state)) }
    }

    /// 重连次数计数器
    private var reconnectAttempt: Int = 0

    /// 离线消息队列（断线期间缓存，重连后批量发送）
    private var offlineQueue: [(Data, NWConnection.ContentContext)] = []

    /// 接收循环 Task（持续 receive）
    private var receiveTask: Task<Void, Never>?
    /// 心跳 Task（Ping / Pong 超时监控）
    private var heartbeatTask: Task<Void, Never>?
    /// 等待 Pong 的超时 Task
    private var pongTimeoutTask: Task<Void, Never>?
    /// 重连延迟 Task
    private var reconnectTask: Task<Void, Never>?
    /// 网络质量监控 Task
    private var networkMonitorTask: Task<Void, Never>?
    /// App 生命周期监听（非 Task，是 token）
    private var backgroundObserver: (any NSObjectProtocol)?
    private var foregroundObserver: (any NSObjectProtocol)?

    /// Pong 是否已经收到（应用层心跳模式）
    private var pongReceived: Bool = false

    /// App 当前是否在后台
    private var isInBackground: Bool = false
}

private extension STWebSocket {
    func startConnect() async {
        guard self.state == .idle || self.state == .reconnecting(attempt: self.reconnectAttempt, delay: 0) else { return }
        self.state = .connecting
        self.buildConnection()
        self.observeAppLifecycle()
        if self.config.enableNetworkQualityMonitor {
            self.startNetworkMonitor()
        }
    }

    func buildConnection() {
        guard self.config.url.host != nil else {
            self.continuation?.yield(.error(.invalidURL))
            return
        }

        let wsOptions = NWProtocolWebSocket.Options()
        wsOptions.autoReplyPing = false  // 手动处理，以便我们能做 Pong 超时检测
        self.config.additionalHeaders.forEach { wsOptions.setAdditionalHeaders([($0.key, $0.value)]) }

        let parameters: NWParameters
        if self.config.url.scheme == "wss" {
            let tlsOptions = self.config.tlsOptions ?? NWProtocolTLS.Options()
            parameters = NWParameters(tls: tlsOptions)
        } else {
            parameters = .tcp
        }
        parameters.defaultProtocolStack.applicationProtocols.insert(wsOptions, at: 0)
        parameters.serviceClass = .interactiveVideo

        let conn = NWConnection(to: NWEndpoint.url(self.config.url), using: parameters)
        self.connection = conn

        conn.stateUpdateHandler = { [weak self] nwState in
            Task { await self?.handleConnectionStateChanged(nwState) }
        }
        conn.start(queue: .global(qos: .utility))
    }

    func handleConnectionStateChanged(_ nwState: NWConnection.State) async {
        switch nwState {
        case .ready:
            self.reconnectAttempt = 0
            self.state = .connected
            self.startReceiveLoop()
            self.startHeartbeat()
            await self.flushOfflineQueue()

        case .failed(let error):
            STWebSocketLogger.log("连接失败: \(error)")
            await self.scheduleReconnectIfNeeded()

        case .waiting(let error):
            // 网络暂时不可达，NWConnection 会自动等待
            STWebSocketLogger.log("连接等待: \(error)")

        case .cancelled:
            // 由 teardown 触发，不再重连
            break

        default:
            break
        }
    }
}

private extension STWebSocket {
    /// Task 创建：startReceiveLoop；持有：receiveTask；取消：teardown / 连接失败
    func startReceiveLoop() {
        self.receiveTask?.cancel()
        self.receiveTask = Task { [weak self] in
            guard let self else { return }
            await self.receiveLoop()
        }
    }

    func receiveLoop() async {
        guard let conn = self.connection else { return }
        while !Task.isCancelled {
            do {
                let (data, context, _) = try await self.receive(on: conn)
                guard let data, let context else { continue }
                await self.handleIncoming(data: data, context: context)
            } catch {
                guard !Task.isCancelled else { break }
                self.continuation?.yield(.error(.receiveFailed(underlying: error)))
                await self.scheduleReconnectIfNeeded()
                break
            }
        }
    }

    func receive(on conn: NWConnection) async throws -> (Data?, NWConnection.ContentContext?, Bool) {
        try await withCheckedThrowingContinuation { cont in
            conn.receiveMessage { data, context, isComplete, error in
                if let error {
                    cont.resume(throwing: error)
                } else {
                    cont.resume(returning: (data, context, isComplete))
                }
            }
        }
    }

    func handleIncoming(data: Data, context: NWConnection.ContentContext) async {
        guard let metadata = context.protocolMetadata(definition: NWProtocolWebSocket.definition) as? NWProtocolWebSocket.Metadata else {
            return
        }
        switch metadata.opcode {
        case .text:
            let text = String(data: data, encoding: .utf8) ?? ""
            // 应用层 Pong 检测
            if let pongMsg = self.config.heartbeat.pongMessage, text == pongMsg {
                self.didReceivePong()
                return
            }
            self.continuation?.yield(.messageReceived(.text(text)))

        case .binary:
            self.continuation?.yield(.messageReceived(.data(data)))

        case .ping:
            // 服务端发 Ping，回复 Pong
            self.sendPong(data: data)

        case .pong:
            self.didReceivePong()

        case .close:
            let code = metadata.closeCode
            let reason = data.isEmpty ? nil : String(data: data, encoding: .utf8)
            STWebSocketLogger.log("服务端关闭 code=\(code) reason=\(reason ?? "")")
            await self.teardown(reason: .serverClose(code: code, reason: reason), allowReconnect: true)

        default:
            break
        }
    }
}

// MARK: - 发送
private extension STWebSocket {
    func sendRaw(data: Data, context: NWConnection.ContentContext, message: STWebSocketMessage) async throws {
        if case .connected = self.state, let conn = self.connection {
            try await self.performSend(data: data, context: context, on: conn)
        } else {
            self.enqueueOffline(data: data, context: context)
        }
    }

    func performSend(data: Data, context: NWConnection.ContentContext, on conn: NWConnection) async throws {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            conn.send(content: data, contentContext: context, isComplete: true, completion: .contentProcessed { error in
                if let error {
                    cont.resume(throwing: STWebSocketError.sendFailed(underlying: error))
                } else {
                    cont.resume()
                }
            })
        }
    }

    func sendPong(data: Data) {
        guard let conn = self.connection else { return }
        let metadata = NWProtocolWebSocket.Metadata(opcode: .pong)
        let context = NWConnection.ContentContext(identifier: "pong", metadata: [metadata])
        conn.send(content: data, contentContext: context, isComplete: true, completion: .idempotent)
    }

    func enqueueOffline(data: Data, context: NWConnection.ContentContext) {
        guard self.config.offlineQueueCapacity > 0 else { return }
        if self.offlineQueue.count >= self.config.offlineQueueCapacity {
            self.offlineQueue.removeFirst()
        }
        self.offlineQueue.append((data, context))
    }

    func flushOfflineQueue() async {
        guard !self.offlineQueue.isEmpty, let conn = self.connection else { return }
        let queued = self.offlineQueue
        self.offlineQueue.removeAll()
        for (data, context) in queued {
            try? await self.performSend(data: data, context: context, on: conn)
        }
    }
}

private extension STWebSocket {
    /// Task 创建：startHeartbeat；持有：heartbeatTask；取消：stopHeartbeat / teardown
    func startHeartbeat() {
        guard self.config.heartbeat.interval > 0 else { return }
        self.heartbeatTask?.cancel()
        self.heartbeatTask = Task { [weak self] in
            guard let self else { return }
            await self.heartbeatLoop()
        }
    }

    func heartbeatLoop() async {
        let interval = self.config.heartbeat.interval
        while !Task.isCancelled {
            do {
                try await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
            } catch {
                break
            }
            guard !Task.isCancelled else { break }
            // 后台且配置 pauseHeartbeat 则跳过本次
            if self.isInBackground, case .pauseHeartbeat = self.config.backgroundBehavior {
                continue
            }
            await self.sendPingAndWaitPong()
        }
    }

    func sendPingAndWaitPong() async {
        self.pongReceived = false

        if let pingMsg = self.config.heartbeat.pingMessage {
            // 应用层心跳
            try? await self.send(text: pingMsg)
        } else {
            // NWProtocol 原生 Ping
            guard let conn = self.connection else { return }
            let metadata = NWProtocolWebSocket.Metadata(opcode: .ping)
            let context = NWConnection.ContentContext(identifier: "ping", metadata: [metadata])
            conn.send(content: nil, contentContext: context, isComplete: true, completion: .idempotent)
        }

        // 启动 Pong 超时检测
        // Task 创建：sendPingAndWaitPong；持有：pongTimeoutTask；取消：didReceivePong / teardown
        self.pongTimeoutTask?.cancel()
        let timeout = self.config.heartbeat.timeout
        self.pongTimeoutTask = Task { [weak self] in
            guard let self else { return }
            do {
                try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
            } catch {
                return
            }
            await self.handlePongTimeout()
        }
    }

    func didReceivePong() {
        self.pongReceived = true
        self.pongTimeoutTask?.cancel()
        self.pongTimeoutTask = nil
    }

    func handlePongTimeout() async {
        guard !self.pongReceived else { return }
        STWebSocketLogger.log("心跳超时，主动断开")
        self.continuation?.yield(.error(.heartbeatTimeout))
        await self.teardown(reason: .heartbeatTimeout, allowReconnect: true)
    }

    func stopHeartbeat() {
        self.heartbeatTask?.cancel()
        self.heartbeatTask = nil
        self.pongTimeoutTask?.cancel()
        self.pongTimeoutTask = nil
    }
}

// MARK: - 重连

private extension STWebSocket {

    func scheduleReconnectIfNeeded() async {
        let policy = self.config.reconnect
        guard policy.maxAttempts > 0 else {
            await self.teardown(reason: .maxRetriesExceeded, allowReconnect: false)
            return
        }
        self.reconnectAttempt += 1
        if self.reconnectAttempt > policy.maxAttempts {
            await self.teardown(reason: .maxRetriesExceeded, allowReconnect: false)
            return
        }
        let delay = policy.delay(forAttempt: self.reconnectAttempt)
        self.state = .reconnecting(attempt: self.reconnectAttempt, delay: delay)
        STWebSocketLogger.log("第 \(self.reconnectAttempt) 次重连，\(delay)s 后尝试")

        self.connection?.cancel()
        self.connection = nil
        self.stopHeartbeat()
        self.receiveTask?.cancel()

        // Task 创建：scheduleReconnectIfNeeded；持有：reconnectTask；取消：teardown
        self.reconnectTask?.cancel()
        self.reconnectTask = Task { [weak self] in
            guard let self else { return }
            do {
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            } catch {
                return
            }
            await self.buildConnectionForReconnect()
        }
    }

    func buildConnectionForReconnect() async {
        guard case .reconnecting = self.state else { return }
        self.state = .connecting
        self.buildConnection()
    }
}

private extension STWebSocket {
    func teardown(reason: STWebSocketCloseReason, allowReconnect: Bool) async {
        self.cancelAllTasks()
        self.connection?.cancel()
        self.connection = nil

        if allowReconnect, case .clientInitiated = reason {} else if allowReconnect {
            await self.scheduleReconnectIfNeeded()
            return
        }

        self.state = .disconnected(reason: reason)
        self.continuation?.finish()
        self.continuation = nil
        self.removeAppLifecycleObservers()
    }

    func cancelAllTasks() {
        self.receiveTask?.cancel()
        self.heartbeatTask?.cancel()
        self.pongTimeoutTask?.cancel()
        self.reconnectTask?.cancel()
        self.networkMonitorTask?.cancel()
        self.receiveTask = nil
        self.heartbeatTask = nil
        self.pongTimeoutTask = nil
        self.reconnectTask = nil
        self.networkMonitorTask = nil
    }

    func handleStreamTerminated() async {
        await self.teardown(reason: .clientInitiated, allowReconnect: false)
    }
}

private extension STWebSocket {
    func observeAppLifecycle() {
        self.removeAppLifecycleObservers()
        let center = NotificationCenter.default
        self.backgroundObserver = center.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            Task { await self?.handleDidEnterBackground() }
        }
        self.foregroundObserver = center.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            Task { await self?.handleWillEnterForeground() }
        }
    }

    func removeAppLifecycleObservers() {
        if let token = self.backgroundObserver {
            NotificationCenter.default.removeObserver(token)
            self.backgroundObserver = nil
        }
        if let token = self.foregroundObserver {
            NotificationCenter.default.removeObserver(token)
            self.foregroundObserver = nil
        }
    }

    func handleDidEnterBackground() async {
        self.isInBackground = true
        switch self.config.backgroundBehavior {
        case .disconnectOnBackground:
            STWebSocketLogger.log("进入后台，断开连接")
            // 不通知 teardown 重连，回到前台再连
            self.stopHeartbeat()
            self.receiveTask?.cancel()
            self.connection?.cancel()
            self.connection = nil
            self.state = .disconnected(reason: .appDidBackground)
        case .pauseHeartbeat:
            STWebSocketLogger.log("进入后台，暂停心跳")
            // heartbeatLoop 内部检查 isInBackground，自动跳过
        case .keepAlive:
            break
        }
    }

    func handleWillEnterForeground() async {
        self.isInBackground = false
        guard case .disconnected(let reason) = self.state, reason == .appDidBackground else {
            // pauseHeartbeat 模式：重启心跳
            if case .pauseHeartbeat = self.config.backgroundBehavior {
                self.startHeartbeat()
            }
            return
        }
        STWebSocketLogger.log("回到前台，恢复连接")
        self.reconnectAttempt = 0
        self.state = .idle
        self.buildConnection()
    }
}

private extension STWebSocket {
    /// Task 创建：startNetworkMonitor；持有：networkMonitorTask；取消：teardown
    func startNetworkMonitor() {
        self.networkMonitorTask?.cancel()
        self.networkMonitorTask = Task { [weak self] in
            guard let self else { return }
            await self.runNetworkMonitor()
        }
    }

    func runNetworkMonitor() async {
        let monitor = NWPathMonitor()
        let stream = AsyncStream<NWPath> { cont in
            monitor.pathUpdateHandler = { cont.yield($0) }
            monitor.start(queue: .global(qos: .utility))
            cont.onTermination = { _ in monitor.cancel() }
        }
        for await path in stream {
            guard !Task.isCancelled else { break }
            let isExpensive = path.isExpensive
            let isConstrained = path.isConstrained
            self.continuation?.yield(.networkQualityChanged(isExpensive: isExpensive, isConstrained: isConstrained))

            // 网络从无到有，且处于断开/重连失败状态时，触发重连
            if path.status == .satisfied {
                if case .disconnected(let reason) = self.state, reason == .maxRetriesExceeded {
                    STWebSocketLogger.log("网络恢复，重置重连计数")
                    self.reconnectAttempt = 0
                    self.state = .idle
                    self.buildConnection()
                }
            }
        }
        monitor.cancel()
    }
}

private enum STWebSocketLogger {
    static func log(_ message: String) {
        #if DEBUG
        print("[STWebSocket] \(message)")
        #endif
    }
}
