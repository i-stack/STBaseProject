//
//  STMarkdownStreamingTextView.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2019/03/16.
//

import UIKit

public final class STMarkdownStreamingTextView: STMarkdownBaseTextView {
    internal enum SmartStreamingRenderMode {
        case full
        case incremental
    }

    private struct PendingAnimatedSuffix {
        let generation: Int
        let suffix: NSAttributedString
        let trailingSuffix: NSAttributedString?
    }

    public var tokenFadeDuration: TimeInterval {
        get { self.shimmerTextView.tokenFadeDuration }
        set {
            _requestedTokenFadeDuration = newValue
            self.shimmerTextView.tokenFadeDuration = self.markdownStyle.streamFadeInEnabled ? newValue : 0
        }
    }

    public var customDocumentRenderer: ((STMarkdownRenderDocument) -> NSAttributedString)?

    public var suppressSystemTextMenu: Bool {
        get { self.shimmerTextView.suppressSystemTextMenu }
        set { self.shimmerTextView.suppressSystemTextMenu = newValue }
    }

    public var animateAcrossNewlines: Bool {
        get { self.shimmerTextView.animateAcrossNewlines }
        set { self.shimmerTextView.animateAcrossNewlines = newValue }
    }

    /// 流式动画 / 容器尾段延迟追加的兜底超时；超时后强制收口，避免宿主一直等不到完成态。
    public var streamingAnimationWatchdogTimeout: TimeInterval = 4.0

    private var smartStreamBuffer: STMarkdownStreamBuffer?
    private var smartStreamingSessionActive = false
    private var isApplyingSmartStreamMarkdownUpdate = false
    private var streamingAnimationGeneration: Int = 0
    private var pendingStreamingSuffixWorkItem: DispatchWorkItem?
    private var pendingAnimatedSuffix: PendingAnimatedSuffix?
    private var streamingWatchdogWorkItem: DispatchWorkItem?
    private var streamingWatchdogGeneration: Int = 0
    /// tokenFadeDuration 最后一次被外部请求设置的值；样式允许 fade 时以此值写入 shimmerTextView。
    private var _requestedTokenFadeDuration: TimeInterval = 0.3
    /// 上一帧已交给 ``setMarkdown(_:animated:)`` 的「安全前缀」展示串（经 ``stripUnclosedTailMarkers``）。
    /// 当缓冲器仅增长尾部、``committedSafePrefix`` 不变时跳过整段重解析，降低流式 CPU 占用（对齐对比文档 P0）。
    private var lastSmartStreamRenderedDisplayMarkdown: String?
    private var lastSmartStreamRenderedCanonicalMarkdown: String?
    private var lastSmartStreamRenderDocument: STMarkdownRenderDocument?
    internal private(set) var lastSmartStreamingRenderMode: SmartStreamingRenderMode?

    /// 是否处于 ``beginSmartMarkdownStreaming()`` 开启的智能缓冲流式会话中。
    public var isSmartMarkdownStreamingActive: Bool {
        self.smartStreamingSessionActive
    }

    /// true 表示没有待执行的容器延迟尾段，也没有进行中的文本 reveal 动画。
    public var isStreamingAnimationIdle: Bool {
        self.pendingAnimatedSuffix == nil && self.shimmerTextView.isAnimatingTextReveal == false
    }

    /// 会话中的完整累积 Markdown（含尚未通过模块检测的尾部）；非会话中为 `nil`。
    public var smartStreamingAccumulatedText: String? {
        self.smartStreamBuffer?.fullAccumulatedText
    }

    /// `containerThenContent` 命中时，容器/块级前缀先上屏，再等待这一小段间隔后让尾部正文继续逐字动画。
    public var containerRevealGapDuration: TimeInterval = 0.06

    private var shimmerTextView: STShimmerTextView {
        guard let textView = self.textView as? STShimmerTextView else {
            preconditionFailure("STMarkdownStreamingTextView requires STShimmerTextView")
        }
        return textView
    }

    public override var attributedText: NSAttributedString {
        self.shimmerTextView.renderedAttributedText
    }

    internal override var currentAttributedText: NSAttributedString {
        self.shimmerTextView.renderedAttributedText
    }

    public init(frame: CGRect, usesTextLayoutManager: Bool = true) {
        super.init(
            textView: STShimmerTextView(usingTextLayoutManager: usesTextLayoutManager),
            frame: frame,
            style: .default,
            advancedRenderers: .empty,
            engine: STMarkdownEngine(),
            accessibilityTraits: [.staticText, .updatesFrequently]
        )
        self.installStreamingAnimationObservers()
    }

    public convenience init(
        style: STMarkdownStyle = .default,
        advancedRenderers: STMarkdownAdvancedRenderers = .empty,
        engine: STMarkdownEngine = STMarkdownEngine(),
        usesTextLayoutManager: Bool = true
    ) {
        self.init(frame: .zero, usesTextLayoutManager: usesTextLayoutManager)
        self.applyConfigurationCommon(
            style: style,
            advancedRenderers: advancedRenderers,
            engine: engine
        )
    }

    public required init?(coder: NSCoder) {
        super.init(
            textView: STShimmerTextView(usingTextLayoutManager: true),
            coder: coder,
            style: .default,
            advancedRenderers: .empty,
            engine: STMarkdownEngine(),
            accessibilityTraits: [.staticText, .updatesFrequently]
        )
        self.installStreamingAnimationObservers()
    }

