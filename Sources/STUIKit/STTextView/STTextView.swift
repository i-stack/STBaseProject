//
//  STTextView.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2018/10/12.
//

import UIKit

public protocol STTextViewDelegate: NSObjectProtocol {
    func st_textViewEditingChanged(textView: STTextView)
    func st_textViewDidReachMaxTextCount(textView: STTextView, maxCount: Int)
    func st_textViewTextCountDidChange(textView: STTextView, currentCount: Int, maxCount: Int)
    func st_textViewWillChangeHeight(textView: STTextView, from oldHeight: CGFloat, to newHeight: CGFloat)
    func st_textViewHeightDidChange(textView: STTextView, currentHeight: CGFloat, isReachMaxHeight: Bool)
    func st_textViewDidChangeHeight(textView: STTextView, from oldHeight: CGFloat, to newHeight: CGFloat)
    func st_textViewShouldChangeText(textView: STTextView, in range: NSRange, replacementText text: String) -> Bool
}

public extension STTextViewDelegate {
    func st_textViewEditingChanged(textView: STTextView) {}
    func st_textViewDidReachMaxTextCount(textView: STTextView, maxCount: Int) {}
    func st_textViewTextCountDidChange(textView: STTextView, currentCount: Int, maxCount: Int) {}
    func st_textViewWillChangeHeight(textView: STTextView, from oldHeight: CGFloat, to newHeight: CGFloat) {}
    func st_textViewHeightDidChange(textView: STTextView, currentHeight: CGFloat, isReachMaxHeight: Bool) {}
    func st_textViewDidChangeHeight(textView: STTextView, from oldHeight: CGFloat, to newHeight: CGFloat) {}
    func st_textViewShouldChangeText(textView: STTextView, in range: NSRange, replacementText text: String) -> Bool { true }
}

public typealias STTextViewHeightChangeUserActionsBlock = (_ oldHeight: CGFloat, _ newHeight: CGFloat) -> Void

@IBDesignable
open class STTextView: STPlaceholderTextView {

    weak open var cusDelegate: STTextViewDelegate?

    open var shouldLimitTextCount: Bool = true
    open private(set) var currentTextCount: Int = 0
    open private(set) var currentInputHeight: CGFloat = 0
    open private(set) var isReachMaxInputHeight: Bool = false
    open var heightChangeUserActionsBlock: STTextViewHeightChangeUserActionsBlock?

    private weak var heightConstraint: NSLayoutConstraint?
    private var lastReportedHeight: CGFloat = 0

    // MARK: - Appearance

    /// Setting cornerRadius > 0 automatically adjusts contentInsets to match the rounded corners.
    @IBInspectable open var cornerRadius: CGFloat {
        get { return self.layer.cornerRadius }
        set {
            self.layer.cornerRadius = newValue
            self.layer.masksToBounds = newValue > 0
            if newValue > 0 {
                self.contentInsets = UIEdgeInsets(
                    top: newValue * 0.5,
                    left: newValue,
                    bottom: newValue * 0.5,
                    right: newValue
                )
            }
        }
    }

    @IBInspectable open var borderWidth: CGFloat {
        get { return self.layer.borderWidth }
        set { self.layer.borderWidth = newValue > 0 ? newValue : 0 }
    }

    @IBInspectable open var borderColor: UIColor {
        get {
            guard let color = self.layer.borderColor else { return .clear }
            return UIColor(cgColor: color)
        }
        set { self.layer.borderColor = newValue.cgColor }
    }

    @IBInspectable open var animateHeightChange: Bool = true
    @IBInspectable open var heightChangeAnimationDuration: Double = 0.35

    @IBInspectable open var minimumNumberOfLines: Int = 1 {
        didSet {
            if self.minimumNumberOfLines < 1 {
                self.minimumNumberOfLines = 1
            }
            if self.maximumNumberOfLines > 0, self.minimumNumberOfLines > self.maximumNumberOfLines {
                self.minimumNumberOfLines = self.maximumNumberOfLines
            }
            self.updateHeightIfNeeded(notify: true, animated: false)
        }
    }

    /// Set to 0 for unlimited height. Set to a positive value to enable scrolling after the given line count.
    @IBInspectable open var maximumNumberOfLines: Int = 0 {
        didSet {
            if self.maximumNumberOfLines < 0 {
                self.maximumNumberOfLines = 0
            }
            if self.maximumNumberOfLines > 0, self.maximumNumberOfLines < self.minimumNumberOfLines {
                self.maximumNumberOfLines = self.minimumNumberOfLines
            }
            self.updateHeightIfNeeded(notify: true, animated: false)
        }
    }

