//
//  STString.swift
//  STBaseProject
//
//  Created by stack on 2017/10/23.
//

import UIKit
import Foundation

public extension String {
    
    // MARK: - 模型转换
    
    /// 将模型转换为参数字典
    /// - Parameter model: 要转换的模型对象
    /// - Returns: 参数字典
    static func st_convertModelToParams<T>(_ model: T) -> [String: String] {
        var params: [String: String] = [:]
        let mirror = Mirror(reflecting: model)
        for case let (label?, value) in mirror.children {
            if let stringValue = value as? String {
                params[label] = stringValue
            } else if let convertibleValue = "\(value)" as String? {
                params[label] = convertibleValue
            }
        }
        return params
    }
    
    /// 将参数字典转换为 URL 编码的 Data
    /// - Parameter params: 参数字典
    /// - Returns: URL 编码的 Data
    static func st_convertDictToURLEncoded(params: [String: String]) -> Data {
        guard !params.isEmpty else { return Data() }
        let parameterString = params.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
        return parameterString.data(using: .utf8) ?? Data()
    }
}

// MARK: - 类型转换工具
public extension String {
    
    /// 将任意对象转换为字符串
    /// - Parameter object: 要转换的对象
    /// - Returns: 转换后的字符串
    static func st_returnStr(object: Any) -> String {
        switch object {
        case let number as NSNumber:
            return String(format: "%@", number)
        case let string as String:
            return string
        case let bool as Bool:
            return bool ? "1" : "0"
        case let jsonValue as STJSONValue:
            return st_convertJSONValueToString(jsonValue)
        case let int as Int:
            return String(int)
        case let double as Double:
            return String(double)
        case let float as Float:
            return String(float)
        case let array as [Any]:
            return array.map { st_returnStr(object: $0) }.joined(separator: ",")
        case let dict as [String: Any]:
            let pairs = dict.map { "\($0.key):\(st_returnStr(object: $0.value))" }
            return "{\(pairs.joined(separator: ", "))}"
        default:
            return "\(object)"
        }
    }
    
    /// 将 STJSONValue 转换为字符串
    /// - Parameter jsonValue: JSON 值
    /// - Returns: 转换后的字符串
    private static func st_convertJSONValueToString(_ jsonValue: STJSONValue) -> String {
        switch jsonValue {
        case .bool(let value):
            return value ? "1" : "0"
        case .int(let value):
            return String(value)
        case .double(let value):
            return String(value)
        case .string(let value):
            return value
        case .array(let values):
            let stringValues = values.map { st_convertJSONValueToString($0) }
            return "[\(stringValues.joined(separator: ", "))]"
        case .object(let dict):
            let pairs = dict.map { "\($0.key):\(st_convertJSONValueToString($0.value))" }
            return "{\(pairs.joined(separator: ", "))}"
        case .null:
            return ""
        }
    }
    
    /// 计算字符串在指定字体下的宽度
    /// - Parameter font: 字体
    /// - Returns: 字符串宽度
    func st_returnStrWidth(font: UIFont) -> CGFloat {
        let normalText: NSString = self as NSString
        let size = CGSize(width: 999, height: 1000)
        let attributes = [NSAttributedString.Key.font: font]
        let stringSize = normalText.boundingRect(with: size, options: .usesLineFragmentOrigin, attributes: attributes, context: nil).size
        return CGFloat(ceilf(Float(stringSize.width)))
    }
    
    /// 计算字符串在指定字体和最大宽度下的高度
    /// - Parameters:
    ///   - font: 字体
    ///   - maxWidth: 最大宽度
    /// - Returns: 字符串高度
    func st_calculateHeight(font: UIFont, maxWidth: CGFloat) -> CGFloat {
        let normalText: NSString = self as NSString
        let size = CGSize(width: maxWidth, height: CGFloat.greatestFiniteMagnitude)
        let attributes = [NSAttributedString.Key.font: font]
        let stringSize = normalText.boundingRect(with: size, options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: attributes, context: nil).size
        return CGFloat(ceilf(Float(stringSize.height)))
    }
}

// MARK: - 数字格式化扩展

public extension String {
    
