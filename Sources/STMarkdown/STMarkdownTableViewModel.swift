//
//  STMarkdownTableViewModel.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2019/03/16.
//

import UIKit

/// 表格 cell 的渲染数据：包含带样式的 NSAttributedString 和 citation 信息
public struct STMarkdownTableCellData {
    public let attributedContent: NSAttributedString
    public let citations: [String]
    public let isHeader: Bool

    public init(attributedContent: NSAttributedString, citations: [String], isHeader: Bool) {
        self.attributedContent = attributedContent
        self.citations = citations
        self.isHeader = isHeader
    }
}

/// 表格的视图模型，将 STMarkdownTableModel 转换为 UICollectionView 可直接消费的数据
public final class STMarkdownTableViewModel {

    public let columnCount: Int
    public let rowCount: Int
    public let hasHeader: Bool
    public let columnAlignments: [STMarkdownColumnAlignment]
    public let cells: [[STMarkdownTableCellData]]

    public init(
        from table: STMarkdownTableModel,
        style: STMarkdownStyle,
        advancedRenderers: STMarkdownAdvancedRenderers = .empty
    ) {
        self.hasHeader = table.header != nil
        self.columnAlignments = table.columnAlignments

        let renderer = STMarkdownAttributedStringRenderer(
            style: style,
            advancedRenderers: advancedRenderers
        )

        let headerFont = UIFont.st_systemFont(ofSize: max(style.font.pointSize - 1, 12), weight: .semibold)
        let bodyFont = UIFont.st_systemFont(ofSize: max(style.font.pointSize - 1, 12), weight: .regular)
        let headerTextColor = style.tableHeaderTextColor ?? style.textColor
        let bodyTextColor = style.tableTextColor ?? style.textColor

        var allRows: [[[STMarkdownInlineNode]]] = []
        if let header = table.header {
            allRows.append(header)
        }
        allRows.append(contentsOf: table.rows)

        let maxCols = allRows.map(\.count).max() ?? 0

        var builtCells: [[STMarkdownTableCellData]] = []
        for (rowIndex, row) in allRows.enumerated() {
            let isHeader = self.hasHeader && rowIndex == 0
            let font = isHeader ? headerFont : bodyFont
            let textColor = isHeader ? headerTextColor : bodyTextColor
            var rowCells: [STMarkdownTableCellData] = []
            for colIndex in 0..<maxCols {
                let nodes = colIndex < row.count ? row[colIndex] : []
                let alignment = Self.textAlignment(
                    for: colIndex < table.columnAlignments.count ? table.columnAlignments[colIndex] : .left
                )
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.alignment = alignment
                paragraphStyle.lineBreakMode = .byWordWrapping

                let citations = Self.extractCitations(from: nodes)
                // 渲染时保留 citation 节点，不做 strip
                let attributed = renderer.renderInlineContent(
                    nodes: nodes,
                    baseFont: font,
                    textColor: textColor,
                    paragraphStyle: paragraphStyle
                )
                // 后处理：将渲染后的 citation 文本替换为内联 badge 图片
                let processed = Self.replaceCitationTextWithBadges(
                    in: attributed,
                    baseFont: font,
                    style: style
                )
                rowCells.append(STMarkdownTableCellData(
                    attributedContent: processed,
                    citations: citations,
                    isHeader: isHeader
                ))
            }
            builtCells.append(rowCells)
        }

        self.cells = builtCells
        self.columnCount = maxCols
        self.rowCount = builtCells.count
    }

    // MARK: - Private

    private static func textAlignment(for alignment: STMarkdownColumnAlignment) -> NSTextAlignment {
        switch alignment {
        case .left: return .left
        case .center: return .center
        case .right: return .right
        }
    }

    private static func extractCitations(from nodes: [STMarkdownInlineNode]) -> [String] {
        var citations: [String] = []
        Self.collectCitations(from: nodes, into: &citations)
        return citations
    }

    private static func collectCitations(from nodes: [STMarkdownInlineNode], into citations: inout [String]) {
        for node in nodes {
            switch node {
            case .link(let destination, let children):
                if destination.isEmpty,
                   let number = extractCitationNumber(from: children) {
                    citations.append(number)
                } else {
                    collectCitations(from: children, into: &citations)
                }
            case .emphasis(let children), .strong(let children), .strikethrough(let children):
                collectCitations(from: children, into: &citations)
            case .text(let text):
                let pattern = #"\[Citation:(\d+)\]"#
                if let regex = try? NSRegularExpression(pattern: pattern) {
                    let ns = text as NSString
                    let matches = regex.matches(in: text, range: NSRange(location: 0, length: ns.length))
                    for match in matches {
                        let numberRange = match.range(at: 1)
                        if numberRange.location != NSNotFound {
                            citations.append(ns.substring(with: numberRange))
                        }
                    }
                }
            default:
                break
            }
        }
    }

    private static func extractCitationNumber(from children: [STMarkdownInlineNode]) -> String? {
        guard children.count == 1, case .text(let text) = children[0] else { return nil }
        let prefix = "Citation:"
        if text.hasPrefix(prefix) {
            let number = String(text.dropFirst(prefix.count))
            return number.isEmpty ? nil : number
        }
        if !text.isEmpty, text.allSatisfy({ $0.isNumber }) {
            return text
        }
        return nil
    }

    // MARK: - Strip Citations from Display

