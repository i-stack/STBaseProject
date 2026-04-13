//
//  STPlaceholderTextView.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2018/10/12.
//

import UIKit

private struct STPlaceholderTextViewLocalizationKey {
    static var localizedPlaceholderKey: UInt8 = 0
}

@IBDesignable
open class STPlaceholderTextView: UITextView {

    @IBInspectable open var localizedPlaceholder: String {
        get {
            return objc_getAssociatedObject(self, &STPlaceholderTextViewLocalizationKey.localizedPlaceholderKey) as? String ?? ""
        }
        set {
            objc_setAssociatedObject(self, &STPlaceholderTextViewLocalizationKey.localizedPlaceholderKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            self.placeholder = newValue.localized
        }
    }

    @IBInspectable open var placeholder: String = "" {
        didSet {
            self.placeholderLabel.text = self.placeholder
            self.updatePlaceholderVisibility()
            self.notifyPlaceholderHeightAffectingChange()
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
            self.notifyPlaceholderHeightAffectingChange()
        }
    }

    @IBInspectable public var placeholderFontSize: CGFloat {
        get { return self.placeholderFont.pointSize }
        set {
            self.placeholderFont = UIFont.st_systemFont(ofSize: max(1, newValue))
        }
    }

    public var contentInsets: UIEdgeInsets {
        get { return self.contentInsetsStorage }
        set {
            self.contentInsetsStorage = newValue
            self.textContainer.lineFragmentPadding = 0
            self.applyTextContainerInset(newValue)
            self.layoutPlaceholderLabel()
            self.notifyPlaceholderHeightAffectingChange()
        }
    }

    @IBInspectable public var placeholderLeftInset: CGFloat {
        get { return self.contentInsetsStorage.left }
        set {
            var insets = self.contentInsetsStorage
            insets.left = max(0, newValue)
            self.contentInsets = insets
        }
    }

    @IBInspectable public var placeholderTopInset: CGFloat {
        get { return self.contentInsetsStorage.top }
        set {
            var insets = self.contentInsetsStorage
            insets.top = max(0, newValue)
            self.contentInsets = insets
        }
    }

    @IBInspectable public var cursorInsetTop: CGFloat {
        get { return self.contentInsetsStorage.top }
        set { self.placeholderTopInset = newValue }
    }

    @IBInspectable public var cursorInsetLeft: CGFloat {
        get { return self.contentInsetsStorage.left }
        set { self.placeholderLeftInset = newValue }
    }

    @IBInspectable public var cursorInsetBottom: CGFloat {
        get { return self.contentInsetsStorage.bottom }
        set {
            var insets = self.contentInsetsStorage
            insets.bottom = max(0, newValue)
            self.contentInsets = insets
        }
    }

    @IBInspectable public var cursorInsetRight: CGFloat {
        get { return self.contentInsetsStorage.right }
        set {
            var insets = self.contentInsetsStorage
            insets.right = max(0, newValue)
            self.contentInsets = insets
        }
    }

    open override var text: String! {
        didSet {
            self.updatePlaceholderVisibility()
            self.notifyPlaceholderTextDidChange()
        }
    }

    open override var attributedText: NSAttributedString! {
        didSet {
            self.updatePlaceholderVisibility()
            self.notifyPlaceholderTextDidChange()
        }
    }

    open override var font: UIFont? {
        didSet {
            if self.shouldFollowTextViewFontForPlaceholder {
                self.applyDefaultPlaceholderFont()
            }
            self.notifyPlaceholderHeightAffectingChange()
        }
    }

    open override var bounds: CGRect {
        didSet {
            if oldValue.size.width != self.bounds.size.width {
                self.layoutPlaceholderLabel()
                self.notifyPlaceholderHeightAffectingChange()
            }
        }
    }

    open override var textContainerInset: UIEdgeInsets {
        didSet {
            guard !self.isUpdatingTextContainerInset else { return }
            self.contentInsetsStorage = self.textContainerInset
            self.layoutPlaceholderLabel()
            self.notifyPlaceholderHeightAffectingChange()
        }
    }

    public override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        self.configPlaceholderTextView()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.configPlaceholderTextView()
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
        self.layoutPlaceholderLabel()
    }

    public func st_updateLocalizedPlaceholder() {
        if !self.localizedPlaceholder.isEmpty {
            self.placeholder = self.localizedPlaceholder.localized
        }
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

    public func configAttributed(placeholderColor: UIColor) {
        self.placeholderTextColor = placeholderColor
    }

    open func st_placeholderTextDidChange() {}

    open func st_placeholderHeightAffectingChange() {}

    public func placeholderFittingHeight(for width: CGFloat) -> CGFloat {
        guard !(self.placeholderLabel.text ?? "").isEmpty else { return 0 }
        let inset = self.textContainerInset
        let placeholderWidth = max(0, width - inset.left - inset.right - self.textContainer.lineFragmentPadding * 2)
        let placeholderHeight = self.placeholderLabel.sizeThatFits(CGSize(width: placeholderWidth, height: CGFloat.greatestFiniteMagnitude)).height
        return ceil(placeholderHeight + inset.top + inset.bottom)
    }

    private func configPlaceholderTextView() {
        self.isConfiguringPlaceholderTextView = true
        self.textContainer.lineFragmentPadding = 0
        self.contentInsetsStorage = self.textContainerInset
        self.placeholderLabel.numberOfLines = 0
        self.placeholderLabel.textColor = self.placeholderTextColor
        self.placeholderLabel.isUserInteractionEnabled = false
        self.applyDefaultPlaceholderFont()
        self.addSubview(self.placeholderLabel)
        self.updatePlaceholderVisibility()
        self.isConfiguringPlaceholderTextView = false
    }

    private func notifyPlaceholderTextDidChange() {
        guard !self.isConfiguringPlaceholderTextView else { return }
        self.st_placeholderTextDidChange()
    }

    private func notifyPlaceholderHeightAffectingChange() {
        guard !self.isConfiguringPlaceholderTextView else { return }
        self.st_placeholderHeightAffectingChange()
    }

    private func applyTextContainerInset(_ textContainerInset: UIEdgeInsets) {
        self.isUpdatingTextContainerInset = true
        self.textContainerInset = textContainerInset
        self.isUpdatingTextContainerInset = false
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
        let fittingSize = self.placeholderLabel.sizeThatFits(CGSize(width: targetWidth, height: CGFloat.greatestFiniteMagnitude))
        self.placeholderLabel.frame = CGRect(x: x, y: inset.top, width: targetWidth, height: ceil(fittingSize.height))
    }

    private func updatePlaceholderVisibility() {
        self.placeholderLabel.isHidden = !(self.text ?? "").isEmpty
    }

    private lazy var placeholderLabel: UILabel = {
        let label = UILabel()
        return label
    }()

    private var contentInsetsStorage: UIEdgeInsets = .zero
    private var isUpdatingTextContainerInset: Bool = false
    private var isApplyingDefaultPlaceholderFont: Bool = false
    private var shouldFollowTextViewFontForPlaceholder: Bool = true
    private var isConfiguringPlaceholderTextView: Bool = false
}
