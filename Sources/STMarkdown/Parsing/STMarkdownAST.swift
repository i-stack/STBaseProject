//
//  STMarkdownAST.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2019/03/16.
//

import Foundation

public enum STMarkdownInlineNode: Hashable, Sendable {
    case text(String)
    case inlineMath(String, isDisplayMode: Bool)
    case emphasis([STMarkdownInlineNode])
    case strong([STMarkdownInlineNode])
    case code(String)
    case link(destination: String, children: [STMarkdownInlineNode])
    case image(source: String, alt: String, title: String?)
    case softBreak
    case strikethrough([STMarkdownInlineNode])
    case footnoteReference(label: String)
    case inlineRawHTML(String)
}

public enum STMarkdownCheckbox: Hashable, Sendable {
    case checked
    case unchecked
}

public enum STMarkdownListKind: Hashable, Sendable {
    case ordered(startIndex: Int)
    case unordered
}

public struct STMarkdownListItemNode: Hashable, Sendable {
    public let blocks: [STMarkdownBlockNode]
    public let checkbox: STMarkdownCheckbox?
    public init(blocks: [STMarkdownBlockNode], checkbox: STMarkdownCheckbox? = nil) {
        self.blocks = blocks
        self.checkbox = checkbox
    }
}

public enum STMarkdownColumnAlignment: Hashable, Sendable {
    case left
    case center
    case right
}

public struct STMarkdownTableModel: Hashable, Sendable {
    public let header: [[STMarkdownInlineNode]]?
    public let rows: [[[STMarkdownInlineNode]]]
    public let columnAlignments: [STMarkdownColumnAlignment]

    public init(header: [[STMarkdownInlineNode]]?, rows: [[[STMarkdownInlineNode]]]) {
        self.header = header
        self.rows = rows
        self.columnAlignments = []
    }

    public init(header: [[STMarkdownInlineNode]]?, rows: [[[STMarkdownInlineNode]]], columnAlignments: [STMarkdownColumnAlignment]) {
        self.header = header
        self.rows = rows
        self.columnAlignments = columnAlignments
    }

    /// 将数据行按"首列为空→延续同组"规则分组，返回基于 `rows` 0-based 下标的分组数组。
    /// 首列有内容时开启新分组；首列为空且当前组非空时延续当前组。
    /// 用于渲染层实现跨行视觉分组效果（对应 LLM 输出的空首列=合并单元格模式）。
    public var rowGroups: [[Int]] {
        guard !rows.isEmpty else { return [] }
        var groups: [[Int]] = []
        var current: [Int] = []
        var currentGroupHeadEmpty = false
        for (index, row) in rows.enumerated() {
            let isEmpty = Self.isCellContentEmpty(row.first ?? [])
            if isEmpty && !current.isEmpty && !currentGroupHeadEmpty {
                current.append(index)
            } else {
                if !current.isEmpty { groups.append(current) }
                current = [index]
                currentGroupHeadEmpty = isEmpty
            }
        }
        if !current.isEmpty { groups.append(current) }
        return groups
    }

    private static func isCellContentEmpty(_ cell: [STMarkdownInlineNode]) -> Bool {
        if cell.isEmpty { return true }
        return cell.allSatisfy {
            switch $0 {
            case .text(let t): return t.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            case .softBreak: return true
            default: return false
            }
        }
    }
}

public enum STMarkdownBlockNode: Hashable, Sendable {
    case paragraph([STMarkdownInlineNode])
    case heading(level: Int, content: [STMarkdownInlineNode])
    case quote([STMarkdownBlockNode])
    case list(kind: STMarkdownListKind, items: [STMarkdownListItemNode])
    case codeBlock(language: String?, code: String)
    case table(STMarkdownTableModel)
    case mathBlock(String)
    case image(url: String, altText: String, title: String?)
    case thematicBreak
    case details(summary: [STMarkdownInlineNode], body: [STMarkdownBlockNode])
    case rawHTML(String)
}

/// 脚注定义体（`[^label]:` 行抽取）；与 ``STMarkdownInlineNode/footnoteReference(label:)`` 配对。
public struct STMarkdownFootnoteDefinition: Hashable, Sendable {
    public let content: [STMarkdownInlineNode]

    public init(content: [STMarkdownInlineNode]) {
        self.content = content
    }
}

public struct STMarkdownDocument: Hashable, Sendable {
    public let blocks: [STMarkdownBlockNode]
    public let footnoteDefinitions: [String: STMarkdownFootnoteDefinition]

    public init(blocks: [STMarkdownBlockNode], footnoteDefinitions: [String: STMarkdownFootnoteDefinition] = [:]) {
        self.blocks = blocks
        self.footnoteDefinitions = footnoteDefinitions
    }
}
