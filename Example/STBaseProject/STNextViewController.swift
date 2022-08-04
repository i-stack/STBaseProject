//
//  STNextViewController.swift
//  STBaseProject_Example
//
//  Created by qcraft on 2022/8/4.
//  Copyright © 2022 STBaseProject. All rights reserved.
//

import UIKit
import STBaseProject

class STNextViewController: STBaseViewController {
    
    private var aTarget: STTimer?
    private var delayTimer: Timer?
    private var delayTimerName: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.timerBtn()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
    }
    
    deinit {
        self.delayTimer?.invalidate()
        STLog("STNextViewController dealloc")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
//        self.delayTimer?.invalidate()
        STTimerGCD.st_cancelTask(name: self.delayTimerName ?? "")
    }
}

extension STNextViewController {
    
    func testTimer() {
//        let timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(handleHideTimer), userInfo: nil, repeats: true)
//        delayTimer = timer
        
//        let timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
//            STLog("handleHideTimer")
//        }
//        self.delayTimer = timer
        
//        let timer = Timer.init(timeInterval: 1, target: self, selector: #selector(handleHideTimer), userInfo: nil, repeats: true)
//        RunLoop.current.add(timer, forMode: .common)
//        self.delayTimer = timer
//
//        let timer = Timer.init(timeInterval: 1, repeats: true) { timer in
//            STLog("handleHideTimer")
//        }
//        RunLoop.current.add(timer, forMode: .common)
//        self.delayTimer = timer
        
        let timer = STTimerGCD.st_scheduledTimer(withTimeInterval: 1, repeats: true, async: true) { name in
            STLog(name)
        }
        self.delayTimerName = timer
        
//        self.aTarget = STTimer.init(aTarget: self)
//        let timer = Timer.scheduledTimer(timeInterval: 1, target: self.aTarget ?? nil, selector: #selector(handleHideTimer), userInfo: nil, repeats: true)
//        self.delayTimer = timer
    }
    
    @objc func handleHideTimer() {
        STLog("handleHideTimer")
    }
    
    func timerBtn() {
        let btn = STBtn()
        btn.backgroundColor = UIColor.orange
        btn.frame = CGRect.init(x: 10, y: 300, width: 380, height: 100)
        btn.setTitle("begin", for: .normal)
        btn.setTitleColor(UIColor.red, for: .normal)
        btn.addTarget(self, action: #selector(btnClick(sender:)), for: .touchUpInside)
        self.view.addSubview(btn)
    }
    
    @objc func btnClick(sender: STBtn) {
        testTimer()
    }
}
