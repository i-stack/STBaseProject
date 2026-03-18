//
//  STCountdownTimer.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2024/01/01.
//

import UIKit

public class STCountdownTimer {
    
    public typealias STCountdownCompletion = () -> Void
    public typealias STCountdownError = (Error) -> Void
    public typealias STCountdownProgress = (TimeInterval) -> Void

    public enum STCountdownTimerError: Error, LocalizedError {
        case timerAlreadyRunning
        case timerNotRunning
        case invalidDuration
        case systemInterruption
        
        public var errorDescription: String? {
            switch self {
            case .timerAlreadyRunning: return "定时器已在运行中"
            case .timerNotRunning: return "定时器未运行"
            case .invalidDuration: return "无效的时长"
            case .systemInterruption: return "系统中断"
            }
        }
    }

    private enum State {
        case idle       // 空闲
        case running    // 运行中
        case paused     // 暂停中
    }

    private var timer: DispatchSourceTimer?
    private let queue: DispatchQueue
    
    private var state: State = .idle
    private var remainingTime: TimeInterval
    private let totalTime: TimeInterval
    private var startDate: Date?
    
    private var completionHandler: STCountdownCompletion?
    private var progressHandler: STCountdownProgress?
    private var errorHandler: STCountdownError?
    private var backgroundTaskId: UIBackgroundTaskIdentifier = .invalid

    public var isRunning: Bool {
        return state == .running
    }
    
    public var isPaused: Bool {
        return state == .paused
    }

    public init(duration: TimeInterval) throws {
        guard duration > 0 else {
            throw STCountdownTimerError.invalidDuration
        }
        self.totalTime = duration
        self.remainingTime = duration
        self.queue = DispatchQueue(label: "com.st.countdowntimer.queue", qos: .userInteractive)
        self.setupNotificationObservers()
    }
    
    public convenience init(minutes: Int) throws {
        try self.init(duration: TimeInterval(minutes * 60))
    }
    
    deinit {
        if self.state == .paused {
            self.timer?.resume()
        }
        self.timer?.cancel()
        self.removeNotificationObservers()
        self.endBackgroundTask()
    }
    
    /// 启动倒计时
    public func start(progress: STCountdownProgress? = nil, completion: @escaping STCountdownCompletion, error: STCountdownError? = nil) {
        self.queue.async { [weak self] in
            guard let self = self else { return }
            guard self.state == .idle else {
                DispatchQueue.main.async { error?(STCountdownTimerError.timerAlreadyRunning) }
                return
            }
            self.progressHandler = progress
            self.completionHandler = completion
            self.errorHandler = error
            self.startBackgroundTask()
            self.startDate = Date()
            self.remainingTime = self.totalTime
            self.createAndResumeTimer()
            self.state = .running
            DispatchQueue.main.async {
                progress?(self.totalTime)
            }
            STLog("✅ (GCD) 倒计时启动: \(self.formatTime(self.totalTime))")
        }
    }

    /// 暂停
    public func pause() {
        self.queue.async { [weak self] in
            guard let self = self, self.state == .running else { return }
            self.timer?.suspend()
            self.state = .paused
            if let startDate = self.startDate {
                let elapsed = Date().timeIntervalSince(startDate)
                self.remainingTime = max(0, self.totalTime - elapsed)
            }
            STLog("⏸️ (GCD) 倒计时暂停, 剩余: \(self.formatTime(self.remainingTime))")
        }
    }

    /// 恢复
    public func resume() {
        self.queue.async { [weak self] in
            guard let self = self, self.state == .paused else {
                DispatchQueue.main.async { self?.errorHandler?(STCountdownTimerError.timerNotRunning) }
                return
            }
            // 新的开始时间 = 当前时间 - (总时长 - 剩余时长)
            // 也就是在 (总时长 - 剩余时长) 之前开始的
            let timeAlreadyPassed = self.totalTime - self.remainingTime
            self.startDate = Date().addingTimeInterval(-timeAlreadyPassed)
            self.timer?.resume()
            self.state = .running
            STLog("▶️ (GCD) 倒计时恢复")
        }
    }

