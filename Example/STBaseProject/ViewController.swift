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
        self.contryCode()
    }
    
    func contryCode() -> Void {
        let codeInfo = STISOCountryCodeInfo()
        codeInfo.st_requestCoutryCode(success: { (model) in

        }) { (error) in

        }
    }
}

