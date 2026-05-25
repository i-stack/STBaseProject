//
//  STMarkdownFootnoteAndHTMLTests.swift
//  STBaseProjectExampleTests
//

import XCTest
import STBaseProject

final class STMarkdownFootnoteAndHTMLTests: XCTestCase {

    private func renderMeta(_ kind: STMarkdownRenderBlockKind) -> STMarkdownRenderBlockMetadata {
        STMarkdownRenderBlockMetadata(
            id: "test-\(kind.rawValue)",
            path: [],
            kind: kind,
            revealPolicy: .atomicBlock
        )
    }

    func testFootnoteDefinitionStrippedAndReferenceParsed() {
        let md = """
        Hello[^a] world.

        [^a]: Foot **note** here.
        """
        let parser = STMarkdownStructureParser()
        let doc = parser.parse(md)
        XCTAssertFalse(doc.footnoteDefinitions["a"]?.content.isEmpty ?? true, "footnote body should parse")
        guard case .paragraph(let inlines)? = doc.blocks.first else {
            return XCTFail("expected paragraph")
        }
        XCTAssertTrue(inlines.contains(where: {
            if case .footnoteReference(let l) = $0 { return l == "a" }
            return false
        }))
    }

    func testRawHTMLBlockPolicyLiteral() {
        var style = STMarkdownStyle.default
        style.rawHTMLPolicy = .literalMonospace
        let renderer = STMarkdownAttributedStringRenderer(style: style, advancedRenderers: .empty)
        let doc = STMarkdownRenderDocument(blocks: [.rawHTML(self.renderMeta(.rawHTML), "<div>x</div>")])
        let attr = renderer.render(document: doc)
        XCTAssertTrue(attr.string.contains("<div>"))
    }

    func testDetailsRenderContainsSummaryGlyph() {
        let renderer = STMarkdownAttributedStringRenderer(style: .default, advancedRenderers: .empty)
        let doc = STMarkdownRenderDocument(blocks: [
            .details(
                self.renderMeta(.details),
                summary: [.text("More")],
                body: [.paragraph(self.renderMeta(.paragraph), [.text("Hidden")])]
            ),
        ])
        let attr = renderer.render(document: doc)
        XCTAssertTrue(attr.string.contains("▸"))
        XCTAssertTrue(attr.string.contains("More"))
        XCTAssertTrue(attr.string.contains("Hidden"))
    }
}
