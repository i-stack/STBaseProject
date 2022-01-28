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
        
        self.view.addSubview(self.testView)
        self.testView.snp.makeConstraints { make in
            make.top.left.bottom.right.equalTo(0)
        }
    }
    
    lazy var testView: STTestView = {
        let view = STTestView()
        return view
    }()
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
    }
}
