//
//  STMarkdownDefaultTableRenderer.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2019/03/16.
//

import UIKit

public struct STMarkdownDefaultTableRenderer: STMarkdownTableRendering {
    public init() {}

    public func renderTable(
        _ table: STMarkdownTableModel,
        style: STMarkdownStyle
    ) -> NSAttributedString? {
        let rows = self.makeRows(from: table)
        guard rows.isEmpty == false else {
            return nil
        }

        let columnCount = rows.map(\.count).max() ?? 0
        guard columnCount > 0 else {
            return nil
        }

        let paddedRows = rows.map { row in
            row + Array(repeating: "", count: max(0, columnCount - row.count))
        }
        let columnWidths = self.columnWidths(for: paddedRows)
        let result = NSMutableAttributedString()

        for (rowIndex, row) in paddedRows.enumerated() {
            let isHeader = table.header != nil && rowIndex == 0
            let renderedRow = self.renderRow(
                row,
                columnWidths: columnWidths,
                isHeader: isHeader,
                style: style
            )
            result.append(renderedRow)

            if rowIndex < paddedRows.count - 1 {
                result.append(NSAttributedString(string: "\n"))
            }

            if isHeader {
                result.append(NSAttributedString(string: "\n"))
                result.append(self.renderSeparator(columnWidths: columnWidths, style: style))
                if rowIndex < paddedRows.count - 1 {
                    result.append(NSAttributedString(string: "\n"))
                }
            }
        }

        return result
    }
}

private extension STMarkdownDefaultTableRenderer {
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
            case .strikethrough(let children):
                return self.plainText(from: children)
            }
        }.joined()
    }

    func columnWidths(for rows: [[String]]) -> [Int] {
        guard let firstRow = rows.first else { return [] }
        return firstRow.indices.map { column in
            rows.reduce(0) { partialResult, row in
                max(partialResult, row[column].count)
            }
        }
    }

    func renderRow(
        _ row: [String],
        columnWidths: [Int],
        isHeader: Bool,
        style: STMarkdownStyle
    ) -> NSAttributedString {
        let font = UIFont.st_monospacedSystemFont(
            ofSize: max(style.font.pointSize - 1, 12),
            weight: isHeader ? .semibold : .regular
        )
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: isHeader
                ? (style.tableHeaderTextColor ?? style.textColor)
                : (style.tableTextColor ?? style.textColor),
            .backgroundColor: style.tableBackgroundColor ?? UIColor.secondarySystemBackground,
        ]

        let rendered = row.enumerated().map { index, column in
            let paddingCount = max(0, columnWidths[index] - column.count)
            return " \(column)\(String(repeating: " ", count: paddingCount)) "
        }
        .joined(separator: "│")

        return NSAttributedString(string: rendered, attributes: attributes)
    }

    func renderSeparator(
        columnWidths: [Int],
        style: STMarkdownStyle
    ) -> NSAttributedString {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.st_monospacedSystemFont(ofSize: max(style.font.pointSize - 1, 12), weight: .regular),
            .foregroundColor: style.tableBorderColor ?? style.textColor.withAlphaComponent(0.55),
            .backgroundColor: style.tableBackgroundColor ?? UIColor.secondarySystemBackground,
        ]
        let separator = columnWidths.map { width in
            String(repeating: "─", count: width + 2)
        }
        .joined(separator: "┼")

        return NSAttributedString(string: separator, attributes: attributes)
    }
}