    /// 格式化金额显示（添加千分位分隔符）
    /// - Returns: 格式化后的金额字符串
    func st_divideAmount() -> String {
        let numFormatter = NumberFormatter()
        let string = String.st_returnStr(object: self)
        numFormatter.formatterBehavior = .behavior10_4
        numFormatter.numberStyle = .decimal
        numFormatter.maximumFractionDigits = 6
        numFormatter.locale = Locale(identifier: "en_US")
        let numString = numFormatter.string(from: NSNumber(floatLiteral: Double(string) ?? 0))
        return numString ?? string
    }
    
    /// 将字符串转换为 Double 值
    /// - Returns: Double 值，转换失败返回 0
    func st_stringToDouble() -> Double {
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
    
    /// 将字符串转换为 Int 值
    /// - Returns: Int 值，转换失败返回 0
    func st_stringToInt() -> Int {
        let formatter = NumberFormatter()
        formatter.locale = Locale.current
        formatter.numberStyle = .decimal
        if let result = formatter.number(from: self) {
            return result.intValue
        }
        return 0
    }
    
    /// 转换为货币格式
    /// - Parameter style: 数字格式样式
    /// - Returns: 格式化后的货币字符串
    func st_convertToCurrency(style: NumberFormatter.Style) -> String {
        let number = NSDecimalNumber(string: self)
        return NumberFormatter.localizedString(from: number, number: style)
    }
    
    /// 转换为百分比格式
    /// - Parameter decimalPlaces: 小数位数
    /// - Returns: 百分比字符串
    func st_convertToPercentage(decimalPlaces: Int = 2) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.minimumFractionDigits = decimalPlaces
        formatter.maximumFractionDigits = decimalPlaces
        if let number = Double(self) {
            return formatter.string(from: NSNumber(value: number / 100)) ?? self
        }
        return self
    }
    
