//
//  STMarkdownPipelineTests.swift
//  STBaseProjectTests
//
//  Created by 寒江孤影 on 2019/03/16.
//

import XCTest
@testable import STBaseProject

private struct MockCodeBlockRenderer: STMarkdownCodeBlockRendering {
    func renderCodeBlock(language: String?, code: String, style: STMarkdownStyle) -> NSAttributedString? {
        NSAttributedString(string: "[code:\(language ?? "plain")]\(code)")
    }
}

private struct MockInlineMathRenderer: STMarkdownInlineMathRendering {
    func renderInlineMath(formula: String, style: STMarkdownStyle, baseFont: UIFont, textColor: UIColor) -> NSAttributedString? {
        NSAttributedString(string: "[math:\(formula)]")
    }
}

private final class MockImageLoader: STMarkdownImageLoading {
    private(set) var lastURL: URL?

    func loadImage(from url: URL, completion: @escaping @Sendable (UIImage?) -> Void) {
        self.lastURL = url
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 24, height: 24))
        let image = renderer.image { context in
            UIColor.systemBlue.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 24, height: 24))
        }
        completion(image)
    }
}

final class STMarkdownPipelineTests: XCTestCase {

    func testInputSanitizerConvertsHtmlLinkToMarkdown() {
        let sanitizer = STMarkdownInputSanitizer(
            rules: [
                STHtmlNormalizeRule(),
                STHtmlLinkToMarkdownRule(),
            ]
        )

        let result = sanitizer.sanitize(#"<a href=\"https://example.com\">Example</a>"#)

        XCTAssertEqual(result.sanitizedText, "[Example](https://example.com)")
        XCTAssertTrue(result.appliedRules.contains("STHtmlLinkToMarkdownRule"))
    }

    func testStructureParserPreservesOrderedListStartIndex() {
        let parser = STMarkdownStructureParser()

        let document = parser.parse(
            """
            3. 第三项
            4. 第四项
            """
        )

        guard case .list(let kind, let items)? = document.blocks.first else {
            return XCTFail("Expected first block to be list")
        }

        guard case .ordered(let startIndex) = kind else {
            return XCTFail("Expected ordered list kind")
        }

        XCTAssertEqual(startIndex, 3)
        XCTAssertEqual(items.count, 2)
    }

    func testRenderAdapterFlattensOrderedListIndices() {
        let parser = STMarkdownStructureParser()
        let adapter = STMarkdownRenderAdapter()
        let document = parser.parse(
            """
            5. 第一项
            6. 第二项
            """
        )

        let renderDocument = adapter.adapt(document)

        guard case .list(let items)? = renderDocument.blocks.first else {
            return XCTFail("Expected first render block to be list")
        }

        XCTAssertEqual(items.map(\.orderedIndex), [5, 6])
        XCTAssertTrue(items.allSatisfy(\.ordered))
    }

    func testMarkdownEngineReturnsSourceAndRenderDocuments() {
        let engine = STMarkdownEngine()

        let result = engine.process("**标题**")

        XCTAssertFalse(result.sourceDocument.blocks.isEmpty)
        XCTAssertFalse(result.renderDocument.blocks.isEmpty)
        XCTAssertEqual(result.rawMarkdown, "**标题**")
    }

    func testSoftBreakCollapsingNormalizerRemovesAdjacentSoftBreaks() {
        let document = STMarkdownDocument(
            blocks: [
                .paragraph([
                    .text("A"),
                    .softBreak,
                    .softBreak,
                    .text("B"),
                ])
            ]
        )
        let normalizer = STMarkdownSoftBreakCollapsingNormalizer()

        let normalized = normalizer.normalize(document)

        guard case .paragraph(let inlines)? = normalized.blocks.first else {
            return XCTFail("Expected paragraph block")
        }
        XCTAssertEqual(inlines, [.text("A"), .softBreak, .text("B")])
    }

    func testAttributedStringRendererUsesDistinctBoldFontForStrongText() {
        let renderer = STMarkdownAttributedStringRenderer()
        let document = STMarkdownRenderDocument(
            blocks: [
                .paragraph([
                    .strong([.text("粗体")]),
                    .text(" 普通"),
                ])
            ]
        )

        let attributed = renderer.render(document: document)
        let strongFont = attributed.attribute(.font, at: 0, effectiveRange: nil) as? UIFont
        let normalFont = attributed.attribute(.font, at: attributed.length - 1, effectiveRange: nil) as? UIFont

        XCTAssertNotNil(strongFont)
        XCTAssertNotNil(normalFont)
        XCTAssertNotEqual(strongFont?.fontName, normalFont?.fontName)
    }

    func testAttributedStringRendererRendersOrderedListMarker() {
        let renderer = STMarkdownAttributedStringRenderer()
        let document = STMarkdownRenderDocument(
            blocks: [
                .list([
                    STMarkdownRenderListItem(
                        content: [.text("第一项")],
                        ordered: true,
                        level: 0,
                        orderedIndex: 3,
                        childBlocks: []
                    )
                ])
            ]
        )

        let attributed = renderer.render(document: document)

        XCTAssertTrue(attributed.string.hasPrefix("3.\t"))
        XCTAssertTrue(attributed.string.contains("第一项"))
    }

    func testMarkdownStreamingTextViewRendersMarkdown() {
        let view = STMarkdownStreamingTextView()

        view.setMarkdown("**标题**\n\n1. 第一项", animated: false)

        XCTAssertTrue(view.attributedText.string.contains("标题"))
        XCTAssertTrue(view.attributedText.string.contains("第一项"))
    }

    func testMarkdownStreamingTextViewReplacesTrailingRangeWhenRenderedPrefixMutates() {
        let view = STMarkdownStreamingTextView()

        view.setMarkdown("[链接](https://example.com", animated: false)
        view.updateStreamingMarkdown("[链接](https://example.com)")

        let range = (view.attributedText.string as NSString).range(of: "链接")
        let link = view.attributedText.attribute(.link, at: range.location, effectiveRange: nil) as? URL

        XCTAssertEqual(link?.absoluteString, "https://example.com")
    }

    func testMarkdownTextViewRendersMarkdown() {
        let view = STMarkdownTextView()

        view.setMarkdown("## 标题\n\n- 列表项")

        XCTAssertTrue(view.attributedText.string.contains("标题"))
        XCTAssertTrue(view.attributedText.string.contains("列表项"))
    }

    func testMarkdownTextViewResetClearsContent() {
        let view = STMarkdownTextView()
        view.setMarkdown("普通文本")

        view.reset()

        XCTAssertTrue(view.attributedText.string.isEmpty)
        XCTAssertTrue(view.rawMarkdown.isEmpty)
    }

    func testRenderAdapterPreservesNestedListLevel() {
        let parser = STMarkdownStructureParser()
        let adapter = STMarkdownRenderAdapter()
        let document = parser.parse(
            """
            1. 第一项
               - 子项
            """
        )

        let renderDocument = adapter.adapt(document)

        guard
            case .list(let items)? = renderDocument.blocks.first,
            case .list(let childItems)? = items.first?.childBlocks.first
        else {
            return XCTFail("Expected nested render list")
        }

        XCTAssertEqual(items.first?.level, 0)
        XCTAssertEqual(childItems.first?.level, 1)
    }

    func testAttributedStringRendererOffsetsLooseListParagraphIndent() {
        let renderer = STMarkdownAttributedStringRenderer()
        let document = STMarkdownRenderDocument(
            blocks: [
                .list([
                    STMarkdownRenderListItem(
                        blocks: [
                            .paragraph([.text("第一段")]),
                            .paragraph([.text("第二段")]),
                        ],
                        ordered: true,
                        level: 0,
                        orderedIndex: 1
                    )
                ])
            ]
        )

        let attributed = renderer.render(document: document)
        let secondParagraphLocation = (attributed.string as NSString).range(of: "第二段").location
        let paragraphStyle = attributed.attribute(.paragraphStyle, at: secondParagraphLocation, effectiveRange: nil) as? NSParagraphStyle

        XCTAssertNotNil(paragraphStyle)
        XCTAssertGreaterThan(paragraphStyle?.headIndent ?? 0, 0)
    }

    func testAttributedStringRendererUsesCustomCodeBlockRenderer() {
        let renderer = STMarkdownAttributedStringRenderer(
            advancedRenderers: STMarkdownAdvancedRenderers(
                codeBlockRenderer: MockCodeBlockRenderer()
            )
        )
        let document = STMarkdownRenderDocument(
            blocks: [
                .codeBlock(language: "swift", code: "print(1)")
            ]
        )

        let attributed = renderer.render(document: document)

        XCTAssertEqual(attributed.string, "[code:swift]print(1)")
    }

    func testAttributedStringRendererUsesCustomInlineMathRenderer() {
        let renderer = STMarkdownAttributedStringRenderer(
            advancedRenderers: STMarkdownAdvancedRenderers(
                inlineMathRenderer: MockInlineMathRenderer()
            )
        )
        let document = STMarkdownRenderDocument(
            blocks: [
                .paragraph([
                    .text("结果 "),
                    .inlineMath("x+y", isDisplayMode: false),
                ])
            ]
        )

        let attributed = renderer.render(document: document)

        XCTAssertTrue(attributed.string.contains("[math:x+y]"))
    }

    func testDefaultMathRendererRendersSuperscriptContent() {
        let renderer = STMarkdownAttributedStringRenderer(
            advancedRenderers: STMarkdownAdvancedRenderers(
                inlineMathRenderer: STMarkdownDefaultMathRenderer()
            )
        )
        let document = STMarkdownRenderDocument(
            blocks: [
                .paragraph([
                    .inlineMath("x^2", isDisplayMode: false)
                ])
            ]
        )

        let attributed = renderer.render(document: document)
        let baselineOffset = attributed.attribute(.baselineOffset, at: 1, effectiveRange: nil) as? CGFloat

        XCTAssertEqual(attributed.string, "x2")
        XCTAssertNotNil(baselineOffset)
        XCTAssertGreaterThan(baselineOffset ?? 0, 0)
    }

    func testStructureParserExtractsInlineMathNodes() {
        let parser = STMarkdownStructureParser()
        let document = parser.parse(#"结果是 \(x^2+y^2\)"#)

        guard case .paragraph(let inlines)? = document.blocks.first else {
            return XCTFail("Expected paragraph block")
        }

        XCTAssertTrue(inlines.contains { node in
            if case .inlineMath(let formula, _) = node {
                return formula == "x^2+y^2"
            }
            return false
        })
    }

    func testDefaultCodeBlockRendererIncludesLanguageHeader() {
        let renderer = STMarkdownAttributedStringRenderer(
            style: STMarkdownStyle.default,
            advancedRenderers: STMarkdownAdvancedRenderers(
                codeBlockRenderer: STMarkdownDefaultCodeBlockRenderer()
            )
        )
        let document = STMarkdownRenderDocument(
            blocks: [
                .codeBlock(language: "swift", code: "print(\"hi\")")
            ]
        )

        let attributed = renderer.render(document: document)

        XCTAssertTrue(attributed.string.hasPrefix("SWIFT\n"))
        XCTAssertTrue(attributed.string.contains("print(\"hi\")"))
    }

    func testDefaultCodeBlockRendererUsesMonospacedFont() {
        let renderer = STMarkdownAttributedStringRenderer(
            style: STMarkdownStyle.default,
            advancedRenderers: STMarkdownAdvancedRenderers(
                codeBlockRenderer: STMarkdownDefaultCodeBlockRenderer()
            )
        )
        let document = STMarkdownRenderDocument(
            blocks: [
                .codeBlock(language: nil, code: "let value = 1")
            ]
        )

        let attributed = renderer.render(document: document)
        let font = attributed.attribute(.font, at: 0, effectiveRange: nil) as? UIFont

        XCTAssertNotNil(font)
        XCTAssertTrue(font?.fontName.lowercased().contains("mono") == true)
    }

    func testDefaultTableRendererRendersHeaderAndSeparator() {
        let renderer = STMarkdownAttributedStringRenderer(
            style: STMarkdownStyle.default,
            advancedRenderers: STMarkdownAdvancedRenderers(
                tableRenderer: STMarkdownDefaultTableRenderer()
            )
        )
        let document = STMarkdownRenderDocument(
            blocks: [
                .table(
                    STMarkdownTableModel(
                        header: [
                            [.text("名称")],
                            [.text("值")],
                        ],
                        rows: [
                            [
                                [.text("速度")],
                                [.text("快")],
                            ]
                        ]
                    )
                )
            ]
        )

        let attributed = renderer.render(document: document)

        XCTAssertTrue(attributed.string.contains("名称"))
        XCTAssertTrue(attributed.string.contains("值"))
        XCTAssertTrue(attributed.string.contains("┼"))
        XCTAssertTrue(attributed.string.contains("速度"))
    }

    func testDefaultTableRendererUsesMonospacedFont() {
        let renderer = STMarkdownAttributedStringRenderer(
            style: STMarkdownStyle.default,
            advancedRenderers: STMarkdownAdvancedRenderers(
                tableRenderer: STMarkdownDefaultTableRenderer()
            )
        )
        let document = STMarkdownRenderDocument(
            blocks: [
                .table(
                    STMarkdownTableModel(
                        header: nil,
                        rows: [
                            [
                                [.text("A")],
                                [.text("B")],
                            ]
                        ]
                    )
                )
            ]
        )

        let attributed = renderer.render(document: document)
        let font = attributed.attribute(.font, at: 0, effectiveRange: nil) as? UIFont

        XCTAssertNotNil(font)
        XCTAssertTrue(font?.fontName.lowercased().contains("mono") == true)
    }

    func testDefaultImageRendererUsesAltTextForInlineImage() {
        let renderer = STMarkdownAttributedStringRenderer(
            style: STMarkdownStyle.default,
            advancedRenderers: STMarkdownAdvancedRenderers(
                imageRenderer: STMarkdownDefaultImageRenderer()
            )
        )
        let document = STMarkdownRenderDocument(
            blocks: [
                .paragraph([
                    .image(source: "https://example.com/a.png", alt: "示意图", title: nil)
                ])
            ]
        )

        let attributed = renderer.render(document: document)

        XCTAssertTrue(attributed.string.contains("示意图"))
    }

    func testDefaultImageRendererRendersBlockCaption() {
        let renderer = STMarkdownAttributedStringRenderer(
            style: STMarkdownStyle.default,
            advancedRenderers: STMarkdownAdvancedRenderers(
                imageRenderer: STMarkdownDefaultImageRenderer()
            )
        )
        let document = STMarkdownRenderDocument(
            blocks: [
                .image(url: "https://example.com/a.png", altText: "", title: "图片说明")
            ]
        )

        let attributed = renderer.render(document: document)

        XCTAssertTrue(attributed.string.contains("[image] a.png"))
        XCTAssertTrue(attributed.string.contains("图片说明"))
    }

    func testDefaultHorizontalRuleRendererUsesConfiguredLength() {
        let style = STMarkdownStyle(
            font: .systemFont(ofSize: 16, weight: .regular),
            textColor: .label,
            lineHeight: 24,
            kern: 0.12,
            horizontalRuleLength: 10
        )
        let renderer = STMarkdownAttributedStringRenderer(
            style: style,
            advancedRenderers: STMarkdownAdvancedRenderers(
                horizontalRuleRenderer: STMarkdownDefaultHorizontalRuleRenderer()
            )
        )
        let document = STMarkdownRenderDocument(blocks: [.thematicBreak])

        let attributed = renderer.render(document: document)

        XCTAssertEqual(attributed.string, String(repeating: "─", count: 12))
    }

    func testCodeBlockAttachmentRendererProducesAttachment() {
        let renderer = STMarkdownAttributedStringRenderer(
            style: STMarkdownStyle.default,
            advancedRenderers: STMarkdownAdvancedRenderers(
                codeBlockRenderer: STMarkdownCodeBlockAttachmentRenderer()
            )
        )
        let document = STMarkdownRenderDocument(
            blocks: [
                .codeBlock(language: "swift", code: "print(\"hi\")")
            ]
        )

        let attributed = renderer.render(document: document)
        let attachment = attributed.attribute(.attachment, at: 0, effectiveRange: nil) as? NSTextAttachment

        XCTAssertNotNil(attachment)
        XCTAssertNotNil(attachment?.image)
        XCTAssertGreaterThan(attachment?.bounds.width ?? 0, 0)
        XCTAssertGreaterThan(attachment?.bounds.height ?? 0, 0)
    }

    func testAsyncImageRendererProducesAttachmentAndCallsLoader() {
        let loader = MockImageLoader()
        let renderer = STMarkdownAttributedStringRenderer(
            style: STMarkdownStyle.default,
            advancedRenderers: STMarkdownAdvancedRenderers(
                imageRenderer: STMarkdownAsyncImageRenderer(loader: loader)
            )
        )
        let document = STMarkdownRenderDocument(
            blocks: [
                .image(url: "https://example.com/image.png", altText: "示意图", title: "图片标题")
            ]
        )

        let attributed = renderer.render(document: document)
        let attachment = attributed.attribute(.attachment, at: 0, effectiveRange: nil) as? NSTextAttachment

        XCTAssertEqual(loader.lastURL?.absoluteString, "https://example.com/image.png")
        XCTAssertNotNil(attachment)
        XCTAssertNotNil(attachment?.image)
        XCTAssertTrue(attributed.string.contains("图片标题"))
    }

    func testTableAttachmentRendererProducesAttachment() {
        let renderer = STMarkdownAttributedStringRenderer(
            style: STMarkdownStyle.default,
            advancedRenderers: STMarkdownAdvancedRenderers(
                tableRenderer: STMarkdownTableAttachmentRenderer()
            )
        )
        let document = STMarkdownRenderDocument(
            blocks: [
                .table(
                    STMarkdownTableModel(
                        header: [
                            [.text("列1")],
                            [.text("列2")],
                        ],
                        rows: [
                            [
                                [.text("A")],
                                [.text("B")],
                            ]
                        ]
                    )
                )
            ]
        )

        let attributed = renderer.render(document: document)
        // STMarkdownTableViewAttachment 使用 overlay 机制（不走 TextKit 绘制），
        // image 始终为 nil，尺寸通过 attachmentBounds 在 layout 时计算。
        let attachment = attributed.attribute(.attachment, at: 0, effectiveRange: nil) as? STMarkdownTableViewAttachment

        XCTAssertNotNil(attachment)
        XCTAssertNil(attachment?.image)
        XCTAssertNotNil(attachment?.tableViewModel)
        XCTAssertGreaterThan(attachment?.containerWidth ?? 0, 0)
    }

    // MARK: - Multi-table Tests

    func testTableBlankLineRuleInsertsBlankLineBeforeTableAfterText() {
        let rule = STTableBlankLineNormalizationRule()
        var context = STMarkdownPreprocessContext()

        let input = "Some text\n| A | B |\n|---|---|"

        let result = rule.apply(to: input, context: &context)

        XCTAssertTrue(result.contains("Some text\n\n| A | B |"))
    }

    func testTableBlankLineRuleInsertsBlankLineAfterTableBeforeText() {
        let rule = STTableBlankLineNormalizationRule()
        var context = STMarkdownPreprocessContext()

        let input = "| A | B |\n|---|---|\nSome text"

        let result = rule.apply(to: input, context: &context)

        XCTAssertTrue(result.contains("|---|---|\n\nSome text"))
    }

    func testTableBlankLineRuleSkipsContentInsideCodeFence() {
        let rule = STTableBlankLineNormalizationRule()
        var context = STMarkdownPreprocessContext()

        let input = "```\nSome text\n| A | B |\n```"

        let result = rule.apply(to: input, context: &context)

        XCTAssertEqual(result, input)
    }

    func testTableDelimiterRuleInsertsDelimiterForHeaderWithoutOne() {
        let rule = STTableDelimiterNormalizationRule()
        var context = STMarkdownPreprocessContext()

        // Second table starts after blank line but has no delimiter row
        let input = "| A | B |\n|---|---|\n| 1 | 2 |\n\n| C | D |\n| 3 | 4 |"

        let result = rule.apply(to: input, context: &context)

        XCTAssertTrue(result.contains("| C | D |\n| --- | --- |\n| 3 | 4 |"))
    }

    func testTableDelimiterRuleDoesNotDuplicateExistingDelimiter() {
        let rule = STTableDelimiterNormalizationRule()
        var context = STMarkdownPreprocessContext()

        let input = "| A | B |\n|---|---|\n| 1 | 2 |"

        let result = rule.apply(to: input, context: &context)

        // No extra delimiter should be inserted
        let delimiterCount = result.components(separatedBy: "|---|---|").count - 1
        XCTAssertEqual(delimiterCount, 1)
    }

    func testTableDelimiterRuleSkipsContentInsideCodeFence() {
        let rule = STTableDelimiterNormalizationRule()
        var context = STMarkdownPreprocessContext()

        let input = "```\n| A | B |\n| 1 | 2 |\n```"

        let result = rule.apply(to: input, context: &context)

        XCTAssertEqual(result, input)
    }

    func testEngineRecognizesSecondTableMissingDelimiter() {
        let engine = STMarkdownEngine()
        // Second table lacks delimiter row — should be repaired by STTableDelimiterNormalizationRule
        let markdown = "| A | B |\n|---|---|\n| 1 | 2 |\n\n| C | D |\n| 3 | 4 |"

        let result = engine.process(markdown)
        let tableBlocks = result.renderDocument.blocks.compactMap { block -> STMarkdownTableModel? in
            if case .table(let m) = block { return m }
            return nil
        }

        XCTAssertEqual(tableBlocks.count, 2, "两个表格都应被识别，即使第二个缺少分隔行")
    }

    func testEngineRecognizesTwoWellFormedTables() {
        let engine = STMarkdownEngine()
        let markdown = "| A | B |\n|---|---|\n| 1 | 2 |\n\n| C | D |\n|---|---|\n| 3 | 4 |"

        let result = engine.process(markdown)
        let tableBlocks = result.renderDocument.blocks.compactMap { block -> STMarkdownTableModel? in
            if case .table(let m) = block { return m }
            return nil
        }

        XCTAssertEqual(tableBlocks.count, 2)
    }

    func testHighFidelityMathRendererProducesInlineAttachment() {
        let renderer = STMarkdownAttributedStringRenderer(
            style: STMarkdownStyle.default,
            advancedRenderers: STMarkdownAdvancedRenderers(
                inlineMathRenderer: STMarkdownHighFidelityMathRenderer()
            )
        )
        let document = STMarkdownRenderDocument(
            blocks: [
                .paragraph([
                    .inlineMath(#"\frac{1}{2}"#, isDisplayMode: false)
                ])
            ]
        )

        let attributed = renderer.render(document: document)
        let attachment = attributed.attribute(.attachment, at: 0, effectiveRange: nil) as? NSTextAttachment

        XCTAssertNotNil(attachment)
        XCTAssertNotNil(attachment?.image)
        XCTAssertGreaterThan(attachment?.bounds.width ?? 0, 0)
    }

    // MARK: - Strikethrough Tests

    func testStructureParserParsesStrikethrough() {
        let parser = STMarkdownStructureParser()
        let document = parser.parse("~~删除文本~~")

        guard case .paragraph(let inlines)? = document.blocks.first else {
            return XCTFail("Expected paragraph block")
        }

        XCTAssertTrue(inlines.contains { node in
            if case .strikethrough(let children) = node {
                return children.contains(.text("删除文本"))
            }
            return false
        })
    }

    func testAttributedStringRendererAppliesStrikethroughStyle() {
        let renderer = STMarkdownAttributedStringRenderer()
        let document = STMarkdownRenderDocument(
            blocks: [
                .paragraph([
                    .strikethrough([.text("已删除")])
                ])
            ]
        )

        let attributed = renderer.render(document: document)
        let style = attributed.attribute(.strikethroughStyle, at: 0, effectiveRange: nil) as? Int

        XCTAssertEqual(attributed.string, "已删除")
        XCTAssertNotNil(style)
        XCTAssertEqual(style, NSUnderlineStyle.single.rawValue)
    }

    func testStrikethroughWithCustomColor() {
        let markdownStyle = STMarkdownStyle(
            font: .systemFont(ofSize: 16),
            textColor: .label,
            lineHeight: 24,
            kern: 0.12,
            strikethroughColor: .red
        )
        let renderer = STMarkdownAttributedStringRenderer(style: markdownStyle)
        let document = STMarkdownRenderDocument(
            blocks: [
                .paragraph([
                    .strikethrough([.text("红色删除线")])
                ])
            ]
        )

        let attributed = renderer.render(document: document)
        let color = attributed.attribute(.strikethroughColor, at: 0, effectiveRange: nil) as? UIColor

        XCTAssertEqual(color, .red)
    }

    // MARK: - Task List / Checkbox Tests

    func testStructureParserParsesTaskListCheckbox() {
        let parser = STMarkdownStructureParser()
        let document = parser.parse("- [x] 已完成\n- [ ] 未完成")

        guard case .list(_, let items)? = document.blocks.first else {
            return XCTFail("Expected list block")
        }

        XCTAssertEqual(items.count, 2)
        XCTAssertEqual(items[0].checkbox, .checked)
        XCTAssertEqual(items[1].checkbox, .unchecked)
    }

    func testRenderAdapterPreservesCheckbox() {
        let parser = STMarkdownStructureParser()
        let adapter = STMarkdownRenderAdapter()
        let document = parser.parse("- [x] 已完成\n- [ ] 未完成")

        let renderDocument = adapter.adapt(document)

        guard case .list(let items)? = renderDocument.blocks.first else {
            return XCTFail("Expected list render block")
        }

        XCTAssertEqual(items[0].checkbox, .checked)
        XCTAssertEqual(items[1].checkbox, .unchecked)
    }

    func testAttributedStringRendererRendersCheckboxMarkers() {
        let renderer = STMarkdownAttributedStringRenderer()
        let document = STMarkdownRenderDocument(
            blocks: [
                .list([
                    STMarkdownRenderListItem(
                        content: [.text("已完成")],
                        ordered: false,
                        level: 0,
                        orderedIndex: nil,
                        childBlocks: [],
                        checkbox: .checked
                    ),
                    STMarkdownRenderListItem(
                        content: [.text("未完成")],
                        ordered: false,
                        level: 0,
                        orderedIndex: nil,
                        childBlocks: [],
                        checkbox: .unchecked
                    ),
                ])
            ]
        )

        let attributed = renderer.render(document: document)
        let text = attributed.string

        XCTAssertTrue(text.contains("☑"))
        XCTAssertTrue(text.contains("☐"))
        XCTAssertTrue(text.contains("已完成"))
        XCTAssertTrue(text.contains("未完成"))
    }

    // MARK: - Sanitizer Rule Tests

    func testHtmlNormalizeRuleUnescapesCRLF() {
        let rule = STHtmlNormalizeRule()
        var context = STMarkdownPreprocessContext()

        let result = rule.apply(to: "第一行\\n第二行", context: &context)

        XCTAssertEqual(result, "第一行\n第二行")
    }

    func testAnchorCleanupRuleRemovesFragmentAnchors() {
        let rule = STAnchorCleanupRule()
        var context = STMarkdownPreprocessContext()

        let input = ##"参考<a href="#ref1">文献1</a>内容"##
        let result = rule.apply(to: input, context: &context)

        XCTAssertFalse(result.contains("<a"))
        XCTAssertTrue(result.contains("参考"))
        XCTAssertTrue(result.contains("内容"))
    }

    func testPageReferenceCleanupRuleRemovesWebpageReferences() {
        let rule = STPageReferenceCleanupRule()
        var context = STMarkdownPreprocessContext()

        let input = "一些内容[webpage 1]后续文本"
        let result = rule.apply(to: input, context: &context)

        XCTAssertEqual(result, "一些内容后续文本")
    }

    func testDoubleNewlineRuleCollapsesTripleNewlines() {
        let rule = STDoubleNewlineRule()
        var context = STMarkdownPreprocessContext()

        let result = rule.apply(to: "A\n\n\n\nB", context: &context)

        XCTAssertEqual(result, "A\n\nB")
    }

    // MARK: - Math Normalizer Tests

    func testMathNormalizerHandlesEmptyInput() {
        let result = STMarkdownMathNormalizer.normalizeBlocks(in: "")

        XCTAssertEqual(result.text, "")
        XCTAssertTrue(result.blockMap.isEmpty)
    }

    func testMathNormalizerExtractsBlockMath() {
        let input = "文本\n\n$$\nx^2 + y^2 = z^2\n$$\n\n后续"
        let result = STMarkdownMathNormalizer.normalizeBlocks(in: input)

        XCTAssertFalse(result.blockMap.isEmpty)
        XCTAssertTrue(result.text.contains("{{ST_MATH_BLOCK:"))
        XCTAssertTrue(result.blockMap.values.contains { $0.contains("x^2 + y^2 = z^2") })
    }

    func testMathNormalizerPreservesCodeBlocks() {
        let input = "```\n$$\nnot math\n$$\n```"
        let result = STMarkdownMathNormalizer.normalizeBlocks(in: input)

        XCTAssertTrue(result.blockMap.isEmpty)
        XCTAssertTrue(result.text.contains("not math"))
    }

    func testInlineMathSplitProducesCorrectNodes() {
        let nodes = STMarkdownMathNormalizer.splitInlineMath(in: #"结果 \(x+y\) 结束"#)

        XCTAssertEqual(nodes.count, 3)
        XCTAssertEqual(nodes[0], .text("结果 "))
        XCTAssertEqual(nodes[1], .inlineMath("x+y", isDisplayMode: false))
        XCTAssertEqual(nodes[2], .text(" 结束"))
    }

    // MARK: - Deep Nested List Tests

    func testRenderAdapterHandlesThreeLevelNestedList() {
        let parser = STMarkdownStructureParser()
        let adapter = STMarkdownRenderAdapter()
        let document = parser.parse(
            """
            - 第一层
              - 第二层
                - 第三层
            """
        )

        let renderDocument = adapter.adapt(document)

        guard case .list(let items)? = renderDocument.blocks.first else {
            return XCTFail("Expected list block")
        }

        XCTAssertEqual(items.first?.level, 0)

        guard case .list(let level1Items)? = items.first?.childBlocks.first else {
            return XCTFail("Expected nested list at level 1")
        }
        XCTAssertEqual(level1Items.first?.level, 1)

        guard case .list(let level2Items)? = level1Items.first?.childBlocks.first else {
            return XCTFail("Expected nested list at level 2")
        }
        XCTAssertEqual(level2Items.first?.level, 2)
    }

    // MARK: - Streaming View Tests

    func testStreamingTextViewAppendFragment() {
        let view = STMarkdownStreamingTextView()

        view.setMarkdown("Hello", animated: false)
        view.appendMarkdownFragment(" World", animated: false)

        XCTAssertTrue(view.attributedText.string.contains("Hello"))
        XCTAssertTrue(view.attributedText.string.contains("World"))
        XCTAssertEqual(view.rawMarkdown, "Hello World")
    }

    func testStreamingTextViewResetClearsContent() {
        let view = STMarkdownStreamingTextView()
        view.setMarkdown("一些内容", animated: false)

        view.reset()

        XCTAssertTrue(view.rawMarkdown.isEmpty)
    }

    // MARK: - Sendable Conformance Tests

    func testPipelineResultIsSendable() {
        let result = STMarkdownPipelineResult(
            rawMarkdown: "test",
            sanitizedMarkdown: "test",
            appliedRules: [],
            sourceDocument: STMarkdownDocument(blocks: []),
            normalizedDocument: STMarkdownDocument(blocks: []),
            renderDocument: STMarkdownRenderDocument(blocks: [])
        )
        let sendableCheck: any Sendable = result
        XCTAssertNotNil(sendableCheck)
    }

    func testSanitizationResultIsSendable() {
        let result = STMarkdownSanitizationResult(
            originalText: "test",
            sanitizedText: "test",
            appliedRules: []
        )
        let sendableCheck: any Sendable = result
        XCTAssertNotNil(sendableCheck)
    }
}
