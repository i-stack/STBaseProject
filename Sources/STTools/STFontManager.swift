//
//  STFontManager.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2018/10/10.
//

import UIKit

public struct STFontFamilyConfig {
    public var regular: String
    public var medium: String
    public var semibold: String
    public var bold: String
    public var light: String
    public var ultraLight: String
    public var thin: String

    public static let pingFangSC = STFontFamilyConfig(
        regular:    "PingFangSC-Regular",
        medium:     "PingFangSC-Medium",
        semibold:   "PingFangSC-Semibold",
        bold:       "PingFangSC-Semibold",
        light:      "PingFangSC-Light",
        ultraLight: "PingFangSC-Ultralight",
        thin:       "PingFangSC-Thin"
    )

    public init(
        regular: String,
        medium: String,
        semibold: String,
        bold: String,
        light: String,
        ultraLight: String,
        thin: String
    ) {
        self.regular = regular
        self.medium = medium
        self.semibold = semibold
        self.bold = bold
        self.light = light
        self.ultraLight = ultraLight
        self.thin = thin
    }

    func fontName(for weight: UIFont.Weight) -> String? {
        switch weight {
        case .regular:    return regular
        case .medium:     return medium
        case .semibold:   return semibold
        case .bold:       return bold
        case .light:      return light
        case .ultraLight: return ultraLight
        case .thin:       return thin
        default:          return nil
        }
    }
}

// MARK: - UIFontMetrics 方案（推荐）
public extension UIFont {
    /// 使用自定义字体 + UIFontMetrics 缩放，支持 Dynamic Type
    static func st_font(
        style: UIFont.TextStyle = .body,
        size: CGFloat,
        weight: UIFont.Weight = .regular,
        maxSize: CGFloat? = nil
    ) -> UIFont {
        let config = STDeviceAdapter.shared.fontFamily
        let baseFont: UIFont
        if let name = config.fontName(for: weight),
           let customFont = UIFont(name: name, size: size) {
            baseFont = customFont
        } else {
            baseFont = .systemFont(ofSize: size, weight: weight)
        }
        let metrics = UIFontMetrics(forTextStyle: style)
        if let maxSize = maxSize {
            return metrics.scaledFont(for: baseFont, maximumPointSize: maxSize)
        }
        return metrics.scaledFont(for: baseFont)
    }

    /// 使用指定字体名 + UIFontMetrics 缩放
    static func st_font(
        name: String,
        style: UIFont.TextStyle = .body,
        size: CGFloat,
        maxSize: CGFloat? = nil
    ) -> UIFont {
        let baseFont = UIFont(name: name, size: size) ?? .systemFont(ofSize: size)
        let metrics = UIFontMetrics(forTextStyle: style)
        if let maxSize = maxSize {
            return metrics.scaledFont(for: baseFont, maximumPointSize: maxSize)
        }
        return metrics.scaledFont(for: baseFont)
    }
}

// MARK: - Swizzle 方案（已废弃，保留向后兼容）
public extension UIFont {
    @available(*, deprecated, message: "Use UIFont.st_font() instead")
    class func activateAdaptiveFonts() {
        self.activateSystemFontSwizzle()
        self.activateWeightedSystemFontSwizzle()
        self.activateBoldSystemFontSwizzle()
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
        guard let metaClass = object_getClass(self) else { return }
        guard let originalMethod = class_getInstanceMethod(metaClass, originalSelector),
              let swizzledMethod = class_getInstanceMethod(metaClass, swizzledSelector) else {
            return
        }
        let didAddMethod = class_addMethod(
            metaClass,
            originalSelector,
            method_getImplementation(swizzledMethod),
            method_getTypeEncoding(swizzledMethod)
        )
        if didAddMethod {
            class_replaceMethod(
                metaClass,
                swizzledSelector,
                method_getImplementation(originalMethod),
                method_getTypeEncoding(originalMethod)
            )
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
    }
    
    private class func scaledFontSize(for size: CGFloat) -> CGFloat {
        return STDeviceAdapter.scaledValue(size)
    }
    
    /// 查找自定义字体的内部方法，不经过 swizzle 链路
    private class func resolveFont(size: CGFloat, weight: UIFont.Weight) -> UIFont? {
        let config = STDeviceAdapter.shared.fontFamily
        guard let name = config.fontName(for: weight) else { return nil }
        return UIFont(name: name, size: size)
    }

    @objc class func adaptiveSystemFont(ofSize: CGFloat) -> UIFont {
        let size = UIFont.scaledFontSize(for: ofSize)
        if let font = resolveFont(size: size, weight: .regular) {
            return font
        }
        // swizzle 后调用的是原始 systemFont(ofSize:)
        return self.adaptiveSystemFont(ofSize: size)
    }

    @objc class func adaptiveSystemFont(ofSize: CGFloat, weight: UIFont.Weight) -> UIFont {
        let size = UIFont.scaledFontSize(for: ofSize)
        if let font = resolveFont(size: size, weight: weight) {
            return font
        }
        // swizzle 后调用的是原始 systemFont(ofSize:weight:)
        return self.adaptiveSystemFont(ofSize: size, weight: weight)
    }

    @objc class func adaptiveBoldSystemFont(ofSize: CGFloat) -> UIFont {
        let size = UIFont.scaledFontSize(for: ofSize)
        if let font = resolveFont(size: size, weight: .semibold) {
            return font
        }
        return self.adaptiveBoldSystemFont(ofSize: size)
    }
}
