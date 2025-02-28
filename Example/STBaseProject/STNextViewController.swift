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
    
    deinit {
        STLog("STNextViewController dealloc")
    }
   
    override func viewDidLoad() {
        super.viewDidLoad()
        self.timerBtn()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
}

extension STNextViewController {
    @objc func testTimer() {
        
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
        STLocationManager.shared.st_startUpdatingLocation { info in
            STLog(info)
            STLocationManager.shared.st_stopUpdatingLocation()
        }
    }
}