    /// 格式化文件大小
    /// - Returns: 格式化后的文件大小字符串
    func st_formatFileSize() -> String {
        guard let bytes = Int64(self) else { return self }
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB, .useTB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

// MARK: - URL 处理扩展
public extension String {
    
    /// 从 URL 中提取参数
    /// - Returns: 参数字典
    func st_parameterWithURL() -> [String: String] {
        var parmDict: [String: String] = [:]
        guard !isEmpty else { return parmDict }
        guard let urlComponents = URLComponents(string: self),
              let queryItems = urlComponents.queryItems else {
            return parmDict
        }
        
        for item in queryItems {
            if !item.name.isEmpty {
                parmDict[item.name] = item.value ?? ""
            }
        }
        return parmDict
    }
    
    /// 向 URL 添加参数
    /// - Parameter parameters: 要添加的参数
    /// - Returns: 添加参数后的 URL 字符串
    func st_appendParametersToURLUsingComponents(parameters: [String: String]) -> String? {
        guard var components = URLComponents(string: self) else {
            return nil
        }
        var queryItems = components.queryItems ?? []
        parameters.forEach { key, value in
            queryItems.append(URLQueryItem(name: key, value: value))
        }
        components.queryItems = queryItems
        return components.url?.absoluteString
    }
    
    /// 移除 URL 中的指定参数
    /// - Parameter parameterNames: 要移除的参数名数组
    /// - Returns: 移除参数后的 URL 字符串
    func st_removeParametersFromURL(parameterNames: [String]) -> String? {
        guard var components = URLComponents(string: self) else {
            return nil
        }
        components.queryItems = components.queryItems?.filter { item in
            !parameterNames.contains(item.name)
        }
        return components.url?.absoluteString
    }
    
    /// 获取 URL 的域名
    /// - Returns: 域名，如果无效返回 nil
    func st_getDomainFromURL() -> String? {
        guard let url = URL(string: self) else { return nil }
        return url.host
    }
    
    /// 获取 URL 的路径
    /// - Returns: 路径，如果无效返回 nil
    func st_getPathFromURL() -> String? {
        guard let url = URL(string: self) else { return nil }
        return url.path
    }
}

// MARK: - 工具方法扩展
public extension String {
    
    /// 生成随机字符串
    /// - Parameters:
    ///   - length: 字符串长度，默认 6-10 位
    ///   - includeNumbers: 是否包含数字
    ///   - includeUppercase: 是否包含大写字母
    ///   - includeLowercase: 是否包含小写字母
    ///   - includeSymbols: 是否包含特殊符号
    /// - Returns: 随机字符串
    static func st_generateRandomString(
        length: Int? = nil,
        includeNumbers: Bool = true,
        includeUppercase: Bool = true,
        includeLowercase: Bool = true,
        includeSymbols: Bool = false
    ) -> String {
        var characters = ""
        if includeLowercase { characters += "abcdefghijklmnopqrstuvwxyz" }
        if includeUppercase { characters += "ABCDEFGHIJKLMNOPQRSTUVWXYZ" }
        if includeNumbers { characters += "0123456789" }
        if includeSymbols { characters += "!@#$%^&*()_+-=[]{}|;:,.<>?" }
        
        let finalLength = length ?? Int.random(in: 6...10)
        let randomString = String((0..<finalLength).compactMap { _ in
            characters.randomElement()
        })
        return randomString
    }
    
    /// 生成指定长度的随机字符串
    /// - Parameter length: 字符串长度
    /// - Returns: 随机字符串
    static func st_generateRandomString(length: Int) -> String {
        return st_generateRandomString(length: length, includeNumbers: true, includeUppercase: true, includeLowercase: true, includeSymbols: false)
    }
    
    /// 掩码处理手机号
    /// - Parameters:
    ///   - start: 开始位置
    ///   - end: 结束位置
    ///   - maskChar: 掩码字符，默认为 "*"
    /// - Returns: 掩码后的字符串
    func st_maskPhoneNumber(start: Int, end: Int, maskChar: Character = "*") -> String {
        guard start < end, count > end else { return self }
        let startIndex = index(self.startIndex, offsetBy: start)
        let endIndex = index(self.startIndex, offsetBy: end)
        let mask = String(repeating: maskChar, count: end - start)
        return replacingCharacters(in: startIndex..<endIndex, with: mask)
    }
    
    /// 掩码处理邮箱
    /// - Parameter maskChar: 掩码字符，默认为 "*"
    /// - Returns: 掩码后的邮箱
    func st_maskEmail(maskChar: Character = "*") -> String {
        guard contains("@") else { return self }
        let components = split(separator: "@")
        guard components.count == 2 else { return self }
        let username = String(components[0])
        let domain = String(components[1])
        if username.count <= 2 {
            return self
        }
        let maskedUsername = String(username.first!) + String(repeating: maskChar, count: username.count - 2) + String(username.last!)
        return "\(maskedUsername)@\(domain)"
    }
    
    /// 掩码处理身份证号
    /// - Parameter maskChar: 掩码字符，默认为 "*"
    /// - Returns: 掩码后的身份证号
    func st_maskIdCard(maskChar: Character = "*") -> String {
        guard count >= 8 else { return self }
        let startIndex = index(self.startIndex, offsetBy: 4)
        let endIndex = index(self.startIndex, offsetBy: count - 4)
        let mask = String(repeating: maskChar, count: count - 8)
        return replacingCharacters(in: startIndex..<endIndex, with: mask)
    }
    
    /// 复制到剪贴板
    /// - Parameter pasteboardString: 要复制的字符串
    func st_copyToPasteboard(pasteboardString: String) {
        UIPasteboard.general.string = pasteboardString
    }
    
    /// 复制自身到剪贴板
    func st_copyToPasteboard() {
        UIPasteboard.general.string = self
    }
    
    /// 移除首尾空白字符
    /// - Returns: 处理后的字符串
    func st_trim() -> String {
        return trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// 移除所有空白字符
    /// - Returns: 处理后的字符串
    func st_removeAllWhitespaces() -> String {
        return replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "\n", with: "").replacingOccurrences(of: "\t", with: "")
    }
    
    /// 首字母大写
    /// - Returns: 首字母大写的字符串
    func st_capitalizeFirstLetter() -> String {
        guard !isEmpty else { return self }
        return prefix(1).uppercased() + dropFirst()
    }
    
    /// 首字母小写
    /// - Returns: 首字母小写的字符串
    func st_lowercaseFirstLetter() -> String {
        guard !isEmpty else { return self }
        return prefix(1).lowercased() + dropFirst()
    }
    
    /// 驼峰命名转换
    /// - Returns: 驼峰命名字符串
    func st_toCamelCase() -> String {
        let components = split(separator: " ")
        guard !components.isEmpty else { return self }
        
        let first = String(components[0]).lowercased()
        let rest = components.dropFirst().map { $0.capitalized }.joined()
        return first + rest
    }
    
    /// 蛇形命名转换
    /// - Returns: 蛇形命名字符串
    func st_toSnakeCase() -> String {
        let pattern = "([a-z0-9])([A-Z])"
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(location: 0, length: count)
        return regex?.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: "$1_$2").lowercased() ?? self
    }
}
