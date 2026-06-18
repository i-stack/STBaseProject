//
//  STMarkdownSpeculativeRewriter.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2026/06/17.
//

import Foundation
import Markdown

/// 流式 Markdown 解析后，在渲染前对 AST 做推测性重写。
///
/// SST 的 `MarkupPostParsingRewriter` mirror：当流式输出中途出现未闭合的 `**xxx`
/// 或仅含表头的 `| col |` 段落时，提前补全/清空节点，避免字面定界符闪烁同时保留可渲染内容。
public protocol STMarkdownSpeculativeRewriterProtocol: Sendable {
    /// 对 `document` 尝试推测重写；若无可重写之处则返回 nil。
    func rewriteIfApplicable(document: Document) -> Document?
}

/// 流式 Emphasis/Strong 推测性重写器。
///
/// 移植自 SST `PartialEmphasisScanner` + `PartialEmphasisRewriter`：
/// - 扫描 AST 最右侧的 Text 节点，若其末尾包含未闭合的 `**...` / `__...` / `*...` / `_...`，
///   将其拆分为 `Text(非定界符前缀) + Strong/Emphasis(定界符内正文)`，使流式阶段即可看到粗体/斜体。
/// - 处理 `*cool*` 前一个 Text 以单 `*` 结尾时合并为 `Strong`（如 `Yeah, this is *`+`cool*` → `Strong`）。
final class STPartialStrongSpeculativeRewriter: MarkupRewriter {

    private let targetNode: Text

    init(targetNode: Text) {
        self.targetNode = targetNode
    }

    func visitTableCell(_ tableCell: Table.Cell) -> Markup? {
        return rewriteIfNeeded(inlineContainer: tableCell) ?? tableCell
    }

    func visitParagraph(_ paragraph: Paragraph) -> Markup? {
        return rewriteIfNeeded(inlineContainer: paragraph) ?? paragraph
    }

    func visitHeading(_ heading: Heading) -> Markup? {
        return rewriteIfNeeded(inlineContainer: heading) ?? heading
    }

    private func rewriteIfNeeded(inlineContainer: InlineContainer) -> Markup? {
        guard inlineContainer.hasChildren else { return nil }

        if let lastChild = inlineContainer.lastChild, lastChild.isIdentical(to: targetNode),
           let text = inlineContainer.lastChild as? Text {
            // 尝试 strong（** / __）
            if let range = text.matchesPartialStrong() {
                let nonMatchingPart = String(text.string[text.string.startIndex..<range.lowerBound])
                let matchingPart = String(text.string[range.lowerBound..<range.upperBound].dropFirst(2))
                let textNode = Text(nonMatchingPart)
                let strongNode = Strong([Text(matchingPart)])
                let targetRange = inlineContainer.lastChildRange
                let replacementNodes: [InlineMarkup] = nonMatchingPart.isEmpty
                    ? [strongNode]
                    : [textNode, strongNode]
                var mutableContainer = inlineContainer
                mutableContainer.replaceChildrenInRange(targetRange, with: replacementNodes)
                return mutableContainer
            }
            // 尝试 italic（* / _）
            if let range = text.matchesPartialItalic() {
                let nonMatchingPart = String(text.string[text.string.startIndex..<range.lowerBound])
                let matchingPart = String(text.string[range.lowerBound..<range.upperBound].dropFirst(1))
                let textNode = Text(nonMatchingPart)
                let emphasisNode = Emphasis([Text(matchingPart)])
                let targetRange = inlineContainer.lastChildRange
                let replacementNodes: [InlineMarkup] = nonMatchingPart.isEmpty
                    ? [emphasisNode]
                    : [textNode, emphasisNode]
                var mutableContainer = inlineContainer
                mutableContainer.replaceChildrenInRange(targetRange, with: replacementNodes)
                return mutableContainer
            }
            return nil
        }

        // 处理 `*cool*` 前一个 Text 以单 `*` 结尾时合并为 Strong
        if let container = rewriteEmphasisToStrongIfNeeded(inlineContainer: inlineContainer) {
            return container
        }
        return nil
    }

