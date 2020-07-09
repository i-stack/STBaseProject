//
//  STPredicateCheck.swift
//  STBaseProject
//
//  Created by stack on 2018/08/12.
//  Copyright © 2018 ST. All rights reserved.
//

import UIKit

public class STPredicateCheck: NSObject {
    /// pragma - 正则匹配用户密码是否包含大写字母
    public class func st_checkCapitalPassword(password: String) -> Bool {
        let pattern = ".*[A-Z].*$"
        let pred = NSPredicate.init(format: "SELF MATCHES %@", pattern)
        let isMatch = pred.evaluate(with: password)
        return isMatch
    }
    
    /// pragma - 正则匹配用户密码是否包含小写字母
    public class func st_checkLowercasePassword(password: String) -> Bool {
        let pattern = ".*[a-z].*$"
        let pred = NSPredicate.init(format: "SELF MATCHES %@", pattern)
        let isMatch = pred.evaluate(with: password)
        return isMatch
    }

    /// pragma - 正则匹配用户密码是否包含数字
    public class func st_checkNumberPassword(password: String) -> Bool {
        let pattern = ".*[0-9].*$"
        let pred = NSPredicate.init(format: "SELF MATCHES %@", pattern)
        let isMatch = pred.evaluate(with: password)
        return isMatch
    }
    
    /// pragma - 正则匹配用户密码：8-32位数字+大写字母+小写字母组合
    public class func st_checkPassword(password: String) -> Bool {
        let pattern = "^(?=.*[0-9])(?=.*[a-z])(?=.*[A-Z]).{8,32}$"
        let pred = NSPredicate.init(format: "SELF MATCHES %@", pattern)
        let isMatch = pred.evaluate(with: password)
        return isMatch
    }

    /// pragma - 正则匹配用户姓名： 1-32位的中文或英文或数字
    public class func st_checkUserName(userName: String) -> Bool {
        return STPredicateCheck.st_checkUserName(userName: userName, hasSpace: false)
    }
    
    /// pragma - 正则匹配用户姓名： 1-32位的中文或英文或数字或空格
    public class func st_checkUserName(userName: String, hasSpace: Bool) -> Bool {
        var pattern = "[\u{4e00}-\u{9fa5}a-zA-Z0-9]{1,32}"
        if hasSpace {
            pattern = "[\u{4e00}-\u{9fa5}a-zA-Z0-9\\s]{1,32}"
        }
        let pred = NSPredicate.init(format: "SELF MATCHES %@", pattern)
        let isMatch = pred.evaluate(with: userName)
        return isMatch
    }

    /// pragma - 匹配邮箱
    public class func st_checkEmail(email: String) -> Bool {
        let pattern = "^([a-zA-Z0-9]+([._\\-])*[a-zA-Z0-9]*)+@([a-zA-Z0-9])+(.([a-zA-Z])+)+$"
        let pred = NSPredicate.init(format: "SELF MATCHES %@", pattern)
        let isMatch = pred.evaluate(with: email)
        return isMatch
    }
    
    /// pragma - 匹配手机号
    public class func st_checkPhoneNum(phoneNum: String) -> Bool {
        let pattern = "^1(3[0-9]|4[56789]|5[0-9]|6[6]|7[0-9]|8[0-9]|9[189])\\d{8}$"
        let pred = NSPredicate.init(format: "SELF MATCHES %@", pattern)
        let isMatch = pred.evaluate(with: phoneNum)
        return isMatch
    }
    
    /// pragma - 匹配是数字
    public class func st_checkIsDigit(text: String) -> Bool {
        let pattern = "^[0-9]*$"
        let pred = NSPredicate.init(format: "SELF MATCHES %@", pattern)
        let isMatch = pred.evaluate(with: text)
        return isMatch
    }
    
    /// pragma - 中英文标点
    public class func st_checkPunctuation(text: String) -> Bool {
        let pattern = "^[\\p{P}]*$"
        let pred = NSPredicate.init(format: "SELF MATCHES %@", pattern)
        let isMatch = pred.evaluate(with: text)
        return isMatch
    }
    
    /// pragma - utf-8编码中的所有中文字符
    public class func st_checkChinaChar(text: String) -> Bool {
        let pattern = "^[\\p{Han}]*$"
        let pred = NSPredicate.init(format: "SELF MATCHES %@", pattern)
        let isMatch = pred.evaluate(with: text)
        return isMatch
    }
    
    /// pragma - 中文、数字、字母、标点符号
    public class func st_normalWithPunctuation(text: String) -> Bool {
        let pattern = "^([\\p{Han}\\p{P}A-Za-z0-9])*$"
        let pred = NSPredicate.init(format: "SELF MATCHES %@", pattern)
        let isMatch = pred.evaluate(with: text)
        return isMatch
    }
}
