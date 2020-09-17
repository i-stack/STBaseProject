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
        self.logDataSources(log: "11111")
        self.st_showNavBtnType(type: .onlyShowTitle)
        STLog("5555")
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        let path = STFileManager.create(filePath: "\(STFileManager.getLibraryCachePath())/ViewController.swift", fileName: "log.text")
        STFileManager.writeToFile(content: "2222", filePath: path)
        STFileManager.writeToFile(content: "3333", filePath: path)
    }
    
    lazy var testView: STTestView = {
        let view = STTestView.init(frame: CGRect.init(x: 0, y: 0, width: 100, height: 200))
        return view
    }()
}
