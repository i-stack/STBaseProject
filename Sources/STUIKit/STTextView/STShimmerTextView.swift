//
//  STShimmerTextView.swift
//  Bajoseek
//
//  Created by 寒江孤影 on 2026/2/3.
//

import UIKit

open class STShimmerTextView: UITextView {

    /// 在 NSAttributedString 中标记此 key 的 range 不参与 fade-in 动画，
    /// 直接以最终颜色渲染。用于 list marker、block separator、heading 等结构元素。
    public static let skipFadeInAttributeKey = NSAttributedString.Key("STShimmerTextView.skipFadeIn")

    // MARK: - LineFadeLayer（行级 CAGradientLayer 遮罩扫入动画）
    private final class LineFadeLayer: CAGradientLayer {
        /// 动画已完成（待下次 applyLineFadeAnimation 时清理折入基底层）。
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
        /// 逐字 stagger 间隔：colorRuns 中第 i 个字符的实际 startTime = startTime + i * staggerInterval。
        /// 为 0 时所有字符同时 fade-in（原始行为）。
        let staggerInterval: TimeInterval
        let colorRuns: [AnimatingColorRun]
    }

    public var tokenFadeDuration: TimeInterval = 0.3
    /// 逐字 stagger 间隔：每个字符的 fade-in 起始时间比前一个字符延迟此值，
    /// 使多字符 delta 呈现"逐字出现"而非"整段同时出现"的效果。
    /// 设为 0 则禁用 stagger（所有字符同时 fade-in）。
    public var characterStaggerInterval: TimeInterval = 0.016
    /// 为 true 时，跨换行也保持连续字符级渐显；
    /// 为 false 时，新增 delta 中最后一个换行前的内容会立即显示，仅最后一行保留动画。
    public var animateAcrossNewlines: Bool = false
    /// `true` 时改用 FluidMarkdown 风格的行级 CAGradientLayer 水平扫入遮罩动画，
    /// 替代默认的字符级 foregroundColor 淡入；由 STMarkdownStreamingTextView 根据样式同步。
    public var lineFadeMode: Bool = false
    /// 行级扫入动画时长（秒），默认 0.15 s，与 FluidMarkdown 对齐。
    public var lineFadeDuration: TimeInterval = 0.15
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
        self.displayLink != nil && !self.animatingTokens.isEmpty
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
            // UITextView(frame:textContainer:nil) 在 iOS 16+ 默认启用 TextKit 2，
            // 导致 textLayoutManager != nil；行级遮罩动画依赖 NSLayoutManager，
            // 必须通过 UITextView(usingTextLayoutManager:) 显式指定版本。
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
        // iOS 16+ 若已启用 TextKit 2（`textLayoutManager != nil`），访问 `layoutManager` 会强制降级到
        // TK1 兼容栈并在控制台产生 `_UITextViewEnablingCompatibilityMode` 告警；仅在经典 TK1 路径下设置。
        if #available(iOS 16.0, *) {
            if self.textLayoutManager == nil {
                self.layoutManager.allowsNonContiguousLayout = false
            }
        } else {
            self.layoutManager.allowsNonContiguousLayout = false
        }
    }

    public func append(_ text: String) {
        guard !text.isEmpty else { return }
        let startLocation = self.textStorage.length
        let baseColor = self.baseForegroundColor(from: self.defaultTextAttributes)
        // 在追加前，立即完成上一行（最后一个 \n 之前）的所有动画
        if self.tokenFadeDuration > 0, !self.animateAcrossNewlines {
            self.finishAnimationsBeforeLastNewline()
        }
        // _baseAttributedText 记录全不透明最终态
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
        // 保存 contentOffset：UITextView 在 textStorage 修改后可能意外偏移。
        let savedOffset = self.contentOffset

        // 行级 CAGradientLayer 扫入模式：文本保持全不透明，由遮罩层控制可见性。
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

        // 在追加前，立即完成上一行（最后一个 \n 之前）的所有动画
        if animated, self.tokenFadeDuration > 0, !self.animateAcrossNewlines {
            self.finishAnimationsBeforeLastNewline()
        }
        // _baseAttributedText 记录全不透明最终态，必须在 applyTransparentForegroundColors
        // 之前追加，保留原始 alpha=1 颜色。
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

        // 默认策略：当 delta 内含换行符时，最后一个 \n 之前的内容立即显示，只对最后一行做淡入。
        // 聊天流式场景要求严格逐字输出时，会开启 animateAcrossNewlines，整个 delta 都走字符级渐显。
        let deltaString = appended.string as NSString
        let lastNLInDelta = deltaString.range(of: "\n", options: .backwards)
        if !self.animateAcrossNewlines, lastNLInDelta.location != NSNotFound {
            let splitPos = lastNLInDelta.location + lastNLInDelta.length  // local offset in delta
            // 立即完成 splitPos 之前的 colorRuns
            self.textStorage.beginEditing()
            var trailingRuns: [AnimatingColorRun] = []
            for run in colorRuns {
                let runLocalStart = run.range.location - startLocation
                let runLocalEnd = runLocalStart + run.range.length
                if runLocalEnd <= splitPos {
                    // run 完全在 \n 之前 → 立即显示
                    self.textStorage.addAttribute(.foregroundColor, value: run.targetColor, range: run.range)
                } else if runLocalStart >= splitPos {
                    // run 完全在 \n 之后 → 保留动画
                    trailingRuns.append(run)
                } else {
                    // run 横跨 \n → 拆分
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
            // 只对尾部片段（最后一个 \n 之后的内容）创建动画 token
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

    public func replaceTrailingAttributedText(
        from location: Int,
        with attributedText: NSAttributedString,
        animateNewPortion: Bool = true
    ) {
        let clampedLocation = max(0, min(location, self.textStorage.length))
        let savedOffset = self.contentOffset

        // 1. 立即完成前缀区域内仍在动画的 token，丢弃与尾部重叠的 token
        if !self.animatingTokens.isEmpty {
            self.textStorage.beginEditing()
            for token in self.animatingTokens {
                let tokenEnd = token.range.location + token.range.length
                if tokenEnd <= clampedLocation {
                    // token 在前缀区域内 → 立即完成动画
                    for run in token.colorRuns {
                        self.textStorage.addAttribute(.foregroundColor, value: run.targetColor, range: run.range)
                    }
                }
                // token 与尾部重叠 → 丢弃（即将被替换）
            }
            self.textStorage.endEditing()
        }
        self.animatingTokens.removeAll()
        if self.lineFadeMode { self.removeLineFadeMask() }

        // 计算旧尾部字符串，用于后续判断哪些是"真正新增"的字符
        let oldTrailingLength = self.textStorage.length - clampedLocation
        let oldTrailingString: String
        if oldTrailingLength > 0 {
            oldTrailingString = (self.textStorage.string as NSString)
                .substring(with: NSRange(location: clampedLocation, length: oldTrailingLength))
        } else {
            oldTrailingString = ""
        }

        // 2. 同步更新 _baseAttributedText：保留 [0, clampedLocation) 前缀 + 新尾部
        let clampedBaseLocation = max(0, min(location, _baseAttributedText.length))
        let newBase = NSMutableAttributedString(
            attributedString: _baseAttributedText.attributedSubstring(
                from: NSRange(location: 0, length: clampedBaseLocation)
            )
        )
        newBase.append(attributedText)
        _baseAttributedText = newBase

        // 3. 替换 textStorage 中的尾部内容。
        //    对已有文本部分（旧尾部与新尾部的公共前缀）直接以最终颜色渲染（不做 fade-in），
        //    对真正新增的字符执行逐字 stagger fade-in 动画。
        let newTrailingString = attributedText.string
        let commonPrefixCount = oldTrailingString.commonPrefix(with: newTrailingString).utf16.count

        // 准备新尾部的 appended 副本用于提取 colorRuns
        let appended = NSMutableAttributedString(attributedString: attributedText)
        let defaultColor = self.baseForegroundColor(from: self.defaultTextAttributes)
        self.ensureForegroundColor(in: appended, defaultColor: defaultColor)

        // 对真正新增的部分（公共前缀之后）提取 colorRuns 并设置透明
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
            // 提取 colorRuns（从新增部分）
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
            // 将新增部分在 appended 中设为透明
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

        // 对新增字符启动逐字 stagger 动画
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
        guard !colorRuns.isEmpty else { return }
        let start = colorRuns.map(\.range.location).min()!
        let end = colorRuns.map { $0.range.location + $0.range.length }.max()!
        let totalLength = colorRuns.reduce(0) { $0 + $1.range.length }
        // 字符数 ≤ 2 或 stagger 为 0 时不使用 stagger
        let stagger = (self.characterStaggerInterval > 0 && totalLength > 2)
            ? self.characterStaggerInterval : 0
        let token = AnimatingToken(
            range: NSRange(location: start, length: end - start),
            startTime: CACurrentMediaTime(),
            staggerInterval: stagger,
            colorRuns: colorRuns
        )
        self.animatingTokens.append(token)
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
                // 无 stagger：所有 colorRuns 共享同一进度
                let elapsed = now - token.startTime
                let progress = min(1.0, elapsed / fadeDuration)
                let easedProgress = 1.0 - pow(1.0 - progress, 3.0)
                for run in token.colorRuns {
                    let color = run.targetColor.withAlphaComponent(CGFloat(easedProgress))
                    self.textStorage.addAttribute(.foregroundColor, value: color, range: run.range)
                }
            } else {
                // 有 stagger：逐字符计算进度，每个字符独立的 startTime
                var charIndex = 0
                for run in token.colorRuns {
                    for offset in 0..<run.range.length {
                        let charStartTime = token.startTime + Double(charIndex) * token.staggerInterval
                        let elapsed = now - charStartTime
                        let progress = min(1.0, max(0, elapsed / fadeDuration))
                        let easedProgress = 1.0 - pow(1.0 - progress, 3.0)
                        let color = run.targetColor.withAlphaComponent(CGFloat(easedProgress))
                        let charRange = NSRange(location: run.range.location + offset, length: 1)
                        self.textStorage.addAttribute(.foregroundColor, value: color, range: charRange)
                        charIndex += 1
                    }
                }
            }
        }
        self.textStorage.endEditing()
        if self.contentOffset != savedOffset {
            self.contentOffset = savedOffset
        }
        // 移除已完成的 token：所有字符都已完成 fade-in
        self.animatingTokens.removeAll { token in
            let totalChars = token.colorRuns.reduce(0) { $0 + $1.range.length }
            let lastCharStart = token.startTime + Double(max(0, totalChars - 1)) * token.staggerInterval
            return (now - lastCharStart) >= fadeDuration
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
            // 跳过含 NSTextAttachment 的字符（如 citation 圆圈），
            // 它们的视觉由 attachment image 决定，不应被 alpha 动画影响。
            if attributedText.attribute(.attachment, at: subrange.location, effectiveRange: nil) != nil {
                return
            }
            // 跳过标记了 skipFadeIn 的 range（list marker、block separator 等结构元素），
            // 它们需要直接以最终颜色渲染，不做 alpha 渐变。
            if attributedText.attribute(Self.skipFadeInAttributeKey, at: subrange.location, effectiveRange: nil) != nil {
                return
            }
            let color = (value as? UIColor) ?? defaultColor
            // 跳过已经透明的颜色（如 blockSeparator 的 UIColor.clear），
            // 避免 withAlphaComponent(0) 将 (0,0,0,0) 变为 (0,0,0,0) 后在动画中渐变为 (0,0,0,progress)。
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
            // 跳过 NSTextAttachment 字符，不参与 fade-in 动画
            if attributedText.attribute(.attachment, at: subrange.location, effectiveRange: nil) != nil {
                return
            }
            // 跳过标记了 skipFadeIn 的 range
            if attributedText.attribute(Self.skipFadeInAttributeKey, at: subrange.location, effectiveRange: nil) != nil {
                return
            }
            // 跳过已透明的颜色（blockSeparator 等），它们不需要 fade-in
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
        // 在 [0, len) 范围内倒序查找最后一个换行符
        let lastNLRange = str.range(of: "\n", options: .backwards, range: NSRange(location: 0, length: len))
        guard lastNLRange.location != NSNotFound else { return }
        // boundary：最后一个 \n 之后的第一个字符位置；此位置之前的 token 全部立即完成
        let boundary = lastNLRange.location + lastNLRange.length

        var completedIndices: [Int] = []
        var splitReplacements: [(index: Int, newToken: AnimatingToken)] = []
        self.textStorage.beginEditing()
        for (idx, token) in self.animatingTokens.enumerated() {
            let tokenEnd = token.range.location + token.range.length
            if tokenEnd <= boundary {
                // token 完全在 boundary 之前 → 立即完成全部动画
                for run in token.colorRuns {
                    self.textStorage.addAttribute(.foregroundColor, value: run.targetColor, range: run.range)
                }
                completedIndices.append(idx)
            } else if token.range.location < boundary {
                // token 横跨 boundary → 拆分：boundary 之前的部分立即完成，之后的部分保留动画
                var beforeRuns: [AnimatingColorRun] = []
                var afterRuns: [AnimatingColorRun] = []
                for run in token.colorRuns {
                    let runEnd = run.range.location + run.range.length
                    if runEnd <= boundary {
                        // run 完全在 boundary 之前
                        beforeRuns.append(run)
                    } else if run.range.location >= boundary {
                        // run 完全在 boundary 之后
                        afterRuns.append(run)
                    } else {
                        // run 横跨 boundary → 拆成两段
                        let beforeLength = boundary - run.range.location
                        let beforeRange = NSRange(location: run.range.location, length: beforeLength)
                        beforeRuns.append(AnimatingColorRun(range: beforeRange, targetColor: run.targetColor))
                        let afterLength = runEnd - boundary
                        let afterRange = NSRange(location: boundary, length: afterLength)
                        afterRuns.append(AnimatingColorRun(range: afterRange, targetColor: run.targetColor))
                    }
                }
                // 立即完成 boundary 之前的部分
                for run in beforeRuns {
                    self.textStorage.addAttribute(.foregroundColor, value: run.targetColor, range: run.range)
                }
                if afterRuns.isEmpty {
                    completedIndices.append(idx)
                } else {
                    // 用剩余的 afterRuns 替换原 token，保持原始 startTime
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
            // token 完全在 boundary 之后 → 不处理，继续动画
        }
        self.textStorage.endEditing()
        // 应用拆分替换
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

    // MARK: - Line Fade Mask

    private func removeLineFadeMask() {
        guard _lineFadeMaskLayer != nil else { return }
        self.layer.mask = nil
        _lineFadeMaskLayer = nil
        _lineFadeBaseLayer = nil
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
        // FluidMarkdown 对齐：补偿滚动偏移（isScrollEnabled=false 时为 identity，仍保留以确保正确性）
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

        // 按 minY 分组得到最末行的 union 矩形
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
        // 基础层覆盖当前行以上的所有内容
        base.frame = CGRect(x: 0, y: 0, width: mask.bounds.width, height: rect.minY)

        // lineDetectRect：稍扩展以容纳浮点误差（与 FluidMarkdown 相同）
        let lineDetectRect = CGRect(
            x: floor(rect.minX), y: floor(rect.minY),
            width: ceil(rect.width), height: ceil(rect.height + 1)
        )
        var latestX: CGFloat = rect.minX
        for sub in mask.sublayers ?? [] {
            guard let fl = sub as? LineFadeLayer else { continue }
            if lineDetectRect.contains(fl.frame) {
                if fl.isFadeComplete {
                    // 已完成的层：折入基础层并移除
                    fl.removeFromSuperlayer()
                    base.frame = CGRect(x: 0, y: 0, width: mask.bounds.width, height: rect.maxY)
                } else {
                    latestX = max(latestX, fl.frame.maxX)
                }
            } else {
                // 其他行的旧层：基础层已覆盖，直接移除
                fl.removeFromSuperlayer()
            }
        }

        let newFrame = CGRect(x: latestX, y: rect.minY, width: rightEdge - latestX, height: rect.height)
        guard newFrame.width > 0.5, newFrame.height > 0.5 else { return }

        // 去重：整数像素级别比较（FluidMarkdown 用 CGRectIntegral）
        let isDuplicate = (mask.sublayers ?? []).compactMap { $0 as? LineFadeLayer }.contains {
            CGRectEqualToRect(CGRectIntegral($0.frame), CGRectIntegral(newFrame))
        }
        guard !isDuplicate else { return }

        let fl = LineFadeLayer()
        fl.startPoint = CGPoint(x: 0, y: 0.5)
        fl.endPoint = CGPoint(x: 1, y: 0.5)
        fl.frame = newFrame
        // 模型值 = 最终状态（动画移除后 layer 回退到此值，无视觉跳变）
        fl.colors = [UIColor.black.cgColor, UIColor.black.cgColor]

        let anim = CAKeyframeAnimation(keyPath: "colors")
        anim.values = [
            [UIColor.clear.cgColor, UIColor.clear.cgColor],
            [UIColor.black.cgColor, UIColor.clear.cgColor],
            [UIColor.black.cgColor, UIColor.black.cgColor],
        ]
        anim.calculationMode = .linear
        anim.fillMode = .both               // FluidMarkdown: kCAFillModeBoth
        anim.isRemovedOnCompletion = true   // FluidMarkdown: removedOnCompletion = YES
        anim.duration = lineFadeDuration
        anim.delegate = LineFadeAnimationDelegate { [weak fl] in
            fl?.isFadeComplete = true       // 供下次 applyLineFadeAnimation 做懒清理
        }
        mask.addSublayer(fl)
        fl.add(anim, forKey: "fadeIn")
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
