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
    func renderImage(url: String, altText: String, title: String?, style: STMarkdownStyle, inline: Bool) -> NSAttributedString?
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
        guard let image = self.renderImage(
            formula: formula,
            fontSize: max(style.font.pointSize + 2, 18),
            textColor: style.textColor,
            displayMode: true,
            maximumWidth: 280
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
        label.displayErrorInline = true
        let fittingSize = label.sizeThatFits(CGSize(width: maximumWidth, height: .greatestFiniteMagnitude))
        guard fittingSize.width > 0, fittingSize.height > 0 else {
            return nil
        }
        label.frame = CGRect(origin: .zero, size: CGSize(width: ceil(fittingSize.width), height: ceil(fittingSize.height)))
        let format = UIGraphicsImageRendererFormat.default()
        let renderer = UIGraphicsImageRenderer(size: label.bounds.size, format: format)
        let image = renderer.image { context in
            let cgContext = context.cgContext
            // MTMathUILabel 内部使用 Core Graphics 坐标系（Y 轴向上）绘制公式。
            // UIGraphicsImageRenderer 提供的是 UIKit 坐标系（Y 轴向下）。
            // layer.render(in:) 不会自动处理 isGeometryFlipped=true 导致的坐标翻转，
            // 因此需要手动翻转 Y 轴，与 SwiftMath 官方 MathImage.asImage() 的做法一致。
            cgContext.translateBy(x: 0, y: label.bounds.size.height)
            cgContext.scaleBy(x: 1, y: -1)
            label.layer.render(in: cgContext)
        }
        return image.size.width > 0 && image.size.height > 0 ? image : nil
    }

    func normalizedFormula(_ formula: String) -> String {
        // Raw-string 字面 `#"\("#` 里的反斜杠是**一个**字面字符。
        // 早期写成 `#"\\("#` 会去匹配两个反斜杠+括号，对真实 LaTeX 输入永远不会命中。
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
