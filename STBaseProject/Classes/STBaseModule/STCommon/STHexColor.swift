//
//  STHexColor.swift
//  STBaseFramework
//
//  Created by song on 2019/12/9.
//  Copyright © 2019 ST. All rights reserved.
//

import UIKit

public extension UIColor {
    
    static func st_color(darkModeName: String, hexString: String) -> UIColor {
        return st_color(darkModeName: darkModeName, hexString: hexString, alpha: 1.0)
    }
    
    static func st_color(darkModeName: String, hexString: String, alpha: CGFloat) -> UIColor {
        if #available(iOS 11.0, *) {
            if darkModeName.count > 0 {
                let color = UIColor.init(named: darkModeName)?.withAlphaComponent(alpha)
                return color ?? UIColor.clear
            }
            return self.st_color(hexString: hexString, alpha: alpha)
        } else {
            return self.st_color(hexString: hexString, alpha: alpha)
        }
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
}