    public func reset() {
        self.invalidatePendingStreamingAnimation()
        self.invalidateStreamingAnimationWatchdog()
        self.cancelSmartMarkdownStreamingSession()
        self.shimmerTextView.reset()
        self.resetBaseState()
    }

    public func finishStreaming() {
        self.flushPendingAnimatedSuffixIfNeeded()
        self.shimmerTextView.finishAnimations()
        self.invalidateStreamingAnimationWatchdog()
        self.finalizeRenderUpdate(rendered: self.shimmerTextView.renderedAttributedText)
    }

    public func setMarkdown(_ markdown: String, animated: Bool = false) {
        self.invalidatePendingStreamingAnimation()
        if self.smartStreamingSessionActive && !self.isApplyingSmartStreamMarkdownUpdate {
            self.cancelSmartMarkdownStreamingSession()
        }
        let markdownForRender = animated
            ? Self.stripUnclosedTailMarkers(in: markdown)
            : markdown
        let displayRendered = self.render(markdownForRender)
        self.applySetMarkdownAnimatedDiff(markdown: markdown, displayRendered: displayRendered, animated: animated)
    }

    private func applySetMarkdownAnimatedDiff(
        markdown: String,
        displayRendered: NSAttributedString,
        animated: Bool
    ) {
        guard animated, !self.rawMarkdown.isEmpty else {
            self.applyFullReplace(markdown: markdown, rendered: displayRendered)
            return
        }

        let current = self.shimmerTextView.renderedAttributedText
        let currentStr = current.string
        let renderedStr = displayRendered.string

        if renderedStr.utf16.count >= currentStr.utf16.count,
           (renderedStr as NSString).hasPrefix(currentStr) {
            let prefixChanged = current.length > 0
                && !displayRendered.attributedSubstring(
                    from: NSRange(location: 0, length: current.length)
                ).isEqual(to: current)
            if prefixChanged {
                self.applyFullReplace(markdown: markdown, rendered: displayRendered)
                return
            }
            let deltaLen = displayRendered.length - current.length
            if deltaLen > 0 {
                let delta = displayRendered.attributedSubstring(
                    from: NSRange(location: current.length, length: deltaLen)
                )
                self.applyAppendDelta(markdown: markdown, delta: delta)
            } else {
                self.rawMarkdown = markdown
                self.textView.accessibilityValue = self.shimmerTextView.renderedAttributedText.string
            }
            return
        }

        let commonLen = currentStr.commonPrefix(with: renderedStr).utf16.count
        if commonLen > 0 {
            let commonPrefixChanged = !current.attributedSubstring(
                from: NSRange(location: 0, length: commonLen)
            ).isEqual(to: displayRendered.attributedSubstring(
                from: NSRange(location: 0, length: commonLen)
            ))
            let listMarkerInvolved = self.shouldDisableAnimationForTrailingReplacement(
                current: current,
                rendered: displayRendered,
                commonLength: commonLen
            )
            if commonPrefixChanged {
                self.applyFullReplace(markdown: markdown, rendered: displayRendered)
            } else if listMarkerInvolved {
                let replaceStart = self.replacementStartForListTransition(
                    currentString: currentStr,
                    commonLength: commonLen
                )
                let trailing = displayRendered.attributedSubstring(
                    from: NSRange(location: replaceStart, length: displayRendered.length - replaceStart)
                )
                self.applyTrailingReplace(
                    markdown: markdown,
                    from: replaceStart,
                    trailing: trailing,
                    animate: false
                )
            } else {
                let trailing = displayRendered.attributedSubstring(
                    from: NSRange(location: commonLen, length: displayRendered.length - commonLen)
                )
                self.applyTrailingReplace(
                    markdown: markdown,
                    from: commonLen,
                    trailing: trailing,
                    animate: true
                )
            }
            return
        }

        self.applyFullReplace(markdown: markdown, rendered: displayRendered)
    }

    public func applyConfiguration(
        markdown: String,
        style: STMarkdownStyle,
        advancedRenderers: STMarkdownAdvancedRenderers,
        engine: STMarkdownEngine,
        animated: Bool
    ) {
        self.applyConfigurationCommon(
            style: style,
            advancedRenderers: advancedRenderers,
            engine: engine
        )
        self.setMarkdown(markdown, animated: animated)
    }

    public func appendMarkdownFragment(_ fragment: String, animated: Bool = true) {
        guard fragment.isEmpty == false else { return }
        if self.smartStreamingSessionActive {
            self.appendSmartMarkdownStreamingChunk(fragment)
            return
        }
        self.setMarkdown(self.rawMarkdown + fragment, animated: animated)
    }

    public func updateStreamingMarkdown(_ fullMarkdown: String) {
        self.cancelSmartMarkdownStreamingSession()
        self.setMarkdown(fullMarkdown, animated: true)
    }

    /// 开始智能流式会话：先 ``reset()``，再用 ``STMarkdownStreamBuffer`` 按安全模块边界累积 chunk。
    public func beginSmartMarkdownStreaming() {
        self.reset()
        self.smartStreamBuffer = STMarkdownStreamBuffer(
            minModuleLength: self.markdownStyle.streamMinModuleLength
        )
        self.smartStreamingSessionActive = true
    }

