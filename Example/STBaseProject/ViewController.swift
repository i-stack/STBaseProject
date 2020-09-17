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
//        let path = STFileManager.create(filePath: "\(STFileManager.getLibraryCachePath())/ViewController.swift", fileName: "log.text")
//        STFileManager.writeToFile(content: "2222", filePath: path)
//        STFileManager.writeToFile(content: "3333", filePath: path)
        
        let path = STConstants.st_outputLogPath()
        if let pathURL = URL.init(string: path) {
            let documentController = UIDocumentInteractionController(url: URL.init(fileURLWithPath: path))
            documentController.delegate = self
            let result = documentController.presentOpenInMenu(from: CGRect.init(x: 0, y: 0, width: self.view.bounds.size.width, height: 400), in: self.view, animated: true)
           if !result {
               print("打开失败")
           }
        }
    }
    
    lazy var testView: STTestView = {
        let view = STTestView.init(frame: CGRect.init(x: 0, y: 0, width: 100, height: 200))
        return view
    }()
}

extension ViewController: UIDocumentInteractionControllerDelegate {
    public func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
        return self
    }
    
    public func documentInteractionControllerViewForPreview(_ controller: UIDocumentInteractionController) -> UIView? {
        return self.view
    }
    
    public func documentInteractionControllerRectForPreview(_ controller: UIDocumentInteractionController) -> CGRect {
        return self.view.bounds
    }
}
