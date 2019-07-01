//
//  STPredicateCheck.swift
//  STBaseProject
//
//  Created by song on 2017/11/14.
//  Copyright © 2018年 song. All rights reserved.
//

import Foundation

open class STPredicateCheck: NSObject {
    
    /**
     *  正则匹配用户密码8-32位数字或字母组合
     */
    public class func st_checkPassword(password: String) -> Bool {
        if password.count < 1 {
            return false
        }
        let pattern: String = "^(?=.*[0-9])(?=.*[a-z])(?=.*[A-Z]).{8,32}$"
        let pred: NSPredicate = NSPredicate.init(format: "SELF MATCHES %@", pattern)
        let isMatch = pred.evaluate(with: password)
        return isMatch
    }
    
    /**
     *  正则匹配用户姓名, 1-32位的中文或英文或数字
     */
    public class func st_checkUserName(userName: String) -> Bool {
        if userName.count < 1 {
            return false
        }
        let pattern: String = "[\\u4e00-\\u9fa5a-zA-Z0-9]{1,32}"
        let pred: NSPredicate = NSPredicate.init(format: "SELF MATCHES %@", pattern)
        let isMatch = pred.evaluate(with: userName)
        return isMatch
    }
    
    /**
     *  正则正则匹配钱包地址, 34位的英文或数字
     */
    public class func st_checkWalletAddress(address: String) -> Bool {
        if address.count < 1 {
            return false
        }
        let pattern: String = "^([a-z]|[A-Z]|[0-9]){34}$"
        let pred: NSPredicate = NSPredicate.init(format: "SELF MATCHES %@", pattern)
        let isMatch = pred.evaluate(with: address)
        return isMatch
    }

    /**
     *  正则匹配邮箱
     */
    public class func st_checkEmail(email: String) -> Bool {
        if email.count < 1 {
            return false
        }
        let pattern: String = "^([a-zA-Z0-9]+([._\\-])*[a-zA-Z0-9]*)+@([a-zA-Z0-9])+(.([a-zA-Z])+)+$"
        let pred: NSPredicate = NSPredicate.init(format: "SELF MATCHES %@", pattern)
        let isMatch = pred.evaluate(with: email)
        return isMatch
    }

    /**
     *  正则匹配是否数字
     */
    public class func st_checkEmail(number: String) -> Bool {
        if number.count < 1 {
            return false
        }
        let pattern: String = "^[0-9]*$"
        let pred: NSPredicate = NSPredicate.init(format: "SELF MATCHES %@", pattern)
        let isMatch = pred.evaluate(with: number)
        return isMatch
    }
    
    /**
     *  正则匹配手机号码
     */
    public class func st_checkMobile(mobileNumbel: String) -> Bool {
        if mobileNumbel.count < 1 {
            return false
        }
        /**
         * 手机号码
         * 移动：134[0-8],135,136,137,138,139,150,151,157,158,159,182,187,188
         * 联通：130,131,132,152,155,156,185,186
         * 电信：133,1349,153,180,189,181(增加)
         */
        let MOBIL = "^1(3[0-9]|5[0-35-9]|8[025-9])\\d{8}$";
        /**
         * 中国移动：China Mobile
         * 134[0-8],135,136,137,138,139,150,151,157,158,159,182,187,188
         */
        let CM = "^1(34[0-8]|(3[5-9]|5[017-9]|8[2378])\\d)\\d{7}$";
        /**
         * 中国联通：China Unicom
         * 130,131,132,152,155,156,185,186
         */
        let CU = "^1(3[0-2]|5[256]|8[56])\\d{8}$";
        /**
         * 中国电信：China Telecom
         * 133,1349,153,180,189,181(增加)
         */
        let CT = "^1((33|53|8[019])[0-9]|349)\\d{7}$";
        let regextestmobile = NSPredicate(format: "SELF MATCHES %@", MOBIL)
        let regextestcm = NSPredicate(format: "SELF MATCHES %@", CM)
        let regextestcu = NSPredicate(format: "SELF MATCHES %@", CU)
        let regextestct = NSPredicate(format: "SELF MATCHES %@", CT)
        if regextestmobile.evaluate(with: mobileNumbel) ||
            regextestcm.evaluate(with: mobileNumbel) ||
            regextestcu.evaluate(with: mobileNumbel) ||
            regextestct.evaluate(with: mobileNumbel) {
            return true
        }
        return false
    }
    
    /**
     *  正则匹配用户身份证号15或18位
     */
    public class func st_checkUserIdCard(idCard: String) -> Bool {
        if idCard.count < 1 {
            return false
        }
        let pattern = "(^[0-9]{15}$)|([0-9]{17}([0-9]|X)$)";
        let pred = NSPredicate(format: "SELF MATCHES %@", pattern)
        let isMatch = pred.evaluate(with: idCard)
        return isMatch
    }
    
    /**
     *  正则匹配URL
     */
    public class func st_checkURL(url: String) -> Bool {
        if url.count < 1 {
            return false
        }
        let pattern = "^[0-9A-Za-z]{1,50}"
        let pred = NSPredicate(format: "SELF MATCHES %@", pattern)
        let isMatch = pred.evaluate(with: url)
        return isMatch
    }
}
