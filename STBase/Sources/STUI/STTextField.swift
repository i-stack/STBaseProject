//
//  STTextField.swift
//  STBaseProject
//
//  Created by stack on 2018/10/12.
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

open class STTextField: UITextField {

    open var textIsCheck: Bool = false
    weak open var cusDelegate: STTextFieldDelegate?
    
    private var limitCount: Int = -1
    private var orginLeft: CGFloat = 0
    private var orginRight: CGFloat = 0
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

    @IBInspectable var cornerRadius: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            layer.cornerRadius = newValue
            layer.masksToBounds = newValue > 0
        }
    }
    
    @IBInspectable var borderWidth: CGFloat {
        get {
            return layer.borderWidth
        }
        set {
            layer.borderWidth = newValue > 0 ? newValue : 0
        }
    }
    
    @IBInspectable var borderColor: UIColor {
        get {
            return UIColor(cgColor: layer.borderColor!)
        }
        set {
            layer.borderColor = newValue.cgColor
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
        removeSecureTextEntryObserver()
    }
    
    open override func deleteBackward() {
        super.deleteBackward()
        if let delegate = self.cusDelegate {
            delegate.st_textFieldBackwardKeyPressed(textField: self)
        }
    }
    
    open override func textRect(forBounds bounds: CGRect) -> CGRect {
        let inset = CGRect.init(x: bounds.origin.x + self.orginLeft, y: bounds.origin.y, width: bounds.size.width - self.orginLeft - self.orginRight, height: bounds.size.height)
        return inset
    }
    
    open override func editingRect(forBounds bounds: CGRect) -> CGRect {
        let inset = CGRect.init(x: bounds.origin.x + self.orginLeft, y: bounds.origin.y, width: bounds.size.width - self.orginLeft - self.orginRight, height: bounds.size.height)
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
            let rightViewFrame = rightViewRect(forBounds: self.bounds)
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
        if isPasswordToggleEnabled, let container = self.rightView, let button = passwordToggleButton {
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
    
    public func config(orginLeft: CGFloat, orginRight: CGFloat) -> Void {
        self.orginLeft = orginLeft
        self.orginRight = orginRight
    }
    
    public func config(textLimitCount: Int) -> Void {
        self.limitCount = textLimitCount
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
        if !localizedPlaceholder.isEmpty {
            self.placeholder = localizedPlaceholder.localized
        }
    }
    
    // MARK: - 密码切换功能
    
    /// 启用密码切换功能（使用默认图标）
    public func st_enablePasswordToggle() {
        st_enablePasswordToggle(showIcon: nil, hideIcon: nil)
    }
    
    /// 启用密码切换功能（支持自定义图标）
    public func st_enablePasswordToggle(showIcon: UIImage?, hideIcon: UIImage?) {
        guard !isPasswordToggleEnabled else { return }
        isPasswordToggleEnabled = true
        self.showPasswordIcon = showIcon
        self.hidePasswordIcon = hideIcon
        self.isSecureTextEntry = true
        setupPasswordToggle()
        setupSecureTextEntryObserver()
    }
    
    /// 禁用密码切换功能
    public func st_disablePasswordToggle() {
        guard isPasswordToggleEnabled else { return }
        isPasswordToggleEnabled = false
        self.rightView = nil
        self.rightViewMode = .never
        passwordToggleButton = nil
        removeSecureTextEntryObserver()
    }
    
    /// 更新密码切换图标
    public func st_updatePasswordToggleIcons(showIcon: UIImage?, hideIcon: UIImage?) {
        guard isPasswordToggleEnabled else { return }
        self.showPasswordIcon = showIcon
        self.hidePasswordIcon = hideIcon
        if let button = passwordToggleButton {
            let showIcon = showPasswordIcon ?? UIImage(systemName: "eye")
            let hideIcon = hidePasswordIcon ?? UIImage(systemName: "eye.slash")
            button.setImage(showIcon, for: .normal)
            button.setImage(hideIcon, for: .selected)
        }
    }
    
    /// 设置密码切换按钮颜色
    public func st_setPasswordToggleButtonColor(_ color: UIColor) {
        passwordToggleButton?.tintColor = color
    }
    
    /// 设置isSecureTextEntry的KVO监听
    private func setupSecureTextEntryObserver() {
        removeSecureTextEntryObserver()
        secureTextEntryObserver = observe(\.isSecureTextEntry, options: [.old, .new]) { [weak self] textField, change in
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
        secureTextEntryObserver?.invalidate()
        secureTextEntryObserver = nil
    }
    
    /// 设置密码切换按钮
    private func setupPasswordToggle() {
        let toggleButton = UIButton(type: .custom)
        toggleButton.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        let showIcon = showPasswordIcon ?? UIImage(systemName: "eye")
        let hideIcon = hidePasswordIcon ?? UIImage(systemName: "eye.slash")
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
        guard let button = passwordToggleButton else { return }
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
        if isPasswordToggleEnabled {
            // 只有在切换密码可见性时才恢复保存的文本，用户正常删除操作不应该恢复
            if isChangingSecureTextEntry {
                if (textField.text?.isEmpty ?? true) && !savaText.isEmpty {
                    textField.text = savaText
                    return
                }
            }
            // 更新保存的文本
            self.savaText = textField.text ?? ""
        }
        
        // 处理文本长度限制
        if self.limitCount > 0 {
            if let inputText = textField.text, inputText.count > self.limitCount {
                self.text = String(inputText.prefix(self.limitCount))
            }
        }

        self.cusDelegate?.st_textFieldEditingChanged(textField: textField)
    }
}