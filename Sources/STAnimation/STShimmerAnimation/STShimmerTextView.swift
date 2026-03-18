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

    private struct AnimatingColorRun {
        let range: NSRange
        let targetColor: UIColor
    }

    private struct AnimatingToken {
        let range: NSRange
        let startTime: CFTimeInterval
        let colorRuns: [AnimatingColorRun]
    }

    public var tokenFadeDuration: TimeInterval = 0.3
    public var suppressSystemTextMenu: Bool = false
    private var displayLink: CADisplayLink?
    private var animatingTokens: [AnimatingToken] = []
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

    public override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        self.setup()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setup()
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
        self.layoutManager.allowsNonContiguousLayout = false
    }

    public func append(_ text: String) {
        guard !text.isEmpty else { return }
        let startLocation = self.textStorage.length
        let baseColor = self.baseForegroundColor(from: self.defaultTextAttributes)
        // 在追加前，立即完成上一行（最后一个 \n 之前）的所有动画
        if self.tokenFadeDuration > 0 {
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
        // 保存 contentOffset：UITextView 在 textStorage 修改后可能意外偏移，
        // 导致非滚动文本视图出现上下抖动。在所有 textStorage 操作之前保存。
        let savedOffset = self.contentOffset
        // 在追加前，立即完成上一行（最后一个 \n 之前）的所有动画，
        // 确保前一段落完全显示后新段落才开始淡入，避免两段同时渲染的视觉问题。
        if animated, self.tokenFadeDuration > 0 {
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

        // 当 delta 内含换行符时，最后一个 \n 之前的内容属于已完成的行，
        // 直接以全不透明渲染（不做 fade-in 动画），只对最后一行（\n 之后的尾部片段）做淡入。
        // 这避免了大段 delta 同时淡入导致"多段同时渲染"的视觉问题，
        // 同时不引入 staggered delay，不会造成布局跳动。
        let deltaString = appended.string as NSString
        let lastNLInDelta = deltaString.range(of: "\n", options: .backwards)
        if lastNLInDelta.location != NSNotFound {
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
                let trailingStart = trailingRuns.map(\.range.location).min()!
                let trailingEnd = trailingRuns.map { $0.range.location + $0.range.length }.max()!
                let token = AnimatingToken(
                    range: NSRange(location: trailingStart, length: trailingEnd - trailingStart),
                    startTime: CACurrentMediaTime(),
                    colorRuns: trailingRuns
                )
                self.animatingTokens.append(token)
                self.startDisplayLinkIfNeeded()
            }
        } else {
            if self.contentOffset != savedOffset { self.contentOffset = savedOffset }
            let token = AnimatingToken(
                range: NSRange(location: startLocation, length: appended.length),
                startTime: CACurrentMediaTime(),
                colorRuns: colorRuns
            )
            self.animatingTokens.append(token)
            self.startDisplayLinkIfNeeded()
        }
    }

    public func setRenderedAttributedText(_ attributedText: NSAttributedString) {
        self.stopDisplayLink()
        self.animatingTokens.removeAll()
        _baseAttributedText = NSMutableAttributedString(attributedString: attributedText)
        self.textStorage.beginEditing()
        self.textStorage.setAttributedString(attributedText)
        self.textStorage.endEditing()
    }

    public func replaceTrailingAttributedText(from location: Int, with attributedText: NSAttributedString) {
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

        // 2. 同步更新 _baseAttributedText：保留 [0, clampedLocation) 前缀 + 新尾部
        let clampedBaseLocation = max(0, min(location, _baseAttributedText.length))
        let newBase = NSMutableAttributedString(
            attributedString: _baseAttributedText.attributedSubstring(
                from: NSRange(location: 0, length: clampedBaseLocation)
            )
        )
        newBase.append(attributedText)
        _baseAttributedText = newBase

        // 3. 直接替换 textStorage 中的尾部内容（不做 fade-in 动画）。
        //    replaceTrailing 通常在 markdown 重解析后调用，属性变化但文本大致相同，
        //    此处不做淡入以避免频繁替换时反复从 alpha=0 开始导致闪烁。
        self.textStorage.beginEditing()
        self.textStorage.replaceCharacters(
            in: NSRange(location: clampedLocation, length: self.textStorage.length - clampedLocation),
            with: attributedText
        )
        self.textStorage.endEditing()
        if self.contentOffset != savedOffset { self.contentOffset = savedOffset }
        self.stopDisplayLink()
    }

    public func reset() {
        self.stopDisplayLink()
        self.animatingTokens.removeAll()
        _baseAttributedText = NSMutableAttributedString()
        self.textStorage.beginEditing()
        self.textStorage.setAttributedString(NSAttributedString())
        self.textStorage.endEditing()
    }

    public func finishAnimations() {
        self.stopDisplayLink()
        let pendingTokens = self.animatingTokens
        self.animatingTokens.removeAll()
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

    private func startDisplayLinkIfNeeded() {
        guard self.displayLink == nil else { return }
        let link = CADisplayLink(target: self, selector: #selector(self.handleDisplayLink))
        link.add(to: .main, forMode: .common)
        self.displayLink = link
    }

    private func stopDisplayLink() {
        self.displayLink?.invalidate()
        self.displayLink = nil
    }

    @objc private func handleDisplayLink() {
        guard !self.animatingTokens.isEmpty else {
            self.stopDisplayLink()
            return
        }
        let now = CACurrentMediaTime()
        var completedIndices: [Int] = []
        let savedOffset = self.contentOffset
        self.textStorage.beginEditing()
        for (index, token) in self.animatingTokens.enumerated() {
            let elapsed = now - token.startTime
            let progress = min(1.0, elapsed / self.tokenFadeDuration)
            let easedProgress = 1.0 - pow(1.0 - progress, 3.0)
            for run in token.colorRuns {
                let color = run.targetColor.withAlphaComponent(CGFloat(easedProgress))
                self.textStorage.addAttribute(.foregroundColor, value: color, range: run.range)
            }
            if progress >= 1.0 {
                completedIndices.append(index)
            }
        }
        self.textStorage.endEditing()
        if self.contentOffset != savedOffset {
            self.contentOffset = savedOffset
        }
        for index in completedIndices.reversed() {
            self.animatingTokens.remove(at: index)
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