    /// 向智能流式缓冲追加一段 chunk 并刷新显示（仅显示已通过检测的安全前缀 + 尾部裁剪）。
    public func appendSmartMarkdownStreamingChunk(_ chunk: String) {
        guard chunk.isEmpty == false else { return }
        guard self.smartStreamingSessionActive, let buffer = self.smartStreamBuffer else {
            self.setMarkdown(self.rawMarkdown + chunk, animated: true)
            return
        }
        buffer.updateMinModuleLength(self.markdownStyle.streamMinModuleLength)
        _ = buffer.append(chunk)
        self.applySmartStreamingPresentation(animated: true)
    }

    /// 结束智能流式会话；默认 ``flush`` 后按完整累积文本做一次非动画收敛。
    public func endSmartMarkdownStreaming(flushPending: Bool = true) {
        guard self.smartStreamingSessionActive, let buffer = self.smartStreamBuffer else { return }
        if flushPending {
            _ = buffer.flush()
        }
        let snapshot = buffer.fullAccumulatedText
        self.smartStreamBuffer = nil
        self.smartStreamingSessionActive = false
        self.lastSmartStreamRenderedDisplayMarkdown = nil
        self.lastSmartStreamRenderedCanonicalMarkdown = nil
        self.lastSmartStreamRenderDocument = nil
        self.lastSmartStreamingRenderMode = nil
        let md = Self.stripUnclosedTailMarkers(in: snapshot)
        self.isApplyingSmartStreamMarkdownUpdate = true
        defer { self.isApplyingSmartStreamMarkdownUpdate = false }
        self.setMarkdown(md, animated: false)
        self.rawMarkdown = snapshot
        self.invalidateStreamingAnimationWatchdog()
        self.publishContentLayoutHeightNotificationIfNeeded(force: true)
    }

    internal override func configurationDidChangeRerender() {
        self.syncTokenFadeDurationFromStyle()
        if self.smartStreamingSessionActive {
            self.smartStreamBuffer?.updateMinModuleLength(self.markdownStyle.streamMinModuleLength)
            self.applySmartStreamingPresentation(animated: false, force: true)
        } else {
            self.setMarkdown(self.rawMarkdown, animated: false)
        }
    }

    private func cancelSmartMarkdownStreamingSession() {
        self.smartStreamBuffer = nil
        self.smartStreamingSessionActive = false
        self.lastSmartStreamRenderedDisplayMarkdown = nil
        self.lastSmartStreamRenderedCanonicalMarkdown = nil
        self.lastSmartStreamRenderDocument = nil
        self.lastSmartStreamingRenderMode = nil
    }

    internal override func applyConfigurationCommon(
        style: STMarkdownStyle,
        advancedRenderers: STMarkdownAdvancedRenderers,
        engine: STMarkdownEngine
    ) {
        super.applyConfigurationCommon(style: style, advancedRenderers: advancedRenderers, engine: engine)
        self.syncTokenFadeDurationFromStyle()
    }

    private func syncTokenFadeDurationFromStyle() {
        let isLineFade = self.markdownStyle.streamFadeInEnabled && self.markdownStyle.streamLineFadeEnabled
        self.shimmerTextView.lineFadeMode = isLineFade
        self.shimmerTextView.tokenFadeDuration = (self.markdownStyle.streamFadeInEnabled && !isLineFade)
            ? _requestedTokenFadeDuration
            : 0
    }

    private func applySmartStreamingPresentation(animated: Bool, force: Bool = false) {
        guard let buffer = self.smartStreamBuffer else { return }
        let accumulated = buffer.fullAccumulatedText
        let committed = buffer.committedSafePrefix
        let md = Self.stripUnclosedTailMarkers(in: committed)
        if force == false, md == self.lastSmartStreamRenderedDisplayMarkdown {
            self.rawMarkdown = accumulated
            return
        }
        self.isApplyingSmartStreamMarkdownUpdate = true
        defer { self.isApplyingSmartStreamMarkdownUpdate = false }
        let rendered = self.renderSmartStreamingDisplayMarkdown(md, forceFull: force)
        self.applySetMarkdownAnimatedDiff(markdown: md, displayRendered: rendered, animated: animated)
        self.lastSmartStreamRenderedDisplayMarkdown = md
        self.rawMarkdown = accumulated
    }

    private func renderSmartStreamingDisplayMarkdown(_ markdown: String, forceFull: Bool) -> NSAttributedString {
        let canonicalMarkdown = self.canonicalMarkdownForIncremental(from: markdown)

        if forceFull == false,
           let previousCanonical = self.lastSmartStreamRenderedCanonicalMarkdown,
           let previousDocument = self.lastSmartStreamRenderDocument,
           previousCanonical.isEmpty == false,
           canonicalMarkdown.count >= previousCanonical.count,
           canonicalMarkdown.hasPrefix(previousCanonical) {
            let incremental = self.engine.processIncremental(
                STMarkdownIncrementalParameters(
                    canonicalMarkdown: canonicalMarkdown,
                    lastCommittedExclusiveEnd: previousCanonical.count,
                    currentSafeExclusiveEnd: canonicalMarkdown.count,
                    contextWindowSize: 200,
                    previousTotalRenderBlockCount: previousDocument.blocks.count
                )
            )
            let mergedDocument = self.normalizedMergedIncrementalRenderDocument(
                incremental.mergedRenderDocument(previous: previousDocument)
            )
            self.updateTableOfContents(from: mergedDocument)
            self.lastSmartStreamRenderedCanonicalMarkdown = canonicalMarkdown
            self.lastSmartStreamRenderDocument = mergedDocument
            self.lastSmartStreamingRenderMode = .incremental
            return self.render(document: mergedDocument)
        }

        let (rendered, renderDocument) = self.renderWithDocument(markdown)
        self.lastSmartStreamRenderedCanonicalMarkdown = canonicalMarkdown
        self.lastSmartStreamRenderDocument = renderDocument
        self.lastSmartStreamingRenderMode = .full
        return rendered
    }

