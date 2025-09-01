//
//  STTextField.swift
//  STBaseProject
//
//  Created by stack on 2018/10/12.
//

import UIKit

// MARK: - 文本框本地化常量
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
    
    private var limitCount: Int = -1
    private var orginLeft: CGFloat = 0
    private var orginRight: CGFloat = 0
    open var textIsCheck: Bool = false
    weak open var cusDelegate: STTextFieldDelegate?
    
    /// 本地化占位符键（支持 Storyboard 设置，支持动态语言切换）
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
            return CGRect.init(x: 0, y: 0, width: frame.size.width, height: frame.size.height)
        }
        return CGRect.zero
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
    
    /// Cursor left and right spacing
    public func config(orginLeft: CGFloat, orginRight: CGFloat) -> Void {
        self.orginLeft = orginLeft
        self.orginRight = orginRight
    }
    
    /// Character word limit textLimitCount <= 0 no limit
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
    
    /// 更新本地化占位符
    public func st_updateLocalizedPlaceholder() {
        if !localizedPlaceholder.isEmpty {
            self.placeholder = localizedPlaceholder.localized
        }
    }
    
    @objc private func st_textFieldEditingChanged(textField: STTextField) {
        if self.limitCount > 0 {
            if let inputText = textField.text, inputText.count > self.limitCount {
                self.text = String(inputText.prefix(self.limitCount))
            }
        }
        self.cusDelegate?.st_textFieldEditingChanged(textField: textField)
    }
}
