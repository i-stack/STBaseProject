//
//  STPredicateCheck.swift
//  STBaseProject
//
//  Created by stack on 2018/06/12.
//

import Foundation

/// 常用正则表达式模式
public struct STRegexPattern {
        
    /// 邮箱验证
    public static let email = "^([a-zA-Z0-9]+([._\\-])*[a-zA-Z0-9]*)+@([a-zA-Z0-9])+(.([a-zA-Z])+)+$"
    
    /// 手机号码验证（中国大陆）
    public static let phoneNumber = "^1(3[0-9]|4[56789]|5[0-9]|6[6]|7[0-9]|8[0-9]|9[189])\\d{8}$"
    
    /// 身份证号码验证（中国大陆）
    public static let idCard = "^[1-9]\\d{5}(18|19|20)\\d{2}((0[1-9])|(1[0-2]))(([0-2][1-9])|10|20|30|31)\\d{3}[0-9Xx]$"
    
    /// 邮政编码验证（中国大陆）
    public static let postalCode = "^[1-9]\\d{5}$"
    
    /// 银行卡号验证
    public static let bankCard = "^\\d{16,19}$"
    
    /// 信用卡号验证
    public static let creditCard = "^\\d{13,19}$"
    
    // MARK: - 密码验证模式
    
    /// 强密码验证（8-32位，包含大小写字母、数字、特殊字符）
    public static let strongPassword = "^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d)(?=.*[@$!%*?&])[A-Za-z\\d@$!%*?&]{8,32}$"
    
    /// 中等密码验证（8-32位，包含大小写字母、数字）
    public static let mediumPassword = "^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d)[A-Za-z\\d]{8,32}$"
    
    /// 弱密码验证（6-32位，包含字母和数字）
    public static let weakPassword = "^(?=.*[A-Za-z])(?=.*\\d)[A-Za-z\\d]{6,32}$"
    
    // MARK: - 数字验证模式
    
    /// 纯数字
    public static let digits = "^[0-9]*$"
    
    /// 整数（包括负数）
    public static let integer = "^-?[1-9]\\d*|0$"
    
    /// 正整数
    public static let positiveInteger = "^[1-9]\\d*$"
    
    /// 非负整数
    public static let nonNegativeInteger = "^[1-9]\\d*|0$"
    
    /// 浮点数
    public static let float = "^-?([1-9]\\d*\\.\\d*|0\\.\\d*[1-9]\\d*|0?\\.0+|0)$"
    
    /// 正浮点数
    public static let positiveFloat = "^([1-9]\\d*\\.\\d*|0\\.\\d*[1-9]\\d*)$"
    
    // MARK: - 字符验证模式
    
    /// 中文字符
    public static let chineseCharacters = "^[\\p{Han}]*$"
    
    /// 英文字母
    public static let englishLetters = "^[A-Za-z]*$"
    
    /// 大写字母
    public static let uppercaseLetters = "^[A-Z]*$"
    
    /// 小写字母
    public static let lowercaseLetters = "^[a-z]*$"
    
    /// 字母和数字
    public static let alphanumeric = "^[A-Za-z0-9]*$"
    
    /// 标点符号
    public static let punctuation = "^[\\p{P}]*$"
    
    // MARK: - 网络相关模式
    
    /// URL 验证
    public static let url = "^(https?:\\/\\/)?([\\da-z\\.-]+)\\.([a-z\\.]{2,6})([\\/\\w \\.-]*)*\\/?$"
    
    /// IPv4 地址验证
    public static let ipv4 = "^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$"
    
    /// IPv6 地址验证
    public static let ipv6 = "^([0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}$"
    
    // MARK: - 时间相关模式
    
    /// 日期格式（YYYY-MM-DD）
    public static let date = "^\\d{4}-(0[1-9]|1[0-2])-(0[1-9]|[12]\\d|3[01])$"
    
    /// 时间格式（HH:MM:SS）
    public static let time = "^([01]\\d|2[0-3]):([0-5]\\d):([0-5]\\d)$"
    
