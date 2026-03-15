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
        paragraphStyle.alignment = .center

        let color = style.horizontalRuleColor ?? style.textColor.withAlphaComponent(0.28)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: max(style.font.pointSize - 2, 12), weight: .regular),
            .foregroundColor: color,
            .paragraphStyle: paragraphStyle,
        ]

        return NSAttributedString(
            string: String(repeating: "─", count: max(style.horizontalRuleLength, 12)),
            attributes: attributes
        )
    }
}
