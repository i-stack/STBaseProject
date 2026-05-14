//
//  STMarkdownTextKitPerformanceAndRegressionTests.swift
//
//  TextKit 1 (`usesTextLayoutManager = false`) vs TextKit 2 (`true`) 对比与交互回归。
//  性能指标通过 NSLog 输出前缀 `[TextKitPerf]`，便于在 Xcode / CI 日志中检索。
//

import XCTest
import UIKit
@testable import STBaseProject

@MainActor
private final class DisplayLinkFrameSampler: NSObject {
    private var link: CADisplayLink?
    private(set) var frameIntervals: [TimeInterval] = []
    private var lastTimestamp: CFTimeInterval = 0
    private var tickAction: (() -> Void)?

    func start(onTick: @escaping () -> Void) {
        self.stop()
        self.frameIntervals = []
        self.lastTimestamp = 0
        self.tickAction = onTick
        let dl = CADisplayLink(target: self, selector: #selector(handleDisplayLink(_:)))
        dl.preferredFrameRateRange = CAFrameRateRange(minimum: 60, maximum: 120, preferred: 60)
        dl.add(to: .main, forMode: .common)
        self.link = dl
    }

    func stop() {
        self.link?.invalidate()
        self.link = nil
        self.tickAction = nil
    }

    @objc private func handleDisplayLink(_ link: CADisplayLink) {
        if self.lastTimestamp > 0 {
            self.frameIntervals.append(TimeInterval(link.timestamp - self.lastTimestamp))
        }
        self.lastTimestamp = link.timestamp
        self.tickAction?()
    }
}

@MainActor
final class STMarkdownTextKitPerformanceAndRegressionTests: XCTestCase {

    private static func stressMarkdown(repeatCount: Int) -> String {
        (0..<repeatCount).map { i in
            """
            ## Section \(i)

            Paragraph \(i) with **bold** and `code` and a [link](https://example.com/\(i)).

            | Col A | Col B | Col C |
            |-------|:-----:|------:|
            | \(i)-1 | \(i)-2 | \(i)-3 |
            | x | y | z |

            Footnote ref[^fn\(i)].

            [^fn\(i)]: Footnote body for section \(i).

            """
        }.joined(separator: "\n")
    }

    private func hostScrollable(width: CGFloat, height: CGFloat, usesTK2: Bool) -> (UIWindow, STScrollableMarkdownView) {
        let bounds = CGRect(x: 0, y: 0, width: width, height: height)
        let window = UIWindow(frame: bounds)
        window.layer.speed = 1
        let vc = UIViewController()
        vc.view.bounds = bounds
        window.rootViewController = vc
        window.makeKeyAndVisible()

        let host = STScrollableMarkdownView(frame: vc.view.bounds, usesTextLayoutManager: usesTK2)
        host.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        vc.view.addSubview(host)
        return (window, host)
    }

    /// 首帧：setMarkdown → 首次 `layoutIfNeeded`；总布局：再跑若干轮直到 intrinsic 高度稳定。
    private func measureFirstFrameAndSettlingLayout(host: STScrollableMarkdownView, markdown: String) -> (
        firstFrame: TimeInterval,
        settleLayout: TimeInterval,
        finalHeight: CGFloat
    ) {
        let t0 = CACurrentMediaTime()
        host.setMarkdown(markdown)
        host.layoutIfNeeded()
        let t1 = CACurrentMediaTime()

        let settleStart = CACurrentMediaTime()
        var h = host.markdownTextView.intrinsicContentSize.height
        for _ in 0..<12 {
            host.layoutIfNeeded()
            let nh = host.markdownTextView.intrinsicContentSize.height
            if abs(nh - h) < 0.5 { break }
            h = nh
        }
        let t2 = CACurrentMediaTime()
        return (t1 - t0, t2 - settleStart, h)
    }