    /// 日期时间格式（YYYY-MM-DD HH:MM:SS）
    public static let dateTime = "^\\d{4}-(0[1-9]|1[0-2])-(0[1-9]|[12]\\d|3[01])\\s([01]\\d|2[0-3]):([0-5]\\d):([0-5]\\d)$"
}

// MARK: - 谓词检查类

/// 谓词检查类，提供各种字符串验证功能
public class STPredicateCheck: NSObject {
        
    /// 使用正则表达式验证字符串
    /// - Parameters:
    ///   - text: 要验证的文本
    ///   - pattern: 正则表达式模式
    /// - Returns: 验证结果
    private class func st_validate(_ text: String, with pattern: String) -> Bool {
        guard !text.isEmpty else { return false }
        let predicate = NSPredicate(format: "SELF MATCHES %@", pattern)
        return predicate.evaluate(with: text)
    }
    
    // MARK: - 密码验证
    
    /// 检查密码是否包含大写字母
    /// - Parameter password: 输入字符串
    /// - Returns: 匹配结果
    public class func st_checkCapitalPassword(password: String) -> Bool {
        return st_validate(password, with: STRegexPattern.uppercaseLetters)
    }
    
    /// 检查密码是否包含小写字母
    /// - Parameter password: 输入字符串
    /// - Returns: 匹配结果
    public class func st_checkLowercasePassword(password: String) -> Bool {
        return st_validate(password, with: STRegexPattern.lowercaseLetters)
    }
    
    /// 检查密码是否包含数字
    /// - Parameter password: 输入字符串
    /// - Returns: 匹配结果
    public class func st_checkNumberPassword(password: String) -> Bool {
        return st_validate(password, with: STRegexPattern.digits)
    }
    
    /// 检查密码是否包含特殊字符
    /// - Parameter password: 输入字符串
    /// - Returns: 匹配结果
    public class func st_checkSpecialCharPassword(password: String) -> Bool {
        let pattern = ".*[@$!%*?&].*"
        return st_validate(password, with: pattern)
    }
    
    /// 验证强密码（8-32位，包含大小写字母、数字、特殊字符）
    /// - Parameter password: 输入字符串
    /// - Returns: 匹配结果
    public class func st_checkStrongPassword(password: String) -> Bool {
        return st_validate(password, with: STRegexPattern.strongPassword)
    }
    
    /// 验证中等密码（8-32位，包含大小写字母、数字）
    /// - Parameter password: 输入字符串
    /// - Returns: 匹配结果
    public class func st_checkMediumPassword(password: String) -> Bool {
        return st_validate(password, with: STRegexPattern.mediumPassword)
    }
    
    /// 验证弱密码（6-32位，包含字母和数字）
    /// - Parameter password: 输入字符串
    /// - Returns: 匹配结果
    public class func st_checkWeakPassword(password: String) -> Bool {
        return st_validate(password, with: STRegexPattern.weakPassword)
    }
    
    /// 验证密码（8-32位，包含大小写字母、数字）
    /// - Parameter password: 输入字符串
    /// - Returns: 匹配结果
    public class func st_checkPassword(password: String) -> Bool {
        return st_checkMediumPassword(password: password)
    }
    
    // MARK: - 用户名验证
    
    /// 验证用户名（1-32位中英文数字）
    /// - Parameter userName: 输入用户名
    /// - Returns: 匹配结果
    public class func st_checkUserName(userName: String) -> Bool {
        return st_checkUserName(userName: userName, hasSpace: false)
    }
    
    /// 验证用户名（1-32位中英文数字，可选空格）
    /// - Parameters:
    ///   - userName: 输入用户名
    ///   - hasSpace: 是否包含空格
    /// - Returns: 匹配结果
    public class func st_checkUserName(userName: String, hasSpace: Bool) -> Bool {
        var pattern = "[\\u{4e00}-\\u{9fa5}a-zA-Z0-9]{1,32}"
        if hasSpace {
            pattern = "[\\u{4e00}-\\u{9fa5}a-zA-Z0-9\\s]{1,32}"
        }
        return st_validate(userName, with: pattern)
    }
    
