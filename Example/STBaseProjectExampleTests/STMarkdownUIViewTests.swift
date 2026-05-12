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
}
