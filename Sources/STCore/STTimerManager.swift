//
//  STTimerManager.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2024/01/01.
//

import Foundation
import Combine

public class STTimerManager {

    public static let shared = STTimerManager()

    private var timer: Timer?
    private var timerTask: (() -> Void)?
    private var timeInterval: TimeInterval = 10 * 60 // 10分钟
    public private(set) var isRunning: Bool = false
    private var cancellables: Set<AnyCancellable> = []

    private init() {}
    
    /// 启动定时器
    /// - Parameters:
    ///   - interval: 时间间隔（秒），默认10分钟
    ///   - task: 定时执行的任务
    public func st_startTimer(interval: TimeInterval = 10 * 60, task: @escaping () -> Void) {
        guard !isRunning else {
            STLog("⚠️ 定时器已在运行中")
            return
        }
        guard interval > 0 else {
            STLog("⚠️ 时间间隔必须大于0秒")
            return
        }
        self.timeInterval = interval
        self.timerTask = task
        self.timerTask!()
        self.timer = Timer.scheduledTimer(
            timeInterval: timeInterval,
            target: self,
            selector: #selector(st_timerFired),
            userInfo: nil,
            repeats: true
        )
        if let timer = self.timer {
            RunLoop.main.add(timer, forMode: .common)
        }
        self.isRunning = true
        STLog("✅ 定时器已启动，间隔: \(timeInterval)秒")
    }
    
    /// 停止定时器
    public func st_stopTimer() {
        self.timer?.invalidate()
        self.timer = nil
        self.timerTask = nil
        self.isRunning = false
        self.cancellables.removeAll()
        STLog("⏹️ 定时器已停止")
    }
    
    // MARK: - 定时器回调
    @objc private func st_timerFired() {
        STLog("⏰ 定时器触发 - \(Date())")
        self.timerTask!()
    }
        
    deinit {
        st_stopTimer()
    }
}

