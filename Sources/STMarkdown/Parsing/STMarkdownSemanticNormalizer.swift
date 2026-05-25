//
//  STMarkdownSemanticNormalizer.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2019/03/16.
//

import Foundation

public protocol STMarkdownSemanticNormalizing: Sendable {
    func normalize(_ document: STMarkdownDocument) -> STMarkdownDocument
}

public struct STMarkdownSemanticNormalizer: STMarkdownSemanticNormalizing {
    public static let passthrough = STMarkdownSemanticNormalizer(normalizers: [])

    public let normalizers: [any STMarkdownSemanticNormalizing]

    public init(normalizers: [any STMarkdownSemanticNormalizing] = []) {
        self.normalizers = normalizers
    }

    public func normalize(_ document: STMarkdownDocument) -> STMarkdownDocument {
        self.normalizers.reduce(document) { partial, normalizer in
            normalizer.normalize(partial)
        }
    }
}

public struct STMarkdownSoftBreakCollapsingNormalizer: STMarkdownSemanticNormalizing {
    public init() {}

    public func normalize(_ document: STMarkdownDocument) -> STMarkdownDocument {
        let defs = document.footnoteDefinitions.mapValues { def in
            STMarkdownFootnoteDefinition(content: self.normalizeInlineNodes(def.content))
        }
        return STMarkdownDocument(
            blocks: document.blocks.map(self.normalizeBlock),
            footnoteDefinitions: defs
        )
    }
}

private extension STMarkdownSoftBreakCollapsingNormalizer {
    func normalizeBlock(_ block: STMarkdownBlockNode) -> STMarkdownBlockNode {
        switch block {
        case .paragraph(let inlines):
            return .paragraph(self.normalizeInlineNodes(inlines))
        case .heading(let level, let content):
            return .heading(level: level, content: self.normalizeInlineNodes(content))
        case .quote(let blocks):
            return .quote(blocks.map(self.normalizeBlock))
        case .list(let kind, let items):
            return .list(
                kind: kind,
                items: items.map { item in
                    STMarkdownListItemNode(
                        blocks: item.blocks.map(self.normalizeBlock),
                        checkbox: item.checkbox
                    )
                }
            )
        case .details(let summary, let body):
            return .details(
                summary: self.normalizeInlineNodes(summary),
                body: body.map(self.normalizeBlock)
            )
        case .codeBlock, .table, .mathBlock, .image, .thematicBreak, .rawHTML:
            return block
        }
    }

    func normalizeInlineNodes(_ nodes: [STMarkdownInlineNode]) -> [STMarkdownInlineNode] {
        var result: [STMarkdownInlineNode] = []
        result.reserveCapacity(nodes.count)

        for node in nodes {
            switch node {
            case .softBreak:
                if case .softBreak = result.last {
                    continue
                }
                result.append(.softBreak)
            case .emphasis(let children):
                result.append(.emphasis(self.normalizeInlineNodes(children)))
            case .strong(let children):
                result.append(.strong(self.normalizeInlineNodes(children)))
            case .link(let destination, let children):
                result.append(.link(destination: destination, children: self.normalizeInlineNodes(children)))
            case .strikethrough(let children):
                result.append(.strikethrough(self.normalizeInlineNodes(children)))
            case .footnoteReference, .inlineRawHTML, .inlineMath, .code, .image, .text, .softBreak:
                result.append(node)
            }
        }

        return result
    }
}

/// heading 内容恰好是单一 `strong` 节点时剥除外层包裹（`### **text**` → `### text`）。
/// 仅在全部内联恰好在同一个 strong 内时触发，不影响局部加粗的 heading（`### **A** B`）。
/// 用途：避免渲染层对 heading font 和 strong bold trait 的双重叠加。
public struct STMarkdownHeadingStandaloneStrongNormalizer: STMarkdownSemanticNormalizing {
    public init() {}

    public func normalize(_ document: STMarkdownDocument) -> STMarkdownDocument {
        STMarkdownDocument(
            blocks: document.blocks.map(Self.normalizeBlock),
            footnoteDefinitions: document.footnoteDefinitions
        )
    }

    private static func normalizeBlock(_ block: STMarkdownBlockNode) -> STMarkdownBlockNode {
        guard case .heading(let level, let content) = block,
              content.count == 1,
              case .strong(let children) = content[0]
        else { return block }
        return .heading(level: level, content: children)
    }
}
