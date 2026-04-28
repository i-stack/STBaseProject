//
//  STAntiDebugMonitor.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2018/12/10.
//

import Foundation

// MARK: - 反调试监控器
public final class STAntiDebugMonitor {

    public var onSecurityIssue: ((STSecurityIssue) -> Void)?

    private var timer: STTimer?
    private var isMonitoring = false // 仅在主线程访问，与 Timer 同线程
    private let config: STAntiDebugConfig
    private let securityCheck: () -> STSecurityCheckResult

    public init(config: STAntiDebugConfig, securityCheck: @escaping () -> STSecurityCheckResult = { STSecurityConfig.shared.st_performSecurityCheck() } ) {
        self.config = config
        self.securityCheck = securityCheck
    }

    /// 开始定时安全检测。若已在监控或 config.enabled == false 则空操作。
    public func st_startMonitoring() {
        guard self.config.enabled else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self, !self.isMonitoring else { return }
            self.isMonitoring = true
            let timer = STTimer(interval: self.config.checkInterval)
            timer.start { [weak self] _ in
                self?.st_runCheck()
            }
            self.timer = timer
        }
    }

    /// 停止定时检测。可安全多次调用。
    public func st_stopMonitoring() {
        DispatchQueue.main.async { [weak self] in
            self?.st_cancelTimer()
        }
    }

    private func st_runCheck() {
        let result = self.securityCheck()
        guard !result.isSecure else { return }
        result.issues.forEach { self.onSecurityIssue?($0) }
    }

    private func st_cancelTimer() {
        self.timer?.stop()
        self.timer = nil
        self.isMonitoring = false
    }

    deinit {
        if Thread.isMainThread {
            self.st_cancelTimer()
        } else {
            let t = self.timer
            DispatchQueue.main.async { t?.stop() }
        }
    }
}
