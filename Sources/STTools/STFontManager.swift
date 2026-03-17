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

// MARK: - UIFontMetrics 方案（支持 Dynamic Type）
public extension UIFont {
    /// 使用自定义字体族 + UIFontMetrics 缩放，支持 Dynamic Type
    /// 迁移时只需: UIFont.preferredFont(forTextStyle: .body) → UIFont.st_preferredFont(ofSize: 14, forTextStyle: .body)
    /// - Parameters:
    ///   - size: 基准字号（设计稿尺寸）
    ///   - style: 文本样式，用于 UIFontMetrics 缩放（默认 .body）
    ///   - weight: 字重（默认 .regular）
    ///   - maxSize: 最大字号限制（可选）
    static func st_preferredFont(ofSize size: CGFloat, forTextStyle style: UIFont.TextStyle = .body, weight: UIFont.Weight = .regular, maxSize: CGFloat? = nil) -> UIFont {
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

    /// 使用指定字体名 + UIFontMetrics 缩放，支持 Dynamic Type
    /// - Parameters:
    ///   - name: 字体名称
    ///   - size: 基准字号
    ///   - style: 文本样式，用于 UIFontMetrics 缩放（默认 .body）
    ///   - maxSize: 最大字号限制（可选）
    static func st_preferredFont(name: String, ofSize size: CGFloat, forTextStyle style: UIFont.TextStyle = .body, maxSize: CGFloat? = nil) -> UIFont {
        let baseFont = UIFont(name: name, size: size) ?? .systemFont(ofSize: size)
        let metrics = UIFontMetrics(forTextStyle: style)
        if let maxSize = maxSize {
            return metrics.scaledFont(for: baseFont, maximumPointSize: maxSize)
        }
        return metrics.scaledFont(for: baseFont)
    }
}

// MARK: - 便捷方法（与 UIFont.systemFont 签名一致，方便替换）
public extension UIFont {

    /// 替换 UIFont.systemFont(ofSize:)
    /// 使用自定义字体族 + 屏幕适配缩放
    /// 迁移时只需: UIFont.systemFont(ofSize: 14) → UIFont.st_systemFont(ofSize: 14)
    static func st_systemFont(ofSize size: CGFloat) -> UIFont {
        let scaledSize = STDeviceAdapter.scaledValue(size)
        let config = STDeviceAdapter.shared.fontFamily
        if let name = config.fontName(for: .regular),
           let font = UIFont(name: name, size: scaledSize) {
            return font
        }
        return .systemFont(ofSize: scaledSize)
    }

    /// 替换 UIFont.systemFont(ofSize:weight:)
    /// 迁移时只需: UIFont.systemFont(ofSize: 14, weight: .medium) → UIFont.st_systemFont(ofSize: 14, weight: .medium)
    static func st_systemFont(ofSize size: CGFloat, weight: UIFont.Weight) -> UIFont {
        let scaledSize = STDeviceAdapter.scaledValue(size)
        let config = STDeviceAdapter.shared.fontFamily
        if let name = config.fontName(for: weight),
           let font = UIFont(name: name, size: scaledSize) {
            return font
        }
        return .systemFont(ofSize: scaledSize, weight: weight)
    }

    /// 替换 UIFont.boldSystemFont(ofSize:)
    /// 迁移时只需: UIFont.boldSystemFont(ofSize: 14) → UIFont.st_boldSystemFont(ofSize: 14)
    static func st_boldSystemFont(ofSize size: CGFloat) -> UIFont {
        let scaledSize = STDeviceAdapter.scaledValue(size)
        let config = STDeviceAdapter.shared.fontFamily
        if let name = config.fontName(for: .semibold),
           let font = UIFont(name: name, size: scaledSize) {
            return font
        }
        return .boldSystemFont(ofSize: scaledSize)
    }

    /// 替换 UIFont.italicSystemFont(ofSize:)
    /// 迁移时只需: UIFont.italicSystemFont(ofSize: 14) → UIFont.st_italicSystemFont(ofSize: 14)
    static func st_italicSystemFont(ofSize size: CGFloat) -> UIFont {
        let scaledSize = STDeviceAdapter.scaledValue(size)
        return .italicSystemFont(ofSize: scaledSize)
    }

    /// 替换 UIFont.preferredFont(forTextStyle:)
    /// 使用自定义字体族 + UIFontMetrics 缩放，支持 Dynamic Type
    /// 字号由系统 TextStyle 自动决定，无需手动传入
    /// 迁移时只需: UIFont.preferredFont(forTextStyle: .body) → UIFont.st_preferredFont(forTextStyle: .body)
    static func st_preferredFont(forTextStyle style: UIFont.TextStyle, weight: UIFont.Weight = .regular) -> UIFont {
        let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: style)
        let pointSize = descriptor.pointSize
        return st_preferredFont(ofSize: pointSize, forTextStyle: style, weight: weight)
    }

    /// 替换 UIFont.monospacedDigitSystemFont(ofSize:weight:)
    /// 等宽数字字体，适用于计时器、价格等需要数字对齐的场景
    /// 迁移时只需: UIFont.monospacedDigitSystemFont(ofSize: 14, weight: .regular) → UIFont.st_monospacedDigitSystemFont(ofSize: 14, weight: .regular)
    static func st_monospacedDigitSystemFont(ofSize size: CGFloat, weight: UIFont.Weight) -> UIFont {
        let scaledSize = STDeviceAdapter.scaledValue(size)
        return .monospacedDigitSystemFont(ofSize: scaledSize, weight: weight)
    }

    /// 替换 UIFont.monospacedSystemFont(ofSize:weight:)
    /// 等宽字体，适用于代码块、终端等需要等宽排列的场景
    /// 迁移时只需: UIFont.monospacedSystemFont(ofSize: 14, weight: .regular) → UIFont.st_monospacedSystemFont(ofSize: 14, weight: .regular)
    static func st_monospacedSystemFont(ofSize size: CGFloat, weight: UIFont.Weight) -> UIFont {
        let scaledSize = STDeviceAdapter.scaledValue(size)
        return .monospacedSystemFont(ofSize: scaledSize, weight: weight)
    }
}
