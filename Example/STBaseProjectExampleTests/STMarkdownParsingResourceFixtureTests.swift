//
//  STMarkdownParsingResourceFixtureTests.swift
//  STBaseProjectExampleTests
//
//  以 Example/STBaseProjectExample/Resources/data1~3.txt 为 fixture，
//  覆盖 STMarkdown/Parsing 目录各模块在真实 LLM 输出上的行为。
//
//  模块映射：
//  - STMarkdownInputSanitizer / defaultRules → sanitizer 阶段
//  - STMarkdownMalformedTableNormalizer → 表格预修复（data2）
//  - STMarkdownMathNormalizer → StructureParser 内块级公式（data1~3 无 $$ 时不应误拆）
//  - STMarkdownStructureParser + FootnoteSupport + HTMLBlockClassifier → parse 阶段
//  - STMarkdownSemanticNormalizer → 语义归一
//  - STMarkdownAST / STMarkdownRenderAST → 管线结果结构
//  - STMarkdownFootnoteDeepLink（internal）→ 由 STMarkdownFootnoteAndHTMLTests / Renderer 间接覆盖
//

import XCTest
import STBaseProject

// MARK: - Fixture 加载

private enum STMarkdownParsingResourceFixture {
    static let names = ["data1", "data2", "data3"]

    static func text(named name: String) throws -> String {
        let testFileURL = URL(fileURLWithPath: #filePath)
        let projectRoot = testFileURL
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let fixtureURL = projectRoot
            .appendingPathComponent("STBaseProjectExample")
            .appendingPathComponent("Resources")
            .appendingPathComponent(name)
            .appendingPathExtension("txt")
        return try String(contentsOf: fixtureURL, encoding: .utf8)
    }
}

// MARK: - 轻量 AST 辅助

private func st_joinInlinePlainText(_ nodes: [STMarkdownInlineNode]) -> String {
    nodes.map { st_inlinePlainText($0) }.joined()
}

private func st_inlinePlainText(_ node: STMarkdownInlineNode) -> String {
    switch node {
    case .text(let s):
        return s
    case .softBreak:
        return "\n"
    case .inlineMath(let f, _):
        return f
    case .code(let s):
        return s
    case .emphasis(let c), .strong(let c), .strikethrough(let c):
        return st_joinInlinePlainText(c)
    case .link(_, let c):
        return st_joinInlinePlainText(c)
    case .image(_, let alt, _):
        return alt
    case .footnoteReference(let label):
        return "[^\(label)]"
    case .inlineRawHTML(let raw):
        return raw
    }
}

private func st_documentPlainText(_ document: STMarkdownDocument) -> String {
    func walkBlocks(_ blocks: [STMarkdownBlockNode]) -> String {
        blocks.map { block in
            switch block {
            case .paragraph(let inlines):
                return st_joinInlinePlainText(inlines)
            case .heading(_, let inlines):
                return st_joinInlinePlainText(inlines)
            case .quote(let children):
                return walkBlocks(children)
            case .list(_, let items):
                return items.map { walkBlocks($0.blocks) }.joined()
            case .table(let table):
                let header = (table.header ?? []).flatMap { $0 }
                let rows = table.rows.flatMap { $0 }.flatMap { $0 }
                return st_joinInlinePlainText(header + rows)
            case .codeBlock(_, let code):
                return code
            case .mathBlock(let formula):
                return formula
            case .image(_, let alt, let title):
                return alt + (title ?? "")
            case .thematicBreak:
                return ""
            case .details(let summary, let body):
                return st_joinInlinePlainText(summary) + walkBlocks(body)
            case .rawHTML(let html):
                return html
            }
        }.joined(separator: "\n")
    }
    return walkBlocks(document.blocks)
}

private func st_containsInlineLink(to term: String, in nodes: [STMarkdownInlineNode]) -> Bool {
    for node in nodes {
        switch node {
        case .link(let destination, let children):
            let text = st_joinInlinePlainText(children)
            if text.contains(term) { return true }
            if destination.contains(term) { return true }
        case .emphasis(let c), .strong(let c), .strikethrough(let c):
            if st_containsInlineLink(to: term, in: c) { return true }
        default:
            break
        }
    }
    return false
}

private func st_collectAllInlines(from document: STMarkdownDocument) -> [STMarkdownInlineNode] {
    var result: [STMarkdownInlineNode] = []
    func walkBlocks(_ blocks: [STMarkdownBlockNode]) {
        for block in blocks {
            switch block {
            case .paragraph(let inlines), .heading(_, let inlines):
                result.append(contentsOf: inlines)
            case .quote(let children):
                walkBlocks(children)
            case .list(_, let items):
                for item in items { walkBlocks(item.blocks) }
            case .table(let table):
                let header = (table.header ?? []).flatMap { $0 }
                let rows = table.rows.flatMap { $0 }.flatMap { $0 }
                result.append(contentsOf: header + rows)
            case .details(let summary, let body):
                result.append(contentsOf: summary)
                walkBlocks(body)
            default:
                break
            }
        }
    }
    walkBlocks(document.blocks)
    return result
}

private func st_assertNoRawMarkdownSyntaxLeaks(in output: String, file: StaticString = #filePath, line: UInt = #line) {
    let forbidden = ["```", "{{ST_MATH_BLOCK:", "$$", "\\(", "\\)"]
    for token in forbidden {
        XCTAssertFalse(
            output.contains(token),
            "渲染可见串不得残留定界符：\(token.debugDescription)",
            file: file,
            line: line
        )
    }
}

// MARK: - Tests

final class STMarkdownParsingResourceFixtureTests: XCTestCase {

