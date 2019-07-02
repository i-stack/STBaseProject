//
//  STColor.swift
//  STBaseProject
//
//  Created by song on 2018/11/14.
//  Copyright © 2018年 song. All rights reserved.
//

import UIKit

extension UIColor {
    public static func st_color(with hexString: String) -> UIColor {
        return self.st_color(with: hexString, alpha: 1.0)
    }
    
    public static func st_color(with hexString: String, alpha: CGFloat) -> UIColor {
        var cString: String = hexString.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).uppercased()
        if cString.count < 6 {
            return UIColor.clear
        }
        
        if cString.hasPrefix("0X") {
            cString = String(cString[Range.init(NSRange.init(location: 2, length: cString.count - 2), in: cString)!])
        }
        
        if cString.hasPrefix("#") {
            cString = String(cString[Range.init(NSRange.init(location: 1, length: cString.count - 1), in: cString)!])
        }
        
        if cString.count != 6 {
            return UIColor.clear
        }
        
        let rString = String(cString[Range.init(NSRange.init(location: 0, length: 2), in: cString)!])
        let gString = String(cString[Range.init(NSRange.init(location: 2, length: 2), in: cString)!])
        let bString = String(cString[Range.init(NSRange.init(location: 4, length: 2), in: cString)!])
        var r: Int = 0
        var g: Int = 0
        var b: Int = 0
        Scanner.init(string: rString).scanInt(&r)
        Scanner.init(string: gString).scanInt(&g)
        Scanner.init(string: bString).scanInt(&b)
        return UIColor.init(red: CGFloat(r) / 255.0, green: CGFloat(g) / 255.0, blue: CGFloat(b) / 255.0, alpha: alpha)
    }
}