    open var numberOfLines: Int {
        self.layoutManager.ensureLayout(for: self.textContainer)
        var lineCount = 0
        var index = 0
        var lineRange = NSRange()
        let numberOfGlyphs = self.layoutManager.numberOfGlyphs
        while index < numberOfGlyphs {
            _ = self.layoutManager.lineFragmentRect(forGlyphAt: index, effectiveRange: &lineRange)
            index = NSMaxRange(lineRange)
            lineCount += 1
        }
        return lineCount
    }

    open var maxTextHeight: CGFloat = CGFloat.greatestFiniteMagnitude {
        didSet {
            self.updateHeightIfNeeded(notify: true, animated: false)
        }
    }

    @IBInspectable open var maxTextCount: Int = -1 {
        didSet {
            self.enforceTextCountIfNeeded()
            self.notifyTextCount()
        }
    }

    @IBInspectable public var maxInputHeight: CGFloat {
        get { return self.maxTextHeight == CGFloat.greatestFiniteMagnitude ? 0 : self.maxTextHeight }
        set {
            self.maxTextHeight = newValue > 0 ? newValue : CGFloat.greatestFiniteMagnitude
        }
    }

    public override var font: UIFont? {
        didSet {
            self.updateHeightIfNeeded(notify: true, animated: false)
        }
    }

    public override var textColor: UIColor? {
        didSet {
            self.typingAttributes[.foregroundColor] = self.textColor ?? UIColor.label
        }
    }

    public override var bounds: CGRect {
        didSet {
            if oldValue.size.width != self.bounds.size.width {
                self.updateHeightIfNeeded(notify: true, animated: false)
            }
        }
    }

    public override var contentSize: CGSize {
        didSet {
            guard oldValue != self.contentSize else { return }
            let animated = self.window != nil && self.isFirstResponder && self.animateHeightChange
            self.updateHeightIfNeeded(notify: true, animated: animated)
        }
    }

    public override var intrinsicContentSize: CGSize {
        if self.heightConstraint != nil {
            return CGSize(width: UIView.noIntrinsicMetric, height: UIView.noIntrinsicMetric)
        }
        return CGSize(width: UIView.noIntrinsicMetric, height: self.calculatedHeight())
    }

