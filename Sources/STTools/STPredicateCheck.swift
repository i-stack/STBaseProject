//
//  STPredicateCheck.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2018/06/12.
//

import Foundation

public enum STStringValidationPattern {
    public static let email = "^([a-zA-Z0-9]+([._\\-])*[a-zA-Z0-9]*)+@([a-zA-Z0-9])+(.([a-zA-Z])+)+$"
    public static let phoneNumber = "^1(3[0-9]|4[56789]|5[0-9]|6[6]|7[0-9]|8[0-9]|9[189])\\d{8}$"
    public static let idCard = "^[1-9]\\d{5}(18|19|20)\\d{2}((0[1-9])|(1[0-2]))(([0-2][1-9])|10|20|30|31)\\d{3}[0-9Xx]$"
    public static let postalCode = "^[1-9]\\d{5}$"
    public static let bankCard = "^\\d{16,19}$"
    public static let creditCard = "^\\d{13,19}$"
    public static let strongPassword = "^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d)(?=.*[@$!%*?&])[A-Za-z\\d@$!%*?&]{8,32}$"
    public static let mediumPassword = "^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d)[A-Za-z\\d]{8,32}$"
    public static let weakPassword = "^(?=.*[A-Za-z])(?=.*\\d)[A-Za-z\\d]{6,32}$"
    public static let digits = "^[0-9]*$"
    public static let integer = "^-?[1-9]\\d*|0$"
    public static let positiveInteger = "^[1-9]\\d*$"
    public static let nonNegativeInteger = "^[1-9]\\d*|0$"
    public static let floatingPoint = "^-?([1-9]\\d*\\.\\d*|0\\.\\d*[1-9]\\d*|0?\\.0+|0)$"
    public static let positiveFloatingPoint = "^([1-9]\\d*\\.\\d*|0\\.\\d*[1-9]\\d*)$"
    public static let chineseCharacters = "^[\\p{Han}]*$"
    public static let englishLetters = "^[A-Za-z]*$"
    public static let uppercaseLetters = "^[A-Z]*$"
    public static let lowercaseLetters = "^[a-z]*$"
    public static let alphanumeric = "^[A-Za-z0-9]*$"
    public static let punctuation = "^[\\p{P}]*$"
    public static let url = "^(https?:\\/\\/)?([\\da-z\\.-]+)\\.([a-z\\.]{2,6})([\\/\\w \\.-]*)*\\/?$"
    public static let ipv4 = "^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$"
    public static let ipv6 = "^([0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}$"
    public static let date = "^\\d{4}-(0[1-9]|1[0-2])-(0[1-9]|[12]\\d|3[01])$"
    public static let time = "^([01]\\d|2[0-3]):([0-5]\\d):([0-5]\\d)$"
    public static let dateTime = "^\\d{4}-(0[1-9]|1[0-2])-(0[1-9]|[12]\\d|3[01])\\s([01]\\d|2[0-3]):([0-5]\\d):([0-5]\\d)$"
    public static let mixedTextWithPunctuation = "^([\\p{Han}\\p{P}A-Za-z0-9])*$"
}

public enum STStringValidator {
    public static func matches(_ text: String, pattern: String) -> Bool {
        guard !text.isEmpty else { return false }
        let predicate = NSPredicate(format: "SELF MATCHES %@", pattern)
        return predicate.evaluate(with: text)
    }

    public static func containsUppercase(_ text: String) -> Bool {
        text.range(of: "[A-Z]", options: .regularExpression) != nil
    }

    public static func containsLowercase(_ text: String) -> Bool {
        text.range(of: "[a-z]", options: .regularExpression) != nil
    }

    public static func containsDigit(_ text: String) -> Bool {
        text.range(of: "\\d", options: .regularExpression) != nil
    }

    public static func containsSpecialCharacter(_ text: String) -> Bool {
        text.range(of: "[@$!%*?&]", options: .regularExpression) != nil
    }

    public static func isStrongPassword(_ password: String) -> Bool {
        matches(password, pattern: STStringValidationPattern.strongPassword)
    }

    public static func isMediumPassword(_ password: String) -> Bool {
        matches(password, pattern: STStringValidationPattern.mediumPassword)
    }

    public static func isWeakPassword(_ password: String) -> Bool {
        matches(password, pattern: STStringValidationPattern.weakPassword)
    }

    public static func isValidPassword(_ password: String) -> Bool {
        isMediumPassword(password)
    }

    public static func isValidUsername(_ username: String, allowsSpaces: Bool = false) -> Bool {
        let pattern = allowsSpaces
            ? "[\\u{4e00}-\\u{9fa5}a-zA-Z0-9\\s]{1,32}"
            : "[\\u{4e00}-\\u{9fa5}a-zA-Z0-9]{1,32}"
        return matches(username, pattern: pattern)
    }

