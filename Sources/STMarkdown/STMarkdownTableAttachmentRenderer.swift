//
//  STMarkdownTableAttachmentRenderer.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2019/03/16.
//

import UIKit
import SwiftMath

public struct STMarkdownTableAttachmentRenderer: STMarkdownTableRendering {
    
    public init() {}

    private let tableHorizontalMargin: CGFloat = 0.0

    public func renderTable(_ table: STMarkdownTableModel, style: STMarkdownStyle) -> NSAttributedString? {
        let rows = self.makeRows(from: table)
        guard rows.isEmpty == false else { return nil }
        
        // 使用完整的 renderWidth 作为容器宽度，边距设为 0 以保证与文字左对齐
        let containerWidth = style.renderWidth
        let hasHeader = table.header != nil
        
        // 生成图片时：宽度至少为 containerWidth，确保背景填满，无“背后视图”泄露
        let image = self.renderAttachmentImage(
            rows: rows,
            hasHeader: hasHeader,
            style: style,
            horizontalMargin: tableHorizontalMargin,
            minWidth: containerWidth
        )
        
        if containerWidth > 0, image.size.width > containerWidth + 1 {
            // 超宽表格：生成的图片宽度为 naturalWidth，背景由图片自带或 UIScrollView 提供
            // 这里传入透明背景版本供滑动
            let scrollableImage = self.renderAttachmentImage(
                rows: rows,
                hasHeader: hasHeader,
                style: style,
                transparentBackground: true,
                horizontalMargin: tableHorizontalMargin
            )
            return NSAttributedString(attachment: STScrollableTableAttachment(
                tableImage: scrollableImage,
                containerWidth: containerWidth,
                backgroundColor: style.tableBackgroundColor ?? UIColor.secondarySystemBackground
            ))
        }

        let attachment = NSTextAttachment()
        attachment.image = image
        // 保证附件宽度覆盖 renderWidth，即使表格内容较窄，背景也会延伸到右侧
        if containerWidth > 0, image.size.width > 0 {
            let scale = containerWidth / image.size.width
            attachment.bounds = CGRect(x: 0, y: 0, width: containerWidth, height: image.size.height * scale)
        } else {
            attachment.bounds = CGRect(origin: .zero, size: image.size)
        }
        return NSAttributedString(attachment: attachment)
    }
}

/// 表格单元格内容片段：普通文本 或 数学公式
private enum CellFragment {
    case text(String)
    case math(formula: String, isDisplayMode: Bool)
}

/// 表格单元格：由多个 CellFragment 组成
private struct CellContent {
    let fragments: [CellFragment]
}

private extension STMarkdownTableAttachmentRenderer {

    // MARK: - 构建单元格内容

    func makeRows(from table: STMarkdownTableModel) -> [[CellContent]] {
        var rows: [[CellContent]] = []
        if let header = table.header {
            rows.append(header.map(self.cellContent))
        }
        rows.append(contentsOf: table.rows.map { $0.map(self.cellContent) })
        return rows
    }

    func cellContent(from nodes: [STMarkdownInlineNode]) -> CellContent {
        var fragments: [CellFragment] = []
        self.collectFragments(from: nodes, into: &fragments)
        return CellContent(fragments: fragments)
    }

    func collectFragments(from nodes: [STMarkdownInlineNode], into fragments: inout [CellFragment]) {
        for node in nodes {
            switch node {
            case .text(let text):
                fragments.append(.text(text))
            case .inlineMath(let formula, let isDisplayMode):
                fragments.append(.math(formula: formula, isDisplayMode: isDisplayMode))
            case .emphasis(let children), .strong(let children):
                self.collectFragments(from: children, into: &fragments)
            case .code(let code):
                fragments.append(.text(code))
            case .link(_, let children):
                self.collectFragments(from: children, into: &fragments)
            case .image(_, let alt, _):
                fragments.append(.text(alt.isEmpty ? "[image]" : alt))
            case .softBreak:
                fragments.append(.text(" "))
            case .strikethrough(let children):
                self.collectFragments(from: children, into: &fragments)
            }
        }
    }

