//
//  STString.swift
//  STBaseProject
//
//  Created by song on 2018/11/14.
//  Copyright © 2018年 song. All rights reserved.
//

import UIKit
import CommonCrypto

public struct STDateFormatter {
    var timeZone = NSTimeZone.local
    var local: Locale = Locale.current
    var formatter: String = "yyyy-MM-dd HH:mm"
}

//MARK:- String Security
extension String {
    /** MD5 Security */
    public func st_md5() -> String {
        if self.count < 1 {
            return ""
        }
        let str = self.cString(using: String.Encoding.utf8)
        let strLen = CC_LONG(self.lengthOfBytes(using: String.Encoding.utf8))
        let digestLen = Int(CC_MD5_DIGEST_LENGTH)
        let result = UnsafeMutablePointer<CUnsignedChar>.allocate(capacity: digestLen)
        
        CC_MD5(str!, strLen, result)
        
        let hash = NSMutableString()
        for i in 0 ..< digestLen {
            hash.appendFormat("%02x", result[i])
        }
        result.deinitialize(count: digestLen)
        return String(format: hash as String)
    }
    
//    /** AES Security */
//    public func st_AES256Encrypt(with encryptStr: String) -> String {
//        if self.count < 1 {
//            return ""
//        }
//        if encryptStr.count < 1 {
//            return self
//        }
//        let data1: Data = encryptStr.data(using: String.Encoding.utf8)
//        let data2: Data = data1
//    }
//
//    NSData *dt1 = [str dataUsingEncoding:NSUTF8StringEncoding];
//    NSData *dt2 = [dt1 TRX_AES256EncryptWithKey:self];
//    NSString *str2 = [dt2 base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
//    return str2;
//    }
//
//    #pragma mark - AES解密
//    - (NSString *)TRX_AES256DecryptWithString:(NSString *)str
//    {
//    if (!str.length) {
//    return @"";
//    }
//    NSData *dt3 = [[NSData alloc] initWithBase64EncodedString:str options:NSDataBase64DecodingIgnoreUnknownCharacters];
//    NSData *dt4 = [dt3 TRX_AES256DecryptWithKey:self];
//    NSString *str4 = [[NSString alloc] initWithData:dt4 encoding:NSUTF8StringEncoding];
//    return str4;
//    }
//
//    #pragma mark - SHA256
//    - (NSString *)SHA256
//    {
//    const char *s = [self cStringUsingEncoding:NSASCIIStringEncoding];
//    NSData *keyData = [NSData dataWithBytes:s length:strlen(s)];
//
//    uint8_t digest[CC_SHA256_DIGEST_LENGTH] = {0};
//    CC_SHA256(keyData.bytes, (CC_LONG)keyData.length, digest);
//    NSData *out = [NSData dataWithBytes:digest length:CC_SHA256_DIGEST_LENGTH];
//    NSString *hash = [out description];
//    hash = [hash stringByReplacingOccurrencesOfString:@" " withString:@""];
//    hash = [hash stringByReplacingOccurrencesOfString:@"<" withString:@""];
//    hash = [hash stringByReplacingOccurrencesOfString:@">" withString:@""];
//    return hash;
//    }
}

//MARK:- NSMutableAttributedString
extension String {
    public static func st_customAttributedUnderlineStyle(string: String, fontSize: CGFloat, textColor: UIColor) -> NSMutableAttributedString {
        if string.count < 1 {
            return NSMutableAttributedString.init(string: "")
        }
        let title: NSMutableAttributedString = NSMutableAttributedString.init(string: string)
        let titleRange: NSRange = NSRange.init(location: 0, length: title.length)
        title.addAttribute(NSAttributedString.Key.underlineStyle, value: NSNumber.init(value: NSUnderlineStyle.single.rawValue), range: titleRange)
        title.addAttribute(NSAttributedString.Key.foregroundColor, value: textColor, range: titleRange)
        return title
    }
}

//MARK:- Date/String conversion
extension String {
    public static func st_currentDate(dateFormatter: STDateFormatter) -> String {
        let dateFormatter: DateFormatter = self.st_detail(formatter: dateFormatter)
        let time: String = dateFormatter.string(from: Date.init())
        return time
    }
    
    /** 获取当前时间戳 13位 */
    public static func st_currentDateToStr() -> String {
        let date: Date = Date.init(timeIntervalSinceReferenceDate: 0)
        let time: TimeInterval = date.timeIntervalSince1970 * 1000
        let timeStr = String.init(format: "%.0f", time)
        return timeStr
    }
    
    /** 时间戳转化日期 yyyy-MM-dd a HH:mm */
    public static func st_timestampToStr(timestamp: String, dateFormatter: STDateFormatter) -> String {
        if timestamp.count < 1 || timestamp == "0" {
            return ""
        }
        let second: Double = self.st_detail(timestamp: timestamp)
        let date: Date = Date.init(timeIntervalSince1970: second)
        let dateFormatter: DateFormatter = self.st_detail(formatter: dateFormatter)
        let timeStr = dateFormatter.string(from: date)
        return timeStr
    }
    
    public static func st_timestampToDay(timestamp: String) -> String {
        if timestamp.count < 1 || timestamp == "0" {
            return ""
        }
        var second: Double = self.st_detail(timestamp: timestamp)
        if timestamp.count == 13 {
            second /= 1000.0
        }
        let day: NSInteger = NSInteger(second / 3600 / 24)
        return String.init(format: "%ld", day)
    }
    
    public static func st_timestampAfterThreeDay(timestamp: String) -> String {
        if timestamp.count < 1 || timestamp == "0" {
            return ""
        }
        var second: Double = self.st_detail(timestamp: timestamp)
        if timestamp.count == 13 {
            second /= 1000.0
        }
        second += 3 * 24 * 60 * 60
        if timestamp.count == 13 {
            second *= 1000
        }
        return String.init(format: "%ld", second)
    }
    
    public static func st_compare(startDateStr: String, endDateStr: String) -> Int {
        var comparisonResult: Int = 0
        let dateFormatter: DateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        var startDate: Date = Date.init()
        if startDateStr.st_doubleValue() > 0 {
            let second: Double = self.st_detail(timestamp: startDateStr)
            startDate = Date.init(timeIntervalSince1970: second)
        }
        var endDate: Date = dateFormatter.date(from: endDateStr) ?? Date.init()
        if endDateStr.st_doubleValue() > 0 {
            let second: Double = self.st_detail(timestamp: endDateStr)
            endDate = Date.init(timeIntervalSince1970: second)
        }
        let result: ComparisonResult = startDate.compare(endDate)
        switch result {
        case .orderedAscending:  // endDate比startDate大
            comparisonResult = 1
            break
        case .orderedDescending: // endDate比startDate小
            comparisonResult = -1
            break
        case .orderedSame:       // endDate=startDate
            comparisonResult = 0
        default:
            break
        }
        return comparisonResult
    }

    public static func st_detail(timestamp: String) -> Double {
        var second: Double = timestamp.st_doubleValue()
        if timestamp.count == 13 {
            second /= 1000.0
        }
        return second
    }
    
    public static func st_detail(formatter: STDateFormatter) -> DateFormatter {
        let dateFormatter: DateFormatter = DateFormatter()
        dateFormatter.locale = formatter.local as Locale?
        dateFormatter.timeZone = formatter.timeZone
        dateFormatter.dateFormat = formatter.formatter
        return dateFormatter
    }
}

//MARK:- string conversion to base date type
extension String {
    public func st_doubleValue() -> Double {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US")
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
