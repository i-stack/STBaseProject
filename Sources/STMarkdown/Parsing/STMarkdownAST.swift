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
    /// GFM 风格脚注引用（标签不含 `^` 前缀，例如 `"1"`、`"note"`）。
    case footnoteReference(label: String)
    /// swift-markdown 解析到的行内 HTML；渲染策略见 ``STMarkdownStyle/rawHTMLPolicy``。
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
    /// 从 ``HTMLBlock`` 识别的 `<details>`（折叠语义由宿主 UI 承载时，渲染侧先展开为缩进块）。
    case details(summary: [STMarkdownInlineNode], body: [STMarkdownBlockNode])
    /// 块级原始 HTML；默认不当作富文本解析，见 ``STMarkdownRawHTMLPolicy``。
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
    /// 从正文剥离的脚注定义；引用仍以内联 ``STMarkdownInlineNode/footnoteReference`` 表示。
    public let footnoteDefinitions: [String: STMarkdownFootnoteDefinition]

    public init(blocks: [STMarkdownBlockNode], footnoteDefinitions: [String: STMarkdownFootnoteDefinition] = [:]) {
        self.blocks = blocks
        self.footnoteDefinitions = footnoteDefinitions
    }
}