    // MARK: 全 fixture 管线冒烟（Engine = Sanitizer + MalformedTable + Parser + Semantic + RenderAdapter）

    func testAllResourceFixturesCompletePipeline() throws {
        let engine = STMarkdownEngine()
        for name in STMarkdownParsingResourceFixture.names {
            let markdown = try STMarkdownParsingResourceFixture.text(named: name)
            XCTAssertFalse(markdown.isEmpty, "\(name) fixture 不应为空")

            let result = engine.process(markdown)
            XCTAssertFalse(result.sourceDocument.blocks.isEmpty, "\(name) source AST 不应为空")
            XCTAssertFalse(result.normalizedDocument.blocks.isEmpty, "\(name) normalized AST 不应为空")
            XCTAssertFalse(result.renderDocument.blocks.isEmpty, "\(name) render AST 不应为空")
            XCTAssertFalse(result.tableOfContents.isEmpty, "\(name) 应抽取至少一个标题目录项")
        }
    }

    // MARK: STMarkdownInputSanitizer

    func testInputSanitizer_AllResourceFixturesProduceNonEmptySanitizedText() throws {
        let sanitizer = STMarkdownInputSanitizer(rules: STMarkdownInputSanitizer.defaultRules)
        for name in STMarkdownParsingResourceFixture.names {
            let raw = try STMarkdownParsingResourceFixture.text(named: name)
            let outcome = sanitizer.sanitize(raw)
            XCTAssertFalse(outcome.sanitizedText.isEmpty, "\(name) sanitizer 输出不应为空")
            XCTAssertGreaterThan(
                outcome.sanitizedText.count,
                raw.count / 4,
                "\(name) sanitizer 不应过度截断正文"
            )
        }
    }

    // MARK: STMarkdownMalformedTableNormalizer

    func testMalformedTableNormalizer_Data2IsIdempotent() throws {
        let raw = try STMarkdownParsingResourceFixture.text(named: "data2")
        let sanitizer = STMarkdownInputSanitizer(rules: STMarkdownInputSanitizer.defaultRules)
        let sanitized = sanitizer.sanitize(raw).sanitizedText

        let once = STMarkdownMalformedTableNormalizer.normalize(sanitized)
        let twice = STMarkdownMalformedTableNormalizer.normalize(once)
        XCTAssertEqual(once, twice, "data2 表格预修复应幂等")
        XCTAssertTrue(once.contains("|"), "data2 预修复后应保留表格竖线")
    }

