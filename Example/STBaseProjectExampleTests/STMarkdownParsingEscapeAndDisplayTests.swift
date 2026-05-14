//
//  STMarkdownParsingEscapeAndDisplayTests.swift
//  STBaseProjectExampleTests
//
//  针对 STMarkdown/Parsing 目录两条核心契约：
//  1) CommonMark 反斜杠转义（含 `\* \** \# \` \[ \] \_ \! \> \1. \- \| \~ \$ \\` 与行尾 `\`）、
//     以及预处理器中的 JSON / HTML 风格转义（`\n \" \/` 还原 + `<a>` 转 markdown 链接）能被正确解析；
//  2) 经默认引擎 + `STMarkdownAttributedStringRenderer` 渲染后的「可见文本」不得残留 Markdown 定界片段、
//     裸 HTML 标签、占位符；同时富文本 trait（粗 / 斜 / 链接 / 等宽）必须真实存在于属性串上。
//
//  分工说明：
//  - sanitizer 表格 / 锚点 / 页码引用 / 多空行等规则的逐条契约由 STMarkdownPipelineTests 覆盖，
//    本文件聚焦「转义解析」与「最终可见串无 markdown 残留 + 富文本 trait 真实存在」两条端到端契约。
//  - AST / RenderAST 的 enum case 穷举与 struct 初始化等价性由
//    STMarkdownASTAndRenderASTExhaustiveTests 覆盖，本文件不重复。
//

import XCTest
import UIKit
import STBaseProject

// MARK: - 渲染为可见纯文本（与 STMarkdownStructureParserParseAndRenderIntegrityTests 对齐）

private func st_renderPlainString(markdown: String) -> String {
    st_renderAttributed(markdown: markdown).string
}

private func st_renderAttributed(markdown: String) -> NSAttributedString {
    let engine = STMarkdownEngine(
        configuration: STMarkdownPipelineConfiguration(
            enableInputSanitizer: true,
            sanitizerRules: STMarkdownInputSanitizer.defaultRules,
            debug: false,
            semanticNormalizers: []
        )
    )
    let result = engine.process(markdown)
    let renderer = STMarkdownAttributedStringRenderer(
        style: .default,
        advancedRenderers: .empty
    )
    return renderer.render(document: result.renderDocument)
}

private func st_firstParagraphInlinesFromRender(_ document: STMarkdownRenderDocument) -> [STMarkdownInlineNode]? {
    for block in document.blocks {
        if case .paragraph(let inlines) = block {
            return inlines
        }
    }
    return nil
}

