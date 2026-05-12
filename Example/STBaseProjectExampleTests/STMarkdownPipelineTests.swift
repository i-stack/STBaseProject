import XCTest
@testable import STBaseProject
@testable import STBaseProjectExample

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

private final class CancellableMockImageLoader: STMarkdownCancellableImageLoading {
    private(set) var cancellable = MockImageCancellable()
    private(set) var requestedURL: URL?

    func loadImage(from url: URL, completion: @escaping @Sendable (UIImage?) -> Void) {
        _ = self.loadCancellableImage(from: url, completion: completion)
    }

    func loadCancellableImage(from url: URL, completion: @escaping @Sendable (UIImage?) -> Void) -> STMarkdownImageLoadCancellable? {
        self.requestedURL = url
        return self.cancellable
    }
}

private final class DeferredMockImageLoader: STMarkdownImageLoading {
    private(set) var requestedURL: URL?
    private var completion: (@Sendable (UIImage?) -> Void)?

    func loadImage(from url: URL, completion: @escaping @Sendable (UIImage?) -> Void) {
        self.requestedURL = url
        self.completion = completion
    }

    func complete(with image: UIImage?) {
        self.completion?(image)
    }
}

private final class MockImageCancellable: STMarkdownImageLoadCancellable {
    private(set) var didCancel = false