    // MARK: STMarkdownMathNormalizer（经 StructureParser 间接）

    func testMathNormalizer_ResourceFixturesDoNotFabricateBlockMathPlaceholders() throws {
        let parser = STMarkdownStructureParser()
        for name in STMarkdownParsingResourceFixture.names {
            let raw = try STMarkdownParsingResourceFixture.text(named: name)
            let normalized = STMarkdownMathNormalizer.normalizeBlocks(in: raw)
            XCTAssertTrue(
                normalized.blockMap.isEmpty,
                "\(name) 不含独立 $$ 块级公式时不应生成 math block 占位"
            )
            let doc = parser.parse(normalized.text)
            XCTAssertFalse(doc.blocks.isEmpty, "\(name) 经 math 预处理后仍应可解析")
            let plain = st_documentPlainText(doc)
            XCTAssertFalse(
                plain.contains("{{ST_MATH_BLOCK:"),
                "\(name) 可见语义文本不应含块公式占位符"
            )
        }
    }

    // MARK: STMarkdownStructureParser（含 FootnoteSupport / HTMLBlockClassifier 路径）

    func testStructureParser_Data1PreservesBracketTermsAndHeadings() throws {
        let raw = try STMarkdownParsingResourceFixture.text(named: "data1")
        let doc = STMarkdownStructureParser().parse(raw)
        let plain = st_documentPlainText(doc)
        XCTAssertTrue(plain.contains("第一步"), "data1 应解析出「第一步」")
        XCTAssertTrue(plain.contains("偏头痛") || plain.contains("咖啡因"), "data1 应保留方括号术语正文")

        let inlines = st_collectAllInlines(from: doc)
        XCTAssertTrue(
            st_containsInlineLink(to: "偏头痛", in: inlines)
                || plain.contains("[偏头痛]")
                || plain.contains("偏头痛"),
            "data1 方括号术语应解析为链接或保留可读正文"
        )

        let headingCount = doc.blocks.compactMap { block -> Int? in
            if case .heading(let level, _) = block { return level }
            return nil
        }.count
        XCTAssertGreaterThanOrEqual(headingCount, 5, "data1 应含多级标题")
    }

    func testStructureParser_Data2ProducesSingleWellFormedTable() throws {
        let raw = try STMarkdownParsingResourceFixture.text(named: "data2")
        let sanitized = STMarkdownInputSanitizer(rules: STMarkdownInputSanitizer.defaultRules)
            .sanitize(raw).sanitizedText
        let parserInput = STMarkdownMalformedTableNormalizer.normalize(sanitized)
        let doc = STMarkdownStructureParser().parse(parserInput)

        let tables = doc.blocks.compactMap { block -> STMarkdownTableModel? in
            if case .table(let model) = block { return model }
            return nil
        }
        XCTAssertEqual(tables.count, 1, "data2 应解析出单个主表格")
        guard let table = tables.first else { return }
        XCTAssertGreaterThanOrEqual(table.header?.count ?? 0, 3)
        XCTAssertGreaterThanOrEqual(table.rows.count, 8)

        let headerText = st_joinInlinePlainText((table.header ?? []).flatMap { $0 })
        XCTAssertTrue(headerText.contains("类别"))
        XCTAssertTrue(headerText.contains("具体建议"))
    }

