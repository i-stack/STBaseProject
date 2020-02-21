//
//  STVerificationCodeBtn.swift
//  STBaseProject
//
//  Created by stack on 2020/2/8.
//  Copyright © 2020 ST. All rights reserved.
//

import UIKit

open class STVerificationCodeBtn: STBtn {

    private var timer: Timer?
    private var originTitle: String?
    open var titleSuffix: String = ""
    open var timerInterval: Int = 60

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
    
    public func beginTimer() -> Void {
        self.originTitle = self.titleLabel?.text
        self.timer = Timer.init(timeInterval: 1, target: self.timerTarger, selector: #selector(timerSelector), userInfo: nil, repeats: true)
        if let timer = self.timer {
            RunLoop.main.add(timer, forMode: RunLoop.Mode.common)
        }
    }
    
    @objc private func timerSelector() -> Void {
        DispatchQueue.main.async {
            if self.timerInterval == 0 {
                self.timerInterval = 60
                self.invalidTimer()
                self.isUserInteractionEnabled = true
                if let title = self.originTitle {
                    self.setTitle(title, for: UIControl.State.normal)
                } else {
                    self.setTitle("发送验证码", for: UIControl.State.normal)
                }
                return
            }
            self.timerInterval -= 1
            self.isUserInteractionEnabled = false
            self.setTitle("\(self.timerInterval)\(self.titleSuffix)", for: UIControl.State.normal)
        }
    }
    
    public func invalidTimer() -> Void {
        if self.timer?.isValid ?? false {
            self.timer?.invalidate()
            self.timer = nil
        }
    }
    
    private lazy var timerTarger: STTimerTarget = {
        let timer = STTimerTarget.init(aTarget: self)
        return timer
    }()
}
