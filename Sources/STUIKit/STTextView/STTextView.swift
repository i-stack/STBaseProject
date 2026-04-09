//
//  STTextView.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2018/10/12.
//

import UIKit

private struct STTextViewLocalizationKey {
    static var localizedPlaceholderKey: UInt8 = 0
}

public protocol STTextViewDelegate: NSObjectProtocol {
    func st_textViewEditingChanged(textView: STTextView)
    func st_textViewDidReachMaxTextCount(textView: STTextView, maxCount: Int)
    func st_textViewTextCountDidChange(textView: STTextView, currentCount: Int, maxCount: Int)
    func st_textViewHeightDidChange(textView: STTextView, currentHeight: CGFloat, isReachMaxHeight: Bool)
}

public extension STTextViewDelegate {
    func st_textViewEditingChanged(textView: STTextView) {}
    func st_textViewDidReachMaxTextCount(textView: STTextView, maxCount: Int) {}
    func st_textViewTextCountDidChange(textView: STTextView, currentCount: Int, maxCount: Int) {}
    func st_textViewHeightDidChange(textView: STTextView, currentHeight: CGFloat, isReachMaxHeight: Bool) {}
}

open class STTextView: UITextView {

    weak open var cusDelegate: STTextViewDelegate?

    open var shouldLimitTextCount: Bool = true
    open private(set) var currentTextCount: Int = 0
    open private(set) var currentInputHeight: CGFloat = 0
    open private(set) var isReachMaxInputHeight: Bool = false

    private let placeholderLabel = UILabel()
    private var lastReportedHeight: CGFloat = 0
    private var _contentInsets: UIEdgeInsets = .zero
    private var isApplyingDefaultPlaceholderFont: Bool = false
    private var shouldFollowTextViewFontForPlaceholder: Bool = true

    // MARK: - Localization

