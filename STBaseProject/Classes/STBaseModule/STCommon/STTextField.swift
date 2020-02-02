//
//  STTextField.swift
//  STBaseFramework
//
//  Created by stack on 2019/12/12.
//  Copyright © 2019 ST. All rights reserved.
//

import UIKit

open class STTextField: UITextField {
    
    open var orginLeft: CGFloat = 0
    open var orginRight: CGFloat = 0
    open var textIsCheck: Bool = false

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
    
    open override func awakeFromNib() {
        super.awakeFromNib()
        self.configContent()
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.configContent()
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
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
    
    func configContent() {
        self.autocorrectionType = UITextAutocorrectionType.no
        self.autocapitalizationType = UITextAutocapitalizationType.none
    }
    
    public func configAttributed(textColor: UIColor) -> Void {
        if let attributedText = self.attributedPlaceholder {
            let placeholderAttributedString = NSMutableAttributedString(attributedString: attributedText)
            placeholderAttributedString.addAttribute(.foregroundColor, value: textColor, range: NSRange(location: 0, length: placeholderAttributedString.length))
            self.attributedPlaceholder = placeholderAttributedString
        }
    }
}
