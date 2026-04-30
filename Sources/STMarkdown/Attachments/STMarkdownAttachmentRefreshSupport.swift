//
//  STMarkdownAttachmentRefreshSupport.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2019/03/16.
//

import UIKit

enum STMarkdownAttachmentRefreshSupport {
    /// 绑定 attachment 就绪后的刷新回调。回调携带触发刷新的 attachment，
    /// 调用方可据此在当前 attributedText 里定位其 range，只刷新该局部。
    static func bindRefreshHandlers(
        in attributedText: NSAttributedString,
        refresh: @escaping @MainActor (_ attachment: NSTextAttachment) -> Void
    ) {
        let range = NSRange(location: 0, length: attributedText.length)
        guard range.length > 0 else { return }
        attributedText.enumerateAttribute(.attachment, in: range) { value, _, _ in
            guard let attachment = value as? STMarkdownAsyncImageAttachment else { return }
            attachment.onNeedsDisplay = { [weak attachment] in
                guard let attachment else { return }
                Task { @MainActor in
                    refresh(attachment)
                }
            }
        }
    }
}
