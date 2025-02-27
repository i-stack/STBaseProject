//
//  STPredicateCheck.swift
//  STBaseProject
//
//  Created by stack on 2018/06/12.
//

import UIKit

public class STPredicateCheck: NSObject {
    
    /// Check if the user's password contains uppercase letters
    ///
    /// - Parameter password: Input string
    ///
    /// - Returns: Return the matching result
    ///
    public class func st_checkCapitalPassword(password: String) -> Bool {
        let pattern = ".*[A-Z].*$"
        let pred = NSPredicate.init(format: "SELF MATCHES %@", pattern)
        let isMatch = pred.evaluate(with: password)
        return isMatch
    }
    
    /// Check if the user's password contains lowercase letters
    ///
    /// - Parameter password: Input string
    ///
    /// - Returns: Return the matching result
    ///
    public class func st_checkLowercasePassword(password: String) -> Bool {
        let pattern = ".*[a-z].*$"
        let pred = NSPredicate.init(format: "SELF MATCHES %@", pattern)
        let isMatch = pred.evaluate(with: password)
        return isMatch
    }

    /// Check if the user's password contains numbers
    ///
    /// - Parameter password: Input string
    ///
    /// - Returns: Return the matching result
    ///
    public class func st_checkNumberPassword(password: String) -> Bool {
        let pattern = ".*[0-9].*$"
        let pred = NSPredicate.init(format: "SELF MATCHES %@", pattern)
        let isMatch = pred.evaluate(with: password)
        return isMatch
    }
    
    /// Match user password: 8-32 characters combination of numbers + uppercase letters + lowercase letters
    ///
    /// - Parameter password: Input string
    ///
    /// - Returns: Return match result
    ///
    public class func st_checkPassword(password: String) -> Bool {
        let pattern = "^(?=.*[0-9])(?=.*[a-z])(?=.*[A-Z]).{8,32}$"
        let pred = NSPredicate.init(format: "SELF MATCHES %@", pattern)
        let isMatch = pred.evaluate(with: password)
        return isMatch
    }

    /// Match user name: 1-32 characters of Chinese, English, or numbers
    ///
    /// - Parameter userName: Input user name
    ///
    /// - Returns: Return match result
    ///
    public class func st_checkUserName(userName: String) -> Bool {
        return STPredicateCheck.st_checkUserName(userName: userName, hasSpace: false)
    }
    
    /// Match user name: 1-32 characters of Chinese, English, numbers, or spaces
    ///
    /// - Parameter userName: Input username
    /// - Parameter hasSpace: Whether it contains spaces
    ///
    /// - Returns: Returns the match result
    ///
    public class func st_checkUserName(userName: String, hasSpace: Bool) -> Bool {
        var pattern = "[\u{4e00}-\u{9fa5}a-zA-Z0-9]{1,32}"
        if hasSpace {
            pattern = "[\u{4e00}-\u{9fa5}a-zA-Z0-9\\s]{1,32}"
        }
        let pred = NSPredicate.init(format: "SELF MATCHES %@", pattern)
        let isMatch = pred.evaluate(with: userName)
        return isMatch
    }

    /// Match Email
    ///
    /// - Parameter email: Input email
    ///
    /// - Returns: Return match result
    ///
    public class func st_checkEmail(email: String) -> Bool {
        let pattern = "^([a-zA-Z0-9]+([._\\-])*[a-zA-Z0-9]*)+@([a-zA-Z0-9])+(.([a-zA-Z])+)+$"
        let pred = NSPredicate.init(format: "SELF MATCHES %@", pattern)
        let isMatch = pred.evaluate(with: email)
        return isMatch
    }
    
    /// Match phone number
    ///
    /// - Parameter phoneNum: Input phone number
    ///
    /// - Returns: Return match result
    ///
    public class func st_checkPhoneNum(phoneNum: String) -> Bool {
        let pattern = "^1(3[0-9]|4[56789]|5[0-9]|6[6]|7[0-9]|8[0-9]|9[189])\\d{8}$"
        let pred = NSPredicate.init(format: "SELF MATCHES %@", pattern)
        let isMatch = pred.evaluate(with: phoneNum)
        return isMatch
    }
    
    /// Matches are numbers
    ///
    /// - Parameter text: Input string
    ///
    /// - Returns: Returns the match result
    ///
    public class func st_checkIsDigit(text: String) -> Bool {
        let pattern = "^[0-9]*$"
        let pred = NSPredicate.init(format: "SELF MATCHES %@", pattern)
        let isMatch = pred.evaluate(with: text)
        return isMatch
    }
    
    /// Match integers
    ///
    /// - Parameter text: Input string
    ///
    /// - Returns: Return match results
    ///
    public class func st_checkIsInteger(text: String) -> Bool {
        let pattern = "^-?[1-9]\\d*|0$"
        let pred = NSPredicate.init(format: "SELF MATCHES %@", pattern)
        let isMatch = pred.evaluate(with: text)
        return isMatch
    }
    
    /// Match float
    ///
    /// - Parameter text: Input string
    ///
    /// - Returns: Return match results
    ///
    public class func st_checkIsFloat(text: String) -> Bool {
        let pattern = "^-?([1-9]\\d*\\.\\d*|0\\.\\d*[1-9]\\d*|0?\\.0+|0)$"
        let pred = NSPredicate.init(format: "SELF MATCHES %@", pattern)
        let isMatch = pred.evaluate(with: text)
        return isMatch
    }
    
    /// Chinese-English Punctuation
    ///
    /// - Parameter text: Input string
    ///
    /// - Returns: Returns the matching result
    ///
    public class func st_checkPunctuation(text: String) -> Bool {
        let pattern = "^[\\p{P}]*$"
        let pred = NSPredicate.init(format: "SELF MATCHES %@", pattern)
        let isMatch = pred.evaluate(with: text)
        return isMatch
    }
    
    /// All Chinese characters in utf-8 encoding
    ///
    /// - Parameter text: Input string
    ///
    ///- Returns: Return matching result
    ///
    public class func st_checkChinaChar(text: String) -> Bool {
        let pattern = "^[\\p{Han}]*$"
        let pred = NSPredicate.init(format: "SELF MATCHES %@", pattern)
        let isMatch = pred.evaluate(with: text)
        return isMatch
    }
    
    /// Chinese, numbers, letters, punctuation
    ///
    /// - Parameter text: Input string
    ///
    /// - Returns: Returns the matching result
    ///
    public class func st_normalWithPunctuation(text: String) -> Bool {
        let pattern = "^([\\p{Han}\\p{P}A-Za-z0-9])*$"
        let pred = NSPredicate.init(format: "SELF MATCHES %@", pattern)
        let isMatch = pred.evaluate(with: text)
        return isMatch
    }
}