    private func percentile(_ values: [TimeInterval], p: Double) -> TimeInterval {
        guard values.isEmpty == false else { return 0 }
        let sorted = values.sorted()
        let idx = min(sorted.count - 1, max(0, Int((Double(sorted.count - 1) * p).rounded(.down))))
        return sorted[idx]
    }

    private func emitPerf(_ line: String) {
        print(line)
        fflush(stdout)
        let attachment = XCTAttachment(string: line)
        attachment.lifetime = .keepAlways
        self.add(attachment)
    }

    // MARK: - 1) 长文档：首帧 / 总布局 / 滚动帧间隔（拆成两条用例，便于 XCTAttachment 落盘到 .xcresult）

    private func runLongMarkdownLayoutAndScrollSample(usesTK2: Bool) {
        let md = Self.stressMarkdown(repeatCount: 24)
        let width: CGFloat = 390
        let height: CGFloat = 844

        let (window, host) = self.hostScrollable(width: width, height: height, usesTK2: usesTK2)
        defer { window.isHidden = true }

        let (first, settle, finalH) = self.measureFirstFrameAndSettlingLayout(host: host, markdown: md)
        host.layoutIfNeeded()
        let scroll = host.scrollView
        scroll.layoutIfNeeded()

        let sampler = DisplayLinkFrameSampler()
        let step: CGFloat = 9
        var ticks = 0
        sampler.start {
            ticks += 1
            let maxY = max(0, scroll.contentSize.height - scroll.bounds.height)
            let y = min(maxY, scroll.contentOffset.y + step)
            scroll.setContentOffset(CGPoint(x: 0, y: y), animated: false)
            if ticks >= 90 || (maxY <= 0 && ticks > 5) {
                sampler.stop()
            }
        }
        let exp = expectation(description: "scroll sampling")
        exp.assertForOverFulfill = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            sampler.stop()
            exp.fulfill()
        }
        wait(for: [exp], timeout: 3)

        let iv = sampler.frameIntervals
        let median = iv.isEmpty ? 0 : iv.sorted()[iv.count / 2]
        let p95 = self.percentile(iv, p: 0.95)
        let jankFrames = iv.filter { $0 > (1.0 / 50.0) * 1.45 }.count

        let mode = usesTK2 ? "TK2" : "TK1"
        self.emitPerf(
            String(
                format: "[TextKitPerf] long-md mode=%@ firstFrameMs=%.2f settleLayoutMs=%.2f finalHeight=%.1f scrollSamples=%ld medianFrameMs=%.3f p95FrameMs=%.3f jankishFrames=%ld",
                mode,
                first * 1000,
                settle * 1000,
                finalH,
                iv.count,
                median * 1000,
                p95 * 1000,
                jankFrames
            )
        )

        XCTAssertGreaterThan(finalH, 200, "应测得显著正文高度 (\(mode))")
    }

    func testLongMarkdown_LayoutAndScrollMetrics_TextKit1() {
        self.runLongMarkdownLayoutAndScrollSample(usesTK2: false)
    }

    func testLongMarkdown_LayoutAndScrollMetrics_TextKit2() {
        self.runLongMarkdownLayoutAndScrollSample(usesTK2: true)
    }

    // MARK: - 2) 流式 append：每 chunk 耗时、显式 layout 轮数、intrinsic 高度抖动

