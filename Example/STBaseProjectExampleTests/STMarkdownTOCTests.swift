import XCTest
@testable import STBaseProject

final class STMarkdownTOCTests: XCTestCase {

    func testPipelineExtractsTableOfContentsWithStableSlugs() {
        let md = """
        # Hello

        ## World Again

        ### Deep
        """
        let result = STMarkdownEngine().process(md)
        XCTAssertEqual(result.tableOfContents.count, 3)
        XCTAssertEqual(result.tableOfContents[0].level, 1)
        XCTAssertEqual(result.tableOfContents[0].title, "Hello")
        XCTAssertEqual(result.tableOfContents[0].anchorId, "hello")
        XCTAssertEqual(result.tableOfContents[1].anchorId, "world-again")
        XCTAssertEqual(result.tableOfContents[2].anchorId, "deep")
    }

    func testDuplicateHeadingTitlesGetUniqueAnchorIds() {
        let md = "## Same\n\n## Same\n"
        let result = STMarkdownEngine().process(md)
        XCTAssertEqual(result.tableOfContents.count, 2)
        XCTAssertEqual(result.tableOfContents[0].anchorId, "same")
        XCTAssertEqual(result.tableOfContents[1].anchorId, "same-1")
    }

    func testStreamBufferInvokesOnCompleteModules() {
        let buffer = STMarkdownStreamBuffer(minModuleLength: 5)
        var received: [[String]] = []
        buffer.onCompleteModules = { received.append($0) }
        _ = buffer.append("# A\n\nParagraph one is long enough here.\n\n")
        XCTAssertEqual(received.count, 1)
        XCTAssertFalse(received[0].isEmpty)
    }

    @MainActor
    func testScrollableMarkdownViewWithTOCPanelUpdatesPipelineTOC() {
        let v = STScrollableMarkdownView(frame: CGRect(x: 0, y: 0, width: 360, height: 500))
        v.showsTableOfContents = true
        v.setMarkdown("# One\n\n## Two\n\nBody.\n")
        XCTAssertGreaterThanOrEqual(v.markdownTextView.tableOfContents.count, 2)
    }
}
