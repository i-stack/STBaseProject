//
//  STBaseNotifactionViewController.swift
//  STBaseProject
//
//  Created by song on 2019/5/7.
//  Copyright © 2019 song. All rights reserved.
//

import UIKit

extension STBaseViewController {
    
    func st_addNotification() -> Void {
        
    }
    
    // keyboard
    func st_addKeyboardShowNotification() -> Void {
        NotificationCenter.default.addObserver(self, selector: #selector(st_keyboardWillShow(note:)), name: UIResponder.keyboardWillShowNotification , object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(st_keyboardWillHidden(note:)), name: UIResponder.keyboardWillHideNotification , object: nil)
    }
    
    // switch language
    func st_addLanguageDidChangeNotification() -> Void {
        NotificationCenter.default.addObserver(self, selector: #selector(st_languageChange), name: NSNotification.Name(rawValue: STNotificationName().st_languageDidChangeNotification) , object: nil)
    }
    
    // 截屏通知
    func st_addUserDidTakeScreenshotNotification() -> Void {
        NotificationCenter.default.addObserver(self, selector: #selector(st_userDidTakeScreenshot(note:)), name: UIApplication.userDidTakeScreenshotNotification, object: nil)
    }
}

// 通知回调
extension STBaseViewController {
    
    @objc open func st_languageChange() -> Void {
        
    }
    
    @objc open func st_networkStatusChange() -> Void {
        
    }
    
    @objc open func st_keyboardWillShow(note: NSNotification) -> Void {
        
    }
    
    @objc open func st_keyboardWillHidden(note: NSNotification) -> Void {
        
    }
    
    @objc func st_userDidTakeScreenshot(note: NSNotification) -> Void {
        print("warning ======  检测到截屏")
    }
}
