//
//  STMarkdownInlineCodeBlockRenderer.swift
//  STBaseProject
//

import UIKit

/// 代码块内联文本渲染器。
///
/// 将代码块渲染为带背景色的 `NSAttributedString`（非 `NSTextAttachment` 图片），
/// 适用于两个场景：
///
/// - **流式阶段**：每帧逐字追加，避免 O(N²) 全帧图片重绘；
///   启用 `tailHighlightOnly` 后仅对末尾 `tailHighlightLines` 行做语法高亮，
///   把每帧扫描量压至常数 O(1)。
///
/// - **AST 静态阶段**：携带 `.codeBlockMarker` 自定义属性供 overlay 按钮定位，
///   避免 TextKit 1 大尺寸图片 glyph rect 计算不准确导致代码块覆盖后续正文。
///
/// 两种用途通过 `Mode` 控制，差异仅在头部属性字典和是否截断高亮行数。
public enum STMarkdownInlineCodeBlockRenderMode {
    /// 流式阶段：跳过业务自定义头部属性，启用尾部高亮截断。
    case streaming(tailHighlightLines: Int)
    /// AST 静态阶段：可附加业务自定义的头部属性（如宿主的 `.codeBlockMarker`）。
    case ast(extraHeaderAttributes: [NSAttributedString.Key: Any])
}

public struct STMarkdownInlineCodeBlockRenderer {

    public init() {}

