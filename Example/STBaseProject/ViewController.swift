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
import SDWebImage

class ViewController: STBaseViewController {
        
    override func viewDidLoad() {
        super.viewDidLoad()
        self.titleLabel.text = "ViewController"
        self.titleLabel.textColor = UIColor.black
        self.st_showNavBtnType(type: .onlyShowTitle)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        let nextVC = STNextViewController.init(nibName: "STNextViewController", bundle: nil)
        self.navigationController?.pushViewController(nextVC, animated: true)
    }
}

extension ViewController {
    @objc func testRandomString() {
        var dict: Dictionary<String, String> = Dictionary<String, String>()
        for i in 0..<1000 {
            dict["key\(i)"] = "\(i)"
        }

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted)
            let outputPath = "\(STFileManager.getLibraryCachePath())/jsonData"
            let pathIsExist = STFileManager.fileExistAt(path: outputPath)
            if pathIsExist.0 {
                let path = STFileManager.create(filePath: outputPath, fileName: "json.json")
                print(outputPath)
                try jsonData.write(to: URL.init(fileURLWithPath: path), options: .atomic)
            } else {
                print(outputPath + "not exist")
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func testBtn() {
        let btn = STBtn()
        btn.backgroundColor = UIColor.orange
        btn.frame = CGRect.init(x: 10, y: 300, width: 380, height: 100)
        btn.setTitle("test001", for: .normal)
        btn.setTitleColor(UIColor.red, for: .normal)
        btn.setImage(UIImage.init(named: "Image"), for: .normal)
        btn.st_layoutButtonWithEdgeInsets(style: .bottom, imageTitleSpace: 10)
        btn.addTarget(self, action: #selector(btnClick(sender:)), for: .touchUpInside)
        self.view.addSubview(btn)
    }
    
    @objc func btnClick(sender: STBtn) {
        sender.st_layoutButtonWithEdgeInsets(style: .reset, imageTitleSpace: 0)
    }
}
