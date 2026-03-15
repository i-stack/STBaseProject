//
//  STDictionary.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2019/1/21.
//

import Foundation

public extension Dictionary {
    // MARK: - Typed Access

    func stringValue(for key: Key) -> String {
        guard let value = self[key] else { return "" }
        if let stringValue = value as? String {
            return stringValue
        }
        return "\(value)"
    }

    func intValue(for key: Key) -> Int {
        guard let value = self[key] else { return 0 }
        if let intValue = value as? Int {
            return intValue
        }
        if let stringValue = value as? String, let intValue = Int(stringValue) {
            return intValue
        }
        if let doubleValue = value as? Double {
            return Int(doubleValue)
        }
        return 0
    }

    func doubleValue(for key: Key) -> Double {
        guard let value = self[key] else { return 0.0 }
        if let doubleValue = value as? Double {
            return doubleValue
        }
        if let stringValue = value as? String, let doubleValue = Double(stringValue) {
            return doubleValue
        }
        if let intValue = value as? Int {
            return Double(intValue)
        }
        return 0.0
    }

    func boolValue(for key: Key) -> Bool {
        guard let value = self[key] else { return false }
        if let boolValue = value as? Bool {
            return boolValue
        }
        if let stringValue = value as? String {
            let lowercased = stringValue.lowercased()
            return lowercased == "true" || lowercased == "1" || lowercased == "yes"
        }
        if let intValue = value as? Int {
            return intValue != 0
        }
        return false
    }

    func arrayValue<T>(for key: Key) -> [T] {
        guard let value = self[key] else { return [] }
        if let typedValue = value as? [T] {
            return typedValue
        }
        return []
    }

    func dictionaryValue<K, V>(for key: Key) -> [K: V] {
        guard let value = self[key] else { return [:] }
        if let typedValue = value as? [K: V] {
            return typedValue
        }
        return [:]
    }

    func value<T>(for key: Key, default defaultValue: T) -> T {
        guard let value = self[key] else { return defaultValue }
        if let typedValue = value as? T {
            return typedValue
        }
        return defaultValue
    }

    // MARK: - URL Encoding

    var urlEncodedQueryString: String {
        self.map { key, value in
            let encodedKey = "\(key)".addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? ""
            let encodedValue = "\(value)".addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? ""
            return "\(encodedKey)=\(encodedValue)"
        }
        .joined(separator: "&")
    }

    var urlEncodedFormData: Data? {
        urlEncodedQueryString.data(using: .utf8)
    }

    // MARK: - Merging

    func mergingValues(with other: [Key: Value]) -> [Key: Value] {
        var result = self
        for (key, value) in other {
            result[key] = value
        }
        return result
    }

    mutating func mergeValues(from other: [Key: Value]) {
        for (key, value) in other {
            self[key] = value
        }
    }

    // MARK: - Mapping

    func filteredDictionary(where predicate: (Key, Value) throws -> Bool) rethrows -> [Key: Value] {
        try filter(predicate)
    }

    func mapEntries<NewKey, NewValue>(
        keys: (Key) throws -> NewKey,
        values: (Value) throws -> NewValue
    ) rethrows -> [NewKey: NewValue] {
        var result: [NewKey: NewValue] = [:]
        for (key, value) in self {
            let newKey = try keys(key)
            let newValue = try values(value)
            result[newKey] = newValue
        }
        return result
    }

    func mapDictionaryValues<T>(_ transform: (Value) throws -> T) rethrows -> [Key: T] {
        var result: [Key: T] = [:]
        for (key, value) in self {
            result[key] = try transform(value)
        }
        return result
    }

    func mapDictionaryKeys<T>(_ transform: (Key) throws -> T) rethrows -> [T: Value] {
        var result: [T: Value] = [:]
        for (key, value) in self {
            let newKey = try transform(key)
            result[newKey] = value
        }
        return result
    }

    // MARK: - Collections

    var keyArray: [Key] {
        Array(keys)
    }