    func testStructureParser_Data3NestedListsCodeBlocksAndCitationText() throws {
        let raw = try STMarkdownParsingResourceFixture.text(named: "data3")
        let doc = STMarkdownStructureParser().parse(raw)

        let codeBlocks = doc.blocks.compactMap { block -> (String?, String)? in
            if case .codeBlock(let lang, let code) = block { return (lang, code) }
            return nil
        }
        XCTAssertGreaterThanOrEqual(codeBlocks.count, 2, "data3 应含 markdown/html 代码块")
        XCTAssertTrue(codeBlocks.contains { ($0.0 ?? "").lowercased().contains("markdown") })
        XCTAssertTrue(codeBlocks.contains { ($0.0 ?? "").lowercased().contains("html") })

        let lists = doc.blocks.compactMap { block -> STMarkdownListKind? in
            if case .list(let kind, _) = block { return kind }
            return nil
        }
        XCTAssertFalse(lists.isEmpty, "data3 应含列表块")
        XCTAssertTrue(lists.contains { if case .ordered = $0 { return true }; return false })

        let plain = st_documentPlainText(doc)
        XCTAssertTrue(plain.contains("[5]") || plain.contains("[8]"), "data3 引用角标应保留在 AST 语义文本中")
        XCTAssertTrue(plain.contains("应用场景"))
    }

    // MARK: STMarkdownSemanticNormalizer

    func testSemanticNormalizer_PassthroughPreservesResourceBlockCount() throws {
        let parser = STMarkdownStructureParser()
        let normalizer = STMarkdownSemanticNormalizer.passthrough
        for name in STMarkdownParsingResourceFixture.names {
            let raw = try STMarkdownParsingResourceFixture.text(named: name)
            let parsed = parser.parse(raw)
            let normalized = normalizer.normalize(parsed)
            XCTAssertEqual(
                parsed.blocks.count,
                normalized.blocks.count,
                "\(name) passthrough 归一化不应改变块数量"
            )
        }
    }

      // MARK: 端到端渲染（Parsing 输出经 RenderAdapter + Renderer）

    func testRenderedPlainText_AllResourceFixturesNoSyntaxLeaks() throws {
        let engine = STMarkdownEngine()
        let renderer = STMarkdownAttributedStringRenderer(style: .default, advancedRenderers: .empty)
        for name in STMarkdownParsingResourceFixture.names {
            let markdown = try STMarkdownParsingResourceFixture.text(named: name)
            let result = engine.process(markdown)
            let plain = renderer.render(document: result.renderDocument).string
            XCTAssertFalse(plain.isEmpty, "\(name) 渲染结果不应为空")
            st_assertNoRawMarkdownSyntaxLeaks(in: plain)
        }
    }

    func testRenderedPlainText_Data1ContainsExpectedSectionTitles() throws {
        let markdown = try STMarkdownParsingResourceFixture.text(named: "data1")
        let plain = STMarkdownAttributedStringRenderer(style: .default, advancedRenderers: .empty)
            .render(document: STMarkdownEngine().process(markdown).renderDocument)
            .string
        XCTAssertTrue(plain.contains("第一步"))
        XCTAssertTrue(plain.contains("第三步"))
        XCTAssertTrue(plain.contains("立即"))
    }

    func testRenderedPlainText_Data2ContainsTableContent() throws {
        let markdown = try STMarkdownParsingResourceFixture.text(named: "data2")
        let plain = STMarkdownAttributedStringRenderer(style: .default, advancedRenderers: .empty)
            .render(document: STMarkdownEngine().process(markdown).renderDocument)
            .string
        XCTAssertTrue(plain.contains("减肥方法"))
        XCTAssertTrue(plain.contains("控制热量摄入"))
    }

    func testRenderedPlainText_Data3PreservesExampleSectionTitles() throws {
        let markdown = try STMarkdownParsingResourceFixture.text(named: "data3")
        let plain = STMarkdownAttributedStringRenderer(style: .default, advancedRenderers: .empty)
            .render(document: STMarkdownEngine().process(markdown).renderDocument)
            .string
        XCTAssertTrue(plain.contains("Markdown实现示例"))
        XCTAssertTrue(plain.contains("HTML实现示例"))
        XCTAssertTrue(plain.contains("应用场景"))
    }
}
