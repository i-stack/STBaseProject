//
//  STWindowManager.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2018/10/10.
//

import UIKit

public extension UIView {
    
    /// 获取UIWindow
    /// - Returns: UIWindow
    func st_keyWindow() -> UIWindow? {
        return UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.flatMap { $0.windows }.first { $0.isKeyWindow }
    }
}
