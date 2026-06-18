//
//  STStreamingBurstScheduler.swift
//  STMarkdown
//

import Foundation
import STBaseProject

/// 突释分帧调度器。
/// 用于在流式 markdown 渲染中，当 presentation 尾部出现大段突释（如 emphasis 闭合、citation 标签）时，
/// 将一次释放拆分为多个小步，降低单次高度跃迁带来的视觉抖动。
public final class STStreamingBurstScheduler {
    private var threshold: Int = 15
    private var smallStep: Int = 8
    private var largeStep: Int = 15

    public init() {}

    public func configure(threshold: Int, smallStep: Int, largeStep: Int) {
        self.threshold = max(1, threshold)
        self.smallStep = max(1, smallStep)
        self.largeStep = max(self.smallStep, largeStep)
    }

    public var burstReleaseThreshold: Int { self.threshold }
    public var burstReleaseSmallStep: Int { self.smallStep }
    public var burstReleaseLargeStep: Int { self.largeStep }

    /// 计算一步 drain 的结果。调用方负责应用 presentation、通知高度、并在 shouldContinue 为 true 时调度下一步。
    public func step(
        current: String,
        target: String,
        activeBlockKind: STMarkdownStreamingBlockKind?
    ) -> BurstStepResult {
        guard target.count > current.count else {
            return BurstStepResult(presentation: nil, shouldContinue: false)
        }
        let remaining = target.count - current.count
        let stepSize = remaining >= 30 ? self.largeStep : self.smallStep
        let nextCount = min(current.count + stepSize, target.count)
        let stepped = Self.sanitizeSteppedPresentation(
            String(target.prefix(nextCount)),
            activeBlockKind: activeBlockKind
        )
        if stepped != current {
            if !current.isEmpty, stepped.count < current.count {
                let fullStepped = Self.sanitizeSteppedPresentation(target, activeBlockKind: activeBlockKind)
                let presentation = fullStepped.count >= current.count ? fullStepped : nil
                return BurstStepResult(presentation: presentation, shouldContinue: false)
            }
            return BurstStepResult(presentation: stepped, shouldContinue: stepped.count < target.count)
        }
        return BurstStepResult(presentation: nil, shouldContinue: stepped.count < target.count)
    }

    public static func sanitizeSteppedPresentation(
        _ text: String,
        activeBlockKind: STMarkdownStreamingBlockKind?
    ) -> String {
        guard !text.isEmpty else { return text }
        switch activeBlockKind {
        case .paragraph, .list, .quote, .heading, nil:
            let presentation = STMarkdownStreamingPresenter.makeActiveStreamingBlockPresentation(from: text)
            guard activeBlockKind == .list else { return presentation }
            let trimmedMarker = STMarkdownStreamingTransforms.trimTrailingListMarkerWithDanglingEmphasis(in: presentation)
            let softenedLeading = STMarkdownStreamingTransforms.softenTrailingListLeadingDanglingEmphasis(in: trimmedMarker)
            return STMarkdownStreamingTransforms.sanitizeDanglingInlineMarkdownFragments(in: softenedLeading)
        case .table:
            return STMarkdownStreamingPresenter.makeLiveReplyStreamingActivePresentation(from: text, kind: .table)
        case .fencedCode:
            return text.hasSuffix("```") || text.hasSuffix("~~~") ? text : ""
        case .thematicBreak:
            return ""
        }
    }

    public static func shouldStepBurstRelease(for kind: STMarkdownStreamingBlockKind?) -> Bool {
        switch kind {
        case .none, .some(.paragraph):
            return true
        case .some(.heading), .some(.list), .some(.table), .some(.quote), .some(.fencedCode), .some(.thematicBreak):
            return false
        }
    }
}

public struct BurstStepResult {
    public let presentation: String?
    public let shouldContinue: Bool

    public init(presentation: String?, shouldContinue: Bool) {
        self.presentation = presentation
        self.shouldContinue = shouldContinue
    }
}