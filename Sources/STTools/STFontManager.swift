//
//  STFontManager.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2018/10/10.
//

import UIKit

public struct STFontFamilyConfig: Sendable, Equatable {
    public var regular: String?
    public var medium: String?
    public var semibold: String?
    public var bold: String?
    public var light: String?
    public var ultraLight: String?
    public var thin: String?
    public var heavy: String?
    public var black: String?
    /// 使用系统默认字体（简体中文环境下系统会自动选用苹方）
    public static let system = STFontFamilyConfig()

    public init(
        regular: String? = nil,
        medium: String? = nil,
        semibold: String? = nil,
        bold: String? = nil,
        light: String? = nil,
        ultraLight: String? = nil,
        thin: String? = nil,
        heavy: String? = nil,
        black: String? = nil
    ) {
        self.regular = regular
        self.medium = medium
        self.semibold = semibold
        self.bold = bold
        self.light = light
        self.ultraLight = ultraLight
        self.thin = thin
        self.heavy = heavy
        self.black = black
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
        case .heavy:      return heavy
        case .black:      return black
        default:          return nil
        }
    }
}

/// 字体的设计语义。基准字号负责视觉层级，text style 负责 Dynamic Type 缩放曲线。
public struct STTypographyToken: Sendable, Equatable {

    public let baseSize: CGFloat
    public let textStyle: UIFont.TextStyle
    public let weight: UIFont.Weight
    public let maximumPointSize: CGFloat?

    public init(
        baseSize: CGFloat,
        textStyle: UIFont.TextStyle,
        weight: UIFont.Weight = .regular,
        maximumPointSize: CGFloat? = nil
    ) {
        self.baseSize = baseSize
        self.textStyle = textStyle
        self.weight = weight
        self.maximumPointSize = maximumPointSize
    }

    public func font(compatibleWith traitCollection: UITraitCollection? = nil) -> UIFont {
        UIFont.st_preferredFont(
            ofSize: self.baseSize,
            forTextStyle: self.textStyle,
            weight: self.weight,
            maxSize: self.maximumPointSize,
            compatibleWith: traitCollection
        )
    }
}

/// STBaseProject 的默认字体语义。业务模块可组合自己的 token，无需扩大全局枚举。
public enum STTypography {
    public static let largeTitle = STTypographyToken(baseSize: 34, textStyle: .largeTitle)
    public static let title = STTypographyToken(baseSize: 20, textStyle: .title3, weight: .semibold)
    public static let headline = STTypographyToken(baseSize: 17, textStyle: .headline, weight: .semibold)
    public static let body = STTypographyToken(baseSize: 17, textStyle: .body)
    public static let callout = STTypographyToken(baseSize: 16, textStyle: .callout)
    public static let subheadline = STTypographyToken(baseSize: 15, textStyle: .subheadline)
    public static let footnote = STTypographyToken(baseSize: 13, textStyle: .footnote)
    public static let caption = STTypographyToken(baseSize: 12, textStyle: .caption1)
    public static let button = STTypographyToken(baseSize: 16, textStyle: .body, weight: .medium)
}

// MARK: - STFontManager
public final class STFontManager {

    public static let shared = STFontManager()
    private let configurationLock = NSLock()
    private var storedFontFamily: STFontFamilyConfig = .system
    private var storedFontSizeScale: CGFloat = 1.0

    public var fontFamily: STFontFamilyConfig {
        self.configurationLock.lock()
        defer { self.configurationLock.unlock() }
        return self.storedFontFamily
    }

    /// 全局字体缩放比例（用于字号调节功能），默认 1.0。
    /// 设置后所有 `st_preferredFont` 方法均会自动乘以此比例。
    public var fontSizeScale: CGFloat {
        get {
            self.configurationLock.lock()
            defer { self.configurationLock.unlock() }
            return self.storedFontSizeScale
        }
        set {
            self.configurationLock.lock()
            defer { self.configurationLock.unlock() }
            self.storedFontSizeScale = newValue
        }
    }

    private init() {}

    public func configure(fontFamily: STFontFamilyConfig) {
        self.configurationLock.lock()
        defer { self.configurationLock.unlock() }
        self.storedFontFamily = fontFamily
    }

    /// 同时配置字体族和缩放比例。
    public func configure(fontFamily: STFontFamilyConfig, fontSizeScale: CGFloat) {
        self.configurationLock.lock()
        defer { self.configurationLock.unlock() }
        self.storedFontFamily = fontFamily
        self.storedFontSizeScale = fontSizeScale
    }