    public override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        self.config()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.config()
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
        self.updateHeightConstraintIfNeeded()
    }

    open override func didMoveToSuperview() {
        super.didMoveToSuperview()
        self.updateHeightConstraintIfNeeded()
        self.updateHeightIfNeeded(notify: false, animated: false)
    }

    open override func sizeThatFits(_ size: CGSize) -> CGSize {
        let fittingHeight = self.fittingContentHeight(for: size.width)
        let height = self.clampedHeight(for: fittingHeight)
        return CGSize(width: size.width, height: height)
    }

    open override func sizeToFit() {
        self.bounds.size.height = self.calculatedHeight()
    }

    open override func st_placeholderTextDidChange() {
        self.handleTextChange()
    }

    open override func st_placeholderHeightAffectingChange() {
        self.updateHeightIfNeeded(notify: true, animated: false)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    public func config(textLimitCount: Int) {
        self.maxTextCount = textLimitCount
    }

    public func config(maxInputHeight: CGFloat) {
        self.maxTextHeight = maxInputHeight > 0 ? maxInputHeight : CGFloat.greatestFiniteMagnitude
    }

    public func config(minimumNumberOfLines: Int, maximumNumberOfLines: Int) {
        self.minimumNumberOfLines = minimumNumberOfLines
        self.maximumNumberOfLines = maximumNumberOfLines
    }

    public func config(text: String?, textFont: UIFont? = nil, textColor: UIColor? = nil) {
        if let textFont {
            self.font = textFont
            self.typingAttributes[.font] = textFont
        }
        if let textColor {
            self.textColor = textColor
            self.typingAttributes[.foregroundColor] = textColor
        }
        self.text = text
    }

    private func config() {
        self.isScrollEnabled = false
        self.delegate = self
        self.keyboardDismissMode = .interactive
        self.alwaysBounceVertical = false
        self.typingAttributes[.font] = self.font ?? UIFont.st_systemFont(ofSize: 16)
        self.typingAttributes[.foregroundColor] = self.textColor ?? UIColor.label
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.handleTextDidChangeNotification(_:)),
            name: UITextView.textDidChangeNotification,
            object: self
        )
        self.updateHeightConstraintIfNeeded()
        self.updateHeightIfNeeded(notify: false, animated: false)
    }

    private func minTextHeight() -> CGFloat {
        return self.heightForNumberOfLines(self.minimumNumberOfLines)
    }

    private func maxTextHeightLimit() -> CGFloat {
        let lineBasedMaxHeight = self.maximumNumberOfLines > 0
            ? self.heightForNumberOfLines(self.maximumNumberOfLines)
            : CGFloat.greatestFiniteMagnitude
        return min(self.maxTextHeight, lineBasedMaxHeight)
    }

    private func heightForNumberOfLines(_ numberOfLines: Int) -> CGFloat {
        let font = self.typingAttributes[.font] as? UIFont ?? self.font ?? UIFont.st_systemFont(ofSize: 16)
        var lineHeight = font.lineHeight
        if let paragraphStyle = self.typingAttributes[.paragraphStyle] as? NSParagraphStyle {
            if paragraphStyle.lineHeightMultiple > 0 {
                lineHeight *= paragraphStyle.lineHeightMultiple
            }
            if paragraphStyle.minimumLineHeight > 0, lineHeight < paragraphStyle.minimumLineHeight {
                lineHeight = paragraphStyle.minimumLineHeight
            } else if paragraphStyle.maximumLineHeight > 0, lineHeight > paragraphStyle.maximumLineHeight {
                lineHeight = paragraphStyle.maximumLineHeight
            }
            lineHeight += paragraphStyle.lineSpacing
        }
        return ceil(self.textContainerInset.top + self.textContainerInset.bottom + lineHeight * CGFloat(numberOfLines))
    }

    private func fittingContentHeight(for width: CGFloat) -> CGFloat {
        let targetWidth = width > 0 ? width : UIScreen.main.bounds.width
        let textViewFitting = super.sizeThatFits(
            CGSize(width: targetWidth, height: CGFloat.greatestFiniteMagnitude)
        ).height
        let placeholderHeight = self.placeholderFittingHeight(for: targetWidth)
        guard (self.text ?? "").isEmpty, placeholderHeight > 0 else {
            return textViewFitting
        }
        return max(textViewFitting, placeholderHeight)
    }

    private func clampedHeight(for fittingHeight: CGFloat) -> CGFloat {
        return ceil(max(self.minTextHeight(), min(self.maxTextHeightLimit(), fittingHeight)))
    }

    private func calculatedHeight() -> CGFloat {
        let targetWidth = self.bounds.width > 0 ? self.bounds.width : UIScreen.main.bounds.width
        return self.clampedHeight(for: self.fittingContentHeight(for: targetWidth))
    }

    private func handleTextChange() {
        self.enforceTextCountIfNeeded()
        self.updateHeightIfNeeded(notify: true, animated: self.shouldAnimateHeightChangeNow())
        self.notifyTextCount()
    }

    private func enforceTextCountIfNeeded() {
        guard self.shouldLimitTextCount, self.maxTextCount > 0 else { return }
        let value = self.text ?? ""
        guard value.count > self.maxTextCount else { return }
        self.text = String(value.prefix(self.maxTextCount))
        self.cusDelegate?.st_textViewDidReachMaxTextCount(textView: self, maxCount: self.maxTextCount)
    }

    private func notifyTextCount() {
        let currentCount = (self.text ?? "").count
        self.currentTextCount = currentCount
        guard self.maxTextCount > 0 else { return }
        self.cusDelegate?.st_textViewTextCountDidChange(
            textView: self,
            currentCount: currentCount,
            maxCount: self.maxTextCount
        )
    }

    @objc private func handleTextDidChangeNotification(_ notification: Notification) {
        self.updateHeightIfNeeded(notify: true, animated: self.shouldAnimateHeightChangeNow())
    }

    private func shouldAnimateHeightChangeNow() -> Bool {
        return self.animateHeightChange && self.window != nil && self.isFirstResponder
    }

    private func updateHeightIfNeeded(notify: Bool, animated: Bool) {
        self.invalidateIntrinsicContentSize()
        self.updateHeightConstraintIfNeeded()
        let targetWidth = self.bounds.width > 0 ? self.bounds.width : UIScreen.main.bounds.width
        let fittingHeight = self.fittingContentHeight(for: targetWidth)
        let currentHeight = self.clampedHeight(for: fittingHeight)
        let maxHeightLimit = self.maxTextHeightLimit()
        let isReachMaxHeight = fittingHeight >= maxHeightLimit && maxHeightLimit < CGFloat.greatestFiniteMagnitude
        self.currentInputHeight = currentHeight
        self.isReachMaxInputHeight = isReachMaxHeight
        self.isScrollEnabled = isReachMaxHeight
        let oldHeight = self.currentDisplayedHeight()
        guard currentHeight != self.lastReportedHeight else {
            if currentHeight != oldHeight {
                self.setHeight(currentHeight)
            }
            if isReachMaxHeight {
                self.scrollToVisibleCaretIfNeeded()
            }
            return
        }
        let applyHeightChange = {
            self.setHeight(currentHeight)
            self.heightChangeUserActionsBlock?(oldHeight, currentHeight)
            self.superview?.layoutIfNeeded()
        }
        let completeHeightChange = {
            self.layoutManager.ensureLayout(for: self.textContainer)
            self.scrollToVisibleCaretIfNeeded()
            self.lastReportedHeight = currentHeight
            if notify {
                self.cusDelegate?.st_textViewHeightDidChange(
                    textView: self,
                    currentHeight: currentHeight,
                    isReachMaxHeight: isReachMaxHeight
                )
                self.cusDelegate?.st_textViewDidChangeHeight(textView: self, from: oldHeight, to: currentHeight)
            }
        }
        if notify {
            self.cusDelegate?.st_textViewWillChangeHeight(textView: self, from: oldHeight, to: currentHeight)
        }
        if animated {
            UIView.animate(
                withDuration: self.heightChangeAnimationDuration,
                delay: 0,
                options: [.allowUserInteraction, .beginFromCurrentState],
                animations: applyHeightChange,
                completion: { _ in completeHeightChange() }
            )
        } else {
            applyHeightChange()
            completeHeightChange()
        }
    }

    private func currentDisplayedHeight() -> CGFloat {
        if let heightConstraint = self.heightConstraint {
            return ceil(heightConstraint.constant)
        }
        if self.bounds.height > 0 {
            return ceil(self.bounds.height)
        }
        return ceil(self.lastReportedHeight)
    }

    private func setHeight(_ height: CGFloat) {
        if let heightConstraint = self.heightConstraint {
            heightConstraint.constant = height
        } else if !self.constraints.isEmpty || self.superview != nil {
            self.invalidateIntrinsicContentSize()
            self.setNeedsLayout()
        } else {
            self.frame.size.height = height
        }
    }

    private func updateHeightConstraintIfNeeded() {
        if self.heightConstraint?.isActive == true {
            return
        }
        if let constraint = self.constraints.first(where: { self.isHeightConstraint($0) }) {
            self.heightConstraint = constraint
            return
        }
        self.heightConstraint = self.superview?.constraints.first(where: { self.isHeightConstraint($0) })
    }

    private func isHeightConstraint(_ constraint: NSLayoutConstraint) -> Bool {
        guard constraint.firstAttribute == .height, constraint.relation == .equal else { return false }
        return constraint.firstItem as? UIView === self || constraint.secondItem as? UIView === self
    }

    private func scrollToVisibleCaretIfNeeded() {
        guard self.isReachMaxInputHeight, let textPosition = self.selectedTextRange?.end else { return }
        let caretRect = self.caretRect(for: textPosition)
        let insets = UIEdgeInsets(
            top: self.contentInset.top + self.textContainerInset.top,
            left: self.contentInset.left + self.textContainerInset.left + self.textContainer.lineFragmentPadding,
            bottom: self.contentInset.bottom + self.textContainerInset.bottom,
            right: self.contentInset.right + self.textContainerInset.right + self.textContainer.lineFragmentPadding
        )
        let visibleRect = self.bounds.inset(by: insets)
        guard !visibleRect.contains(caretRect) else { return }
        self.scrollRectToVisible(caretRect, animated: false)
    }
}

extension STTextView: UITextViewDelegate {
    public func textViewDidChange(_ textView: UITextView) {
        self.handleTextChange()
        self.cusDelegate?.st_textViewEditingChanged(textView: self)
    }

    public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if let cusDelegate, !cusDelegate.st_textViewShouldChangeText(textView: self, in: range, replacementText: text) {
            return false
        }
        guard self.maxTextCount > 0, self.shouldLimitTextCount else { return true }
        guard let currentText = textView.text else { return true }
        guard let stringRange = Range(range, in: currentText) else { return true }
        let markedRange = textView.markedTextRange
        if markedRange != nil {
            return true
        }
        let nextText = currentText.replacingCharacters(in: stringRange, with: text)
        if nextText.count <= self.maxTextCount {
            return true
        }
        self.cusDelegate?.st_textViewDidReachMaxTextCount(textView: self, maxCount: self.maxTextCount)
        return false
    }
}
