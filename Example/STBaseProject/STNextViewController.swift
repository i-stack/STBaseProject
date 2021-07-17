//
//  STNextViewController.swift
//  STBaseProject_Example
//
//  Created by song on 2021/1/7.
//  Copyright © 2021 STBaseProject. All rights reserved.
//

import UIKit
import SnapKit
import STBaseProject

class STNextViewController: STBaseViewController {
    
    


    deinit {
        STLog("STNextViewController dealloc")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.st_showNavBtnType(type: .showLeftBtn)
        self.view.backgroundColor = UIColor.orange
        self.view.addSubview(self.progressView)
        self.progressView.snp.makeConstraints { make in
            make.height.equalTo(20)
            make.top.equalTo(100)
            make.left.right.equalToSuperview()
        }
    }
    

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        for index in 1..<11 {
            self.progressView.setProgress(Float(index) * 0.1, animated: true)
        }
        
    }
    
    private lazy var progressView: UIProgressView = {
        var progress = UIProgressView()
        progress.progressTintColor = UIColor.green
//        progress.progress = 0.5
        progress.trackTintColor = UIColor.blue // huad
        return progress
    }()
}