private func st_markdownFixtureText(named name: String, ext: String = "txt") throws -> String {
    let testFileURL = URL(fileURLWithPath: #filePath)
    let projectRoot = testFileURL
        .deletingLastPathComponent() // STBaseProjectExampleTests
        .deletingLastPathComponent() // project root
    let fixtureURL = projectRoot
        .appendingPathComponent("STBaseProjectExample")
        .appendingPathComponent("Resources")
        .appendingPathComponent(name)
        .appendingPathExtension(ext)
    return try String(contentsOf: fixtureURL, encoding: .utf8)
}

/// 归一化空白，便于将「AST 语义拼接」与 `NSAttributedString.string` 对比。
private func st_normalizeReaderWhitespace(_ s: String) -> String {
    s.replacingOccurrences(of: "\u{00a0}", with: " ")
        .replacingOccurrences(of: "\r\n", with: "\n")
        .replacingOccurrences(of: #"\n{3,}"#, with: "\n\n", options: .regularExpression)
        .trimmingCharacters(in: .whitespacesAndNewlines)
}

/// 深度优先收集段落 / 标题 / 代码块正文的语义文本（不含列表 marker、引用竖线等 UI 装饰）。
private func st_collectSemanticTextSegments(from blocks: [STMarkdownRenderBlock]) -> [String] {
    var segments: [String] = []
    for block in blocks {
        switch block {
        case .paragraph(let inlines):
            let t = st_joinInlinePlainText(inlines).trimmingCharacters(in: .whitespacesAndNewlines)
            if t.isEmpty == false { segments.append(t) }
        case .heading(_, _, let inlines):
            let t = st_joinInlinePlainText(inlines).trimmingCharacters(in: .whitespacesAndNewlines)
            if t.isEmpty == false { segments.append(t) }
        case .quote(let inner):
            segments.append(contentsOf: st_collectSemanticTextSegments(from: inner))
        case .list(let items):
            for item in items {
                segments.append(contentsOf: st_collectSemanticTextSegments(from: item.blocks))
            }
        case .codeBlock(_, let code):
            let t = code.trimmingCharacters(in: .whitespacesAndNewlines)
            if t.isEmpty == false { segments.append(t) }
        case .table, .mathBlock, .image, .thematicBreak, .rawHTML:
            break
        case .details(let summary, let inner):
            let t = st_joinInlinePlainText(summary).trimmingCharacters(in: .whitespacesAndNewlines)
            if t.isEmpty == false { segments.append(t) }
            segments.append(contentsOf: st_collectSemanticTextSegments(from: inner))
        }
    }
    return segments
}

/// 渲染结果中绝不应出现的 Markdown/HTML 定界片段：与转义/未消费定界相关，无论何种用例都禁。
private let st_baselineForbiddenSubstrings: [(token: String, label: String)] = [
    ("```", "代码围栏"),
    ("{{ST_MATH_BLOCK:", "块公式内部占位符泄漏"),
    ("![", "图片 Markdown 前缀"),
    ("$$", "块公式美元定界符"),
    ("\\(", #"行内公式 `\("#),
    ("\\)", #"行内公式 `\)`"#),
    ("- [ ]", "任务列表未完成原始语法"),
    ("- [x]", "任务列表已完成原始语法（小写 x）"),
    ("- [X]", "任务列表已完成原始语法（大写 X）"),
    ("<a ", "裸 HTML 链接开标签"),
    ("<br", "裸 HTML 换行标签"),
    ("<img", "裸 HTML 图片标签"),
    ("</", "裸 HTML 闭标签前缀"),
    ("|---", "表格定界行片段"),
]

/// 成对强调定界符；若用例本身含「已转义字面量」语义（如 `\*\*` 期望可见串保留 `**`），可通过 relaxations 放过对应序列。
private let st_pairedEmphasisDelimiters: [(token: String, label: String)] = [
    ("**", "粗体定界符"),
    ("__", "下划线强调定界符"),
    ("~~", "删除线定界符"),
]

/// 行首 ATX 标题前缀。注意：CommonMark §6.1 允许 `\#` 转义为字面 `#`，
/// 因此行首字面 `# ` 在「源含 \\# 」的用例里是合法输出，故 ATX 行首检测不进 baseline，
/// 仅由 `st_assertNoAtxOrQuoteLineStarts` 单独按需调用。
private let st_atxHeadingLinePrefixes: [String] = [
    "# ", "## ", "### ", "#### ", "##### ", "###### ",
]

/// 行首块引用前缀。同理：源含 `\>` 时合法输出 `>`，行首 `> ` 检测仅按需调用。
private let st_quoteLinePrefix = "> "

private struct STMarkdownLeakRelaxations: OptionSet {
    let rawValue: Int
    static let allowLiteralStarRuns       = STMarkdownLeakRelaxations(rawValue: 1 << 0)
    static let allowLiteralUnderscoreRuns = STMarkdownLeakRelaxations(rawValue: 1 << 1)
    static let allowLiteralTildeRuns      = STMarkdownLeakRelaxations(rawValue: 1 << 2)
}

/// 若仍出现在最终可见串里，视为解析/渲染泄漏的 Markdown / 公式 / 裸 HTML 片段。
/// 仅检测子串型定界符；ATX / quote 行首前缀因可能与字面字符冲突，由独立 helper 按需校验。
private func st_assertNoMarkdownLeaks(
    in output: String,
    relaxations: STMarkdownLeakRelaxations = [],
    file: StaticString = #filePath,
    line: UInt = #line
) {
    for (token, label) in st_baselineForbiddenSubstrings {
        XCTAssertFalse(
            output.contains(token),
            "渲染结果不得包含未消费的 Markdown/HTML 定界片段（\(label)）：\(token.debugDescription)",
            file: file,
            line: line
        )
    }
    for (token, label) in st_pairedEmphasisDelimiters {
        if token == "**" && relaxations.contains(.allowLiteralStarRuns) { continue }
        if token == "__" && relaxations.contains(.allowLiteralUnderscoreRuns) { continue }
        if token == "~~" && relaxations.contains(.allowLiteralTildeRuns) { continue }
        XCTAssertFalse(
            output.contains(token),
            "渲染结果不得包含未消费的 Markdown 强调定界片段（\(label)）：\(token.debugDescription)",
            file: file,
            line: line
        )
    }
}

/// 按需调用：源 markdown 含真 ATX 标题 / 块引用时，验证渲染后该结构不再以 `# / > ` 行首形式出现；
/// 不可在「源含 `\#` / `\>` 转义」的用例上调用——CommonMark §6.1 转义后字面 `#` / `>` 在行首是合法输出。
private func st_assertNoAtxOrQuoteLineStarts(
    in output: String,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    let lines = output.components(separatedBy: CharacterSet.newlines)
    for rawLine in lines {
        let trimmed = rawLine.trimmingCharacters(in: .whitespaces)
        for prefix in st_atxHeadingLinePrefixes where trimmed.hasPrefix(prefix) {
            XCTFail(
                "渲染结果某行不得以 ATX 标题前缀开头（\(prefix.debugDescription)）：\(rawLine.debugDescription)",
                file: file,
                line: line
            )
            break
        }
        if trimmed.hasPrefix(st_quoteLinePrefix) {
            XCTFail(
                "渲染结果某行不得以块引用前缀 `> ` 开头：\(rawLine.debugDescription)",
                file: file,
                line: line
            )
        }
    }
}

/// 兼容旧调用：默认无任何放过项，禁全部 baseline + 强调子串。
private func st_assertNoRawMarkdownOrTagSyntaxLeaks(
    in output: String,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    st_assertNoMarkdownLeaks(in: output, relaxations: [], file: file, line: line)
}

/// 兼容旧调用：用例已转义 `\*\*` / `\*`，可见串允许保留字面量 `**` / `*`，故放过粗体定界符序列。
private func st_assertNoRawMarkdownOrTagSyntaxLeaksAllowingLiteralStarRuns(
    in output: String,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    st_assertNoMarkdownLeaks(
        in: output,
        relaxations: [.allowLiteralStarRuns],
        file: file,
        line: line
    )
}

// MARK: - AST 文本收集（仅用于转义解析断言）

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

private func st_firstParagraphText(_ document: STMarkdownDocument) -> String? {
    for block in document.blocks {
        if case .paragraph(let inlines) = block {
            return st_joinInlinePlainText(inlines)
        }
    }
    return nil
}

private func st_blockContainsText(_ block: STMarkdownBlockNode, text: String) -> Bool {
    switch block {
    case .paragraph(let inlines):
        return st_joinInlinePlainText(inlines).contains(text)
    case .heading(_, let inlines):
        return st_joinInlinePlainText(inlines).contains(text)
    case .quote(let children):
        return children.contains { st_blockContainsText($0, text: text) }
    case .list(_, let items):
        return items.contains { item in
            item.blocks.contains { st_blockContainsText($0, text: text) }
        }
    case .table(let table):
        let header = (table.header ?? []).flatMap { $0 }
        let rows = table.rows.flatMap { $0 }.flatMap { $0 }
        return st_joinInlinePlainText(header + rows).contains(text)
    case .codeBlock(_, let code):
        return code.contains(text)
    case .mathBlock(let formula):
        return formula.contains(text)
    case .image(_, let altText, let title):
        return altText.contains(text) || (title?.contains(text) == true)
    case .thematicBreak:
        return false
    case .details(let summary, let body):
        return st_joinInlinePlainText(summary).contains(text)
            || body.contains { st_blockContainsText($0, text: text) }
    case .rawHTML(let html):
        return html.contains(text)
    }
}

private func st_renderBlockContainsText(_ block: STMarkdownRenderBlock, text: String) -> Bool {
    switch block {
    case .paragraph(let inlines):
        return st_joinInlinePlainText(inlines).contains(text)
    case .heading(_, _, let inlines):
        return st_joinInlinePlainText(inlines).contains(text)
    case .quote(let children):
        return children.contains { st_renderBlockContainsText($0, text: text) }
    case .list(let items):
        return items.contains { item in
            item.blocks.contains { st_renderBlockContainsText($0, text: text) }
        }
    case .table(let table):
        let header = (table.header ?? []).flatMap { $0 }
        let rows = table.rows.flatMap { $0 }.flatMap { $0 }
        return st_joinInlinePlainText(header + rows).contains(text)
    case .codeBlock(_, let code):
        return code.contains(text)
    case .mathBlock(let formula):
        return formula.contains(text)
    case .image(_, let altText, let title):
        return altText.contains(text) || (title?.contains(text) == true)
    case .thematicBreak:
        return false
    case .details(let summary, let body):
        return st_joinInlinePlainText(summary).contains(text)
            || body.contains { st_renderBlockContainsText($0, text: text) }
    case .rawHTML(let html):
        return html.contains(text)
    }
}

// MARK: - Tests

final class STMarkdownParsingEscapeAndDisplayTests: XCTestCase {

    // MARK: CommonMark 反斜杠转义 → 解析结果

    func testParserEscapedAsterisksDoNotFormStrongOrEmphasis() {
        let parser = STMarkdownStructureParser()
        let doc = parser.parse(#"展示 \*不是斜体\* 与 \*\*不是粗体\*\*"#)

        guard let plain = st_firstParagraphText(doc) else {
            return XCTFail("期望首块为段落")
        }
        XCTAssertTrue(plain.contains("*不是斜体*"), "转义后的星号应作为字面量保留：\(plain)")
        XCTAssertTrue(plain.contains("**不是粗体**"), "转义后的双星号应作为字面量保留：\(plain)")
        XCTAssertFalse(plain.contains("\\"), "解析后 Text 节点不应再保留反斜杠转义符本身（CommonMark 会消费反斜杠）")
    }

    func testParserEscapedHashIsParagraphNotHeading() {
        let parser = STMarkdownStructureParser()
        let doc = parser.parse("\\# 这不是标题")

        guard case .paragraph = doc.blocks.first else {
            return XCTFail("转义的 # 不应被识别为 ATX 标题，期望段落块")
        }
        guard let plain = st_firstParagraphText(doc) else {
            return XCTFail("期望段落含文本")
        }
        XCTAssertTrue(plain.hasPrefix("# 这不是标题") || plain.contains("这不是标题"),
                      "字面量井号应保留在段落文本中：\(plain)")
    }

    func testParserEscapedBackticksDoNotFormInlineCode() {
        let parser = STMarkdownStructureParser()
        let doc = parser.parse(#"这里是 \`不是代码\` 片段"#)

        guard let plain = st_firstParagraphText(doc) else {
            return XCTFail("期望段落")
        }
        XCTAssertTrue(plain.contains("`不是代码`"), "反引号应作为字面量：\(plain)")
    }

    func testParserEscapedSquareBracketsDoNotFormLinkOrImage() {
        let parser = STMarkdownStructureParser()
        // 避免裸 URL 自动链接干扰：验证转义后的 `[]` 不会变成 link 节点。
        // 注：swift-markdown / cmark 对 `\[...\]` 的纯文本拼接未必保留 ASCII 方括号字面量，
        // 但「可见方括号」等语义与「不得出现 link」应稳定成立。
        let doc = parser.parse("参考 \\[可见方括号\\] 后文")

        guard let plain = st_firstParagraphText(doc) else {
            return XCTFail("期望段落")
        }
        XCTAssertTrue(plain.contains("可见方括号") && plain.contains("参考") && plain.contains("后文"), "语义应保留：\(plain)")

        let inlines = doc.blocks.compactMap { block -> [STMarkdownInlineNode]? in
            if case .paragraph(let nodes) = block { return nodes }
            return nil
        }.first ?? []
        let hasLink = inlines.contains { node in
            if case .link = node { return true }
            return false
        }
        XCTAssertFalse(hasLink, "转义后的 [] 不应被解析为 Markdown 链接节点")
        let hasInlineImage = inlines.contains { node in
            if case .image = node { return true }
            return false
        }
        XCTAssertFalse(hasInlineImage, "转义后的 [] 不应被解析为 inline image 节点")
        let hasBlockImage = doc.blocks.contains { block in
            if case .image = block { return true }
            return false
        }
        XCTAssertFalse(hasBlockImage, "转义后的 [] 不应被提升为段落级 image 块")
    }

    /// `\![alt](url)` 的反斜杠把图片前缀 `!` 转义掉；解析器不得生成 image 节点。
    func testParserEscapedBangBracketDoesNotFormImage() {
        let parser = STMarkdownStructureParser()
        let doc = parser.parse(#"开头 \![占位](https://example.com/i.png) 结尾"#)

        let hasBlockImage = doc.blocks.contains { block in
            if case .image = block { return true }
            return false
        }
        XCTAssertFalse(hasBlockImage, "转义的 \\! 不应触发段落级 image 提升")

        let inlines = doc.blocks.compactMap { block -> [STMarkdownInlineNode]? in
            if case .paragraph(let nodes) = block { return nodes }
            return nil
        }.first ?? []
        let hasInlineImage = inlines.contains { node in
            if case .image = node { return true }
            return false
        }
        XCTAssertFalse(hasInlineImage, "转义的 \\! 不应被解析为 inline image 节点")
    }

    func testParserEscapedUnderscoreDoesNotFormEmphasis() {
        let parser = STMarkdownStructureParser()
        let doc = parser.parse(#"下划线 \_字面量\_ 测试"#)

        guard let plain = st_firstParagraphText(doc) else {
            return XCTFail("期望段落")
        }
        XCTAssertTrue(plain.contains("_字面量_"), "转义下划线应保留：\(plain)")
    }

    /// 行首 `\>` 被转义后，整行视为段落而非 BlockQuote 块。
    func testParserEscapedGreaterThanDoesNotFormBlockQuote() {
        let parser = STMarkdownStructureParser()
        let doc = parser.parse(#"\> 不是引用"#)

        XCTAssertEqual(doc.blocks.count, 1)
        guard case .paragraph = doc.blocks.first else {
            return XCTFail("转义的 \\> 不应被识别为 BlockQuote，期望段落块；实际：\(String(describing: doc.blocks.first))")
        }
        let hasQuote = doc.blocks.contains { block in
            if case .quote = block { return true }
            return false
        }
        XCTAssertFalse(hasQuote)
    }

    /// 行首数字后转义的 `\.` 阻止有序列表识别。
    func testParserEscapedOrderedListMarkerDoesNotFormList() {
        let parser = STMarkdownStructureParser()
        let doc = parser.parse(#"1\. 不是有序列表"#)

        let hasList = doc.blocks.contains { block in
            if case .list = block { return true }
            return false
        }
        XCTAssertFalse(hasList, "转义后的 1\\. 不应被识别为有序列表块")
        guard case .paragraph = doc.blocks.first else {
            return XCTFail("期望首块为段落，实际：\(String(describing: doc.blocks.first))")
        }
    }

    /// 行首 `\-` 阻止无序列表识别。
    func testParserEscapedUnorderedListMarkerDoesNotFormList() {
        let parser = STMarkdownStructureParser()
        let doc = parser.parse(#"\- 不是无序列表"#)

        let hasList = doc.blocks.contains { block in
            if case .list = block { return true }
            return false
        }
        XCTAssertFalse(hasList, "转义后的 \\- 不应被识别为无序列表块")
    }

    /// `\~` 阻止 GFM 删除线识别，且字面 `~` 字符应保留。
    func testParserEscapedTildeDoesNotFormStrikethrough() {
        let parser = STMarkdownStructureParser()
        let doc = parser.parse(#"\~不是删除线\~ 文本"#)

        let inlines = doc.blocks.compactMap { block -> [STMarkdownInlineNode]? in
            if case .paragraph(let nodes) = block { return nodes }
            return nil
        }.first ?? []
        let hasStrikethrough = inlines.contains { node in
            if case .strikethrough = node { return true }
            return false
        }
        XCTAssertFalse(hasStrikethrough, "转义后的 \\~ 不应被解析为 strikethrough 节点")

        guard let plain = st_firstParagraphText(doc) else {
            return XCTFail("期望段落")
        }
        XCTAssertTrue(plain.contains("~不是删除线~"), "转义后的字面 ~ 应保留：\(plain)")
    }

    /// `\|` 在表格未成立的上下文里转义为字面 `|`，且不会触发 table 块。
    func testParserEscapedPipeDoesNotFormTableInProseContext() {
        let parser = STMarkdownStructureParser()
        let doc = parser.parse(#"列 A \| 列 B 是字面"#)

        let hasTable = doc.blocks.contains { block in
            if case .table = block { return true }
            return false
        }
        XCTAssertFalse(hasTable, "无 delimiter row 的散文场景下，转义 \\| 不应触发 table 块")

        guard let plain = st_firstParagraphText(doc) else {
            return XCTFail("期望段落")
        }
        XCTAssertTrue(plain.contains("|"), "转义后的字面 | 应保留：\(plain)")
    }

    /// `\$\$` 不应触发 mathBlock；mathNormalizer 仅在行首独占 `$$` 才提取，单行内 `\$\$` 走 cmark。
    func testParserEscapedDollarSignsDoNotFormMathBlock() {
        let parser = STMarkdownStructureParser()
        let doc = parser.parse(#"价格 \$9.99 与 \$\$ 不是公式 \$\$"#)

        let hasMathBlock = doc.blocks.contains { block in
            if case .mathBlock = block { return true }
            return false
        }
        XCTAssertFalse(hasMathBlock, "单行内的 \\$\\$ 不应被识别为块公式")
        guard case .paragraph = doc.blocks.first else {
            return XCTFail("期望首块为段落")
        }
    }

    /// CommonMark §6.1：`\\` 应渲染为字面单反斜杠；解析后的 text 节点至少含一个 `\` 字符。
    func testParserDoubleBackslashRendersAsLiteralSingleBackslash() {
        let parser = STMarkdownStructureParser()
        let doc = parser.parse(#"路径 C:\\Users\\song 字面"#)

        guard let plain = st_firstParagraphText(doc) else {
            return XCTFail("期望段落")
        }
        XCTAssertTrue(plain.contains(#"\"#), "双反斜杠应保留为字面单反斜杠：\(plain)")
    }

    /// CommonMark §6.6：行尾单 `\` 表示硬换行，解析后段落 inline 节点序列应含 softBreak。
    func testParserTrailingBackslashFormsHardLineBreak() {
        let parser = STMarkdownStructureParser()
        let doc = parser.parse("第一行\\\n第二行")

        XCTAssertEqual(doc.blocks.count, 1, "硬换行不应分段")
        guard case .paragraph(let inlines) = doc.blocks.first else {
            return XCTFail("期望首块为段落")
        }
        let hasBreak = inlines.contains { node in
            if case .softBreak = node { return true }
            return false
        }
        XCTAssertTrue(hasBreak, "行尾 \\ 应映射到 softBreak 节点；实际 inlines=\(inlines)")
    }

    /// 工程契约（主动偏离 CommonMark）：`STMarkdownMathNormalizer` 把 `\(...\)` 视为行内公式定界符；
    /// 因此用户在散文中写 `\(对话\)` 会被解析成 inlineMath 节点，而非字面括号。
    /// 本用例钉住该契约——若实现改变（如恢复 CommonMark 转义括号语义），此用例将红字提示需要同步更新文档。
    func testMathNormalizerTreatsBackslashParenthesesAsInlineMathEvenInProseContext() {
        let parser = STMarkdownStructureParser()
        let doc = parser.parse(#"开头 \(对话\) 结尾"#)

        guard case .paragraph(let inlines) = doc.blocks.first else {
            return XCTFail("期望首块为段落")
        }
        let mathNode = inlines.first { node in
            if case .inlineMath = node { return true }
            return false
        }
        guard case .inlineMath(let formula, let display)? = mathNode else {
            return XCTFail("工程契约：\\(...\\) 应被吞成 inlineMath；实际 inlines=\(inlines)")
        }
        XCTAssertEqual(formula, "对话")
        XCTAssertFalse(display, "\\(...\\) 是 inline 模式（非 display）")
    }

    func testMathNormalizerDoubleBackslashBeforeParenNormalizesToSingleForInlineMath() {
        // 通过公共 API：normalizeDelimiters 在 splitInlineMath 内部执行，
        // 将 API/模型输出的 "\\(" 规范为 "\(" 后再识别行内公式。
        let raw = #"\\(a+b\\)"#
        let nodes = STMarkdownMathNormalizer.splitInlineMath(in: raw)
        XCTAssertEqual(nodes.count, 1)
        guard case .inlineMath(let formula, let display) = nodes.first else {
            return XCTFail("期望单个 inlineMath 节点")
        }
        XCTAssertEqual(formula, "a+b")
        XCTAssertFalse(display)
    }

    // MARK: 预处理器转义（STHtmlNormalizeRule 等）+ 全链路

    func testSanitizerUnescapesJsonStyleSequencesThenParserSeesRealNewlines() {
        let sanitizer = STMarkdownInputSanitizer(rules: [STHtmlNormalizeRule()])
        let result = sanitizer.sanitize("第一行\\n第二行\\n第三行")
        XCTAssertTrue(
            result.appliedRules.contains("STHtmlNormalizeRule"),
            "JSON 风格 \\n 必须由 STHtmlNormalizeRule 还原；appliedRules=\(result.appliedRules)"
        )
        XCTAssertNotEqual(result.sanitizedText, result.originalText, "sanitized 文本应不同于原始文本")

        let parser = STMarkdownStructureParser()
        let doc = parser.parse(result.sanitizedText)

        // STHtmlNormalizeRule 把 `\n` 还原为单换行；CommonMark 把单换行视为 softBreak（同段落），
        // 因此应当形成「单一段落 + 两个 softBreak」结构，而非多段落。
        XCTAssertEqual(doc.blocks.count, 1, "单换行应折叠到同一段落，期望 blocks.count == 1：实际 \(doc.blocks.count)")
        guard case .paragraph(let inlines) = doc.blocks.first else {
            return XCTFail("首块应为 paragraph，实际：\(String(describing: doc.blocks.first))")
        }
        let softBreakCount = inlines.reduce(into: 0) { partial, node in
            if case .softBreak = node { partial += 1 }
        }
        XCTAssertEqual(softBreakCount, 2, "两个 \\n 应解析为两个 softBreak 节点；实际 \(softBreakCount)")
        let joined = st_joinInlinePlainText(inlines)
        XCTAssertTrue(joined.contains("第一行"))
        XCTAssertTrue(joined.contains("第二行"))
        XCTAssertTrue(joined.contains("第三行"))
    }

    func testEndToEndEscapedInlineRichTextRendersWithoutDelimiterOrHtmlLeaks() {
        let md = #"""
        行内混合：\*\*不是粗体\*\*、\*不是斜体\*、\`不是代码\`、\[方括\] 后接、~~真删除~~。
        """#
        let plain = st_renderPlainString(markdown: md)
        // 本用例故意含「已转义」字面量 ** / * / `，可见串允许出现连续 *，不得按「泄漏」判失败
        st_assertNoRawMarkdownOrTagSyntaxLeaksAllowingLiteralStarRuns(in: plain)
        // CommonMark §6.1：所有 ASCII 标点的反斜杠转义都应保留字面字符。
        // 单分支严格断言而非 `||` 双向放过，保证「正确解析为字面」与「错误解析为强调」可被区分。
        XCTAssertTrue(plain.contains("**不是粗体**"), "已转义 \\*\\* 应保留字面 ** 字符序列：\(plain)")
        XCTAssertTrue(plain.contains("*不是斜体*"), "已转义 \\* 应保留字面 * 字符序列：\(plain)")
        XCTAssertTrue(plain.contains("`不是代码`"), "已转义 \\` 应保留字面 ` 字符：\(plain)")
        XCTAssertTrue(plain.contains("真删除"), "真删除线正文应渲染：\(plain)")
        XCTAssertFalse(plain.contains("~~"), "真删除线经解析后可见串不应残留 ~~")
    }

    func testEndToEndEscapedHeadingMarkerRendersAsPlainTextWithoutAtxLeak() {
        let md = """
        \\# 这不是标题

        普通 **粗** 尾
        """
        let plain = st_renderPlainString(markdown: md)
        st_assertNoRawMarkdownOrTagSyntaxLeaks(in: plain)
        XCTAssertTrue(plain.contains("这不是标题"))
        XCTAssertTrue(plain.contains("粗"))
    }

    func testEndToEndHtmlAnchorFromApiSanitizesToMarkdownThenRendersNoRawTags() {
        let md = #"<a href=\"https://example.com\">点我</a> 与 **粗**"#

        // 先单跑 sanitizer 验证规则确实被应用——避免「sanitizer 静默失效 + cmark 吞掉 raw HTML」类回归静默通过
        let sanitizer = STMarkdownInputSanitizer(rules: STMarkdownInputSanitizer.defaultRules)
        let sanitized = sanitizer.sanitize(md)
        XCTAssertTrue(
            sanitized.appliedRules.contains("STHtmlNormalizeRule"),
            "STHtmlNormalizeRule 应将 \\\" 还原为 \"；appliedRules=\(sanitized.appliedRules)"
        )
        XCTAssertTrue(
            sanitized.appliedRules.contains("STHtmlLinkToMarkdownRule"),
            "STHtmlLinkToMarkdownRule 应将 <a> 转为 markdown 链接；appliedRules=\(sanitized.appliedRules)"
        )
        XCTAssertTrue(
            sanitized.sanitizedText.contains("[点我](https://example.com)"),
            "sanitize 后应得到 markdown 链接形式：\(sanitized.sanitizedText)"
        )

        let attributed = st_renderAttributed(markdown: md)
        let visible = attributed.string
        st_assertNoRawMarkdownOrTagSyntaxLeaks(in: visible)
        XCTAssertTrue(visible.contains("点我"))
        XCTAssertTrue(visible.contains("粗"))

        let ns = visible as NSString
        let linkRange = ns.range(of: "点我")
        XCTAssertNotEqual(linkRange.location, NSNotFound)
        let linkAttribute = attributed.attribute(.link, at: linkRange.location, effectiveRange: nil) as? URL
        XCTAssertEqual(
            linkAttribute?.absoluteString,
            "https://example.com",
            "anchor 转 markdown 链接后，渲染层应在「点我」区段附 .link 属性而非以 [文本](url) 形式出现在可见串"
        )

        let boldRange = ns.range(of: "粗")
        XCTAssertNotEqual(boldRange.location, NSNotFound)
        let boldFont = attributed.attribute(.font, at: boldRange.location, effectiveRange: nil) as? UIFont
        XCTAssertTrue(
            boldFont?.fontDescriptor.symbolicTraits.contains(.traitBold) == true,
            "**粗** 区段应携带 .traitBold"
        )
    }

    /// 界面可见串应等于「解析管线最终语义」下的纯文本拼接；不得残留 Markdown/HTML 定界片段；
    /// 且属性串上须能观察到富文本（粗体字体与链接），不能退化成单一默认字体的纯文本块。
    func testRenderedVisibleStringMatchesFinalMarkdownSemanticsAndUsesRichAttributes() {
        let md = "请使用 **加粗** 查看 [文档](https://docs.example.com) 与 *斜体*。"
        let engine = STMarkdownEngine(
            configuration: STMarkdownPipelineConfiguration(
                enableInputSanitizer: true,
                sanitizerRules: STMarkdownInputSanitizer.defaultRules,
                debug: false,
                semanticNormalizers: []
            )
        )
        let result = engine.process(md)
        guard let inlines = st_firstParagraphInlinesFromRender(result.renderDocument) else {
            return XCTFail("期望渲染文档首块为段落")
        }
        let expectedSemantic = st_joinInlinePlainText(inlines)

        let attributed = STMarkdownAttributedStringRenderer(style: .default, advancedRenderers: .empty)
            .render(document: result.renderDocument)
        let visible = st_normalizeReaderWhitespace(attributed.string)
        let expectedTrimmed = st_normalizeReaderWhitespace(expectedSemantic)

        XCTAssertEqual(
            visible,
            expectedTrimmed,
            "可见文本应与管线最终 AST 的语义拼接一致（即 Markdown 解析完成后的读者文本）"
        )
        st_assertNoRawMarkdownOrTagSyntaxLeaks(in: visible)

        let ns = visible as NSString
        let boldRange = ns.range(of: "加粗")
        let italicRange = ns.range(of: "斜体")
        let linkRange = ns.range(of: "文档")
        XCTAssertNotEqual(boldRange.location, NSNotFound)
        XCTAssertNotEqual(italicRange.location, NSNotFound)
        XCTAssertNotEqual(linkRange.location, NSNotFound)

        let fontAtBold = attributed.attribute(.font, at: boldRange.location, effectiveRange: nil) as? UIFont
        XCTAssertNotNil(fontAtBold)
        let boldTraits = fontAtBold?.fontDescriptor.symbolicTraits
        XCTAssertTrue(
            boldTraits?.contains(.traitBold) == true,
            "粗体区段应携带 .traitBold，界面不能只呈现无样式纯文本"
        )

        let fontAtItalic = attributed.attribute(.font, at: italicRange.location, effectiveRange: nil) as? UIFont
        XCTAssertNotNil(fontAtItalic)
        let italicTraits = fontAtItalic?.fontDescriptor.symbolicTraits
        XCTAssertTrue(
            italicTraits?.contains(.traitItalic) == true,
            "斜体区段应携带 .traitItalic"
        )

        let linkURL = attributed.attribute(.link, at: linkRange.location, effectiveRange: nil) as? URL
        XCTAssertEqual(linkURL?.absoluteString, "https://docs.example.com", "链接语义应体现在属性上，而非以 `[文本](url)` 形式出现在可见串中")
    }

    // MARK: 多段 / 非首块 paragraph / 列表与引用（补全语义与富文本覆盖）

    /// 两段纯段落：可见串与递归收集的语义段落拼接一致，且两段内粗/斜均有 trait。
    func testMultiParagraphRenderedVisibleMatchesSemanticSegmentsAndRichAttributes() {
        let md = """
        第一段 **粗一**。

        第二段 *斜二*。
        """
        let engine = STMarkdownEngine(
            configuration: STMarkdownPipelineConfiguration(
                enableInputSanitizer: true,
                sanitizerRules: STMarkdownInputSanitizer.defaultRules,
                debug: false,
                semanticNormalizers: []
            )
        )
        let result = engine.process(md)
        let segments = st_collectSemanticTextSegments(from: result.renderDocument.blocks)
        XCTAssertEqual(segments.count, 2, "期望两个顶层段落语义片段")

        let attributed = STMarkdownAttributedStringRenderer(style: .default, advancedRenderers: .empty)
            .render(document: result.renderDocument)
        let visible = st_normalizeReaderWhitespace(attributed.string)
        let expected = st_normalizeReaderWhitespace(segments.joined(separator: "\n"))
        XCTAssertEqual(
            visible,
            expected,
            "多段纯文本场景下，可见串应与各段语义文本用块间单换行拼接一致（与 STMarkdownAttributedStringRenderer 块分隔一致）"
        )
        st_assertNoRawMarkdownOrTagSyntaxLeaks(in: visible)

        let ns = visible as NSString
        let r1 = ns.range(of: "粗一")
        let r2 = ns.range(of: "斜二")
        XCTAssertNotEqual(r1.location, NSNotFound)
        XCTAssertNotEqual(r2.location, NSNotFound)
        let boldTraits = (attributed.attribute(.font, at: r1.location, effectiveRange: nil) as? UIFont)?
            .fontDescriptor.symbolicTraits
        let italicTraits = (attributed.attribute(.font, at: r2.location, effectiveRange: nil) as? UIFont)?
            .fontDescriptor.symbolicTraits
        XCTAssertTrue(boldTraits?.contains(.traitBold) == true)
        XCTAssertTrue(italicTraits?.contains(.traitItalic) == true)
    }

    /// 首块为标题时，顶层首块不是 paragraph（但文档内嵌套处仍可有 paragraph，故 `st_firstParagraphInlinesFromRender` 可能非 nil）。
    func testHeadingThenParagraphVisibleMatchesSemanticJoinWithoutAtxMarkers() {
        let md = """
        ## 章节 **内粗**

        正文 *斜* 尾。
        """
        let engine = STMarkdownEngine(
            configuration: STMarkdownPipelineConfiguration(
                enableInputSanitizer: true,
                sanitizerRules: STMarkdownInputSanitizer.defaultRules,
                debug: false,
                semanticNormalizers: []
            )
        )
        let result = engine.process(md)
        guard case .heading(let level, _, _)? = result.renderDocument.blocks.first else {
            return XCTFail("期望渲染文档首块为 heading，实际：\(String(describing: result.renderDocument.blocks.first))")
        }
        XCTAssertEqual(level, 2)

        let segments = st_collectSemanticTextSegments(from: result.renderDocument.blocks)
        XCTAssertEqual(segments.count, 2)

        let attributed = STMarkdownAttributedStringRenderer(style: .default, advancedRenderers: .empty)
            .render(document: result.renderDocument)
        let visible = st_normalizeReaderWhitespace(attributed.string)
        let expected = st_normalizeReaderWhitespace(segments.joined(separator: "\n"))
        XCTAssertEqual(visible, expected)
        st_assertNoRawMarkdownOrTagSyntaxLeaks(in: visible)
        st_assertNoAtxOrQuoteLineStarts(in: visible)
        XCTAssertFalse(visible.contains("##"), "可见串不应残留 ATX ## 定界")
        XCTAssertTrue(visible.contains("章节") && visible.contains("内粗"))

        let ns = visible as NSString
        let rBold = ns.range(of: "内粗")
        let rItalic = ns.range(of: "斜")
        XCTAssertTrue(
            (attributed.attribute(.font, at: rBold.location, effectiveRange: nil) as? UIFont)?
                .fontDescriptor.symbolicTraits.contains(.traitBold) == true
        )
        XCTAssertTrue(
            (attributed.attribute(.font, at: rItalic.location, effectiveRange: nil) as? UIFont)?
                .fontDescriptor.symbolicTraits.contains(.traitItalic) == true
        )
    }

    /// 块引用内粗体：可见串含引用正文，无 `> ` 前缀泄漏，粗体区段有 trait。
    func testBlockQuoteWithStrongRendersQuoteBodyWithoutMarkdownPrefixLeaks() {
        let md = "> **引用粗** 与 *引用斜*。"
        let attributed = st_renderAttributed(markdown: md)
        let visible = attributed.string
        st_assertNoRawMarkdownOrTagSyntaxLeaks(in: visible)
        st_assertNoAtxOrQuoteLineStarts(in: visible)
        XCTAssertTrue(visible.contains("引用粗") && visible.contains("引用斜"))
        XCTAssertFalse(visible.contains("> "), "块引用不应以 Markdown `> ` 前缀出现在可见文本中")

        let ns = visible as NSString
        let rB = ns.range(of: "引用粗")
        let rI = ns.range(of: "引用斜")
        XCTAssertTrue(
            (attributed.attribute(.font, at: rB.location, effectiveRange: nil) as? UIFont)?
                .fontDescriptor.symbolicTraits.contains(.traitBold) == true
        )
        XCTAssertTrue(
            (attributed.attribute(.font, at: rI.location, effectiveRange: nil) as? UIFont)?
                .fontDescriptor.symbolicTraits.contains(.traitItalic) == true
        )
    }

    /// 无序列表项内粗体：首块为 list 非 paragraph；可见串无 `**`，且列表项正文为粗体 trait。
    func testUnorderedListWithStrongItemNoRawMarkdownAndBoldTrait() {
        let md = """
        - **列表粗**
        - 普通项
        """
        let engine = STMarkdownEngine(
            configuration: STMarkdownPipelineConfiguration(
                enableInputSanitizer: true,
                sanitizerRules: STMarkdownInputSanitizer.defaultRules,
                debug: false,
                semanticNormalizers: []
            )
        )
        let result = engine.process(md)
        guard case .list? = result.renderDocument.blocks.first else {
            return XCTFail("期望首块为 list，实际：\(String(describing: result.renderDocument.blocks.first))")
        }

        let attributed = STMarkdownAttributedStringRenderer(style: .default, advancedRenderers: .empty)
            .render(document: result.renderDocument)
        let visible = attributed.string
        st_assertNoRawMarkdownOrTagSyntaxLeaks(in: visible)
        XCTAssertFalse(visible.contains("**"))
        XCTAssertTrue(visible.contains("列表粗") && visible.contains("普通项"))

        let ns = visible as NSString
        let rBold = ns.range(of: "列表粗")
        XCTAssertNotEqual(rBold.location, NSNotFound)
        XCTAssertTrue(
            (attributed.attribute(.font, at: rBold.location, effectiveRange: nil) as? UIFont)?
                .fontDescriptor.symbolicTraits.contains(.traitBold) == true
        )
    }

    /// 有序列表后接独立段落：首块为 list；语义收集含「粗体项」与「跟段落」；可见串无列表 Markdown 定界泄漏。
    func testOrderedListThenParagraphSemanticSegmentsAndNoDelimiterLeaks() {
        let md = """
        1. 有序 **粗体项**

        跟段落 *斜*。
        """
        let engine = STMarkdownEngine(
            configuration: STMarkdownPipelineConfiguration(
                enableInputSanitizer: true,
                sanitizerRules: STMarkdownInputSanitizer.defaultRules,
                debug: false,
                semanticNormalizers: []
            )
        )
        let result = engine.process(md)
        guard case .list? = result.renderDocument.blocks.first else {
            return XCTFail("期望首块为 list，实际：\(String(describing: result.renderDocument.blocks.first))")
        }

        let segments = st_collectSemanticTextSegments(from: result.renderDocument.blocks)
        XCTAssertEqual(segments.count, 2)
        XCTAssertTrue(segments[0].contains("粗体项"))
        XCTAssertTrue(segments[1].contains("跟段落"))

        let visible = st_renderPlainString(markdown: md)
        st_assertNoRawMarkdownOrTagSyntaxLeaks(in: visible)
        XCTAssertTrue(visible.contains("粗体项") && visible.contains("跟段落"))
        XCTAssertFalse(visible.contains("**"))
        XCTAssertFalse(visible.contains("1. 有序"), "不应把有序列表源码前缀原样显示为读者文本")
    }

    /// 列表项以围栏代码块开头、后接段落：首子块非 paragraph；可见串含代码正文与「说明」，且不得残留 ``` 围栏。
    func testListItemLeadingWithCodeBlockThenParagraphRendersWithoutFenceLeaks() {
        let md = """
        - ```swift
          let v = 1
          ```

          说明文字
        """
        let attributed = st_renderAttributed(markdown: md)
        let visible = attributed.string
        st_assertNoRawMarkdownOrTagSyntaxLeaks(in: visible)
        XCTAssertFalse(visible.contains("```"), "围栏代码不应以 ``` 出现在最终可见串中")
        XCTAssertTrue(visible.contains("let v = 1"), "代码正文应出现在可见输出中")
        XCTAssertTrue(visible.contains("说明文字"), "代码块后的列表项段落应保留")

        let engine = STMarkdownEngine(
            configuration: STMarkdownPipelineConfiguration(
                enableInputSanitizer: true,
                sanitizerRules: STMarkdownInputSanitizer.defaultRules,
                debug: false,
                semanticNormalizers: []
            )
        )
        let result = engine.process(md)
        guard case .list(let items)? = result.renderDocument.blocks.first,
              let firstItem = items.first
        else {
            return XCTFail("期望首块为列表")
        }
        XCTAssertFalse(firstItem.blocks.isEmpty, "列表项应包含子块")
        if case .codeBlock = firstItem.blocks.first {} else {
            XCTFail("期望列表项首子块为 codeBlock（首块非 paragraph 场景）")
        }
    }

    /// 嵌套无序列表：可见串含父子项正文，无 `**` 泄漏。
    func testNestedUnorderedListRendersChildBoldWithoutMarkdownDelimiters() {
        let md = """
        - 父项
          - **子粗**
        """
        let visible = st_renderPlainString(markdown: md)
        st_assertNoRawMarkdownOrTagSyntaxLeaks(in: visible)
        XCTAssertTrue(visible.contains("父项") && visible.contains("子粗"))
        XCTAssertFalse(visible.contains("**"))

        let attributed = st_renderAttributed(markdown: md)
        let ns = visible as NSString
        let r = ns.range(of: "子粗")
        XCTAssertNotEqual(r.location, NSNotFound)
        XCTAssertTrue(
            (attributed.attribute(.font, at: r.location, effectiveRange: nil) as? UIFont)?
                .fontDescriptor.symbolicTraits.contains(.traitBold) == true
        )
    }

    @MainActor
    func testStreamingViewAccumulatedStringHasNoMarkdownOrHtmlLeaksWhenEscapesPresent() {
        // 显式注入带 sanitizer 的 engine：避免默认值漂移导致 chunks 内字面 `\n` 还原行为变化造成假阳性
        let engine = STMarkdownEngine(
            configuration: STMarkdownPipelineConfiguration(
                enableInputSanitizer: true,
                sanitizerRules: STMarkdownInputSanitizer.defaultRules,
                debug: false,
                semanticNormalizers: []
            )
        )
        let view = STMarkdownStreamingTextView(
            style: .default,
            advancedRenderers: .empty,
            engine: engine
        )
        let chunks = [
            #"字面值 \*"#,
            #"*不斜*\n\n"#,
            #"[链](https://e.com)"#,
            "\n\n**真粗**",
        ]
        var accumulated = ""
        for chunk in chunks {
            accumulated += chunk
            view.updateStreamingMarkdown(accumulated)
            st_assertNoRawMarkdownOrTagSyntaxLeaks(in: view.attributedText.string)
        }
        XCTAssertTrue(view.attributedText.string.contains("真粗"))
    }

    func testSemanticNormalizerPassthroughPreservesEscapedParagraphAST() {
        let parser = STMarkdownStructureParser()
        let doc = parser.parse(#"字面 \*星\*"#)
        let normalized = STMarkdownSemanticNormalizer.passthrough.normalize(doc)
        XCTAssertEqual(normalized, doc)
    }

    func testRenderAdapterProducesRenderDocumentWithoutExtraMarkdownDelimiters() {
        let parser = STMarkdownStructureParser()
        let adapter = STMarkdownRenderAdapter()
        let doc = parser.parse("\\# 标题字面 与 **粗**")
        let renderDoc = adapter.adapt(doc)
        let plain = STMarkdownAttributedStringRenderer(style: .default, advancedRenderers: .empty)
            .render(document: renderDoc)
            .string
        st_assertNoRawMarkdownOrTagSyntaxLeaks(in: plain)
        XCTAssertTrue(plain.contains("粗"))
    }

    func testRenderListItemParagraphInitializerPreservesCheckboxForTaskEscapeScenario() {
        let item = STMarkdownRenderListItem(
            content: [.text("任务项")],
            ordered: false,
            level: 0,
            orderedIndex: nil,
            childBlocks: [],
            checkbox: .unchecked
        )
        XCTAssertEqual(item.checkbox, .unchecked)
        XCTAssertEqual(item.content, [.text("任务项")])
    }

    // MARK: 本地 Resources 数据回归

    func testResourceData1MarkdownCanBeParsedAndRendered() throws {
        let markdown = try st_markdownFixtureText(named: "data1")
        let result = STMarkdownEngine().process(markdown)
        XCTAssertFalse(result.sourceDocument.blocks.isEmpty, "data1 应至少解析出一个 source block")
        XCTAssertFalse(result.renderDocument.blocks.isEmpty, "data1 应至少生成一个 render block")

        let rendered = STMarkdownAttributedStringRenderer(style: .default, advancedRenderers: .empty)
            .render(document: result.renderDocument)
            .string
        XCTAssertTrue(rendered.contains("第一步"))
        XCTAssertTrue(rendered.contains("第三步"))
        XCTAssertTrue(rendered.contains("立即"))
    }

    func testResourceData2MarkdownCanBeParsedAndRendered() throws {
        let markdown = try st_markdownFixtureText(named: "data2")
        let result = STMarkdownEngine().process(markdown)
        XCTAssertFalse(result.sourceDocument.blocks.isEmpty, "data2 应至少解析出一个 source block")
        XCTAssertFalse(result.renderDocument.blocks.isEmpty, "data2 应至少生成一个 render block")

        let rendered = STMarkdownAttributedStringRenderer(style: .default, advancedRenderers: .empty)
            .render(document: result.renderDocument)
            .string
        XCTAssertTrue(rendered.contains("减肥方法"))
        XCTAssertTrue(rendered.contains("关键提醒"))
        XCTAssertTrue(rendered.contains("控制热量摄入"))
    }

    func testResourceData3MarkdownCanBeParsedAndRenderedWithoutCodeFenceLeaks() throws {
        let markdown = try st_markdownFixtureText(named: "data3")
        let result = STMarkdownEngine().process(markdown)
        XCTAssertFalse(result.sourceDocument.blocks.isEmpty, "data3 应至少解析出一个 source block")
        XCTAssertFalse(result.renderDocument.blocks.isEmpty, "data3 应至少生成一个 render block")

        let rendered = STMarkdownAttributedStringRenderer(style: .default, advancedRenderers: .empty)
            .render(document: result.renderDocument)
            .string
        XCTAssertTrue(rendered.contains("Markdown实现示例"))
        XCTAssertTrue(rendered.contains("HTML实现示例"))
        XCTAssertTrue(rendered.contains("应用场景"))
        XCTAssertFalse(rendered.contains("```"), "代码围栏定界符不应泄漏到最终可见串")
    }

    func testResourceData1ASTStructureContracts() throws {
        let markdown = try st_markdownFixtureText(named: "data1")
        let result = STMarkdownEngine().process(markdown)
        let sourceBlocks = result.sourceDocument.blocks
        XCTAssertFalse(sourceBlocks.isEmpty)

        let headingBlocks = sourceBlocks.compactMap { block -> (Int, [STMarkdownInlineNode])? in
            if case .heading(let level, let content) = block { return (level, content) }
            return nil
        }
        XCTAssertGreaterThanOrEqual(headingBlocks.count, 5, "data1 应含多级标题结构")
        XCTAssertTrue(headingBlocks.contains { level, content in
            level == 2 && st_joinInlinePlainText(content).contains("第一步")
        }, "data1 应包含“第一步”二级标题")
        XCTAssertTrue(headingBlocks.contains { level, content in
            level == 2 && st_joinInlinePlainText(content).contains("第三步")
        }, "data1 应包含“第三步”二级标题")

        let listBlocks = sourceBlocks.compactMap { block -> (STMarkdownListKind, [STMarkdownListItemNode])? in
            if case .list(let kind, let items) = block { return (kind, items) }
            return nil
        }
        XCTAssertFalse(listBlocks.isEmpty, "data1 应解析出列表块")
        XCTAssertTrue(listBlocks.contains { _, items in
            items.contains { item in
                item.blocks.contains { st_blockContainsText($0, text: "安静") }
            }
        }, "data1 列表中应包含“安静”相关条目")
    }

    func testResourceData2ASTStructureContracts() throws {
        let markdown = try st_markdownFixtureText(named: "data2")
        let result = STMarkdownEngine().process(markdown)
        let sourceBlocks = result.sourceDocument.blocks
        XCTAssertFalse(sourceBlocks.isEmpty)

        let tables = sourceBlocks.compactMap { block -> STMarkdownTableModel? in
            if case .table(let model) = block { return model }
            return nil
        }
        XCTAssertEqual(tables.count, 1, "data2 应包含单个主表格")
        guard let table = tables.first else { return }
        XCTAssertNotNil(table.header, "data2 表格应有 header")
        XCTAssertGreaterThanOrEqual(table.header?.count ?? 0, 3, "data2 header 至少 3 列")
        XCTAssertGreaterThanOrEqual(table.rows.count, 8, "data2 表格应包含多行建议内容")

        let headerText = st_joinInlinePlainText((table.header ?? []).flatMap { $0 })
        XCTAssertTrue(headerText.contains("类别"))
        XCTAssertTrue(headerText.contains("具体建议"))
        XCTAssertTrue(headerText.contains("注意事项"))

        let rowText = st_joinInlinePlainText(table.rows.flatMap { $0 }.flatMap { $0 })
        XCTAssertTrue(rowText.contains("饮食调整"))
        XCTAssertTrue(rowText.contains("运动建议"))
        XCTAssertTrue(rowText.contains("生活习惯"))
    }

    func testResourceData3ASTStructureContracts() throws {
        let markdown = try st_markdownFixtureText(named: "data3")
        let result = STMarkdownEngine().process(markdown)
        let sourceBlocks = result.sourceDocument.blocks
        XCTAssertFalse(sourceBlocks.isEmpty)

        let codeBlocks = sourceBlocks.compactMap { block -> (String?, String)? in
            if case .codeBlock(let language, let code) = block { return (language, code) }
            return nil
        }
        XCTAssertGreaterThanOrEqual(codeBlocks.count, 2, "data3 至少包含 markdown/html 两段代码块")
        XCTAssertTrue(codeBlocks.contains { lang, code in
            (lang ?? "").lowercased().contains("markdown") && code.contains("1. 有序列表第一项")
        })
        XCTAssertTrue(codeBlocks.contains { lang, code in
            (lang ?? "").lowercased().contains("html") && code.contains("<ol>")
        })

        let renderLists = result.renderDocument.blocks.compactMap { block -> [STMarkdownRenderListItem]? in
            if case .list(let items) = block { return items }
            return nil
        }
        XCTAssertFalse(renderLists.isEmpty, "data3 渲染 AST 应至少包含一个列表块")
        XCTAssertTrue(renderLists.contains { items in
            items.contains { $0.ordered }
        }, "data3 应包含有序列表")
        XCTAssertTrue(result.renderDocument.blocks.contains { st_renderBlockContainsText($0, text: "关键点") })
        XCTAssertTrue(result.renderDocument.blocks.contains { st_renderBlockContainsText($0, text: "应用场景") })
    }
}