    // MARK: - 联系方式验证
    
    /// 验证邮箱
    /// - Parameter email: 输入邮箱
    /// - Returns: 匹配结果
    public class func st_checkEmail(email: String) -> Bool {
        return st_validate(email, with: STRegexPattern.email)
    }
    
    /// 验证手机号码（中国大陆）
    /// - Parameter phoneNum: 输入手机号
    /// - Returns: 匹配结果
    public class func st_checkPhoneNum(phoneNum: String) -> Bool {
        return st_validate(phoneNum, with: STRegexPattern.phoneNumber)
    }
    
    /// 验证身份证号码（中国大陆）
    /// - Parameter idCard: 输入身份证号
    /// - Returns: 匹配结果
    public class func st_checkIdCard(idCard: String) -> Bool {
        return st_validate(idCard, with: STRegexPattern.idCard)
    }
    
    /// 验证邮政编码（中国大陆）
    /// - Parameter postalCode: 输入邮政编码
    /// - Returns: 匹配结果
    public class func st_checkPostalCode(postalCode: String) -> Bool {
        return st_validate(postalCode, with: STRegexPattern.postalCode)
    }
    
    /// 验证银行卡号
    /// - Parameter bankCard: 输入银行卡号
    /// - Returns: 匹配结果
    public class func st_checkBankCard(bankCard: String) -> Bool {
        return st_validate(bankCard, with: STRegexPattern.bankCard)
    }
    
    /// 验证信用卡号
    /// - Parameter creditCard: 输入信用卡号
    /// - Returns: 匹配结果
    public class func st_checkCreditCard(creditCard: String) -> Bool {
        return st_validate(creditCard, with: STRegexPattern.creditCard)
    }
    
    // MARK: - 数字验证
    
    /// 验证是否为纯数字
    /// - Parameter text: 输入字符串
    /// - Returns: 匹配结果
    public class func st_checkIsDigit(text: String) -> Bool {
        return st_validate(text, with: STRegexPattern.digits)
    }
    
    /// 验证是否为整数
    /// - Parameter text: 输入字符串
    /// - Returns: 匹配结果
    public class func st_checkIsInteger(text: String) -> Bool {
        return st_validate(text, with: STRegexPattern.integer)
    }
    
    /// 验证是否为正整数
    /// - Parameter text: 输入字符串
    /// - Returns: 匹配结果
    public class func st_checkIsPositiveInteger(text: String) -> Bool {
        return st_validate(text, with: STRegexPattern.positiveInteger)
    }
    
    /// 验证是否为非负整数
    /// - Parameter text: 输入字符串
    /// - Returns: 匹配结果
    public class func st_checkIsNonNegativeInteger(text: String) -> Bool {
        return st_validate(text, with: STRegexPattern.nonNegativeInteger)
    }
    
    /// 验证是否为浮点数
    /// - Parameter text: 输入字符串
    /// - Returns: 匹配结果
    public class func st_checkIsFloat(text: String) -> Bool {
        return st_validate(text, with: STRegexPattern.float)
    }
    
    /// 验证是否为正浮点数
    /// - Parameter text: 输入字符串
    /// - Returns: 匹配结果
    public class func st_checkIsPositiveFloat(text: String) -> Bool {
        return st_validate(text, with: STRegexPattern.positiveFloat)
    }
    
    // MARK: - 字符验证
    
    /// 验证是否为中文字符
    /// - Parameter text: 输入字符串
    /// - Returns: 匹配结果
    public class func st_checkChinaChar(text: String) -> Bool {
        return st_validate(text, with: STRegexPattern.chineseCharacters)
    }
    
    /// 验证是否为英文字母
    /// - Parameter text: 输入字符串
    /// - Returns: 匹配结果
    public class func st_checkEnglishLetters(text: String) -> Bool {
        return st_validate(text, with: STRegexPattern.englishLetters)
    }
    
