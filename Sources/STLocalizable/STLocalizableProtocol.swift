//
//  STLocalizableProtocol.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2018/10/10.
//

import UIKit

// MARK: - 本地化协议
// 由各 ST 封装控件（STLabel / STBtn / STTextField 等）显式实现，
// 视图树遍历通过此协议触发运行时语言切换刷新。
@objc public protocol STLocalizable: AnyObject {
    func st_updateLocalizedText()
}
