//
//  STShimmerTextView.swift
//  Bajoseek
//
//  Created by 寒江孤影 on 2026/2/3.
//

import UIKit

open class STShimmerTextView: UITextView {

    public static let skipFadeInAttributeKey = NSAttributedString.Key("STShimmerTextView.skipFadeIn")

    private final class LineFadeLayer: CAGradientLayer {
        var isFadeComplete: Bool = false
    }

    private final class LineFadeAnimationDelegate: NSObject, CAAnimationDelegate {
        private let onComplete: () -> Void
        init(_ onComplete: @escaping () -> Void) { self.onComplete = onComplete }
        func animationDidStop(_ anim: CAAnimation, finished: Bool) {
            if finished { onComplete() }
        }
    }

    private struct AnimatingColorRun {
        let range: NSRange
        let targetColor: UIColor
    }

    private struct AnimatingToken {
        let range: NSRange
        let startTime: CFTimeInterval
        let staggerInterval: TimeInterval
        let colorRuns: [AnimatingColorRun]
    }

    public var tokenFadeDuration: TimeInterval = 0.3
    /// token stagger 间隔：每个语义 token 的 fade-in 起始时间比前一个 token 延迟此值。
    /// token 由 localized word + separator range 组成；无法分词时退化为整段 run fade，
    /// 避免逐 UTF-16 字符揭示时把折行过程暴露给用户。
    /// 设为 0 则禁用 stagger（所有 token 同时 fade-in）。
    public var characterStaggerInterval: TimeInterval = 0.016
    /// 为 true 时，跨换行也保持连续 token 渐显；
    /// 为 false 时，新增 delta 中最后一个换行前的内容会立即显示，仅最后一行保留动画。
    public var animateAcrossNewlines: Bool = false
    /// `true` 时改用 FluidMarkdown 风格的行级 CAGradientLayer 水平扫入遮罩动画，
    /// 替代默认的 token 级 foregroundColor 淡入；由 STMarkdownStreamingTextView 根据样式同步。
    public var lineFadeMode: Bool = false
    /// 行级扫入动画时长（秒），默认 0.15 s，与 FluidMarkdown 对齐。
    public var lineFadeDuration: TimeInterval = 0.15
    /// 当前 token 输出行尾部的柔和渐隐宽度。
    public var lineFadeTrailingWidth: CGFloat = 18
    public var suppressSystemTextMenu: Bool = false
    public var onAnimationStateChange: ((Bool) -> Void)?
    private var displayLink: CADisplayLink?
    private var animatingTokens: [AnimatingToken] = []
    /// 行级遮罩所用父 CALayer（挂在 self.layer.mask）。
    private var _lineFadeMaskLayer: CALayer?
    /// 遮罩内的基础不透明层，覆盖所有"已完成动画"的文本区域。
    private var _lineFadeBaseLayer: CALayer?
    /// 最终目标态的 attributed text（全不透明），不含任何动画中间状态的 alpha 值。
    /// 供外部做 "已渲染前缀" 比较时使用，避免因动画过渡期 alpha < 1 导致前缀比较误判。
    private var _baseAttributedText: NSMutableAttributedString = NSMutableAttributedString()
    private var _isLineFadeAnimating: Bool = false

    open var defaultTextAttributes: [NSAttributedString.Key: Any] {
        return [
            .font: self.font ?? UIFont.st_systemFont(ofSize: 16),
            .foregroundColor: self.textColor ?? UIColor.label,
        ]
    }

    public var renderedAttributedText: NSAttributedString {
        return _baseAttributedText
    }

    public var isAnimatingTextReveal: Bool {
        (self.displayLink != nil && !self.animatingTokens.isEmpty) || self._isLineFadeAnimating
    }

