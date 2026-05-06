//
//  STAppLifecycleManager.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2024/01/01.
//

import UIKit

public class STAppLifecycleManager {

    private enum STAppLifecycleKeys {
        static let backgroundTimestamp = "STAppLifecycleManager_backgroundTimestamp"
    }

    private var backgroundTimestamp: Date?
    private var foregroundTimestamp: Date?
    private var hasStarted = false
    private let startLock = NSLock()
    public static let shared = STAppLifecycleManager()
    public var backgroundTimeoutInterval: TimeInterval = 900 // 15分钟
    public var onBackgroundTimeout: ((TimeInterval) -> Void)?
    public var onDidEnterBackground: (() -> Void)?
    public var onWillEnterForeground: (() -> Void)?

    private init() {}

    public func start() {
        self.startLock.lock()
        defer { self.startLock.unlock() }
        guard !self.hasStarted else { return }
        self.hasStarted = true
        self.setupNotifications()
    }

    /// 设置通知监听
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }

    /// 应用进入后台时调用
    @objc private func appDidEnterBackground() {
        let now = Date()
        self.backgroundTimestamp = now
        STLog("📱 应用进入后台时间: \(self.formatDate(now))")
        self.persistBackgroundTimestamp(now)
        self.onDidEnterBackground?()
    }

    /// 应用进入前台时调用
    @objc private func appWillEnterForeground() {
        let now = Date()
        self.foregroundTimestamp = now
        STLog("📱 应用进入前台时间: \(self.formatDate(now))")
        self.checkTimeDifference()
        self.onWillEnterForeground?()
    }

    /// 检查时间差是否超过设定阈值
    private func checkTimeDifference() {
        let savedBackgroundTime = self.backgroundTimestamp ?? self.readPersistedBackgroundTimestamp()
        guard let backgroundTime = savedBackgroundTime,
              let foregroundTime = self.foregroundTimestamp else {
            STLog("⚠️ 时间戳不完整，无法计算时间差")
            return
        }
        let timeDifference = foregroundTime.timeIntervalSince(backgroundTime)
        let minutes = timeDifference / 60
        STLog("📱 应用在后台运行了 \(String(format: "%.2f", minutes)) 分钟")
        if timeDifference > self.backgroundTimeoutInterval {
            STLog("⚠️ 应用在后台超过 \(self.backgroundTimeoutInterval / 60) 分钟！")
            self.handleLongBackgroundTime(minutes: minutes)
        } else {
            STLog("✅ 应用在后台未超过 \(self.backgroundTimeoutInterval / 60) 分钟")
        }
        self.clearPersistedBackgroundTimestamp()
    }

    /// 处理长时间后台的逻辑
    /// - Parameter minutes: 后台时长（分钟）
    private func handleLongBackgroundTime(minutes: Double) {
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.onBackgroundTimeout?(minutes * 60)
        }
    }

    /// 格式化日期显示
    /// - Parameter date: 日期
    /// - Returns: 格式化后的字符串
    private func formatDate(_ date: Date) -> String {
        return self.dateFormatter.string(from: date)
    }

    // MARK: - 持久化

    private func persistBackgroundTimestamp(_ date: Date) {
        UserDefaults.standard.set(date.timeIntervalSince1970, forKey: STAppLifecycleKeys.backgroundTimestamp)
    }

    private func readPersistedBackgroundTimestamp() -> Date? {
        guard let value = UserDefaults.standard.object(forKey: STAppLifecycleKeys.backgroundTimestamp) else {
            return nil
        }
        if let date = value as? Date {
            self.persistBackgroundTimestamp(date)
            return date
        }
        if let interval = value as? TimeInterval {
            return Date(timeIntervalSince1970: interval)
        }
        if let number = value as? NSNumber {
            return Date(timeIntervalSince1970: number.doubleValue)
        }
        self.clearPersistedBackgroundTimestamp()
        return nil
    }

    private func clearPersistedBackgroundTimestamp() {
        UserDefaults.standard.removeObject(forKey: STAppLifecycleKeys.backgroundTimestamp)
    }

    // MARK: - Public API

    /// 手动获取后台时长（可选的公共方法）
    /// - Returns: 后台时长（秒），如果无法计算则返回 nil
    public func getBackgroundDuration() -> TimeInterval? {
        guard let backgroundTime = self.backgroundTimestamp ?? self.readPersistedBackgroundTimestamp() else {
            return nil
        }
        return Date().timeIntervalSince(backgroundTime)
    }

    /// 恢复上次持久化的后台时间戳，适合在应用冷启动时调用
    public func restoreBackgroundTimestampIfNeeded() {
        if self.backgroundTimestamp == nil, let savedTime = self.readPersistedBackgroundTimestamp() {
            self.backgroundTimestamp = savedTime
        }
    }

    /// 手动清理内存与持久化中的时间戳
    public func resetTimestamps() {
        self.backgroundTimestamp = nil
        self.foregroundTimestamp = nil
        self.clearPersistedBackgroundTimestamp()
    }

    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()
}