    /// 验证是否为大写字母
    /// - Parameter text: 输入字符串
    /// - Returns: 匹配结果
    public class func st_checkUppercaseLetters(text: String) -> Bool {
        return st_validate(text, with: STRegexPattern.uppercaseLetters)
    }
    
    /// 验证是否为小写字母
    /// - Parameter text: 输入字符串
    /// - Returns: 匹配结果
    public class func st_checkLowercaseLetters(text: String) -> Bool {
        return st_validate(text, with: STRegexPattern.lowercaseLetters)
    }
    
    /// 验证是否为字母和数字组合
    /// - Parameter text: 输入字符串
    /// - Returns: 匹配结果
    public class func st_checkAlphanumeric(text: String) -> Bool {
        return st_validate(text, with: STRegexPattern.alphanumeric)
    }
    
    /// 验证是否为标点符号
    /// - Parameter text: 输入字符串
    /// - Returns: 匹配结果
    public class func st_checkPunctuation(text: String) -> Bool {
        return st_validate(text, with: STRegexPattern.punctuation)
    }
    
    /// 验证中英文数字标点符号
    /// - Parameter text: 输入字符串
    /// - Returns: 匹配结果
    public class func st_normalWithPunctuation(text: String) -> Bool {
        let pattern = "^([\\p{Han}\\p{P}A-Za-z0-9])*$"
        return st_validate(text, with: pattern)
    }
    
    // MARK: - 网络相关验证
    
    /// 验证 URL
    /// - Parameter url: 输入 URL
    /// - Returns: 匹配结果
    public class func st_checkURL(url: String) -> Bool {
        return st_validate(url, with: STRegexPattern.url)
    }
    
    /// 验证 IPv4 地址
    /// - Parameter ip: 输入 IP 地址
    /// - Returns: 匹配结果
    public class func st_checkIPv4(ip: String) -> Bool {
        return st_validate(ip, with: STRegexPattern.ipv4)
    }
    
    /// 验证 IPv6 地址
    /// - Parameter ip: 输入 IP 地址
    /// - Returns: 匹配结果
    public class func st_checkIPv6(ip: String) -> Bool {
        return st_validate(ip, with: STRegexPattern.ipv6)
    }
    
    // MARK: - 时间相关验证
    
    /// 验证日期格式（YYYY-MM-DD）
    /// - Parameter date: 输入日期
    /// - Returns: 匹配结果
    public class func st_checkDate(date: String) -> Bool {
        return st_validate(date, with: STRegexPattern.date)
    }
    
    /// 验证时间格式（HH:MM:SS）
    /// - Parameter time: 输入时间
    /// - Returns: 匹配结果
    public class func st_checkTime(time: String) -> Bool {
        return st_validate(time, with: STRegexPattern.time)
    }
    
    /// 验证日期时间格式（YYYY-MM-DD HH:MM:SS）
    /// - Parameter dateTime: 输入日期时间
    /// - Returns: 匹配结果
    public class func st_checkDateTime(dateTime: String) -> Bool {
        return st_validate(dateTime, with: STRegexPattern.dateTime)
    }
    
    // MARK: - 长度验证
    
    /// 验证字符串长度范围
    /// - Parameters:
    ///   - text: 输入字符串
    ///   - minLength: 最小长度
    ///   - maxLength: 最大长度
    /// - Returns: 验证结果
    public class func st_checkLength(text: String, minLength: Int, maxLength: Int) -> Bool {
        guard minLength <= maxLength else { return false }
        let length = text.count
        return length >= minLength && length <= maxLength
    }
    
    /// 验证字符串最小长度
    /// - Parameters:
    ///   - text: 输入字符串
    ///   - minLength: 最小长度
    /// - Returns: 验证结果
    public class func st_checkMinLength(text: String, minLength: Int) -> Bool {
        return text.count >= minLength
    }
    
    /// 验证字符串最大长度
    /// - Parameters:
    ///   - text: 输入字符串
    ///   - maxLength: 最大长度
    /// - Returns: 验证结果
    public class func st_checkMaxLength(text: String, maxLength: Int) -> Bool {
        return text.count <= maxLength
    }
    
