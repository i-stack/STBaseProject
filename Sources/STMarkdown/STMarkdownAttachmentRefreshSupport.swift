//
//  STMarkdownAttachmentRefreshSupport.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2019/03/16.
//

import UIKit

enum STMarkdownAttachmentRefreshSupport {
    static func bindRefreshHandlers(in attributedText: NSAttributedString, refresh: @escaping @MainActor () -> Void) {
        let range = NSRange(location: 0, length: attributedText.length)
        guard range.length > 0 else { return }
        attributedText.enumerateAttribute(.attachment, in: range) { value, _, _ in
            guard let attachment = value as? STMarkdownAsyncImageAttachment else { return }
            attachment.onNeedsDisplay = {
                Task { @MainActor in
                    refresh()
                }
            }
        }
    }
}
