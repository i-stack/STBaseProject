//
//  STMarkdownStructureParserASTContractTests.swift
//  STBaseProjectExampleTests
//
//  AST 级契约测试：钉住 STMarkdownStructureParser 的关键解析路径。
//  这些用例直接断言 STMarkdownDocument 的结构，不经渲染层，
//  目的是让 parser 行为的回归在 PR/CI 阶段就能被发现。
//

import XCTest
import STBaseProject

private extension STMarkdownDocument {
    /// 找到第一个匹配的块节点；找不到则 nil。
    func firstBlock(where predicate: (STMarkdownBlockNode) -> Bool) -> STMarkdownBlockNode? {
        self.blocks.first(where: predicate)
    }
}

final class STMarkdownStructureParserASTContractTests: XCTestCase {

    // MARK: - P0 #6: 段落内多占位符 + inline AST 保留

    func testExtractMathBlocks_preservesInlineAST_whenMixedWithStrong() {
        // 构造："看 **公式一** ${{ST_MATH_BLOCK:0}}$ 与 **公式二** ${{ST_MATH_BLOCK:1}}$ 结束"
        // 真实输入用 $$…$$ 写在独立行——STMarkdownMathNormalizer 会把它们替换为占位符并隔行；
        // 这里我们手动构造一个"占位符与 strong 在同一段落"的边界场景，验证 extractMathBlocks
        // 即使遇到这种病理结构也不丢 inline AST。
        // 走的是：先让 normalizer 产出占位符，然后利用 markdown 的 inline 语法把它们拼到同段。
        let parser = STMarkdownStructureParser()

        // 强制把两个块公式与 inline 强调拼到一段：去掉 $$ 前后的空行。
        let markdown = """
        看 **公式一**
        $$
        a = b
        $$
        与 **公式二**
        $$
        c = d
        $$
        结束
        """

        let doc = parser.parse(markdown)

        // 期望：mathBlock 块至少出现两次，并且 strong("公式一")/strong("公式二") 都被保留在
        // 周围段落里——而不是被扁平成 .text("公式一公式二")。
        var mathBlockCount = 0
        var strongTexts: [String] = []
        for block in doc.blocks {
            switch block {
            case .mathBlock(let latex):
                mathBlockCount += 1
                XCTAssertTrue(latex.contains("="), "math 块应保留 LaTeX 内容: \(latex)")
            case .paragraph(let inlines):
                self.collectStrongTexts(inlines, into: &strongTexts)
            default:
                break
            }
        }

        XCTAssertEqual(mathBlockCount, 2, "应识别两个块公式")
        XCTAssertTrue(strongTexts.contains("公式一"), "粗体『公式一』应被保留为 strong inline，而不是被扁平化")
        XCTAssertTrue(strongTexts.contains("公式二"), "粗体『公式二』应被保留为 strong inline，而不是被扁平化")
    }

    // MARK: - P0 #7: 占位符嵌套在 strong/emphasis 内 → 不可识别，走普通段落

    func testExtractMathBlocks_returnsNil_whenPlaceholderWrappedInStrong() {
        let parser = STMarkdownStructureParser()
        // 直接喂 swift-markdown 一段把占位符包进 ** 的字面文本——绕过 normalizer，确保
        // 占位符位于 strong 子节点，而不是顶层 Text。
        // 注意：normalizer 不会主动产出这种结构，这里是给 extractMathBlocks 一个"病理输入"
        // 验证它的兜底行为：应返回 nil，让段落走普通渲染——而不是悄悄丢掉外层 strong。
        let markdown = "前缀 **{{ST_MATH_BLOCK:0}}** 后缀"
        let doc = parser.parse(markdown)

        guard case .paragraph(let inlines)? = doc.blocks.first else {
            return XCTFail("期望首块为 paragraph，实际为 \(String(describing: doc.blocks.first))")
        }

        // 没有 mathBlock，因为 mathMap 里根本没有 0；段落必须保留 strong 结构。
        let strongCount = inlines.reduce(into: 0) { acc, node in
            if case .strong = node { acc += 1 }
        }
        XCTAssertEqual(strongCount, 1, "占位符被包进 strong 时不应丢掉外层 strong 结构")

        // 同时应该没有任何 mathBlock 块被提升出来。
        let hasMathBlock = doc.blocks.contains { if case .mathBlock = $0 { return true }; return false }
        XCTAssertFalse(hasMathBlock, "未匹配的占位符不应被升级为 mathBlock 块")
    }

