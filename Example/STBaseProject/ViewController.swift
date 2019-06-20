//
//  ViewController.swift
//  STBaseProject
//
//  Created by songMW on 05/16/2017.
//  Copyright (c) 2019 songMW. All rights reserved.
//

import UIKit
import STBaseProject

class ViewController: STBaseOpenSystemOperationController {
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.testIndicatorBtn()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
//        self.testScanner()
    }
    
    func testScanner() -> Void {
        let scannerVC = STScanViewController.init(qrType: .STScanTypeQrCode) { (result) in
            print(result)
        }
        self.navigationController?.pushViewController(scannerVC, animated: true)
    }
    
    func testScreenShot() -> Void {
        NotificationCenter.default.addObserver(self, selector: #selector(userDidTakeScreenshot(note:)), name: UIApplication.userDidTakeScreenshotNotification, object: nil)
    }
    
    
    @objc func userDidTakeScreenshot(note: NSNotification) -> Void {
        print("warning ======  userDidTakeScreenshot")
        // call st_showScreenshotImage(rect: CGRect) class method can return UIImageView
        // call st_imageWithScreenshot() class method can return UIImage
    }
    
    func testIndicatorBtn() -> Void {
        let btn = STIndicatorBtn()
        btn.cornerRadius = 4
        btn.frame = CGRect.init(x: 0, y: 200, width: self.view.bounds.width, height: 40)
        btn.setTitle("loading", for: UIControl.State.normal)
        btn.addTarget(self, action: #selector(btnClick), for: UIControl.Event.touchUpInside)
        btn.backgroundColor = UIColor.green
        self.view.addSubview(btn)
        btn.tag = 100
    }
    
    @objc func btnClick() -> Void {
        let btn: STIndicatorBtn = self.view.viewWithTag(100) as! STIndicatorBtn
        if btn.st_indicatorIsAnimating {
            btn.st_indicatorStopAnimating()
        } else {
            btn.st_indicatorStartAnimating()
        }
//        btn.st_indicatorStartAnimating()
    }

}

