//
//  STString.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2017/10/23.
//

import Foundation
import UIKit

private extension String {
    static func stringify(jsonValue: STJSONValue) -> String {
        switch jsonValue {
        case .bool(let value):
            return String(value)
        case .int(let value):
            return String(value)
        case .double(let value):
            return String(value)
        case .string(let value):
            return value
        case .array(let values):
            return "[\(values.map(Self.stringify(jsonValue:)).joined(separator: ", "))]"
        case .object(let dictionary):
            let pairs = dictionary.map { "\($0.key):\(Self.stringify(jsonValue: $0.value))" }
            return "{\(pairs.joined(separator: ", "))}"
        case .null:
            return ""
        }
    }
}

public extension String {
    // MARK: - Conversions

    static func parameterDictionary<T>(from model: T) -> [String: String] {
        var parameters: [String: String] = [:]
        let mirror = Mirror(reflecting: model)
        for case let (label?, value) in mirror.children {
            parameters[label] = String.string(from: value)
        }
        return parameters
    }

    static func formURLEncodedData(from parameters: [String: String]) -> Data {
        guard !parameters.isEmpty else { return Data() }
        let parameterString = parameters.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
        return parameterString.data(using: .utf8) ?? Data()
    }

    static func string(from value: Any) -> String {
        switch value {
        case let bool as Bool:
            return String(bool)
        case let string as String:
            return string
        case let number as NSNumber:
            return String(format: "%@", number)
        case let jsonValue as STJSONValue:
            return stringify(jsonValue: jsonValue)
        case let int as Int:
            return String(int)
        case let double as Double:
            return String(double)
        case let float as Float:
            return String(float)
        case let array as [Any]:
            return array.map(Self.string(from:)).joined(separator: ",")
        case let dictionary as [String: Any]:
            let pairs = dictionary.map { "\($0.key):\(Self.string(from: $0.value))" }
            return "{\(pairs.joined(separator: ", "))}"
        default:
            return "\(value)"
        }
    }

    func width(using font: UIFont) -> CGFloat {
        let size = CGSize(width: 999, height: 1000)
        let attributes = [NSAttributedString.Key.font: font]
        let stringSize = (self as NSString).boundingRect(
            with: size,
            options: .usesLineFragmentOrigin,
            attributes: attributes,
            context: nil
        ).size
        return CGFloat(ceilf(Float(stringSize.width)))
    }

    func height(using font: UIFont, constrainedTo maxWidth: CGFloat) -> CGFloat {
        let size = CGSize(width: maxWidth, height: .greatestFiniteMagnitude)
        let attributes = [NSAttributedString.Key.font: font]
        let stringSize = (self as NSString).boundingRect(
            with: size,
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: attributes,
            context: nil
        ).size
        return CGFloat(ceilf(Float(stringSize.height)))
    }

    // MARK: - Formatting

    func formattedAmount() -> String {
        let formatter = NumberFormatter()
        formatter.formatterBehavior = .behavior10_4
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 6
        formatter.locale = Locale(identifier: "en_US")
        let original = Self.string(from: self)
        let value = Double(original) ?? 0
        return formatter.string(from: NSNumber(value: value)) ?? original
    }

    func toDouble() -> Double {
        let formatter = NumberFormatter()
        formatter.locale = Locale.current
        formatter.decimalSeparator = "."
        if let result = formatter.number(from: self) {
            return result.doubleValue
        }
        formatter.decimalSeparator = ","
        return formatter.number(from: self)?.doubleValue ?? 0
    }

    func toInt() -> Int {
        let formatter = NumberFormatter()
        formatter.locale = Locale.current
        formatter.numberStyle = .decimal
        return formatter.number(from: self)?.intValue ?? 0
    }

    func formattedNumber(style: NumberFormatter.Style) -> String {
        let number = NSDecimalNumber(string: self)
        return NumberFormatter.localizedString(from: number, number: style)
    }