    private func canonicalMarkdownForIncremental(from markdown: String) -> String {
        let configuration = self.engine.pipeline.configuration
        guard configuration.enableInputSanitizer else {
            return markdown
        }
        let sanitizer = STMarkdownInputSanitizer(rules: configuration.sanitizerRules)
        return sanitizer.sanitize(markdown, debug: configuration.debug).sanitizedText
    }

    private func render(document: STMarkdownRenderDocument) -> NSAttributedString {
        if let customRenderer = self.customDocumentRenderer {
            return customRenderer(document)
        }
        return self.renderer.render(document: document)
    }

    private func normalizedMergedIncrementalRenderDocument(
        _ document: STMarkdownRenderDocument
    ) -> STMarkdownRenderDocument {
        var slugger = STMarkdownAnchorSlugRegistry()
        let blocks = document.blocks.enumerated().map {
            self.normalizedMergedRenderBlock(
                $0.element,
                path: ["b:\($0.offset)"],
                slugger: &slugger
            )
        }
        return STMarkdownRenderDocument(blocks: blocks)
    }

    private func normalizedMergedRenderBlock(
        _ block: STMarkdownRenderBlock,
        path: [String],
        slugger: inout STMarkdownAnchorSlugRegistry
    ) -> STMarkdownRenderBlock {
        switch block {
        case .paragraph(let metadata, let inlines):
            return .paragraph(
                self.rebasedMetadata(metadata, kind: .paragraph, path: path),
                inlines
            )
        case .heading(let metadata, level: let level, anchorId: _, content: let content):
            let anchorId = slugger.uniqueAnchorId(forPlainTitle: content.st_plainTextForTOC())
            return .heading(
                self.rebasedMetadata(metadata, kind: .heading, path: path),
                level: level,
                anchorId: anchorId,
                content: content
            )
        case .quote(let metadata, let blocks):
            return .quote(
                self.rebasedMetadata(metadata, kind: .quote, path: path),
                blocks.enumerated().map {
                    self.normalizedMergedRenderBlock(
                        $0.element,
                        path: path + ["q:\($0.offset)"],
                        slugger: &slugger
                    )
                }
            )
        case .list(let metadata, let items):
            return .list(
                self.rebasedMetadata(metadata, kind: .list, path: path),
                items.enumerated().map { index, item in
                    let itemPath = path + ["li:\(index)"]
                    return STMarkdownRenderListItem(
                        blocks: item.blocks.enumerated().map {
                            self.normalizedMergedRenderBlock(
                                $0.element,
                                path: itemPath + ["b:\($0.offset)"],
                                slugger: &slugger
                            )
                        },
                        ordered: item.ordered,
                        level: item.level,
                        orderedIndex: item.orderedIndex,
                        checkbox: item.checkbox
                    )
                }
            )
        case .codeBlock(let metadata, language: let language, code: let code):
            return .codeBlock(
                self.rebasedMetadata(metadata, kind: .codeBlock, path: path),
                language: language,
                code: code
            )
        case .table(let metadata, let table):
            return .table(self.rebasedMetadata(metadata, kind: .table, path: path), table)
        case .mathBlock(let metadata, let latex):
            return .mathBlock(self.rebasedMetadata(metadata, kind: .mathBlock, path: path), latex)
        case .image(let metadata, url: let url, altText: let altText, title: let title):
            return .image(
                self.rebasedMetadata(metadata, kind: .image, path: path),
                url: url,
                altText: altText,
                title: title
            )
        case .thematicBreak(let metadata):
            return .thematicBreak(self.rebasedMetadata(metadata, kind: .thematicBreak, path: path))
        case .details(let metadata, summary: let summary, body: let body):
            return .details(
                self.rebasedMetadata(metadata, kind: .details, path: path),
                summary: summary,
                body: body.enumerated().map {
                    self.normalizedMergedRenderBlock(
                        $0.element,
                        path: path + ["d:\($0.offset)"],
                        slugger: &slugger
                    )
                }
            )
        case .rawHTML(let metadata, let html):
            return .rawHTML(self.rebasedMetadata(metadata, kind: .rawHTML, path: path), html)
        }
    }

    private func rebasedMetadata(
        _ metadata: STMarkdownRenderBlockMetadata,
        kind: STMarkdownRenderBlockKind,
        path: [String]
    ) -> STMarkdownRenderBlockMetadata {
        STMarkdownRenderBlockMetadata(
            id: path.joined(separator: "/"),
            path: path,
            kind: kind,
            revealPolicy: metadata.revealPolicy
        )
    }

