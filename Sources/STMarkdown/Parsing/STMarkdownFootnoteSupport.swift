//
//  STMarkdownFootnoteSupport.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2019/03/16.
//

import Foundation

// MARK: - 定义行剥离

enum STMarkdownFootnoteDefinitionScanner {
    private static let definitionLine = try! NSRegularExpression(
        pattern: #"^\[\^([^\]]+)\]:\s*(.*)$"#,
        options: []
    )

    /// 剥离脚注定义行，返回剩余 Markdown 与 `label -> 定义原文`（单行定义；多行续行可后续扩展）。
    static func stripDefinitions(from markdown: String) -> (markdown: String, rawBodies: [String: String]) {
        var definitions: [String: String] = [:]
        var kept: [String] = []
        for line in markdown.components(separatedBy: "\n") {
            let ns = line as NSString
            let range = NSRange(location: 0, length: ns.length)
            guard let match = Self.definitionLine.firstMatch(in: line, range: range),
                  match.numberOfRanges >= 3,
                  let labelR = Range(match.range(at: 1), in: line),
                  let bodyR = Range(match.range(at: 2), in: line)
            else {
                kept.append(line)
                continue
            }
            let label = String(line[labelR])
            let body = String(line[bodyR])
            definitions[label] = body
        }
        return (kept.joined(separator: "\n"), definitions)
    }
}

// MARK: - 定义体 -> AST

enum STMarkdownFootnoteDefinitionBuilder {
    static func definitions(
        from rawBodies: [String: String],
        parseFragment: (String) -> STMarkdownDocument
    ) -> [String: STMarkdownFootnoteDefinition] {
        var out: [String: STMarkdownFootnoteDefinition] = [:]
        for (label, raw) in rawBodies {
            let trimmed = raw.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty {
                out[label] = STMarkdownFootnoteDefinition(content: [])
                continue
            }
            let doc = parseFragment(trimmed)
            out[label] = STMarkdownFootnoteDefinition(content: Self.inlineContent(from: doc))
        }
        return out
    }

    private static func inlineContent(from document: STMarkdownDocument) -> [STMarkdownInlineNode] {
        var chunks: [[STMarkdownInlineNode]] = []
        for block in document.blocks {
            switch block {
            case .paragraph(let inlines):
                chunks.append(inlines)
            default:
                return fallbackPlainText(from: document)
            }
        }
        guard chunks.isEmpty == false else { return [] }
        var merged: [STMarkdownInlineNode] = []
        for (idx, part) in chunks.enumerated() {
            if idx > 0 { merged.append(.softBreak) }
            merged.append(contentsOf: part)
        }
        return merged
    }

    private static func fallbackPlainText(from document: STMarkdownDocument) -> [STMarkdownInlineNode] {
        [.text(document.blocks.map { blockPlain($0) }.joined(separator: "\n"))]
    }

    private static func blockPlain(_ block: STMarkdownBlockNode) -> String {
        switch block {
        case .paragraph(let n), .heading(_, let n):
            return n.map { $0.st_plainTextForTOC() }.joined()
        case .codeBlock(_, let code):
            return code
        default:
            return ""
        }
    }
}

// MARK: - 正文 `[^label]` -> footnoteReference

enum STMarkdownFootnoteInlineInjector {
    private static let refRegex = try! NSRegularExpression(
        pattern: #"\[\^([^\]]+)\]"#,
        options: []
    )

    static func apply(_ document: STMarkdownDocument) -> STMarkdownDocument {
        STMarkdownDocument(
            blocks: document.blocks.map { injectBlock($0) },
            footnoteDefinitions: document.footnoteDefinitions
        )
    }

    private static func injectBlock(_ block: STMarkdownBlockNode) -> STMarkdownBlockNode {
        switch block {
        case .paragraph(let inlines):
            return .paragraph(injectInlines(inlines))
        case .heading(let level, let content):
            return .heading(level: level, content: injectInlines(content))
        case .quote(let inner):
            return .quote(inner.map { injectBlock($0) })
        case .list(let kind, let items):
            return .list(
                kind: kind,
                items: items.map { item in
                    STMarkdownListItemNode(
                        blocks: item.blocks.map { injectBlock($0) },
                        checkbox: item.checkbox
                    )
                }
            )
        case .details(let summary, let body):
            return .details(summary: injectInlines(summary), body: body.map { injectBlock($0) })
        case .codeBlock, .table, .mathBlock, .image, .thematicBreak, .rawHTML:
            return block
        }
    }

    private static func injectInlines(_ nodes: [STMarkdownInlineNode]) -> [STMarkdownInlineNode] {
        var out: [STMarkdownInlineNode] = []
        for n in nodes {
            out.append(contentsOf: injectOne(n))
        }
        return out
    }

    private static func injectOne(_ node: STMarkdownInlineNode) -> [STMarkdownInlineNode] {
        switch node {
        case .text(let s):
            return splitText(s)
        case .emphasis(let c):
            let inner = injectInlines(c)
            return inner.isEmpty ? [] : [.emphasis(inner)]
        case .strong(let c):
            let inner = injectInlines(c)
            return inner.isEmpty ? [] : [.strong(inner)]
        case .strikethrough(let c):
            let inner = injectInlines(c)
            return inner.isEmpty ? [] : [.strikethrough(inner)]
        case .link(let dest, let c):
            let inner = injectInlines(c)
            return inner.isEmpty ? [] : [.link(destination: dest, children: inner)]
        case .footnoteReference, .inlineRawHTML, .inlineMath, .code, .image, .softBreak:
            return [node]
        }
    }

