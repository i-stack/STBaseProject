//
//  STMarkdownStructureParserParseAndRenderIntegrityTests.swift
//  STBaseProjectExampleTests
//
//  验证 STMarkdownStructureParser 对常见 Markdown 结构的识别，
//  以及经默认管线 + STMarkdownAttributedStringRenderer 渲染后的纯文本中
//  不得残留未解析的 Markdown 定界符（标签/语法糖）。
//

import XCTest
import STBaseProject

/// 默认引擎 + 默认属性串渲染器得到的可见字符串（不含 attribute 中的 URL）。
private func st_renderPlainString(markdown: String) -> String {
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
    return renderer.render(document: result.renderDocument).string
}

/// 在「我们构造的样例」中，若仍出现在最终可见串里，可视为解析/渲染泄漏的定界片段。
private func st_assertNoRawMarkdownSyntaxLeaks(
    in output: String,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    let forbidden: [(String, String)] = [
        ("**", "粗体定界符"),
        ("__", "下划线强调定界符"),
        ("~~", "删除线定界符"),
        ("```", "代码围栏"),
        ("{{ST_MATH_BLOCK:", "块公式内部占位符泄漏"),
        ("![", "图片 Markdown 前缀"),
        ("$$", "块公式美元定界符"),
        ("\\(", #"行内公式 `\(`"#),
        ("\\)", #"行内公式 `\)`"#),
        ("- [ ]", "任务列表未完成原始语法"),
        ("- [x]", "任务列表已完成原始语法（小写 x）"),
        ("- [X]", "任务列表已完成原始语法（大写 X）"),
    ]
    for (token, label) in forbidden {
        XCTAssertFalse(
            output.contains(token),
            "渲染结果不得包含未消费的 Markdown/公式定界片段（\(label)）：\(token.debugDescription)",
            file: file,
            line: line
        )
    }
}

@MainActor
private func st_assertStreamingNoRawMarkdownSyntaxLeaks(
    chunks: [String],
    file: StaticString = #filePath,
    line: UInt = #line
) {
    let view = STMarkdownStreamingTextView()
    var accumulated = ""
    for chunk in chunks {
        accumulated += chunk
        view.updateStreamingMarkdown(accumulated)
        st_assertNoRawMarkdownSyntaxLeaks(
            in: view.attributedText.string,
            file: file,
            line: line
        )
    }
}

private func st_collectInlineKinds(_ nodes: [STMarkdownInlineNode]) -> Set<String> {
    var kinds = Set<String>()
    func walk(_ nodes: [STMarkdownInlineNode]) {
        for node in nodes {
            switch node {
            case .text:
                kinds.insert("text")
            case .inlineMath:
                kinds.insert("inlineMath")
            case .emphasis(let c):
                kinds.insert("emphasis")
                walk(c)
            case .strong(let c):
                kinds.insert("strong")
                walk(c)
            case .code:
                kinds.insert("code")
            case .link:
                kinds.insert("link")
            case .image:
                kinds.insert("image")
            case .softBreak:
                kinds.insert("softBreak")
            case .strikethrough(let c):
                kinds.insert("strikethrough")
                walk(c)
            }
        }
    }
    walk(nodes)
    return kinds
}

private func st_firstParagraphInlines(_ document: STMarkdownDocument) -> [STMarkdownInlineNode]? {
    for block in document.blocks {
        if case .paragraph(let inlines) = block {
            return inlines
        }
    }
    return nil
}

final class STMarkdownStructureParserParseAndRenderIntegrityTests: XCTestCase {

    // MARK: - 解析：结构是否被识别为 AST 节点（而非整段原文）

    func testParserRecognizesHeadingLevelsAndContent() {
        let parser = STMarkdownStructureParser()
        let doc = parser.parse(
            """
            # 一级
            ## 二级
            ### 三级
            """
        )
        XCTAssertEqual(doc.blocks.count, 3)
        guard case .heading(let l1, let c1) = doc.blocks[0],
              case .heading(let l2, let c2) = doc.blocks[1],
              case .heading(let l3, let c3) = doc.blocks[2]
        else {
            return XCTFail("期望三个 heading 块")
        }
        XCTAssertEqual(l1, 1)
        XCTAssertEqual(l2, 2)
        XCTAssertEqual(l3, 3)
        XCTAssertTrue(c1.contains { if case .text(let t) = $0 { return t.contains("一级") }; return false })
        XCTAssertTrue(c2.contains { if case .text(let t) = $0 { return t.contains("二级") }; return false })
        XCTAssertTrue(c3.contains { if case .text(let t) = $0 { return t.contains("三级") }; return false })
    }

    func testParserRecognizesInlineStrongEmphasisCodeLinkImageStrikeAndMath() {
        let parser = STMarkdownStructureParser()
        let doc = parser.parse(
            #"""
            行内 **粗体** *斜体* `代码` [链接](https://example.com) ![图](https://example.com/i.png) ~~删~~ 公式 \(x+y\)
            """#
        )
        guard let inlines = st_firstParagraphInlines(doc) else {
            return XCTFail("期望首块为段落")
        }
        let kinds = st_collectInlineKinds(inlines)
        XCTAssertTrue(kinds.contains("strong"), "应识别 ** 为 strong")
        XCTAssertTrue(kinds.contains("emphasis"), "应识别 * 为 emphasis")
        XCTAssertTrue(kinds.contains("code"), "应识别行内代码")
        XCTAssertTrue(kinds.contains("link"), "应识别链接")
        XCTAssertTrue(kinds.contains("image"), "应识别图片")
        XCTAssertTrue(kinds.contains("strikethrough"), "应识别删除线")
        XCTAssertTrue(kinds.contains("inlineMath"), "应识别行内公式")
    }

    func testParserRecognizesBlockQuoteFencedCodeTableThematicBreakAndDisplayMath() {
        let parser = STMarkdownStructureParser()
        let doc = parser.parse(
            """
            > 引用一行

            ```swift
            let a = 1
            ```

            | 列一 | 列二 |
            | --- | --- |
            | 甲 | 乙 |

            ---

            $$
            E = mc^2
            $$
            """
        )

        var sawQuote = false
        var sawCode = false
        var sawTable = false
        var sawBreak = false
        var sawMath = false

        for block in doc.blocks {
            switch block {
            case .quote(let inner):
                sawQuote = true
                XCTAssertFalse(inner.isEmpty)
            case .codeBlock(let lang, let code):
                sawCode = true
                XCTAssertEqual(lang, "swift")
                XCTAssertTrue(code.contains("let a"))
            case .table(let model):
                sawTable = true
                XCTAssertFalse(model.rows.isEmpty)
            case .thematicBreak:
                sawBreak = true
            case .mathBlock(let latex):
                sawMath = true
                XCTAssertTrue(latex.contains("E = mc^2"))
            default:
                break
            }
        }

        XCTAssertTrue(sawQuote, "应识别块引用")
        XCTAssertTrue(sawCode, "应识别围栏代码块")
        XCTAssertTrue(sawTable, "应识别 GFM 表格")
        XCTAssertTrue(sawBreak, "应识别主题分隔线")
        XCTAssertTrue(sawMath, "应识别块级公式（mathBlock）")
    }

    func testParserRecognizesOrderedUnorderedAndTaskLists() {
        let parser = STMarkdownStructureParser()
        let doc = parser.parse(
            """
            1. 有序一
            2. 有序二

            - 无序项

            - [x] 已完成
            - [ ] 未完成
            """
        )

        var orderedItems = 0
        var unorderedItems = 0
        var taskChecked = false
        var taskUnchecked = false

        for block in doc.blocks {
            guard case .list(let kind, let items) = block else { continue }
            switch kind {
            case .ordered:
                orderedItems += items.count
            case .unordered:
                unorderedItems += items.count
                for item in items {
                    if item.checkbox == .checked { taskChecked = true }
                    if item.checkbox == .unchecked { taskUnchecked = true }
                }
            }
        }

        XCTAssertEqual(orderedItems, 2, "有序列表两项")
        XCTAssertGreaterThanOrEqual(unorderedItems, 3, "无序 + 任务列表项")
        XCTAssertTrue(taskChecked, "应识别已完成任务项")
        XCTAssertTrue(taskUnchecked, "应识别未完成任务项")
    }

    // MARK: - 渲染：可见串中不得残留 Markdown 定界符

    func testRenderedOutputHasNoMarkdownDelimiterLeaks_inlineRichParagraph() {
        let md = #"""
        展示 **粗体**、*斜体*、`mono`、[点我](https://example.com)、![示意](https://example.com/x.png) 与 ~~旧文~~ 以及 \(a+b\)。
        """#
        let plain = st_renderPlainString(markdown: md)
        st_assertNoRawMarkdownSyntaxLeaks(in: plain)
        XCTAssertTrue(plain.contains("粗体"))
        XCTAssertTrue(plain.contains("斜体"))
        XCTAssertTrue(plain.contains("mono"))
        XCTAssertTrue(plain.contains("点我"))
        XCTAssertTrue(plain.contains("示意"))
        XCTAssertTrue(plain.contains("旧文"))
    }

    func testRenderedOutputHasNoMarkdownDelimiterLeaks_headingsAndBlockStructures() {
        let md = """
        # 标题一

        ## 标题二

        > 引用内容

        ```swift
        let v = 42
        ```

        | H1 | H2 |
        | --- | --- |
        | c1 | c2 |

        ---

        $$
        x^2
        $$
        """
        let plain = st_renderPlainString(markdown: md)
        st_assertNoRawMarkdownSyntaxLeaks(in: plain)
        XCTAssertTrue(plain.contains("标题一"))
        XCTAssertTrue(plain.contains("标题二"))
        XCTAssertTrue(plain.contains("引用内容"))
        XCTAssertTrue(plain.contains("let v = 42"))
        XCTAssertTrue(plain.contains("c1"))
        XCTAssertFalse(plain.contains("# "), "标题不应以 Markdown # 前缀出现在可见文本中")
        XCTAssertFalse(plain.contains("> "), "块引用不应以 `> ` 出现在可见文本中")
    }

    func testRenderedOutputHasNoMarkdownDelimiterLeaks_listsAndTasks() {
        let md = """
        1. 第一项
        2. 第二项

        - 圆点

        - [x] 做完
        - [ ] 待办
        """
        let plain = st_renderPlainString(markdown: md)
        st_assertNoRawMarkdownSyntaxLeaks(in: plain)
        XCTAssertTrue(plain.contains("第一项"))
        XCTAssertTrue(plain.contains("第二项"))
        XCTAssertTrue(plain.contains("圆点"))
        XCTAssertTrue(plain.contains("做完"))
        XCTAssertTrue(plain.contains("待办"))
    }

    func testRenderedOutputHasNoMarkdownDelimiterLeaks_nestedEmphasisAndLink() {
        let md = """
        外层 **粗里 *斜粗尾* 尾** [链](https://a.org/b)
        """
        let plain = st_renderPlainString(markdown: md)
        st_assertNoRawMarkdownSyntaxLeaks(in: plain)
        XCTAssertTrue(plain.contains("粗里"))
        XCTAssertTrue(plain.contains("斜粗尾"))
        XCTAssertTrue(plain.contains("链"))
    }

    // MARK: - 流式：每个中间态都不允许出现 Markdown 定界符

    @MainActor
    func testStreamingIntermediateStatesHaveNoMarkdownLeaks_strongAndEmphasis() {
        st_assertStreamingNoRawMarkdownSyntaxLeaks(
            chunks: [
                "展示 ",
                "**粗",
                "体**",
                " 与 *斜",
                "体* 结束"
            ]
        )
    }

    @MainActor
    func testStreamingIntermediateStatesHaveNoMarkdownLeaks_linkAndInlineCode() {
        st_assertStreamingNoRawMarkdownSyntaxLeaks(
            chunks: [
                "点击 ",
                "[链",
                "接](https://example.com)",
                " 与 `co",
                "de`"
            ]
        )
    }

    @MainActor
    func testStreamingIntermediateStatesHaveNoMarkdownLeaks_strikethroughAndTaskList() {
        st_assertStreamingNoRawMarkdownSyntaxLeaks(
            chunks: [
                "~~删",
                "除线~~\n\n",
                "- [x] 已",
                "完成\n",
                "- [ ] 待",
                "办"
            ]
        )
    }

    @MainActor
    func testStreamingIntermediateStatesHaveNoMarkdownLeaks_mathDelimiters() {
        st_assertStreamingNoRawMarkdownSyntaxLeaks(
            chunks: [
                "行内公式 ",
                #"\(x+"#,
                #"y\)"#,
                "\n\n",
                "$$",
                "\nE = mc^2\n",
                "$$"
            ]
        )
    }
}
