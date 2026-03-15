//
//  STShimmerTextView.swift
//  Bajoseek
//
//  Created by 寒江孤影 on 2026/2/3.
//

import UIKit

open class STShimmerTextView: UITextView {

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

    open var defaultTextAttributes: [NSAttributedString.Key: Any] {
        return [
            .font: self.font ?? UIFont.systemFont(ofSize: 16),
            .foregroundColor: self.textColor ?? UIColor.label,
        ]
    }

    public var renderedAttributedText: NSAttributedString {
        self.attributedText ?? NSAttributedString()
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
        self.font = .systemFont(ofSize: 16)
        self.textColor = .label
        self.layoutManager.allowsNonContiguousLayout = false
    }

    public func append(_ text: String) {
        guard !text.isEmpty else { return }
        let startLocation = self.textStorage.length
        var attrs = self.defaultTextAttributes
        let baseColor = self.baseForegroundColor(from: attrs)
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
        let colorRuns = self.animatingColorRuns(in: appended, offset: startLocation)
        if animated {
            self.applyTransparentForegroundColors(to: appended, defaultColor: defaultColor)
        }
        self.textStorage.beginEditing()
        self.textStorage.append(appended)
        self.textStorage.endEditing()
        guard animated, self.tokenFadeDuration > 0, !colorRuns.isEmpty else { return }
        let token = AnimatingToken(
            range: NSRange(location: startLocation, length: appended.length),
            startTime: CACurrentMediaTime(),
            colorRuns: colorRuns
        )
        self.animatingTokens.append(token)
        self.startDisplayLinkIfNeeded()
    }

    public func setRenderedAttributedText(_ attributedText: NSAttributedString) {
        self.stopDisplayLink()
        self.animatingTokens.removeAll()
        self.textStorage.beginEditing()
        self.textStorage.setAttributedString(attributedText)
        self.textStorage.endEditing()
    }

    public func replaceTrailingAttributedText(from location: Int, with attributedText: NSAttributedString) {
        let clampedLocation = max(0, min(location, self.textStorage.length))
        self.stopDisplayLink()
        self.animatingTokens.removeAll()
        self.textStorage.beginEditing()
        self.textStorage.replaceCharacters(
            in: NSRange(location: clampedLocation, length: self.textStorage.length - clampedLocation),
            with: attributedText
        )
        self.textStorage.endEditing()
    }

    public func reset() {
        self.stopDisplayLink()
        self.animatingTokens.removeAll()
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
            let color = (value as? UIColor) ?? defaultColor
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