    private static func splitText(_ text: String) -> [STMarkdownInlineNode] {
        let ns = text as NSString
        let full = NSRange(location: 0, length: ns.length)
        let matches = Self.refRegex.matches(in: text, range: full)
        if matches.isEmpty {
            return text.isEmpty ? [] : [.text(text)]
        }
        var parts: [STMarkdownInlineNode] = []
        var cursor = 0
        for m in matches {
            if m.range.location > cursor {
                let sub = ns.substring(with: NSRange(location: cursor, length: m.range.location - cursor))
                if sub.isEmpty == false {
                    parts.append(.text(sub))
                }
            }
            if let labelR = Range(m.range(at: 1), in: text) {
                parts.append(.footnoteReference(label: String(text[labelR])))
            }
            cursor = m.range.location + m.range.length
        }
        if cursor < ns.length {
            let tail = ns.substring(from: cursor)
            if tail.isEmpty == false {
                parts.append(.text(tail))
            }
        }
        return parts
    }
}

// MARK: - 渲染 AST 尾部脚注区

enum STMarkdownFootnoteSectionBuilder {
    static func appendingSectionIfNeeded(
        document: STMarkdownDocument,
        renderBlocks: [STMarkdownRenderBlock]
    ) -> [STMarkdownRenderBlock] {
        let labels = orderedReferenceLabels(in: renderBlocks)
        guard labels.isEmpty == false else { return renderBlocks }
        var out = renderBlocks
        var nextTopLevelIndex = renderBlocks.count
        out.append(.thematicBreak(metadata(kind: .thematicBreak, topLevelIndex: nextTopLevelIndex)))
        nextTopLevelIndex += 1
        out.append(.paragraph(metadata(kind: .paragraph, topLevelIndex: nextTopLevelIndex), [.strong([.text("脚注")])]))
        nextTopLevelIndex += 1
        for (idx, label) in labels.enumerated() {
            let ordinal = idx + 1
            let def = document.footnoteDefinitions[label]?.content ?? [.text("（未找到定义）")]
            var line: [STMarkdownInlineNode] = [.strong([.text("\(ordinal).")]), .text(" ")]
            line.append(contentsOf: def)
            out.append(.paragraph(metadata(kind: .paragraph, topLevelIndex: nextTopLevelIndex + idx), line))
        }
        return out
    }

    /// 正文中脚注引用首次出现顺序（与上标编号一致）。
    static func orderedReferenceLabels(in blocks: [STMarkdownRenderBlock]) -> [String] {
        var order: [String] = []
        var seen: Set<String> = []
        for b in blocks {
            visitRenderBlock(b, order: &order, seen: &seen)
        }
        return order
    }

    private static func visitRenderBlock(_ block: STMarkdownRenderBlock, order: inout [String], seen: inout Set<String>) {
        switch block {
        case .paragraph(_, let inlines):
            visitInlines(inlines, order: &order, seen: &seen)
        case .heading(_, level: _, anchorId: _, content: let inlines):
            visitInlines(inlines, order: &order, seen: &seen)
        case .quote(_, let inner):
            inner.forEach { visitRenderBlock($0, order: &order, seen: &seen) }
        case .list(_, let items):
            for item in items {
                for b in item.blocks {
                    visitRenderBlock(b, order: &order, seen: &seen)
                }
            }
        case .details(_, summary: let summary, body: let body):
            visitInlines(summary, order: &order, seen: &seen)
            body.forEach { visitRenderBlock($0, order: &order, seen: &seen) }
        case .codeBlock, .table, .mathBlock, .image, .thematicBreak, .rawHTML:
            break
        }
    }

    private static func metadata(
        kind: STMarkdownRenderBlockKind,
        topLevelIndex: Int
    ) -> STMarkdownRenderBlockMetadata {
        let path = ["b:\(topLevelIndex)"]
        return STMarkdownRenderBlockMetadata(
            id: path.joined(separator: "/"),
            path: path,
            kind: kind,
            revealPolicy: revealPolicy(for: kind)
        )
    }

    private static func revealPolicy(for kind: STMarkdownRenderBlockKind) -> STMarkdownRevealPolicy {
        switch kind {
        case .paragraph, .heading:
            return .inlineProgressive
        case .quote, .list, .details:
            return .containerThenContent
        case .codeBlock, .table, .mathBlock, .image, .thematicBreak, .rawHTML:
            return .atomicBlock
        }
    }

    private static func visitInlines(_ nodes: [STMarkdownInlineNode], order: inout [String], seen: inout Set<String>) {
        for n in nodes {
            switch n {
            case .footnoteReference(let label):
                if seen.insert(label).inserted {
                    order.append(label)
                }
            case .emphasis(let c), .strong(let c), .strikethrough(let c):
                visitInlines(c, order: &order, seen: &seen)
            case .link(_, let c):
                visitInlines(c, order: &order, seen: &seen)
            default:
                break
            }
        }
    }
}

// MARK: - 脚注上标编号映射（渲染器）

enum STMarkdownFootnoteOrdinalResolver {
    static func ordinalMap(for blocks: [STMarkdownRenderBlock]) -> [String: Int] {
        let labels = STMarkdownFootnoteSectionBuilder.orderedReferenceLabels(in: blocks)
        var map: [String: Int] = [:]
        for (i, l) in labels.enumerated() {
            map[l] = i + 1
        }
        return map
    }
}
