//
//  STVerificationCodeBtn.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2020/2/8.
//

import UIKit

@IBDesignable
open class STVerificationCodeBtn: STBtn {

    private var timer: STTimer?
    private var endDate: Date?
    private var originTitle: String?
    private var remainingTimerInterval: Int = 0

    /// Display suffix 10s, 10 seconds
    @IBInspectable open var titleSuffix: String = ""
    
    /// Countdown interval time
    @IBInspectable open var interval: TimeInterval = 1 {
        didSet {
            guard self.interval <= 0 else { return }
            self.interval = oldValue > 0 ? oldValue : 1
        }
    }
    
    /// Countdown end time
    @IBInspectable open var timerInterval: Int = 60 {
        didSet {
            guard self.timerInterval < 0 else { return }
            self.timerInterval = 0
        }
    }

    deinit {
        self.invalidTimer()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override open func awakeFromNib() {
        super.awakeFromNib()
    }
    
    public func st_configDone() {
        self.originTitle = self.title(for: .normal) ?? self.titleLabel?.text
    }
    
    public func beginTimer() -> Void {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.beginTimer()
            }
            return
        }
        guard self.timer == nil else { return }
        self.invalidTimer()
        if self.originTitle == nil {
            self.originTitle = self.title(for: .normal) ?? self.titleLabel?.text
        }
        let countdownDuration = max(self.timerInterval, 0)
        self.remainingTimerInterval = countdownDuration
        guard self.remainingTimerInterval > 0 else {
            self.restoreTimerState()
            return
        }
        self.endDate = Date().addingTimeInterval(TimeInterval(countdownDuration))
        self.isEnabled = false
        self.updateCountdownTitle()
        let timer = STTimer(interval: self.interval)
        timer.start { [weak self] timer in
            self?.timerSelector(timer)
        }
        self.timer = timer
    }
    
    private func timerSelector(_ timer: STTimer) -> Void {
        guard self.timer === timer else { return }
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self, weak timer] in
                guard let timer else { return }
                self?.timerSelector(timer)
            }
            return
        }
        self.updateRemainingTimerInterval()
        guard self.remainingTimerInterval > 0 else {
            self.resetCountdown()
            return
        }
        self.updateCountdownTitle()
    }
    
    public func invalidTimer() -> Void {
        self.timer?.stop()
        self.timer = nil
    }
    
    public func resetCountdown() -> Void {
        self.invalidTimer()
        self.restoreTimerState()
    }
    
    private func updateCountdownTitle() {
        self.setTitle("\(self.remainingTimerInterval)\(self.titleSuffix)", for: UIControl.State.normal)
    }
    
    private func updateRemainingTimerInterval() {
        guard let endDate = self.endDate else {
            self.remainingTimerInterval = 0
            return
        }
        self.remainingTimerInterval = max(0, Int(ceil(endDate.timeIntervalSinceNow)))
    }
    
    private func restoreTimerState() {
        self.endDate = nil
        self.isEnabled = true
        self.remainingTimerInterval = 0
        self.setTitle(self.originTitle ?? self.title(for: .normal) ?? "发送验证码", for: UIControl.State.normal)
    }
}
