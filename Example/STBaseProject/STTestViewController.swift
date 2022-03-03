//
//  STTestViewController.swift
//  STBaseProject_Example
//
//  Created by song on 2021/1/28.
//  Copyright © 2021 STBaseProject. All rights reserved.
//

import UIKit
import STBaseProject

class STTestViewController: STBaseViewController {
    
    deinit {
        STLogP("STTestViewController dealloc")
    }
    
    var count: Int = 0
    override func viewDidLoad() {
        super.viewDidLoad()
        self.titleLabel.text = "STTestViewController"
        self.st_showNavBtnType(type: .showLeftBtn)
        self.view.backgroundColor = UIColor.blue
        STLogP("STTestViewController execting count: \(self.count)")
        
//        self.view.addSubview(self.testView)
//        self.testView.snp.makeConstraints { make in
//            make.top.left.bottom.right.equalTo(0)
//        }
    }
    
    lazy var testView: STTestView = {
        let view = STTestView()
        return view
    }()
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        
//        let name = STTimer.st_execTask(task: {
//            STLog("1111")
//
//        }, start: 0, interval: 1, repeates: true, async: true)
//
////        DispatchQueue.global().async {
////            STTimer.st_execTask(task: {
////                STLog("222")
////            }, start: 0, interval: 1, repeates: true, async: true)
////        }
////
//        STTimer.st_execTask(task: {
////            STLog("3333")
//        }, start: 0, interval: 1, repeates: true, async: false)
//
//        STTimer.st_execTask(task: {
////            STLog("3333")
//        }, start: 0, interval: 1, repeates: true, async: true)
//
//        STTimer.st_cancelTask(name: name)
        
        STTimer.st_scheduledTimer(withTimeInterval: 1, repeats: true, async: true) { name in
            STLog("1111")
            STTimer.st_cancelTask(name: name)
        }
    }
}
