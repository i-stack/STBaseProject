import XCTest
import UIKit
@testable import STBaseProject

@MainActor
final class STMarkdownUIViewTests: XCTestCase {

    func testTextViewLinkTapCallbackReturnsFalseAndForwardsURL() {
        let view = STMarkdownTextView()
        let url = URL(string: "https://example.com")!
        var tappedURL: URL?
        view.onLinkTap = { tappedURL = $0 }

        let shouldInteract = view.textView(
            view.contentTextView,
            shouldInteractWith: url,
            in: NSRange(location: 0, length: 0),
            interaction: .invokeDefaultAction
        )

        XCTAssertFalse(shouldInteract)
        XCTAssertEqual(tappedURL, url)
    }

    func testTextViewSelectionChangeCallbackReturnsSelectedText() {
        let view = STMarkdownTextView()
        view.setMarkdown("Hello World")
        var selectedText: String?
        view.onSelectionChange = { selectedText = $0 }

        view.contentTextView.selectedRange = NSRange(location: 6, length: 5)
        view.textViewDidChangeSelection(view.contentTextView)

        XCTAssertEqual(selectedText, "World")
    }

    func testTextViewResetClearsRawMarkdownAndRenderedText() {
        let view = STMarkdownTextView()
        view.setMarkdown("## Title")

        view.reset()

        XCTAssertTrue(view.rawMarkdown.isEmpty)
        XCTAssertTrue(view.attributedText.string.isEmpty)
    }

    func testStreamingViewUsesCustomDocumentRendererWhenProvided() {
        let view = STMarkdownStreamingTextView()
        view.customDocumentRenderer = { _ in
            NSAttributedString(string: "custom-rendered")
        }

        view.setMarkdown("**ignored**", animated: false)

        XCTAssertEqual(view.attributedText.string, "custom-rendered")
    }

    func testStreamingViewAppendEmptyFragmentDoesNotChangeState() {
        let view = STMarkdownStreamingTextView()
        view.setMarkdown("base", animated: false)

        view.appendMarkdownFragment("", animated: true)

        XCTAssertEqual(view.rawMarkdown, "base")
        XCTAssertEqual(view.attributedText.string, "base")
    }

    func testStreamingApplyConfigurationUpdatesStyleAndRendersMarkdown() {
        let view = STMarkdownStreamingTextView()
        let style = STMarkdownStyle(
            font: .systemFont(ofSize: 18, weight: .medium),
            textColor: .systemRed,
            lineHeight: 26,
            kern: 0.2
        )

        view.applyConfiguration(
            markdown: "Configured content",
            style: style,
            advancedRenderers: .empty,
            engine: STMarkdownEngine(),
            animated: false
        )

        XCTAssertEqual(view.rawMarkdown, "Configured content")
        XCTAssertEqual(view.attributedText.string, "Configured content")
        XCTAssertEqual(view.contentTextView.textColor, .systemRed)
    }

    func testStreamingPlainParagraphTailRemainsCharacterAnimated() {
        let view = STMarkdownStreamingTextView()
        view.tokenFadeDuration = 0.25
        (view.contentTextView as? STShimmerTextView)?.characterStaggerInterval = 0.02
        view.setMarkdown("Hello", animated: false)

        view.appendMarkdownFragment(" world", animated: true)

        let visible = view.contentTextView.attributedText ?? NSAttributedString()
        XCTAssertEqual(visible.string, "Hello world")
        let ns = visible.string as NSString
        let lastIndex = ns.length - 1
        XCTAssertLessThan(self.foregroundAlpha(in: visible, at: lastIndex), 0.5)
    }

    func testStreamingContainerThenContentDelaysOnlyTrailingInlineBlock() {
        let view = STMarkdownStreamingTextView()
        view.tokenFadeDuration = 0.25
        view.containerRevealGapDuration = 0.2
        (view.contentTextView as? STShimmerTextView)?.characterStaggerInterval = 0.02
        view.setMarkdown("Intro", animated: false)

        view.appendMarkdownFragment("\n\n> quoted line\n\nTail block", animated: true)

        let immediate = view.contentTextView.attributedText?.string ?? ""
        XCTAssertTrue(immediate.contains("quoted line"))
        XCTAssertFalse(immediate.contains("Tail block"))

        let exp = expectation(description: "wait for trailing inline block reveal scheduling")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)