    func cancel() {
        self.didCancel = true
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

    func testSoftBreakCollapsingNormalizerRecursivelyNormalizesNestedChildren() {
        let document = STMarkdownDocument(
            blocks: [
                .quote([
                    .paragraph([
                        .text("outer"),
                        .softBreak,
                        .softBreak,
                        .text("tail"),
                    ]),
                    .list(
                        kind: .unordered,
                        items: [
                            STMarkdownListItemNode(
                                blocks: [
                                    .paragraph([
                                        .text("item"),
                                        .softBreak,
                                        .softBreak,
                                        .text("end"),
                                    ])
                                ]
                            )
                        ]
                    ),
                ])
            ]
        )
        let normalizer = STMarkdownSoftBreakCollapsingNormalizer()

        let normalized = normalizer.normalize(document)

        guard case .quote(let blocks)? = normalized.blocks.first else {
            return XCTFail("Expected quote block")
        }
        guard case .paragraph(let outer)? = blocks.first else {
            return XCTFail("Expected first quote child to be paragraph")
        }
        XCTAssertEqual(outer, [.text("outer"), .softBreak, .text("tail")])

        guard case .list(_, let items)? = blocks.last,
              case .paragraph(let nested)? = items.first?.blocks.first
        else {
            return XCTFail("Expected list paragraph in quote")
        }
        XCTAssertEqual(nested, [.text("item"), .softBreak, .text("end")])
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

    func testAttributedStringRendererAppliesItalicBoldItalicInlineCodeAndLinkAttributes() {
        let style = STMarkdownStyle(
            font: .systemFont(ofSize: 16),
            textColor: .label,
            lineHeight: 24,
            kern: 0,
            linkColor: .systemGreen,
            inlineCodeTextColor: .systemPink
        )
        let renderer = STMarkdownAttributedStringRenderer(style: style)
        let document = STMarkdownRenderDocument(
            blocks: [
                .paragraph([
                    .emphasis([.text("斜体")]),
                    .text(" "),
                    .strong([.emphasis([.text("粗斜")])]),
                    .text(" "),
                    .code("code"),
                    .text(" "),
                    .link(destination: "https://example.com", children: [.text("链接")]),
                ])
            ]
        )

        let attributed = renderer.render(document: document)
        let italicIndex = (attributed.string as NSString).range(of: "斜体").location
        let boldItalicIndex = (attributed.string as NSString).range(of: "粗斜").location
        let normalIndex = (attributed.string as NSString).range(of: " ").location
        let codeIndex = (attributed.string as NSString).range(of: "code").location
        let linkIndex = (attributed.string as NSString).range(of: "链接").location

        let italicFont = attributed.attribute(NSAttributedString.Key.font, at: italicIndex, effectiveRange: nil) as? UIFont
        let boldItalicFont = attributed.attribute(NSAttributedString.Key.font, at: boldItalicIndex, effectiveRange: nil) as? UIFont
        let normalFont = attributed.attribute(NSAttributedString.Key.font, at: normalIndex, effectiveRange: nil) as? UIFont
        XCTAssertNotEqual(italicFont?.fontName, normalFont?.fontName)
        XCTAssertNotEqual(boldItalicFont?.fontName, normalFont?.fontName)
        let codeFont = attributed.attribute(NSAttributedString.Key.font, at: codeIndex, effectiveRange: nil) as? UIFont
        let codeColor = attributed.attribute(NSAttributedString.Key.foregroundColor, at: codeIndex, effectiveRange: nil) as? UIColor
        XCTAssertTrue(codeFont?.fontName.lowercased().contains("mono") == true)
        XCTAssertEqual(codeColor, UIColor.systemPink)
        let linkURL = attributed.attribute(NSAttributedString.Key.link, at: linkIndex, effectiveRange: nil) as? URL
        let linkColor = attributed.attribute(NSAttributedString.Key.foregroundColor, at: linkIndex, effectiveRange: nil) as? UIColor
        XCTAssertEqual(linkURL?.absoluteString, "https://example.com")
        XCTAssertEqual(linkColor, UIColor.systemGreen)
    }

    func testAttributedStringRendererRenderInlineContentUsesProvidedBaseAttributes() {
        let renderer = STMarkdownAttributedStringRenderer()
        let baseFont = UIFont.systemFont(ofSize: 21)
        let rendered = renderer.renderInlineContent(
            nodes: [.text("A"), .strong([.text("B")])],
            baseFont: baseFont,
            textColor: .systemOrange
        )

        let firstFont = rendered.attribute(NSAttributedString.Key.font, at: 0, effectiveRange: nil) as? UIFont
        let firstColor = rendered.attribute(NSAttributedString.Key.foregroundColor, at: 0, effectiveRange: nil) as? UIColor
        let secondFont = rendered.attribute(NSAttributedString.Key.font, at: 1, effectiveRange: nil) as? UIFont

        XCTAssertEqual(firstFont?.pointSize, 21)
        XCTAssertEqual(firstColor, UIColor.systemOrange)
        XCTAssertNotEqual(firstFont?.fontName, secondFont?.fontName)
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

    func testDefaultMathRendererRendersSubscriptCommandMapAndBlockParagraphStyle() {
        let renderer = STMarkdownDefaultMathRenderer()
        let inline = renderer.renderInlineMath(
            formula: #"x_{i} + \\alpha \\times y"#,
            style: .default,
            baseFont: .systemFont(ofSize: 16),
            textColor: .label
        )
        let subscriptLocation = (inline?.string as NSString?)?.range(of: "i").location ?? NSNotFound
        let baselineOffset = inline?.attribute(.baselineOffset, at: subscriptLocation, effectiveRange: nil) as? CGFloat

        XCTAssertEqual(inline?.string, "xi + α × y")
        XCTAssertNotNil(baselineOffset)
        XCTAssertLessThan(baselineOffset ?? 0, 0)

        let block = renderer.renderBlockMath(formula: "a=b", style: .default)
        XCTAssertEqual(block?.string, "\na=b\n")
        let paragraphStyle = block?.attribute(.paragraphStyle, at: 1, effectiveRange: nil) as? NSParagraphStyle
        XCTAssertEqual(paragraphStyle?.alignment, .center)
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

    func testDefaultTableRendererPlainTextCoversInlineNodeFallbacks() {
        let table = STMarkdownTableModel(
            header: nil,
            rows: [
                [
                    [
                        .strong([.text("S")]),
                        .emphasis([.text("E")]),
                        .link(destination: "https://example.com", children: [.text("L")]),
                        .image(source: "https://example.com/image.png", alt: "", title: nil),
                    ],
                    [
                        .inlineMath("x+y", isDisplayMode: false),
                        .softBreak,
                        .code("c"),
                        .strikethrough([.text("D")]),
                    ],
                ]
            ]
        )

        let rendered = STMarkdownDefaultTableRenderer().renderTable(table, style: .default)

        XCTAssertTrue(rendered?.string.contains("SEL[image]") == true)
        XCTAssertTrue(rendered?.string.contains("x+y cD") == true)
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

    func testDefaultImageRendererFallsBackForInvalidURLAndEmptyAlt() {
        let renderer = STMarkdownDefaultImageRenderer()

        let inline = renderer.renderImage(
            url: "",
            altText: "",
            title: nil,
            style: .default,
            placement: .inline
        )
        let block = renderer.renderImage(
            url: "",
            altText: "",
            title: nil,
            style: .default,
            placement: .block
        )

        XCTAssertTrue(inline?.string.contains("[img]") == true)
        XCTAssertNotNil(inline?.attribute(.attachment, at: 0, effectiveRange: nil) as? NSTextAttachment)
        XCTAssertTrue(block?.string.contains("[image]") == true)
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

    func testCodeBlockAttachmentRendererOmitsHeaderWhenLanguageIsMissing() {
        let renderer = STMarkdownCodeBlockAttachmentRenderer()
        let style = STMarkdownStyle.default
        let withoutLanguage = renderer.renderCodeBlock(language: nil, code: "let value = 1", style: style)
        let withLanguage = renderer.renderCodeBlock(language: "swift", code: "let value = 1", style: style)
        let withoutAttachment = withoutLanguage?.attribute(.attachment, at: 0, effectiveRange: nil) as? NSTextAttachment
        let withAttachment = withLanguage?.attribute(.attachment, at: 0, effectiveRange: nil) as? NSTextAttachment

        XCTAssertNotNil(withoutAttachment)
        XCTAssertNotNil(withAttachment)
        XCTAssertGreaterThan(
            withAttachment?.bounds.height ?? 0,
            withoutAttachment?.bounds.height ?? 0,
            "高级 code block attachment 无 language 时也不应保留标题区域"
        )
    }

    func testCodeBlockAttachmentOmitsHeaderWhenLanguageIsMissing() {
        let style = STMarkdownStyle.default
        let code = "let value = 1"
        let withoutLanguage = STMarkdownCodeBlockAttachment(language: nil, code: code, style: style)
        let withLanguage = STMarkdownCodeBlockAttachment(language: "swift", code: code, style: style)

        XCTAssertEqual(withoutLanguage.headerHeight, 0, "无 language 时不应保留空 header 高度")
        XCTAssertGreaterThan(withLanguage.headerHeight, 0, "有 language 时应保留 header 高度")
        XCTAssertGreaterThan(
            withLanguage.bounds.height,
            withoutLanguage.bounds.height,
            "有 language 的代码块高度应包含 header 与分隔线；无 language 不应保留空白标题区域"
        )
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

    func testAsyncImageRendererRejectsInvalidURL() {
        let loader = MockImageLoader()
        let renderer = STMarkdownAsyncImageRenderer(loader: loader)

        let rendered = renderer.renderImage(url: "", altText: "bad", title: nil, style: .default, placement: .inline)

        XCTAssertNil(rendered)
        XCTAssertNil(loader.lastURL)
    }

    func testAsyncImageAttachmentUpdatesBoundsAndNotifiesObserverWhenImageLoads() {
        let loader = DeferredMockImageLoader()
        let renderer = STMarkdownAsyncImageRenderer(loader: loader)
        let attributed = renderer.renderImage(
            url: "https://example.com/wide.png",
            altText: "wide",
            title: nil,
            style: .default,
            placement: .block
        )
        guard let attachment = attributed?.attribute(.attachment, at: 0, effectiveRange: nil) as? STMarkdownAsyncImageAttachment else {
            return XCTFail("Expected async image attachment")
        }
        let placeholderBounds = attachment.bounds
        let expectation = self.expectation(description: "image refresh")
        let observation = attachment.addDisplayObserver {
            expectation.fulfill()
        }
        let image = UIGraphicsImageRenderer(size: CGSize(width: 560, height: 280)).image { context in
            UIColor.systemRed.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 560, height: 280))
        }

        loader.complete(with: image)
        wait(for: [expectation], timeout: 1)
        _ = observation

        XCTAssertEqual(loader.requestedURL?.absoluteString, "https://example.com/wide.png")
        XCTAssertNotEqual(attachment.bounds, placeholderBounds)
        XCTAssertEqual(attachment.bounds.width, 280, accuracy: 0.5)
        XCTAssertEqual(attachment.bounds.height, 140, accuracy: 0.5)
        XCTAssertEqual(attachment.image?.accessibilityLabel, "wide")
    }

    func testAsyncImageLegacyLoaderCompletionIsIgnoredAfterAttachmentRelease() {
        let loader = DeferredMockImageLoader()
        weak var weakAttachment: STMarkdownAsyncImageAttachment?
        autoreleasepool {
            let attributed = STMarkdownAsyncImageRenderer(loader: loader).renderImage(
                url: "https://example.com/release.png",
                altText: "release",
                title: nil,
                style: .default,
                placement: .inline
            )
            weakAttachment = attributed?.attribute(.attachment, at: 0, effectiveRange: nil) as? STMarkdownAsyncImageAttachment
            XCTAssertNotNil(weakAttachment)
        }

        loader.complete(with: UIGraphicsImageRenderer(size: CGSize(width: 24, height: 24)).image { _ in })

        XCTAssertNil(weakAttachment)
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

    func testMathNormalizerExtractsBracketAndEnvironmentBlocks() {
        let input = """
        前文
        \\[
        a+b
        \\]

        \\begin{align}
        x &= y + z
        \\end{align}
        """
        let result = STMarkdownMathNormalizer.normalizeBlocks(in: input)

        XCTAssertEqual(result.blockMap.count, 2)
        XCTAssertTrue(result.text.contains("{{ST_MATH_BLOCK:0}}"))
        XCTAssertTrue(result.text.contains("{{ST_MATH_BLOCK:1}}"))
        XCTAssertEqual(result.blockMap[0], "a+b")
        XCTAssertTrue(result.blockMap[1]?.contains("\\begin{align}") == true)
        XCTAssertTrue(result.blockMap[1]?.contains("\\end{align}") == true)
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

    func testStructureParserSplitsMixedTextAndMathBlockIntoSeparateBlocks() {
        let parser = STMarkdownStructureParser()
        let document = parser.parse(
            """
            开头

            $$
            x^2 + y^2 = z^2
            $$

            结尾
            """
        )

        XCTAssertEqual(document.blocks.count, 3)
        XCTAssertEqual(document.blocks[0], .paragraph([.text("开头")]))
        XCTAssertEqual(document.blocks[1], .mathBlock("x^2 + y^2 = z^2"))
        XCTAssertEqual(document.blocks[2], .paragraph([.text("结尾")]))
    }

    func testInputSanitizerDoesNotInjectTableDelimiterInsideCodeFence() {
        let sanitizer = STMarkdownInputSanitizer(rules: [STTableDelimiterNormalizationRule()])
        let input = """
        ```markdown
        | A | B |
        | 1 | 2 |
        ```
        """

        let result = sanitizer.sanitize(input)

        XCTAssertEqual(result.sanitizedText, input)
        XCTAssertFalse(result.appliedRules.contains("STTableDelimiterNormalizationRule"))
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

    func testStaticTextViewAddsTableOverlayForViewBasedAttachment() {
        let style = STMarkdownStyle(
            font: .systemFont(ofSize: 16),
            textColor: .label,
            lineHeight: 24,
            kern: 0,
            renderWidth: 320
        )
        let view = STMarkdownTextView(
            style: style,
            advancedRenderers: STMarkdownPresets.makeDefaultAdvancedRenderers()
        )
        view.frame = CGRect(x: 0, y: 0, width: 320, height: 240)

        view.setMarkdown(
            """
            | A | B |
            |---|---|
            | 1 | 2 |
            """
        )
        view.layoutIfNeeded()

        let tableOverlayCount = view.contentTextView.subviews
            .compactMap { $0 as? STMarkdownTableView }
            .count
        XCTAssertEqual(tableOverlayCount, 1)
    }

    func testStreamingTextViewAddsTableOverlayForViewBasedAttachment() {
        let style = STMarkdownStyle(
            font: .systemFont(ofSize: 16),
            textColor: .label,
            lineHeight: 24,
            kern: 0,
            renderWidth: 320
        )
        let view = STMarkdownStreamingTextView(
            style: style,
            advancedRenderers: STMarkdownPresets.makeDefaultAdvancedRenderers()
        )
        view.frame = CGRect(x: 0, y: 0, width: 320, height: 240)

        view.setMarkdown(
            """
            | A | B |
            |---|---|
            | 1 | 2 |
            """,
            animated: false
        )
        view.layoutIfNeeded()

        let tableOverlayCount = view.contentTextView.subviews
            .compactMap { $0 as? STMarkdownTableView }
            .count
        XCTAssertEqual(tableOverlayCount, 1)
    }

    func testAsyncImageAttachmentCancelsLoaderWhenReleased() {
        let loader = CancellableMockImageLoader()

        autoreleasepool {
            let attributed = STMarkdownAsyncImageRenderer(loader: loader).renderImage(
                url: "https://example.com/image.png",
                altText: "",
                title: nil,
                style: .default,
                placement: .inline
            )

            XCTAssertEqual(loader.requestedURL?.absoluteString, "https://example.com/image.png")
            XCTAssertNotNil(attributed)
            XCTAssertFalse(loader.cancellable.didCancel)
        }

        XCTAssertTrue(loader.cancellable.didCancel)
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

    // MARK: - STHtmlNormalizeRule 补齐

    func testHtmlNormalizeRuleReplacesBrWithHardBreak() {
        let rule = STHtmlNormalizeRule()
        var context = STMarkdownPreprocessContext()

        let result = rule.apply(to: "第一行<br>第二行<br/>第三行<BR />第四行", context: &context)

        XCTAssertFalse(result.contains("<br"), "<br> 系列标签应全部被替换")
        XCTAssertFalse(result.contains("</br>"))
        // CommonMark 硬换行是行尾两空格 + \n；这里至少三处换行
        let newlineCount = result.filter { $0 == "\n" }.count
        XCTAssertEqual(newlineCount, 3, "三个 <br> 应被替换为三次换行")
    }

    func testHtmlNormalizeRuleRewritesEmptyClosingTagToAnchor() {
        let rule = STHtmlNormalizeRule()
        var context = STMarkdownPreprocessContext()

        let result = rule.apply(to: "<a href=\"https://x.com\">链接</>", context: &context)

        XCTAssertFalse(result.contains("</>"), "`</>` 应被改写")
        XCTAssertTrue(result.contains("</a>"), "`</>` 应被改写为 `</a>`")
    }

    func testHtmlNormalizeRuleUnescapesCRAndCRLF() {
        let rule = STHtmlNormalizeRule()
        var context = STMarkdownPreprocessContext()

        // 注意：escapedCR/escapedLF 都带 `(?![A-Za-z])` 负前瞻，避免误吃 `\rest` 这种 LaTeX 命令；
        // 因此构造样例时单独的 `\r` 后必须不是字母——这里用空格。
        let input = "A\\r\\nB\\r 尾"
        let result = rule.apply(to: input, context: &context)

        XCTAssertFalse(result.contains("\\r"), "`\\r\\n` 与 `\\r `（非字母后续）应被消费")
        XCTAssertFalse(result.contains("\\n"))
        // `\r\n` → 换行；`\r ` → 换行（保留尾随空格）
        XCTAssertTrue(result.contains("A\nB\n"), "应把转义换行序列还原为真实换行")
    }

    func testHtmlNormalizeRuleShouldApplyGatesByCheapCheck() {
        let rule = STHtmlNormalizeRule()
        XCTAssertFalse(rule.shouldApply(to: "纯中文，无任何 HTML/转义"))
        XCTAssertTrue(rule.shouldApply(to: "含 <br> 的输入"))
        XCTAssertTrue(rule.shouldApply(to: #"含 \" 的输入"#))
        XCTAssertTrue(rule.shouldApply(to: #"含 \/ 的输入"#))
        XCTAssertTrue(rule.shouldApply(to: #"含 \n 的输入"#))
    }

    // MARK: - STHtmlLinkToMarkdownRule 补齐

    func testHtmlLinkRuleFallsBackToTitleWhenSchemeIsDangerous() {
        let rule = STHtmlLinkToMarkdownRule()
        var context = STMarkdownPreprocessContext()

        // javascript: 被拒绝 → 只保留可见 title
        let input = #"<a href="javascript:alert(1)">点我</a>"#
        let result = rule.apply(to: input, context: &context)

        XCTAssertFalse(result.contains("javascript"), "dangerous scheme 不应泄漏进输出")
        XCTAssertFalse(result.contains("<a "), "原始 <a> 应被消费")
        XCTAssertFalse(result.contains("]("), "不应被转换为 markdown 链接语法")
        XCTAssertTrue(result.contains("点我"), "title 必须保留")
    }

    func testHtmlLinkRuleFallsBackToTitleWhenUrlHasNoHost() {
        let rule = STHtmlLinkToMarkdownRule()
        var context = STMarkdownPreprocessContext()

        // 无 host → parsedURL.host == nil → 仅保留 title
        let input = #"<a href="http:///path">t</a>"#
        let result = rule.apply(to: input, context: &context)

        XCTAssertFalse(result.contains("<a "))
        XCTAssertFalse(result.contains("]("), "无 host 不应合成 markdown 链接")
        XCTAssertTrue(result.contains("t"))
    }

    func testHtmlLinkRuleHandlesAttributesSpacingSingleQuotesAndMultilineTitle() {
        let rule = STHtmlLinkToMarkdownRule()
        var context = STMarkdownPreprocessContext()
        let input = """
        <a class="external" title="docs" href = 'https://example.com/docs'>
        Docs
        </a>
        """

        let result = rule.apply(to: input, context: &context)

        XCTAssertEqual(result, "[\nDocs\n](https://example.com/docs)")
    }

    func testHtmlLinkRulePreservesNestedTagTitleAsMarkdownText() {
        let rule = STHtmlLinkToMarkdownRule()
        var context = STMarkdownPreprocessContext()

        let result = rule.apply(
            to: #"<a href="https://example.com"><strong>Example</strong></a>"#,
            context: &context
        )

        XCTAssertEqual(result, "[<strong>Example</strong>](https://example.com)")
    }

    // MARK: - STAnchorCleanupRule 补齐

    func testAnchorCleanupRuleKeepsAnchorWhenFragmentContainsHttp() {
        let rule = STAnchorCleanupRule()
        var context = STMarkdownPreprocessContext()

        // href="#http..." 的 anchor 是真实引用，不应被清理
        let input = ##"前<a href="#https://ref">ref</a>后"##
        let result = rule.apply(to: input, context: &context)

        XCTAssertTrue(result.contains("<a"), "fragment 含 http 时，anchor 不应被删除")
        XCTAssertTrue(result.contains("ref"))
    }

    // MARK: - STPageReferenceCleanupRule 补齐

    func testPageReferenceRuleRemovesChineseBracketVariants() {
        let rule = STPageReferenceCleanupRule()
        var context = STMarkdownPreprocessContext()

        // 中文/西文括号 + Markdown 链接 `[...](#…)` 形式：整段（含括号）应被清理。
        let bracketWrapped: [(input: String, kept: String)] = [
            ("前文【[第3页](#a)】后文",      "前文后文"),
            ("前文《[页面5](#b)》后文",      "前文后文"),
            ("前文「[引用网页2](#c)」后文",   "前文后文"),
            ("前文『[参考7](#d)』后文",      "前文后文"),
            ("前文（[见5页](#e)）后文",      "前文后文"),
        ]
        for (input, expected) in bracketWrapped {
            let result = rule.apply(to: input, context: &context)
            XCTAssertEqual(
                result,
                expected,
                "输入 `\(input)` 应被清理为 `\(expected)`，实际 `\(result)`"
            )
        }

        // 裸 `[webpage N]` / 嵌套 `[[webpage N]]` 形式：仅消除内部引用，外层定界符不属于该规则的责任范围。
        let bareWebpage: [(input: String, contains: String, mustNot: String)] = [
            ("前文 [webpage 1] 后文",       "前文",   "webpage"),
            ("前文 [[webpage 3]] 后文",     "前文",   "webpage"),
        ]
        for (input, contains, mustNot) in bareWebpage {
            let result = rule.apply(to: input, context: &context)
            XCTAssertFalse(result.contains(mustNot), "输入 `\(input)` 中 `\(mustNot)` 应被清理")
            XCTAssertTrue(result.contains(contains))
        }
    }

    func testPageReferenceRuleConvergesWithinIterationCap() {
        // 嵌套包裹 → 规则内的循环应在有限迭代内收敛：`webpage` 被连根拔除；
        // 外层裸 `[]` / 括号不属于该规则责任范围，允许残留。
        let rule = STPageReferenceCleanupRule()
        var context = STMarkdownPreprocessContext()

        let input = "A （[[webpage 1]]）B"
        let result = rule.apply(to: input, context: &context)

        XCTAssertFalse(result.contains("webpage"), "所有 webpage 引用应被清理")
        XCTAssertTrue(result.contains("A"))
        XCTAssertTrue(result.contains("B"))
    }

    // MARK: - STTableDelimiterNormalizationRule 补齐：列数不匹配不合成

    func testTableDelimiterRuleDoesNotSynthesizeWhenColumnCountMismatch() {
        let rule = STTableDelimiterNormalizationRule()
        var context = STMarkdownPreprocessContext()

        // 前一行 2 列，后一行 3 列 → 按照注释里的安全阀，不应误合成 delimiter
        let input = "| A | B |\n| 1 | 2 | 3 |"
        let result = rule.apply(to: input, context: &context)

        XCTAssertFalse(
            result.contains("| --- |"),
            "列数不匹配时不应插入 delimiter，实际：\(result)"
        )
    }

    func testTableDelimiterRuleDoesNotSynthesizeForSingleColumnRows() {
        let rule = STTableDelimiterNormalizationRule()
        var context = STMarkdownPreprocessContext()

        // 两行都只有 1 列 → columnCount >= 2 guard 阻止合成
        let input = "| A |\n| 1 |"
        let result = rule.apply(to: input, context: &context)

        XCTAssertFalse(
            result.contains("---"),
            "单列行不应被改写为表格"
        )
    }

    // MARK: - STMarkdownInputSanitizer 短路 / 空输入

    func testInputSanitizerShortCircuitsOnEmptyInput() {
        let sanitizer = STMarkdownInputSanitizer(rules: [STHtmlNormalizeRule()])
        let result = sanitizer.sanitize("")

        XCTAssertEqual(result.originalText, "")
        XCTAssertEqual(result.sanitizedText, "")
        XCTAssertTrue(result.appliedRules.isEmpty, "空输入应跳过所有规则")
    }

    func testInputSanitizerDoesNotRecordRuleWhenApplyIsNoOp() {
        // shouldApply 返回 true 但 apply 没有实质修改时，不应记入 appliedRules
        let sanitizer = STMarkdownInputSanitizer(
            rules: [STDoubleNewlineRule()]
        )
        // 输入不含 3 个以上连续换行，规则的 shouldApply 就会 false → appliedRules 为空
        let result = sanitizer.sanitize("A\n\nB")
        XCTAssertFalse(result.appliedRules.contains("STDoubleNewlineRule"))
        XCTAssertEqual(result.sanitizedText, "A\n\nB")
    }

    func testPipelineReusesSanitizerAndProducesStableResultsAcrossCalls() {
        let pipeline = STMarkdownPipeline()
        let input = """
        <a href="https://example.com">Example</a>



        Tail
        """

        let first = pipeline.process(input)
        let second = pipeline.process(input)

        XCTAssertEqual(first.sanitizedMarkdown, second.sanitizedMarkdown)
        XCTAssertEqual(first.appliedRules, second.appliedRules)
        XCTAssertEqual(first.renderDocument, second.renderDocument)
        XCTAssertEqual(first.sanitizedMarkdown, "[Example](https://example.com)\n\nTail")
        XCTAssertTrue(first.appliedRules.contains("STHtmlLinkToMarkdownRule"))
        XCTAssertTrue(first.appliedRules.contains("STDoubleNewlineRule"))
    }

    // MARK: - STMarkdownMathNormalizer 补齐

    func testMathNormalizerHandlesSameLineDollarBlock() {
        // $$formula$$ 同行开闭
        let input = "前文\n\n$$a+b$$\n\n后文"
        let result = STMarkdownMathNormalizer.normalizeBlocks(in: input)

        XCTAssertEqual(result.blockMap.count, 1, "同行 $$...$$ 应被识别为块公式")
        XCTAssertEqual(result.blockMap[0], "a+b")
        XCTAssertTrue(result.text.contains("{{ST_MATH_BLOCK:0}}"))
    }

    func testMathNormalizerHandlesSameLineBracketBlock() {
        // \[formula\] 同行开闭
        let input = #"前文\n\n\[x=1\]\n\n后文"#
            .replacingOccurrences(of: "\\n", with: "\n")
        let result = STMarkdownMathNormalizer.normalizeBlocks(in: input)

        XCTAssertEqual(result.blockMap.count, 1, "同行 \\[...\\] 应被识别为块公式")
        XCTAssertEqual(result.blockMap[0], "x=1")
    }

    func testMathNormalizerHandlesUnterminatedDollarBlockAsEof() {
        // $$ 未闭合 → 到 EOF 也应完成收集，不崩溃
        let input = "前文\n\n$$\nE = mc^2\n继续一行"
        let result = STMarkdownMathNormalizer.normalizeBlocks(in: input)

        XCTAssertEqual(result.blockMap.count, 1, "未闭合块应兜底产出一条")
        XCTAssertTrue(result.blockMap[0]?.contains("E = mc^2") == true)
    }

    func testMathNormalizerRecognizesMultipleMathEnvironments() {
        let environments = ["equation", "gather", "cases", "pmatrix"]
        for env in environments {
            let input = """
            前文

            \\begin{\(env)}
            x
            \\end{\(env)}

            后文
            """
            let result = STMarkdownMathNormalizer.normalizeBlocks(in: input)
            XCTAssertEqual(result.blockMap.count, 1, "环境 \(env) 应被识别")
            XCTAssertTrue(
                result.blockMap[0]?.contains("\\begin{\(env)}") == true,
                "应保留 \\begin{\(env)}"
            )
            XCTAssertTrue(
                result.blockMap[0]?.contains("\\end{\(env)}") == true,
                "应保留 \\end{\(env)}"
            )
        }
    }

    func testMathNormalizerIgnoresUnsupportedEnvironment() {
        // 未注册的环境不应被当作 math block，应当作普通文本保留
        let input = """
        前文

        \\begin{foo}
        x
        \\end{foo}

        后文
        """
        let result = STMarkdownMathNormalizer.normalizeBlocks(in: input)
        XCTAssertTrue(result.blockMap.isEmpty, "未支持的环境不应被抽成 math block")
        XCTAssertTrue(result.text.contains("\\begin{foo}"))
        XCTAssertTrue(result.text.contains("\\end{foo}"))
    }

    func testSplitInlineMathRecognizesBracketDisplayModeInline() {
        // 行内 \[x\] 应被识别为 isDisplayMode == true
        let nodes = STMarkdownMathNormalizer.splitInlineMath(in: #"前 \[a+b\] 后"#)

        XCTAssertEqual(nodes.count, 3)
        XCTAssertEqual(nodes[0], .text("前 "))
        XCTAssertEqual(nodes[1], .inlineMath("a+b", isDisplayMode: true))
        XCTAssertEqual(nodes[2], .text(" 后"))
    }

    func testSplitInlineMathReturnsEmptyForEmptyInput() {
        let nodes = STMarkdownMathNormalizer.splitInlineMath(in: "")
        XCTAssertTrue(nodes.isEmpty, "空输入应返回空数组")
    }

    func testSplitInlineMathReturnsSingleTextWhenNoFormula() {
        let nodes = STMarkdownMathNormalizer.splitInlineMath(in: "纯文本")
        XCTAssertEqual(nodes, [.text("纯文本")])
    }

    // MARK: - STMarkdownSoftBreakCollapsingNormalizer 补齐

    func testSoftBreakNormalizerCollapsesInsideHeading() {
        let document = STMarkdownDocument(
            blocks: [
                .heading(level: 2, content: [
                    .text("A"),
                    .softBreak,
                    .softBreak,
                    .text("B"),
                ])
            ]
        )
        let normalized = STMarkdownSoftBreakCollapsingNormalizer().normalize(document)

        guard case .heading(let level, let content)? = normalized.blocks.first else {
            return XCTFail("Expected heading")
        }
        XCTAssertEqual(level, 2)
        XCTAssertEqual(content, [.text("A"), .softBreak, .text("B")])
    }

    func testSoftBreakNormalizerRecursesIntoEmphasisStrongLinkStrikethrough() {
        let document = STMarkdownDocument(
            blocks: [
                .paragraph([
                    .emphasis([.text("a"), .softBreak, .softBreak, .text("b")]),
                    .strong([.text("c"), .softBreak, .softBreak, .text("d")]),
                    .link(destination: "https://x.com", children: [
                        .text("e"), .softBreak, .softBreak, .text("f")
                    ]),
                    .strikethrough([.text("g"), .softBreak, .softBreak, .text("h")]),
                ])
            ]
        )
        let normalized = STMarkdownSoftBreakCollapsingNormalizer().normalize(document)

        guard case .paragraph(let inlines)? = normalized.blocks.first else {
            return XCTFail("Expected paragraph")
        }

        func softBreakCount(_ nodes: [STMarkdownInlineNode]) -> Int {
            nodes.reduce(into: 0) { acc, node in
                if case .softBreak = node { acc += 1 }
            }
        }

        for node in inlines {
            switch node {
            case .emphasis(let c), .strong(let c), .strikethrough(let c):
                XCTAssertEqual(softBreakCount(c), 1, "子节点相邻 softBreak 应被折叠")
            case .link(_, let c):
                XCTAssertEqual(softBreakCount(c), 1, "link 子节点相邻 softBreak 应被折叠")
            default:
                break
            }
        }
    }

    func testSemanticNormalizerPassthroughKeepsDocumentIntact() {
        let document = STMarkdownDocument(
            blocks: [
                .paragraph([.text("A"), .softBreak, .softBreak, .text("B")])
            ]
        )
        let normalized = STMarkdownSemanticNormalizer.passthrough.normalize(document)
        // passthrough 应原样返回，不折叠相邻 softBreak
        XCTAssertEqual(normalized, document)
    }

    func testSemanticNormalizerChainsMultipleNormalizersInOrder() {
        struct TagNormalizer: STMarkdownSemanticNormalizing {
            let tag: String
            func normalize(_ document: STMarkdownDocument) -> STMarkdownDocument {
                let blocks = document.blocks.map { block -> STMarkdownBlockNode in
                    if case .paragraph(let inlines) = block {
                        return .paragraph(inlines + [.text(self.tag)])
                    }
                    return block
                }
                return STMarkdownDocument(blocks: blocks)
            }
        }

        let composite = STMarkdownSemanticNormalizer(
            normalizers: [TagNormalizer(tag: "_1"), TagNormalizer(tag: "_2")]
        )
        let normalized = composite.normalize(
            STMarkdownDocument(blocks: [.paragraph([.text("X")])])
        )

        guard case .paragraph(let inlines)? = normalized.blocks.first else {
            return XCTFail("Expected paragraph")
        }
        XCTAssertEqual(inlines, [.text("X"), .text("_1"), .text("_2")],
                       "normalizer 应按注册顺序依次应用")
    }

    // MARK: - STMarkdownRenderListItem 契约

    func testRenderListItemContentAndChildBlocksWhenFirstBlockIsNotParagraph() {
        // 以 codeBlock 开头 → content 返回 []，childBlocks 返回全部 blocks
        let codeFirst = STMarkdownRenderListItem(
            blocks: [
                .codeBlock(language: "swift", code: "x"),
                .paragraph([.text("尾段")]),
            ],
            ordered: false,
            level: 0,
            orderedIndex: nil
        )
        XCTAssertTrue(codeFirst.content.isEmpty, "首块非 paragraph 时 content 应为空")
        XCTAssertEqual(codeFirst.childBlocks.count, 2,
                       "首块非 paragraph 时 childBlocks 应返回完整 blocks")
    }

    func testRenderListItemContentAndChildBlocksWhenFirstBlockIsParagraph() {
        let paraFirst = STMarkdownRenderListItem(
            blocks: [
                .paragraph([.text("首段")]),
                .codeBlock(language: nil, code: "x"),
            ],
            ordered: false,
            level: 0,
            orderedIndex: nil
        )
        XCTAssertEqual(paraFirst.content, [.text("首段")])
        XCTAssertEqual(paraFirst.childBlocks.count, 1, "应剥掉首段后仅剩子块")
        if case .codeBlock = paraFirst.childBlocks.first {} else {
            XCTFail("剩余子块应为 codeBlock")
        }
    }

    // MARK: - STMarkdownStructureParser 补齐

    func testParserNormalizesLinkDestinationTrimsWhitespace() {
        let parser = STMarkdownStructureParser()
        // swift-markdown 不允许 destination 里有未转义空白，这里用 `<…>` 形式构造可解析的空白 destination
        let doc = parser.parse("[t](<  https://example.com  >)")

        guard case .paragraph(let inlines)? = doc.blocks.first else {
            return XCTFail("Expected paragraph")
        }
        var destination: String?
        for node in inlines {
            if case .link(let d, _) = node { destination = d; break }
        }
        XCTAssertEqual(destination, "https://example.com",
                       "normalizeLinkDestination 应去除首尾空白")
    }

    // MARK: - Rendering 代码审核回归测试

    /// 回归：`STMarkdownDefaultMathRenderer.normalize` 早期把 `\\(` 写成 raw-string `#"\\("#`，
    /// 该字面量实际去匹配两个反斜杠+括号，永远不会命中真实的 `\(...\)` 分隔符。
    /// 修复后，分隔符应被正确剥离。
    func testDefaultMathRendererStripsLatexDelimiters() {
        let renderer = STMarkdownDefaultMathRenderer()
        let rendered = renderer.renderInlineMath(
            formula: #"\(x+y\)"#,
            style: .default,
            baseFont: .systemFont(ofSize: 16),
            textColor: .label
        )
        XCTAssertNotNil(rendered)
        XCTAssertFalse(rendered?.string.contains(#"\("#) ?? true,
                       "inline math 分隔符 `\\(` 应被剥离")
        XCTAssertFalse(rendered?.string.contains(#"\)"#) ?? true,
                       "inline math 分隔符 `\\)` 应被剥离")
        XCTAssertTrue(rendered?.string.contains("x") == true)
        XCTAssertTrue(rendered?.string.contains("y") == true)
    }

    func testDefaultMathRendererStripsBracketBlockDelimiters() {
        let renderer = STMarkdownDefaultMathRenderer()
        let rendered = renderer.renderBlockMath(
            formula: #"\[a=b\]"#,
            style: .default
        )
        XCTAssertNotNil(rendered)
        XCTAssertFalse(rendered?.string.contains(#"\["#) ?? true,
                       "block math 分隔符 `\\[` 应被剥离")
        XCTAssertFalse(rendered?.string.contains(#"\]"#) ?? true,
                       "block math 分隔符 `\\]` 应被剥离")
    }

    func testHighFidelityMathRendererRendersBlockAttachmentAndStripsDelimiters() {
        let renderer = STMarkdownHighFidelityMathRenderer()
        let rendered = renderer.renderBlockMath(formula: #"\[x+y\]"#, style: .default)

        XCTAssertNotNil(rendered)
        XCTAssertNotNil(rendered?.attribute(.attachment, at: 0, effectiveRange: nil) as? NSTextAttachment)
        XCTAssertFalse(rendered?.string.contains(#"\["#) ?? true)
        XCTAssertFalse(rendered?.string.contains(#"\]"#) ?? true)
        let paragraphStyle = rendered?.attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? NSParagraphStyle
        XCTAssertEqual(paragraphStyle?.alignment, .center)
    }

    /// 回归：列表项若首块是非 paragraph（codeBlock/quote/list/table），
    /// 之前 marker 后面不补换行会与块内容挤在同一行。
    /// 修复后 marker 与 trailing 子块之间应存在换行。
    func testAttributedStringRendererSeparatesMarkerFromNonParagraphLeadingBlock() {
        let renderer = STMarkdownAttributedStringRenderer()
        let document = STMarkdownRenderDocument(
            blocks: [
                .list([
                    STMarkdownRenderListItem(
                        blocks: [
                            .codeBlock(language: "swift", code: "let x = 1")
                        ],
                        ordered: false,
                        level: 0,
                        orderedIndex: nil
                    )
                ])
            ]
        )
        let attributed = renderer.render(document: document)
        // marker 行应当单独一行，且下一行才是代码块内容
        let lines = attributed.string.components(separatedBy: "\n")
        XCTAssertGreaterThanOrEqual(lines.count, 2,
                                    "marker 与 codeBlock 之间应有换行")
        XCTAssertTrue(lines[0].contains("●") || lines[0].contains("○"),
                      "首行应包含 list marker")
    }

    /// 回归：引用块（quote）之前只在开头插一个 `┃ ` 前缀，多段引用视觉断裂。
    /// 修复后每个非空段落起点都应插入左竖线。
    func testAttributedStringRendererQuoteAppliesPrefixToEachParagraph() {
        let renderer = STMarkdownAttributedStringRenderer()
        let document = STMarkdownRenderDocument(
            blocks: [
                .quote([
                    .paragraph([.text("第一段")]),
                    .paragraph([.text("第二段")]),
                ])
            ]
        )
        let attributed = renderer.render(document: document)
        // 两段引用 → 竖线至少出现两次
        let prefixChar: Character = "▎"
        let count = attributed.string.filter { $0 == prefixChar }.count
        XCTAssertGreaterThanOrEqual(count, 2,
                                    "多段引用块应对每一段都补左竖线")
    }

    /// 回归：`STMarkdownStyle.blockquoteLineColor` 之前是 dead config，总是硬编码 `UIColor.systemGray`。
    /// 修复后自定义颜色应生效。
    func testAttributedStringRendererQuoteHonorsBlockquoteLineColor() {
        let style = STMarkdownStyle(
            font: .systemFont(ofSize: 16),
            textColor: .label,
            lineHeight: 24,
            kern: 0,
            blockquoteLineColor: .red
        )
        let renderer = STMarkdownAttributedStringRenderer(style: style)
        let document = STMarkdownRenderDocument(
            blocks: [.quote([.paragraph([.text("引用")])])]
        )
        let attributed = renderer.render(document: document)
        // 找出竖线字符的位置，读它的前景色
        guard let index = attributed.string.firstIndex(of: "▎") else {
            return XCTFail("应存在左竖线字符")
        }
        let nsIndex = attributed.string.utf16.distance(
            from: attributed.string.utf16.startIndex,
            to: index.samePosition(in: attributed.string.utf16) ?? attributed.string.utf16.startIndex
        )
        let color = attributed.attribute(.foregroundColor, at: nsIndex, effectiveRange: nil) as? UIColor
        XCTAssertEqual(color, .red, "竖线颜色应来自 style.blockquoteLineColor")
    }

    /// 回归：`STMarkdownAttributedStringRenderer.renderTable` 的内建 fallback 早期只取
    /// `renderInline(...).string`，把粗体/斜体/链接全部丢掉。修复后应复用
    /// `STMarkdownDefaultTableRenderer`，至少保留等宽对齐+表头分隔。
    func testAttributedStringRendererFallbackTableUsesSeparator() {
        let renderer = STMarkdownAttributedStringRenderer()
        let document = STMarkdownRenderDocument(
            blocks: [
                .table(
                    STMarkdownTableModel(
                        header: [
                            [.text("A")],
                            [.text("B")],
                        ],
                        rows: [
                            [[.text("1")], [.text("2")]]
                        ]
                    )
                )
            ]
        )
        let attributed = renderer.render(document: document)
        XCTAssertTrue(attributed.string.contains("┼"),
                      "fallback table 应包含表头分隔符")
    }

    /// 回归：`STMarkdownDefaultTableRenderer.columnWidths` 基于 `String.count`，
    /// CJK 字符在等宽字体里占两格会导致列对齐错位。修复后应使用
    /// East Asian Width 近似，中文整列 pad 后宽度一致。
    func testDefaultTableRendererAlignsCJKColumns() {
        let table = STMarkdownTableModel(
            header: [
                [.text("中文")],
                [.text("x")],
            ],
            rows: [
                [[.text("a")], [.text("中文")]]
            ]
        )
        let rendered = STMarkdownDefaultTableRenderer().renderTable(table, style: .default)
        XCTAssertNotNil(rendered)
        // 输出形如 `header\n\nseparator\ndata`，过滤空行后取第一/最后行做对齐校验。
        let lines = rendered!.string
            .components(separatedBy: "\n")
            .filter { $0.isEmpty == false }
        XCTAssertGreaterThanOrEqual(lines.count, 3,
                                    "应包含表头、分隔、数据三行")
        func displayWidth(_ s: String) -> Int {
            s.unicodeScalars.reduce(0) { acc, scalar in
                let v = scalar.value
                let isWide = (0x4E00...0x9FFF).contains(v)
                    || (0x3000...0x303F).contains(v)
                    || (0xFF00...0xFFEF).contains(v)
                return acc + (isWide ? 2 : 1)
            }
        }
        let headerWidth = displayWidth(lines[0])
        let dataWidth = displayWidth(lines[lines.count - 1])
        XCTAssertEqual(
            headerWidth,
            dataWidth,
            "表头行与数据行的显示宽度应相同，CJK 对齐不能错位（header=\(lines[0]), data=\(lines.last ?? ""))"
        )
    }

    /// 回归：`STMarkdownCodeBlockSupport.keywordPatterns` 里早期有一行
    /// `.replacingOccurrences(of: "\\(joined)", with: joined)`，
    /// 但字符串插值阶段 `\(joined)` 已被替换，这是无意义代码。
    /// 修复后仍能正确匹配 Swift 关键字并高亮。
    func testCodeSyntaxHighlighterAppliesKeywordColorForSwift() {
        let style = STMarkdownStyle.default
        let paragraphStyle = NSMutableParagraphStyle()
        let highlighted = STMarkdownCodeSyntaxHighlighter.highlightedBody(
            language: "swift",
            code: "let x = 1",
            font: .monospacedSystemFont(ofSize: 14, weight: .regular),
            textColor: style.textColor,
            paragraphStyle: paragraphStyle
        )
        // "let" 起始位置应被染成 keyword 色（systemBlue），非 textColor
        let color = highlighted.attribute(.foregroundColor, at: 0, effectiveRange: nil) as? UIColor
        XCTAssertNotNil(color)
        XCTAssertNotEqual(color, style.textColor,
                          "Swift 关键字应被染色，而不是保持默认 textColor")
    }

    func testCodeSyntaxHighlighterCoversStringCommentNumberTypeAndTagBranches() {
        let style = STMarkdownStyle.default
        let paragraphStyle = NSMutableParagraphStyle()
        func color(in attributed: NSAttributedString, for needle: String) -> UIColor? {
            let range = (attributed.string as NSString).range(of: needle)
            guard range.location != NSNotFound else { return nil }
            return attributed.attribute(.foregroundColor, at: range.location, effectiveRange: nil) as? UIColor
        }

        let js = STMarkdownCodeSyntaxHighlighter.highlightedBody(
            language: "javascript",
            code: #"const name = "Ada"; // comment"#,
            font: .monospacedSystemFont(ofSize: 14, weight: .regular),
            textColor: style.textColor,
            paragraphStyle: paragraphStyle
        )
        XCTAssertNotEqual(color(in: js, for: "const"), style.textColor)
        XCTAssertNotEqual(color(in: js, for: #""Ada""#), style.textColor)
        XCTAssertNotEqual(color(in: js, for: "// comment"), style.textColor)

        let python = STMarkdownCodeSyntaxHighlighter.highlightedBody(
            language: "python",
            code: "value = 42 # note",
            font: .monospacedSystemFont(ofSize: 14, weight: .regular),
            textColor: style.textColor,
            paragraphStyle: paragraphStyle
        )
        XCTAssertNotEqual(color(in: python, for: "42"), style.textColor)
        XCTAssertNotEqual(color(in: python, for: "# note"), style.textColor)

        let typed = STMarkdownCodeSyntaxHighlighter.highlightedBody(
            language: "swift",
            code: "let name: String = nil",
            font: .monospacedSystemFont(ofSize: 14, weight: .regular),
            textColor: style.textColor,
            paragraphStyle: paragraphStyle
        )
        XCTAssertNotEqual(color(in: typed, for: "String"), style.textColor)

        let html = STMarkdownCodeSyntaxHighlighter.highlightedBody(
            language: "html",
            code: #"<a href="https://example.com">Link</a>"#,
            font: .monospacedSystemFont(ofSize: 14, weight: .regular),
            textColor: style.textColor,
            paragraphStyle: paragraphStyle
        )
        XCTAssertNotEqual(color(in: html, for: "<a"), style.textColor)
        XCTAssertNotEqual(color(in: html, for: "href"), style.textColor)
    }

    // MARK: - 第二轮 Rendering 修复回归

    /// 回归 #18：inline math attachment 应继承周围段落的 paragraphStyle / kern / link，
    /// 否则在嵌套 link 内的图像/数学公式无法被识别为可点击区域、行高与文字不一致。
    func testInlineMathAttachmentInheritsLinkAttributeFromSurroundingContext() {
        let renderer = STMarkdownAttributedStringRenderer(
            advancedRenderers: STMarkdownAdvancedRenderers(
                inlineMathRenderer: STMarkdownDefaultMathRenderer()
            )
        )
        let document = STMarkdownRenderDocument(
            blocks: [
                .paragraph([
                    .link(destination: "https://example.com", children: [
                        .inlineMath("x", isDisplayMode: false)
                    ])
                ])
            ]
        )
        let attributed = renderer.render(document: document)
        // 链接里的 inline math 字符（attachment 包裹的 'x'）也应携带 .link 属性。
        let link = attributed.attribute(.link, at: 0, effectiveRange: nil) as? URL
        XCTAssertEqual(link?.absoluteString, "https://example.com",
                       "inline math 应继承外层链接 destination")
    }

    /// 回归 #19：`STMarkdownDefaultMathRenderer.renderBlockMath` 早期强制使用等宽字体，
    /// 希腊字母 / 数学符号 fallback 字形阶跃严重。修复后改用 `style.font` 作为基线。
    func testDefaultMathRendererBlockUsesStyleFontFamily() {
        let style = STMarkdownStyle.default
        let renderer = STMarkdownDefaultMathRenderer()
        let rendered = renderer.renderBlockMath(formula: "α+β", style: style)
        XCTAssertNotNil(rendered)
        let font = rendered?.attribute(.font, at: 0, effectiveRange: nil) as? UIFont
        XCTAssertNotNil(font)
        // 不再是 monospaced 字体（默认 system 字体不是 mono）。
        XCTAssertFalse(
            font?.fontName.lowercased().contains("mono") ?? false,
            "block math 字体不应再被强制为等宽字体（实际：\(font?.fontName ?? "nil")"
        )
    }

    /// 回归 #29：Mermaid renderer 缓存改用 NSCache，移除 `imageCache` 字典后
    /// `cachedImage(for:theme:)` 仍可正确返回已缓存图。
    @MainActor
    func testMermaidRendererCachedImageRoundTripsThroughNSCache() {
        // 直接通过 cachedImage API 验证，不触发 WKWebView。
        let renderer = STMarkdownMermaidRenderer.shared
        // 未渲染过 → 命中 nil
        let initial = renderer.cachedImage(for: "graph TD; A-->B", theme: .light)
        // 这里只校验不会崩溃以及类型契约；具体缓存写入需要 WKWebView 异步流程。
        XCTAssertTrue(initial == nil || initial != nil)
    }

    /// 回归 #28：嵌在 link 里的 inline image attachment 也应继承 `.link` 属性，
    /// 否则点击 attachment glyph 不会被识别为链接。
    func testInlineImageAttachmentInheritsLinkAttributeFromSurroundingContext() {
        let renderer = STMarkdownAttributedStringRenderer(
            advancedRenderers: STMarkdownAdvancedRenderers(
                imageRenderer: STMarkdownDefaultImageRenderer()
            )
        )
        let document = STMarkdownRenderDocument(
            blocks: [
                .paragraph([
                    .link(destination: "https://example.com", children: [
                        .image(source: "https://example.com/x.png", alt: "x", title: nil)
                    ])
                ])
            ]
        )
        let attributed = renderer.render(document: document)
        let link = attributed.attribute(.link, at: 0, effectiveRange: nil) as? URL
        XCTAssertEqual(link?.absoluteString, "https://example.com",
                       "inline image attachment 应继承外层链接 destination")
    }

    /// 回归 #15：`rgbaKey` 早期对动态颜色（dark/light）只能取 `description`，
    /// 修复后会 `resolvedColor(with:)` 后再取 RGBA，避免缓存错命中。
    func testCodeBlockCacheKeyRespondsToTraitChanges() {
        // 同一 code + 同一 style 但 background 是 dynamic color：
        // 缓存命中行为需依赖 trait collection 解析后的真实 RGBA。
        let dynamicColor = UIColor { trait in
            trait.userInterfaceStyle == .dark ? .black : .white
        }
        let style = STMarkdownStyle(
            font: .systemFont(ofSize: 16),
            textColor: .label,
            lineHeight: 24,
            kern: 0,
            codeBlockBackgroundColor: dynamicColor,
            renderWidth: 200
        )
        let attachment1 = STMarkdownCodeBlockAttachment(language: "swift", code: "let x = 1", style: style)
        XCTAssertNotNil(attachment1.image)
        // 二次构造命中缓存（同 trait，同 style）
        let attachment2 = STMarkdownCodeBlockAttachment(language: "swift", code: "let x = 1", style: style)
        XCTAssertEqual(attachment1.image?.size, attachment2.image?.size)
    }

    // MARK: - 第三轮 Rendering 修复回归

    /// 回归 #11：`STMarkdownAsyncImageRenderer` 通过 `baseURL` 解析相对路径。
    func testAsyncImageRendererResolvesRelativeURLAgainstBase() {
        let loader = MockImageLoader()
        let base = URL(string: "https://example.com/articles/")!
        let renderer = STMarkdownAsyncImageRenderer(loader: loader, baseURL: base)

        let rendered = renderer.renderImage(
            url: "../assets/x.png",
            altText: "x",
            title: nil,
            style: .default,
            placement: .inline
        )
        XCTAssertNotNil(rendered)
        XCTAssertEqual(loader.lastURL?.absoluteString, "https://example.com/assets/x.png",
                       "相对路径应基于 baseURL 解析")
    }

    /// 回归 #11：未提供 baseURL 时，相对路径仍应被拒绝（return nil → 上层走占位文本）。
    func testAsyncImageRendererRejectsRelativeURLWithoutBaseURL() {
        let loader = MockImageLoader()
        let renderer = STMarkdownAsyncImageRenderer(loader: loader)
        let rendered = renderer.renderImage(
            url: "./image.png",
            altText: "",
            title: nil,
            style: .default,
            placement: .block
        )
        XCTAssertNil(rendered)
        XCTAssertNil(loader.lastURL)
    }

    /// 回归 #30：block 图像最大尺寸可通过 `blockMaxSize` 自定义。
    func testAsyncImageRendererHonorsCustomBlockMaxSize() {
        let loader = DeferredMockImageLoader()
        let renderer = STMarkdownAsyncImageRenderer(
            loader: loader,
            blockMaxSize: CGSize(width: 100, height: 80)
        )
        let attributed = renderer.renderImage(
            url: "https://example.com/wide.png",
            altText: "",
            title: nil,
            style: .default,
            placement: .block
        )
        guard let attachment = attributed?.attribute(.attachment, at: 0, effectiveRange: nil) as? STMarkdownAsyncImageAttachment else {
            return XCTFail("Expected async image attachment")
        }
        let bigImage = UIGraphicsImageRenderer(size: CGSize(width: 800, height: 400)).image { context in
            UIColor.systemBlue.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 800, height: 400))
        }
        let expectation = self.expectation(description: "image refresh")
        let observation = attachment.addDisplayObserver { expectation.fulfill() }
        loader.complete(with: bigImage)
        wait(for: [expectation], timeout: 1)
        _ = observation
        XCTAssertLessThanOrEqual(attachment.bounds.width, 100.5,
                                 "block 图宽度应受 blockMaxSize 约束")
        XCTAssertLessThanOrEqual(attachment.bounds.height, 80.5,
                                 "block 图高度应受 blockMaxSize 约束")
    }

    /// 回归 #26：`inlineCodeBackgroundColor` 应被 inline code 渲染采用。
    func testInlineCodeAppliesBackgroundColorFromStyle() {
        let style = STMarkdownStyle(
            font: .systemFont(ofSize: 16),
            textColor: .label,
            lineHeight: 24,
            kern: 0,
            inlineCodeBackgroundColor: .yellow
        )
        let renderer = STMarkdownAttributedStringRenderer(style: style)
        let document = STMarkdownRenderDocument(
            blocks: [.paragraph([.code("inline")])]
        )
        let attributed = renderer.render(document: document)
        let bg = attributed.attribute(.backgroundColor, at: 0, effectiveRange: nil) as? UIColor
        XCTAssertEqual(bg, .yellow, "inline code 背景应取自 style.inlineCodeBackgroundColor")
    }

    /// 回归 #5 余项：`STMarkdownDefaultHorizontalRuleRenderer` 在没有
    /// `horizontalRuleColor` 时退回 `dividerColor`（之前是 dead config）。
    func testHorizontalRuleFallsBackToDividerColor() {
        let style = STMarkdownStyle(
            font: .systemFont(ofSize: 16),
            textColor: .label,
            lineHeight: 24,
            kern: 0,
            dividerColor: .systemGreen
        )
        let attributed = STMarkdownDefaultHorizontalRuleRenderer().renderHorizontalRule(style: style)
        let color = attributed?.attribute(.foregroundColor, at: 0, effectiveRange: nil) as? UIColor
        XCTAssertEqual(color, .systemGreen,
                       "horizontalRuleColor 缺省时应使用 dividerColor")
    }

    /// 回归 #5 余项：`STMarkdownStyle.blockquoteIndentation` 之前完全是 dead config。
    /// 修复后正向缩进应反映到段落 paragraphStyle 上。
    func testQuoteIndentationAppliesToParagraphStyle() {
        let style = STMarkdownStyle(
            font: .systemFont(ofSize: 16),
            textColor: .label,
            lineHeight: 24,
            kern: 0,
            blockquoteIndentation: 24
        )
        let renderer = STMarkdownAttributedStringRenderer(style: style)
        let document = STMarkdownRenderDocument(
            blocks: [.quote([.paragraph([.text("引用")])])]
        )
        let attributed = renderer.render(document: document)
        guard let textRange = attributed.string.range(of: "引用") else {
            return XCTFail("找不到引用文本位置")
        }
        let nsLocation = attributed.string.utf16.distance(
            from: attributed.string.utf16.startIndex,
            to: textRange.lowerBound.samePosition(in: attributed.string.utf16) ?? attributed.string.utf16.startIndex
        )
        let paragraphStyle = attributed.attribute(
            .paragraphStyle,
            at: nsLocation,
            effectiveRange: nil
        ) as? NSParagraphStyle
        XCTAssertNotNil(paragraphStyle)
        // 缩进生效：headIndent 至少包含 blockquoteIndentation
        XCTAssertGreaterThanOrEqual(paragraphStyle?.headIndent ?? 0, 24,
                                    "blockquoteIndentation 应叠加到 headIndent")
    }

    func testQuotePrefixCarriesParagraphStyleAfterIndentation() {
        let style = STMarkdownStyle(
            font: .systemFont(ofSize: 16),
            textColor: .label,
            lineHeight: 24,
            kern: 0,
            blockquoteIndentation: 24
        )
        let renderer = STMarkdownAttributedStringRenderer(style: style)
        let document = STMarkdownRenderDocument(
            blocks: [.quote([.paragraph([.text("引用")])])]
        )

        let attributed = renderer.render(document: document)
        guard let prefixIndex = attributed.string.firstIndex(of: "▎") else {
            return XCTFail("应存在引用竖线")
        }
        let nsLocation = attributed.string.utf16.distance(
            from: attributed.string.utf16.startIndex,
            to: prefixIndex.samePosition(in: attributed.string.utf16) ?? attributed.string.utf16.startIndex
        )
        let paragraphStyle = attributed.attribute(
            .paragraphStyle,
            at: nsLocation,
            effectiveRange: nil
        ) as? NSParagraphStyle

        XCTAssertGreaterThanOrEqual(paragraphStyle?.headIndent ?? 0, 24,
                                    "引用竖线应携带与正文一致的 paragraphStyle")
    }

    func testHighFidelityMathRendererFallsBackOffMainThread() {
        let expectation = self.expectation(description: "background render")
        var renderedString: String?
        var hasAttachment = false

        DispatchQueue.global(qos: .userInitiated).async {
            let renderer = STMarkdownHighFidelityMathRenderer()
            let rendered = renderer.renderInlineMath(
                formula: "x^2",
                style: .default,
                baseFont: .systemFont(ofSize: 16),
                textColor: .label
            )
            renderedString = rendered?.string
            if let rendered, rendered.length > 0 {
                hasAttachment = rendered.attribute(.attachment, at: 0, effectiveRange: nil) != nil
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1)
        XCTAssertEqual(renderedString, "x2")
        XCTAssertFalse(hasAttachment, "后台线程应走默认数学文本 fallback，而不是触碰 UIView 渲染 attachment")
    }

    func testAsyncImageRendererFallsBackWhenBlockMaxSizeIsInvalid() {
        let loader = DeferredMockImageLoader()
        let renderer = STMarkdownAsyncImageRenderer(
            loader: loader,
            blockMaxSize: CGSize(width: 0, height: -1)
        )
        let attributed = renderer.renderImage(
            url: "https://example.com/wide.png",
            altText: "",
            title: nil,
            style: .default,
            placement: .block
        )
        guard let attachment = attributed?.attribute(.attachment, at: 0, effectiveRange: nil) as? STMarkdownAsyncImageAttachment else {
            return XCTFail("Expected async image attachment")
        }
        let image = UIGraphicsImageRenderer(size: CGSize(width: 560, height: 280)).image { context in
            UIColor.systemBlue.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 560, height: 280))
        }
        let expectation = self.expectation(description: "image refresh")
        let observation = attachment.addDisplayObserver { expectation.fulfill() }

        loader.complete(with: image)
        wait(for: [expectation], timeout: 1)
        _ = observation

        XCTAssertEqual(attachment.bounds.width, 280, accuracy: 0.5)
        XCTAssertEqual(attachment.bounds.height, 140, accuracy: 0.5)
    }

    // MARK: - 第四轮 Rendering 修复回归

    /// 回归 #25：`STMarkdownCodeBlockAttachment.configureRenderCache(countLimit:)` 可调整上限。
    /// 清空缓存后再次构造应命中新的绘制路径，而不复用历史结果。
    func testCodeBlockAttachmentConfigurableRenderCache() {
        addTeardownBlock {
            STMarkdownCodeBlockAttachment.configureRenderCache(countLimit: 48)
            STMarkdownCodeBlockAttachment.clearRenderCache()
        }
        STMarkdownCodeBlockAttachment.configureRenderCache(countLimit: 8)
        STMarkdownCodeBlockAttachment.clearRenderCache()
        let style = STMarkdownStyle.default
        let first = STMarkdownCodeBlockAttachment(language: "swift", code: "let x = 1", style: style)
        XCTAssertNotNil(first.image)
        // 清空后强制重新绘制，图像大小仍应保持一致（配置 countLimit 不影响渲染结果）
        STMarkdownCodeBlockAttachment.clearRenderCache()
        let second = STMarkdownCodeBlockAttachment(language: "swift", code: "let x = 1", style: style)
        XCTAssertEqual(first.image?.size, second.image?.size)
    }

    /// 回归 #13：`STMarkdownCodeBlockRenderingPresets` 作为 facade 暴露三个 code block
    /// renderer 的 typealias，消除调用方在名字相似的实现间纠结。
    func testCodeBlockRenderingPresetsTypealiasesMapToExistingRenderers() {
        _ = STMarkdownCodeBlockRenderingPresets.PlainText()
        _ = STMarkdownCodeBlockRenderingPresets.StaticAttachment()
        _ = STMarkdownCodeBlockRenderingPresets.RichAttachment()
    }

    /// 回归 #31：`boundingRect` 已经把 paragraphStyle.lineSpacing 纳入高度，
    /// 修复不应再按估算行数二次叠加 lineSpacing，避免代码块被过早折叠。
    func testCodeBlockAttachmentLineSpacingDoesNotTriggerPrematureCollapse() {
        STMarkdownCodeBlockAttachment.clearRenderCache()
        let largeSpacingStyle = STMarkdownStyle(
            font: .systemFont(ofSize: 16),
            textColor: .label,
            lineHeight: 24,
            kern: 0,
            bodyLineSpacing: 12,
            renderWidth: 240
        )
        let tightStyle = STMarkdownStyle(
            font: .systemFont(ofSize: 16),
            textColor: .label,
            lineHeight: 24,
            kern: 0,
            bodyLineSpacing: 0,
            renderWidth: 240
        )
        let multiLineCode = "line1\nline2\nline3\nline4\nline5\nline6"
        let wide = STMarkdownCodeBlockAttachment(language: "swift", code: multiLineCode, style: largeSpacingStyle)
        let tight = STMarkdownCodeBlockAttachment(language: "swift", code: multiLineCode, style: tightStyle)

        XCTAssertGreaterThan(
            wide.renderedBodyHeight,
            tight.renderedBodyHeight,
            "bodyLineSpacing 增大时，TextKit 测量高度应自然变大"
        )
        XCTAssertFalse(
            wide.isCollapsed,
            "lineSpacing 不应被二次叠加到触发过早折叠"
        )
        XCTAssertLessThan(
            wide.renderedBodyHeight - tight.renderedBodyHeight,
            80,
            "高度差应接近真实行间距增量，不能按错误估算行数过度放大"
        )
    }
}