    var valueArray: [Value] {
        Array(values)
    }

    var randomKey: Key? {
        keys.randomElement()
    }

    var randomValue: Value? {
        values.randomElement()
    }

    func sortedByKey() -> [(Key, Value)] where Key: Comparable {
        sorted { $0.key < $1.key }
    }

    func sortedByKeyDescending() -> [(Key, Value)] where Key: Comparable {
        sorted { $0.key > $1.key }
    }

    func sortedByValue() -> [(Key, Value)] where Value: Comparable {
        sorted { $0.value < $1.value }
    }

    func sortedByValueDescending() -> [(Key, Value)] where Value: Comparable {
        sorted { $0.value > $1.value }
    }

    func sortedEntries(
        by areInIncreasingOrder: (Key, Value, Key, Value) throws -> Bool
    ) rethrows -> [(Key, Value)] {
        try sorted { try areInIncreasingOrder($0.key, $0.value, $1.key, $1.value) }
    }

    func contains(key: Key) -> Bool {
        keys.contains(key)
    }

    func containsValue(_ value: Value) -> Bool where Value: Equatable {
        values.contains(value)
    }

    func allValuesSatisfy(_ predicate: (Value) throws -> Bool) rethrows -> Bool {
        try values.allSatisfy(predicate)
    }

    func anyValueSatisfies(_ predicate: (Value) throws -> Bool) rethrows -> Bool {
        try values.contains { try predicate($0) }
    }

    func groupedValues<GroupKey>(by predicate: (Key, Value) throws -> GroupKey) rethrows -> [GroupKey: [Value]] {
        var result: [GroupKey: [Value]] = [:]
        for (key, value) in self {
            let groupKey = try predicate(key, value)
            if result[groupKey] == nil {
                result[groupKey] = []
            }
            result[groupKey]?.append(value)
        }
        return result
    }

    func sum() -> Double where Value: BinaryFloatingPoint {
        values.reduce(0.0) { $0 + Double($1) }
    }

    func sum() -> Int where Value: BinaryInteger {
        values.reduce(0) { $0 + Int($1) }
    }

    func average() -> Double where Value: BinaryFloatingPoint {
        guard !isEmpty else { return 0.0 }
        return sum() / Double(count)
    }

    func average() -> Double where Value: BinaryInteger {
        guard !isEmpty else { return 0.0 }
        return Double(sum()) / Double(count)
    }

}

public extension Dictionary where Value: Comparable {
    var maximumValue: Value? {
        values.max()
    }

    var minimumValue: Value? {
        values.min()
    }
}

public extension Dictionary {
    static func dictionary<K, V>(from elements: [(K, V)]) -> [K: V] {
        var result: [K: V] = [:]
        for (key, value) in elements {
            result[key] = value
        }
        return result
    }
}

public extension Dictionary where Value: Equatable {
    func equalsContents(of other: [Key: Value]) -> Bool {
        guard count == other.count else { return false }
        for (key, value) in self {
            guard let otherValue = other[key], otherValue == value else { return false }
        }
        return true
    }

    func differences(comparedTo other: [Key: Value]) -> [Key: Value] {
        var differences: [Key: Value] = [:]
        for (key, value) in self {
            if let otherValue = other[key] {
                if value != otherValue {
                    differences[key] = value
                }
            } else {
                differences[key] = value
            }
        }
        for (key, value) in other {
            if self[key] == nil {
                differences[key] = value
            }
        }
        return differences
    }
}

public extension Dictionary {
    mutating func apply(_ updates: [Key: Value]) {
        for (key, value) in updates {
            self[key] = value
        }
    }

    mutating func removeValues(for keys: [Key]) {
        for key in keys {
            self.removeValue(forKey: key)
        }
    }

    mutating func updateValue(
        _ value: Value,
        for key: Key,
        if condition: (Value?) -> Bool
    ) {
        if condition(self[key]) {
            self[key] = value
        }
    }
}