    func testExtractMathBlocks_preservesLiteralPlaceholder_whenMathMapMissingAtTopLevel() {
        let parser = STMarkdownStructureParser()
        let markdown = "前缀 {{ST_MATH_BLOCK:999}} 后缀"
        let doc = parser.parse(markdown)

        guard case .paragraph(let inlines)? = doc.blocks.first else {
            return XCTFail("期望首块为 paragraph，实际为 \(String(describing: doc.blocks.first))")
        }

        let renderedText = self.flattenText(inlines)
        XCTAssertEqual(renderedText, markdown, "mathMap 缺失时，顶层占位符必须按字面文本保留，不能静默丢弃")

        let hasMathBlock = doc.blocks.contains { if case .mathBlock = $0 { return true }; return false }
        XCTAssertFalse(hasMathBlock, "mathMap 缺失时不应生成 mathBlock")
    }

    func testExtractMathBlocks_preservesTopLevelLiteralPlaceholdersAndAdjacentInlineAST_whenMathMapMissing() {
        let parser = STMarkdownStructureParser()
        let doc = parser.parse("前 **粗体** {{ST_MATH_BLOCK:0}} 与 *斜体* {{ST_MATH_BLOCK:1}} 后")

        XCTAssertEqual(doc.blocks.count, 1, "缺失 mathMap 时整段应保留为普通 paragraph")
        guard case .paragraph(let inlines)? = doc.blocks.first else {
            return XCTFail("期望缺失占位符场景保留为 paragraph，实际为 \(String(describing: doc.blocks.first))")
        }

        XCTAssertTrue(inlines.contains { if case .strong = $0 { return true }; return false }, "相邻 strong inline 不应被扁平化或丢失")
        XCTAssertTrue(inlines.contains { if case .emphasis = $0 { return true }; return false }, "相邻 emphasis inline 不应被扁平化或丢失")

        let text = self.flattenText(inlines)
        XCTAssertTrue(text.contains("{{ST_MATH_BLOCK:0}}"), "第一个缺失占位符应按字面保留")
        XCTAssertTrue(text.contains("{{ST_MATH_BLOCK:1}}"), "第二个缺失占位符应按字面保留")
    }

    // MARK: - P0 #17: Table columnAlignments — center / right / left

    func testTableColumnAlignments_center_right_left() {
        let parser = STMarkdownStructureParser()
        let doc = parser.parse(
            """
            | 左 | 中 | 右 |
            | :--- | :---: | ---: |
            | a | b | c |
            """
        )

        guard let table = doc.firstBlock(where: { if case .table = $0 { return true }; return false }),
              case .table(let model) = table else {
            return XCTFail("期望识别为表格")
        }

        XCTAssertEqual(model.columnAlignments.count, 3, "应解析三列对齐信息")
        XCTAssertEqual(model.columnAlignments[safe: 0], .left, "第 1 列 :--- 应为 left")
        XCTAssertEqual(model.columnAlignments[safe: 1], .center, "第 2 列 :---: 应为 center")
        XCTAssertEqual(model.columnAlignments[safe: 2], .right, "第 3 列 ---: 应为 right")
    }

    // MARK: - P1 #11: OrderedList.startIndex 非 1

