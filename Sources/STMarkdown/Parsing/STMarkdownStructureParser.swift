//
//  STMarkdownStructureParser.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2019/03/16.
//

import Foundation
import Markdown

public protocol STMarkdownStructureParsing: Sendable {
    func parse(_ markdown: String) -> STMarkdownDocument
}

public struct STMarkdownStructureParser: STMarkdownStructureParsing, Sendable {
    /// 串行化 swift-markdown / cmark 解析路径；使用递归锁以支持脚注定义体内再解析。
    private static let parseLock = NSRecursiveLock()

    /// 流式推测重写器列表，为空则不执行推测重写。
    /// 仅在流式场景下由调用方构造带重写器的实例。
    private let speculativeRewriters: [any STMarkdownSpeculativeRewriterProtocol]

    public init() {
        self.speculativeRewriters = []
    }

    /// 使用指定的推测重写器列表创建解析器。
    /// - Parameter speculativeRewriters: 流式推测重写器，默认空（不推测重写）。
    public init(speculativeRewriters: [any STMarkdownSpeculativeRewriterProtocol]) {
        self.speculativeRewriters = speculativeRewriters
    }

    /// 是否包含活跃的推测重写器
    public var hasActiveSpeculativeRewriters: Bool {
        !self.speculativeRewriters.isEmpty
    }

    public func parse(_ markdown: String) -> STMarkdownDocument {
        guard markdown.isEmpty == false else {
            return STMarkdownDocument(blocks: [])
        }
        Self.parseLock.lock()
        defer { Self.parseLock.unlock() }
        return self.parseUnlocked(markdown, stripFootnoteDefinitions: true)
    }

    /// 将短 Markdown 片段解析为单个段落的行内节点（脚注定义体、HTML `<summary>` 等）。
    public func parseInlineFragment(_ markdown: String) -> [STMarkdownInlineNode] {
        guard markdown.isEmpty == false else { return [] }
        Self.parseLock.lock()
        defer { Self.parseLock.unlock() }
        let doc = self.parseUnlocked(markdown, stripFootnoteDefinitions: false)
        if let first = doc.blocks.first, case .paragraph(let inlines) = first {
            return inlines
        }
        return [.text(markdown)]
    }
}

private extension STMarkdownStructureParser {
    func parseUnlocked(_ markdown: String, stripFootnoteDefinitions: Bool) -> STMarkdownDocument {
        let working: String
        let rawDefs: [String: String]
        if stripFootnoteDefinitions {
            let pair = STMarkdownFootnoteDefinitionScanner.stripDefinitions(from: markdown)
            working = pair.markdown
            rawDefs = pair.rawBodies
        } else {
            working = markdown
            rawDefs = [:]
        }

        let footnoteDefs = STMarkdownFootnoteDefinitionBuilder.definitions(from: rawDefs) { [self] fragment in
            self.parseUnlocked(fragment, stripFootnoteDefinitions: false)
        }

        let normalized = STMarkdownMathNormalizer.normalizeBlocks(in: working)
        var document = Document(parsing: normalized.text)

        // 流式推测重写：在 Document 解析后、makeBlocks 前，
        // 对 AST 末尾未闭合的强调/表头做 AST 层补全。
        if speculativeRewriters.isEmpty == false {
            for rewriter in speculativeRewriters {
                if let rewritten = rewriter.rewriteIfApplicable(document: document) {
                    document = rewritten
                }
            }
        }

        let blocks = self.makeBlocks(from: Array(document.children), mathMap: normalized.blockMap)
        var doc = STMarkdownDocument(blocks: blocks, footnoteDefinitions: footnoteDefs)
        if stripFootnoteDefinitions {
            doc = STMarkdownFootnoteInlineInjector.apply(doc)
        }
        return doc
    }

    static let mathBlockRegex = STMarkdownRegexFactory.compile(
        pattern: #"\{\{ST_MATH_BLOCK:(\d+)\}\}"#,
        owner: "STMarkdownStructureParser.mathBlock"
    )

