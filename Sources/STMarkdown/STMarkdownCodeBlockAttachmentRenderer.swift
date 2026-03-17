//
//  STMarkdownCodeBlockAttachmentRenderer.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2019/03/16.
//

import UIKit

public struct STMarkdownCodeBlockAttachmentRenderer: STMarkdownCodeBlockRendering {
    public init() {}

    public func renderCodeBlock(
        language: String?,
        code: String,
        style: STMarkdownStyle
    ) -> NSAttributedString? {
        let attachment = NSTextAttachment()
        let image = self.renderAttachmentImage(language: language, code: code, style: style)
        attachment.image = image
        attachment.bounds = CGRect(origin: .zero, size: image.size)
        return NSAttributedString(attachment: attachment)
    }
}

private extension STMarkdownCodeBlockAttachmentRenderer {
    func renderAttachmentImage(
        language: String?,
        code: String,
        style: STMarkdownStyle
    ) -> UIImage {
        let headerFont = UIFont.st_monospacedSystemFont(ofSize: max(style.font.pointSize - 2, 12), weight: .semibold)
        let codeFont = UIFont.st_monospacedSystemFont(ofSize: max(style.font.pointSize - 1, 12), weight: .regular)
        let horizontalPadding: CGFloat = 12
        let verticalPadding: CGFloat = 10
        let contentWidth: CGFloat = 280
        let blockWidth = contentWidth + (horizontalPadding * 2)

        let backgroundColor = style.codeBlockBackgroundColor ?? UIColor.secondarySystemBackground
        let headerColor = style.codeBlockHeaderTextColor ?? style.textColor.withAlphaComponent(0.72)
        let textColor = style.codeBlockTextColor ?? style.textColor

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byCharWrapping
        paragraphStyle.lineSpacing = max(style.bodyLineSpacing, 2)

        let codeAttributes: [NSAttributedString.Key: Any] = [
            .font: codeFont,
            .foregroundColor: textColor,
            .paragraphStyle: paragraphStyle,
        ]
        let headerAttributes: [NSAttributedString.Key: Any] = [
            .font: headerFont,
            .foregroundColor: headerColor,
        ]

        let codeAttributedText = NSAttributedString(string: code, attributes: codeAttributes)
        let codeBounds = codeAttributedText.boundingRect(
            with: CGSize(width: contentWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        )

        let headerText = language?.uppercased() ?? "CODE"
        let headerHeight = headerText.isEmpty ? 0 : ceil(headerFont.lineHeight)
        let separatorSpacing: CGFloat = headerText.isEmpty ? 0 : 8
        let codeHeight = max(ceil(codeBounds.height), ceil(codeFont.lineHeight))
        let blockHeight = verticalPadding + headerHeight + separatorSpacing + codeHeight + verticalPadding

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = UIScreen.main.scale
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: blockWidth, height: blockHeight), format: format)

        return renderer.image { context in
            let cgContext = context.cgContext
            let rect = CGRect(x: 0, y: 0, width: blockWidth, height: blockHeight)
            let path = UIBezierPath(roundedRect: rect, cornerRadius: 12)
            backgroundColor.setFill()
            path.fill()

            var currentY = verticalPadding

            if headerText.isEmpty == false {
                let headerRect = CGRect(
                    x: horizontalPadding,
                    y: currentY,
                    width: contentWidth,
                    height: headerHeight
                )
                headerText.draw(in: headerRect, withAttributes: headerAttributes)
                currentY += headerHeight + 4

                let separatorRect = CGRect(
                    x: horizontalPadding,
                    y: currentY,
                    width: contentWidth,
                    height: 1
                )
                cgContext.setFillColor((style.horizontalRuleColor ?? UIColor.separator).withAlphaComponent(0.35).cgColor)
                cgContext.fill(separatorRect)
                currentY += separatorSpacing - 4
            }

            let codeRect = CGRect(
                x: horizontalPadding,
                y: currentY,
                width: contentWidth,
                height: codeHeight
            )
            codeAttributedText.draw(
                with: codeRect,
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                context: nil
            )
        }
    }
}
