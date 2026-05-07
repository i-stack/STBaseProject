//
//  STHostnameReachability.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2018/12/10.
//

import Foundation
import SystemConfiguration

/// 基于 SCNetworkReachability 的主机可达性监听
///
/// 与 `STNetworkMonitoring`（NWPathMonitor）的区别：
/// - 该类可以跟踪特定主机名的可达性
/// - 可区分 Wi-Fi/蜂窝/离线
/// - 可选是否允许走蜂窝
public final class STHostnameReachability {

    public enum STReachabilityStatus: Int, Sendable {
        case unknown
        case offline
        case onlineViaCellular
        case onlineViaWiFi
    }

    public static let statusChangedNotification = Notification.Name("STHostnameReachabilityStatusChanged")
    public static let didGoOnlineNotification = Notification.Name("STHostnameReachabilityDidGoOnline")
    public static let didGoOfflineNotification = Notification.Name("STHostnameReachabilityDidGoOffline")
    public static let cellularPolicyChangedNotification = Notification.Name("STHostnameReachabilityCellularPolicyChanged")

    private let hostname: String
    private var reachabilityRef: SCNetworkReachability?
    private let lock = NSLock()
    private var currentStatus: STReachabilityStatus = .unknown
    private var previousStatus: STReachabilityStatus = .unknown
    private var cachedIsOnline: Bool = false
    private var requireWiFi: Bool

    public var status: STReachabilityStatus {
        lock.lock()
        defer { lock.unlock() }
        return currentStatus
    }

    public var isOnline: Bool {
        lock.lock()
        defer { lock.unlock() }
        return cachedIsOnline
    }

    public var isOnlineViaWiFi: Bool {
        status == .onlineViaWiFi
    }

    /// 是否允许使用蜂窝网络视为在线
    public var allowsCellular: Bool {
        get {
            lock.lock()
            defer { lock.unlock() }
            return !requireWiFi
        }
        set {
            let changed: Bool = lock.withLock {
                let oldValue = !requireWiFi
                requireWiFi = !newValue
                return oldValue != newValue
            }
            if changed {
                NotificationCenter.default.post(name: Self.cellularPolicyChangedNotification, object: self)
                refresh()
            }
        }
    }

    /// 初始化
    /// - Parameters:
    ///   - hostname: 需要监听的主机名
    ///   - allowsCellular: 是否允许蜂窝网络视为在线
    public init(hostname: String, allowsCellular: Bool = true) {
        self.hostname = hostname
        self.requireWiFi = !allowsCellular
        setupReachability(hostname: hostname)
    }

    deinit {
        if let ref = reachabilityRef {
            SCNetworkReachabilitySetCallback(ref, nil, nil)
            SCNetworkReachabilityUnscheduleFromRunLoop(ref, CFRunLoopGetMain(), CFRunLoopMode.commonModes.rawValue)
        }
    }

    /// 根据 URLError 判断是否是本机离线导致的错误
    public func isOfflineError(_ error: Error) -> Bool {
        let nsError = error as NSError
        guard nsError.domain == NSURLErrorDomain else { return false }
        let offlineCodes: Set<Int> = [
            NSURLErrorNotConnectedToInternet,
            NSURLErrorNetworkConnectionLost,
            NSURLErrorDataNotAllowed,
        ]
        if offlineCodes.contains(nsError.code) {
            refresh()
            return true
        }
        return false
    }

    /// 主动刷新当前状态
    public func refresh() {
        guard let ref = reachabilityRef else { return }
        var flags = SCNetworkReachabilityFlags()
        guard SCNetworkReachabilityGetFlags(ref, &flags) else { return }
        updateStatus(for: flags)
    }

    private func setupReachability(hostname: String) {
        guard let ref = SCNetworkReachabilityCreateWithName(nil, hostname) else { return }
        reachabilityRef = ref

        var context = SCNetworkReachabilityContext(
            version: 0,
            info: Unmanaged.passUnretained(self).toOpaque(),
            retain: nil,
            release: nil,
            copyDescription: nil
        )

        let callback: SCNetworkReachabilityCallBack = { _, flags, info in
            guard let info else { return }
            let instance = Unmanaged<STHostnameReachability>.fromOpaque(info).takeUnretainedValue()
            instance.updateStatus(for: flags)
        }

        SCNetworkReachabilitySetCallback(ref, callback, &context)
        SCNetworkReachabilityScheduleWithRunLoop(ref, CFRunLoopGetMain(), CFRunLoopMode.commonModes.rawValue)

        // 初始读取一次
        refresh()
    }

    private func updateStatus(for flags: SCNetworkReachabilityFlags) {
        let newStatus: STReachabilityStatus
        if Self.isReachable(flags) {
            newStatus = flags.contains(.isWWAN) ? .onlineViaCellular : .onlineViaWiFi
        } else {
            newStatus = .offline
        }

        lock.lock()
        previousStatus = currentStatus
        currentStatus = newStatus
        let effectiveOnline = newStatus == .onlineViaWiFi || (!requireWiFi && newStatus == .onlineViaCellular)
        let wentOnline = effectiveOnline && !cachedIsOnline
        let wentOffline = !effectiveOnline && cachedIsOnline
        let wasUnknown = previousStatus == .unknown
        cachedIsOnline = effectiveOnline
        lock.unlock()

        DispatchQueue.main.async {
            let center = NotificationCenter.default
            if wentOnline, !wasUnknown {
                center.post(name: Self.didGoOnlineNotification, object: self)
            } else if wentOffline, !wasUnknown {
                center.post(name: Self.didGoOfflineNotification, object: self)
            }
            center.post(name: Self.statusChangedNotification, object: self)
        }
    }

    private static func isReachable(_ flags: SCNetworkReachabilityFlags) -> Bool {
        guard flags.contains(.reachable) else { return false }
        guard flags.contains(.connectionRequired) else { return true }

        let canConnectAutomatically = flags.contains(.connectionOnDemand) || flags.contains(.connectionOnTraffic)
        let requiresUserIntervention = flags.contains(.interventionRequired)
        return canConnectAutomatically && !requiresUserIntervention
    }
}

private extension NSLock {
    func withLock<T>(_ body: () -> T) -> T {
        lock()
        defer { unlock() }
        return body()
    }
}
