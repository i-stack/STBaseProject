//
//  STAppLifecycleManager.swift
//  STBaseProject
//
//  Created by stack on 2024/01/01.
//

import UIKit

/// 应用生命周期管理器
public class STAppLifecycleManager {
    
    // 存储时间戳
    private var backgroundTimestamp: Date?
    private var foregroundTimestamp: Date?
    
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
        st_setupNotifications()
    }
    
    // MARK: - 设置通知监听
    
    /// 设置通知监听
    private func st_setupNotifications() {
        // 监听应用进入后台
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(st_appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        // 监听应用进入前台
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(st_appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }
    
    // MARK: - 应用生命周期回调
    
    /// 应用进入后台时调用
    @objc private func st_appDidEnterBackground() {
        backgroundTimestamp = Date()
        STLog("📱 应用进入后台时间: \(st_formatDate(backgroundTimestamp!))")
        
        // 可选：保存到 UserDefaults 以防应用被杀死
        UserDefaults.standard.set(backgroundTimestamp, forKey: "STAppLifecycleManager_backgroundTimestamp")
        
        onDidEnterBackground?()
    }
    
    /// 应用进入前台时调用
    @objc private func st_appWillEnterForeground() {
        foregroundTimestamp = Date()
        STLog("📱 应用进入前台时间: \(st_formatDate(foregroundTimestamp!))")
        
        // 检查时间差
        st_checkTimeDifference()
        
        onWillEnterForeground?()
    }
    
    // MARK: - 时间检查
    
    /// 检查时间差是否超过设定阈值
    private func st_checkTimeDifference() {
        // 优先使用内存中的时间戳，如果没有则从 UserDefaults 读取
        let savedBackgroundTime = backgroundTimestamp ?? UserDefaults.standard.object(forKey: "STAppLifecycleManager_backgroundTimestamp") as? Date
        
        guard let backgroundTime = savedBackgroundTime,
              let foregroundTime = foregroundTimestamp else {
            STLog("⚠️ 时间戳不完整，无法计算时间差")
            return
        }
        
        // 计算时间差（秒）
        let timeDifference = foregroundTime.timeIntervalSince(backgroundTime)
        let minutes = timeDifference / 60
        
        STLog("📱 应用在后台运行了 \(String(format: "%.2f", minutes)) 分钟")
        
        // 检查是否超过设定阈值
        if timeDifference > backgroundTimeoutInterval {
            STLog("⚠️ 应用在后台超过 \(backgroundTimeoutInterval / 60) 分钟！")
            st_handleLongBackgroundTime(minutes: minutes)
        } else {
            STLog("✅ 应用在后台未超过 \(backgroundTimeoutInterval / 60) 分钟")
        }
        
        // 清除保存的时间戳
        UserDefaults.standard.removeObject(forKey: "STAppLifecycleManager_backgroundTimestamp")
    }
    
    /// 处理长时间后台的逻辑
    /// - Parameter minutes: 后台时长（分钟）
    private func st_handleLongBackgroundTime(minutes: Double) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.onBackgroundTimeout?(minutes * 60)
        }
    }
    
    // MARK: - 工具方法
    
    /// 格式化日期显示
    /// - Parameter date: 日期
    /// - Returns: 格式化后的字符串
    private func st_formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: date)
    }
    
    /// 手动获取后台时长（可选的公共方法）
    /// - Returns: 后台时长（秒），如果无法计算则返回 nil
    public func st_getBackgroundDuration() -> TimeInterval? {
        guard let backgroundTime = backgroundTimestamp ?? UserDefaults.standard.object(forKey: "STAppLifecycleManager_backgroundTimestamp") as? Date else {
            return nil
        }
        return Date().timeIntervalSince(backgroundTime)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

