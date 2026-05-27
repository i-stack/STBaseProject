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
        // UIScreen.main 仅主线程安全；非主线程时 renderImage 会因主线程守卫返回 nil 走 fallback，
        // 此处 343 作为兜底（不影响输出，renderImage 返回 nil 后由文本渲染器接管）。
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
        attachment.bounds = CGRect(origin: .zero, size: image.size)

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = max(style.lineHeight, image.size.height)
        paragraphStyle.maximumLineHeight = max(style.lineHeight, image.size.height)
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
        // MTMathUILabel 是 UIView，其创建与 layoutIfNeeded() 都必须在主线程。
        // STMarkdownAttributedStringRenderer.render(document:) 没有 actor 注解，
        // 可能从后台调度器调用；此处返回 nil 让上层走纯文本 fallback，而非触发 UIKit 警告或 crash。
        guard Thread.isMainThread else { return nil }
        let normalized = self.normalizedFormula(formula)
        let label = MTMathUILabel()
        label.latex = normalized
        label.fontSize = fontSize
        label.textColor = textColor
        label.backgroundColor = .clear
        label.labelMode = displayMode ? .display : .text
        label.textAlignment = displayMode ? .center : .left
        label.contentInsets = displayMode
            ? UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
            : UIEdgeInsets(top: 2, left: 0, bottom: 2, right: 0)
        label.displayErrorInline = false
        let fittingSize = label.sizeThatFits(CGSize(width: maximumWidth, height: .greatestFiniteMagnitude))
        guard fittingSize.width > 0, fittingSize.height > 0 else { return nil }
        label.frame = CGRect(origin: .zero, size: CGSize(width: ceil(fittingSize.width), height: ceil(fittingSize.height)))
        label.layoutIfNeeded()
        guard let displayList = label.displayList else { return nil }
        let size = label.bounds.size
        let format = UIGraphicsImageRendererFormat.default()
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let image = renderer.image { ctx in
            ctx.cgContext.saveGState()
            ctx.cgContext.translateBy(x: 0, y: size.height)
            ctx.cgContext.scaleBy(x: 1, y: -1)
            displayList.draw(ctx.cgContext)
            ctx.cgContext.restoreGState()
        }
        return image.size.width > 0 && image.size.height > 0 ? image : nil
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
    }
}
