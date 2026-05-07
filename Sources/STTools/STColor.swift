//
//  STColor.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2018/10/9.
//

import UIKit
import CoreGraphics

public extension UIColor {
    
    /// 从 Assets 中的颜色集创建颜色（支持暗黑模式）
    /// 注意：颜色和透明度都从 Assets 中读取，如需调整透明度请使用 withAlphaComponent 方法
    /// - Parameter colorSet: 颜色集名称
    /// - Returns: UIColor 对象，如果找不到颜色集则返回 clear
    static func color(named colorSet: String) -> UIColor {
        guard !colorSet.isEmpty else {
            return UIColor.clear
        }
        return UIColor(named: colorSet) ?? UIColor.clear
    }
    
    /// 从十六进制字符串创建颜色（sRGB 色彩空间）
    /// - Parameter hexString: 十六进制字符串，支持 #、0x 前缀，支持 3位(#FFF)、6位(#FFFFFF)、8位(#FFFFFFFF)格式
    ///   如果使用 8 位格式，alpha 值将从 hexString 中读取；否则 alpha 默认为 1.0
    /// - Returns: UIColor 对象
    static func color(hex hexString: String) -> UIColor {
        return color(hexString: hexString, alphaOverride: nil)
    }
    
    /// 从十六进制字符串创建颜色（sRGB 色彩空间，可指定透明度）
    /// - Parameters:
    ///   - hexString: 十六进制字符串，支持 #、0x 前缀，支持 3位(#FFF)、6位(#FFFFFF)、8位(#FFFFFFFF)格式
    ///   - alpha: 透明度 (0.0-1.0)，如果指定则覆盖 hexString 中的 alpha 值
    /// - Returns: UIColor 对象
    static func color(hex hexString: String, alpha: CGFloat) -> UIColor {
        return color(hexString: hexString, alphaOverride: alpha)
    }
    
    private static func color(hexString: String, alphaOverride alpha: CGFloat?) -> UIColor {
        guard !hexString.isEmpty else {
            return UIColor.clear
        }
        var cString = hexString.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).uppercased()
        if cString.hasPrefix("#") {
            cString = String(cString.dropFirst())
        } else if cString.hasPrefix("0X") {
            cString = String(cString.dropFirst(2))
        }
        // 支持 3 位简写格式（如 FFF -> FFFFFF）
        if cString.count == 3 {
            cString = cString.map { "\($0)\($0)" }.joined()
        }
        var rgbValue: UInt64 = 0
        guard Scanner(string: cString).scanHexInt64(&rgbValue) else {
            return UIColor.clear
        }
        var finalAlpha: CGFloat = 1.0
        // 如果用户明确指定了 alpha，使用用户指定的值；否则从 hexString 中读取
        if let userAlpha = alpha {
            finalAlpha = userAlpha
            // 如果 hexString 是 8 位格式但用户指定了 alpha，需要清除 alpha 位
            if cString.count == 8 {
                rgbValue = rgbValue & 0x00FFFFFF
            }
        } else if cString.count == 8 {
            // 8 位格式（RRGGBBAA），alpha 从 hexString 中读取
            finalAlpha = CGFloat((rgbValue & 0xFF000000) >> 24) / 255.0
            rgbValue = rgbValue & 0x00FFFFFF
        }
        if cString.count != 6 && cString.count != 8 {
            return UIColor.clear
        }
        // 显式使用 sRGB 色彩空间，确保与设计图一致
        let red = CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(rgbValue & 0x0000FF) / 255.0
        return srgbColor(red: red, green: green, blue: blue, alpha: finalAlpha)
    }
    
    /// 从 RGB 值创建颜色（sRGB 色彩空间，确保与设计图一致）
    /// - Parameters:
    ///   - red: 红色值 (0-255)
    ///   - green: 绿色值 (0-255)
    ///   - blue: 蓝色值 (0-255)
    ///   - alpha: 透明度 (0.0-1.0)，默认 1.0
    /// - Returns: UIColor 对象
    static func color(red: Int, green: Int, blue: Int, alpha: CGFloat = 1.0) -> UIColor {
        return srgbColor(
            red: CGFloat(red) / 255.0,
            green: CGFloat(green) / 255.0,
            blue: CGFloat(blue) / 255.0,
            alpha: alpha
        )
    }
    
    /// 从 HSB 值创建颜色
    /// - Parameters:
    ///   - hue: 色相 (0.0-1.0)
    ///   - saturation: 饱和度 (0.0-1.0)
    ///   - brightness: 亮度 (0.0-1.0)
    ///   - alpha: 透明度 (0.0-1.0)，默认 1.0
    /// - Returns: UIColor 对象
    static func color(hue: CGFloat, saturation: CGFloat, brightness: CGFloat, alpha: CGFloat = 1.0) -> UIColor {
        return UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: alpha)
    }
}

