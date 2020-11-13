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
        self.st_showNavBtnType(type: .onlyShowTitle)
        self.view.addSubview(self.applianceNameLabel)
        self.applianceNameLabel.snp.makeConstraints { (make) in
            make.top.equalTo(STConstants.st_handleFloat(float: 100))
            make.left.equalTo(STConstants.st_handleFloat(float: 10))
            make.right.equalTo(STConstants.st_handleFloat(float: -10))
//            make.height.equalTo(STConstants.st_handleFloat(float: 40))
        }
        self.applianceNameLabel.text = "中华人民共和国于1949年10月1日正式成立，good!"
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
    }
    
    lazy var testView: STTestView = {
        let view = STTestView.init(frame: CGRect.init(x: 0, y: 0, width: 100, height: 200))
        return view
    }()
    
    lazy var applianceNameLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.textColor = UIColor.red
        label.numberOfLines = 0
        let fontSize = 18 * STConstants.st_multiplier()
        print("current size:", self.view.bounds, "current font:", fontSize)
        label.font = UIFont.st_systemFont(ofSize: 18, weight: .regular)
        return label
    }()
}