    private func renderWithDocument(_ markdown: String) -> (NSAttributedString, STMarkdownRenderDocument) {
        let result = self.engine.process(markdown)
        self.updateTableOfContents(from: result)
        return (self.render(document: result.renderDocument), result.renderDocument)
    }

    private func applyFullReplace(markdown: String, rendered: NSAttributedString) {
        self.invalidatePendingStreamingAnimation()
        self.rawMarkdown = markdown
        self.shimmerTextView.setRenderedAttributedText(rendered)
        self.finalizeRenderUpdate(rendered: rendered)
    }

    private func applyAppendDelta(markdown: String, delta: NSAttributedString) {
        self.rawMarkdown = markdown
        self.invalidatePendingStreamingAnimation()
        let plan = self.streamingAnimationPlan(for: delta)
        if plan.immediatePrefix.length > 0 {
            self.shimmerTextView.appendAttributedText(plan.immediatePrefix, animated: false)
            self.finalizeRenderUpdate(rendered: self.shimmerTextView.renderedAttributedText)
        }
        if let animatedSuffix = plan.animatedSuffix, animatedSuffix.length > 0 {
            self.enqueueAnimatedStreamingSuffix(
                animatedSuffix,
                trailingSuffix: plan.trailingSuffix,
                shouldDelay: plan.requiresContainerGap
            )
            return
        }
        self.finalizeRenderUpdate(rendered: self.shimmerTextView.renderedAttributedText)
    }

    private func applyTrailingReplace(
        markdown: String,
        from location: Int,
        trailing: NSAttributedString,
        animate: Bool
    ) {
        self.rawMarkdown = markdown
        self.invalidatePendingStreamingAnimation()
        if animate {
            let plan = self.streamingAnimationPlan(for: trailing)
            if let animatedSuffix = plan.animatedSuffix, animatedSuffix.length > 0 {
                self.shimmerTextView.replaceTrailingAttributedText(
                    from: location,
                    with: plan.immediatePrefix,
                    animateNewPortion: false
                )
                self.finalizeRenderUpdate(rendered: self.shimmerTextView.renderedAttributedText)
                self.enqueueAnimatedStreamingSuffix(
                    animatedSuffix,
                    trailingSuffix: plan.trailingSuffix,
                    shouldDelay: plan.requiresContainerGap
                )
                return
            } else {
                self.shimmerTextView.replaceTrailingAttributedText(
                    from: location,
                    with: trailing,
                    animateNewPortion: false
                )
            }
        } else {
            self.shimmerTextView.replaceTrailingAttributedText(
                from: location,
                with: trailing,
                animateNewPortion: false
            )
        }
        self.finalizeRenderUpdate(rendered: self.shimmerTextView.renderedAttributedText)
    }

    /// 按尾部 reveal policy 把增量切成"立即显示前缀 + 可动画后缀"。
    /// 规则：
    /// 1. 仅当尾部最后一个 render block 的 reveal policy 是 `inlineProgressive` 时，才对该 block 动画；
    /// 2. `atomicBlock` / `containerThenContent` 本身立即上屏；
    /// 3. 这样 quote/list/details 等容器可先稳定出现，再让最后一个正文 block 继续逐字输出。
    private func streamingAnimationPlan(for attributedText: NSAttributedString) -> (
        immediatePrefix: NSAttributedString,
        animatedSuffix: NSAttributedString?,
        trailingSuffix: NSAttributedString?,
        requiresContainerGap: Bool
    ) {
        guard attributedText.length > 0 else {
            return (NSAttributedString(), nil, nil, false)
        }

        guard let suffixRange = self.trailingAnimatedBlockRange(in: attributedText) else {
            return (attributedText, nil, nil, false)
        }

        let suffixEnd = suffixRange.location + suffixRange.length
        let trailingLength = attributedText.length - suffixEnd
        let trailingSuffix: NSAttributedString? = trailingLength > 0
            ? attributedText.attributedSubstring(from: NSRange(location: suffixEnd, length: trailingLength))
            : nil

        if suffixRange.location == 0 {
            return (NSAttributedString(), attributedText.attributedSubstring(from: suffixRange), trailingSuffix, false)
        }

        let immediatePrefix = attributedText.attributedSubstring(
            from: NSRange(location: 0, length: suffixRange.location)
        )
        let animatedSuffix = attributedText.attributedSubstring(from: suffixRange)
        return (
            immediatePrefix,
            animatedSuffix,
            trailingSuffix,
            self.containsContainerRevealPolicy(in: immediatePrefix)
        )
    }

    private func trailingAnimatedBlockRange(in attributedText: NSAttributedString) -> NSRange? {
        guard attributedText.length > 0 else { return nil }

        var cursor = attributedText.length - 1
        while cursor >= 0 {
            var blockRange = NSRange(location: 0, length: 0)
            guard let blockID = attributedText.attribute(
                .stMarkdownBlockID,
                at: cursor,
                effectiveRange: &blockRange
            ) as? String,
            blockID.isEmpty == false else {
                return nil
            }

            if blockID == "__separator__" {
                cursor = blockRange.location - 1
                continue
            }

            guard let revealRaw = attributedText.attribute(
                .stMarkdownRevealPolicy,
                at: cursor,
                effectiveRange: nil
            ) as? String,
            let revealPolicy = STMarkdownRevealPolicy(rawValue: revealRaw) else {
                return nil
            }

            if revealPolicy == .inlineProgressive {
                return blockRange
            }
            return nil
        }

        return nil
    }

