//
//  STHexColor.swift
//  STBaseProject
//
//  Created by stack on 2018/10/9.
//  Copyright © 2018 ST. All rights reserved.
//

import UIKit

public extension UIColor {
    
    static func st_color(colorSet: String) -> UIColor {
        return st_color(colorSet: colorSet, alpha: 1.0)
    }
    
    static func st_color(colorSet: String, alpha: CGFloat) -> UIColor {
        if #available(iOS 11.0, *) {
            if colorSet.count > 0 {
                if let color = UIColor.init(named: colorSet) {
                    if alpha < 1.0 {
                        return color.withAlphaComponent(alpha)
                    }
                    return color
                }
            }
        }
        return UIColor.clear
    }

    static func st_color(hexString: String) -> UIColor {
        return self.st_color(hexString: hexString, alpha: 1.0)
    }
    
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
        
        var rgbValue: UInt32 = 0
        Scanner(string: cString).scanHexInt32(&rgbValue)

        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(alpha)
        )
    }
    
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
}

public struct STColorsInfo: Codable {
    public var colors: Dictionary<String, STColorModel> = Dictionary<String, STColorModel>()
}

public struct STColorModel: Codable {
    public var light: String = ""
    public var dark: String = ""
}

public extension UIColor {
    
    private struct STColorAssociatedKeys {
        static var colorsInfoKey = "colorsInfoKey"
    }
    
    static func st_resolvedColor(jsonString: String) {
        if jsonString.count > 0 {
            if let data = try? Data(contentsOf: URL(fileURLWithPath: jsonString)) {
                if let objc = try? JSONSerialization.jsonObject(with: data) as? Dictionary<String, Dictionary<String, String>> {
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
    }
    
    static func st_color(dynamicProvider key: String) -> UIColor {
        if let colorsInfo = objc_getAssociatedObject(self, &STColorAssociatedKeys.colorsInfoKey) as? STColorsInfo {
            if colorsInfo.colors.count > 0, key.count > 0 {
                if let colorModel = colorsInfo.colors[key] {
                    if #available(iOS 13.0, *) {
                        return UIColor.init { trainCollection in
                            if trainCollection.userInterfaceStyle == .light {
                                return UIColor.st_color(hexString: colorModel.light)
                            }
                            return UIColor.st_color(hexString: colorModel.dark)
                        }
                    }
                }
            }
        }
        return UIColor.clear
    }
    
    static func st_cleanColorAssociatedObject() {
        if let colorsInfo = objc_getAssociatedObject(self, &STColorAssociatedKeys.colorsInfoKey) as? STColorsInfo {
            if colorsInfo.colors.count > 0 {
                objc_setAssociatedObject(self, &STColorAssociatedKeys.colorsInfoKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
        }
    }
}