    /// 处理特殊情况：前一个 Text 以 `*` 结尾且紧跟 Emphasis 节点时，推测为 Strong。
    ///
    /// ```
    /// └─ Paragraph
    ///    ├─ Text "Yeah, this is *"
    ///    └─ Emphasis
    ///       └─ Text "cool"
    /// → Strong([Text("cool")]), Text("Yeah, this is ")
    /// ```
    private func rewriteEmphasisToStrongIfNeeded(inlineContainer: InlineContainer) -> InlineContainer? {
        guard inlineContainer.childCount >= 2 else { return nil }
        guard let emphasis = inlineContainer.lastChild as? Emphasis else { return nil }
        guard let emphasizedText = emphasis.firstChild as? Text else { return nil }
        guard emphasizedText.isIdentical(to: targetNode) else { return nil }
        guard let precedingText = inlineContainer.child(at: inlineContainer.childCount - 2) as? Text else {
            return nil
        }

        let preceding = precedingText.plainText
        if (preceding.hasSuffix("*") && !preceding.hasSuffix("**"))
            || (preceding.hasSuffix("_") && !preceding.hasSuffix("__")) {
            var mutableContainer = inlineContainer
            let newPrecedingText = Text(String(preceding.dropLast()))
            let newTrailingStrongText = Strong([emphasizedText])
            let startIndex = inlineContainer.childCount - 2
            let endIndex = inlineContainer.childCount
            let newChildren: [InlineMarkup] = newPrecedingText.string.isEmpty
                ? [newTrailingStrongText]
                : [newPrecedingText, newTrailingStrongText]
            mutableContainer.replaceChildrenInRange(startIndex..<endIndex, with: newChildren)
            return mutableContainer
        }
        return nil
    }
}

// MARK: - Text 扩展：匹配尾部部分标记

extension Text {
    /// 匹配尾部未闭合的 `**...` 或 `__...` 标记
    func matchesPartialStrong() -> Range<String.Index>? {
        let pattern = try? Regex("(?:\\*\\*|__).*$")
        guard let regex = pattern else { return nil }
        let ranges = self.string.ranges(of: regex)
        guard ranges.count == 1, let range = ranges.first,
              range.upperBound == self.string.endIndex else {
            return nil
        }
        return range
    }

    /// 匹配尾部未闭合的 `*...` 或 `_...` 标记
    func matchesPartialItalic() -> Range<String.Index>? {
        let pattern = try? Regex("(?:\\*|_).*$")
        guard let regex = pattern else { return nil }
        let ranges = self.string.ranges(of: regex)
        guard ranges.count == 1, let range = ranges.first,
              range.upperBound == self.string.endIndex else {
            return nil
        }
        return range
    }
}

// MARK: - InlineContainer 辅助

extension InlineContainer {
    var hasChildren: Bool { childCount > 0 }
    var firstChild: Markup? { child(at: 0) }
    var lastChild: Markup? { child(at: childCount - 1) }
    var lastChildRange: Range<Int> { (childCount - 1)..<childCount }
}

// MARK: - 流式表头推测性重写器

/// 流式 Table 推测性重写器。
///
/// 移植自 SST `PartialTableScanner` + `PartialTableRewriter`：
/// 扫描末尾 Paragraph 是否包含以 `|` 开头的表头行但无分隔行（即表头不完整）。
/// 若匹配，清空该 Paragraph 的内容，避免流式阶段表头文字以纯文本裸露闪烁。
final class STPartialTableSpeculativeRewriter: MarkupRewriter {

    private let targetParagraph: Paragraph

    init(targetParagraph: Paragraph) {
        self.targetParagraph = targetParagraph
    }

    func visitParagraph(_ paragraph: Paragraph) -> Markup? {
        if paragraph.isIdentical(to: targetParagraph) {
            var mutableParagraph = paragraph
            mutableParagraph.replaceChildrenInRange(0..<paragraph.childCount, with: [])
            return mutableParagraph
        }
        return paragraph
    }
}