    public func reset() {
        self.configurationLock.lock()
        defer { self.configurationLock.unlock() }
        self.storedFontFamily = .system
        self.storedFontSizeScale = 1.0
    }
}

// MARK: - UIFontMetrics 方案（支持 Dynamic Type）
public extension UIFont {
    /// 使用自定义字体族 + UIFontMetrics 缩放，支持 Dynamic Type
    /// 迁移时只需: UIFont.preferredFont(forTextStyle: .body) → UIFont.st_preferredFont(ofSize: 14, forTextStyle: .body)
    /// - Parameters:
    ///   - size: 基准字号（设计稿尺寸）
    ///   - style: 文本样式，用于 UIFontMetrics 缩放（默认 .body）
    ///   - weight: 字重（默认 .regular）
    ///   - maxSize: 最大字号限制（可选）
    static func st_preferredFont(
        ofSize size: CGFloat,
        forTextStyle style: UIFont.TextStyle = .body,
        weight: UIFont.Weight = .regular,
        maxSize: CGFloat? = nil,
        compatibleWith traitCollection: UITraitCollection? = nil
    ) -> UIFont {
        let adjustedSize = size * STFontManager.shared.fontSizeScale
        let config = STFontManager.shared.fontFamily
        let baseFont: UIFont
        if let name = config.fontName(for: weight),
           let customFont = UIFont(name: name, size: adjustedSize) {
            baseFont = customFont
        } else {
            baseFont = UIFont.systemFont(ofSize: adjustedSize, weight: weight)
        }
        let metrics = UIFontMetrics(forTextStyle: style)
        if let maxSize = maxSize {
            return metrics.scaledFont(for: baseFont, maximumPointSize: maxSize, compatibleWith: traitCollection)
        }
        return metrics.scaledFont(for: baseFont, compatibleWith: traitCollection)
    }

    /// 使用指定字体名 + UIFontMetrics 缩放，支持 Dynamic Type
    /// - Parameters:
    ///   - name: 字体名称
    ///   - size: 基准字号
    ///   - style: 文本样式，用于 UIFontMetrics 缩放（默认 .body）
    ///   - maxSize: 最大字号限制（可选）
    static func st_preferredFont(
        name: String,
        ofSize size: CGFloat,
        forTextStyle style: UIFont.TextStyle = .body,
        maxSize: CGFloat? = nil,
        compatibleWith traitCollection: UITraitCollection? = nil
    ) -> UIFont {
        let adjustedSize = size * STFontManager.shared.fontSizeScale
        let baseFont = UIFont(name: name, size: adjustedSize) ?? .systemFont(ofSize: adjustedSize)
        let metrics = UIFontMetrics(forTextStyle: style)
        if let maxSize = maxSize {
            return metrics.scaledFont(for: baseFont, maximumPointSize: maxSize, compatibleWith: traitCollection)
        }
        return metrics.scaledFont(for: baseFont, compatibleWith: traitCollection)
    }
}

// MARK: - 便捷方法（与 UIFont.systemFont 签名一致，方便替换）
public extension UIFont {

    /// 替换 UIFont.preferredFont(forTextStyle:)
    /// 使用自定义字体族 + UIFontMetrics 缩放，支持 Dynamic Type
    /// 字号由系统 TextStyle 自动决定，无需手动传入
    /// 迁移时只需: UIFont.preferredFont(forTextStyle: .body) → UIFont.st_preferredFont(forTextStyle: .body)
    static func st_preferredFont(forTextStyle style: UIFont.TextStyle, weight: UIFont.Weight = .regular) -> UIFont {
        let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: style)
        let pointSize = descriptor.pointSize
        return st_preferredFont(ofSize: pointSize, forTextStyle: style, weight: weight)
    }

    /// 支持 Dynamic Type 的等宽字体，适用于代码、日志、计时器和行号。
    static func st_preferredMonospacedFont(
        ofSize size: CGFloat,
        weight: UIFont.Weight = .regular,
        forTextStyle style: UIFont.TextStyle = .body,
        maxSize: CGFloat? = nil,
        compatibleWith traitCollection: UITraitCollection? = nil
    ) -> UIFont {
        let adjustedSize = size * STFontManager.shared.fontSizeScale
        let baseFont = UIFont.monospacedSystemFont(ofSize: adjustedSize, weight: weight)
        let metrics = UIFontMetrics(forTextStyle: style)
        if let maxSize {
            return metrics.scaledFont(for: baseFont, maximumPointSize: maxSize, compatibleWith: traitCollection)
        }
        return metrics.scaledFont(for: baseFont, compatibleWith: traitCollection)
    }

}
