//
//  STMarkdownBlockLayoutCalculator.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2019/03/16.
//

import UIKit

public enum STMarkdownBlockLayoutCalculator {

    /// 两个相邻块之间的视觉间距（点）。
    public static func spacing(
        after previousBlock: STMarkdownRenderBlock,
        before nextBlock: STMarkdownRenderBlock,
        style: STMarkdownStyle
    ) -> CGFloat {
        if isTableAdjacent(previousBlock: previousBlock, nextBlock: nextBlock) {
            return style.blockSpacing
        }
        if case .heading = nextBlock {
            // Heading 的 paragraphSpacingBefore/paragraphSpacing 已编码了上下留白，
            // 分隔符 "\n" 只是终止上一段，minimumLineHeight 对此无视觉效果，取最小值 1pt。
            return 1
        }
        if isListBridgeStrongParagraph(previousBlock: previousBlock, nextBlock: nextBlock, style: style) {
            return max(style.listItemSpacing, 1)
        }
        let prev = trailingSpacing(for: previousBlock, style: style)
        let next = leadingSpacing(for: nextBlock, style: style)
        return max(max(prev, next), 1)
    }

    /// 块之前的推荐前导间距。
    public static func leadingSpacing(for block: STMarkdownRenderBlock, style: STMarkdownStyle) -> CGFloat {
        switch block {
        case .heading(_, level: let level, anchorId: _, content: _):
            return STMarkdownTypography.headingInsets(for: level).top
        case .list:
            return style.listItemSpacing
        case .quote:
            return style.blockSpacing * 0.8
        case .codeBlock, .table, .mathBlock, .image, .thematicBreak, .details, .rawHTML:
            return style.blockSpacing
        case .paragraph:
            if isStandaloneColonHeadingParagraph(block) {
                return pseudoHeadingTopSpacing(style: style)
            }
            return style.blockSpacing
        }
    }

    /// 块之后的推荐尾随间距。
    public static func trailingSpacing(for block: STMarkdownRenderBlock, style: STMarkdownStyle) -> CGFloat {
        switch block {
        case .heading(_, level: let level, anchorId: _, content: _):
            if let bottomSpacings = style.headingBottomSpacing,
               level >= 1, level <= bottomSpacings.count {
                return bottomSpacings[level - 1]
            }
            return STMarkdownTypography.headingInsets(for: level).bottom
        case .list:
            return style.listItemSpacing
        case .quote:
            return style.blockSpacing * 0.8
        case .codeBlock, .table, .mathBlock, .image, .thematicBreak, .details, .rawHTML:
            return style.blockSpacing
        case .paragraph:
            return style.blockSpacing
        }
    }

    public static func isTableAdjacent(previousBlock: STMarkdownRenderBlock, nextBlock: STMarkdownRenderBlock) -> Bool {
        switch (previousBlock, nextBlock) {
        case (.table, _), (_, .table):
            return true
        default:
            return false
        }
    }

    /// 生成两个相邻块之间的间距 `NSAttributedString`（单个 `"\n"`，行高 = 计算所得间距）。
    ///
    /// - Parameters:
    ///   - skipFadeInKey: 可选的"跳过淡入"自定义属性 key（流式 shimmer 用），传 nil 则不写入。
    public static func separatorAttributedString(
        after previousBlock: STMarkdownRenderBlock,
        before nextBlock: STMarkdownRenderBlock,
        style: STMarkdownStyle,
        skipFadeInKey: NSAttributedString.Key? = nil
    ) -> NSAttributedString {
        let spacing = Self.spacing(after: previousBlock, before: nextBlock, style: style)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = spacing
        paragraphStyle.maximumLineHeight = spacing
        paragraphStyle.lineBreakMode = .byWordWrapping
        var attrs: [NSAttributedString.Key: Any] = [
            .font: style.font,
            .foregroundColor: UIColor.clear,
            .paragraphStyle: paragraphStyle,
        ]
        if let key = skipFadeInKey { attrs[key] = true }
        return NSAttributedString(string: "\n", attributes: attrs)
    }

    /// 前后块是否构成"列表 ↔ standalone-strong 段落"的桥接关系（使用 listItemSpacing 而非 blockSpacing）。
    public static func isListBridgeStrongParagraph(
        previousBlock: STMarkdownRenderBlock,
        nextBlock: STMarkdownRenderBlock,
        style: STMarkdownStyle
    ) -> Bool {
        (isListBlock(previousBlock) && isStandaloneStrongParagraph(nextBlock))
            || (isStandaloneStrongParagraph(previousBlock) && isListBlock(nextBlock))
    }

    /// 是否为列表块（不限嵌套层级）。
    public static func isListBlock(_ block: STMarkdownRenderBlock) -> Bool {
        if case .list = block { return true }
        return false
    }

    /// 是否为"仅含 strong 节点"的段落（列表相邻时用 listItemSpacing）。
    public static func isStandaloneStrongParagraph(_ block: STMarkdownRenderBlock) -> Bool {
        guard case .paragraph(_, let inlines) = block else { return false }
        return isStandaloneStrongParagraph(inlines: inlines)
    }

    public static func isStandaloneStrongParagraph(inlines: [STMarkdownInlineNode]) -> Bool {
        var sawStrongContent = false
        for inline in inlines {
            switch inline {
            case .strong(let children):
                guard !inlineNodesVisibleText(children).isEmpty else { return false }
                sawStrongContent = true
            case .text(let text), .inlineRawHTML(let text):
                if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return false }
            case .softBreak:
                continue
            default:
                return false
            }
        }
        return sawStrongContent
    }

    /// 递归提取内联节点的可见纯文本（用于判断节点是否有实际内容）。
    public static func inlineNodesVisibleText(_ nodes: [STMarkdownInlineNode]) -> String {
        var text = ""
        for node in nodes {
            switch node {
            case .text(let value), .code(let value), .inlineMath(let value, _), .inlineRawHTML(let value):
                text.append(value)
            case .emphasis(let children), .strong(let children),
                 .strikethrough(let children), .link(_, let children):
                text.append(inlineNodesVisibleText(children))
            case .softBreak:
                text.append("\n")
            case .image(_, let alt, _):
                text.append(alt)
            case .footnoteReference(let label):
                text.append(label)
            }
        }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// 某块的前一块或后一块是否为列表块（用于判断段落是否紧邻列表）。
    public static func isListAdjacentParagraph(previousBlock: STMarkdownRenderBlock?, nextBlock: STMarkdownRenderBlock?) -> Bool {
        if let prev = previousBlock, isListBlock(prev) { return true }
        if let next = nextBlock, isListBlock(next) { return true }
        return false
    }

    /// `paragraph(only-strong, 文本以冒号结尾)` ——LLM 用 `**xxx：**` 单行模拟标题的模式。
    public static func isStandaloneColonHeadingParagraph(_ block: STMarkdownRenderBlock) -> Bool {
        guard isStandaloneStrongParagraph(block),
              case .paragraph(_, let inlines) = block else { return false }
        let text = inlineNodesVisibleText(inlines)
        return text.hasSuffix("：") || text.hasSuffix(":")
    }

    /// 伪标题的前导间距：等同 h3 heading top spacing，降级为 blockSpacing * 1.6。
    public static func pseudoHeadingTopSpacing(style: STMarkdownStyle) -> CGFloat {
        if let topSpacings = style.headingTopSpacing, topSpacings.count >= 3 {
            return topSpacings[2]   // h3 index
        }
        return STMarkdownTypography.headingInsets(for: 3).top
    }
}
