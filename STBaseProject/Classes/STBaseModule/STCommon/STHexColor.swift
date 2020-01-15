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
        if #available(iOS 11.0, *) {
            return UIColor.init(named: darkModeName) ?? UIColor.clear
        } else {
            return self.st_color(hexString: hexString, alpha: 1.0)
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
//        let rStart = cString.index(cString.startIndex, offsetBy: 2)
//        let rString = String(cString[..<rStart])
//
//        let gStart = cString.index(cString.startIndex, offsetBy: 4)
//        let gString = String(cString[rStart..<gStart])
//
//        let bStart = cString.index(gString.startIndex, offsetBy: 6)
//        let bString = String(cString[gStart..<bStart])
//
//        var r: UInt32 = 0
//        var g: UInt32 = 0
//        var b: UInt32 = 0
//        Scanner.init(string: rString).scanHexInt32(&r)
//        Scanner.init(string: gString).scanHexInt32(&g)
//        Scanner.init(string: bString).scanHexInt32(&b)
//
//        return UIColor.init(red: CGFloat(r) / 255.0, green: CGFloat(g) / 255.0, blue: CGFloat(b) / 255.0, alpha: alpha)
    }
}
