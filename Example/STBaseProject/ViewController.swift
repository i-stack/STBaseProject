//
//  ViewController.swift
//  STBaseProject
//
//  Created by songMW on 05/16/2017.
//  Copyright (c) 2019 songMW. All rights reserved.
//

import UIKit
import SnapKit
import STBaseProject

class ViewController: STBaseViewController {
        
    override func viewDidLoad() {
        super.viewDidLoad()
        self.st_showNavBtnType(type: .none)
        
        let str = "登录表示同意《用户协议》及《隐私协议》"
        let label = UILabel.init(frame: CGRect.init(x: 0, y: 100, width: 300, height: 50))
        label.attributedText = str.st_attributed(originStr: str, originStrColor: UIColor.black, originStrFont: UIFont.st_boldSystemFont(ofSize: 14), replaceStrs: ["《用户协议》", "《隐私协议》"], replaceStrColors: [UIColor.blue, UIColor.orange], replaceStrFonts: [UIFont.st_systemFont(ofSize: 11), UIFont.st_systemFont(ofSize: 15)])
        self.view.addSubview(label)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
}