    /// 停止/取消
    public func stop() {
        self.queue.async { [weak self] in
            guard let self = self else { return }
            self.internalStop()
            STLog("⏹️ (GCD) 倒计时停止")
        }
    }
    
    /// 重置
    public func reset() {
        self.queue.async { [weak self] in
            guard let self = self else { return }
            self.internalStop()
            self.remainingTime = self.totalTime
            self.startDate = nil
            STLog("🔄 (GCD) 倒计时重置")
        }
    }
    
    public func getRemainingTime() -> TimeInterval {
        return self.queue.sync { max(0, self.remainingTime) }
    }
    
    public func getProgress() -> Double {
        return queue.sync { 1.0 - (remainingTime / totalTime) }
    }
        
    private func createAndResumeTimer() {
        if let oldTimer = self.timer {
            oldTimer.cancel()
            self.timer = nil
        }
        let timerSource = DispatchSource.makeTimerSource(flags: [], queue: self.queue)
        // 使用 .milliseconds(100) 即 0.1秒精度
        timerSource.schedule(deadline: .now(), repeating: .milliseconds(100), leeway: .milliseconds(10))
        timerSource.setEventHandler { [weak self] in
            self?.handleTimerTick()
        }
        self.timer = timerSource
        timerSource.resume()
    }
    
    private func internalStop() {
        if self.state == .paused {
            self.timer?.resume()
        }
        self.timer?.cancel()
        self.timer = nil
        self.state = .idle
        self.endBackgroundTask()
    }
    
    private func handleTimerTick() {
        guard let startDate = self.startDate, self.state == .running else { return }
        let now = Date()
        let elapsed = now.timeIntervalSince(startDate)
        let newRemainingTime = max(0, self.totalTime - elapsed)
        let currentSecond = Int(newRemainingTime)
        let previousSecond = Int(self.remainingTime)
        self.remainingTime = newRemainingTime
        if currentSecond != previousSecond {
             DispatchQueue.main.async { [weak self] in
                 guard let self = self else { return }
                 self.progressHandler?(self.remainingTime)
             }
        }
        if newRemainingTime <= 0 {
            self.internalStop()
            DispatchQueue.main.async { [weak self] in
                self?.completionHandler?()
            }
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let seconds = Int(time)
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }

    private func startBackgroundTask() {
        self.endBackgroundTask()
        self.backgroundTaskId = UIApplication.shared.beginBackgroundTask(withName: "STGCDCountdown") { [weak self] in
            self?.handleBackgroundTaskExpiration()
        }
    }
    
    private func endBackgroundTask() {
        if self.backgroundTaskId != .invalid {
            UIApplication.shared.endBackgroundTask(self.backgroundTaskId)
            self.backgroundTaskId = .invalid
        }
    }
    
    private func handleBackgroundTaskExpiration() {
        self.queue.async { [weak self] in
            guard let self = self else { return }
            guard self.state == .running else { return }
            if let startDate = self.startDate {
                let elapsed = Date().timeIntervalSince(startDate)
                self.remainingTime = max(0, self.totalTime - elapsed)
            }
            self.timer?.suspend()
            self.state = .paused
            self.endBackgroundTask()
            STLog("⏸️ (GCD) 后台时间耗尽，倒计时暂停，剩余: \(self.formatTime(self.remainingTime))")
            DispatchQueue.main.async { [weak self] in
                self?.errorHandler?(STCountdownTimerError.systemInterruption)
            }
        }
    }
    
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(appWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    private func removeNotificationObservers() {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func appWillEnterForeground() {
        self.queue.async { [weak self] in
            guard let self = self, self.state == .running, let start = self.startDate else { return }
            let elapsed = Date().timeIntervalSince(start)
            self.remainingTime = max(0, self.totalTime - elapsed)
            if self.remainingTime <= 0 {
                self.handleTimerTick()
            }
        }
    }
}
