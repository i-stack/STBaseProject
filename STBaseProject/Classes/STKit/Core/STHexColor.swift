//
//  STHexColor.swift
//  STBaseProject
//
//  Created by stack on 2018/10/9.
//

import UIKit

public extension UIColor {
    
    // MARK: - 基础颜色创建
    
    /// 从十六进制字符串创建颜色
    /// - Parameter hexString: 十六进制字符串，支持 #、0x 前缀
    /// - Returns: UIColor 对象
    static func st_color(hexString: String) -> UIColor {
        return st_color(hexString: hexString, alpha: 1.0)
    }
    
    /// 从十六进制字符串创建颜色（带透明度）
    /// - Parameters:
    ///   - hexString: 十六进制字符串，支持 #、0x 前缀
    ///   - alpha: 透明度 (0.0 - 1.0)
    /// - Returns: UIColor 对象
    static func st_color(hexString: String, alpha: CGFloat) -> UIColor {
        if hexString.count < 1 {
            return UIColor.clear
        }
        var cString = hexString.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).uppercased()
        if cString.count < 6 {
            return UIColor.clear
        }
        if cString.hasPrefix("#") {
            cString = String(cString.dropFirst())
        }
        if cString.hasPrefix("0X") {
            let start = cString.index(cString.startIndex, offsetBy: 2)
            cString = String(cString[start...])
        }
        if cString.count != 6 {
            return UIColor.clear
        }
        var rgbValue: UInt64 = 0
        Scanner(string: cString).scanHexInt64(&rgbValue)
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: alpha
        )
    }
    
    /// 从 RGB 值创建颜色
    /// - Parameters:
    ///   - red: 红色值 (0-255)
    ///   - green: 绿色值 (0-255)
    ///   - blue: 蓝色值 (0-255)
    ///   - alpha: 透明度 (0.0-1.0)
    /// - Returns: UIColor 对象
    static func st_color(red: Int, green: Int, blue: Int, alpha: CGFloat = 1.0) -> UIColor {
        return UIColor(
            red: CGFloat(red) / 255.0,
            green: CGFloat(green) / 255.0,
            blue: CGFloat(blue) / 255.0,
            alpha: alpha
        )
    }
    
    /// 从 RGB 值创建颜色（0-1 范围）
    /// - Parameters:
    ///   - red: 红色值 (0.0-1.0)
    ///   - green: 绿色值 (0.0-1.0)
    ///   - blue: 蓝色值 (0.0-1.0)
    ///   - alpha: 透明度 (0.0-1.0)
    /// - Returns: UIColor 对象
    static func st_color(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat = 1.0) -> UIColor {
        return UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }
    
    // MARK: - 暗黑模式支持
    
    /// 创建支持暗黑模式的动态颜色
    /// - Parameters:
    ///   - lightHex: 浅色模式下的十六进制颜色
    ///   - darkHex: 暗黑模式下的十六进制颜色
    ///   - alpha: 透明度
    /// - Returns: 动态颜色对象
    @available(iOS 13.0, *)
    static func st_dynamicColor(lightHex: String, darkHex: String, alpha: CGFloat = 1.0) -> UIColor {
        return UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return st_color(hexString: darkHex, alpha: alpha)
            } else {
                return st_color(hexString: lightHex, alpha: alpha)
            }
        }
    }
    
    /// 创建支持暗黑模式的动态颜色（带默认值）
    /// - Parameters:
    ///   - lightHex: 浅色模式下的十六进制颜色
    ///   - darkHex: 暗黑模式下的十六进制颜色
    ///   - defaultHex: 默认颜色（iOS 13 以下使用）
    ///   - alpha: 透明度
    /// - Returns: 动态颜色对象
    static func st_dynamicColor(lightHex: String, darkHex: String, defaultHex: String, alpha: CGFloat = 1.0) -> UIColor {
        if #available(iOS 13.0, *) {
            return st_dynamicColor(lightHex: lightHex, darkHex: darkHex, alpha: alpha)
        } else {
            return st_color(hexString: defaultHex, alpha: alpha)
        }
    }
    
    /// 从 Assets 中的颜色集创建颜色（支持暗黑模式）
    /// - Parameters:
    ///   - colorSet: 颜色集名称
    ///   - alpha: 透明度
    /// - Returns: UIColor 对象
    @available(iOS 11.0, *)
    static func st_color(colorSet: String, alpha: CGFloat = 1.0) -> UIColor {
        if colorSet.count > 0 {
            if let color = UIColor(named: colorSet) {
                if alpha < 1.0 {
                    return color.withAlphaComponent(alpha)
                }
                return color
            }
        }
        return UIColor.clear
    }
    
    /// 从 Assets 中的颜色集创建颜色（支持暗黑模式）
    /// - Parameter colorSet: 颜色集名称
    /// - Returns: UIColor 对象
    @available(iOS 11.0, *)
    static func st_color(colorSet: String) -> UIColor {
        return st_color(colorSet: colorSet, alpha: 1.0)
    }
    
    // MARK: - 兼容性方法（保持向后兼容）
    
    /// 兼容旧版本的暗黑模式颜色创建方法
    /// - Parameters:
    ///   - darkModeName: 颜色集名称
    ///   - hexString: 十六进制字符串（备用）
    ///   - alpha: 透明度
    /// - Returns: UIColor 对象
    static func st_color(darkModeName: String, hexString: String = "", alpha: CGFloat = 1.0) -> UIColor {
        if #available(iOS 11.0, *) {
            if darkModeName.count > 0 {
                if let color = UIColor(named: darkModeName) {
                    if alpha < 1.0 {
                        return color.withAlphaComponent(alpha)
                    }
                    return color
                }
                return UIColor.clear
            }
            return st_color(hexString: hexString, alpha: alpha)
        } else {
            return st_color(hexString: hexString, alpha: alpha)
        }
    }
    
    /// 兼容旧版本的暗黑模式颜色创建方法
    /// - Parameters:
    ///   - darkModeName: 颜色集名称
    ///   - alpha: 透明度
    /// - Returns: UIColor 对象
    static func st_color(darkModeName: String, alpha: CGFloat) -> UIColor {
        return st_color(darkModeName: darkModeName, hexString: "", alpha: alpha)
    }
    
    /// 兼容旧版本的暗黑模式颜色创建方法
    /// - Parameter darkModeName: 颜色集名称
    /// - Returns: UIColor 对象
    static func st_color(darkModeName: String) -> UIColor {
        return st_color(darkModeName: darkModeName, hexString: "", alpha: 1.0)
    }
    
    // MARK: - 颜色转换
    
    /// 将颜色转换为十六进制字符串
    /// - Returns: 十六进制字符串
    func st_colorToHex() -> String {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        let multiplier = CGFloat(255.999999)
        guard self.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            return ""
        }
        if alpha == 1.0 {
            return String(
                format: "#%02lX%02lX%02lX",
                Int(red * multiplier),
                Int(green * multiplier),
                Int(blue * multiplier)
            )
        } else {
            return String(
                format: "#%02lX%02lX%02lX%02lX",
                Int(red * multiplier),
                Int(green * multiplier),
                Int(blue * multiplier),
                Int(alpha * multiplier)
            )
        }
    }
    
    /// 获取颜色的红色分量
    /// - Returns: 红色值 (0-255)
    func st_getColorR() -> Int {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        let multiplier = CGFloat(255.0)
        guard self.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            return 0
        }
        return Int(red * multiplier) <= 255 ? Int(red * multiplier) : 255
    }
    
    /// 获取颜色的绿色分量
    /// - Returns: 绿色值 (0-255)
    func st_getColorG() -> Int {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        let multiplier = CGFloat(255.0)
        guard self.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            return 0
        }
        return Int(green * multiplier) <= 255 ? Int(green * multiplier) : 255
    }
    
    /// 获取颜色的蓝色分量
    /// - Returns: 蓝色值 (0-255)
    func st_getColorB() -> Int {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        let multiplier = CGFloat(255.0)
        guard self.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            return 0
        }
        return Int(blue * multiplier) <= 255 ? Int(blue * multiplier) : 255
    }
    
    /// 获取颜色的透明度分量
    /// - Returns: 透明度值 (0.0-1.0)
    func st_getColorA() -> CGFloat {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        guard self.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            return 0.0
        }
        return alpha
    }
    
    // MARK: - 颜色操作
    
    /// 调整颜色透明度
    /// - Parameter alpha: 新的透明度值
    /// - Returns: 调整后的颜色
    func st_withAlpha(_ alpha: CGFloat) -> UIColor {
        return self.withAlphaComponent(alpha)
    }
    
    /// 混合两个颜色
    /// - Parameters:
    ///   - color: 要混合的颜色
    ///   - ratio: 混合比例 (0.0-1.0)
    /// - Returns: 混合后的颜色
    func st_blend(with color: UIColor, ratio: CGFloat) -> UIColor {
        var red1: CGFloat = 0, green1: CGFloat = 0, blue1: CGFloat = 0, alpha1: CGFloat = 0
        var red2: CGFloat = 0, green2: CGFloat = 0, blue2: CGFloat = 0, alpha2: CGFloat = 0
        guard self.getRed(&red1, green: &green1, blue: &blue1, alpha: &alpha1),
              color.getRed(&red2, green: &green2, blue: &blue2, alpha: &alpha2) else {
            return self
        }
        let newRed = red1 * (1 - ratio) + red2 * ratio
        let newGreen = green1 * (1 - ratio) + green2 * ratio
        let newBlue = blue1 * (1 - ratio) + blue2 * ratio
        let newAlpha = alpha1 * (1 - ratio) + alpha2 * ratio
        return UIColor(red: newRed, green: newGreen, blue: newBlue, alpha: newAlpha)
    }
    
    /// 获取颜色的对比色（用于文字等）
    /// - Returns: 对比色
    func st_contrastColor() -> UIColor {
        let brightness = self.st_brightness()
        return brightness > 0.5 ? UIColor.black : UIColor.white
    }
    
    /// 获取颜色的亮度
    /// - Returns: 亮度值 (0.0-1.0)
    func st_brightness() -> CGFloat {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        guard self.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            return 0.0
        }
        return (0.299 * red + 0.587 * green + 0.114 * blue)
    }
}