    public static func isValidEmail(_ text: String) -> Bool { matches(text, pattern: STStringValidationPattern.email) }
    public static func isValidPhoneNumber(_ text: String) -> Bool { matches(text, pattern: STStringValidationPattern.phoneNumber) }
    public static func isValidIDCard(_ text: String) -> Bool { matches(text, pattern: STStringValidationPattern.idCard) }
    public static func isValidPostalCode(_ text: String) -> Bool { matches(text, pattern: STStringValidationPattern.postalCode) }
    public static func isValidBankCard(_ text: String) -> Bool { matches(text, pattern: STStringValidationPattern.bankCard) }
    public static func isValidCreditCard(_ text: String) -> Bool { matches(text, pattern: STStringValidationPattern.creditCard) }
    public static func isDigits(_ text: String) -> Bool { matches(text, pattern: STStringValidationPattern.digits) }
    public static func isInteger(_ text: String) -> Bool { matches(text, pattern: STStringValidationPattern.integer) }
    public static func isPositiveInteger(_ text: String) -> Bool { matches(text, pattern: STStringValidationPattern.positiveInteger) }
    public static func isNonNegativeInteger(_ text: String) -> Bool { matches(text, pattern: STStringValidationPattern.nonNegativeInteger) }
    public static func isFloatingPoint(_ text: String) -> Bool { matches(text, pattern: STStringValidationPattern.floatingPoint) }
    public static func isPositiveFloatingPoint(_ text: String) -> Bool { matches(text, pattern: STStringValidationPattern.positiveFloatingPoint) }
    public static func isChineseText(_ text: String) -> Bool { matches(text, pattern: STStringValidationPattern.chineseCharacters) }
    public static func isEnglishLetters(_ text: String) -> Bool { matches(text, pattern: STStringValidationPattern.englishLetters) }
    public static func isUppercaseLetters(_ text: String) -> Bool { matches(text, pattern: STStringValidationPattern.uppercaseLetters) }
    public static func isLowercaseLetters(_ text: String) -> Bool { matches(text, pattern: STStringValidationPattern.lowercaseLetters) }
    public static func isAlphanumeric(_ text: String) -> Bool { matches(text, pattern: STStringValidationPattern.alphanumeric) }
    public static func isPunctuation(_ text: String) -> Bool { matches(text, pattern: STStringValidationPattern.punctuation) }
    public static func isMixedTextWithPunctuation(_ text: String) -> Bool { matches(text, pattern: STStringValidationPattern.mixedTextWithPunctuation) }
    public static func isValidURL(_ text: String) -> Bool { matches(text, pattern: STStringValidationPattern.url) }
    public static func isIPv4Address(_ text: String) -> Bool { matches(text, pattern: STStringValidationPattern.ipv4) }
    public static func isIPv6Address(_ text: String) -> Bool { matches(text, pattern: STStringValidationPattern.ipv6) }
    public static func isDateString(_ text: String) -> Bool { matches(text, pattern: STStringValidationPattern.date) }
    public static func isTimeString(_ text: String) -> Bool { matches(text, pattern: STStringValidationPattern.time) }
    public static func isDateTimeString(_ text: String) -> Bool { matches(text, pattern: STStringValidationPattern.dateTime) }

    public static func hasLength(_ text: String, between minLength: Int, and maxLength: Int) -> Bool {
        guard minLength <= maxLength else { return false }
        return text.count >= minLength && text.count <= maxLength
    }

    public static func hasMinimumLength(_ text: String, _ minLength: Int) -> Bool {
        text.count >= minLength
    }

    public static func hasMaximumLength(_ text: String, _ maxLength: Int) -> Bool {
        text.count <= maxLength
    }

    public static func passwordStrength(for password: String) -> Int {
        var strength = 0
        if hasMinimumLength(password, 8) { strength += 1 }
        if containsLowercase(password) { strength += 1 }
        if containsUppercase(password) { strength += 1 }
        if containsDigit(password) { strength += 1 }
        if containsSpecialCharacter(password) { strength += 1 }
        return strength
    }

    public static func passwordStrengthDescription(for password: String) -> String {
        switch passwordStrength(for: password) {
        case 0, 1: return "很弱"
        case 2: return "弱"
        case 3: return "中等"
        case 4: return "强"
        case 5: return "很强"
        default: return "未知"
        }
    }

    public static func validateForm(email: String, phone: String, password: String) -> (isValid: Bool, errors: [String]) {
        var errors: [String] = []
        if !isValidEmail(email) {
            errors.append("邮箱格式不正确")
        }
        if !isValidPhoneNumber(phone) {
            errors.append("手机号格式不正确")
        }
        if !isValidPassword(password) {
            errors.append("密码格式不正确（8-32位，包含大小写字母和数字）")
        }
        return (errors.isEmpty, errors)
    }
}

public extension String {
    func matches(pattern: String) -> Bool {
        STStringValidator.matches(self, pattern: pattern)
    }

    var isValidEmail: Bool { STStringValidator.isValidEmail(self) }
    var isValidPhoneNumber: Bool { STStringValidator.isValidPhoneNumber(self) }
    var isValidIDCard: Bool { STStringValidator.isValidIDCard(self) }
    var isValidPassword: Bool { STStringValidator.isValidPassword(self) }
    var isValidUsername: Bool { STStringValidator.isValidUsername(self) }
    var isDigitsOnly: Bool { STStringValidator.isDigits(self) }
    var isIntegerNumber: Bool { STStringValidator.isInteger(self) }
    var isFloatingPointNumber: Bool { STStringValidator.isFloatingPoint(self) }
    var containsOnlyChineseCharacters: Bool { STStringValidator.isChineseText(self) }
    var containsOnlyEnglishLetters: Bool { STStringValidator.isEnglishLetters(self) }
    var isValidURL: Bool { STStringValidator.isValidURL(self) }
    var passwordStrength: Int { STStringValidator.passwordStrength(for: self) }
    var passwordStrengthDescription: String { STStringValidator.passwordStrengthDescription(for: self) }
}
