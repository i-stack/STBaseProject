//
//  STAppLifecycleManager.swift
//  STBaseProject
//
//  Created by stack on 2024/01/01.
//

import UIKit

/// 应用生命周期管理器
public class STAppLifecycleManager {
    
    private enum STAppLifecycleKeys {
        static let backgroundTimestamp = "STAppLifecycleManager_backgroundTimestamp"
    }
    
    private var backgroundTimestamp: Date?
    private var foregroundTimestamp: Date?
    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()
    
    // 单例模式
    public static let shared = STAppLifecycleManager()
    
    /// 后台超时时间（秒），默认15分钟
    public var backgroundTimeoutInterval: TimeInterval = 900 // 15分钟
    
    /// 后台超时回调
    public var onBackgroundTimeout: ((TimeInterval) -> Void)?
    
    /// 应用进入后台回调
    public var onDidEnterBackground: (() -> Void)?
    
    /// 应用进入前台回调
    public var onWillEnterForeground: (() -> Void)?
    
    private init() {
        self.st_setupNotifications()
    }
        
    /// 设置通知监听
    private func st_setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(st_appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(st_appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }
        
    /// 应用进入后台时调用
    @objc private func st_appDidEnterBackground() {
        self.backgroundTimestamp = Date()
        STLog("📱 应用进入后台时间: \(self.st_formatDate(self.backgroundTimestamp!))")
        UserDefaults.standard.set(self.backgroundTimestamp, forKey: STAppLifecycleKeys.backgroundTimestamp)
        self.onDidEnterBackground?()
    }
    
    /// 应用进入前台时调用
    @objc private func st_appWillEnterForeground() {
        self.foregroundTimestamp = Date()
        STLog("📱 应用进入前台时间: \(st_formatDate(foregroundTimestamp!))")
        self.st_checkTimeDifference()
        self.onWillEnterForeground?()
    }
        
    /// 检查时间差是否超过设定阈值
    private func st_checkTimeDifference() {
        let savedBackgroundTime = self.backgroundTimestamp ?? UserDefaults.standard.object(forKey: STAppLifecycleKeys.backgroundTimestamp) as? Date
        guard let backgroundTime = savedBackgroundTime,
              let foregroundTime = self.foregroundTimestamp else {
            STLog("⚠️ 时间戳不完整，无法计算时间差")
            return
        }
        // 计算时间差（秒）
        let timeDifference = foregroundTime.timeIntervalSince(backgroundTime)
        let minutes = timeDifference / 60
        STLog("📱 应用在后台运行了 \(String(format: "%.2f", minutes)) 分钟")
        // 检查是否超过设定阈值
        if timeDifference > self.backgroundTimeoutInterval {
            STLog("⚠️ 应用在后台超过 \(self.backgroundTimeoutInterval / 60) 分钟！")
            self.st_handleLongBackgroundTime(minutes: minutes)
        } else {
            STLog("✅ 应用在后台未超过 \(self.backgroundTimeoutInterval / 60) 分钟")
        }
        // 清除保存的时间戳
        UserDefaults.standard.removeObject(forKey: STAppLifecycleKeys.backgroundTimestamp)
    }
    
    /// 处理长时间后台的逻辑
    /// - Parameter minutes: 后台时长（分钟）
    private func st_handleLongBackgroundTime(minutes: Double) {
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.onBackgroundTimeout?(minutes * 60)
        }
    }
        
    /// 格式化日期显示
    /// - Parameter date: 日期
    /// - Returns: 格式化后的字符串
    private func st_formatDate(_ date: Date) -> String {
        return self.dateFormatter.string(from: date)
    }
    
    /// 手动获取后台时长（可选的公共方法）
    /// - Returns: 后台时长（秒），如果无法计算则返回 nil
    public func st_getBackgroundDuration() -> TimeInterval? {
        guard let backgroundTime = self.backgroundTimestamp ?? UserDefaults.standard.object(forKey: STAppLifecycleKeys.backgroundTimestamp) as? Date else {
            return nil
        }
        return Date().timeIntervalSince(backgroundTime)
    }
    
    /// 恢复上次持久化的后台时间戳，适合在应用冷启动时调用
    public func st_restoreBackgroundTimestampIfNeeded() {
        if self.backgroundTimestamp == nil,
           let savedTime = UserDefaults.standard.object(forKey: STAppLifecycleKeys.backgroundTimestamp) as? Date {
            self.backgroundTimestamp = savedTime
        }
    }
    
    /// 手动清理内存与持久化中的时间戳
    public func st_resetTimestamps() {
        self.backgroundTimestamp = nil
        self.foregroundTimestamp = nil
        UserDefaults.standard.removeObject(forKey: STAppLifecycleKeys.backgroundTimestamp)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
