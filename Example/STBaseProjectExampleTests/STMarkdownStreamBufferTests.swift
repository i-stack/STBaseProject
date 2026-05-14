import XCTest
@testable import STBaseProject

final class STMarkdownStreamBufferTests: XCTestCase {

    func testSingleHeadingStreamsParagraphByParagraph() {
        let buffer = STMarkdownStreamBuffer(minModuleLength: 10)
        let markdown = """
        # Title

        Paragraph one is long enough to stream.

        Paragraph two is also long enough.

        """
        let result = buffer.append(markdown)
        XCTAssertEqual(result.completeModules.count, 2)
        XCTAssertEqual(
            result.completeModules[0].trimmingCharacters(in: .whitespacesAndNewlines),
            "# Title\n\nParagraph one is long enough to stream."
        )
        XCTAssertEqual(
            result.completeModules[1].trimmingCharacters(in: .whitespacesAndNewlines),
            "Paragraph two is also long enough."
        )
        XCTAssertTrue(result.pendingText.isEmpty)
        XCTAssertFalse(result.hasPendingStructure)
    }

    func testDoubleNewlinesInsideCodeBlocksDoNotCreateParagraphBoundaries() {
        let buffer = STMarkdownStreamBuffer(minModuleLength: 10)
        let markdown = """
        # Title

        ```swift
        let first = 1

        let second = 2
        ```

        Closing paragraph is outside the code block.

        """
        let result = buffer.append(markdown)
        XCTAssertEqual(result.completeModules.count, 2)
        XCTAssertTrue(result.completeModules[0].contains("let second = 2"))
        XCTAssertTrue(result.completeModules[0].contains("```swift"))
        XCTAssertEqual(
            result.completeModules[1].trimmingCharacters(in: .whitespacesAndNewlines),
            "Closing paragraph is outside the code block."
        )
        XCTAssertTrue(result.pendingText.isEmpty)
    }

    func testUnclosedFenceDefersCommitUntilClosingTripleBacktick() {
        let buffer = STMarkdownStreamBuffer(minModuleLength: 5)
        _ = buffer.append("Intro\n\n```swift\nlet a = 1\n")
        XCTAssertTrue(buffer.committedSafePrefix.isEmpty)
        XCTAssertEqual(buffer.fullAccumulatedText, "Intro\n\n```swift\nlet a = 1\n")

        let closed = buffer.append("```\n\nDone.\n")
        XCTAssertFalse(closed.hasPendingStructure)
        XCTAssertFalse(buffer.committedSafePrefix.isEmpty)
        XCTAssertTrue(buffer.committedSafePrefix.contains("let a = 1"))
        XCTAssertTrue(buffer.committedSafePrefix.contains("Done."))
    }

    func testOddDollarMathFenceReportsLatexPending() {
        let buffer = STMarkdownStreamBuffer(minModuleLength: 5)
        let r = buffer.append("Text\n\n$$ E = mc^2 ")
        XCTAssertTrue(r.hasPendingStructure)
        XCTAssertEqual(r.pendingType, .latexBlock)
        XCTAssertTrue(r.completeModules.isEmpty)
    }

    func testTableRowWithoutTrailingBlankLineDefersAsTablePending() {
        let buffer = STMarkdownStreamBuffer(minModuleLength: 5)
        let r = buffer.append("| h1 | h2 |\n| -- | -- |\n| a  | b  |")
        XCTAssertTrue(r.hasPendingStructure)
        XCTAssertEqual(r.pendingType, .table)
    }

    func testChunkSplitAcrossWordsStillCommitsParagraphs() {
        let buffer = STMarkdownStreamBuffer(minModuleLength: 8)
        _ = buffer.append("Paragraph one is long")
        _ = buffer.append(" enough to meet the minimum.\n\n")
        _ = buffer.append("Paragraph two is also long enough.\n\n")
        XCTAssertFalse(buffer.committedSafePrefix.isEmpty)
        XCTAssertTrue(buffer.committedSafePrefix.contains("Paragraph one"))
        XCTAssertTrue(buffer.committedSafePrefix.contains("Paragraph two"))
    }

    func testMultiAppendWithoutNewSafePrefixKeepsCommittedStable() {
        // 使用 `##` 而非单行 `# `：单 H1 且以 `\n\n` 结尾时会触发 `shouldDeferCommitAwaitingPossibleSecondTopLevelHeading`，
        // 后续追加若去掉该后缀，defer 解除并可能把 `lastSafe` 顶到文末，导致 committed 突然变长，与本用例「仅增长尾部」假设冲突。
        let buffer = STMarkdownStreamBuffer(minModuleLength: 10)
        let first = buffer.append("## Section\n\nFirst block is long enough.\n\n")
        XCTAssertFalse(first.completeModules.isEmpty)
        let committedAfterFirst = buffer.committedSafePrefix
        _ = buffer.append("still ")
        _ = buffer.append("typing ")
        _ = buffer.append("pending tail without new paragraph break")
        XCTAssertEqual(buffer.committedSafePrefix, committedAfterFirst)
    }

    func testFlushExposesFullTextAsCommitted() {
        let buffer = STMarkdownStreamBuffer(minModuleLength: 100)
        _ = buffer.append("Short")
        XCTAssertTrue(buffer.committedSafePrefix.isEmpty)
        let tail = buffer.flush()
        XCTAssertEqual(tail, "Short")
        XCTAssertEqual(buffer.committedSafePrefix, "Short")
    }
}
