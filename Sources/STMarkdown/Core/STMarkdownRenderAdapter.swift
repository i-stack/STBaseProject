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
///
/// - Note: ``STMarkdownRenderBlock/heading(level:anchorId:content:)`` 的 `anchorId` 须与
///   ``STMarkdownTOCItem/anchorId``、``NSAttributedString.Key/stMarkdownHeadingAnchor`` 一致；
///   自定义适配器若无法生成 slug，可对纯文本标题使用稳定哈希并保证文档内唯一。
/// - Important: 正式 adapter 必须产出结构化 `metadata.path/id`（如 `b:0/q:0`）；
///   不要复用兼容工厂里的通用 metadata 作为正式渲染路径标识。
public protocol STMarkdownRenderAdapting: Sendable {
    func adapt(_ document: STMarkdownDocument) -> STMarkdownRenderDocument
}

public struct STMarkdownRenderAdapter: STMarkdownRenderAdapting, Sendable {
    public init() {}

    public func adapt(_ document: STMarkdownDocument) -> STMarkdownRenderDocument {
        var slugger = STMarkdownAnchorSlugRegistry()
        let mainBlocks = document.blocks.enumerated().map {
            self.makeRenderBlock(
                from: $0.element,
                listLevel: 0,
                path: ["b:\($0.offset)"],
                slugger: &slugger
            )
        }
        let merged = STMarkdownFootnoteSectionBuilder.appendingSectionIfNeeded(
            document: document,
            renderBlocks: mainBlocks
        )
        return STMarkdownRenderDocument(blocks: merged)
    }
}

private extension STMarkdownRenderAdapter {
    func makeRenderBlock(
        from block: STMarkdownBlockNode,
        listLevel: Int,
        path: [String],
        slugger: inout STMarkdownAnchorSlugRegistry
    ) -> STMarkdownRenderBlock {
        switch block {
        case .paragraph(let inlines):
            return .paragraph(self.makeMetadata(kind: .paragraph, path: path), inlines)
        case .heading(let level, let content):
            let plain = content.st_plainTextForTOC()
            let anchorId = slugger.uniqueAnchorId(forPlainTitle: plain)
            return .heading(
                self.makeMetadata(kind: .heading, path: path),
                level: level,
                anchorId: anchorId,
                content: content
            )
        case .quote(let blocks):
            // Quote 内嵌 list 时不推进 listLevel：产品侧把引用块视作视觉"容器"，
            // 不改变列表的逻辑嵌套深度（层级仍以真实 list 节点计算）。
            return .quote(
                self.makeMetadata(kind: .quote, path: path),
                blocks.enumerated().map {
                    self.makeRenderBlock(
                        from: $0.element,
                        listLevel: listLevel,
                        path: path + ["q:\($0.offset)"],
                        slugger: &slugger
                    )
                }
            )
        case .list(let kind, let items):
            return .list(
                self.makeMetadata(kind: .list, path: path),
                self.flattenListItems(
                    kind: kind,
                    items: items,
                    level: listLevel,
                    path: path,
                    slugger: &slugger
                )
            )
        case .codeBlock(let language, let code):
            return .codeBlock(self.makeMetadata(kind: .codeBlock, path: path), language: language, code: code)
        case .table(let table):
            return .table(self.makeMetadata(kind: .table, path: path), table)
        case .mathBlock(let latex):
            return .mathBlock(self.makeMetadata(kind: .mathBlock, path: path), latex)
        case .image(let url, let altText, let title):
            return .image(self.makeMetadata(kind: .image, path: path), url: url, altText: altText, title: title)
        case .thematicBreak:
            return .thematicBreak(self.makeMetadata(kind: .thematicBreak, path: path))
        case .details(let summary, let body):
            return .details(
                self.makeMetadata(kind: .details, path: path),
                summary: summary,
                body: body.enumerated().map {
                    self.makeRenderBlock(
                        from: $0.element,
                        listLevel: listLevel,
                        path: path + ["d:\($0.offset)"],
                        slugger: &slugger
                    )
                }
            )
        case .rawHTML(let html):
            return .rawHTML(self.makeMetadata(kind: .rawHTML, path: path), html)
        }
    }

    func flattenListItems(
        kind: STMarkdownListKind,
        items: [STMarkdownListItemNode],
        level: Int,
        path: [String],
        slugger: inout STMarkdownAnchorSlugRegistry
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
            let itemPath = path + ["li:\(index)"]
            let renderBlocks = item.blocks.enumerated().map {
                self.makeRenderBlock(
                    from: $0.element,
                    listLevel: level + 1,
                    path: itemPath + ["b:\($0.offset)"],
                    slugger: &slugger
                )
            }
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

    func makeMetadata(kind: STMarkdownRenderBlockKind, path: [String]) -> STMarkdownRenderBlockMetadata {
        STMarkdownRenderBlockMetadata(
            id: path.joined(separator: "/"),
            path: path,
            kind: kind,
            revealPolicy: self.revealPolicy(for: kind)
        )
    }

    func revealPolicy(for kind: STMarkdownRenderBlockKind) -> STMarkdownRevealPolicy {
        switch kind {
        case .paragraph, .heading:
            return .inlineProgressive
        case .quote, .list, .details:
            return .containerThenContent
        case .codeBlock, .table, .mathBlock, .image, .thematicBreak, .rawHTML:
            return .atomicBlock
        }
    }
}
