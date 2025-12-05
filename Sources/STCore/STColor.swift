//
//  STColor.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2018/10/9.
//

import UIKit
import CoreGraphics

// MARK: - 颜色创建方法
public extension UIColor {
    
    /// 从十六进制字符串创建颜色（sRGB 色彩空间）
    /// - Parameter hexString: 十六进制字符串，支持 #、0x 前缀，支持 3位(#FFF)、6位(#FFFFFF)、8位(#FFFFFFFF)格式
    ///   如果使用 8 位格式，alpha 值将从 hexString 中读取；否则 alpha 默认为 1.0
    /// - Returns: UIColor 对象
    static func st_color(hexString: String) -> UIColor {
        return st_colorInternal(hexString: hexString, alpha: nil)
    }
    
    /// 从十六进制字符串创建颜色（sRGB 色彩空间，可指定透明度）
    /// - Parameters:
    ///   - hexString: 十六进制字符串，支持 #、0x 前缀，支持 3位(#FFF)、6位(#FFFFFF)、8位(#FFFFFFFF)格式
    ///   - alpha: 透明度 (0.0-1.0)，如果指定则覆盖 hexString 中的 alpha 值
    /// - Returns: UIColor 对象
    static func st_color(hexString: String, alpha: CGFloat) -> UIColor {
        return st_colorInternal(hexString: hexString, alpha: alpha)
    }
    
    /// 内部实现方法
    private static func st_colorInternal(hexString: String, alpha: CGFloat?) -> UIColor {
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
        return st_colorInSRGB(red: red, green: green, blue: blue, alpha: finalAlpha)
    }
    
    /// 从 RGB 值创建颜色（sRGB 色彩空间，确保与设计图一致）
    /// - Parameters:
    ///   - red: 红色值 (0-255)
    ///   - green: 绿色值 (0-255)
    ///   - blue: 蓝色值 (0-255)
    ///   - alpha: 透明度 (0.0-1.0)，默认 1.0
    /// - Returns: UIColor 对象
    static func st_color(red: Int, green: Int, blue: Int, alpha: CGFloat = 1.0) -> UIColor {
        return st_colorInSRGB(
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
    static func st_color(hue: CGFloat, saturation: CGFloat, brightness: CGFloat, alpha: CGFloat = 1.0) -> UIColor {
        return UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: alpha)
    }
    
    /// 从 Assets 中的颜色集创建颜色（支持暗黑模式）
    /// 注意：颜色和透明度都从 Assets 中读取，如需调整透明度请使用 withAlphaComponent 方法
    /// - Parameter colorSet: 颜色集名称
    /// - Returns: UIColor 对象，如果找不到颜色集则返回 clear
    @available(iOS 11.0, *)
    static func st_color(colorSet: String) -> UIColor {
        guard !colorSet.isEmpty else {
            return UIColor.clear
        }
        return UIColor(named: colorSet) ?? UIColor.clear
    }
}

// MARK: - 私有辅助方法
private extension UIColor {
    /// 在 sRGB 色彩空间中创建颜色
    /// 此方法显式使用 sRGB 色彩空间，避免在支持 Display P3 的设备上出现颜色偏差
    /// - Parameters:
    ///   - red: 红色值 (0.0-1.0)
    ///   - green: 绿色值 (0.0-1.0)
    ///   - blue: 蓝色值 (0.0-1.0)
    ///   - alpha: 透明度 (0.0-1.0)
    /// - Returns: UIColor 对象
    static func st_colorInSRGB(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) -> UIColor {
        // 使用 CGColor 和 sRGB 色彩空间显式创建颜色
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
