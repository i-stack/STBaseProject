//
//  STFontManager.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2018/10/10.
//

import UIKit

public extension UIFont {
    class func activateAdaptiveFonts() {
        self.activateNameFontSwizzle()
        self.activateSystemFontSwizzle()
        self.activateWeightedSystemFontSwizzle()
        self.activateBoldSystemFontSwizzle()
    }
    
    private class func activateNameFontSwizzle() {
       let originalSelector = #selector(UIFont.init(name:size:))
       let swizzledSelector = #selector(UIFont.adaptiveBoldSystemFont(ofSize:))
       self.applySwizzle(originalSelector: originalSelector, swizzledSelector: swizzledSelector)
    }
    
    private class func activateSystemFontSwizzle() {
        let originalSelector = #selector(UIFont.systemFont(ofSize:))
        let swizzledSelector = #selector(UIFont.adaptiveSystemFont(ofSize:))
        self.applySwizzle(originalSelector: originalSelector, swizzledSelector: swizzledSelector)
    }
    
    private class func activateWeightedSystemFontSwizzle() {
        let originalSelector = #selector(UIFont.systemFont(ofSize:weight:))
        let swizzledSelector = #selector(UIFont.adaptiveSystemFont(ofSize:weight:))
        self.applySwizzle(originalSelector: originalSelector, swizzledSelector: swizzledSelector)
    }
    
    private class func activateBoldSystemFontSwizzle() {
        let originalSelector = #selector(UIFont.boldSystemFont(ofSize:))
        let swizzledSelector = #selector(UIFont.adaptiveBoldSystemFont(ofSize:))
        self.applySwizzle(originalSelector: originalSelector, swizzledSelector: swizzledSelector)
    }
    
    private class func applySwizzle(originalSelector: Selector, swizzledSelector: Selector) {
        let originalMethod = class_getInstanceMethod(self, originalSelector)
        let swizzledMethod = class_getInstanceMethod(self, swizzledSelector)
        let didAddMethod: Bool = class_addMethod(self, originalSelector, method_getImplementation(swizzledMethod!), method_getTypeEncoding(swizzledMethod!))
        if didAddMethod {
            class_replaceMethod(self, swizzledSelector, method_getImplementation(originalMethod!), method_getTypeEncoding(originalMethod!))
        } else {
            method_exchangeImplementations(originalMethod!, swizzledMethod!)
        }
    }
    
    private class func scaledFontSize(for size: CGFloat) -> CGFloat {
        return STDeviceAdapter.scaledValue(size)
    }
    
    @objc class func adaptiveSystemFont(ofSize: CGFloat) -> UIFont {
        return self.adaptiveSystemFont(ofSize: ofSize, weight: .regular)
    }
    
    @objc class func adaptiveSystemFont(ofSize: CGFloat, weight: UIFont.Weight) -> UIFont {
        var font: UIFont?
        let size = UIFont.scaledFontSize(for: ofSize)
        switch weight {
        case .medium:
            font = UIFont.init(name: "PingFangSC-Medium", size: size)
        case .semibold, .bold:
            font = UIFont.init(name: "PingFangSC-Semibold", size: size)
        case .light:
            font = UIFont.init(name: "PingFangSC-Light", size: size)
        case .ultraLight:
            font = UIFont.init(name: "PingFangSC-Ultralight", size: size)
        case .regular:
            font = UIFont.init(name: "PingFangSC-Regular", size: size)
        case .thin:
            font = UIFont.init(name: "PingFangSC-Thin", size: size)
        default: break
        }
        return font ?? UIFont.systemFont(ofSize: ofSize, weight: weight)
    }
    
    @objc class func adaptiveSystemFont(ofSize: CGFloat, fontName: String) -> UIFont {
        let size = UIFont.scaledFontSize(for: ofSize)
        return UIFont.init(name: fontName, size: ofSize) ?? UIFont.systemFont(ofSize: size)
    }
    
    @objc class func adaptiveBoldSystemFont(ofSize: CGFloat) -> UIFont {
        return self.adaptiveSystemFont(ofSize: ofSize, weight: .semibold)
    }
}
