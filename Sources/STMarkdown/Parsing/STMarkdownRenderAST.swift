//
//  STMarkdownRenderAST.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2019/03/16.
//

import Foundation

public enum STMarkdownRenderBlockKind: String, Hashable, Sendable {
    case paragraph
    case heading
    case quote
    case list
    case codeBlock
    case table
    case mathBlock
    case image
    case thematicBreak
    case details
    case rawHTML
}

public enum STMarkdownRevealPolicy: String, Hashable, Sendable {
    case inlineProgressive
    case atomicBlock
    case containerThenContent
}

public struct STMarkdownRenderBlockMetadata: Hashable, Sendable {
    public let id: String
    public let path: [String]
    public let kind: STMarkdownRenderBlockKind
    public let revealPolicy: STMarkdownRevealPolicy

    public init(id: String, path: [String], kind: STMarkdownRenderBlockKind, revealPolicy: STMarkdownRevealPolicy) {
        self.id = id
        self.path = path
        self.kind = kind
        self.revealPolicy = revealPolicy
    }
}

public struct STMarkdownRenderDocument: Hashable, Sendable {
    public let blocks: [STMarkdownRenderBlock]

    public init(blocks: [STMarkdownRenderBlock]) {
        self.blocks = blocks
    }
}

public enum STMarkdownRenderBlock: Hashable, Sendable {
    case paragraph(STMarkdownRenderBlockMetadata, [STMarkdownInlineNode])
    case heading(STMarkdownRenderBlockMetadata, level: Int, anchorId: String, content: [STMarkdownInlineNode])
    case quote(STMarkdownRenderBlockMetadata, [STMarkdownRenderBlock])
    case list(STMarkdownRenderBlockMetadata, [STMarkdownRenderListItem])
    case codeBlock(STMarkdownRenderBlockMetadata, language: String?, code: String)
    case table(STMarkdownRenderBlockMetadata, STMarkdownTableModel)
    case mathBlock(STMarkdownRenderBlockMetadata, String)
    case image(STMarkdownRenderBlockMetadata, url: String, altText: String, title: String?)
    case thematicBreak(STMarkdownRenderBlockMetadata)
    case details(STMarkdownRenderBlockMetadata, summary: [STMarkdownInlineNode], body: [STMarkdownRenderBlock])
    case rawHTML(STMarkdownRenderBlockMetadata, String)

    public var metadata: STMarkdownRenderBlockMetadata {
        switch self {
        case .paragraph(let metadata, _),
             .heading(let metadata, level: _, anchorId: _, content: _),
             .quote(let metadata, _),
             .list(let metadata, _),
             .codeBlock(let metadata, language: _, code: _),
             .table(let metadata, _),
             .mathBlock(let metadata, _),
             .image(let metadata, url: _, altText: _, title: _),
             .thematicBreak(let metadata),
             .details(let metadata, summary: _, body: _),
             .rawHTML(let metadata, _):
            return metadata
        }
    }

    private static func compatibilityMetadata(kind: STMarkdownRenderBlockKind, revealPolicy: STMarkdownRevealPolicy) -> STMarkdownRenderBlockMetadata {
        let path = ["compat", kind.rawValue]
        return STMarkdownRenderBlockMetadata(id: path.joined(separator: "/"), path: path, kind: kind, revealPolicy: revealPolicy)
    }

    public static func paragraph(_ content: [STMarkdownInlineNode]) -> Self {
        .paragraph(
            Self.compatibilityMetadata(kind: .paragraph, revealPolicy: .inlineProgressive),
            content
        )
    }

    public static func heading(level: Int, content: [STMarkdownInlineNode]) -> Self {
        .heading(
            Self.compatibilityMetadata(kind: .heading, revealPolicy: .inlineProgressive),
            level: level,
            anchorId: "",
            content: content
        )
    }

    public static func heading(level: Int, anchorId: String, content: [STMarkdownInlineNode]) -> Self {
        .heading(
            Self.compatibilityMetadata(kind: .heading, revealPolicy: .inlineProgressive),
            level: level,
            anchorId: anchorId,
            content: content
        )
    }

    public static func quote(_ blocks: [STMarkdownRenderBlock]) -> Self {
        .quote(
            Self.compatibilityMetadata(kind: .quote, revealPolicy: .containerThenContent),
            blocks
        )
    }

    public static func list(_ items: [STMarkdownRenderListItem]) -> Self {
        .list(
            Self.compatibilityMetadata(kind: .list, revealPolicy: .containerThenContent),
            items
        )
    }

    public static func codeBlock(language: String?, code: String) -> Self {
        .codeBlock(
            Self.compatibilityMetadata(kind: .codeBlock, revealPolicy: .atomicBlock),
            language: language,
            code: code
        )
    }

    public static func table(_ model: STMarkdownTableModel) -> Self {
        .table(
            Self.compatibilityMetadata(kind: .table, revealPolicy: .atomicBlock),
            model
        )
    }

    public static func mathBlock(_ latex: String) -> Self {
        .mathBlock(
            Self.compatibilityMetadata(kind: .mathBlock, revealPolicy: .atomicBlock),
            latex
        )
    }

    public static func image(url: String, altText: String, title: String?) -> Self {
        .image(
            Self.compatibilityMetadata(kind: .image, revealPolicy: .atomicBlock),
            url: url,
            altText: altText,
            title: title
        )
    }

    public static func details(summary: [STMarkdownInlineNode], body: [STMarkdownRenderBlock]) -> Self {
        .details(
            Self.compatibilityMetadata(kind: .details, revealPolicy: .containerThenContent),
            summary: summary,
            body: body
        )
    }

    public static func rawHTML(_ html: String) -> Self {
        .rawHTML(
            Self.compatibilityMetadata(kind: .rawHTML, revealPolicy: .atomicBlock),
            html
        )
    }

    public static func thematicBreak() -> Self {
        .thematicBreak(
            Self.compatibilityMetadata(kind: .thematicBreak, revealPolicy: .atomicBlock)
        )
    }
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
            let path = ["li-paragraph"]
            let metadata = STMarkdownRenderBlockMetadata(
                id: path.joined(separator: "/"),
                path: path,
                kind: .paragraph,
                revealPolicy: .inlineProgressive
            )
            blocks.append(.paragraph(metadata, content))
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
        guard let first = self.blocks.first else {
            return []
        }
        switch first {
        case .paragraph(_, let inlines):
            return inlines
        default:
            return []
        }
    }

    /// 列表项的子块（排除开头那个 paragraph）。
    /// 当列表项不以 paragraph 开头时返回完整 `blocks`，因为此时没有独立的文案段。
    public var childBlocks: [STMarkdownRenderBlock] {
        guard let first = self.blocks.first else {
            return self.blocks
        }
        switch first {
        case .paragraph:
            break
        default:
            return self.blocks
        }
        return Array(self.blocks.dropFirst())
    }
}
