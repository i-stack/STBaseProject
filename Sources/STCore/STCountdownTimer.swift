//
//  STCountdownTimer.swift
//  STBaseProject
//
//  Created by stack on 2024/01/01.
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

// MARK: - STCountdownTimer
public class STCountdownTimer {
    
    // MARK: - Properties
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
    
    // MARK: - Initialization
    public init(duration: TimeInterval) throws {
        guard duration > 0 else {
            throw STCountdownTimerError.invalidDuration
        }
        self.totalTime = duration
        self.remainingTime = duration
        
        // 监听应用状态变化
        st_setupNotificationObservers()
    }
    
    // 便利初始化方法
    public convenience init(minutes: Int) throws {
        try self.init(duration: TimeInterval(minutes * 60))
    }
    
    public convenience init(hours: Int, minutes: Int) throws {
        try self.init(duration: TimeInterval(hours * 3600 + minutes * 60))
    }
    
    // MARK: - Public Methods
    
    /// 启动倒计时
    public func st_start(
        progress: STCountdownProgress? = nil,
        completion: @escaping STCountdownCompletion,
        error: STCountdownError? = nil
    ) {
        // 防止重复启动
        guard !isRunning else {
            error?(STCountdownTimerError.timerAlreadyRunning)
            return
        }
        
        // 设置回调
        self.progressHandler = progress
        self.completionHandler = completion
        self.errorHandler = error
        
        // 开始后台任务（防止应用进入后台时被暂停）
        st_startBackgroundTask()
        
        // 记录开始时间
        startDate = Date()
        
        // 启动定时器
        st_startTimer()
        
        STLog("✅ 倒计时已启动，总时长: \(st_formatTime(totalTime))")
        
        // 立即调用一次进度回调
        progressHandler?(remainingTime)
    }
    
    /// 暂停倒计时
    public func st_pause() {
        guard isRunning && !isPaused else { return }
        
        st_stopTimer()
        isPaused = true
        
        STLog("⏸️ 倒计时已暂停，剩余时间: \(st_formatTime(remainingTime))")
    }
    
    /// 恢复倒计时
    public func st_resume() {
        guard isPaused else {
            errorHandler?(STCountdownTimerError.timerNotRunning)
            return
        }
        
        isPaused = false
        st_startTimer()
        
        STLog("▶️ 倒计时已恢复")
    }
    
    /// 停止倒计时
    public func st_stop() {
        st_stopTimer()
        st_endBackgroundTask()
        
        STLog("⏹️ 倒计时已停止")
    }
    
    /// 重置倒计时
    public func st_reset() {
        st_stop()
        remainingTime = totalTime
        startDate = nil
        
        STLog("🔄 倒计时已重置")
    }
    
    /// 获取剩余时间
    public func st_getRemainingTime() -> TimeInterval {
        return max(0, remainingTime)
    }
    
    /// 获取进度百分比
    public func st_getProgress() -> Double {
        return 1.0 - (st_getRemainingTime() / totalTime)
    }
    
    /// 获取格式化的剩余时间字符串
    public func st_getRemainingTimeString() -> String {
        return st_formatTime(st_getRemainingTime())
    }
    
    // MARK: - Private Methods
    
    private func st_startTimer() {
        // 确保先停止已有定时器
        timer?.invalidate()
        
        isRunning = true
        
        // 使用更精确的定时器
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            self.st_timerTick()
        }
        
        // 确保定时器在所有运行循环模式下都能工作
        if let timer = timer {
            RunLoop.current.add(timer, forMode: .common)
        }
    }
    
    private func st_stopTimer() {
        timer?.invalidate()
        timer = nil
        isRunning = false
    }
    
    private func st_timerTick() {
        // 使用实际经过的时间来更新剩余时间（更精确）
        if let startDate = startDate {
            let elapsed = Date().timeIntervalSince(startDate)
            remainingTime = max(0, totalTime - elapsed)
        } else {
            remainingTime -= 0.1
        }
        
        // 每秒调用一次进度回调（避免过于频繁）
        let currentSecond = Int(remainingTime)
        let lastSecond = Int(remainingTime + 0.1)
        
        if currentSecond != lastSecond {
            progressHandler?(st_getRemainingTime())
        }
        
        // 检查是否完成
        if remainingTime <= 0 {
            st_timerCompleted()
        }
    }
    
    private func st_timerCompleted() {
        st_stopTimer()
        st_endBackgroundTask()
        remainingTime = 0
        
        STLog("🎉 倒计时结束！")
        
        // 调用完成回调
        let completion = completionHandler
        completionHandler = nil
        progressHandler = nil
        errorHandler = nil
        
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
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    // MARK: - Background Task Management
    
    private func st_startBackgroundTask() {
        st_endBackgroundTask() // 先结束之前的任务
        
        backgroundTaskId = UIApplication.shared.beginBackgroundTask(withName: "STCountdownTimer") { [weak self] in
            self?.st_handleBackgroundTaskExpiration()
        }
    }
    
    private func st_endBackgroundTask() {
        if backgroundTaskId != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskId)
            backgroundTaskId = .invalid
        }
    }
    
    private func st_handleBackgroundTaskExpiration() {
        STLog("⚠️ 后台任务即将过期，保存状态...")
        
        // 保存当前状态
        if isRunning {
            st_pause()
        }
        
        st_endBackgroundTask()
        
        // 通知错误处理器
        errorHandler?(STCountdownTimerError.systemInterruption)
    }
    
    // MARK: - Notification Observers
    
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
        
        // 重新计算剩余时间
        if let startDate = startDate, isRunning {
            let elapsed = Date().timeIntervalSince(startDate)
            remainingTime = max(0, totalTime - elapsed)
            
            if remainingTime <= 0 {
                st_timerCompleted()
            }
        }
    }
    
    // MARK: - Deinitializer
    
    deinit {
        st_stopTimer()
        st_endBackgroundTask()
        NotificationCenter.default.removeObserver(self)
    }
}