    private func containsContainerRevealPolicy(in attributedText: NSAttributedString) -> Bool {
        guard attributedText.length > 0 else { return false }
        let fullRange = NSRange(location: 0, length: attributedText.length)
        var found = false
        attributedText.enumerateAttribute(.stMarkdownRevealPolicy, in: fullRange, options: []) { value, _, stop in
            guard let raw = value as? String,
                  let policy = STMarkdownRevealPolicy(rawValue: raw),
                  policy == .containerThenContent else {
                return
            }
            found = true
            stop.pointee = true
        }
        return found
    }

    private func enqueueAnimatedStreamingSuffix(
        _ suffix: NSAttributedString,
        trailingSuffix: NSAttributedString?,
        shouldDelay: Bool
    ) {
        let generation = self.streamingAnimationGeneration
        self.pendingAnimatedSuffix = PendingAnimatedSuffix(
            generation: generation,
            suffix: suffix,
            trailingSuffix: trailingSuffix
        )

        if shouldDelay, self.containerRevealGapDuration > 0 {
            let workItem = DispatchWorkItem { [weak self] in
                self?.applyPendingAnimatedSuffixIfNeeded(generation: generation, animated: true)
            }
            self.pendingStreamingSuffixWorkItem = workItem
            DispatchQueue.main.asyncAfter(
                deadline: .now() + self.containerRevealGapDuration,
                execute: workItem
            )
        } else {
            self.applyPendingAnimatedSuffixIfNeeded(generation: generation, animated: true)
        }
        self.feedStreamingAnimationWatchdogIfNeeded()
    }

    private func invalidatePendingStreamingAnimation() {
        self.streamingAnimationGeneration += 1
        self.pendingStreamingSuffixWorkItem?.cancel()
        self.pendingStreamingSuffixWorkItem = nil
        self.pendingAnimatedSuffix = nil
        self.invalidateStreamingAnimationWatchdog()
    }

    private func installStreamingAnimationObservers() {
        self.shimmerTextView.onAnimationStateChange = { [weak self] _ in
            self?.feedStreamingAnimationWatchdogIfNeeded()
        }
    }

    private func applyPendingAnimatedSuffixIfNeeded(generation: Int, animated: Bool) {
        guard self.streamingAnimationGeneration == generation,
              let pending = self.pendingAnimatedSuffix,
              pending.generation == generation else {
            return
        }
        self.pendingStreamingSuffixWorkItem?.cancel()
        self.pendingStreamingSuffixWorkItem = nil
        self.pendingAnimatedSuffix = nil
        self.shimmerTextView.appendAttributedText(pending.suffix, animated: animated)
        if let trailingSuffix = pending.trailingSuffix, trailingSuffix.length > 0 {
            self.shimmerTextView.appendAttributedText(trailingSuffix, animated: false)
        }
        self.finalizeRenderUpdate(rendered: self.shimmerTextView.renderedAttributedText)
        self.feedStreamingAnimationWatchdogIfNeeded()
    }

    private func flushPendingAnimatedSuffixIfNeeded() {
        guard let pending = self.pendingAnimatedSuffix else { return }
        self.pendingStreamingSuffixWorkItem?.cancel()
        self.pendingStreamingSuffixWorkItem = nil
        self.pendingAnimatedSuffix = nil
        self.shimmerTextView.appendAttributedText(pending.suffix, animated: false)
        if let trailingSuffix = pending.trailingSuffix, trailingSuffix.length > 0 {
            self.shimmerTextView.appendAttributedText(trailingSuffix, animated: false)
        }
        self.finalizeRenderUpdate(rendered: self.shimmerTextView.renderedAttributedText)
    }

    private func feedStreamingAnimationWatchdogIfNeeded() {
        self.streamingWatchdogWorkItem?.cancel()
        self.streamingWatchdogWorkItem = nil

        guard self.streamingAnimationWatchdogTimeout > 0,
              self.isStreamingAnimationIdle == false else {
            return
        }

        self.streamingWatchdogGeneration += 1
        let generation = self.streamingWatchdogGeneration
        let workItem = DispatchWorkItem { [weak self] in
            guard let self, self.streamingWatchdogGeneration == generation else { return }
            self.forceFinishStreamingAnimationIfNeeded()
        }
        self.streamingWatchdogWorkItem = workItem
        DispatchQueue.main.asyncAfter(
            deadline: .now() + self.streamingAnimationWatchdogTimeout,
            execute: workItem
        )
    }

    private func invalidateStreamingAnimationWatchdog() {
        self.streamingWatchdogGeneration += 1
        self.streamingWatchdogWorkItem?.cancel()
        self.streamingWatchdogWorkItem = nil
    }

    private func forceFinishStreamingAnimationIfNeeded() {
        guard self.isStreamingAnimationIdle == false else {
            self.invalidateStreamingAnimationWatchdog()
            return
        }
        self.flushPendingAnimatedSuffixIfNeeded()
        self.shimmerTextView.finishAnimations()
        self.invalidateStreamingAnimationWatchdog()
        self.finalizeRenderUpdate(rendered: self.shimmerTextView.renderedAttributedText)
    }

