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
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        let nextVC = STTestViewController.init(nibName: "STTestViewController", bundle: nil)
        self.navigationController?.pushViewController(nextVC, animated: true)
    }
}