    func makeBlocks(from markups: [Markup], mathMap: [Int: String]) -> [STMarkdownBlockNode] {
        var blocks: [STMarkdownBlockNode] = []

        for block in markups {
            if let paragraph = block as? Paragraph {
                if let mathBlocks = self.extractMathBlocks(from: paragraph, mathMap: mathMap) {
                    blocks.append(contentsOf: mathBlocks)
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
                blocks.append(.codeBlock(language: codeBlock.language, code: codeBlock.code))
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
                let alignments: [STMarkdownColumnAlignment] = table.columnAlignments.map { alignment in
                    switch alignment {
                    case .center: return .center
                    case .right: return .right
                    default: return .left
                    }
                }
                blocks.append(.table(STMarkdownTableModel(
                    header: header.isEmpty ? nil : header,
                    rows: rows,
                    columnAlignments: alignments
                )))
                continue
            }

            if let htmlBlock = block as? HTMLBlock {
                let classified = STMarkdownHTMLBlockClassifier.classify(html: htmlBlock.rawHTML) { [self] fragment in
                    self.parseUnlocked(fragment, stripFootnoteDefinitions: false)
                }
                blocks.append(classified)
                continue
            }

            if block is ThematicBreak {
                blocks.append(.thematicBreak)
                continue
            }

            let fallbackInlines = block.children.flatMap { self.inlineNodes(from: $0) }
            if fallbackInlines.isEmpty == false {
                blocks.append(.paragraph(fallbackInlines))
            }
        }

        return blocks
    }

    /// 识别段落中一个或多个 `{{ST_MATH_BLOCK:N}}` 占位符，拆成 `.mathBlock` + 夹在之间的 `.paragraph`。
    /// 返回 nil 表示段落内无占位符，交给上游走普通段落路径。
    ///
    /// 识别范围仅限于段落**顶层**的 Text 节点。若占位符被包进 strong/emphasis/link 之类的
    /// 父节点（例如 `**{{ST_MATH_BLOCK:0}}**`），这里视为不可识别，返回 nil 让段落按普通
    /// 路径渲染——在这种病理情况下用户会看到字面占位符，但这比悄悄丢掉外层 inline 结构更安全。
    /// 正常链路下 `STMarkdownMathNormalizer` 会在块公式前后插空行，不会走到这个分支。
    func extractMathBlocks(from paragraph: Paragraph, mathMap: [Int: String]) -> [STMarkdownBlockNode]? {
        let inlines = self.inlineNodes(from: paragraph)

        let hasTopLevelPlaceholder = inlines.contains { node in
            guard case .text(let raw) = node else { return false }
            let range = NSRange(location: 0, length: raw.utf16.count)
            return Self.mathBlockRegex.firstMatch(in: raw, range: range) != nil
        }
        guard hasTopLevelPlaceholder else { return nil }

        var blocks: [STMarkdownBlockNode] = []
        var pending: [STMarkdownInlineNode] = []

        func flushPending() {
            let meaningful = pending.contains { Self.isMeaningfulInline($0) }
            if meaningful {
                blocks.append(.paragraph(pending))
            }
            pending.removeAll(keepingCapacity: true)
        }

        for node in inlines {
            guard case .text(let raw) = node else {
                pending.append(node)
                continue
            }

            let nsText = raw as NSString
            let matches = Self.mathBlockRegex.matches(
                in: raw,
                range: NSRange(location: 0, length: nsText.length)
            )

            if matches.isEmpty {
                pending.append(node)
                continue
            }

            var cursor = 0
            for match in matches {
                if match.range.location > cursor {
                    let prefix = nsText.substring(
                        with: NSRange(location: cursor, length: match.range.location - cursor)
                    )
                    if prefix.isEmpty == false {
                        pending.append(.text(prefix))
                    }
                }
                if let indexRange = Range(match.range(at: 1), in: raw),
                   let index = Int(raw[indexRange]),
                   let latex = mathMap[index] {
                    flushPending()
                    blocks.append(.mathBlock(latex))
                } else {
                    // mathMap 缺失（例如用户/模型直接输出字面 `{{ST_MATH_BLOCK:N}}`，
                    // 或者 normalizer 未注册该序号）时，把原文占位符作为 `.text` 回填到
                    // 当前段落，避免 flushPending 后 block 被静默丢弃导致整段消失。
                    let literal = nsText.substring(with: match.range)
                    if literal.isEmpty == false {
                        pending.append(.text(literal))
                    }
                }
                cursor = match.range.location + match.range.length
            }

            if cursor < nsText.length {
                let suffix = nsText.substring(
                    with: NSRange(location: cursor, length: nsText.length - cursor)
                )
                if suffix.isEmpty == false {
                    pending.append(.text(suffix))
                }
            }
        }
        flushPending()
        return blocks
    }

    private static func isMeaningfulInline(_ node: STMarkdownInlineNode) -> Bool {
        switch node {
        case .softBreak:
            return false
        case .text(let raw):
            return raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
        default:
            return true
        }
    }

    func listItems(from markups: [Markup], mathMap: [Int: String]) -> [STMarkdownListItemNode] {
        markups.compactMap { markup in
            guard let item = markup as? ListItem else { return nil }
            let checkbox: STMarkdownCheckbox?
            if let cb = item.checkbox {
                switch cb {
                case .checked:   checkbox = .checked
                case .unchecked: checkbox = .unchecked
                }
            } else {
                checkbox = nil
            }
            let childBlocks = self.makeBlocks(from: Array(item.children), mathMap: mathMap)
            if childBlocks.isEmpty {
                let fallbackInlines = item.children.flatMap { self.inlineNodes(from: $0) }
                if fallbackInlines.isEmpty {
                    return STMarkdownListItemNode(blocks: [], checkbox: checkbox)
                }
                return STMarkdownListItemNode(blocks: [.paragraph(fallbackInlines)], checkbox: checkbox)
            }
            return STMarkdownListItemNode(blocks: childBlocks, checkbox: checkbox)
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
        if let strikethrough = markup as? Strikethrough {
            return [.strikethrough(strikethrough.children.flatMap { self.inlineNodes(from: $0) })]
        }
        if let inlineHTML = markup as? InlineHTML {
            return [.inlineRawHTML(inlineHTML.rawHTML)]
        }
        return markup.children.flatMap { self.inlineNodes(from: $0) }
    }

    func normalizeLinkDestination(_ destination: String) -> String {
        destination
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: #"\/"#, with: "/")
    }
}
