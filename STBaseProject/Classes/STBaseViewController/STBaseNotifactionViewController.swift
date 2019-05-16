//
//  STBaseNotifactionViewController.swift
//  STBaseProject
//
//  Created by song on 2019/5/7.
//  Copyright © 2019 song. All rights reserved.
//

import UIKit

extension STBaseViewController {
    
    func addNotification() -> Void {
        
    }
    
    // keyboard
    func addKeyboardShowNotification() -> Void {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(note:)), name: UIResponder.keyboardWillShowNotification , object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHidden(note:)), name: UIResponder.keyboardWillHideNotification , object: nil)
    }
    
    // switch language
    func addLanguageDidChangeNotification() -> Void {
        NotificationCenter.default.addObserver(self, selector: #selector(languageChange), name: NSNotification.Name(rawValue: STNotificationName().st_languageDidChangeNotification) , object: nil)
    }
    
    // 截屏通知
    func addUserDidTakeScreenshotNotification() -> Void {
        NotificationCenter.default.addObserver(self, selector: #selector(userDidTakeScreenshot(note:)), name: UIApplication.userDidTakeScreenshotNotification, object: nil)
    }
}

// 通知回调
extension STBaseViewController {
    
    @objc func languageChange() -> Void {
        
    }
    
    @objc func networkStatusChange() -> Void {
        
    }
    
    @objc func keyboardWillShow(note: NSNotification) -> Void {
        
    }
    
    @objc func keyboardWillHidden(note: NSNotification) -> Void {
        
    }
    
    @objc func userDidTakeScreenshot(note: NSNotification) -> Void {
        print("warning ======  检测到截屏")
    }
}