        let delayed = view.contentTextView.attributedText?.string ?? ""
        XCTAssertTrue(delayed.contains("Tail block"))
    }

    func testStreamingSeparatorTailFallsBackToPreviousInlineBlockAnimation() {
        let view = STMarkdownStreamingTextView()
        view.tokenFadeDuration = 0.25
        (view.contentTextView as? STShimmerTextView)?.characterStaggerInterval = 0.02
        view.setMarkdown("Intro", animated: false)

        view.appendMarkdownFragment("\n\nTail block\n\n<div>ignored</div>", animated: true)

        let visible = view.contentTextView.attributedText ?? NSAttributedString()
        let text = visible.string as NSString
        let tailRange = text.range(of: "Tail block")
        XCTAssertNotEqual(tailRange.location, NSNotFound)
        XCTAssertLessThan(self.foregroundAlpha(in: visible, at: tailRange.location), 0.5)
    }

    func testSmartStreamingSecondCommittedFrameUsesIncrementalMergedRenderPath() {
        let view = STMarkdownStreamingTextView()
        view.tokenFadeDuration = 0
        view.markdownStyle.streamMinModuleLength = 1

        let p1 = String(repeating: "a", count: 98)
        let p2 = String(repeating: "b", count: 98)
        let p3 = String(repeating: "c", count: 98)
        let p4 = String(repeating: "d", count: 98)
        let p5 = String(repeating: "e", count: 98)

        view.beginSmartMarkdownStreaming()
        view.appendSmartMarkdownStreamingChunk([p1, p2, p3, p4].joined(separator: "\n\n") + "\n\n")
        XCTAssertEqual(view.lastSmartStreamingRenderMode, .full)

        view.appendSmartMarkdownStreamingChunk(p5 + "\n\n")

        XCTAssertEqual(view.lastSmartStreamingRenderMode, .incremental)
        let rendered = view.attributedText.string
        XCTAssertTrue(rendered.contains(p1))
        XCTAssertTrue(rendered.contains(p5))
    }

    func testSmartStreamingFinalConvergenceKeepsDuplicateHeadingAnchorsUnique() {
        let view = STMarkdownStreamingTextView()
        view.tokenFadeDuration = 0
        view.markdownStyle.streamMinModuleLength = 1

        view.beginSmartMarkdownStreaming()
        view.appendSmartMarkdownStreamingChunk("## Same\n\nBody 1\n\n")
        XCTAssertEqual(view.tableOfContents.map(\.anchorId), ["same"])

        view.appendSmartMarkdownStreamingChunk("## Same\n\nBody 2")
        view.appendSmartMarkdownStreamingChunk("\n\nTail 3\n\n")
        view.endSmartMarkdownStreaming(flushPending: true)

        XCTAssertEqual(view.tableOfContents.map(\.anchorId), ["same", "same-1"])
    }

    func testSmartStreamingIncrementalPathRespectsSanitizerCanonicalization() {
        let view = STMarkdownStreamingTextView()
        view.tokenFadeDuration = 0
        view.markdownStyle.streamMinModuleLength = 1

        view.beginSmartMarkdownStreaming()
        view.appendSmartMarkdownStreamingChunk("<a href=\"https://example.com\">Example</a>\n\n")
        XCTAssertEqual(view.attributedText.string, "Example")

        view.appendSmartMarkdownStreamingChunk("Tail\n\n")

        XCTAssertEqual(view.lastSmartStreamingRenderMode, .incremental)
        XCTAssertTrue(view.attributedText.string.contains("Example"))
        XCTAssertTrue(view.attributedText.string.contains("Tail"))
    }

    private func foregroundAlpha(in attributed: NSAttributedString, at index: Int) -> CGFloat {
        guard index >= 0, index < attributed.length else { return 1 }
        guard let color = attributed.attribute(.foregroundColor, at: index, effectiveRange: nil) as? UIColor else {
            return 1
        }
        return color.cgColor.alpha
    }
}