// MARK: - Document 扫描辅助

extension Markup {
    /// 返回最右下方的后代节点。
    var rightMostDescendant: Markup? {
        var result: Markup = self
        while result.childCount > 0 {
            if let rightMost = result.child(at: result.childCount - 1) {
                result = rightMost
            } else {
                break
            }
        }
        return result
    }
}

// MARK: - 公开协议方法

/// 对 AST 最末端的 Text 节点做 Strong/Emphasis 推测性重写。
public struct STStreamingEmphasisRewriter: STMarkdownSpeculativeRewriterProtocol {
    public init() {}
    public func rewriteIfApplicable(document: Document) -> Document? {
        let textNode = scanForPartialEmphasis(in: document)
        guard let target = textNode else { return nil }
        var rewriter = STPartialStrongSpeculativeRewriter(targetNode: target)
        return rewriter.visitDocument(document) as? Document
    }

    private func scanForPartialEmphasis(in document: Document) -> Text? {
        let rightMost = document.rightMostDescendant
        if let textNode = rightMost as? Text {
            // 只有末尾确实有未闭合标记时才返回
            if textNode.matchesPartialStrong() != nil || textNode.matchesPartialItalic() != nil {
                return textNode
            }
            return nil
        }

        // 处理表格末尾的情况（SST 兼容：忽略空的 Table.Cell）
        if let cellNode = rightMost as? Table.Cell, let row = cellNode.parent as? Table.Row {
            let nonEmptyCells = row.children.compactMap { $0 as? Table.Cell }.filter { $0.childCount > 0 }
            if let lastNonEmpty = nonEmptyCells.last,
               let textNode = lastNonEmpty.rightMostDescendant as? Text {
                if textNode.matchesPartialStrong() != nil || textNode.matchesPartialItalic() != nil {
                    return textNode
                }
            }
        }
        return nil
    }
}

/// 对末尾仅含表头行的 Paragraph 做推测性清空。
public struct STStreamingTableRewriter: STMarkdownSpeculativeRewriterProtocol {
    public init() {}
    public func rewriteIfApplicable(document: Document) -> Document? {
        guard let paragraph = scanForPartialTable(in: document) else { return nil }
        var rewriter = STPartialTableSpeculativeRewriter(targetParagraph: paragraph)
        return rewriter.visitDocument(document) as? Document
    }

    private func scanForPartialTable(in document: Document) -> Paragraph? {
        let rightMost = document.rightMostDescendant
        guard let paragraph = rightMost?.parent as? Paragraph else { return nil }

        // 仅表头，无分隔行：Paragraph.childCount == 1 且 text 以 | 开头
        // 例：| Month | Savings |
        if paragraph.childCount == 1, let text = paragraph.child(at: 0) as? Text {
            if text.string.hasPrefix("|") {
                return paragraph
            }
        }

        // 表头 + 换行：Paragraph.childCount == 2
        // 例：| Month | Savings |\n
        if paragraph.childCount == 2 {
            if let text = paragraph.child(at: 0) as? Text,
               paragraph.child(at: 1) is SoftBreak {
                if text.string.hasPrefix("|") {
                    return paragraph
                }
            }
        }

        // 表头 + 换行 + 部分分隔行：
        // 例：| Month | Savings |\n| :--
        if paragraph.childCount == 3 {
            if let header = paragraph.child(at: 0) as? Text,
               paragraph.child(at: 1) is SoftBreak,
               let delimiter = paragraph.child(at: 2) as? Text {
                if header.string.hasPrefix("|") && delimiter.string.hasPrefix("|") {
                    return paragraph
                }
            }
        }

        return nil
    }
}

// MARK: - 便捷工厂

extension STMarkdownStructureParser {
    /// 创建一个预配置了流式推测重写器的实例。
    public static func streamingParser() -> STMarkdownStructureParser {
        STMarkdownStructureParser(speculativeRewriters: [
            STStreamingEmphasisRewriter(),
            STStreamingTableRewriter()
        ])
    }
}
