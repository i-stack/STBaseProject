//
//  STMarkdownDefaultHorizontalRuleRenderer.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2019/03/16.
//

import UIKit

public struct STMarkdownDefaultHorizontalRuleRenderer: STMarkdownHorizontalRuleRendering {
    public init() {}

    public func renderHorizontalRule(style: STMarkdownStyle) -> NSAttributedString? {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = style.lineHeight
        paragraphStyle.maximumLineHeight = style.lineHeight
        paragraphStyle.paragraphSpacing = style.paragraphSpacing
        paragraphStyle.alignment = .natural
        paragraphStyle.lineBreakMode = .byClipping

        // 优先 horizontalRuleColor → 退回 dividerColor → 再退回 textColor 28% 透明度。
        // dividerColor 是早期遗留 dead config，在分隔线场景里语义最贴近，先于默认色。
        let color = style.horizontalRuleColor
            ?? style.dividerColor
            ?? style.textColor.withAlphaComponent(0.28)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.st_systemFont(ofSize: max(style.font.pointSize - 2, 12), weight: .regular),
            .foregroundColor: color,
            .paragraphStyle: paragraphStyle,
        ]

        return NSAttributedString(
            string: String(repeating: "─", count: max(style.horizontalRuleLength, 12)),
            attributes: attributes
        )
    }
}
