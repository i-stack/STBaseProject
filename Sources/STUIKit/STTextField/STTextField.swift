//
//  STTextField.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2018/10/12.
//

import UIKit

private struct STTextFieldLocalizationKey {
    static var localizedPlaceholderKey: UInt8 = 0
}

public protocol STTextFieldDelegate: NSObjectProtocol {
    func st_textFieldEditingChanged(textField: STTextField)
    func st_textFieldBackwardKeyPressed(textField: STTextField)
}

public extension STTextFieldDelegate {
    func st_textFieldEditingChanged(textField: STTextField) {}
    func st_textFieldBackwardKeyPressed(textField: STTextField) {}
}

@IBDesignable
open class STTextField: UITextField {

    open var textIsCheck: Bool = false
    weak open var cusDelegate: STTextFieldDelegate?
    
    private var contentInsetLeft: CGFloat = 0
    private var contentInsetRight: CGFloat = 0
    private var savaText: String = ""
    private var showPasswordIcon: UIImage?
    private var hidePasswordIcon: UIImage?
    private var passwordToggleButton: UIButton?
    private var isPasswordToggleEnabled: Bool = false
    private var isChangingSecureTextEntry: Bool = false
    private var preservedText: String = ""
    private var secureTextEntryObserver: NSKeyValueObservation?
    
    @IBInspectable open var localizedPlaceholder: String {
        get {
            return objc_getAssociatedObject(self, &STTextFieldLocalizationKey.localizedPlaceholderKey) as? String ?? ""
        }
        set {
            objc_setAssociatedObject(self, &STTextFieldLocalizationKey.localizedPlaceholderKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            self.placeholder = newValue.localized
        }
    }

    @IBInspectable open var cornerRadius: CGFloat {
        get {
            return self.layer.cornerRadius
        }
        set {
            self.layer.cornerRadius = newValue
            self.st_updateLiquidGlassCornerRadius()
        }
    }
    
    @IBInspectable open var clipsContentToBounds: Bool {
        get {
            return self.layer.masksToBounds
        }
        set {
            self.layer.masksToBounds = newValue
        }
    }
    
    @IBInspectable open var borderWidth: CGFloat {
        get {
            return self.layer.borderWidth
        }
        set {
            self.layer.borderWidth = newValue > 0 ? newValue : 0
        }
    }
    
    @IBInspectable open var borderColor: UIColor {
        get {
            guard let cgColor = self.layer.borderColor else {
                return .clear
            }
            return UIColor(cgColor: cgColor)
        }
        set {
            self.layer.borderColor = newValue.cgColor
        }
    }
    
    @IBInspectable open var isLiquidGlassEnabled: Bool = false {
        didSet {
            if self.isLiquidGlassEnabled {
                self.updateLiquidGlassBackground()
            } else {
                self.st_disableLiquidGlassBackground()
            }
        }
    }
    
    @IBInspectable open var liquidGlassTintColor: UIColor = UIColor.white.withAlphaComponent(0.18) {
        didSet {
            self.updateLiquidGlassBackground()
        }
    }
    
    @IBInspectable open var liquidGlassHighlightOpacity: Float = 0.45 {
        didSet {
            self.updateLiquidGlassBackground()
        }
    }
    
    @IBInspectable open var liquidGlassBorderColor: UIColor = UIColor.white.withAlphaComponent(0.45) {
        didSet {
            self.updateLiquidGlassBackground()
        }
    }
    
    @IBInspectable open var textInsetLeft: CGFloat {
        get {
            return self.contentInsetLeft
        }
        set {
            self.contentInsetLeft = max(0, newValue)
            self.setNeedsLayout()
        }
    }
    
    @IBInspectable open var textInsetRight: CGFloat {
        get {
            return self.contentInsetRight
        }
        set {
            self.contentInsetRight = max(0, newValue)
            self.setNeedsLayout()
        }
    }

    @IBInspectable open var maxTextCount: Int = -1 {
        didSet {
            self.enforceTextCountIfNeeded(for: self)
        }
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.config()
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        self.config()
    }
    
    deinit {
        self.removeSecureTextEntryObserver()
    }
    
    open override func deleteBackward() {
        super.deleteBackward()
        if let delegate = self.cusDelegate {
            delegate.st_textFieldBackwardKeyPressed(textField: self)
        }
    }
    
    open override func textRect(forBounds bounds: CGRect) -> CGRect {
        let inset = CGRect.init(x: bounds.origin.x + self.contentInsetLeft, y: bounds.origin.y, width: bounds.size.width - self.contentInsetLeft - self.contentInsetRight, height: bounds.size.height)
        return inset
    }
    
    open override func editingRect(forBounds bounds: CGRect) -> CGRect {
        let inset = CGRect.init(x: bounds.origin.x + self.contentInsetLeft, y: bounds.origin.y, width: bounds.size.width - self.contentInsetLeft - self.contentInsetRight, height: bounds.size.height)
        return inset
    }
    
    open override func leftViewRect(forBounds bounds: CGRect) -> CGRect {
        if let newView = self.leftView {
            let frame = newView.frame
            return CGRect.init(x: 0, y: 0, width: frame.size.width, height: frame.size.height)
        }
        return CGRect.zero
    }
    
    open override func rightViewRect(forBounds bounds: CGRect) -> CGRect {
        if let newView = self.rightView {
            let frame = newView.frame
            let x = bounds.width - frame.width
            let y = (bounds.height - frame.height) / 2
            return CGRect(x: x, y: y, width: frame.width, height: frame.height)
        }
        return CGRect.zero
    }
    
    open override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if let rightView = self.rightView {
            let rightViewFrame = self.rightViewRect(forBounds: self.bounds)
            if rightViewFrame.contains(point) {
                let pointInRightView = CGPoint(x: point.x - rightViewFrame.origin.x, y: point.y - rightViewFrame.origin.y)
                if let hitView = rightView.hitTest(pointInRightView, with: event) {
                    return hitView
                }
            }
        }
        return super.hitTest(point, with: event)
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        self.st_updateLiquidGlassCornerRadius()
        if self.isPasswordToggleEnabled, let container = self.rightView, let button = self.passwordToggleButton {
            button.center = CGPoint(x: container.bounds.midX, y: container.bounds.midY)
        }
    }
    