    /// 渲染代码块为带背景色的 `NSAttributedString`。
    ///
    /// - Parameters:
    ///   - language: 代码语言（nil / 空字符串时显示 "CODE"）
    ///   - code: 代码正文
    ///   - style: 当前 Markdown 样式配置
    ///   - mode: 渲染模式（流式 or AST）
    ///   - skipFadeInKey: 流式 shimmer 文字跳过淡入动画的 `NSAttributedString.Key`（传 nil 时不写入）
    public func render(
        language: String?,
        code: String,
        style: STMarkdownStyle,
        mode: STMarkdownInlineCodeBlockRenderMode,
        skipFadeInKey: NSAttributedString.Key? = nil
    ) -> NSAttributedString {
        let contentInsets = style.codeBlockContentInsets
        let backgroundColor = style.codeBlockBackgroundColor ?? UIColor.secondarySystemBackground
        let headerColor = style.codeBlockHeaderTextColor ?? style.textColor.withAlphaComponent(0.72)
        let headerFont = UIFont.st_monospacedSystemFont(
            ofSize: max(style.font.pointSize - 2, 12),
            weight: .semibold
        )
        let codeFont = UIFont.st_monospacedSystemFont(
            ofSize: max(style.font.pointSize - 1, 12),
            weight: .regular
        )

        let result = NSMutableAttributedString()

        // 头部段落样式：spacer attachment 撑出左侧间距，确保背景色连续
        let headerParagraphStyle = NSMutableParagraphStyle()
        headerParagraphStyle.tailIndent = -contentInsets.right
        headerParagraphStyle.paragraphSpacingBefore = contentInsets.top
        headerParagraphStyle.lineBreakMode = .byTruncatingTail
        if style.codeBlockHeaderHeight > 0 {
            headerParagraphStyle.minimumLineHeight = style.codeBlockHeaderHeight
            headerParagraphStyle.maximumLineHeight = style.codeBlockHeaderHeight
        }

        let headerText = language.flatMap { $0.isEmpty ? nil : $0.uppercased() } ?? "CODE"
        let headerBaselineOffset: CGFloat = style.codeBlockHeaderHeight > 0
            ? (style.codeBlockHeaderHeight - headerFont.lineHeight) / 2
            : 0

        var headerAttrs: [NSAttributedString.Key: Any] = [
            .font: headerFont,
            .foregroundColor: headerColor,
            .backgroundColor: backgroundColor,
            .paragraphStyle: headerParagraphStyle,
            .baselineOffset: headerBaselineOffset,
        ]
        if let key = skipFadeInKey { headerAttrs[key] = true }

        // AST 模式写入宿主注入的业务属性（如 .codeBlockMarker）
        if case .ast(let extraAttrs) = mode {
            for (key, value) in extraAttrs {
                headerAttrs[key] = value
            }
        }

        let headerLine = NSMutableAttributedString()
        let spacer = NSTextAttachment()
        spacer.image = UIImage()
        spacer.bounds = CGRect(x: 0, y: 0, width: contentInsets.left, height: 1)
        let spacerStr = NSMutableAttributedString(attachment: spacer)
        spacerStr.addAttributes(headerAttrs, range: NSRange(location: 0, length: spacerStr.length))
        headerLine.append(spacerStr)
        headerLine.append(NSAttributedString(string: headerText + "\n", attributes: headerAttrs))
        result.append(headerLine)

        // 代码体段落样式
        let codeParagraphStyle = NSMutableParagraphStyle()
        codeParagraphStyle.lineBreakMode = .byCharWrapping
        codeParagraphStyle.lineSpacing = max(style.bodyLineSpacing, 2)
        codeParagraphStyle.firstLineHeadIndent = contentInsets.left
        codeParagraphStyle.headIndent = contentInsets.left
        codeParagraphStyle.tailIndent = -contentInsets.right
        codeParagraphStyle.paragraphSpacingBefore = style.codeBlockSeparatorSpacing

        // 语法高亮（流式阶段可截断为尾部 N 行降低 O(N²)）
        let mutableBody: NSMutableAttributedString
        if case .streaming(let tailLines) = mode,
           tailLines > 0 {
            let codeLines = code.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
            let totalLines = codeLines.count
            if totalLines > tailLines {
                let prefixCode = codeLines.prefix(totalLines - tailLines).joined(separator: "\n") + "\n"
                let suffixCode = codeLines.dropFirst(totalLines - tailLines).joined(separator: "\n")
                mutableBody = NSMutableAttributedString()
                mutableBody.append(NSAttributedString(string: prefixCode, attributes: [
                    .font: codeFont,
                    .foregroundColor: style.codeBlockTextColor ?? style.textColor,
                    .paragraphStyle: codeParagraphStyle,
                ]))
                let highlightedSuffix = STMarkdownCodeSyntaxHighlighter.highlightedBody(
                    language: language,
                    code: suffixCode,
                    font: codeFont,
                    textColor: style.codeBlockTextColor ?? style.textColor,
                    paragraphStyle: codeParagraphStyle
                )
                mutableBody.append(highlightedSuffix)
            } else {
                mutableBody = NSMutableAttributedString(
                    attributedString: STMarkdownCodeSyntaxHighlighter.highlightedBody(
                        language: language,
                        code: code,
                        font: codeFont,
                        textColor: style.codeBlockTextColor ?? style.textColor,
                        paragraphStyle: codeParagraphStyle
                    )
                )
            }
        } else {
            mutableBody = NSMutableAttributedString(
                attributedString: STMarkdownCodeSyntaxHighlighter.highlightedBody(
                    language: language,
                    code: code,
                    font: codeFont,
                    textColor: style.codeBlockTextColor ?? style.textColor,
                    paragraphStyle: codeParagraphStyle
                )
            )
        }
        mutableBody.addAttribute(
            .backgroundColor,
            value: backgroundColor,
            range: NSRange(location: 0, length: mutableBody.length)
        )
        result.append(mutableBody)

        // 尾部：底部间距
        let tailParagraphStyle = NSMutableParagraphStyle()
        tailParagraphStyle.minimumLineHeight = contentInsets.bottom
        tailParagraphStyle.maximumLineHeight = contentInsets.bottom
        var tailAttrs: [NSAttributedString.Key: Any] = [
            .font: codeFont,
            .foregroundColor: UIColor.clear,
            .backgroundColor: backgroundColor,
            .paragraphStyle: tailParagraphStyle,
        ]
        if let key = skipFadeInKey, case .streaming = mode { tailAttrs[key] = true }
        result.append(NSAttributedString(string: "\n", attributes: tailAttrs))

        return result
    }
}