    /// 从 inline nodes 中移除 citation 引用，仅保留正常内容用于显示。
    /// Citation 以 badge 形式由 STMarkdownTableCell 单独渲染，避免显示重复。
    private static func stripCitationNodes(from nodes: [STMarkdownInlineNode]) -> [STMarkdownInlineNode] {
        var result: [STMarkdownInlineNode] = []
        for node in nodes {
            switch node {
            case .link(let destination, let children):
                if destination.isEmpty, extractCitationNumber(from: children) != nil {
                    // Citation link：不加入显示节点
                    continue
                }
                let stripped = stripCitationNodes(from: children)
                result.append(.link(destination: destination, children: stripped))
            case .emphasis(let children):
                let stripped = stripCitationNodes(from: children)
                if !stripped.isEmpty { result.append(.emphasis(stripped)) }
            case .strong(let children):
                let stripped = stripCitationNodes(from: children)
                if !stripped.isEmpty { result.append(.strong(stripped)) }
            case .strikethrough(let children):
                let stripped = stripCitationNodes(from: children)
                if !stripped.isEmpty { result.append(.strikethrough(stripped)) }
            case .text(let text):
                let cleaned = Self.stripCitationTextPatterns(from: text)
                if !cleaned.isEmpty {
                    result.append(.text(cleaned))
                }
            default:
                result.append(node)
            }
        }
        return result
    }

    /// 从纯文本中移除 [Citation:N] 及 Citation:N 模式的残留文本。
    private static func stripCitationTextPatterns(from text: String) -> String {
        var result = text
        // 移除 [Citation:N] 及 [[Citation:N]]
        let patterns: [String] = [
            #"\[\[?\s*(?:[Cc]itation|[Ww]ebpage)\s*:?\s*\d+\s*\]?\]?"#,
            #"\b(?:[Cc]itation|[Ww]ebpage)\s*:\s*\d+"#,
        ]
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern) {
                let ns = result as NSString
                result = regex.stringByReplacingMatches(
                    in: result,
                    range: NSRange(location: 0, length: ns.length),
                    withTemplate: ""
                )
            }
        }
        // 清理残留的空括号和多余空格
        result = result.replacingOccurrences(of: "()", with: "")
        result = result.replacingOccurrences(of: "[]", with: "")
        result = result.replacingOccurrences(of: "  ", with: " ")
        result = result.trimmingCharacters(in: .whitespaces)
        return result
    }

    // MARK: - Inline Citation Badge

    /// 在已渲染的 NSAttributedString 中查找 citation 文本模式，将其替换为内联 badge 图片。
    /// 支持以下模式：
    /// - 链接文本 "Citation:N"（由 .link 节点渲染）
    /// - 纯文本 "[Citation:N]"、"Citation:N"
    private static func replaceCitationTextWithBadges(
        in attributedString: NSAttributedString,
        baseFont: UIFont,
        style: STMarkdownStyle
    ) -> NSAttributedString {
        let result = NSMutableAttributedString(attributedString: attributedString)
        let text = result.string as NSString

        // 匹配 [Citation:N]、[[Citation:N]]、Citation:N 及链接文本 "Citation:N"
        let patterns: [String] = [
            #"\[?\[?\s*(?:[Cc]itation|[Ww]ebpage)\s*:?\s*(\d+)\s*\]?\]?"#,
            #"(?:[Cc]itation|[Ww]ebpage)\s*:\s*(\d+)"#,
        ]

        // 收集所有匹配的 (range, number)，从后往前替换以保持索引有效
        var replacements: [(range: NSRange, number: String)] = []
        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern) else { continue }
            let matches = regex.matches(in: text as String, range: NSRange(location: 0, length: text.length))
            for match in matches {
                let numberRange = match.range(at: 1)
                guard numberRange.location != NSNotFound else { continue }
                let number = text.substring(with: numberRange)
                let fullRange = match.range(at: 0)
                // 检查是否与已收集的范围重叠
                let overlaps = replacements.contains { existing in
                    NSIntersectionRange(existing.range, fullRange).length > 0
                }
                if !overlaps {
                    replacements.append((range: fullRange, number: number))
                }
            }
        }

        // 从后往前替换，保持索引有效
        replacements.sort { $0.range.location > $1.range.location }
        for replacement in replacements {
            let badge = Self.makeCitationBadgeAttachment(
                number: replacement.number,
                baseFont: baseFont,
                style: style
            )
            let badgeString = NSAttributedString(attachment: badge)
            // 清理 badge 前后可能残留的空格
            var replaceRange = replacement.range
            // 如果 badge 前面是空格，一并移除
            if replaceRange.location > 0 {
                let charBefore = text.character(at: replaceRange.location - 1)
                if charBefore == 0x20 /* space */ {
                    replaceRange = NSRange(location: replaceRange.location - 1, length: replaceRange.length + 1)
                }
            }
            result.replaceCharacters(in: replaceRange, with: badgeString)
        }

        return result
    }

    /// 生成 citation badge 的 NSTextAttachment（内联圆形数字图片）。
    private static func makeCitationBadgeAttachment(
        number: String,
        baseFont: UIFont,
        style: STMarkdownStyle
    ) -> NSTextAttachment {
        let diameter: CGFloat = 16
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: diameter, height: diameter))
        let image = renderer.image { _ in
            let bgColor = style.citationBadgeBgColor ?? .systemBlue
            bgColor.setFill()
            UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: diameter, height: diameter)).fill()
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 9, weight: .semibold),
                .foregroundColor: style.citationBadgeTextColor ?? UIColor.white,
            ]
            let textSize = (number as NSString).size(withAttributes: attrs)
            let textRect = CGRect(
                x: (diameter - textSize.width) / 2,
                y: (diameter - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )
            (number as NSString).draw(in: textRect, withAttributes: attrs)
        }
        let attachment = NSTextAttachment()
        attachment.image = image
        // 与文本基线对齐
        attachment.bounds = CGRect(
            x: 0,
            y: (baseFont.capHeight - diameter) / 2,
            width: diameter,
            height: diameter
        )
        return attachment
    }
}