    @IBInspectable open var localizedPlaceholder: String {
        get {
            return objc_getAssociatedObject(self, &STTextViewLocalizationKey.localizedPlaceholderKey) as? String ?? ""
        }
        set {
            objc_setAssociatedObject(
                self,
                &STTextViewLocalizationKey.localizedPlaceholderKey,
                newValue,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
            self.placeholder = newValue.localized
        }
    }

    // MARK: - Placeholder

    @IBInspectable open var placeholder: String = "" {
        didSet {
            self.placeholderLabel.text = self.placeholder
            self.updatePlaceholderVisibility()
        }
    }

    @IBInspectable open var placeholderTextColor: UIColor = UIColor.systemGray3 {
        didSet {
            self.placeholderLabel.textColor = self.placeholderTextColor
        }
    }

    @objc dynamic open var placeholderFont: UIFont = UIFont.st_systemFont(ofSize: 16) {
        didSet {
            self.placeholderLabel.font = self.placeholderFont
            if !self.isApplyingDefaultPlaceholderFont {
                self.shouldFollowTextViewFontForPlaceholder = false
            }
            self.layoutPlaceholderLabel()
        }
    }

    @IBInspectable public var placeholderFontSize: CGFloat {
        get { return self.placeholderFont.pointSize }
        set {
            self.placeholderFont = UIFont.st_systemFont(ofSize: max(1, newValue))
        }
    }

    // MARK: - Content Insets (unified)

    /// Unified content insets for text, cursor, and placeholder.
    /// All individual inset properties (placeholderLeftInset, cursorInsetTop, etc.) route through this.
    public var contentInsets: UIEdgeInsets {
        get { return _contentInsets }
        set {
            _contentInsets = newValue
            self.textContainer.lineFragmentPadding = 0
            self.textContainerInset = newValue
            self.layoutPlaceholderLabel()
            self.updateHeightIfNeeded(notify: true)
        }
    }

    @IBInspectable public var placeholderLeftInset: CGFloat {
        get { return _contentInsets.left }
        set {
            var insets = _contentInsets
            insets.left = max(0, newValue)
            self.contentInsets = insets
        }
    }

    @IBInspectable public var placeholderTopInset: CGFloat {
        get { return _contentInsets.top }
        set {
            var insets = _contentInsets
            insets.top = max(0, newValue)
            self.contentInsets = insets
        }
    }

    @IBInspectable public var cursorInsetTop: CGFloat {
        get { return _contentInsets.top }
        set { self.placeholderTopInset = newValue }
    }

    @IBInspectable public var cursorInsetLeft: CGFloat {
        get { return _contentInsets.left }
        set { self.placeholderLeftInset = newValue }
    }

    @IBInspectable public var cursorInsetBottom: CGFloat {
        get { return _contentInsets.bottom }
        set {
            var insets = _contentInsets
            insets.bottom = max(0, newValue)
            self.contentInsets = insets
        }
    }

    @IBInspectable public var cursorInsetRight: CGFloat {
        get { return _contentInsets.right }
        set {
            var insets = _contentInsets
            insets.right = max(0, newValue)
            self.contentInsets = insets
        }
    }

    // MARK: - Appearance

    /// Setting cornerRadius > 0 automatically adjusts contentInsets to match the rounded corners.
    @IBInspectable var cornerRadius: CGFloat {
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

    @IBInspectable var borderWidth: CGFloat {
        get { return self.layer.borderWidth }
        set { self.layer.borderWidth = newValue > 0 ? newValue : 0 }
    }

    @IBInspectable var borderColor: UIColor {
        get {
            guard let color = self.layer.borderColor else { return .clear }
            return UIColor(cgColor: color)
        }
        set { self.layer.borderColor = newValue.cgColor }
    }

    // MARK: - Text Limits

    open var maxTextHeight: CGFloat = CGFloat.greatestFiniteMagnitude {
        didSet {
            self.updateHeightIfNeeded(notify: true)
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

    // MARK: - Overrides

    public override var text: String! {
        didSet {
            self.handleTextChange()
        }
    }

    public override var attributedText: NSAttributedString! {
        didSet {
            self.handleTextChange()
        }
    }

    public override var font: UIFont? {
        didSet {
            if self.shouldFollowTextViewFontForPlaceholder {
                self.applyDefaultPlaceholderFont()
            }
            self.updateHeightIfNeeded(notify: true)
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
                self.updateHeightIfNeeded(notify: true)
            }
        }
    }

    public override var intrinsicContentSize: CGSize {
        let targetWidth = self.bounds.width > 0 ? self.bounds.width : UIScreen.main.bounds.width
        let fitting = self.sizeThatFits(CGSize(width: targetWidth, height: CGFloat.greatestFiniteMagnitude))
        let targetHeight = min(self.maxTextHeight, max(self.minTextHeight(), fitting.height))
        return CGSize(width: UIView.noIntrinsicMetric, height: ceil(targetHeight))
    }

    // MARK: - Init

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
        self.layoutPlaceholderLabel()
    }

    // MARK: - Public Config

    public func config(textLimitCount: Int) {
        self.maxTextCount = textLimitCount
    }

    public func config(maxInputHeight: CGFloat) {
        self.maxTextHeight = maxInputHeight > 0 ? maxInputHeight : CGFloat.greatestFiniteMagnitude
    }

    public func config(placeholder: String, placeholderFont: UIFont? = nil, placeholderColor: UIColor? = nil) {
        self.placeholder = placeholder
        if let placeholderFont {
            self.placeholderFont = placeholderFont
        }
        if let placeholderColor {
            self.placeholderTextColor = placeholderColor
        }
    }

    public func st_updateLocalizedPlaceholder() {
        if !self.localizedPlaceholder.isEmpty {
            self.placeholder = self.localizedPlaceholder.localized
        }
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

    public func configAttributed(placeholderColor: UIColor) {
        self.placeholderTextColor = placeholderColor
    }

    // MARK: - Private

    private func config() {
        self.isScrollEnabled = false
        self.delegate = self
        self.keyboardDismissMode = .interactive
        self.alwaysBounceVertical = false
        self.textContainer.lineFragmentPadding = 0
        _contentInsets = self.textContainerInset
        self.placeholderLabel.numberOfLines = 0
        self.placeholderLabel.textColor = self.placeholderTextColor
        self.applyDefaultPlaceholderFont()
        self.placeholderLabel.isUserInteractionEnabled = false
        self.addSubview(self.placeholderLabel)
        self.typingAttributes[.font] = self.font ?? UIFont.st_systemFont(ofSize: 16)
        self.typingAttributes[.foregroundColor] = self.textColor ?? UIColor.label
        self.updatePlaceholderVisibility()
        self.updateHeightIfNeeded(notify: false)
    }

    private func applyDefaultPlaceholderFont() {
        self.isApplyingDefaultPlaceholderFont = true
        self.placeholderFont = self.font ?? UIFont.st_systemFont(ofSize: 16)
        self.isApplyingDefaultPlaceholderFont = false
        self.shouldFollowTextViewFontForPlaceholder = true
    }

    private func layoutPlaceholderLabel() {
        let inset = self.textContainerInset
        let x = inset.left + self.textContainer.lineFragmentPadding
        let maxWidth = self.bounds.width - x - inset.right - self.textContainer.lineFragmentPadding
        let targetWidth = max(0, maxWidth)
        let fittingSize = self.placeholderLabel.sizeThatFits(
            CGSize(width: targetWidth, height: CGFloat.greatestFiniteMagnitude)
        )
        self.placeholderLabel.frame = CGRect(
            x: x,
            y: inset.top,
            width: targetWidth,
            height: ceil(fittingSize.height)
        )
    }

    private func minTextHeight() -> CGFloat {
        let lineHeight = (self.font ?? UIFont.st_systemFont(ofSize: 16)).lineHeight
        return lineHeight + self.textContainerInset.top + self.textContainerInset.bottom
    }

    private func handleTextChange() {
        self.updatePlaceholderVisibility()
        self.enforceTextCountIfNeeded()
        self.updateHeightIfNeeded(notify: true)
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

    private func updatePlaceholderVisibility() {
        self.placeholderLabel.isHidden = !(self.text ?? "").isEmpty
    }

    private func updateHeightIfNeeded(notify: Bool) {
        self.invalidateIntrinsicContentSize()
        let targetWidth = self.bounds.width > 0 ? self.bounds.width : UIScreen.main.bounds.width
        let fitting = self.sizeThatFits(CGSize(width: targetWidth, height: CGFloat.greatestFiniteMagnitude))
        let minHeight = self.minTextHeight()
        let currentHeight = ceil(max(minHeight, min(self.maxTextHeight, fitting.height)))
        let isReachMaxHeight = fitting.height >= self.maxTextHeight && self.maxTextHeight < CGFloat.greatestFiniteMagnitude
        self.currentInputHeight = currentHeight
        self.isReachMaxInputHeight = isReachMaxHeight
        self.isScrollEnabled = isReachMaxHeight
        if notify, currentHeight != self.lastReportedHeight {
            self.lastReportedHeight = currentHeight
            self.cusDelegate?.st_textViewHeightDidChange(
                textView: self,
                currentHeight: currentHeight,
                isReachMaxHeight: isReachMaxHeight
            )
        }
    }
}

extension STTextView: UITextViewDelegate {
    public func textViewDidChange(_ textView: UITextView) {
        self.handleTextChange()
        self.cusDelegate?.st_textViewEditingChanged(textView: self)
    }

    public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
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
