import XCTest
import UIKit
import STBaseProject

private struct CoreMockRule: STMarkdownRule {
    let name: String
    let shouldApplyResult: Bool
    let replacement: String

    func shouldApply(to text: String) -> Bool {
        self.shouldApplyResult
    }

    func apply(to text: String, context: inout STMarkdownPreprocessContext) -> String {
        self.replacement
    }
}

private struct CoreMockParser: STMarkdownStructureParsing {
    let parseResult: STMarkdownDocument
    func parse(_ markdown: String) -> STMarkdownDocument { self.parseResult }
}

private struct CoreMockRenderAdapter: STMarkdownRenderAdapting {
    let adaptResult: STMarkdownRenderDocument
    func adapt(_ document: STMarkdownDocument) -> STMarkdownRenderDocument { self.adaptResult }
}

private struct CoreAppendNormalizer: STMarkdownSemanticNormalizing {
    let suffix: String
    func normalize(_ document: STMarkdownDocument) -> STMarkdownDocument {
        let appended = STMarkdownBlockNode.paragraph([.text(self.suffix)])
        return STMarkdownDocument(blocks: document.blocks + [appended])
    }
}

@MainActor
private final class CoreInteractionStub: STMarkdownInteractable {
    var onLinkTap: ((URL) -> Void)?
    var onSelectionChange: ((String) -> Void)?
    var isTextSelectionEnabled: Bool = false
}

final class STMarkdownCoreContractsTests: XCTestCase {

    func testEngineDelegatesToPipelineAndPreservesRawMarkdown() {
        let parserOutput = STMarkdownDocument(blocks: [.heading(level: 1, content: [.text("Title")])])
        let renderOutput = STMarkdownRenderDocument(blocks: [.thematicBreak])
        let parser = CoreMockParser(parseResult: parserOutput)
        let adapter = CoreMockRenderAdapter(adaptResult: renderOutput)
        let engine = STMarkdownEngine(
            configuration: .init(enableInputSanitizer: false),
            parser: parser,
            renderAdapter: adapter
        )

        let result = engine.process("raw markdown")

        XCTAssertEqual(result.rawMarkdown, "raw markdown")
        XCTAssertEqual(result.sanitizedMarkdown, "raw markdown")
        XCTAssertEqual(result.sourceDocument, parserOutput)
        XCTAssertEqual(result.normalizedDocument, parserOutput)
        XCTAssertEqual(result.renderDocument, renderOutput)
    }

    func testPipelineUsesSemanticNormalizersInOrder() {
        let source = STMarkdownDocument(blocks: [.paragraph([.text("seed")])])
        let parser = CoreMockParser(parseResult: source)
        let adapter = CoreMockRenderAdapter(adaptResult: .init(blocks: []))
        let pipeline = STMarkdownPipeline(
            configuration: .init(
                enableInputSanitizer: false,
                semanticNormalizers: [
                    CoreAppendNormalizer(suffix: "A"),
                    CoreAppendNormalizer(suffix: "B"),
                ]
            ),
            parser: parser,
            renderAdapter: adapter
        )

        let result = pipeline.process("ignored")

        XCTAssertEqual(result.normalizedDocument.blocks.count, 3)
        XCTAssertEqual(result.normalizedDocument.blocks[1], .paragraph([.text("A")]))
        XCTAssertEqual(result.normalizedDocument.blocks[2], .paragraph([.text("B")]))
    }

    func testPipelineConfigurationDefaultsEnableSanitizerAndRules() {
        let configuration = STMarkdownPipelineConfiguration()

        XCTAssertTrue(configuration.enableInputSanitizer)
        XCTAssertFalse(configuration.debug)
        XCTAssertFalse(configuration.sanitizerRules.isEmpty)
        XCTAssertTrue(configuration.semanticNormalizers.isEmpty)
    }