private extension UIColor {
    /// 在 sRGB 色彩空间中创建颜色
    /// 此方法显式使用 sRGB 色彩空间，避免在支持 Display P3 的设备上出现颜色偏差
    /// - Parameters:
    ///   - red: 红色值 (0.0-1.0)
    ///   - green: 绿色值 (0.0-1.0)
    ///   - blue: 蓝色值 (0.0-1.0)
    ///   - alpha: 透明度 (0.0-1.0)
    /// - Returns: UIColor 对象
    static func srgbColor(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) -> UIColor {
        guard let sRGBColorSpace = CGColorSpace(name: CGColorSpace.sRGB) else {
            return UIColor(red: red, green: green, blue: blue, alpha: alpha)
        }
        let components = [red, green, blue, alpha]
        guard let cgColor = CGColor(colorSpace: sRGBColorSpace, components: components) else {
            return UIColor(red: red, green: green, blue: blue, alpha: alpha)
        }
        return UIColor(cgColor: cgColor)
    }
}

// MARK: - Color Modification

public extension UIColor {

    /// 通过 block 修改 RGBA 分量后生成新颜色；若当前颜色只支持灰度，则 R=G=B=white
    /// - Parameter modify: 传入可变的 red/green/blue/alpha
    /// - Returns: 新的 UIColor
    func modifyingRGBA(_ modify: (_ red: inout CGFloat, _ green: inout CGFloat, _ blue: inout CGFloat, _ alpha: inout CGFloat) -> Void) -> UIColor {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        if !getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
            var white: CGFloat = 0
            if getWhite(&white, alpha: &alpha) {
                red = white
                green = white
                blue = white
            } else {
                return self
            }
        }
        modify(&red, &green, &blue, &alpha)
        return UIColor(
            red: max(0, min(1, red)),
            green: max(0, min(1, green)),
            blue: max(0, min(1, blue)),
            alpha: max(0, min(1, alpha))
        )
    }

    /// 通过 block 修改 HSBA 分量后生成新颜色
    func modifyingHSBA(_ modify: (_ hue: inout CGFloat, _ saturation: inout CGFloat, _ brightness: inout CGFloat, _ alpha: inout CGFloat) -> Void) -> UIColor {
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        if !getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) {
            var white: CGFloat = 0
            if getWhite(&white, alpha: &alpha) {
                hue = 0
                saturation = 0
                brightness = white
            } else {
                return self
            }
        }
        modify(&hue, &saturation, &brightness, &alpha)
        return UIColor(
            hue: max(0, min(1, hue)),
            saturation: max(0, min(1, saturation)),
            brightness: max(0, min(1, brightness)),
            alpha: max(0, min(1, alpha))
        )
    }

    /// 生成 CSS 风格颜色字符串 `rgba(r, g, b, a)`，便于注入 WebView 样式
    var cssColorString: String {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        if getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
            return Self.cssColorString(red: red, green: green, blue: blue, alpha: alpha)
        }
        var white: CGFloat = 0
        if getWhite(&white, alpha: &alpha) {
            return Self.cssColorString(red: white, green: white, blue: white, alpha: alpha)
        }
        return "rgba(0, 0, 0, 1)"
    }

    private static func cssColorString(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) -> String {
        let r = Int(round(max(0, min(1, red)) * 255))
        let g = Int(round(max(0, min(1, green)) * 255))
        let b = Int(round(max(0, min(1, blue)) * 255))
        let a = max(0, min(1, alpha))
        return String(format: "rgba(%d, %d, %d, %.3g)", locale: Locale(identifier: "en_US_POSIX"), r, g, b, Double(a))
    }

    /// 按 source-over 方式与另一颜色混合
    /// - Parameter other: 叠加在当前颜色上的目标颜色
    /// - Returns: 混合后的颜色
    func blending(with other: UIColor) -> UIColor? {
        func components(of color: UIColor) -> (CGFloat, CGFloat, CGFloat, CGFloat)? {
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            if color.getRed(&r, green: &g, blue: &b, alpha: &a) {
                return (r, g, b, a)
            }
            var white: CGFloat = 0
            if color.getWhite(&white, alpha: &a) {
                return (white, white, white, a)
            }
            return nil
        }

        guard let (baseRed, baseGreen, baseBlue, baseAlpha) = components(of: self),
              let (sourceRed, sourceGreen, sourceBlue, sourceAlpha) = components(of: other)
        else {
            return nil
        }

        let outputAlpha = sourceAlpha + baseAlpha * (1.0 - sourceAlpha)
        guard outputAlpha > 0 else {
            return UIColor(red: 0, green: 0, blue: 0, alpha: 0)
        }

        return UIColor(
            red: (sourceRed * sourceAlpha + baseRed * baseAlpha * (1.0 - sourceAlpha)) / outputAlpha,
            green: (sourceGreen * sourceAlpha + baseGreen * baseAlpha * (1.0 - sourceAlpha)) / outputAlpha,
            blue: (sourceBlue * sourceAlpha + baseBlue * baseAlpha * (1.0 - sourceAlpha)) / outputAlpha,
            alpha: outputAlpha
        )
    }

    /// 十六进制整数值（0xRRGGBB）创建颜色
    static func color(hexValue: UInt32, alpha: CGFloat = 1.0) -> UIColor {
        let red = CGFloat((hexValue & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((hexValue & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(hexValue & 0x0000FF) / 255.0
        return UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }
}
