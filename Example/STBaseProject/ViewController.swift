//
//  ViewController.swift
//  STBaseProject
//
//  Created by songMW on 05/16/2019.
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
        self.testScreenShot()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.testScanner()
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

}