    public override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        self.setup()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setup()
    }

    /// - Parameter usingTextLayoutManager: `true` 时使用 TextKit 2 栈（iOS 16+）；低版本系统始终为 TextKit 1。
    public convenience init(usingTextLayoutManager: Bool) {
        if #available(iOS 16.0, *) {
            let shell = UITextView(usingTextLayoutManager: usingTextLayoutManager)
            self.init(frame: .zero, textContainer: shell.textContainer)
        } else {
            self.init(frame: .zero, textContainer: nil)
        }
    }

    private func setup() {
        self.translatesAutoresizingMaskIntoConstraints = false
        self.isEditable = false
        self.isSelectable = true
        self.isScrollEnabled = false
        self.backgroundColor = .clear
        self.textContainerInset = .zero
        self.textContainer.lineFragmentPadding = 0
        self.font = .st_systemFont(ofSize: 16)
        self.textColor = .label
        if #available(iOS 16.0, *) {
            if self.textLayoutManager == nil {
                self.layoutManager.allowsNonContiguousLayout = false
            }
        } else {
            self.layoutManager.allowsNonContiguousLayout = false
        }
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
        guard let mask = _lineFadeMaskLayer else { return }
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        mask.frame = self.bounds
        mask.sublayerTransform = CATransform3DMakeTranslation(contentOffset.x, -contentOffset.y, 0)
        _lineFadeBaseLayer?.frame.size.width = self.bounds.width
        CATransaction.commit()
    }

    public func append(_ text: String) {
        guard !text.isEmpty else { return }
        let startLocation = self.textStorage.length
        let baseColor = self.baseForegroundColor(from: self.defaultTextAttributes)
        if self.tokenFadeDuration > 0, !self.animateAcrossNewlines {
            self.finishAnimationsBeforeLastNewline()
        }
        let baseAttr = NSAttributedString(
            string: text,
            attributes: [.font: self.font ?? UIFont.st_systemFont(ofSize: 16), .foregroundColor: baseColor]
        )
        _baseAttributedText.append(baseAttr)
        var attrs = self.defaultTextAttributes
        attrs[.foregroundColor] = baseColor.withAlphaComponent(self.tokenFadeDuration > 0 ? 0 : 1)
        let tokenAttr = NSAttributedString(string: text, attributes: attrs)
        self.textStorage.beginEditing()
        self.textStorage.append(tokenAttr)
        self.textStorage.endEditing()
        guard self.tokenFadeDuration > 0 else { return }
        let token = AnimatingToken(
            range: NSRange(location: startLocation, length: text.utf16.count),
            startTime: CACurrentMediaTime(),
            staggerInterval: 0,
            colorRuns: [
                AnimatingColorRun(
                    range: NSRange(location: startLocation, length: text.utf16.count),
                    targetColor: baseColor
                )
            ]
        )
        self.animatingTokens.append(token)
        self.startDisplayLinkIfNeeded()
    }

    public func appendAttributedText(_ attributedText: NSAttributedString, animated: Bool = true) {
        guard attributedText.length > 0 else { return }
        let startLocation = self.textStorage.length
        let appended = NSMutableAttributedString(attributedString: attributedText)
        let defaultColor = self.baseForegroundColor(from: self.defaultTextAttributes)
        self.ensureForegroundColor(in: appended, defaultColor: defaultColor)
        let savedOffset = self.contentOffset
        if animated && self.lineFadeMode {
            _baseAttributedText.append(appended)
            self.textStorage.beginEditing()
            self.textStorage.append(appended)
            self.textStorage.endEditing()
            if self.contentOffset != savedOffset { self.contentOffset = savedOffset }
            self.applyLineFadeAnimation(
                changedRange: NSRange(location: startLocation, length: appended.length)
            )
            return
        }
        if animated, self.tokenFadeDuration > 0, !self.animateAcrossNewlines {
            self.finishAnimationsBeforeLastNewline()
        }
        _baseAttributedText.append(appended)
        let colorRuns = self.animatingColorRuns(in: appended, offset: startLocation)
        if animated {
            self.applyTransparentForegroundColors(to: appended, defaultColor: defaultColor)
        }
        self.textStorage.beginEditing()
        self.textStorage.append(appended)
        self.textStorage.endEditing()
        guard animated, self.tokenFadeDuration > 0, !colorRuns.isEmpty else {
            if self.contentOffset != savedOffset { self.contentOffset = savedOffset }
            return
        }
        let deltaString = appended.string as NSString
        let lastNLInDelta = deltaString.range(of: "\n", options: .backwards)
        if !self.animateAcrossNewlines, lastNLInDelta.location != NSNotFound {
            let splitPos = lastNLInDelta.location + lastNLInDelta.length  // local offset in delta
            self.textStorage.beginEditing()
            var trailingRuns: [AnimatingColorRun] = []
            for run in colorRuns {
                let runLocalStart = run.range.location - startLocation
                let runLocalEnd = runLocalStart + run.range.length
                if runLocalEnd <= splitPos {
                    self.textStorage.addAttribute(.foregroundColor, value: run.targetColor, range: run.range)
                } else if runLocalStart >= splitPos {
                    trailingRuns.append(run)
                } else {
                    let beforeLength = splitPos - runLocalStart
                    let beforeRange = NSRange(location: run.range.location, length: beforeLength)
                    self.textStorage.addAttribute(.foregroundColor, value: run.targetColor, range: beforeRange)
                    let afterLength = runLocalEnd - splitPos
                    let afterRange = NSRange(location: startLocation + splitPos, length: afterLength)
                    trailingRuns.append(AnimatingColorRun(range: afterRange, targetColor: run.targetColor))
                }
            }
            self.textStorage.endEditing()
            if self.contentOffset != savedOffset { self.contentOffset = savedOffset }
            if !trailingRuns.isEmpty {
                self.appendStaggeredTokens(for: trailingRuns)
                self.startDisplayLinkIfNeeded()
            }
        } else {
            if self.contentOffset != savedOffset { self.contentOffset = savedOffset }
            self.appendStaggeredTokens(for: colorRuns)
            self.startDisplayLinkIfNeeded()
        }
    }

    public func setRenderedAttributedText(_ attributedText: NSAttributedString) {
        self.stopDisplayLink()
        self.animatingTokens.removeAll()
        self.removeLineFadeMask()
        _baseAttributedText = NSMutableAttributedString(attributedString: attributedText)
        self.textStorage.beginEditing()
        self.textStorage.setAttributedString(attributedText)
        self.textStorage.endEditing()
    }

    public func replaceTrailingAttributedText(from location: Int, with attributedText: NSAttributedString, animateNewPortion: Bool = true) {
        let clampedLocation = max(0, min(location, self.textStorage.length))
        let savedOffset = self.contentOffset
        if !self.animatingTokens.isEmpty {
            self.textStorage.beginEditing()
            for token in self.animatingTokens {
                let tokenEnd = token.range.location + token.range.length
                if tokenEnd <= clampedLocation {
                    for run in token.colorRuns {
                        self.textStorage.addAttribute(.foregroundColor, value: run.targetColor, range: run.range)
                    }
                }
            }
            self.textStorage.endEditing()
        }
        self.animatingTokens.removeAll()
        if self.lineFadeMode { self.removeLineFadeMask() }
        let oldTrailingLength = self.textStorage.length - clampedLocation
        let oldTrailingString: String
        if oldTrailingLength > 0 {
            oldTrailingString = (self.textStorage.string as NSString)
                .substring(with: NSRange(location: clampedLocation, length: oldTrailingLength))
        } else {
            oldTrailingString = ""
        }
        let clampedBaseLocation = max(0, min(location, _baseAttributedText.length))
        let newBase = NSMutableAttributedString(
            attributedString: _baseAttributedText.attributedSubstring(
                from: NSRange(location: 0, length: clampedBaseLocation)
            )
        )
        newBase.append(attributedText)
        _baseAttributedText = newBase
        let newTrailingString = attributedText.string
        let commonPrefixCount = oldTrailingString.commonPrefix(with: newTrailingString).utf16.count
        let appended = NSMutableAttributedString(attributedString: attributedText)
        let defaultColor = self.baseForegroundColor(from: self.defaultTextAttributes)
        self.ensureForegroundColor(in: appended, defaultColor: defaultColor)
        let newCharCount = attributedText.length - commonPrefixCount
        var newColorRuns: [AnimatingColorRun] = []
        if animateNewPortion,
           newCharCount > 0,
           self.tokenFadeDuration > 0,
           self.characterStaggerInterval > 0 {
            let newRange = NSRange(location: commonPrefixCount, length: newCharCount)
            let newPortion = appended.attributedSubstring(from: newRange)
            let newPortionMut = NSMutableAttributedString(attributedString: newPortion)
            let newPortionOffset = clampedLocation + commonPrefixCount
            let fullRange = NSRange(location: 0, length: newPortionMut.length)
            newPortionMut.enumerateAttribute(.foregroundColor, in: fullRange, options: []) { value, subrange, _ in
                guard let color = value as? UIColor else { return }
                if newPortionMut.attribute(.attachment, at: subrange.location, effectiveRange: nil) != nil { return }
                if newPortionMut.attribute(Self.skipFadeInAttributeKey, at: subrange.location, effectiveRange: nil) != nil { return }
                var alpha: CGFloat = 0
                color.getWhite(nil, alpha: &alpha)
                if alpha < 0.01 { return }
                newColorRuns.append(AnimatingColorRun(
                    range: NSRange(location: newPortionOffset + subrange.location, length: subrange.length),
                    targetColor: color
                ))
            }
            if !newColorRuns.isEmpty {
                newPortionMut.enumerateAttribute(.foregroundColor, in: fullRange, options: []) { value, subrange, _ in
                    if newPortionMut.attribute(.attachment, at: subrange.location, effectiveRange: nil) != nil { return }
                    if newPortionMut.attribute(Self.skipFadeInAttributeKey, at: subrange.location, effectiveRange: nil) != nil { return }
                    let color = (value as? UIColor) ?? defaultColor
                    var alpha: CGFloat = 0
                    color.getWhite(nil, alpha: &alpha)
                    if alpha < 0.01 { return }
                    newPortionMut.addAttribute(.foregroundColor, value: color.withAlphaComponent(0), range: subrange)
                }
                appended.replaceCharacters(in: newRange, with: newPortionMut)
            }
        }

        self.textStorage.beginEditing()
        self.textStorage.replaceCharacters(
            in: NSRange(location: clampedLocation, length: self.textStorage.length - clampedLocation),
            with: appended
        )
        self.textStorage.endEditing()
        if self.contentOffset != savedOffset { self.contentOffset = savedOffset }
        if !newColorRuns.isEmpty {
            self.appendStaggeredTokens(for: newColorRuns)
            self.startDisplayLinkIfNeeded()
        } else {
            self.stopDisplayLink()
        }
    }

    public func reset() {
        self.stopDisplayLink()
        self.animatingTokens.removeAll()
        self.removeLineFadeMask()
        _baseAttributedText = NSMutableAttributedString()
        self.textStorage.beginEditing()
        self.textStorage.setAttributedString(NSAttributedString())
        self.textStorage.endEditing()
    }

    public func finishAnimations() {
        self.stopDisplayLink()
        let pendingTokens = self.animatingTokens
        self.animatingTokens.removeAll()
        self.removeLineFadeMask()
        guard !pendingTokens.isEmpty else { return }
        self.textStorage.beginEditing()
        for token in pendingTokens {
            for run in token.colorRuns {
                self.textStorage.addAttribute(.foregroundColor, value: run.targetColor, range: run.range)
            }
        }
        self.textStorage.endEditing()
    }

    public func caretRect() -> CGRect? {
        guard self.textStorage.length > 0 else { return nil }
        let rect = self.caretRect(for: self.endOfDocument)
        if rect.isEmpty || rect.origin.x.isInfinite || rect.origin.y.isInfinite {
            return nil
        }
        return rect
    }

    /// 创建带 stagger 的单个 AnimatingToken。
    ///
    /// 所有文本已经以 alpha=0 插入 textStorage 并完成布局，此处仅控制 fade-in 动画时序，
    /// 不会引起任何布局变化、跳动或闪烁。
    private func appendStaggeredTokens(for colorRuns: [AnimatingColorRun]) {
        let revealRuns = self.semanticRevealColorRuns(from: colorRuns)
        guard !revealRuns.isEmpty else { return }
        let start = revealRuns.map(\.range.location).min()!
        let end = revealRuns.map { $0.range.location + $0.range.length }.max()!
        let stagger = (self.characterStaggerInterval > 0 && revealRuns.count > 1)
            ? self.characterStaggerInterval : 0
        let token = AnimatingToken(
            range: NSRange(location: start, length: end - start),
            startTime: CACurrentMediaTime(),
            staggerInterval: stagger,
            colorRuns: revealRuns
        )
        self.animatingTokens.append(token)
    }

    private func semanticRevealColorRuns(from colorRuns: [AnimatingColorRun]) -> [AnimatingColorRun] {
        guard self.characterStaggerInterval > 0, colorRuns.isEmpty == false else {
            return colorRuns
        }

        let fullString = self.textStorage.string as NSString
        guard fullString.length > 0 else { return colorRuns }

        var result: [AnimatingColorRun] = []
        for run in colorRuns {
            let clampedRange = NSIntersectionRange(
                run.range,
                NSRange(location: 0, length: fullString.length)
            )
            guard clampedRange.length > 0 else { continue }
            let semanticRanges = self.semanticRevealRanges(in: fullString, range: clampedRange)
            for semanticRange in semanticRanges {
                result.append(AnimatingColorRun(range: semanticRange, targetColor: run.targetColor))
            }
        }
        return result.isEmpty ? colorRuns : result
    }

    private func semanticRevealRanges(in string: NSString, range: NSRange) -> [NSRange] {
        guard range.location != NSNotFound,
              range.location >= 0,
              NSMaxRange(range) <= string.length else {
            return []
        }

        var ranges: [NSRange] = []
        string.enumerateSubstrings(
            in: range,
            options: [.byWords, .localized, .substringNotRequired]
        ) { _, substringRange, _, _ in
            if let last = ranges.last {
                let gapStart = NSMaxRange(last)
                let gapLength = substringRange.location - gapStart
                if gapLength > 0 {
                    ranges.append(NSRange(location: gapStart, length: gapLength))
                }
            } else {
                let leadingGapLength = substringRange.location - range.location
                if leadingGapLength > 0 {
                    ranges.append(NSRange(location: range.location, length: leadingGapLength))
                }
            }
            ranges.append(substringRange)
        }

        if let last = ranges.last {
            let trailingStart = NSMaxRange(last)
            let trailingLength = NSMaxRange(range) - trailingStart
            if trailingLength > 0 {
                ranges.append(NSRange(location: trailingStart, length: trailingLength))
            }
        } else {
            ranges.append(range)
        }
        return ranges
    }

    private func startDisplayLinkIfNeeded() {
        guard self.displayLink == nil else { return }
        let link = CADisplayLink(target: self, selector: #selector(self.handleDisplayLink))
        link.add(to: .main, forMode: .common)
        self.displayLink = link
        self.onAnimationStateChange?(true)
    }

    private func stopDisplayLink() {
        let wasAnimating = self.displayLink != nil
        self.displayLink?.invalidate()
        self.displayLink = nil
        if wasAnimating {
            self.onAnimationStateChange?(false)
        }
    }

    @objc private func handleDisplayLink() {
        guard !self.animatingTokens.isEmpty else {
            self.stopDisplayLink()
            return
        }
        let now = CACurrentMediaTime()
        let fadeDuration = self.tokenFadeDuration
        let savedOffset = self.contentOffset
        self.textStorage.beginEditing()
        for token in self.animatingTokens {
            if token.staggerInterval <= 0 {
                let elapsed = now - token.startTime
                let progress = min(1.0, elapsed / fadeDuration)
                let easedProgress = 1.0 - pow(1.0 - progress, 3.0)
                for run in token.colorRuns {
                    let color = run.targetColor.withAlphaComponent(CGFloat(easedProgress))
                    self.textStorage.addAttribute(.foregroundColor, value: color, range: run.range)
                }
            } else {
                for (index, run) in token.colorRuns.enumerated() {
                    let tokenStartTime = token.startTime + Double(index) * token.staggerInterval
                    let elapsed = now - tokenStartTime
                    let progress = min(1.0, max(0, elapsed / fadeDuration))
                    let easedProgress = 1.0 - pow(1.0 - progress, 3.0)
                    let color = run.targetColor.withAlphaComponent(CGFloat(easedProgress))
                    self.textStorage.addAttribute(.foregroundColor, value: color, range: run.range)
                }
            }
        }
        self.textStorage.endEditing()
        if self.contentOffset != savedOffset {
            self.contentOffset = savedOffset
        }
        self.animatingTokens.removeAll { token in
            let totalUnits = token.staggerInterval > 0 ? token.colorRuns.count : 1
            let lastUnitStart = token.startTime + Double(max(0, totalUnits - 1)) * token.staggerInterval
            return (now - lastUnitStart) >= fadeDuration
        }
        if self.animatingTokens.isEmpty {
            self.stopDisplayLink()
        }
    }

    private func ensureForegroundColor(in attributedText: NSMutableAttributedString, defaultColor: UIColor) {
        let range = NSRange(location: 0, length: attributedText.length)
        guard range.length > 0 else { return }
        attributedText.enumerateAttribute(.foregroundColor, in: range, options: []) { value, subrange, _ in
            guard value == nil else { return }
            attributedText.addAttribute(.foregroundColor, value: defaultColor, range: subrange)
        }
    }

    private func applyTransparentForegroundColors(to attributedText: NSMutableAttributedString, defaultColor: UIColor) {
        let range = NSRange(location: 0, length: attributedText.length)
        guard range.length > 0 else { return }
        attributedText.enumerateAttribute(.foregroundColor, in: range, options: []) { value, subrange, _ in
            if attributedText.attribute(.attachment, at: subrange.location, effectiveRange: nil) != nil {
                return
            }
            if attributedText.attribute(Self.skipFadeInAttributeKey, at: subrange.location, effectiveRange: nil) != nil {
                return
            }
            let color = (value as? UIColor) ?? defaultColor
            var alpha: CGFloat = 0
            color.getWhite(nil, alpha: &alpha)
            if alpha < 0.01 { return }
            attributedText.addAttribute(
                .foregroundColor,
                value: color.withAlphaComponent(self.tokenFadeDuration > 0 ? 0 : 1),
                range: subrange
            )
        }
    }

    private func animatingColorRuns(in attributedText: NSAttributedString, offset: Int) -> [AnimatingColorRun] {
        let range = NSRange(location: 0, length: attributedText.length)
        guard range.length > 0 else { return [] }

        var runs: [AnimatingColorRun] = []
        attributedText.enumerateAttribute(.foregroundColor, in: range, options: []) { value, subrange, _ in
            guard let color = value as? UIColor else { return }
            if attributedText.attribute(.attachment, at: subrange.location, effectiveRange: nil) != nil {
                return
            }
            if attributedText.attribute(Self.skipFadeInAttributeKey, at: subrange.location, effectiveRange: nil) != nil {
                return
            }
            var alpha: CGFloat = 0
            color.getWhite(nil, alpha: &alpha)
            if alpha < 0.01 { return }
            runs.append(
                AnimatingColorRun(
                    range: NSRange(location: offset + subrange.location, length: subrange.length),
                    targetColor: color
                )
            )
        }
        return runs
    }

    private func baseForegroundColor(from attrs: [NSAttributedString.Key: Any]) -> UIColor {
        return (attrs[.foregroundColor] as? UIColor) ?? self.textColor ?? .label
    }

    private func applyForegroundColor(_ color: UIColor, range: NSRange) {
        let offset = self.contentOffset
        self.textStorage.beginEditing()
        self.textStorage.addAttribute(.foregroundColor, value: color, range: range)
        self.textStorage.endEditing()
        if self.contentOffset != offset {
            self.setContentOffset(offset, animated: false)
        }
    }

    /// 立即完成"当前行"之前所有行的 fade-in 动画。
    ///
    /// 原则：_baseAttributedText 中最后一个 \n 之前的字符已属于已完成的行，
    /// 它们的 animatingToken 应立即置为全不透明，不应继续半透明地悬挂在屏幕上。
    /// 调用时机：在每次 append 新字符 **之前**（_baseAttributedText 尚未追加新内容），
    /// 以 _baseAttributedText 的当前末尾搜索最后一个换行符。
    private func finishAnimationsBeforeLastNewline() {
        guard !self.animatingTokens.isEmpty else { return }
        let str = _baseAttributedText.string as NSString
        let len = str.length
        guard len > 0 else { return }
        let lastNLRange = str.range(of: "\n", options: .backwards, range: NSRange(location: 0, length: len))
        guard lastNLRange.location != NSNotFound else { return }
        let boundary = lastNLRange.location + lastNLRange.length
        var completedIndices: [Int] = []
        var splitReplacements: [(index: Int, newToken: AnimatingToken)] = []
        self.textStorage.beginEditing()
        for (idx, token) in self.animatingTokens.enumerated() {
            let tokenEnd = token.range.location + token.range.length
            if tokenEnd <= boundary {
                for run in token.colorRuns {
                    self.textStorage.addAttribute(.foregroundColor, value: run.targetColor, range: run.range)
                }
                completedIndices.append(idx)
            } else if token.range.location < boundary {
                var beforeRuns: [AnimatingColorRun] = []
                var afterRuns: [AnimatingColorRun] = []
                for run in token.colorRuns {
                    let runEnd = run.range.location + run.range.length
                    if runEnd <= boundary {
                        beforeRuns.append(run)
                    } else if run.range.location >= boundary {
                        afterRuns.append(run)
                    } else {
                        let beforeLength = boundary - run.range.location
                        let beforeRange = NSRange(location: run.range.location, length: beforeLength)
                        beforeRuns.append(AnimatingColorRun(range: beforeRange, targetColor: run.targetColor))
                        let afterLength = runEnd - boundary
                        let afterRange = NSRange(location: boundary, length: afterLength)
                        afterRuns.append(AnimatingColorRun(range: afterRange, targetColor: run.targetColor))
                    }
                }
                for run in beforeRuns {
                    self.textStorage.addAttribute(.foregroundColor, value: run.targetColor, range: run.range)
                }
                if afterRuns.isEmpty {
                    completedIndices.append(idx)
                } else {
                    let afterStart = afterRuns.map(\.range.location).min() ?? boundary
                    let afterEnd = afterRuns.map { $0.range.location + $0.range.length }.max() ?? boundary
                    let newToken = AnimatingToken(
                        range: NSRange(location: afterStart, length: afterEnd - afterStart),
                        startTime: token.startTime,
                        staggerInterval: token.staggerInterval,
                        colorRuns: afterRuns
                    )
                    splitReplacements.append((index: idx, newToken: newToken))
                }
            }
        }
        self.textStorage.endEditing()
        for replacement in splitReplacements {
            self.animatingTokens[replacement.index] = replacement.newToken
        }
        guard !completedIndices.isEmpty else { return }
        for idx in completedIndices.reversed() {
            self.animatingTokens.remove(at: idx)
        }
        if self.animatingTokens.isEmpty {
            self.stopDisplayLink()
        }
    }

    private func removeLineFadeMask() {
        guard _lineFadeMaskLayer != nil else { return }
        self.layer.mask = nil
        _lineFadeMaskLayer = nil
        _lineFadeBaseLayer = nil
        self.setLineFadeAnimating(false)
    }

    /// 对 `changedRange` 所在的最末行应用 CAGradientLayer 水平扫入遮罩动画（FluidMarkdown 风格）。
    /// 遮罩结构：父 CALayer（mask）→ 黑色基础层（覆盖已完成行）+ LineFadeLayer（当前行动画）。
    /// TK2（iOS 16+）优先；TK2 不可用时回退到 TK1 layoutManager。
    private func applyLineFadeAnimation(changedRange: NSRange) {
        guard changedRange.length > 0, self.bounds.width > 1 else { return }
        if _lineFadeMaskLayer == nil {
            let null = NSNull()
            let mask = CALayer()
            mask.actions = [
                "bounds": null, "position": null,
                "frame": null, "sublayerTransform": null, "transition": null,
            ]
            let base = CALayer()
            base.backgroundColor = UIColor.black.cgColor
            base.actions = ["bounds": null, "position": null, "frame": null, "transition": null]
            mask.addSublayer(base)
            _lineFadeBaseLayer = base
            _lineFadeMaskLayer = mask
            self.layer.mask = mask
        }
        guard let mask = _lineFadeMaskLayer, let base = _lineFadeBaseLayer else { return }
        mask.frame = self.bounds
        mask.sublayerTransform = CATransform3DMakeTranslation(contentOffset.x, -contentOffset.y, 0)
        if #available(iOS 16.0, *), let tlm = self.textLayoutManager {
            applyLineFadeAnimation_tk2(changedRange: changedRange, tlm: tlm, mask: mask, base: base)
        } else {
            applyLineFadeAnimation_tk1(changedRange: changedRange, mask: mask, base: base)
        }
    }

    @available(iOS 16.0, *)
    private func applyLineFadeAnimation_tk2(
        changedRange: NSRange,
        tlm: NSTextLayoutManager,
        mask: CALayer,
        base: CALayer
    ) {
        guard let tcs = tlm.textContentManager else { return }
        let docStart = tcs.documentRange.location
        guard
            let rs = tcs.location(docStart, offsetBy: changedRange.location),
            let re = tcs.location(rs, offsetBy: changedRange.length),
            let textRange = NSTextRange(location: rs, end: re)
        else { return }
        tlm.ensureLayout(for: textRange)
        var prevMinY: CGFloat = .nan
        var curLineRect: CGRect = .null
        var lastLineRect: CGRect = .null
        tlm.enumerateTextSegments(in: textRange, type: .standard, options: .rangeNotRequired) { _, sf, _, _ in
            if abs(sf.minY - prevMinY) > 0.5 {
                prevMinY = sf.minY
                curLineRect = sf
            } else {
                curLineRect = curLineRect.union(sf)
            }
            lastLineRect = curLineRect
            return true
        }
        guard !lastLineRect.isNull else { return }
        installLineFadeLayer(lineRect: lastLineRect, rightEdge: lastLineRect.maxX, mask: mask, base: base)
    }

    private func applyLineFadeAnimation_tk1(changedRange: NSRange, mask: CALayer, base: CALayer) {
        let glyphRange = self.layoutManager.glyphRange(
            forCharacterRange: changedRange, actualCharacterRange: nil
        )
        self.layoutManager.enumerateLineFragments(forGlyphRange: glyphRange) { [weak self]
            rect, usedRect, _, lineGlyphRange, _ in
            guard let self else { return }
            guard NSMaxRange(glyphRange) == NSMaxRange(lineGlyphRange) else { return }
            self.installLineFadeLayer(lineRect: rect, rightEdge: usedRect.maxX, mask: mask, base: base)
        }
    }

    /// 在遮罩层上为当前最末行追加或更新一个 LineFadeLayer。
    /// - Parameters:
    ///   - lineRect:  行片段矩形（用于确定 y 位置和行高）。
    ///   - rightEdge: 行内已用文字的右边界（TK1 用 usedRect.maxX；TK2 用 segment union 的 maxX）。
    private func installLineFadeLayer(lineRect rect: CGRect, rightEdge: CGFloat, mask: CALayer, base: CALayer) {
        base.frame = CGRect(x: 0, y: 0, width: mask.bounds.width, height: rect.minY)
        let tailWidth = max(8, self.lineFadeTrailingWidth)
        let lineDetectRect = CGRect(
            x: floor(rect.minX), y: floor(rect.minY),
            width: ceil(max(rect.width, rightEdge - rect.minX + tailWidth)),
            height: ceil(rect.height + 1)
        )
        var previousRightEdge: CGFloat?
        for sub in mask.sublayers ?? [] {
            guard let fl = sub as? LineFadeLayer else { continue }
            if lineDetectRect.contains(fl.frame) {
                previousRightEdge = max(previousRightEdge ?? rect.minX, fl.frame.maxX - tailWidth)
            }
            fl.removeFromSuperlayer()
        }
        let lineWidth = max(0, rightEdge - rect.minX)
        let newFrame = CGRect(
            x: rect.minX,
            y: rect.minY,
            width: lineWidth + tailWidth,
            height: rect.height
        )
        guard newFrame.width > 0.5, newFrame.height > 0.5 else { return }

        let fl = LineFadeLayer()
        fl.startPoint = CGPoint(x: 0, y: 0.5)
        fl.endPoint = CGPoint(x: 1, y: 0.5)
        fl.frame = newFrame
        fl.colors = [UIColor.black.cgColor, UIColor.black.cgColor, UIColor.clear.cgColor]
        let fadeStart = min(0.98, max(0, lineWidth / max(newFrame.width, 1)))
        fl.locations = [NSNumber(value: 0), NSNumber(value: Double(fadeStart)), NSNumber(value: 1)]
        let fromRightEdge = min(rightEdge, max(previousRightEdge ?? rect.minX, rect.minX))
        let fromFadeStart = min(0.98, max(0, (fromRightEdge - rect.minX) / max(newFrame.width, 1)))
        let anim = CABasicAnimation(keyPath: "locations")
        anim.fromValue = [
            NSNumber(value: 0),
            NSNumber(value: Double(fromFadeStart)),
            NSNumber(value: 1),
        ]
        anim.toValue = [
            NSNumber(value: 0),
            NSNumber(value: Double(fadeStart)),
            NSNumber(value: 1),
        ]
        anim.fillMode = .both
        anim.isRemovedOnCompletion = true
        anim.duration = lineFadeDuration
        self.setLineFadeAnimating(true)
        anim.delegate = LineFadeAnimationDelegate { [weak self, weak fl] in
            fl?.isFadeComplete = true
            guard let self else { return }
            let stillAnimating = (mask.sublayers ?? []).contains {
                guard let layer = $0 as? LineFadeLayer else { return false }
                return layer.animation(forKey: "fadeIn") != nil
            }
            if !stillAnimating {
                self.setLineFadeAnimating(false)
            }
        }
        mask.addSublayer(fl)
        fl.add(anim, forKey: "fadeIn")
    }

    private func setLineFadeAnimating(_ isAnimating: Bool) {
        guard self._isLineFadeAnimating != isAnimating else { return }
        self._isLineFadeAnimating = isAnimating
        self.onAnimationStateChange?(isAnimating)
    }

    /// 子类可重写：禁止系统长按复制/粘贴菜单，仅使用自定义 popupMenuItems（如 Bajoseek 回复区）
    open override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if self.suppressSystemTextMenu {
            return false
        }
        if action == #selector(UIResponderStandardEditActions.copy(_:))
            || action == #selector(UIResponderStandardEditActions.cut(_:))
            || action == #selector(UIResponderStandardEditActions.paste(_:))
            || action == #selector(UIResponderStandardEditActions.select(_:))
            || action == #selector(UIResponderStandardEditActions.selectAll(_:)) {
            return false
        }
        return super.canPerformAction(action, withSender: sender)
    }
}