// MARK: - 常用颜色预设

public extension UIColor {
    
    /// 系统主色调（支持暗黑模式）
    @available(iOS 13.0, *)
    static var st_systemPrimary: UIColor {
        return UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return UIColor.systemBlue
            } else {
                return UIColor.systemBlue
            }
        }
    }
    
    /// 系统背景色（支持暗黑模式）
    @available(iOS 13.0, *)
    static var st_systemBackground: UIColor {
        return UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return UIColor.systemBackground
            } else {
                return UIColor.systemBackground
            }
        }
    }
    
    /// 系统标签色（支持暗黑模式）
    @available(iOS 13.0, *)
    static var st_systemLabel: UIColor {
        return UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return UIColor.label
            } else {
                return UIColor.label
            }
        }
    }
    
    /// 系统次要标签色（支持暗黑模式）
    @available(iOS 13.0, *)
    static var st_systemSecondaryLabel: UIColor {
        return UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return UIColor.secondaryLabel
            } else {
                return UIColor.secondaryLabel
            }
        }
    }
    
    /// 系统分隔线色（支持暗黑模式）
    @available(iOS 13.0, *)
    static var st_systemSeparator: UIColor {
        return UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return UIColor.separator
            } else {
                return UIColor.separator
            }
        }
    }
}

