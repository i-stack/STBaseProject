//
//  STFontManager.swift
//  STBaseProject
//
//  Created by stack on 2018/10/10.
//

import UIKit

public extension UIFont {
    class func initializeMethod() {
        self.st_initNameSwizzled()
        self.st_systemFontSwizzled()
        self.st_systemFontSwizzledWithWeight()
        self.st_boldSystemFontSwizzled()
    }
    
    private class func st_initNameSwizzled() -> Void {
       let originalSelector = #selector(UIFont.init(name:size:))
       let swizzledSelector = #selector(UIFont.st_boldSystemFont(ofSize:))
       self.st_beginSwizzled(originalSelector: originalSelector, swizzledSelector: swizzledSelector)
    }
    
    private class func st_systemFontSwizzled() -> Void {
        let originalSelector = #selector(UIFont.systemFont(ofSize:))
        let swizzledSelector = #selector(UIFont.st_systemFont(ofSize:))
        self.st_beginSwizzled(originalSelector: originalSelector, swizzledSelector: swizzledSelector)
    }
    
    private class func st_systemFontSwizzledWithWeight() -> Void {
        let originalSelector = #selector(UIFont.systemFont(ofSize:weight:))
        let swizzledSelector = #selector(UIFont.st_systemFont(ofSize:weight:))
        self.st_beginSwizzled(originalSelector: originalSelector, swizzledSelector: swizzledSelector)
    }
    
    private class func st_boldSystemFontSwizzled() -> Void {
        let originalSelector = #selector(UIFont.boldSystemFont(ofSize:))
        let swizzledSelector = #selector(UIFont.st_boldSystemFont(ofSize:))
        self.st_beginSwizzled(originalSelector: originalSelector, swizzledSelector: swizzledSelector)
    }
    
    private class func st_beginSwizzled(originalSelector: Selector, swizzledSelector: Selector) {
        let originalMethod = class_getInstanceMethod(self, originalSelector)
        let swizzledMethod = class_getInstanceMethod(self, swizzledSelector)
        let didAddMethod: Bool = class_addMethod(self, originalSelector, method_getImplementation(swizzledMethod!), method_getTypeEncoding(swizzledMethod!))
        if didAddMethod {
            class_replaceMethod(self, swizzledSelector, method_getImplementation(originalMethod!), method_getTypeEncoding(originalMethod!))
        } else {
            method_exchangeImplementations(originalMethod!, swizzledMethod!)
        }
    }
    
    private class func st_fontSize(size: CGFloat) -> CGFloat {
        return STConstants.st_handleFloat(float: size)
    }
    
    @objc class func st_systemFont(ofSize: CGFloat) -> UIFont {
        if let font = UIFont.init(name: "PingFangSC-Regular", size: ofSize) {
            return font
        }
        return UIFont.systemFont(ofSize: ofSize)
    }
    
    @objc class func st_systemFont(ofSize: CGFloat, weight: UIFont.Weight) -> UIFont {
        var font: UIFont?
        let size = UIFont.st_fontSize(size: ofSize)
        switch weight {
        case .medium:
            font = UIFont.init(name: "PingFangSC-Medium", size: size)
            break
        case .semibold, .bold:
            font = UIFont.init(name: "PingFangSC-Semibold", size: size)
            break
        case .light:
            font = UIFont.init(name: "PingFangSC-Light", size: size)
            break
        case .ultraLight:
            font = UIFont.init(name: "PingFangSC-Ultralight", size: size)
            break
        case .regular:
            font = UIFont.init(name: "PingFangSC-Regular", size: size)
            break
        case .thin:
            font = UIFont.init(name: "PingFangSC-Thin", size: size)
            break
        default:
            break
        }
        return font ?? UIFont.systemFont(ofSize: ofSize, weight: weight)
    }
    
    @objc class func st_systemFont(ofSize: CGFloat, fontName: String) -> UIFont {
        let size = UIFont.st_fontSize(size: ofSize)
        return UIFont.init(name: fontName, size: ofSize) ?? UIFont.systemFont(ofSize: size)
    }
    
    @objc class func st_boldSystemFont(ofSize: CGFloat) -> UIFont {
        return self.st_systemFont(ofSize: ofSize, weight: .semibold)
    }
}
