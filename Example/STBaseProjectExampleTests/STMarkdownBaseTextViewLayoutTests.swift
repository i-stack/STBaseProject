import XCTest
import UIKit
@testable import STBaseProject

/// 验证 ``STMarkdownBaseTextView`` 在 Cell 未布局完成时的测量宽度回退与高度回调节流（对齐流式 Cell 稳定性加强）。
@MainActor
final class STMarkdownBaseTextViewLayoutTests: XCTestCase {

    func testResolvedMeasurementWidthFallsBackToTextViewFrameWhenBoundsZero() {
        let view = STMarkdownTextView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        view.preferredContentWidth = 0
        view.bounds = .zero
        view.textView.frame = CGRect(x: 0, y: 0, width: 320, height: 44)
        XCTAssertEqual(view.resolvedMarkdownMeasurementWidth(), 320, accuracy: 0.01)
    }

    func testContentLayoutHeightNotificationRespectsMinIntervalUnlessForced() {
        let view = STMarkdownTextView(frame: CGRect(x: 0, y: 0, width: 300, height: 400))
        view.contentLayoutHeightNotificationThreshold = 0
        view.contentLayoutHeightNotificationMinInterval = 10
        view.setMarkdown("# Hello\n\nSome body text for height.")

        var invocations = 0
        view.onContentLayoutHeightChange = { _ in
            invocations += 1
        }

        view.publishContentLayoutHeightNotificationIfNeeded(force: false)
        XCTAssertEqual(invocations, 1)

        view.publishContentLayoutHeightNotificationIfNeeded(force: false)
        XCTAssertEqual(invocations, 1, "节流期内不应重复触发")

        view.publishContentLayoutHeightNotificationIfNeeded(force: true)
        XCTAssertEqual(invocations, 2, "force 应绕过时间节流")
    }
}
