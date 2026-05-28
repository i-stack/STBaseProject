//
//  STMarkdownAdvancedRenderers.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2019/03/16.
//

import UIKit
import SwiftMath

public protocol STMarkdownInlineMathRendering {
    func renderInlineMath(formula: String, style: STMarkdownStyle, baseFont: UIFont, textColor: UIColor) -> NSAttributedString?
}

public protocol STMarkdownBlockMathRendering {
    func renderBlockMath(formula: String, style: STMarkdownStyle) -> NSAttributedString?
}

public protocol STMarkdownCodeBlockRendering {
    func renderCodeBlock(language: String?, code: String, style: STMarkdownStyle) -> NSAttributedString?
}

public protocol STMarkdownTableRendering {
    func renderTable(_ table: STMarkdownTableModel, style: STMarkdownStyle) -> NSAttributedString?
}

public protocol STMarkdownImageRendering {
    func renderImage(url: String, altText: String, title: String?, style: STMarkdownStyle, placement: STMarkdownImagePlacement) -> NSAttributedString?
}

/// Placement of a markdown image: inline with text vs block-level (centered, with caption).
public enum STMarkdownImagePlacement: Sendable, Equatable {
    case inline
    case block

    public var isInline: Bool { self == .inline }
}

public protocol STMarkdownHorizontalRuleRendering {
    func renderHorizontalRule(style: STMarkdownStyle) -> NSAttributedString?
}

public struct STMarkdownAdvancedRenderers {
    public var inlineMathRenderer: STMarkdownInlineMathRendering?
    public var blockMathRenderer: STMarkdownBlockMathRendering?
    public var codeBlockRenderer: STMarkdownCodeBlockRendering?
    public var tableRenderer: STMarkdownTableRendering?
    public var imageRenderer: STMarkdownImageRendering?
    public var horizontalRuleRenderer: STMarkdownHorizontalRuleRendering?

    public init(
        inlineMathRenderer: STMarkdownInlineMathRendering? = nil,
        blockMathRenderer: STMarkdownBlockMathRendering? = nil,
        codeBlockRenderer: STMarkdownCodeBlockRendering? = nil,
        tableRenderer: STMarkdownTableRendering? = nil,
        imageRenderer: STMarkdownImageRendering? = nil,
        horizontalRuleRenderer: STMarkdownHorizontalRuleRendering? = nil
    ) {
        self.inlineMathRenderer = inlineMathRenderer
        self.blockMathRenderer = blockMathRenderer
        self.codeBlockRenderer = codeBlockRenderer
        self.tableRenderer = tableRenderer
        self.imageRenderer = imageRenderer
        self.horizontalRuleRenderer = horizontalRuleRenderer
    }

    public static let empty = STMarkdownAdvancedRenderers()
}

public struct STMarkdownHighFidelityMathRenderer: STMarkdownInlineMathRendering, STMarkdownBlockMathRendering {
    
    private let fallbackRenderer = STMarkdownDefaultMathRenderer()

    public init() {}

    public func renderInlineMath(formula: String, style: STMarkdownStyle, baseFont: UIFont, textColor: UIColor) -> NSAttributedString? {
        guard let image = self.renderImage(
            formula: formula,
            fontSize: max(baseFont.pointSize, 14),
            textColor: textColor,
            displayMode: false,
            maximumWidth: 1024
        ) else {
            return self.fallbackRenderer.renderInlineMath(
                formula: formula,
                style: style,
                baseFont: baseFont,
                textColor: textColor
            )
        }

        let attachment = NSTextAttachment()
        attachment.image = image
        let targetHeight = min(image.size.height, max(baseFont.capHeight + 4, 16))
        let scale = image.size.height > 0 ? targetHeight / image.size.height : 1
        let targetWidth = image.size.width * scale
        let y = (baseFont.capHeight - targetHeight) / 2
        attachment.bounds = CGRect(x: 0, y: y, width: targetWidth, height: targetHeight)
        return NSAttributedString(attachment: attachment)
    }

    public func renderBlockMath(formula: String, style: STMarkdownStyle) -> NSAttributedString? {
        let availableWidth: CGFloat
        if style.renderWidth > 0 {
            availableWidth = style.renderWidth
        } else {
            availableWidth = Thread.isMainThread ? UIScreen.main.bounds.width - 32 : 343
        }
        guard let image = self.renderImage(
            formula: formula,
            fontSize: max(style.font.pointSize + 2, 18),
            textColor: style.textColor,
            displayMode: true,
            maximumWidth: availableWidth
        ) else {
            return self.fallbackRenderer.renderBlockMath(formula: formula, style: style)
        }

        let attachment = NSTextAttachment()
        attachment.image = image
        // Scale down to fit when SwiftMath returns an image wider than the available container
        // width (e.g. aligned rows with long \text{} content).  Scaling only the attachment
        // bounds works because UIKit draws the image to fit those bounds.
        let scale: CGFloat = image.size.width > availableWidth && availableWidth > 0
            ? availableWidth / image.size.width
            : 1.0
        let displaySize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        attachment.bounds = CGRect(origin: .zero, size: displaySize)

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = max(style.lineHeight, displaySize.height)
        paragraphStyle.maximumLineHeight = max(style.lineHeight, displaySize.height)
        paragraphStyle.paragraphSpacing = style.paragraphSpacing
        paragraphStyle.paragraphSpacingBefore = style.lineHeight / 2
        paragraphStyle.alignment = .center

        let attachmentStr = NSMutableAttributedString(attachment: attachment)
        attachmentStr.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: attachmentStr.length))

        let trailingStyle = NSMutableParagraphStyle()
        trailingStyle.minimumLineHeight = 2
        trailingStyle.maximumLineHeight = 2
        trailingStyle.paragraphSpacing = style.paragraphSpacing

        let result = NSMutableAttributedString()
        result.append(attachmentStr)
        result.append(NSAttributedString(string: "\n", attributes: [.paragraphStyle: trailingStyle]))
        return result
    }
}

private extension STMarkdownHighFidelityMathRenderer {
    func renderImage(formula: String, fontSize: CGFloat, textColor: UIColor, displayMode: Bool, maximumWidth: CGFloat) -> UIImage? {
        let normalized = self.normalizedFormula(formula)
        let mathImage = MTMathImage(
            latex: normalized,
            fontSize: max(fontSize, 10),
            textColor: textColor,
            labelMode: displayMode ? .display : .text,
            textAlignment: displayMode ? .center : .left
        )
        mathImage.contentInsets = displayMode
            ? UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
            : UIEdgeInsets(top: 2, left: 0, bottom: 2, right: 0)
        let (_, image) = mathImage.asImage()
        guard let image, image.size.width > 0, image.size.height > 0 else { return nil }
        return image
    }

    func normalizedFormula(_ formula: String) -> String {
        formula
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: #"\("#, with: "")
            .replacingOccurrences(of: #"\)"#, with: "")
            .replacingOccurrences(of: #"\["#, with: "")
            .replacingOccurrences(of: #"\]"#, with: "")
            .replacingOccurrences(of: #"\'"#, with: "'")
            .replacingOccurrences(of: #"\|"#, with: "|")
            // SwiftMath does not support align/align* — map to its equivalent `aligned`
            .replacingOccurrences(of: #"\begin{align*}"#, with: #"\begin{aligned}"#)
            .replacingOccurrences(of: #"\end{align*}"#, with: #"\end{aligned}"#)
            .replacingOccurrences(of: #"\begin{align}"#, with: #"\begin{aligned}"#)
            .replacingOccurrences(of: #"\end{align}"#, with: #"\end{aligned}"#)
    }
}
