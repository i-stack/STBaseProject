//
//  STPredicateCheck.swift
//  STBaseProject
//
//  Created by stack on 2018/10/12.
//  Copyright © 2019 ST. All rights reserved.
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
        let pattern = "[\u{4e00}-\u{9fa5}a-zA-Z0-9]{1,32}"
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
        let pattern = "1[0-9]{10}"
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
}
