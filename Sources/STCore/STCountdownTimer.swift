//
//  STCountdownTimer.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2024/01/01.
//

import Foundation
import UIKit

// MARK: - 回调闭包类型
public typealias STCountdownCompletion = () -> Void
public typealias STCountdownProgress = (TimeInterval) -> Void
public typealias STCountdownError = (Error) -> Void

// MARK: - 自定义错误类型
public enum STCountdownTimerError: Error, LocalizedError {
    case timerAlreadyRunning
    case timerNotRunning
    case invalidDuration
    case systemInterruption
    
    public var errorDescription: String? {
        switch self {
        case .timerAlreadyRunning:
            return "定时器已在运行中"
        case .timerNotRunning:
            return "定时器未运行"
        case .invalidDuration:
            return "无效的时长"
        case .systemInterruption:
            return "系统中断"
        }
    }
}

public class STCountdownTimer {
    
    private var timer: Timer?
    private var remainingTime: TimeInterval
    private let totalTime: TimeInterval
    private var startDate: Date?
    
    // 回调闭包
    private var completionHandler: STCountdownCompletion?
    private var progressHandler: STCountdownProgress?
    private var errorHandler: STCountdownError?
    
    // 定时器状态
    public private(set) var isRunning: Bool = false
    public private(set) var isPaused: Bool = false
    
    // 后台任务标识符
    private var backgroundTaskId: UIBackgroundTaskIdentifier = .invalid
    
    public init(duration: TimeInterval) throws {
        guard duration > 0 else {
            throw STCountdownTimerError.invalidDuration
        }
        self.totalTime = duration
        self.remainingTime = duration
        self.st_setupNotificationObservers()
    }
    
    public convenience init(minutes: Int) throws {
        try self.init(duration: TimeInterval(minutes * 60))
    }
    
    public convenience init(hours: Int, minutes: Int) throws {
        try self.init(duration: TimeInterval(hours * 3600 + minutes * 60))
    }
        
    /// 启动倒计时
    public func st_start(
        progress: STCountdownProgress? = nil,
        completion: @escaping STCountdownCompletion,
        error: STCountdownError? = nil
    ) {
        guard !self.isRunning else {
            error?(STCountdownTimerError.timerAlreadyRunning)
            return
        }
        self.progressHandler = progress
        self.completionHandler = completion
        self.errorHandler = error
        self.st_startBackgroundTask()
        self.startDate = Date()
        self.st_startTimer()
        STLog("✅ 倒计时已启动，总时长: \(self.st_formatTime(self.totalTime))")
        self.progressHandler?(self.remainingTime)
    }
    
    /// 暂停倒计时
    public func st_pause() {
        guard self.isRunning && !self.isPaused else { return }
        self.st_stopTimer()
        self.isPaused = true
        STLog("⏸️ 倒计时已暂停，剩余时间: \(self.st_formatTime(self.remainingTime))")
    }
    
    /// 恢复倒计时
    public func st_resume() {
        guard self.isPaused else {
            self.errorHandler?(STCountdownTimerError.timerNotRunning)
            return
        }
        self.isPaused = false
        self.st_startTimer()
        STLog("▶️ 倒计时已恢复")
    }
    
    /// 停止倒计时
    public func st_stop() {
        self.st_stopTimer()
        self.st_endBackgroundTask()
        STLog("⏹️ 倒计时已停止")
    }
    
    /// 重置倒计时
    public func st_reset() {
        self.st_stop()
        self.remainingTime = self.totalTime
        self.startDate = nil
        STLog("🔄 倒计时已重置")
    }
    
    /// 获取剩余时间
    public func st_getRemainingTime() -> TimeInterval {
        return max(0, self.remainingTime)
    }
    
    /// 获取进度百分比
    public func st_getProgress() -> Double {
        return 1.0 - (self.st_getRemainingTime() / self.totalTime)
    }
    
    /// 获取格式化的剩余时间字符串
    public func st_getRemainingTimeString() -> String {
        return self.st_formatTime(self.st_getRemainingTime())
    }
        
    private func st_startTimer() {
        self.timer?.invalidate()
        self.isRunning = true
        self.timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            guard let strongSelf = self else {
                timer.invalidate()
                return
            }
            strongSelf.st_timerTick()
        }
        // 确保定时器在所有运行循环模式下都能工作
        if let timer = self.timer {
            RunLoop.current.add(timer, forMode: .common)
        }
    }
    
    private func st_stopTimer() {
        self.timer?.invalidate()
        self.timer = nil
        self.isRunning = false
    }
    
    private func st_timerTick() {
        // 使用实际经过的时间来更新剩余时间（更精确）
        if let startDate = self.startDate {
            let elapsed = Date().timeIntervalSince(startDate)
            self.remainingTime = max(0, self.totalTime - elapsed)
        } else {
            self.remainingTime -= 0.1
        }
        
        // 每秒调用一次进度回调（避免过于频繁）
        let currentSecond = Int(self.remainingTime)
        let lastSecond = Int(self.remainingTime + 0.1)
        
        if currentSecond != lastSecond {
            self.progressHandler?(self.st_getRemainingTime())
        }
        
        if self.remainingTime <= 0 {
            self.st_timerCompleted()
        }
    }
    
    private func st_timerCompleted() {
        self.st_stopTimer()
        self.st_endBackgroundTask()
        self.remainingTime = 0
        STLog("🎉 倒计时结束！")
        let completion = self.completionHandler
        self.completionHandler = nil
        self.progressHandler = nil
        self.errorHandler = nil
        DispatchQueue.main.async {
            completion?()
        }
    }
    
    private func st_formatTime(_ time: TimeInterval) -> String {
        let totalSeconds = Int(max(0, time))
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }
        
    private func st_startBackgroundTask() {
        self.st_endBackgroundTask() // 先结束之前的任务
        self.backgroundTaskId = UIApplication.shared.beginBackgroundTask(withName: "STCountdownTimer") { [weak self] in
            self?.st_handleBackgroundTaskExpiration()
        }
    }
    
    private func st_endBackgroundTask() {
        if self.backgroundTaskId != .invalid {
            UIApplication.shared.endBackgroundTask(self.backgroundTaskId)
            self.backgroundTaskId = .invalid
        }
    }
    
    private func st_handleBackgroundTaskExpiration() {
        STLog("⚠️ 后台任务即将过期，保存状态...")
        if self.isRunning {
            self.st_pause()
        }
        self.st_endBackgroundTask()
        self.errorHandler?(STCountdownTimerError.systemInterruption)
    }
        
    private func st_setupNotificationObservers() {
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
    
    @objc private func st_appDidEnterBackground() {
        STLog("📱 应用进入后台")
        // 应用进入后台时的处理
    }
    
    @objc private func st_appWillEnterForeground() {
        STLog("📱 应用即将进入前台")
        if let startDate = self.startDate, self.isRunning {
            let elapsed = Date().timeIntervalSince(startDate)
            self.remainingTime = max(0, self.totalTime - elapsed)
            
            if self.remainingTime <= 0 {
                self.st_timerCompleted()
            }
        }
    }
        
    deinit {
        self.st_stopTimer()
        self.st_endBackgroundTask()
        NotificationCenter.default.removeObserver(self)
    }
}
