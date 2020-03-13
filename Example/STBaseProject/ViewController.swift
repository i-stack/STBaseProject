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
        
    override func viewDidLoad() {
        super.viewDidLoad()
        self.st_showNavBtnType(type: .showBothBtn)
        self.titleLabel.text = "登录表示同意"
        self.leftBtn.backgroundColor = UIColor.red
        self.rightBtn.backgroundColor = UIColor.blue
        self.titleLabel.backgroundColor = UIColor.green
    }
}

