//
//  STMarkdownRenderAdapter.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2019/03/16.
//

import Foundation

/// Transforms a parsed `STMarkdownDocument` into a flattened `STMarkdownRenderDocument`
/// suitable for the rendering pipeline.
///
/// Conformances must be stateless (or internally thread-safe) so that a single adapter
/// instance can be shared across concurrent pipeline invocations.
public protocol STMarkdownRenderAdapting: Sendable {
    func adapt(_ document: STMarkdownDocument) -> STMarkdownRenderDocument
}

public struct STMarkdownRenderAdapter: STMarkdownRenderAdapting, Sendable {
    public init() {}

    public func adapt(_ document: STMarkdownDocument) -> STMarkdownRenderDocument {
        STMarkdownRenderDocument(blocks: document.blocks.map { self.makeRenderBlock(from: $0, listLevel: 0) })
    }
}

private extension STMarkdownRenderAdapter {
    func makeRenderBlock(from block: STMarkdownBlockNode, listLevel: Int) -> STMarkdownRenderBlock {
        switch block {
        case .paragraph(let inlines):
            return .paragraph(inlines)
        case .heading(let level, let content):
            return .heading(level: level, content: content)
        case .quote(let blocks):
            // Quote 内嵌 list 时不推进 listLevel：产品侧把引用块视作视觉"容器"，
            // 不改变列表的逻辑嵌套深度（层级仍以真实 list 节点计算）。
            return .quote(blocks.map { self.makeRenderBlock(from: $0, listLevel: listLevel) })
        case .list(let kind, let items):
            return .list(self.flattenListItems(kind: kind, items: items, level: listLevel))
        case .codeBlock(let language, let code):
            return .codeBlock(language: language, code: code)
        case .table(let table):
            return .table(table)
        case .mathBlock(let latex):
            return .mathBlock(latex)
        case .image(let url, let altText, let title):
            return .image(url: url, altText: altText, title: title)
        case .thematicBreak:
            return .thematicBreak
        }
    }

    func flattenListItems(
        kind: STMarkdownListKind,
        items: [STMarkdownListItemNode],
        level: Int
    ) -> [STMarkdownRenderListItem] {
        var result: [STMarkdownRenderListItem] = []
        let isOrdered: Bool
        let startIndex: Int

        switch kind {
        case .ordered(let start):
            isOrdered = true
            startIndex = start
        case .unordered:
            isOrdered = false
            startIndex = 1
        }

        for (index, item) in items.enumerated() {
            let orderedIndex = isOrdered ? startIndex + index : nil
            let renderBlocks = item.blocks.map { self.makeRenderBlock(from: $0, listLevel: level + 1) }
            result.append(
                STMarkdownRenderListItem(
                    blocks: renderBlocks,
                    ordered: isOrdered,
                    level: level,
                    orderedIndex: orderedIndex,
                    checkbox: item.checkbox
                )
            )
        }

        return result
    }
}