    private func config() {
        self.configContent()
        self.addEditingChangedTarget()
    }
    
    private func configContent() {
        self.clearButtonMode = .whileEditing
        self.autocorrectionType = UITextAutocorrectionType.no
        self.autocapitalizationType = UITextAutocapitalizationType.none
    }
    
    private func addEditingChangedTarget() {
        self.addTarget(self, action: #selector(st_textFieldEditingChanged(textField:)), for: .editingChanged)
    }
    
    public func setTextInsets(left: CGFloat, right: CGFloat) -> Void {
        self.contentInsetLeft = max(0, left)
        self.contentInsetRight = max(0, right)
        self.setNeedsLayout()
    }
    
    public func config(textLimitCount: Int) -> Void {
        self.maxTextCount = textLimitCount
    }
        
    public func configAttributed(textColor: UIColor) -> Void {
        if let attributedText = self.attributedPlaceholder {
            let placeholderAttributedString = NSMutableAttributedString(attributedString: attributedText)
            placeholderAttributedString.addAttribute(.foregroundColor, value: textColor, range: NSRange(location: 0, length: placeholderAttributedString.length))
            self.attributedPlaceholder = placeholderAttributedString
        }
    }
    
    public func configAttributed(text: String, textColor: UIColor) -> Void {
        if text.count > 0 {
            let placeholderAttributedString = NSMutableAttributedString(attributedString: NSAttributedString.init(string: text))
            placeholderAttributedString.addAttribute(.foregroundColor, value: textColor, range: NSRange(location: 0, length: placeholderAttributedString.length))
            self.attributedPlaceholder = placeholderAttributedString
        }
    }
    
    public func st_updateLocalizedPlaceholder() {
        if !self.localizedPlaceholder.isEmpty {
            self.placeholder = self.localizedPlaceholder.localized
        }
    }
    
    // MARK: - 密码切换功能
    
    /// 启用密码切换功能（使用默认图标）
    public func st_enablePasswordToggle() {
        self.st_enablePasswordToggle(showIcon: nil, hideIcon: nil)
    }
    
    /// 启用密码切换功能（支持自定义图标）
    public func st_enablePasswordToggle(showIcon: UIImage?, hideIcon: UIImage?) {
        guard !self.isPasswordToggleEnabled else { return }
        self.isPasswordToggleEnabled = true
        self.showPasswordIcon = showIcon
        self.hidePasswordIcon = hideIcon
        self.isSecureTextEntry = true
        self.setupPasswordToggle()
        self.setupSecureTextEntryObserver()
    }
    
    /// 禁用密码切换功能
    public func st_disablePasswordToggle() {
        guard self.isPasswordToggleEnabled else { return }
        self.isPasswordToggleEnabled = false
        self.rightView = nil
        self.rightViewMode = .never
        self.passwordToggleButton = nil
        self.removeSecureTextEntryObserver()
    }
    
    /// 更新密码切换图标
    public func st_updatePasswordToggleIcons(showIcon: UIImage?, hideIcon: UIImage?) {
        guard self.isPasswordToggleEnabled else { return }
        self.showPasswordIcon = showIcon
        self.hidePasswordIcon = hideIcon
        if let button = self.passwordToggleButton {
            let showIcon = self.showPasswordIcon ?? UIImage(systemName: "eye")
            let hideIcon = self.hidePasswordIcon ?? UIImage(systemName: "eye.slash")
            button.setImage(showIcon, for: .normal)
            button.setImage(hideIcon, for: .selected)
        }
    }
    
    /// 设置密码切换按钮颜色
    public func st_setPasswordToggleButtonColor(_ color: UIColor) {
        self.passwordToggleButton?.tintColor = color
    }
    
    /// 设置isSecureTextEntry的KVO监听
    private func setupSecureTextEntryObserver() {
        self.removeSecureTextEntryObserver()
        self.secureTextEntryObserver = self.observe(\.isSecureTextEntry, options: [.old, .new]) { [weak self] textField, change in
            guard let strongSelf = self, strongSelf.isPasswordToggleEnabled else { return }
            if let oldValue = change.oldValue, let newValue = change.newValue,
               !oldValue && newValue {
                strongSelf.isChangingSecureTextEntry = true
                DispatchQueue.main.async {
                    strongSelf.isChangingSecureTextEntry = false
                }
            }
        }
    }
    
    /// 移除isSecureTextEntry的KVO监听
    private func removeSecureTextEntryObserver() {
        self.secureTextEntryObserver?.invalidate()
        self.secureTextEntryObserver = nil
    }
    
    /// 设置密码切换按钮
    private func setupPasswordToggle() {
        let toggleButton = UIButton(type: .custom)
        toggleButton.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        let showIcon = self.showPasswordIcon ?? UIImage(systemName: "eye")
        let hideIcon = self.hidePasswordIcon ?? UIImage(systemName: "eye.slash")
        toggleButton.setImage(showIcon, for: .normal)
        toggleButton.setImage(hideIcon, for: .selected)
        toggleButton.tintColor = UIColor.systemGray
        toggleButton.addTarget(self, action: #selector(st_passwordToggleButtonTapped), for: .touchUpInside)
        toggleButton.isUserInteractionEnabled = true
        toggleButton.isEnabled = true
        let containerWidth: CGFloat = 44
        let containerHeight: CGFloat = self.bounds.height > 0 ? self.bounds.height : 44
        let container = UIView(frame: CGRect(x: 0, y: 0, width: containerWidth, height: containerHeight))
        toggleButton.center = CGPoint(x: container.bounds.midX, y: container.bounds.midY)
        container.addSubview(toggleButton)
        container.isUserInteractionEnabled = true
        self.semanticContentAttribute = .forceLeftToRight
        container.semanticContentAttribute = .forceLeftToRight
        toggleButton.semanticContentAttribute = .forceLeftToRight
        self.passwordToggleButton = toggleButton
        self.rightView = container
        self.rightViewMode = .always
    }
    
    /// 密码切换按钮点击事件
    @objc private func st_passwordToggleButtonTapped() {
        guard let button = self.passwordToggleButton else { return }
        self.savaText = self.text ?? ""
        self.isChangingSecureTextEntry = true
        self.isSecureTextEntry = !self.isSecureTextEntry
        button.isSelected = !self.isSecureTextEntry
        // 延迟重置标志，确保文本变化事件能正确处理
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.isChangingSecureTextEntry = false
        }
    }
    
    @objc private func st_textFieldEditingChanged(textField: STTextField) {
        if self.isPasswordToggleEnabled {
            // 只有在切换密码可见性时才恢复保存的文本，用户正常删除操作不应该恢复
            if self.isChangingSecureTextEntry {
                if (textField.text?.isEmpty ?? true) && !self.savaText.isEmpty {
                    textField.text = self.savaText
                    return
                }
            }
            // 更新保存的文本
            self.savaText = textField.text ?? ""
        }
        
        self.enforceTextCountIfNeeded(for: textField)

        self.cusDelegate?.st_textFieldEditingChanged(textField: textField)
    }

    private func enforceTextCountIfNeeded(for textField: STTextField) {
        guard self.maxTextCount > 0 else { return }
        if textField.markedTextRange != nil {
            return
        }
        guard let inputText = textField.text, inputText.count > self.maxTextCount else { return }
        textField.text = String(inputText.prefix(self.maxTextCount))
    }
    
    private func updateLiquidGlassBackground() {
        guard self.isLiquidGlassEnabled else { return }
        self.st_enableLiquidGlassBackground(
            tintColor: self.liquidGlassTintColor,
            highlightOpacity: self.liquidGlassHighlightOpacity,
            borderColor: self.liquidGlassBorderColor
        )
    }
}

// MARK: - STLocalizable
extension STTextField: STLocalizable {
    public func st_updateLocalizedText() {
        let key = self.localizedPlaceholder
        if !key.isEmpty {
            self.placeholder = key.localized
        }
    }
}