    /// 将公式中的 LaTeX 转义序列归一化为 SwiftMath 可识别的形式
    func normalizedFormula(_ formula: String) -> String {
        formula
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: #"\\("#, with: "")
            .replacingOccurrences(of: #"\\)"#, with: "")
            .replacingOccurrences(of: #"\\["#, with: "")
            .replacingOccurrences(of: #"\\]"#, with: "")
            .replacingOccurrences(of: #"\'"#, with: "'")
            .replacingOccurrences(of: #"\|"#, with: "|")
    }

    /// 用 SwiftMath 渲染行内公式为图片
    func renderMathImage(formula: String, fontSize: CGFloat, textColor: UIColor) -> UIImage? {
        let normalized = self.normalizedFormula(formula)
        let label = MTMathUILabel()
        label.latex = normalized
        label.fontSize = fontSize
        label.textColor = textColor
        label.backgroundColor = .clear
        label.labelMode = .text
        label.textAlignment = .left
        label.contentInsets = UIEdgeInsets(top: 1, left: 0, bottom: 1, right: 0)
        label.displayErrorInline = true
        let fittingSize = label.sizeThatFits(CGSize(width: CGFloat(600), height: CGFloat.greatestFiniteMagnitude))
        guard fittingSize.width > 0, fittingSize.height > 0 else { return nil }
        label.frame = CGRect(origin: .zero, size: CGSize(width: ceil(fittingSize.width), height: ceil(fittingSize.height)))
        let format = UIGraphicsImageRendererFormat.default()
        let renderer = UIGraphicsImageRenderer(size: label.bounds.size, format: format)
        return renderer.image { context in
            let cgContext = context.cgContext
            cgContext.translateBy(x: 0, y: label.bounds.size.height)
            cgContext.scaleBy(x: 1, y: -1)
            label.layer.render(in: cgContext)
        }
    }

    // MARK: - 测量与绘制

    /// 计算单元格内容的自然宽度
    func measureCellWidth(_ cell: CellContent, font: UIFont, textColor: UIColor, padding: CGFloat) -> CGFloat {
        var width: CGFloat = 0
        for fragment in cell.fragments {
            switch fragment {
            case .text(let text):
                width += ceil((text as NSString).size(withAttributes: [.font: font]).width)
            case .math(let formula, _):
                if let img = self.renderMathImage(formula: formula, fontSize: max(font.pointSize - 1, 12), textColor: textColor) {
                    let scale = min(1, font.lineHeight / img.size.height)
                    width += ceil(img.size.width * scale)
                } else {
                    // fallback: 当作纯文本测量
                    width += ceil((formula as NSString).size(withAttributes: [.font: font]).width)
                }
            }
        }
        return width + padding * 2
    }

    /// 在指定矩形内绘制单元格内容（混合文本和公式图片）
    func drawCell(
        _ cell: CellContent,
        in rect: CGRect,
        font: UIFont,
        textColor: UIColor,
        context: CGContext
    ) {
        var x = rect.origin.x
        let midY = rect.midY

        for fragment in cell.fragments {
            switch fragment {
            case .text(let text):
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: textColor,
                ]
                let size = (text as NSString).size(withAttributes: attrs)
                let textY = midY - size.height / 2
                (text as NSString).draw(
                    in: CGRect(x: x, y: textY, width: rect.maxX - x, height: size.height),
                    withAttributes: attrs
                )
                x += ceil(size.width)

            case .math(let formula, _):
                if let img = self.renderMathImage(formula: formula, fontSize: max(font.pointSize - 1, 12), textColor: textColor) {
                    let scale = min(1, font.lineHeight / img.size.height)
                    let drawW = ceil(img.size.width * scale)
                    let drawH = ceil(img.size.height * scale)
                    let imgY = midY - drawH / 2
                    context.saveGState()
                    context.translateBy(x: x, y: imgY + drawH)
                    context.scaleBy(x: 1, y: -1)
                    if let cgImage = img.cgImage {
                        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: drawW, height: drawH))
                    }
                    context.restoreGState()
                    x += drawW
                } else {
                    let attrs: [NSAttributedString.Key: Any] = [
                        .font: font,
                        .foregroundColor: textColor,
                    ]
                    let size = (formula as NSString).size(withAttributes: attrs)
                    let textY = midY - size.height / 2
                    (formula as NSString).draw(
                        in: CGRect(x: x, y: textY, width: rect.maxX - x, height: size.height),
                        withAttributes: attrs
                    )
                    x += ceil(size.width)
                }
            }
        }
    }

    // MARK: - 渲染表格图片

    func renderAttachmentImage(
        rows: [[CellContent]],
        hasHeader: Bool,
        style: STMarkdownStyle,
        transparentBackground: Bool = false,
        horizontalMargin: CGFloat = 0,
        minWidth: CGFloat = 0
    ) -> UIImage {
        let columnCount = rows.map(\.count).max() ?? 0
        let emptyCell = CellContent(fragments: [])
        let paddedRows = rows.map { row in
            row + Array(repeating: emptyCell, count: max(0, columnCount - row.count))
        }

        let headerFont = UIFont.st_systemFont(ofSize: max(style.font.pointSize - 1, 12), weight: .semibold)
        let bodyFont = UIFont.st_systemFont(ofSize: max(style.font.pointSize - 1, 12), weight: .regular)
        let textColor = style.tableTextColor ?? style.textColor
        let headerTextColor = style.tableHeaderTextColor ?? style.textColor
        let horizontalPadding: CGFloat = 10
        let verticalPadding: CGFloat = 8
        let minimumColumnWidth: CGFloat = 56
        let maxTableWidth: CGFloat = style.renderWidth > 0 ? style.renderWidth : 300

        var columnWidths = Array(repeating: minimumColumnWidth, count: columnCount)
        for rowIndex in paddedRows.indices {
            for columnIndex in paddedRows[rowIndex].indices {
                let font = hasHeader && rowIndex == 0 ? headerFont : bodyFont
                let color = hasHeader && rowIndex == 0 ? headerTextColor : textColor
                let width = self.measureCellWidth(
                    paddedRows[rowIndex][columnIndex],
                    font: font,
                    textColor: color,
                    padding: horizontalPadding
                )
                columnWidths[columnIndex] = max(columnWidths[columnIndex], width)
            }
        }

        let naturalWidth = columnWidths.reduce(0, +)
        let separatorWidth = CGFloat(max(columnCount - 1, 0))
        // 不缩放：保留各列自然宽度，超宽时由调用方通过 UIScrollView 实现水平滚动
        _ = maxTableWidth

        let rowHeight = max(ceil(headerFont.lineHeight), ceil(bodyFont.lineHeight)) + (verticalPadding * 2)
        // 总宽度包含左右边距，并确保至少达到 minWidth (renderWidth) 以填充背景
        let contentWidth = naturalWidth + (horizontalMargin * 2) + separatorWidth
        let totalWidth = max(contentWidth, minWidth)
        let totalHeight = CGFloat(paddedRows.count) * rowHeight + 1

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = style.resolvedDisplayScale
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: totalWidth, height: totalHeight), format: format)

        return renderer.image { context in
            let cgContext = context.cgContext
            let backgroundColor = style.tableBackgroundColor ?? UIColor.secondarySystemBackground
            let borderColor = (style.tableBorderColor ?? UIColor.separator).cgColor
            
            // 始终填充完整背景色（除非显式要求透明，但在本方案中滑动图片也应自带背景）
            if !transparentBackground {
                backgroundColor.setFill()
                cgContext.fill(CGRect(x: 0, y: 0, width: totalWidth, height: totalHeight))
            }

            var y: CGFloat = 0
            for rowIndex in paddedRows.indices {
                let isHeader = hasHeader && rowIndex == 0
                let rowBackground = isHeader
                    ? (style.tableBackgroundColor ?? UIColor.secondarySystemBackground).withAlphaComponent(0.92)
                    : (style.tableBackgroundColor ?? UIColor.secondarySystemBackground)
                
                // 行背景也填充包含边距的全宽
                cgContext.setFillColor(rowBackground.cgColor)
                cgContext.fill(CGRect(x: 0, y: y, width: totalWidth, height: rowHeight))

                // 从水平边距开始绘制单元格
                var x: CGFloat = horizontalMargin
                for columnIndex in paddedRows[rowIndex].indices {
                    let font = isHeader ? headerFont : bodyFont
                    let color = isHeader ? headerTextColor : textColor
                    let cellRect = CGRect(
                        x: x + horizontalPadding,
                        y: y + verticalPadding,
                        width: columnWidths[columnIndex] - (horizontalPadding * 2),
                        height: rowHeight - (verticalPadding * 2)
                    )
                    self.drawCell(
                        paddedRows[rowIndex][columnIndex],
                        in: cellRect,
                        font: font,
                        textColor: color,
                        context: cgContext
                    )

                    cgContext.setStrokeColor(borderColor)
                    cgContext.setLineWidth(1 / style.resolvedDisplayScale)
                    cgContext.stroke(CGRect(x: x, y: y, width: columnWidths[columnIndex], height: rowHeight))
                    x += columnWidths[columnIndex] + 1
                }
                y += rowHeight
            }
        }
    }
}