    private func render(_ markdown: String) -> NSAttributedString {
        self.renderWithDocument(markdown).0
    }

    /// 流式期间，若源 markdown 尾部存在**尚未闭合**的 delimiter token（例如只打了
    /// 开头的 `**`、`~~`、`$$`、` ``` `、`\(`，或 task list 的前缀 `- [ ]`），直接把
    /// 它们丢给渲染引擎会导致字面字符抖动。历史版本对最终 `NSAttributedString`
    /// 做全局字符串删除，会把代码块里展示的 `$$`、`**`，inline code 里的 `` ` ``，
    /// 以及正文里字面 `- [ ]` 等**合法内容**一起吞掉。
    ///
    /// 这里改为只裁剪源 markdown 的**尾部未闭合片段**，完全不触碰已渲染的正文：
    /// 1. 保留所有已完整闭合的代码块、公式块、inline 标记；
    /// 2. 若最末尾处于一个 fenced code block 未闭合（奇数个 ```），则删掉末尾那组 ```
    ///    所在行及之后的流式片段；
    /// 3. 只对最末一行做未闭合 inline delimiter（`**` / `__` / `~~` / `\(`）
    ///    的 opening marker 裁剪，且通过**成对计数**判定，不会误伤已闭合对；
    /// 4. task list 前缀 `- [ ]` / `- [x]` 仅当该行只有前缀、尚无实际文字时才暂时隐藏。
    private static func stripUnclosedTailMarkers(in markdown: String) -> String {
        guard markdown.isEmpty == false else { return markdown }

        var working = Self.stripUnclosedFencedCodeTail(in: markdown)
        working = Self.stripUnclosedDollarMathBlockTail(in: working)
        working = Self.stripUnclosedInlineTailMarkers(in: working)
        working = Self.stripBareTaskListPrefix(in: working)
        return working
    }

    /// 若源字符串包含奇数个 ``` fence，则截断到最后一个 fence 之前（保留其前的换行），
    /// 这样最后那个 "打开但未闭合" 的代码块在流式期间暂时不显示，等到下一帧闭合后再一起渲染。
    private static func stripUnclosedFencedCodeTail(in markdown: String) -> String {
        let ns = markdown as NSString
        let fenceMatches = Self.fencedCodeRegex.matches(
            in: markdown,
            options: [],
            range: NSRange(location: 0, length: ns.length)
        )
        guard fenceMatches.count % 2 == 1, let last = fenceMatches.last else {
            return markdown
        }
        // 截到最后一个未闭合 fence 所在行的起点；找不到就截到 fence 之前。
        let lastLineStart: Int
        let prefixRange = NSRange(location: 0, length: last.range.location)
        let prefix = ns.substring(with: prefixRange) as NSString
        let newline = prefix.range(of: "\n", options: .backwards)
        lastLineStart = newline.location == NSNotFound ? 0 : newline.location + newline.length
        return ns.substring(to: lastLineStart)
    }

    /// 若源字符串包含奇数个 `$$`，说明末尾存在未闭合块公式。
    /// 流式阶段先隐藏从打开 `$$` 所在行起的尾段，避免 `$$` 或公式体以普通文本闪烁。
    private static func stripUnclosedDollarMathBlockTail(in markdown: String) -> String {
        let ns = markdown as NSString
        let matches = Self.dollarMathFenceRegex.matches(
            in: markdown,
            options: [],
            range: NSRange(location: 0, length: ns.length)
        )
        guard matches.count % 2 == 1, let last = matches.last else {
            return markdown
        }

        let prefix = ns.substring(to: last.range.location) as NSString
        let newline = prefix.range(of: "\n", options: .backwards)
        let lastLineStart = newline.location == NSNotFound ? 0 : newline.location + newline.length
        return ns.substring(to: lastLineStart)
    }

    /// 只处理最末一行的未闭合 inline delimiter：成对数量为奇数时裁剪最后一个 opening marker。
    /// 这样 "文本里已经成对闭合" 的 `**foo**` 不会被动到，代码块内已完整闭合的 token 也不会被动到。
    private static func stripUnclosedInlineTailMarkers(in markdown: String) -> String {
        let ns = markdown as NSString
        let newline = ns.range(of: "\n", options: .backwards)
        let lastLineStart = newline.location == NSNotFound ? 0 : newline.location + newline.length
        let lastLine = ns.substring(from: lastLineStart)
        guard lastLine.isEmpty == false else { return markdown }

        var trimmed = lastLine
        // 按“从长到短 / 从强到弱”的顺序，避免 `**` 被当成两个 `*`。
        for token in Self.inlinePairableTokens {
            trimmed = Self.trimUnclosedInlineToken(token, in: trimmed)
        }
        // `\(` 单独处理：无配对 `\)` 时，先隐藏 opening marker，保留已到达的公式体文本。
        trimmed = Self.trimUnclosedMathOpen(in: trimmed)

        if trimmed == lastLine {
            return markdown
        }
        let prefix = ns.substring(to: lastLineStart)
        return prefix + trimmed
    }

