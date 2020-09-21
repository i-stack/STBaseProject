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
        for index in 0...100 {
            STLog("\(index)")
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        for index in 100...200 {
            STLog("\(index)")
        }
    }
    
    lazy var testView: STTestView = {
        let view = STTestView.init(frame: CGRect.init(x: 0, y: 0, width: 100, height: 200))
        return view
    }()
}