    // MARK: - 组合验证
    
    /// 验证密码强度
    /// - Parameter password: 输入密码
    /// - Returns: 密码强度等级（0-4）
    public class func st_checkPasswordStrength(password: String) -> Int {
        var strength = 0
        
        if st_checkMinLength(text: password, minLength: 8) { strength += 1 }
        if st_checkLowercaseLetters(text: password) { strength += 1 }
        if st_checkUppercaseLetters(text: password) { strength += 1 }
        if st_checkIsDigit(text: password) { strength += 1 }
        if st_checkSpecialCharPassword(password: password) { strength += 1 }
        
        return strength
    }
    
    /// 获取密码强度描述
    /// - Parameter password: 输入密码
    /// - Returns: 密码强度描述
    public class func st_getPasswordStrengthDescription(password: String) -> String {
        let strength = st_checkPasswordStrength(password: password)
        
        switch strength {
        case 0, 1:
            return "很弱"
        case 2:
            return "弱"
        case 3:
            return "中等"
        case 4:
            return "强"
        case 5:
            return "很强"
        default:
            return "未知"
        }
    }
    
    /// 验证表单数据
    /// - Parameters:
    ///   - email: 邮箱
    ///   - phone: 手机号
    ///   - password: 密码
    /// - Returns: 验证结果和错误信息
    public class func st_validateForm(email: String, phone: String, password: String) -> (isValid: Bool, errors: [String]) {
        var errors: [String] = []
        
        if !st_checkEmail(email: email) {
            errors.append("邮箱格式不正确")
        }
        
        if !st_checkPhoneNum(phoneNum: phone) {
            errors.append("手机号格式不正确")
        }
        
        if !st_checkPassword(password: password) {
            errors.append("密码格式不正确（8-32位，包含大小写字母和数字）")
        }
        
        return (errors.isEmpty, errors)
    }
}

// MARK: - String 扩展

public extension String {
    
    // MARK: - 便捷验证方法
    
    /// 验证是否为有效邮箱
    var st_isValidEmail: Bool {
        return STPredicateCheck.st_checkEmail(email: self)
    }
    
    /// 验证是否为有效手机号
    var st_isValidPhone: Bool {
        return STPredicateCheck.st_checkPhoneNum(phoneNum: self)
    }
    
    /// 验证是否为有效身份证号
    var st_isValidIdCard: Bool {
        return STPredicateCheck.st_checkIdCard(idCard: self)
    }
    
    /// 验证是否为有效密码
    var st_isValidPassword: Bool {
        return STPredicateCheck.st_checkPassword(password: self)
    }
    
    /// 验证是否为有效用户名
    var st_isValidUsername: Bool {
        return STPredicateCheck.st_checkUserName(userName: self)
    }
    
    /// 验证是否为纯数字
    var st_isDigits: Bool {
        return STPredicateCheck.st_checkIsDigit(text: self)
    }
    
    /// 验证是否为整数
    var st_isInteger: Bool {
        return STPredicateCheck.st_checkIsInteger(text: self)
    }
    
    /// 验证是否为浮点数
    var st_isFloat: Bool {
        return STPredicateCheck.st_checkIsFloat(text: self)
    }
    
    /// 验证是否为中文字符
    var st_isChinese: Bool {
        return STPredicateCheck.st_checkChinaChar(text: self)
    }
    
    /// 验证是否为英文字母
    var st_isEnglish: Bool {
        return STPredicateCheck.st_checkEnglishLetters(text: self)
    }
    
    /// 验证是否为有效 URL
    var st_isValidURL: Bool {
        return STPredicateCheck.st_checkURL(url: self)
    }
    
    /// 获取密码强度
    var st_passwordStrength: Int {
        return STPredicateCheck.st_checkPasswordStrength(password: self)
    }
    
    /// 获取密码强度描述
    var st_passwordStrengthDescription: String {
        return STPredicateCheck.st_getPasswordStrengthDescription(password: self)
    }
}
