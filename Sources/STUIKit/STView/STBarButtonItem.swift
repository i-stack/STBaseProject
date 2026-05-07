//
//  STBarButtonItem.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2019/1/21.
//

import UIKit

public extension UIBarButtonItem {

    /// 构造指定宽度的固定间隔 UIBarButtonItem
    /// - Parameter width: 间隔宽度
    /// - Returns: 配置好 width 的固定空白按钮
    static func fixedSpace(width: CGFloat) -> UIBarButtonItem {
        let item = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        item.width = width
        return item
    }

    /// 构造自适应间隔 UIBarButtonItem
    static var flexibleSpace: UIBarButtonItem {
        UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
    }
}
