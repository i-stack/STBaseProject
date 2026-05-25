//
//  STMarkdownStreamingHeightStabilityTests.swift
//  STBaseProjectExampleTests
//
//  流式逐字输出场景下：测量 intrinsic 高度与高度回调的稳定性（单调性、动画期无振荡、节流生效）。
//

import XCTest
import UIKit
@testable import STBaseProject

@MainActor
final class STMarkdownStreamingHeightStabilityTests: XCTestCase {

    private func shimmer(for stream: STMarkdownStreamingTextView) -> STShimmerTextView {
        stream.contentTextView as! STShimmerTextView
    }

    /// 多次 `layoutIfNeeded` 直到 intrinsic 高度在容差内收敛（对齐 TextKit 性能测试中的做法）。
    @discardableResult
    private func settleIntrinsicHeight(for view: STMarkdownStreamingTextView, maxPasses: Int = 16) -> CGFloat {
        var height = view.intrinsicContentSize.height
        for _ in 0..<maxPasses {
            view.layoutIfNeeded()
            let next = view.intrinsicContentSize.height
            if abs(next - height) < 0.25 {
                return next
            }
            height = next
        }
        return height
    }

    private func makeKeyWindowHost(width: CGFloat, height: CGFloat) -> (UIWindow, UIViewController, STMarkdownStreamingTextView) {
        let bounds = CGRect(x: 0, y: 0, width: width, height: height)
        let window = UIWindow(frame: bounds)
        let vc = UIViewController()
        vc.view.bounds = bounds
        window.rootViewController = vc
        window.makeKeyAndVisible()

        let stream = STMarkdownStreamingTextView(frame: vc.view.bounds)
        stream.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        stream.preferredContentWidth = width
        vc.view.addSubview(stream)
        return (window, vc, stream)
    }

    /// 逐字追加纯文本（无 Markdown 定界符），开启 stagger：稳定后高度应单调不减。
    func testPerCharacterStreamingIntrinsicHeightMonotonicPlainText() {
        let (window, _, stream) = self.makeKeyWindowHost(width: 360, height: 900)
        defer { window.isHidden = true }

        stream.tokenFadeDuration = 0.06
        self.shimmer(for: stream).characterStaggerInterval = 0.002
        stream.animateAcrossNewlines = true

        var heights: [CGFloat] = []
        let sentence = "Streaming plain characters without markdown tokens."
        for ch in sentence {
            stream.appendMarkdownFragment(String(ch), animated: true)
            heights.append(self.settleIntrinsicHeight(for: stream))
        }
        stream.finishStreaming()

        for i in 1..<heights.count {
            XCTAssertGreaterThanOrEqual(
                heights[i],
                heights[i - 1] - 0.5,
                "intrinsic 高度不应在纯文本前缀增长时出现明显下降 @index=\(i) prev=\(heights[i - 1]) cur=\(heights[i])"
            )
        }
        XCTAssertGreaterThan(heights.last ?? 0, 20)
    }

    /// 单次大块 append 后仅颜色 stagger：排版高度在若干帧内应保持恒定（无上下振荡）。
    func testIntrinsicHeightStableWhileStaggerFadeRuns() {
        let (window, _, stream) = self.makeKeyWindowHost(width: 340, height: 900)
        defer { window.isHidden = true }

        stream.tokenFadeDuration = 0.25
        self.shimmer(for: stream).characterStaggerInterval = 0.012
        stream.animateAcrossNewlines = true

        stream.setMarkdown("", animated: false)
        stream.appendMarkdownFragment(String(repeating: "Typewriter ", count: 25), animated: true)

        var samples: [CGFloat] = []
        for _ in 0..<45 {
            stream.layoutIfNeeded()
            samples.append(stream.intrinsicContentSize.height)
            RunLoop.current.run(until: Date().addingTimeInterval(0.012))
        }

        let minH = samples.min() ?? 0
        let maxH = samples.max() ?? 0
        XCTAssertLessThanOrEqual(
            maxH - minH,
            2.0,
            "stagger 仅改 foregroundColor 时 intrinsic 高度不应明显振荡 spread=\(maxH - minH) samples=\(samples.prefix(5))…"
        )

        stream.finishStreaming()
    }

    /// 智能流式：多 chunk 追加后稳定高度仍应整体单调不减（阈值容差内）。
    func testSmartStreamingCommittedPrefixIntrinsicHeightMonotonic() {
        let (window, _, stream) = self.makeKeyWindowHost(width: 320, height: 900)
        defer { window.isHidden = true }

        stream.tokenFadeDuration = 0
        self.shimmer(for: stream).characterStaggerInterval = 0

        stream.beginSmartMarkdownStreaming()
        let chunks = [
            "# Stream Title\n\n",
            "First paragraph with **bold** and more text.\n\n",
            "## Section\n",
            "- item one\n",
            "- item two\n",
        ]
        var heights: [CGFloat] = []
        for chunk in chunks {
            stream.appendSmartMarkdownStreamingChunk(chunk)
            heights.append(self.settleIntrinsicHeight(for: stream))
        }
        stream.endSmartMarkdownStreaming(flushPending: true)
        let finalH = self.settleIntrinsicHeight(for: stream)
        heights.append(finalH)

        for i in 1..<heights.count {
            XCTAssertGreaterThanOrEqual(
                heights[i],
                heights[i - 1] - 1.0,
                "智能流式累积展示前缀时高度不应回退 @i=\(i)"
            )
        }
        XCTAssertGreaterThan(finalH, 80)
    }

    /// `contentLayoutHeightNotificationThreshold` 应减少小步高频回调次数。
    func testHeightChangeCallbackRespectsThresholdDuringStreaming() {
        let (window, _, stream) = self.makeKeyWindowHost(width: 300, height: 800)
        defer { window.isHidden = true }

        stream.tokenFadeDuration = 0
        self.shimmer(for: stream).characterStaggerInterval = 0
        stream.contentLayoutHeightNotificationThreshold = 72
        stream.contentLayoutHeightNotificationMinInterval = 0

        stream.setMarkdown("# H\n\n", animated: false)
        _ = self.settleIntrinsicHeight(for: stream)

        // 须在首帧渲染之后再挂回调：`setMarkdown` 已会触发一次 `finalizeRenderUpdate` 内的高度发布。
        var callbackCount = 0
        stream.onContentLayoutHeightChange = { _ in
            callbackCount += 1
        }

        stream.publishContentLayoutHeightNotificationIfNeeded(force: true)
        XCTAssertEqual(callbackCount, 1)

        // 每行增高约一行高；大阈值下多次 append 才触发一次「可通知」变化。
        for i in 0..<12 {
            stream.appendMarkdownFragment("Line \(i) of plain text for vertical growth.\n", animated: false)
            _ = self.settleIntrinsicHeight(for: stream)
            stream.publishContentLayoutHeightNotificationIfNeeded(force: false)
        }

        XCTAssertLessThanOrEqual(
            callbackCount,
            6,
            "大阈值下高度回调次数应明显少于 append 次数，避免外层布局抖动 actual=\(callbackCount)"
        )
        XCTAssertGreaterThanOrEqual(callbackCount, 1, "至少应有一次 force 高度回调")
    }
}
