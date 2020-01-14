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

class ViewController: STBaseOpenSystemOperationController {
    
    var testView: STTestView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.st_showNavBtnType(type: .none)
        
        self.testView = STTestView()
        self.view.addSubview(self.testView!)
        self.testView?.snp.makeConstraints({ (make) in
            make.top.left.bottom.right.equalTo(0)
        })
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let model = STBaseModel()
        model.setValue("hhh", forKey: "jjj")
    }
}