// MARK: - 颜色信息模型

public struct STColorsInfo: Codable {
    public var colors: Dictionary<String, STColorModel> = Dictionary<String, STColorModel>()
}

public struct STColorModel: Codable {
    public var light: String = ""
    public var dark: String = ""
}

// MARK: - 动态颜色管理

@available(iOS 13, *)
public extension UIColor {
    
    private struct STColorAssociatedKeys {
        static var colorsInfoKey = true
    }
    
    /// 从 JSON 文件加载颜色配置
    /// - Parameter jsonString: JSON 文件路径
    static func st_resolvedColor(jsonString: String) {
        if jsonString.count > 0 {
            if let jsonObject = STJSONUtils.st_readJSONFromFile(jsonString),
               let objc = jsonObject as? Dictionary<String, Dictionary<String, String>> {
                var colorsInfo = STColorsInfo()
                for key in objc.keys {
                    var colorModel = STColorModel()
                    if let value = objc[key] {
                        colorModel.light = String.st_returnStr(object: value["light"] ?? "")
                        colorModel.dark = String.st_returnStr(object: value["dark"] ?? "")
                    }
                    colorsInfo.colors[key] = colorModel
                }
                if colorsInfo.colors.count > 0 {
                    objc_setAssociatedObject(self, &STColorAssociatedKeys.colorsInfoKey, colorsInfo, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                }
            }
        }
    }
    
    /// 从配置中获取动态颜色
    /// - Parameter key: 颜色键名
    /// - Returns: 动态颜色对象
    static func st_color(dynamicProvider key: String) -> UIColor {
        if let colorsInfo = objc_getAssociatedObject(self, &STColorAssociatedKeys.colorsInfoKey) as? STColorsInfo {
            if colorsInfo.colors.count > 0, key.count > 0 {
                if let colorModel = colorsInfo.colors[key] {
                    return UIColor { traitCollection in
                        if traitCollection.userInterfaceStyle == .light {
                            return UIColor.st_color(hexString: colorModel.light)
                        }
                        return UIColor.st_color(hexString: colorModel.dark)
                    }
                }
            }
        }
        return UIColor.clear
    }
    
    /// 清理关联对象
    static func st_cleanColorAssociatedObject() {
        if let colorsInfo = objc_getAssociatedObject(self, &STColorAssociatedKeys.colorsInfoKey) as? STColorsInfo {
            if colorsInfo.colors.count > 0 {
                objc_setAssociatedObject(self, &STColorAssociatedKeys.colorsInfoKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
        }
    }
}

// MARK: - 便捷的颜色创建方法
public extension UIColor {
    
    /// 创建随机颜色
    /// - Parameter alpha: 透明度
    /// - Returns: 随机颜色
    static func st_random(alpha: CGFloat = 1.0) -> UIColor {
        let red = CGFloat.random(in: 0...1)
        let green = CGFloat.random(in: 0...1)
        let blue = CGFloat.random(in: 0...1)
        return UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }
    
    /// 从图片获取主色调
    /// - Parameter image: 图片
    /// - Returns: 主色调
    static func st_dominantColor(from image: UIImage) -> UIColor? {
        guard let cgImage = image.cgImage else { return nil }
        let width = cgImage.width
        let height = cgImage.height
        let totalPixels = width * height
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        guard let data = context.data else { return nil }
        let buffer = data.bindMemory(to: UInt8.self, capacity: totalPixels * bytesPerPixel)
        var redSum: CGFloat = 0
        var greenSum: CGFloat = 0
        var blueSum: CGFloat = 0
        for i in stride(from: 0, to: totalPixels * bytesPerPixel, by: bytesPerPixel) {
            let red = CGFloat(buffer[i]) / 255.0
            let green = CGFloat(buffer[i + 1]) / 255.0
            let blue = CGFloat(buffer[i + 2]) / 255.0
            redSum += red
            greenSum += green
            blueSum += blue
        }
        let pixelCount = CGFloat(totalPixels)
        return UIColor(
            red: redSum / pixelCount,
            green: greenSum / pixelCount,
            blue: blueSum / pixelCount,
            alpha: 1.0
        )
    }
}
