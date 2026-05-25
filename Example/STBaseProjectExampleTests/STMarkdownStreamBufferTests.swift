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
        // 1) 使用 `##` 避免单 H1 + `\n\n` 结尾触发的 `shouldDeferCommitAwaitingPossibleSecondTopLevelHeading` 与后续追加的交互。
        // 2) `findModuleBoundaries` 在尾部「未闭合段落」上若 `tailUTF16 >= minModuleLength`，会把 `text.endIndex`
        //    并入边界，pending 过长时 committed 会合法地扩展；本用例只追加极少字符，使 tail 仍低于阈值。
        let buffer = STMarkdownStreamBuffer(minModuleLength: 10)
        let first = buffer.append("## Section\n\nFirst block is long enough.\n\n")
        XCTAssertFalse(first.completeModules.isEmpty)
        let committedAfterFirst = buffer.committedSafePrefix
        _ = buffer.append("a")
        _ = buffer.append("b")
        _ = buffer.append("c")
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
