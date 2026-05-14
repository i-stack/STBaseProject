import XCTest
@testable import STBaseProject

final class STMarkdownIncrementalParseTests: XCTestCase {

    func testReplaceTailCountMatchesVendorHeuristic() {
        // parseStart=50, lastCommitted=250 → backtrack 200 → max(1,2)=2
        let n = STMarkdownIncrementalReplaceCountEstimator.estimateReplaceTailCount(
            previousTotalRenderBlockCount: 10,
            parseStart: 50,
            lastCommittedExclusiveEnd: 250
        )
        XCTAssertEqual(n, 2)
        let capped = STMarkdownIncrementalReplaceCountEstimator.estimateReplaceTailCount(
            previousTotalRenderBlockCount: 1,
            parseStart: 50,
            lastCommittedExclusiveEnd: 250
        )
        XCTAssertEqual(capped, 1)
    }

    func testReplaceTailCountZeroWhenNoRewindOverlap() {
        XCTAssertEqual(
            STMarkdownIncrementalReplaceCountEstimator.estimateReplaceTailCount(
                previousTotalRenderBlockCount: 99,
                parseStart: 100,
                lastCommittedExclusiveEnd: 100
            ),
            0
        )
    }

    func testProcessIncrementalParsesWindowFragment() {
        let pipeline = STMarkdownPipeline(configuration: STMarkdownPipelineConfiguration(enableInputSanitizer: false))
        let canonical = "# Title\n\nFirst paragraph is here.\n\n## Sub\n\nSecond."
        let full = pipeline.process(canonical)
        let prevCount = full.renderDocument.blocks.count
        XCTAssertGreaterThan(prevCount, 0)

        let lastCommitted = canonical.distance(from: canonical.startIndex, to: canonical.firstIndex(of: "F")!)
        let safeEnd = canonical.count
        let inc = pipeline.processIncremental(
            STMarkdownIncrementalParameters(
                canonicalMarkdown: canonical,
                lastCommittedExclusiveEnd: lastCommitted,
                currentSafeExclusiveEnd: safeEnd,
                contextWindowSize: 200,
                previousTotalRenderBlockCount: prevCount
            )
        )
        XCTAssertGreaterThan(inc.parseEndOffset, inc.parseStartOffset)
        XCTAssertFalse(inc.windowFragment.isEmpty)
        XCTAssertFalse(inc.windowRenderDocument.blocks.isEmpty)
        XCTAssertGreaterThanOrEqual(inc.replaceTailCount, 0)
    }

    func testMergedRenderBlocksReplacesTail() {
        let prev: [STMarkdownRenderBlock] = [
            .paragraph([.text("a")]),
            .paragraph([.text("b")]),
            .paragraph([.text("c")]),
        ]
        let newTail: [STMarkdownRenderBlock] = [
            .paragraph([.text("x")]),
        ]
        let merged = STMarkdownIncrementalParseResult.mergedRenderBlocks(
            previous: prev,
            replaceTailCount: 2,
            newTailBlocks: newTail
        )
        XCTAssertEqual(merged.count, 2)
        XCTAssertEqual(merged[0], prev[0])
        XCTAssertEqual(merged[1], newTail[0])
    }
}