    func testOrderedList_startIndex_nonOne() {
        let parser = STMarkdownStructureParser()
        let doc = parser.parse(
            """
            5. 第五
            6. 第六
            7. 第七
            """
        )

        guard let list = doc.firstBlock(where: { if case .list = $0 { return true }; return false }),
              case .list(let kind, let items) = list else {
            return XCTFail("期望识别为有序列表")
        }

        guard case .ordered(let startIndex) = kind else {
            return XCTFail("期望 ordered list，得到 \(kind)")
        }
        XCTAssertEqual(startIndex, 5, "ordered list 应保留 startIndex = 5")
        XCTAssertEqual(items.count, 3, "应识别 3 个列表项")
    }

    // MARK: - P1 #27: Link destination 归一化（`\/` → `/`）

    func testLinkDestination_normalizesEscapedSlash() {
        let parser = STMarkdownStructureParser()
        // 在 destination 中混入字面 `\/`，预期 normalizeLinkDestination 还原为 `/`。
        // Markdown 不会原生触发这种内容；它来自上游 JSON 转义未清理干净的 LLM 输出。
        let markdown = #"[官网](https:\/\/example.com\/path)"#
        let doc = parser.parse(markdown)

        guard case .paragraph(let inlines)? = doc.blocks.first else {
            return XCTFail("期望首块为 paragraph")
        }

        var foundDestination: String?
        for node in inlines {
            if case .link(let destination, _) = node {
                foundDestination = destination
                break
            }
        }

        guard let destination = foundDestination else {
            return XCTFail("应识别为 link inline")
        }
        XCTAssertFalse(destination.contains(#"\/"#), "link destination 不应保留字面 \\/")
        XCTAssertEqual(destination, "https://example.com/path", "link destination 应被归一化为 /")
    }

    // MARK: - P1 #21: `\[…\]` 块级数学

    func testBracketDisplayMath_isRecognizedAsMathBlock() {
        let parser = STMarkdownStructureParser()
        let doc = parser.parse(
            #"""
            前文

            \[
            x = y + 1
            \]

            后文
            """#
        )

        let mathBlocks = doc.blocks.compactMap { block -> String? in
            if case .mathBlock(let latex) = block { return latex }
            return nil
        }
        XCTAssertEqual(mathBlocks.count, 1, "应识别一个 \\[ \\] 块公式")
        XCTAssertTrue(
            mathBlocks.first?.contains("x = y + 1") ?? false,
            "块公式应保留 LaTeX 内容，实际：\(mathBlocks.first ?? "<nil>")"
        )
    }

    // MARK: - P1 #22: `\begin{align}` 环境块

    func testAlignEnvironmentBlock_isRecognizedAsMathBlock() {
        let parser = STMarkdownStructureParser()
        let doc = parser.parse(
            #"""
            前文

            \begin{align}
            a &= b \\
            c &= d
            \end{align}

            后文
            """#
        )

        let mathBlocks = doc.blocks.compactMap { block -> String? in
            if case .mathBlock(let latex) = block { return latex }
            return nil
        }
        XCTAssertEqual(mathBlocks.count, 1, "应识别一个 align 环境块")
        XCTAssertTrue(
            mathBlocks.first?.contains(#"\begin{align}"#) ?? false,
            "应保留 \\begin{align} 起始标记"
        )
        XCTAssertTrue(
            mathBlocks.first?.contains(#"\end{align}"#) ?? false,
            "应保留 \\end{align} 结束标记"
        )
    }

    // MARK: - P1 #4: 段落是纯图片 → 单独成 .image 块

    func testParagraphContainingOnlyImage_becomesImageBlock() {
        let parser = STMarkdownStructureParser()
        let doc = parser.parse("![示意](https://example.com/x.png)")

        guard let firstBlock = doc.blocks.first else {
            return XCTFail("应至少有一个块")
        }

        guard case .image(let url, let altText, _) = firstBlock else {
            return XCTFail("段落只含一张图片时应升级为 .image block，实际为 \(firstBlock)")
        }
        XCTAssertEqual(url, "https://example.com/x.png")
        XCTAssertEqual(altText, "示意")
    }

    // MARK: - P2 # 边界：parse("") → 空文档

    func testParse_emptyInput_returnsEmptyDocument() {
        let parser = STMarkdownStructureParser()
        let doc = parser.parse("")
        XCTAssertEqual(doc.blocks.count, 0, "空输入应返回空文档（短路）")
    }

    // MARK: - P2 #23: 行内公式 `\(…\)` 内容与 isDisplayMode 断言

    func testInlineMath_parenStyle_preservesContentAndIsNotDisplayMode() {
        let parser = STMarkdownStructureParser()
        let doc = parser.parse(#"前文 \(x+y\) 后文"#)

        guard case .paragraph(let inlines)? = doc.blocks.first else {
            return XCTFail("期望首块为 paragraph")
        }

        var formula: String?
        var displayMode: Bool?
        for node in inlines {
            if case .inlineMath(let f, let d) = node {
                formula = f
                displayMode = d
                break
            }
        }
        XCTAssertEqual(formula, "x+y", "行内公式应保留 LaTeX 内容（不含定界符）")
        XCTAssertEqual(displayMode, false, #"\(...\) 形式应为 isDisplayMode == false"#)
    }

    // MARK: - P2 #14: 列表项嵌套块（子列表 / 代码块 / 引用）

    func testListItem_withNestedSublistAndCodeBlock() {
        let parser = STMarkdownStructureParser()
        let doc = parser.parse(
            """
            - 父项一
                - 子项一
                - 子项二
            - 父项二

                ```swift
                let x = 1
                ```
            """
        )

        guard case .list(_, let items)? = doc.blocks.first else {
            return XCTFail("期望首块为 list")
        }
        XCTAssertEqual(items.count, 2, "应有两个父项")

        // 父项一：blocks 里应同时含 paragraph + 嵌套 list
        let firstItemBlocks = items[0].blocks
        let hasNestedList = firstItemBlocks.contains { if case .list = $0 { return true }; return false }
        XCTAssertTrue(hasNestedList, "父项一应包含嵌套的子列表块")

        // 父项二：应含 codeBlock 子块
        let secondItemBlocks = items[1].blocks
        let nestedCode = secondItemBlocks.first { if case .codeBlock = $0 { return true }; return false }
        guard let nestedCode, case .codeBlock(let lang, let code) = nestedCode else {
            return XCTFail("父项二应包含嵌套的 codeBlock 子块")
        }
        XCTAssertEqual(lang, "swift")
        XCTAssertTrue(code.contains("let x = 1"))
    }

    // MARK: - P2 #8: BlockQuote 嵌套（quote 里套 list 与 code）

    func testBlockQuote_withNestedListAndCode() {
        let parser = STMarkdownStructureParser()
        let doc = parser.parse(
            """
            > 引用首段
            >
            > - 引用列表项一
            > - 引用列表项二
            >
            > ```swift
            > let v = 1
            > ```
            """
        )

        guard case .quote(let inner)? = doc.blocks.first else {
            return XCTFail("期望首块为 quote")
        }

        let hasParagraph = inner.contains { if case .paragraph = $0 { return true }; return false }
        let hasList = inner.contains { if case .list = $0 { return true }; return false }
        let hasCode = inner.contains { if case .codeBlock = $0 { return true }; return false }
        XCTAssertTrue(hasParagraph, "quote 内应保留段落子块")
        XCTAssertTrue(hasList, "quote 内应保留 list 子块")
        XCTAssertTrue(hasCode, "quote 内应保留 codeBlock 子块")
    }

    // MARK: - P2 #29: SoftBreak（同一段落跨行）

    func testParagraph_withSoftBreakBetweenLines() {
        let parser = STMarkdownStructureParser()
        let doc = parser.parse(
            """
            第一行
            第二行
            """
        )

        guard case .paragraph(let inlines)? = doc.blocks.first else {
            return XCTFail("期望首块为 paragraph")
        }
        let softBreakCount = inlines.reduce(into: 0) { acc, node in
            if case .softBreak = node { acc += 1 }
        }
        XCTAssertEqual(softBreakCount, 1, "段落内同一段两行之间应有一个 softBreak")
    }

    // MARK: - P3 #2: Heading 4–6

    func testHeading_levelFourFiveSix() {
        let parser = STMarkdownStructureParser()
        let doc = parser.parse(
            """
            #### 四级
            ##### 五级
            ###### 六级
            """
        )
        let levels = doc.blocks.compactMap { block -> Int? in
            if case .heading(let level, _) = block { return level }
            return nil
        }
        XCTAssertEqual(levels, [4, 5, 6], "应识别 4/5/6 级标题")
    }

    // MARK: - P3 #10: 无 language 的围栏代码块

    func testCodeBlock_withoutLanguage_hasNilLanguage() {
        let parser = STMarkdownStructureParser()
        let doc = parser.parse(
            """
            ```
            plain code
            ```
            """
        )
        guard case .codeBlock(let language, let code)? = doc.blocks.first else {
            return XCTFail("期望首块为 codeBlock")
        }
        // swift-markdown 在没有标签时 language 为 nil 或空串；两种都接受。
        XCTAssertTrue(language == nil || language?.isEmpty == true, "无标签围栏的 language 应为 nil/空，实际：\(String(describing: language))")
        XCTAssertTrue(code.contains("plain code"))
    }

    // MARK: - P3 #28: Image inline 的 alt / source / title 完整断言

    func testInlineImage_preservesAltSourceAndTitle() {
        let parser = STMarkdownStructureParser()
        // 段落含其它 inline，强制 image 走 inline 分支而非"段落只含图片→升级 .image 块"。
        let doc = parser.parse(#"前文 ![替代](https://example.com/i.png "标题") 后文"#)

        guard case .paragraph(let inlines)? = doc.blocks.first else {
            return XCTFail("期望首块为 paragraph")
        }

        var foundSource: String?
        var foundAlt: String?
        var foundTitle: String?
        for node in inlines {
            if case .image(let source, let alt, let title) = node {
                foundSource = source
                foundAlt = alt
                foundTitle = title
                break
            }
        }
        XCTAssertEqual(foundSource, "https://example.com/i.png")
        XCTAssertEqual(foundAlt, "替代")
        XCTAssertEqual(foundTitle, "标题")
    }

    // MARK: - P3 #30: Strikethrough 子节点完整保留

    func testStrikethrough_preservesNestedTextContent() {
        let parser = STMarkdownStructureParser()
        let doc = parser.parse("前 ~~删除内容~~ 后")

        guard case .paragraph(let inlines)? = doc.blocks.first else {
            return XCTFail("期望首块为 paragraph")
        }

        var strikethroughText: String?
        for node in inlines {
            if case .strikethrough(let children) = node {
                strikethroughText = self.flattenText(children)
                break
            }
        }
        XCTAssertEqual(strikethroughText, "删除内容", "strikethrough 应保留内部文本")
    }

    // MARK: - 私有：递归收集 strong 内的纯文本（用于 P0 #6 的断言）

    private func collectStrongTexts(_ inlines: [STMarkdownInlineNode], into bucket: inout [String]) {
        for node in inlines {
            switch node {
            case .strong(let children):
                let text = self.flattenText(children)
                if text.isEmpty == false { bucket.append(text) }
                self.collectStrongTexts(children, into: &bucket)
            case .emphasis(let children),
                 .strikethrough(let children),
                 .link(_, let children):
                self.collectStrongTexts(children, into: &bucket)
            default:
                break
            }
        }
    }

    private func flattenText(_ inlines: [STMarkdownInlineNode]) -> String {
        var out = ""
        for node in inlines {
            switch node {
            case .text(let raw): out += raw
            case .strong(let c), .emphasis(let c), .strikethrough(let c):
                out += self.flattenText(c)
            case .link(_, let c):
                out += self.flattenText(c)
            default:
                break
            }
        }
        return out
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