    func testPreprocessContextMarksAppliedRulesInOrder() {
        var context = STMarkdownPreprocessContext(debugMode: .enabled)
        let first = CoreMockRule(name: "rule-1", shouldApplyResult: true, replacement: "x")

        context.markApplied(first)
        context.markApplied("rule-2")

        XCTAssertTrue(context.debugMode.isEnabled)
        XCTAssertEqual(context.appliedRules, ["rule-1", "rule-2"])
    }

    func testRenderAdapterKeepsQuoteListItemLevelWithoutExtraIncrement() {
        let adapter = STMarkdownRenderAdapter()
        let document = STMarkdownDocument(
            blocks: [
                .quote([
                    .list(
                        kind: .ordered(startIndex: 3),
                        items: [
                            STMarkdownListItemNode(blocks: [.paragraph([.text("inside quote")])]),
                        ]
                    )
                ])
            ]
        )

        let renderDocument = adapter.adapt(document)

        guard case .quote(let quoteBlocks)? = renderDocument.blocks.first,
              case .list(let items)? = quoteBlocks.first
        else {
            return XCTFail("Expected quote->list render structure")
        }
        XCTAssertEqual(items.first?.orderedIndex, 3)
        XCTAssertEqual(items.first?.level, 0)
    }

    func testBodyParagraphStyleUsesConfiguredMetrics() {
        let style = STMarkdownStyle.default
        let paragraph = STMarkdownTypography.bodyParagraphStyle(style: style)

        XCTAssertEqual(paragraph.minimumLineHeight, style.lineHeight)
        XCTAssertEqual(paragraph.maximumLineHeight, style.lineHeight)
        XCTAssertEqual(paragraph.lineSpacing, style.bodyLineSpacing)
        XCTAssertEqual(paragraph.paragraphSpacing, style.paragraphSpacing)
    }

    func testHeadingFontAndInsetsForFallbackLevel() {
        let font = STMarkdownTypography.headingFont(for: 6)
        let insets = STMarkdownTypography.headingInsets(for: 6)
        let expected = UIFont.st_systemFont(ofSize: 16, weight: .medium)

        XCTAssertEqual(font.pointSize, expected.pointSize)
        XCTAssertEqual(insets.top, 16)
        XCTAssertEqual(insets.bottom, 6)
    }

    func testHeadingParagraphStyleNeverUsesNegativeParagraphSpacingBefore() {
        var style = STMarkdownStyle.default
        style.paragraphSpacing = 100
        let font = UIFont.st_systemFont(ofSize: 22, weight: .bold)

        let paragraph = STMarkdownTypography.headingParagraphStyle(level: 1, font: font, style: style)

        XCTAssertEqual(paragraph.paragraphSpacingBefore, 0)
        XCTAssertEqual(paragraph.paragraphSpacing, 10)
    }

    func testListStyleResolverOrderedLayoutBuildsMonotonicIndices() {
        let style = STMarkdownStyle.default
        let baseFont = style.font
        let layout = STMarkdownListStyleResolver.makeLayout(
            ordered: true,
            level: 2,
            orderedIndex: 0,
            baseFont: baseFont,
            style: style
        )

        XCTAssertEqual(layout.markerText, "1.\t")
        XCTAssertGreaterThan(layout.contentIndent, layout.markerIndent)
        XCTAssertGreaterThan(layout.paragraphStyle.tabStops.count, 1)
    }

    func testApplyContinuationIndentAlignsAllParagraphsToContentIndent() {
        let attributed = NSMutableAttributedString(string: "line1\nline2\n\nline3")
        let style = STMarkdownStyle.default

        STMarkdownListStyleResolver.applyContinuationIndent(
            to: attributed,
            firstLineIndent: 4,
            contentIndent: 28,
            style: style
        )

        var location = 0
        let string = attributed.string as NSString
        while location < attributed.length {
            let range = string.paragraphRange(for: NSRange(location: location, length: 0))
            let paragraph = attributed.attribute(.paragraphStyle, at: range.location, effectiveRange: nil) as? NSParagraphStyle
            XCTAssertEqual(paragraph?.firstLineHeadIndent, 28)
            XCTAssertEqual(paragraph?.headIndent, 28)
            location = range.location + range.length
        }
    }

