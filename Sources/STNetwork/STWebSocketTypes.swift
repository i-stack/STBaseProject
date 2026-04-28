//
//  STWebSocketTypes.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2018/12/10.
//

import Network
import Foundation

public enum STWebSocketState: Equatable, Sendable {
    /// 初始未连接
    case idle
    /// 正在建立连接
    case connecting
    /// 连接已就绪，可收发消息
    case connected
    /// 等待重连（携带当前重试次数和距下次重连剩余秒数）
    case reconnecting(attempt: Int, delay: TimeInterval)
    /// 主动断开，不再重连
    case disconnected(reason: STWebSocketCloseReason)
}

public enum STWebSocketCloseReason: Equatable, Sendable {
    /// 客户端主动调用 disconnect()
    case clientInitiated
    /// 服务端发送 Close 帧（携带 code 和 reason）
    case serverClose(code: NWProtocolWebSocket.CloseCode, reason: String?)
    /// 心跳超时
    case heartbeatTimeout
    /// 重连次数耗尽
    case maxRetriesExceeded
    /// App 进入后台且配置为后台断开
    case appDidBackground
}

public enum STWebSocketError: Error, Sendable {
    case invalidURL
    case notConnected
    case sendFailed(underlying: Error)
    case receiveFailed(underlying: Error)
    case heartbeatTimeout
    case encodingFailed
}

// MARK: - 消息类型
public enum STWebSocketMessage: Sendable {
    case text(String)
    case data(Data)
}

// MARK: - 事件（对外事件流）
public enum STWebSocketEvent: Sendable {
    case stateChanged(STWebSocketState)
    case messageReceived(STWebSocketMessage)
    case error(STWebSocketError)
    /// 弱网变化通知（isExpensive: 热点/蜂窝, isConstrained: 低数据模式）
    case networkQualityChanged(isExpensive: Bool, isConstrained: Bool)
    /// Ping 往返时延（毫秒），用于弱网监测
    case pingLatency(milliseconds: Int)
}

// MARK: - 重连策略
public struct STWebSocketReconnectPolicy: Sendable {
    /// 最大重连次数；0 表示不重连
    public var maxAttempts: Int
    /// 初始退避间隔（秒）
    public var initialDelay: TimeInterval
    /// 退避乘数（指数退避）
    public var multiplier: Double
    /// 最大退避上限（秒）
    public var maxDelay: TimeInterval

    public static let disabled = STWebSocketReconnectPolicy(maxAttempts: 0, initialDelay: 0, multiplier: 1, maxDelay: 0)
    public static let `default` = STWebSocketReconnectPolicy(maxAttempts: 10, initialDelay: 1.0, multiplier: 1.5, maxDelay: 60.0)

    public init(maxAttempts: Int, initialDelay: TimeInterval, multiplier: Double, maxDelay: TimeInterval) {
        self.maxAttempts = maxAttempts
        self.initialDelay = initialDelay
        self.multiplier = multiplier
        self.maxDelay = maxDelay
    }

    /// 计算第 n 次（从 1 起）重连的等待时间
    func delay(forAttempt attempt: Int) -> TimeInterval {
        guard attempt > 0 else { return initialDelay }
        let raw = initialDelay * pow(multiplier, Double(attempt - 1))
        return min(raw, maxDelay)
    }
}

// MARK: - 心跳配置
public struct STWebSocketHeartbeatConfig: Sendable {
    /// Ping 间隔（秒）；0 表示禁用
    public var interval: TimeInterval
    /// 等待 Pong 的超时时长（秒）
    public var timeout: TimeInterval
    /// 自定义应用层心跳文本；nil 则使用 NWProtocol 原生 Ping
    public var pingMessage: String?
    /// 判断 Pong 的回复文本（配合 pingMessage 使用）
    public var pongMessage: String?

    public static let disabled = STWebSocketHeartbeatConfig(interval: 0, timeout: 0)
    public static let `default` = STWebSocketHeartbeatConfig(interval: 25, timeout: 10)

    public init(interval: TimeInterval, timeout: TimeInterval, pingMessage: String? = nil, pongMessage: String? = nil) {
        self.interval = interval
        self.timeout = timeout
        self.pingMessage = pingMessage
        self.pongMessage = pongMessage
    }
}

public enum STWebSocketBackgroundBehavior: Sendable {
    /// 进入后台立即断开，回到前台自动重连
    case disconnectOnBackground
    /// 保持连接（需要 Background Modes → Voice over IP 权限）
    case keepAlive
    /// 进入后台暂停心跳，连接不主动断开，回来后恢复心跳
    case pauseHeartbeat
}

public struct STWebSocketConfig: Sendable {
    public var url: URL
    public var additionalHeaders: [String: String]
    public var reconnect: STWebSocketReconnectPolicy
    public var heartbeat: STWebSocketHeartbeatConfig
    public var backgroundBehavior: STWebSocketBackgroundBehavior
    /// 消息发送队列上限（超出后丢弃最旧的消息），0 表示不缓冲
    public var offlineQueueCapacity: Int
    /// 是否开启弱网质量监测（NWPathMonitor）
    public var enableNetworkQualityMonitor: Bool
    /// TLS 配置；nil 表示不启用 TLS
    public var tlsOptions: NWProtocolTLS.Options?

    public init(
        url: URL,
        additionalHeaders: [String: String] = [:],
        reconnect: STWebSocketReconnectPolicy = .default,
        heartbeat: STWebSocketHeartbeatConfig = .default,
        backgroundBehavior: STWebSocketBackgroundBehavior = .pauseHeartbeat,
        offlineQueueCapacity: Int = 50,
        enableNetworkQualityMonitor: Bool = true,
        tlsOptions: NWProtocolTLS.Options? = nil
    ) {
        self.url = url
        self.additionalHeaders = additionalHeaders
        self.reconnect = reconnect
        self.heartbeat = heartbeat
        self.backgroundBehavior = backgroundBehavior
        self.offlineQueueCapacity = offlineQueueCapacity
        self.enableNetworkQualityMonitor = enableNetworkQualityMonitor
        self.tlsOptions = tlsOptions
    }
}
