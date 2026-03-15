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
                    .image(url: "https://example.com/a.png", altText: "示意图", title: nil)
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

        XCTAssertEqual(attributed.string, String(repeating: "─", count: 10))
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
        let attachment = attributed.attribute(.attachment, at: 0, effectiveRange: nil) as? NSTextAttachment

        XCTAssertNotNil(attachment)
        XCTAssertNotNil(attachment?.image)
        XCTAssertGreaterThan(attachment?.bounds.width ?? 0, 0)
        XCTAssertGreaterThan(attachment?.bounds.height ?? 0, 0)
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
}
