//
//  STMarkdownInteraction.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2019/03/16.
//

import Foundation

/// UI 层 Markdown 交互入口协议。
///
/// 所有成员均会更新 UI 状态或触发 UI 回调，协议被约束在 `MainActor`，
/// 以便在严格并发模式下避免后台线程访问 UI。
@MainActor
public protocol STMarkdownInteractable: AnyObject {
    var onLinkTap: ((URL) -> Void)? { get set }
    var onSelectionChange: ((String) -> Void)? { get set }
    var isTextSelectionEnabled: Bool { get set }
}
