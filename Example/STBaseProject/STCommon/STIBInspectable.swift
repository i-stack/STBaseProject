//
//  STIBInspectable.swift
//  STBaseProject
//
//  Created by stack on 2017/02/24.
//

import UIKit

extension NSLayoutConstraint {
    @IBInspectable open var autoConstant: Bool {
        set {
            self.constant = STConstants.st_handleFloat(float: self.constant)
        }
        get {
            return true
        }
    }
}

extension UILabel {
    @IBInspectable open var autoFont: Bool {
        set {
            let fontName = self.font.fontName
            self.font = UIFont.st_systemFont(ofSize: self.font.pointSize, fontName: fontName)
        }
        get {
            return true
        }
    }
}
