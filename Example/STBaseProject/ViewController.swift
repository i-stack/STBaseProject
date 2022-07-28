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
        self.st_showNavBtnType(type: .onlyShowTitle)
        self.titleLabel.text = "ViewController"
        let imageView = UIImageView()
        imageView.sd_setImage(with: URL.init(string: "https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/de66ab3f19a5499eb6ceff64db5e9476~tplv-k3u1fbpfcp-zoom-in-crop-mark:3024:0:0:0.awebp"))
        self.view.addSubview(imageView)
        
        dispatch_main_async_safe {[weak self]
            
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        let nextVC = STTestViewController.init(nibName: "STTestViewController", bundle: nil)
        self.navigationController?.pushViewController(nextVC, animated: true)
    }
    
    @objc func randomString() {
//        var dict: Dictionary<String, String> = Dictionary<String, String>()
//        for i in 0..<1000 {
//            dict["key\(i)"] = "\(i)"
//        }
//
//        do {
//            let jsonData = try JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted)
//            let outputPath = "\(STFileManager.getLibraryCachePath())/jsonData"
//            let pathIsExist = STFileManager.fileExistAt(path: outputPath)
//            let path = STFileManager.create(filePath: outputPath, fileName: "json.json")
//            print(outputPath)
//            try jsonData.write(to: URL.init(fileURLWithPath: path), options: .atomic)
//        } catch {
//
//        }
        print("randomString")
        print(Thread.current)

        dispatch_main_async_safe {
            print(Thread.current)
        }
    }
}
