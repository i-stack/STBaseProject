//
//  STMarkdownDefaultImageRenderer.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2019/03/16.
//

import UIKit

public struct STMarkdownDefaultImageRenderer: STMarkdownImageRendering {
    public init() {}

    public func renderImage(
        url: String,
        altText: String,
        title: String?,
        style: STMarkdownStyle,
        inline: Bool
    ) -> NSAttributedString? {
        let label = self.displayLabel(url: url, altText: altText, inline: inline)
        if inline {
            return self.renderInlineImage(label: label, style: style)
        }
        return self.renderBlockImage(label: label, title: title, style: style)
    }
}

private extension STMarkdownDefaultImageRenderer {
    func displayLabel(url: String, altText: String, inline: Bool) -> String {
        if altText.isEmpty == false {
            return altText
        }
        if let lastPath = URL(string: url)?.lastPathComponent, lastPath.isEmpty == false {
            return inline ? lastPath : "[image] \(lastPath)"
        }
        return inline ? "[img]" : "[image]"
    }

    func renderInlineImage(label: String, style: STMarkdownStyle) -> NSAttributedString {
        let font = UIFont.st_systemFont(ofSize: max(style.font.pointSize - 1, 12), weight: .medium)
        let attachment = NSTextAttachment()
        // SF Symbol 默认由 tint 控制颜色；通过 withTintColor + alwaysOriginal 让占位符颜色
        // 与 style.imagePlaceholderTextColor 对齐，而不是依赖上层 TextView 的 tint。
        let tint = style.imagePlaceholderTextColor ?? style.textColor.withAlphaComponent(0.88)
        let placeholder = UIImage(systemName: "photo")?
            .withTintColor(tint, renderingMode: .alwaysOriginal)
        attachment.image = placeholder
        let imageHeight = max(font.capHeight, 12)
        attachment.bounds = CGRect(x: 0, y: (font.capHeight - imageHeight) / 2, width: imageHeight, height: imageHeight)

        let result = NSMutableAttributedString(attachment: attachment)
        let text = NSAttributedString(
            string: " \(label)",
            attributes: [
                .font: font,
                .foregroundColor: style.imagePlaceholderTextColor ?? style.textColor.withAlphaComponent(0.88),
                .backgroundColor: style.imagePlaceholderBackgroundColor ?? UIColor.tertiarySystemBackground,
            ]
        )
        result.append(text)
        return result
    }

    func renderBlockImage(label: String, title: String?, style: STMarkdownStyle) -> NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = style.lineHeight
        paragraphStyle.maximumLineHeight = style.lineHeight
        paragraphStyle.paragraphSpacing = style.paragraphSpacing
        paragraphStyle.alignment = .center

        let iconAttachment = NSTextAttachment()
        let iconTint = style.imagePlaceholderTextColor ?? style.textColor
        iconAttachment.image = UIImage(systemName: "photo.on.rectangle")?
            .withTintColor(iconTint, renderingMode: .alwaysOriginal)
        let iconSize = max(style.font.pointSize + 2, 16)
        iconAttachment.bounds = CGRect(x: 0, y: -2, width: iconSize, height: iconSize)

        let result = NSMutableAttributedString()
        result.append(NSAttributedString(attachment: iconAttachment))
        result.append(
            NSAttributedString(
                string: "\n\(label)",
                attributes: [
                    .font: UIFont.st_systemFont(ofSize: style.font.pointSize, weight: .medium),
                    .foregroundColor: style.imagePlaceholderTextColor ?? style.textColor,
                    .backgroundColor: style.imagePlaceholderBackgroundColor ?? UIColor.tertiarySystemBackground,
                    .paragraphStyle: paragraphStyle,
                ]
            )
        )

        if let title, title.isEmpty == false {
            result.append(
                NSAttributedString(
                    string: "\n\(title)",
                    attributes: [
                        .font: UIFont.st_systemFont(ofSize: max(style.font.pointSize - 2, 12), weight: .regular),
                        .foregroundColor: style.imagePlaceholderCaptionColor ?? style.textColor.withAlphaComponent(0.72),
                        .paragraphStyle: paragraphStyle,
                    ]
                )
            )
        }

        return result
    }
}
