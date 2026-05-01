//
//  STMarkdownRenderAST.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2019/03/16.
//

import Foundation

public struct STMarkdownRenderDocument: Hashable, Sendable {
    public let blocks: [STMarkdownRenderBlock]

    public init(blocks: [STMarkdownRenderBlock]) {
        self.blocks = blocks
    }
}

public enum STMarkdownRenderBlock: Hashable, Sendable {
    case paragraph([STMarkdownInlineNode])
    case heading(level: Int, content: [STMarkdownInlineNode])
    case quote([STMarkdownRenderBlock])
    case list([STMarkdownRenderListItem])
    case codeBlock(language: String?, code: String)
    case table(STMarkdownTableModel)
    case mathBlock(String)
    case image(url: String, altText: String, title: String?)
    case thematicBreak
}

public struct STMarkdownRenderListItem: Hashable, Sendable {
    public let blocks: [STMarkdownRenderBlock]
    public let ordered: Bool
    public let level: Int
    public let orderedIndex: Int?
    public let checkbox: STMarkdownCheckbox?

    public init(
        blocks: [STMarkdownRenderBlock],
        ordered: Bool,
        level: Int,
        orderedIndex: Int?,
        checkbox: STMarkdownCheckbox? = nil
    ) {
        self.blocks = blocks
        self.ordered = ordered
        self.level = level
        self.orderedIndex = orderedIndex
        self.checkbox = checkbox
    }

    public init(
        content: [STMarkdownInlineNode],
        ordered: Bool,
        level: Int,
        orderedIndex: Int?,
        childBlocks: [STMarkdownRenderBlock],
        checkbox: STMarkdownCheckbox? = nil
    ) {
        var blocks: [STMarkdownRenderBlock] = []
        if content.isEmpty == false {
            blocks.append(.paragraph(content))
        }
        blocks.append(contentsOf: childBlocks)
        self.init(
            blocks: blocks,
            ordered: ordered,
            level: level,
            orderedIndex: orderedIndex,
            checkbox: checkbox
        )
    }

    /// 列表项文案（仅对"第一个 block 是 paragraph"的项有效）。
    /// 当列表项以 quote / codeBlock / list 等非段落块开头时返回空数组——
    /// 此时该项的全部内容都在 `childBlocks` 里，请不要据此判空。
    public var content: [STMarkdownInlineNode] {
        guard case .paragraph(let inlines)? = self.blocks.first else {
            return []
        }
        return inlines
    }

    /// 列表项的子块（排除开头那个 paragraph）。
    /// 当列表项不以 paragraph 开头时返回完整 `blocks`，因为此时没有独立的文案段。
    public var childBlocks: [STMarkdownRenderBlock] {
        guard case .paragraph? = self.blocks.first else {
            return self.blocks
        }
        return Array(self.blocks.dropFirst())
    }
}
