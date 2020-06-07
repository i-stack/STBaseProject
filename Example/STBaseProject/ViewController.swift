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
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        let helpVC = STWebViewController.init(url: "https://www.baidu.com", htmlString: "", title: "帮助与反馈", showProgress: false)
        self.navigationController?.pushViewController(helpVC, animated: true)
    }
}

