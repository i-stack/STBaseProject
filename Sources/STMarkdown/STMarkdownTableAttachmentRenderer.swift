//
//  STMarkdownTableAttachmentRenderer.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2019/03/16.
//

import UIKit

public struct STMarkdownTableAttachmentRenderer: STMarkdownTableRendering {
    public init() {}

    public func renderTable(
        _ table: STMarkdownTableModel,
        style: STMarkdownStyle
    ) -> NSAttributedString? {
        let rows = self.makeRows(from: table)
        guard rows.isEmpty == false else { return nil }

        let image = self.renderAttachmentImage(rows: rows, hasHeader: table.header != nil, style: style)
        let attachment = NSTextAttachment()
        attachment.image = image
        attachment.bounds = CGRect(origin: .zero, size: image.size)
        return NSAttributedString(attachment: attachment)
    }
}

private extension STMarkdownTableAttachmentRenderer {
    func makeRows(from table: STMarkdownTableModel) -> [[String]] {
        var rows: [[String]] = []
        if let header = table.header {
            rows.append(header.map(self.plainText))
        }
        rows.append(contentsOf: table.rows.map { $0.map(self.plainText) })
        return rows
    }

    func plainText(from nodes: [STMarkdownInlineNode]) -> String {
        nodes.map { node in
            switch node {
            case .text(let text):
                return text
            case .inlineMath(let formula, _):
                return formula
            case .emphasis(let children), .strong(let children):
                return self.plainText(from: children)
            case .code(let code):
                return code
            case .link(_, let children):
                return self.plainText(from: children)
            case .image(_, let alt, _):
                return alt.isEmpty ? "[image]" : alt
            case .softBreak:
                return " "
            }
        }.joined()
    }

    func renderAttachmentImage(
        rows: [[String]],
        hasHeader: Bool,
        style: STMarkdownStyle
    ) -> UIImage {
        let columnCount = rows.map(\.count).max() ?? 0
        let paddedRows = rows.map { row in
            row + Array(repeating: "", count: max(0, columnCount - row.count))
        }

        let headerFont = UIFont.st_systemFont(ofSize: max(style.font.pointSize - 1, 12), weight: .semibold)
        let bodyFont = UIFont.st_systemFont(ofSize: max(style.font.pointSize - 1, 12), weight: .regular)
        let horizontalPadding: CGFloat = 10
        let verticalPadding: CGFloat = 8
        let minimumColumnWidth: CGFloat = 56
        let maxTableWidth: CGFloat = 300

        var columnWidths = Array(repeating: minimumColumnWidth, count: columnCount)
        for rowIndex in paddedRows.indices {
            for columnIndex in paddedRows[rowIndex].indices {
                let font = hasHeader && rowIndex == 0 ? headerFont : bodyFont
                let width = ceil((paddedRows[rowIndex][columnIndex] as NSString).size(withAttributes: [.font: font]).width) + (horizontalPadding * 2)
                columnWidths[columnIndex] = max(columnWidths[columnIndex], width)
            }
        }

        let naturalWidth = columnWidths.reduce(0, +)
        let separatorWidth = CGFloat(max(columnCount - 1, 0))
        let scale = naturalWidth > maxTableWidth ? maxTableWidth / naturalWidth : 1
        columnWidths = columnWidths.map { max(minimumColumnWidth, floor($0 * scale)) }

        let rowHeight = max(ceil(headerFont.lineHeight), ceil(bodyFont.lineHeight)) + (verticalPadding * 2)
        let totalWidth = columnWidths.reduce(0, +) + separatorWidth
        let totalHeight = CGFloat(paddedRows.count) * rowHeight + 1

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = UIScreen.main.scale
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: totalWidth, height: totalHeight), format: format)

        return renderer.image { context in
            let cgContext = context.cgContext
            let backgroundColor = style.tableBackgroundColor ?? UIColor.secondarySystemBackground
            let borderColor = (style.tableBorderColor ?? UIColor.separator).cgColor
            backgroundColor.setFill()
            cgContext.fill(CGRect(x: 0, y: 0, width: totalWidth, height: totalHeight))

            var y: CGFloat = 0
            for rowIndex in paddedRows.indices {
                let isHeader = hasHeader && rowIndex == 0
                let rowBackground = isHeader
                    ? (style.tableBackgroundColor ?? UIColor.secondarySystemBackground).withAlphaComponent(0.92)
                    : (style.tableBackgroundColor ?? UIColor.secondarySystemBackground)
                cgContext.setFillColor(rowBackground.cgColor)
                cgContext.fill(CGRect(x: 0, y: y, width: totalWidth, height: rowHeight))

                var x: CGFloat = 0
                for columnIndex in paddedRows[rowIndex].indices {
                    let font = isHeader ? headerFont : bodyFont
                    let textColor = isHeader
                        ? (style.tableHeaderTextColor ?? style.textColor)
                        : (style.tableTextColor ?? style.textColor)
                    let textRect = CGRect(
                        x: x + horizontalPadding,
                        y: y + verticalPadding,
                        width: columnWidths[columnIndex] - (horizontalPadding * 2),
                        height: rowHeight - (verticalPadding * 2)
                    )
                    (paddedRows[rowIndex][columnIndex] as NSString).draw(
                        in: textRect,
                        withAttributes: [
                            .font: font,
                            .foregroundColor: textColor,
                        ]
                    )

                    cgContext.setStrokeColor(borderColor)
                    cgContext.setLineWidth(1 / UIScreen.main.scale)
                    cgContext.stroke(CGRect(x: x, y: y, width: columnWidths[columnIndex], height: rowHeight))
                    x += columnWidths[columnIndex] + 1
                }
                y += rowHeight
            }
        }
    }
}
