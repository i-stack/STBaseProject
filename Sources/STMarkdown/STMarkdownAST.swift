//
//  STMarkdownAST.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2019/03/16.
//

import Foundation

public enum STMarkdownInlineNode: Hashable {
    case text(String)
    case inlineMath(String, isDisplayMode: Bool)
    case emphasis([STMarkdownInlineNode])
    case strong([STMarkdownInlineNode])
    case code(String)
    case link(destination: String, children: [STMarkdownInlineNode])
    case image(source: String, alt: String, title: String?)
    case softBreak
}

public enum STMarkdownListKind: Hashable {
    case ordered(startIndex: Int)
    case unordered
}

public struct STMarkdownListItemNode: Hashable {
    public let blocks: [STMarkdownBlockNode]

    public init(blocks: [STMarkdownBlockNode]) {
        self.blocks = blocks
    }
}

public struct STMarkdownTableModel: Hashable {
    public let header: [[STMarkdownInlineNode]]?
    public let rows: [[[STMarkdownInlineNode]]]

    public init(header: [[STMarkdownInlineNode]]?, rows: [[[STMarkdownInlineNode]]]) {
        self.header = header
        self.rows = rows
    }
}

public enum STMarkdownBlockNode: Hashable {
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

public struct STMarkdownDocument: Hashable {
    public let blocks: [STMarkdownBlockNode]

    public init(blocks: [STMarkdownBlockNode]) {
        self.blocks = blocks
    }
}
