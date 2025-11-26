//
//  STCrashDetector.swift
//  STBaseProject
//
//  Created by stack on 2024/01/01.
//

import Foundation

/// 崩溃检测器
public class STCrashDetector {
    
    public static let shared = STCrashDetector()
    
    private let crashKey = "STCrashDetector_app_crashed"
    private let launchTimeKey = "STCrashDetector_app_launch_time"
    private let backgroundTimeKey = "STCrashDetector_app_background_time"
    
    /// 崩溃回调
    public var onCrashDetected: (([String: Any]) -> Void)?
    
    private init() {}
    
    /// 标记应用已启动
    public func st_markAppLaunched() {
        UserDefaults.standard.set(true, forKey: crashKey)
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: launchTimeKey)
        STLog("✅ 应用启动标记已设置")
    }
    
    /// 标记应用已正常终止
    public func st_markAppTerminated() {
        UserDefaults.standard.set(false, forKey: crashKey)
        STLog("✅ 应用正常终止标记已设置")
    }
    
    /// 标记应用进入后台
    public func st_markAppInBackground() {
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: backgroundTimeKey)
        STLog("✅ 应用后台标记已设置")
    }
    
    /// 检查是否有崩溃
    /// - Returns: 如果有崩溃返回 true，否则返回 false
    public func st_checkForCrash() -> Bool {
        let wasCrashed = UserDefaults.standard.bool(forKey: crashKey)
        
        if wasCrashed {
            STLog("⚠️ 检测到应用崩溃")
            // 获取崩溃信息
            let crashInfo = st_getCrashInfo()
            onCrashDetected?(crashInfo)
            // 清除崩溃标记
            UserDefaults.standard.set(false, forKey: crashKey)
            return true
        }
        
        return false
    }
    
    /// 获取崩溃信息
    /// - Returns: 崩溃信息字典
    public func st_getCrashInfo() -> [String: Any] {
        let launchTime = UserDefaults.standard.double(forKey: launchTimeKey)
        let backgroundTime = UserDefaults.standard.double(forKey: backgroundTimeKey)
        
        var crashInfo: [String: Any] = [:]
        
        if launchTime > 0 {
            crashInfo["last_launch_time"] = Date(timeIntervalSince1970: launchTime)
            crashInfo["time_since_launch"] = Date().timeIntervalSince1970 - launchTime
        }
        
        if backgroundTime > 0 {
            crashInfo["last_background_time"] = Date(timeIntervalSince1970: backgroundTime)
        }
        
        return crashInfo
    }
    
    /// 清除所有崩溃检测数据
    public func st_clearCrashData() {
        UserDefaults.standard.removeObject(forKey: crashKey)
        UserDefaults.standard.removeObject(forKey: launchTimeKey)
        UserDefaults.standard.removeObject(forKey: backgroundTimeKey)
        STLog("🧹 崩溃检测数据已清除")
    }
}

