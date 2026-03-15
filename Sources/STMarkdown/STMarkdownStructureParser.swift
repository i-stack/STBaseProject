//
//  STMarkdownStructureParser.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2019/03/16.
//

import Foundation
import Markdown

public protocol STMarkdownStructureParsing {
    func parse(_ markdown: String) -> STMarkdownDocument
}

public struct STMarkdownStructureParser: STMarkdownStructureParsing {
    public init() {}

    public func parse(_ markdown: String) -> STMarkdownDocument {
        let normalized = STMarkdownMathNormalizer.normalizeBlocks(in: markdown)
        let document = Document(parsing: normalized.text)
        let blocks = self.makeBlocks(from: Array(document.children), mathMap: normalized.blockMap)
        return STMarkdownDocument(blocks: blocks)
    }
}

private extension STMarkdownStructureParser {
    func makeBlocks(from markups: [Markup], mathMap: [Int: String]) -> [STMarkdownBlockNode] {
        let mathPattern = #"\{\{ST_MATH_BLOCK:(\d+)\}\}"#
        let mathRegex = try! NSRegularExpression(pattern: mathPattern)
        var blocks: [STMarkdownBlockNode] = []

        for block in markups {
            if let paragraph = block as? Paragraph {
                let plain = self.plainText(from: paragraph).trimmingCharacters(in: .whitespacesAndNewlines)
                if let match = mathRegex.firstMatch(
                    in: plain,
                    range: NSRange(location: 0, length: plain.utf16.count)
                ), let range = Range(match.range(at: 1), in: plain),
                   let index = Int(plain[range]),
                   let latex = mathMap[index] {
                    blocks.append(.mathBlock(latex))
                    continue
                }

                if paragraph.childCount == 1, let image = paragraph.child(at: 0) as? Image,
                   let source = image.source {
                    let altText = image.children.map { self.plainText(from: $0) }.joined()
                    blocks.append(.image(url: source, altText: altText, title: image.title))
                    continue
                }

                blocks.append(.paragraph(self.inlineNodes(from: paragraph)))
                continue
            }

            if let heading = block as? Heading {
                let content = heading.children.flatMap { self.inlineNodes(from: $0) }
                blocks.append(.heading(level: heading.level, content: content))
                continue
            }

            if let quote = block as? BlockQuote {
                blocks.append(.quote(self.makeBlocks(from: Array(quote.children), mathMap: mathMap)))
                continue
            }

            if let codeBlock = block as? CodeBlock {
                let code: String
                if codeBlock.childCount > 0, let first = codeBlock.child(at: 0) as? Text {
                    code = first.string
                } else {
                    code = self.plainText(from: codeBlock)
                }
                blocks.append(.codeBlock(language: codeBlock.language, code: code))
                continue
            }

            if let orderedList = block as? OrderedList {
                let items = self.listItems(from: Array(orderedList.children), mathMap: mathMap)
                blocks.append(.list(kind: .ordered(startIndex: Int(orderedList.startIndex)), items: items))
                continue
            }

            if let unorderedList = block as? UnorderedList {
                let items = self.listItems(from: Array(unorderedList.children), mathMap: mathMap)
                blocks.append(.list(kind: .unordered, items: items))
                continue
            }

            if let table = block as? Table {
                let header = Array(table.head.cells).map { self.inlineNodes(from: $0) }
                let rows = Array(table.body.rows).map { row in
                    Array(row.cells).map { self.inlineNodes(from: $0) }
                }
                blocks.append(.table(STMarkdownTableModel(header: header.isEmpty ? nil : header, rows: rows)))
                continue
            }

            if block is ThematicBreak {
                blocks.append(.thematicBreak)
                continue
            }

            let fallback = self.plainText(from: block)
            if fallback.isEmpty == false {
                blocks.append(.paragraph([.text(fallback)]))
            }
        }

        return blocks
    }

    func listItems(from markups: [Markup], mathMap: [Int: String]) -> [STMarkdownListItemNode] {
        markups.compactMap { markup in
            guard let item = markup as? ListItem else { return nil }
            let childBlocks = self.makeBlocks(from: Array(item.children), mathMap: mathMap)
            if childBlocks.isEmpty {
                let fallback = self.plainText(from: item)
                if fallback.isEmpty {
                    return STMarkdownListItemNode(blocks: [])
                }
                return STMarkdownListItemNode(blocks: [.paragraph([.text(fallback)])])
            }
            return STMarkdownListItemNode(blocks: childBlocks)
        }
    }

    func plainText(from markup: Markup) -> String {
        if let text = markup as? Text {
            return text.string
        }
        return markup.children.map { self.plainText(from: $0) }.joined()
    }

    func inlineNodes(from markup: Markup) -> [STMarkdownInlineNode] {
        if let text = markup as? Text {
            return STMarkdownMathNormalizer.splitInlineMath(in: text.string)
        }
        if let emphasis = markup as? Emphasis {
            return [.emphasis(emphasis.children.flatMap { self.inlineNodes(from: $0) })]
        }
        if let strong = markup as? Strong {
            return [.strong(strong.children.flatMap { self.inlineNodes(from: $0) })]
        }
        if let code = markup as? InlineCode {
            return [.code(code.code)]
        }
        if let link = markup as? Link {
            return [
                .link(
                    destination: self.normalizeLinkDestination(link.destination ?? ""),
                    children: link.children.flatMap { self.inlineNodes(from: $0) }
                )
            ]
        }
        if let image = markup as? Image {
            let alt = image.children.map { self.plainText(from: $0) }.joined()
            return [.image(source: image.source ?? "", alt: alt, title: image.title)]
        }
        if markup is SoftBreak || markup is LineBreak {
            return [.softBreak]
        }
        return markup.children.flatMap { self.inlineNodes(from: $0) }
    }

    func normalizeLinkDestination(_ destination: String) -> String {
        destination
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: #"\/"#, with: "/")
    }
}
