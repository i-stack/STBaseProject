//
//  STIBInspectable.swift
//  STBaseProject
//
//  Created by stack on 2017/02/24.
//

import UIKit

extension NSLayoutConstraint {
    private struct AssociatedKeys {
        static var autoConstantKey = true
    }
    
    private var _autoConstant: Bool {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.autoConstantKey) as? Bool ?? true
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.autoConstantKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    @IBInspectable open var autoConstant: Bool {
        set {
            _autoConstant = newValue
            
            if newValue {
                self.constant = STBaseConstants.st_handleFloat(float: self.constant)
            }
        }
        get {
            return false
        }
    }
    
    open override func awakeFromNib() {
        super.awakeFromNib()
        if _autoConstant == true {
            self.constant = STBaseConstants.st_handleFloat(float: self.constant)
        }
    }
}
