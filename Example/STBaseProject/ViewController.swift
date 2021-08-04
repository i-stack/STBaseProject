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
        self.st_showNavBtnType(type: .onlyShowTitle)
        self.titleLabel.text = "ViewController"
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        let nextVC = STTestViewController.init(nibName: "STTestViewController", bundle: nil)
        self.navigationController?.pushViewController(nextVC, animated: true)
    }
}
