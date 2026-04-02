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
}

public struct STMarkdownDocument: Hashable, Sendable {
    public let blocks: [STMarkdownBlockNode]
    public init(blocks: [STMarkdownBlockNode]) {
        self.blocks = blocks
    }
}
