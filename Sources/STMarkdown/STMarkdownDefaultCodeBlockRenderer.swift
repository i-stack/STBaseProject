//
//  STMarkdownDefaultCodeBlockRenderer.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2019/03/16.
//

import UIKit

public struct STMarkdownDefaultCodeBlockRenderer: STMarkdownCodeBlockRendering {
    public init() {}

    public func renderCodeBlock(
        language: String?,
        code: String,
        style: STMarkdownStyle
    ) -> NSAttributedString? {
        let result = NSMutableAttributedString()
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = style.lineHeight
        paragraphStyle.maximumLineHeight = style.lineHeight
        paragraphStyle.paragraphSpacing = style.paragraphSpacing
        paragraphStyle.lineBreakMode = .byCharWrapping

        let headerAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.monospacedSystemFont(ofSize: max(style.font.pointSize - 2, 12), weight: .semibold),
            .foregroundColor: style.codeBlockHeaderTextColor ?? style.textColor.withAlphaComponent(0.72),
            .backgroundColor: style.codeBlockBackgroundColor ?? UIColor.secondarySystemBackground,
            .paragraphStyle: paragraphStyle,
        ]

        let bodyAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.monospacedSystemFont(ofSize: max(style.font.pointSize - 1, 12), weight: .regular),
            .foregroundColor: style.codeBlockTextColor ?? style.textColor,
            .backgroundColor: style.codeBlockBackgroundColor ?? UIColor.secondarySystemBackground,
            .paragraphStyle: paragraphStyle,
        ]

        if let language, language.isEmpty == false {
            result.append(NSAttributedString(string: language.uppercased(), attributes: headerAttributes))
            result.append(NSAttributedString(string: "\n", attributes: bodyAttributes))
        }

        result.append(NSAttributedString(string: code, attributes: bodyAttributes))
        return result
    }
}