    func testStyleDefaultAndResolvedDisplayScale() {
        let style = STMarkdownStyle.default
        XCTAssertEqual(style.lineHeight, 24)
        XCTAssertGreaterThan(style.resolvedDisplayScale, 0)
    }

    func testStyleHeadingFontProviderCanOverrideLevel() {
        var style = STMarkdownStyle.default
        style.headingFontProvider = { _ in UIFont.st_systemFont(ofSize: 42, weight: .bold) }

        let resolved = style.headingFontProvider?(3)
        let expected = UIFont.st_systemFont(ofSize: 42, weight: .bold)

        XCTAssertEqual(resolved?.pointSize, expected.pointSize)
    }

    func testFontResolverReturnsExpectedPointSizeForBoldAndItalic() {
        let base = UIFont.st_systemFont(ofSize: 17, weight: .regular)

        let italic = STMarkdownFontResolver.italicFont(from: base)
        let bold = STMarkdownFontResolver.boldFont(from: base)
        let boldItalic = STMarkdownFontResolver.boldItalicFont(from: base)

        XCTAssertEqual(italic.pointSize, base.pointSize)
        XCTAssertEqual(bold.pointSize, base.pointSize)
        XCTAssertEqual(boldItalic.pointSize, base.pointSize)
    }

    func testPresetsFactoryCreatesFreshRendererInstances() {
        let first = STMarkdownPresets.makeDefaultAdvancedRenderers()
        let second = STMarkdownPresets.makeDefaultAdvancedRenderers()

        XCTAssertNotNil(first.inlineMathRenderer)
        XCTAssertNotNil(first.codeBlockRenderer)

        let firstObject = first.inlineMathRenderer as AnyObject
        let secondObject = second.inlineMathRenderer as AnyObject
        XCTAssertFalse(firstObject === secondObject)
    }

    func testDeprecatedDefaultAdvancedRenderersCompatibilityCreatesFreshInstances() {
        let first = STMarkdownPresets.defaultAdvancedRenderers
        let second = STMarkdownPresets.defaultAdvancedRenderers

        XCTAssertNotNil(first.inlineMathRenderer)
        XCTAssertNotNil(first.blockMathRenderer)
        XCTAssertNotNil(first.codeBlockRenderer)
        XCTAssertNotNil(first.tableRenderer)
        XCTAssertNotNil(first.imageRenderer)
        XCTAssertNotNil(first.horizontalRuleRenderer)

        let firstObject = first.inlineMathRenderer as AnyObject
        let secondObject = second.inlineMathRenderer as AnyObject
        XCTAssertFalse(firstObject === secondObject)
    }

    func testPresetsProvideArticleAndCompactWithDifferentTypography() {
        XCTAssertGreaterThan(STMarkdownPresets.article.font.pointSize, STMarkdownPresets.compact.font.pointSize)
        XCTAssertGreaterThan(STMarkdownPresets.article.lineHeight, STMarkdownPresets.compact.lineHeight)
        XCTAssertGreaterThan(STMarkdownPresets.article.horizontalRuleLength, STMarkdownPresets.compact.horizontalRuleLength)
    }

    @MainActor
    func testInteractionProtocolPropertiesAreUsableOnMainActor() {
        let stub = CoreInteractionStub()
        var tappedURL: URL?
        var selectedText: String?
        let url = URL(string: "https://example.com")!

        stub.onLinkTap = { tappedURL = $0 }
        stub.onSelectionChange = { selectedText = $0 }
        stub.isTextSelectionEnabled = true

        stub.onLinkTap?(url)
        stub.onSelectionChange?("selection")

        XCTAssertEqual(tappedURL, url)
        XCTAssertEqual(selectedText, "selection")
        XCTAssertTrue(stub.isTextSelectionEnabled)
    }
}
