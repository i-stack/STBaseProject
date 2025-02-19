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
    
    @IBOutlet weak var detailBtn: STBtn!
    private var aTarget: STTimer?
    private var delayTimer: Timer?
    private var delayTimerName: String?
    
    var count = 0
    var spacing = STBtnSpacing()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.timerBtn()
        self.detailBtn.backgroundColor = UIColor.orange
        
        spacing = STBtnSpacing.init(spacing: 5, topSpacing: 5)
        self.detailBtn.st_layoutButtonWithEdgeInsets(style: .top, spacing: spacing)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        count += 1
        if count == 1 {
            spacing = STBtnSpacing.init(spacing: 10, leftSpacing: 20)
        } else if count == 2 {
            spacing = STBtnSpacing.init(spacing: 10, rightSpacing: 20)
        } else if count == 3 {
            spacing = STBtnSpacing.init(spacing: 20, leftSpacing: 10, rightSpacing: 10)
        } else {
            count = 0
            spacing = STBtnSpacing.init(spacing: 10)
        }
        self.detailBtn.st_layoutButtonWithEdgeInsets(style: .left, spacing: spacing)
    }
    
    deinit {
        self.delayTimer?.invalidate()
        STLog("STNextViewController dealloc")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
//        self.delayTimer?.invalidate()
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
//        let url = URL(string: "https://www.baidu.com")!
//        let task = URLSession.shared.dataTask(with: url) { data, response, error in
//            if let error = error {
//                print("Error: \(error.localizedDescription)")
//            } else {
//                print("Success")
//            }
//        }
//        task.resume()
        
        STDeviceInfo.st_getNetworkInfo()
    }
}
