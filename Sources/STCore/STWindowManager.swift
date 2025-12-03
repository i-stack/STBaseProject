//
//  STWindowManager.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2018/10/10.
//

import UIKit

// MARK: - 窗口管理扩展
public extension UIView {
    
    /// 获取关键窗口
    /// - Returns: 关键窗口
    func st_keyWindow() -> UIWindow? {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            for window in windowScene.windows {
                if window.isKeyWindow {
                    return window
                }
            }
        }
        return nil
    }
}
