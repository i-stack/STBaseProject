//
//  TRXString.swift
//  STBaseFramework
//
//  Created by Tron on 2018/11/23.
//  Copyright © 2018年 ST. All rights reserved.
//

import UIKit
import Foundation

public extension String {
    func st_jsonStringToPrettyPrintedJson(jsonString: String?) -> String {
        if let str = jsonString {
            let jsonData = str.data(using: String.Encoding.utf8)!
            let jsonObject: AnyObject = try! JSONSerialization.jsonObject(with: jsonData, options: []) as AnyObject
            let prettyJsonData = try! JSONSerialization.data(withJSONObject: jsonObject, options: JSONSerialization.WritingOptions.prettyPrinted)
            let prettyPrintedJson = NSString(data: prettyJsonData, encoding: String.Encoding.utf8.rawValue)!
            return prettyPrintedJson as String
        }
        return ""
    }
    
    func st_dictToJSON(dict: NSDictionary) -> String {
        if dict.count < 1 {
            return ""
        }
        let data: NSData! = try! JSONSerialization.data(withJSONObject: dict, options: []) as NSData
        let jsonStr: String = String.init(data: data! as Data, encoding: String.Encoding(rawValue: String.Encoding.utf8.rawValue)) ?? ""
        return jsonStr
    }
}

public extension String {
    static func st_returnStr(object: Any) -> String {
        var cnt = ""
        if let obj = object as? NSNumber {
            cnt = String.init(format: "%@", obj)
        } else if let obj = object as? String {
            if obj.contains("null") || obj.contains("nan") || obj.contains("nil") {
                cnt = ""
            } else {
                cnt = obj
            }
        }
        return cnt
    }
    
    func st_returnStrWidth(font: UIFont) -> CGFloat {
        let normalText: NSString = self as NSString
        let size = CGSize(width: 999, height: 1000)
        let attributes = [NSAttributedString.Key.font: font]
        let stringSize = normalText.boundingRect(with: size, options: .usesLineFragmentOrigin, attributes: attributes, context:nil).size
        return CGFloat(ceilf(Float(stringSize.width)))
    }
}

public extension String {
    func st_divideAmount() -> String {
        let numFormatter = NumberFormatter()
        let string = String.st_returnStr(object: self)
        numFormatter.formatterBehavior = NumberFormatter.Behavior.behavior10_4
        numFormatter.numberStyle = NumberFormatter.Style.decimal
        numFormatter.maximumFractionDigits = 6
        numFormatter.locale = Locale(identifier: "en_US")
        let numString = numFormatter.string(from: NSNumber.init(floatLiteral: Double(string) ?? 0))
        return numString ?? string
    }
    
    func st_stringToDouble(string: String) -> Double {
        let formatter = NumberFormatter()
        formatter.locale = Locale.current
        formatter.decimalSeparator = "."
        if let result = formatter.number(from: string) {
            return result.doubleValue
        } else {
            formatter.decimalSeparator = ","
            if let result = formatter.number(from: string) {
                return result.doubleValue
            }
        }
        return 0
    }
}

public extension String {
    func st_timeStampToCurrennTime(timeStamp: String) -> String {
        if timeStamp.count < 1 {
            return ""
        }
        let stamp: Double = timeStamp.doubleValue
        var timeSta: TimeInterval = TimeInterval(stamp)
        if timeStamp.count == 13 {
            timeSta = TimeInterval(timeSta / 1000)
        }
        let currentTime = Date().timeIntervalSince1970
        let reduceTime : TimeInterval = currentTime - timeSta
        if reduceTime < 60 {
            return "刚刚"
        }
        let mins = Int(reduceTime / 60)
        if mins < 60 {
            return "\(mins)分钟前"
        }
        let hours = Int(reduceTime / 3600)
        if hours < 24 {
            return "\(hours)小时前"
        }
        let days = Int(reduceTime / 3600 / 24)
        if days < 30 {
            return "\(days)天前"
        }
        let date = NSDate(timeIntervalSince1970: timeSta)
        let dfmatter = DateFormatter()
        dfmatter.dateFormat="yyyy.MM.dd HH:mm:ss"
        return dfmatter.string(from: date as Date)
    }
    
    var doubleValue: Double {
        let formatter = NumberFormatter()
        formatter.locale = Locale.current
        formatter.decimalSeparator = "."
        if let result = formatter.number(from: self) {
            return result.doubleValue
        } else {
            formatter.decimalSeparator = ","
            if let result = formatter.number(from: self) {
                return result.doubleValue
            }
        }
        return 0
    }
}
