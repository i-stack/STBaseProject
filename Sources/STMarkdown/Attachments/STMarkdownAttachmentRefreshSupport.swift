//
//  STMarkdownAttachmentRefreshSupport.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2019/03/16.
//

import UIKit

enum STMarkdownAttachmentRefreshSupport {
    /// 为 `attributedText` 内所有可刷新 attachment 注册刷新观察者。
    ///
    /// 与早期覆盖式赋值不同，这里走 `STMarkdownRefreshableAttachment.addDisplayObserver`
    /// 走多播订阅，同一个 attachment 被多个 TextView 同时挂载时不会互相覆盖。
    /// 调用方需要持有返回的 `[STMarkdownRefreshObservation]`，在文本被替换或 TextView
    /// 销毁时通过 `invalidate()` 解绑，否则旧 TextView 会继续被回调（虽然 `[weak self]`
    /// 会让回调成为 no-op，但仍会保留多余的 entry 直到 attachment 释放）。
    ///
    /// - Parameters:
    ///   - attributedText: 待扫描的富文本。
    ///   - refresh: 主线程闭包；图像就绪时会在主线程被调用，参数为触发刷新的 attachment。
    /// - Returns: 注册产生的 observation token 数组，调用方持有以控制生命周期。
    @discardableResult
    static func bindRefreshHandlers(
        in attributedText: NSAttributedString,
        refresh: @escaping @MainActor (_ attachment: NSTextAttachment) -> Void
    ) -> [STMarkdownRefreshObservation] {
        let range = NSRange(location: 0, length: attributedText.length)
        guard range.length > 0 else { return [] }
        var tokens: [STMarkdownRefreshObservation] = []
        attributedText.enumerateAttribute(.attachment, in: range) { value, _, _ in
            guard let attachment = value as? STMarkdownRefreshableAttachment else { return }
            let token = attachment.addDisplayObserver { [weak attachment] in
                guard let attachment else { return }
                // 发射端 (`STMarkdownAsyncImageAttachment.loadImage`) 已通过
                // `DispatchQueue.main.async` 保证回调在主线程触发；这里直接同步执行避免
                // 多一帧延迟。若调用链未来发生变化导致不在主线程，再降级到一次主线程派发。
                if Thread.isMainThread {
                    MainActor.assumeIsolated {
                        refresh(attachment)
                    }
                } else {
                    DispatchQueue.main.async {
                        MainActor.assumeIsolated {
                            refresh(attachment)
                        }
                    }
                }
            }
            tokens.append(token)
        }
        return tokens
    }
}