    func percentageString(decimalPlaces: Int = 2) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.minimumFractionDigits = decimalPlaces
        formatter.maximumFractionDigits = decimalPlaces
        guard let number = Double(self) else { return self }
        return formatter.string(from: NSNumber(value: number / 100)) ?? self
    }

    func formattedFileSize() -> String {
        guard let bytes = Int64(self) else { return self }
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB, .useTB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    // MARK: - URL

    var urlQueryParameters: [String: String] {
        guard
            !isEmpty,
            let components = URLComponents(string: self),
            let queryItems = components.queryItems
        else {
            return [:]
        }

        var parameters: [String: String] = [:]
        for item in queryItems where !item.name.isEmpty {
            parameters[item.name] = item.value ?? ""
        }
        return parameters
    }

    func appendingURLParameters(_ parameters: [String: String]) -> String? {
        guard var components = URLComponents(string: self) else { return nil }
        var queryItems = components.queryItems ?? []
        parameters.forEach { key, value in
            queryItems.append(URLQueryItem(name: key, value: value))
        }
        components.queryItems = queryItems
        return components.url?.absoluteString
    }

    func removingURLParameters(named names: [String]) -> String? {
        guard var components = URLComponents(string: self) else { return nil }
        components.queryItems = components.queryItems?.filter { !names.contains($0.name) }
        return components.url?.absoluteString
    }

    var urlHost: String? {
        URL(string: self)?.host
    }

    var urlPath: String? {
        URL(string: self)?.path
    }

    // MARK: - Random

    static func random(
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
        guard !characters.isEmpty, finalLength > 0 else { return "" }
        return String((0..<finalLength).compactMap { _ in characters.randomElement() })
    }

    // MARK: - Masking

    func maskingCharacters(
        in range: Range<Int>,
        with maskCharacter: Character = "*"
    ) -> String {
        guard
            range.lowerBound >= 0,
            range.lowerBound < range.upperBound,
            range.upperBound <= count
        else {
            return self
        }

        let startIndex = index(self.startIndex, offsetBy: range.lowerBound)
        let endIndex = index(self.startIndex, offsetBy: range.upperBound)
        let mask = String(repeating: maskCharacter, count: range.upperBound - range.lowerBound)
        return replacingCharacters(in: startIndex..<endIndex, with: mask)
    }

    func maskedPhoneNumber(start: Int, end: Int, maskCharacter: Character = "*") -> String {
        maskingCharacters(in: start..<end, with: maskCharacter)
    }

    func maskedEmail(maskCharacter: Character = "*") -> String {
        guard contains("@") else { return self }
        let components = split(separator: "@")
        guard components.count == 2 else { return self }
        let username = String(components[0])
        let domain = String(components[1])
        guard username.count > 2, let first = username.first, let last = username.last else { return self }
        let maskedUsername = String(first) + String(repeating: maskCharacter, count: username.count - 2) + String(last)
        return "\(maskedUsername)@\(domain)"
    }

    func maskedIDCard(maskCharacter: Character = "*") -> String {
        guard count >= 8 else { return self }
        return maskingCharacters(in: 4..<(count - 4), with: maskCharacter)
    }

    // MARK: - Clipboard

    func copyToPasteboard() {
        UIPasteboard.general.string = self
    }

    static func copyToPasteboard(_ string: String) {
        UIPasteboard.general.string = string
    }

    // MARK: - Transformations

    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var removingWhitespaceAndNewlines: String {
        unicodeScalars
            .filter { !$0.properties.isWhitespace }
            .map(String.init)
            .joined()
    }

    var capitalizingFirstLetter: String {
        guard !isEmpty else { return self }
        return prefix(1).uppercased() + dropFirst()
    }

    var lowercasingFirstLetter: String {
        guard !isEmpty else { return self }
        return prefix(1).lowercased() + dropFirst()
    }

    var camelCased: String {
        let components = split(separator: " ")
        guard !components.isEmpty else { return self }
        let first = String(components[0]).lowercased()
        let rest = components.dropFirst().map { $0.capitalized }.joined()
        return first + rest
    }

    var snakeCased: String {
        let pattern = "([a-z0-9])([A-Z])"
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(location: 0, length: count)
        return regex?
            .stringByReplacingMatches(in: self, options: [], range: range, withTemplate: "$1_$2")
            .lowercased() ?? self
    }
}
