//
//  STDictionary.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2019/1/21.
//

import Foundation

public extension Dictionary {
        
    /// 安全获取字符串值
    /// - Parameter key: 键
    /// - Returns: 字符串值，如果不存在或类型不匹配则返回空字符串
    func st_safeString(for key: Key) -> String {
        guard let value = self[key] else { return "" }
        if let stringValue = value as? String {
            return stringValue
        }
        return "\(value)"
    }
    
    /// 安全获取整数值
    /// - Parameter key: 键
    /// - Returns: 整数值，如果不存在或类型不匹配则返回0
    func st_safeInt(for key: Key) -> Int {
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
    
    /// 安全获取双精度浮点数值
    /// - Parameter key: 键
    /// - Returns: 双精度浮点数值，如果不存在或类型不匹配则返回0.0
    func st_safeDouble(for key: Key) -> Double {
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
    
    /// 安全获取布尔值
    /// - Parameter key: 键
    /// - Returns: 布尔值，如果不存在或类型不匹配则返回false
    func st_safeBool(for key: Key) -> Bool {
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
    
    /// 安全获取数组值
    /// - Parameter key: 键
    /// - Returns: 数组值，如果不存在或类型不匹配则返回空数组
    func st_safeArray<T>(for key: Key) -> [T] {
        guard let value = self[key] else { return [] }
        if let arrayValue = value as? [T] {
            return arrayValue
        }
        return []
    }
    
    /// 安全获取字典值
    /// - Parameter key: 键
    /// - Returns: 字典值，如果不存在或类型不匹配则返回空字典
    func st_safeDictionary<K, V>(for key: Key) -> [K: V] {
        guard let value = self[key] else { return [:] }
        if let dictValue = value as? [K: V] {
            return dictValue
        }
        return [:]
    }
    
    /// 安全获取任意值，带默认值
    /// - Parameters:
    ///   - key: 键
    ///   - defaultValue: 默认值
    /// - Returns: 值或默认值
    func st_safeValue<T>(for key: Key, defaultValue: T) -> T {
        guard let value = self[key] else { return defaultValue }
        if let typedValue = value as? T {
            return typedValue
        }
        return defaultValue
    }
    
    // MARK: - URL Encoding Methods
    
    /// 将字典转换为URL编码的字符串
    /// - Returns: URL编码的查询字符串
    func st_urlEncodedToString() -> String {
        self.map { key, value in
            let encodedKey = "\(key)".addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? ""
            let encodedValue = "\(value)".addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? ""
            return "\(encodedKey)=\(encodedValue)"
        }
        .joined(separator: "&")
    }
    
    /// 将字典转换为URL编码的数据
    /// - Returns: URL编码的数据
    func st_urlEncodedToData() -> Data? {
        return st_urlEncodedToString().data(using: .utf8)
    }
    
    // MARK: - Dictionary Operations
    
    /// 合并另一个字典（不修改原字典）
    /// - Parameter other: 要合并的字典
    /// - Returns: 合并后的新字典
    func st_merged(with other: [Key: Value]) -> [Key: Value] {
        var result = self
        for (key, value) in other {
            result[key] = value
        }
        return result
    }
    
    /// 合并另一个字典（修改原字典）
    /// - Parameter other: 要合并的字典
    mutating func st_merge(with other: [Key: Value]) {
        for (key, value) in other {
            self[key] = value
        }
    }
    
    /// 过滤字典
    /// - Parameter predicate: 过滤条件
    /// - Returns: 过滤后的新字典
    func st_filtered(where predicate: (Key, Value) throws -> Bool) rethrows -> [Key: Value] {
        return try self.filter(predicate)
    }
    
    /// 转换字典的键和值
    /// - Parameters:
    ///   - keyTransform: 键转换函数
    ///   - valueTransform: 值转换函数
    /// - Returns: 转换后的新字典
    func st_transformed<K, V>(keyTransform: (Key) throws -> K, valueTransform: (Value) throws -> V) rethrows -> [K: V] {
        var result: [K: V] = [:]
        for (key, value) in self {
            let newKey = try keyTransform(key)
            let newValue = try valueTransform(value)
            result[newKey] = newValue
        }
        return result
    }
    
    /// 转换字典的值（保持键不变）
    /// - Parameter transform: 值转换函数
    /// - Returns: 转换后的新字典
    func st_mapValues<T>(_ transform: (Value) throws -> T) rethrows -> [Key: T] {
        var result: [Key: T] = [:]
        for (key, value) in self {
            result[key] = try transform(value)
        }
        return result
    }
    
    /// 转换字典的键（保持值不变）
    /// - Parameter transform: 键转换函数
    /// - Returns: 转换后的新字典
    func st_mapKeys<T>(_ transform: (Key) throws -> T) rethrows -> [T: Value] {
        var result: [T: Value] = [:]
        for (key, value) in self {
            let newKey = try transform(key)
            result[newKey] = value
        }
        return result
    }
    
    // MARK: - Utility Methods
    
    /// 检查字典是否为空
    var st_isEmpty: Bool {
        return self.isEmpty
    }
    
    /// 获取字典的键数组
    var st_keys: [Key] {
        return Array(self.keys)
    }
    
    /// 获取字典的值数组
    var st_values: [Value] {
        return Array(self.values)
    }
    
    /// 获取字典的大小
    var st_count: Int {
        return self.count
    }
    
    /// 随机获取一个键值对
    var st_randomElement: (Key, Value)? {
        return self.randomElement()
    }
    
    /// 随机获取一个键
    var st_randomKey: Key? {
        return self.keys.randomElement()
    }
    
    /// 随机获取一个值
    var st_randomValue: Value? {
        return self.values.randomElement()
    }
    
    // MARK: - Sorting Methods
    
    /// 按键排序（升序）
    /// - Returns: 排序后的键值对数组
    func st_sortedByKey() -> [(Key, Value)] where Key: Comparable {
        return self.sorted { $0.key < $1.key }
    }
    
    /// 按键排序（降序）
    /// - Returns: 排序后的键值对数组
    func st_sortedByKeyDescending() -> [(Key, Value)] where Key: Comparable {
        return self.sorted { $0.key > $1.key }
    }
    
    /// 按值排序（升序）
    /// - Returns: 排序后的键值对数组
    func st_sortedByValue() -> [(Key, Value)] where Value: Comparable {
        return self.sorted { $0.value < $1.value }
    }
    
    /// 按值排序（降序）
    /// - Returns: 排序后的键值对数组
    func st_sortedByValueDescending() -> [(Key, Value)] where Value: Comparable {
        return self.sorted { $0.value > $1.value }
    }
    
    /// 自定义排序
    /// - Parameter areInIncreasingOrder: 排序规则
    /// - Returns: 排序后的键值对数组
    func st_sorted(by areInIncreasingOrder: (Key, Value, Key, Value) throws -> Bool) rethrows -> [(Key, Value)] {
        return try self.sorted { try areInIncreasingOrder($0.key, $0.value, $1.key, $1.value) }
    }
    
    // MARK: - Subscript Methods
    
    /// 安全的下标访问，带默认值
    /// - Parameters:
    ///   - key: 键
    ///   - defaultValue: 默认值
    /// - Returns: 值或默认值
    subscript(key: Key, default defaultValue: Value) -> Value {
        return self[key] ?? defaultValue
    }
    
    // MARK: - Validation Methods
    
    /// 检查是否包含指定的键
    /// - Parameter key: 要检查的键
    /// - Returns: 是否包含
    func st_contains(key: Key) -> Bool {
        return self.keys.contains(key)
    }
    
    /// 检查是否包含指定的值
    /// - Parameter value: 要检查的值
    /// - Returns: 是否包含
    func st_contains(value: Value) -> Bool where Value: Equatable {
        return self.values.contains(value)
    }
    
    /// 检查所有值是否满足条件
    /// - Parameter predicate: 条件函数
    /// - Returns: 是否所有值都满足条件
    func st_allSatisfy(_ predicate: (Value) throws -> Bool) rethrows -> Bool {
        return try self.values.allSatisfy(predicate)
    }
    
    /// 检查是否存在满足条件的值
    /// - Parameter predicate: 条件函数
    /// - Returns: 是否存在满足条件的值
    func st_anySatisfy(_ predicate: (Value) throws -> Bool) rethrows -> Bool {
        return try self.values.contains { try predicate($0) }
    }
    
    // MARK: - Grouping Methods
    
    /// 按条件分组
    /// - Parameter predicate: 分组条件
    /// - Returns: 分组后的字典
    func st_grouped<K>(by predicate: (Key, Value) throws -> K) rethrows -> [K: [Value]] {
        var result: [K: [Value]] = [:]
        for (key, value) in self {
            let groupKey = try predicate(key, value)
            if result[groupKey] == nil {
                result[groupKey] = []
            }
            result[groupKey]?.append(value)
        }
        return result
    }
    
    // MARK: - Statistics Methods
    
    /// 获取值的总和（适用于数值类型）
    /// - Returns: 总和
    func st_sum() -> Double where Value: BinaryFloatingPoint {
        return self.values.reduce(0.0) { $0 + Double($1) }
    }
    
    /// 获取值的总和（适用于整数类型）
    /// - Returns: 总和
    func st_sum() -> Int where Value: BinaryInteger {
        return self.values.reduce(0) { $0 + Int($1) }
    }
    
    /// 获取值的平均值
    /// - Returns: 平均值
    func st_average() -> Double where Value: BinaryFloatingPoint {
        guard !self.isEmpty else { return 0.0 }
        return st_sum() / Double(self.count)
    }
    
    /// 获取值的平均值
    /// - Returns: 平均值
    func st_average() -> Double where Value: BinaryInteger {
        guard !self.isEmpty else { return 0.0 }
        return Double(st_sum()) / Double(self.count)
    }
    
    /// 获取最大值
    /// - Returns: 最大值
    func st_max() -> Value? where Value: Comparable {
        return self.values.max()
    }
    
    /// 获取最小值
    /// - Returns: 最小值
    func st_min() -> Value? where Value: Comparable {
        return self.values.min()
    }
}

// MARK: - Dictionary Initialization Extensions
public extension Dictionary {
    
    
    /// 从键值对数组创建字典
    /// - Parameter elements: 键值对数组
    /// - Returns: 字典对象
    static func st_fromElements<K, V>(_ elements: [(K, V)]) -> [K: V] {
        var result: [K: V] = [:]
        for (key, value) in elements {
            result[key] = value
        }
        return result
    }
}

// MARK: - Dictionary Comparison Extensions
public extension Dictionary where Value: Equatable {
    
    /// 检查两个字典是否相等（忽略键的顺序）
    /// - Parameter other: 要比较的字典
    /// - Returns: 是否相等
    func st_isEqual(to other: [Key: Value]) -> Bool {
        guard self.count == other.count else { return false }
        for (key, value) in self {
            guard let otherValue = other[key], otherValue == value else { return false }
        }
        return true
    }
    
    /// 获取两个字典的差异
    /// - Parameter other: 要比较的字典
    /// - Returns: 差异字典
    func st_differences(from other: [Key: Value]) -> [Key: Value] {
        var differences: [Key: Value] = [:]
        
        // 检查当前字典中的差异
        for (key, value) in self {
            if let otherValue = other[key] {
                if value != otherValue {
                    differences[key] = value
                }
            } else {
                differences[key] = value
            }
        }
        
        // 检查另一个字典中的差异
        for (key, value) in other {
            if self[key] == nil {
                differences[key] = value
            }
        }
        
        return differences
    }
}

// MARK: - Dictionary Performance Extensions
public extension Dictionary {
    
    /// 批量更新字典（性能优化）
    /// - Parameter updates: 要更新的键值对
    mutating func st_batchUpdate(_ updates: [Key: Value]) {
        for (key, value) in updates {
            self[key] = value
        }
    }
    
    /// 批量移除键（性能优化）
    /// - Parameter keys: 要移除的键数组
    mutating func st_batchRemove(_ keys: [Key]) {
        for key in keys {
            self.removeValue(forKey: key)
        }
    }
    
    /// 条件更新（只在条件满足时更新）
    /// - Parameters:
    ///   - key: 键
    ///   - value: 新值
    ///   - condition: 更新条件
    mutating func st_updateIf(_ key: Key, value: Value, condition: (Value?) -> Bool) {
        if condition(self[key]) {
            self[key] = value
        }
    }
}