    func testStreamingAppend_PerChunkMetrics_TK1_vs_TK2() {
        let chunks = (0..<40).map { i in "Line \(i): **bold** and [l](https://e.com) | `c`  \n" }
        let width: CGFloat = 360

        for usesTK2 in [false, true] {
            var heightSeries: [CGFloat] = []
            var wallMs: [TimeInterval] = []
            var layoutPasses: [Int] = []

            let window = UIWindow(frame: CGRect(x: 0, y: 0, width: width, height: 800))
            let vc = UIViewController()
            window.rootViewController = vc
            window.makeKeyAndVisible()
            defer { window.isHidden = true }

            let stream = STMarkdownStreamingTextView(frame: vc.view.bounds, usesTextLayoutManager: usesTK2)
            stream.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            stream.tokenFadeDuration = 0
            stream.characterStaggerInterval = 0
            stream.animateAcrossNewlines = false
            vc.view.addSubview(stream)

            for chunk in chunks {
                let t0 = CACurrentMediaTime()
                stream.appendMarkdownFragment(chunk, animated: false)
                var passes = 0
                var h0 = stream.intrinsicContentSize.height
                for _ in 0..<8 {
                    stream.layoutIfNeeded()
                    passes += 1
                    let h1 = stream.intrinsicContentSize.height
                    if abs(h1 - h0) < 0.25 { break }
                    h0 = h1
                }
                wallMs.append((CACurrentMediaTime() - t0) * 1000)
                layoutPasses.append(passes)
                heightSeries.append(stream.intrinsicContentSize.height)
            }

            let jitters = zip(heightSeries, heightSeries.dropFirst()).map { abs($1 - $0) }
            let maxJitter = jitters.max() ?? 0
            let sumWall = wallMs.reduce(0, +)
            let mode = usesTK2 ? "TK2" : "TK1"
            self.emitPerf(
                String(
                    format: "[TextKitPerf] stream mode=%@ chunks=%ld totalWallMs=%.2f maxHeightJitter=%.2f avgLayoutPasses=%.2f",
                    mode,
                    chunks.count,
                    sumWall,
                    maxJitter,
                    Double(layoutPasses.reduce(0, +)) / Double(max(layoutPasses.count, 1))
                )
            )

            XCTAssertGreaterThan(heightSeries.last ?? 0, 100)
        }
    }

    // MARK: - 3) 交互回归（TK2）：链接 / 脚注 / 选区 / 表格相关富文本非空

    func testTextKit2_LinkFootnoteSelectionAndTableRenderRegression() {
        let md = """
        | a | b |
        |---|---|
        | 1 | 2 |

        Tap [Example](https://example.org) and foot[^f].

        [^f]: Note **body**.
        """
        let view = STMarkdownTextView(frame: CGRect(x: 0, y: 0, width: 320, height: 600), usesTextLayoutManager: true)
        view.setMarkdown(md)

        var linkURL: URL?
        view.onLinkTap = { linkURL = $0 }
        var footLabel: String?
        view.onFootnoteTap = { footLabel = $0 }

        let example = URL(string: "https://example.org")!
        _ = view.textView(
            view.contentTextView,
            shouldInteractWith: example,
            in: NSRange(location: 0, length: 1),
            interaction: .invokeDefaultAction
        )
        XCTAssertEqual(linkURL, example)

        let fnURL = URL(string: "stmarkdown-footnote://f")!
        _ = view.textView(
            view.contentTextView,
            shouldInteractWith: fnURL,
            in: NSRange(location: 0, length: 1),
            interaction: .invokeDefaultAction
        )
        XCTAssertEqual(footLabel, "f")

        var selectionText: String?
        view.onSelectionChange = { selectionText = $0 }
        view.contentTextView.selectedRange = NSRange(location: 0, length: min(4, view.attributedText.length))
        view.textViewDidChangeSelection(view.contentTextView)
        XCTAssertFalse(selectionText?.isEmpty ?? true)

        XCTAssertTrue(view.attributedText.string.contains("1"), "表格单元应出现在可见字符串中")
        XCTAssertGreaterThan(view.intrinsicContentSize.height, 40)
    }
}

// MARK: - STMarkdownStreamingTextView 测试扩展（仅本测试 target）

private extension STMarkdownStreamingTextView {
    /// 测试里压低流式动画 CPU：`STShimmerTextView` 的 stagger 间隔。
    var characterStaggerInterval: TimeInterval {
        get { self.shimmerTextViewForTests.characterStaggerInterval }
        set { self.shimmerTextViewForTests.characterStaggerInterval = newValue }
    }

    private var shimmerTextViewForTests: STShimmerTextView {
        self.contentTextView as! STShimmerTextView
    }
}