    /// 若该行 `token` 数量为奇数，说明最后一个 token 是未闭合 opener；
    /// 去掉 opener 本身但保留其后的流式正文，避免显示原始 Markdown 定界符。
    private static func trimUnclosedInlineToken(_ token: String, in line: String) -> String {
        let count = line.components(separatedBy: token).count - 1
        guard count % 2 == 1 else { return line }

        guard let range = line.range(of: token, options: .backwards) else {
            return line
        }
        var result = line
        result.removeSubrange(range)
        return result
    }

    private static func trimUnclosedMathOpen(in line: String) -> String {
        // `\(` 与 `\)` 成对；未闭合时移除最后一个 opening marker，
        // 避免流式中间态把 `\(` 直接暴露给用户。
        let opens = line.components(separatedBy: #"\("#).count - 1
        let closes = line.components(separatedBy: #"\)"#).count - 1
        guard opens > closes else { return line }

        guard let range = line.range(of: #"\("#, options: .backwards) else {
            return line
        }
        var result = line
        result.removeSubrange(range)
        return result
    }

    /// 末行仅为 task list 前缀（`- [ ] ` / `- [x] `）且无后续文字时，暂时隐藏，
    /// 避免流式过程中 "- [ ]" 字面字符闪一下。已包含任何可见文字则保留，
    /// 这样用户/模型想展示字面 `- [ ]` 也不会被吞。
    private static func stripBareTaskListPrefix(in markdown: String) -> String {
        let ns = markdown as NSString
        let newline = ns.range(of: "\n", options: .backwards)
        let lastLineStart = newline.location == NSNotFound ? 0 : newline.location + newline.length
        let lastLine = ns.substring(from: lastLineStart)
        let lineRange = NSRange(location: 0, length: (lastLine as NSString).length)
        guard Self.bareTaskPrefixRegex.firstMatch(in: lastLine, options: [], range: lineRange) != nil else {
            return markdown
        }
        return ns.substring(to: lastLineStart)
    }

    private static let fencedCodeRegex: NSRegularExpression = {
        // 行首（允许前置空白）出现至少三个反引号的 fence 标记。
        return try! NSRegularExpression(pattern: #"(?m)^[ \t]*`{3,}"#, options: [])
    }()

    private static let dollarMathFenceRegex: NSRegularExpression = {
        return try! NSRegularExpression(pattern: #"\$\$"#, options: [])
    }()

    private static let bareTaskPrefixRegex: NSRegularExpression = {
        // 行首为 task list 前缀但没有任何可见正文。
        return try! NSRegularExpression(
            pattern: #"^[ \t]*[-*+][ \t]+\[[ xX]\][ \t]*$"#,
            options: []
        )
    }()

    private static let inlinePairableTokens: [String] = [
        "```",
        "**",
        "__",
        "~~"
    ]

    private func shouldDisableAnimationForTrailingReplacement(
        current: NSAttributedString,
        rendered: NSAttributedString,
        commonLength: Int
    ) -> Bool {
        let currentSuffix = current.length > commonLength
            ? current.attributedSubstring(
                from: NSRange(location: commonLength, length: current.length - commonLength)
            ).string
            : ""
        let renderedSuffix = rendered.length > commonLength
            ? rendered.attributedSubstring(
                from: NSRange(location: commonLength, length: rendered.length - commonLength)
            ).string
            : ""

        return Self.containsRenderedListMarker(in: currentSuffix)
            || Self.containsRenderedListMarker(in: renderedSuffix)
    }

    private func replacementStartForListTransition(currentString: String, commonLength: Int) -> Int {
        guard commonLength > 0 else { return 0 }
        let prefix = (currentString as NSString).substring(to: commonLength) as NSString
        let lastNewline = prefix.range(of: "\n", options: .backwards)
        guard lastNewline.location != NSNotFound else { return 0 }
        return lastNewline.location + lastNewline.length
    }

    private static func containsRenderedListMarker(in text: String) -> Bool {
        guard text.isEmpty == false else { return false }
        let range = NSRange(location: 0, length: text.utf16.count)
        return Self.unorderedListMarkerRegex.firstMatch(in: text, options: [], range: range) != nil
            || Self.orderedListMarkerRegex.firstMatch(in: text, options: [], range: range) != nil
    }

    private static let orderedListMarkerRegex = try! NSRegularExpression(
        pattern: #"(?m)^\t*\d+\.\t"#,
        options: []
    )

    private static let unorderedListMarkerRegex = try! NSRegularExpression(
        pattern: #"(?m)(?:^|\n)\t*[●▪]\t"#,
        options: []
    )

    /// 启发式判断文本是否**不太可能**含有常见 Markdown 块级/行内标记。
    ///
    /// 适用于宿主自行缓冲 LLM 输出时决定是否采用更细粒度（例如按单行 `\n`）的提交策略；
    /// 与 ``setMarkdown(_:animated:)`` 内置的尾部定界符裁剪正交，可独立使用。
    public static func isLikelyMarkdownFreePlainText(_ text: String) -> Bool {
        let blockMarkers = [
            "#", "> ", "```", "---", "***",
            "- ", "* ", "+ ", "| ",
            "1. ", "2. ", "3. ",
            "![", "](",
        ]
        for marker in blockMarkers where text.contains(marker) {
            return false
        }
        if text.contains("**") || text.contains("__") || text.contains("`") || text.contains("$$") {
            return false
        }
        return true
    }
}
