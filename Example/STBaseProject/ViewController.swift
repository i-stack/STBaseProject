//
//  ViewController.swift
//  STBaseProject
//
//  Created by stackMW on 05/16/2017.
//  Copyright (c) 2019 songMW. All rights reserved.
//

import UIKit
import SnapKit
import STBaseProject

class ViewController: STBaseViewController {
    
    var count: Int = 0
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        self.navigationController?.pushViewController(self.logvc, animated: true)
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { (timer) in
            self.logvc.update(log: "touchesBegan: \(self.count) + \(self.description) ")
            self.count += 1
        }
    }
    
    lazy var logvc: STLogViewController = {
        let vc = STLogViewController()
        return vc
    }()
}
