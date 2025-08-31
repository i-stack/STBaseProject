//
//  STBaseModel.swift
//  STBaseProject
//
//  Created by stack on 2018/3/14.
//

import UIKit
import Foundation

// MARK: - 灵活值类型
public enum STFlexibleValue {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case array([STFlexibleValue])
    case dictionary([String: STFlexibleValue])
    case null
    
    public init(_ value: Any) {
        switch value {
        case let string as String:
            self = .string(string)
        case let int as Int:
            self = .int(int)
        case let double as Double:
            self = .double(double)
        case let bool as Bool:
            self = .bool(bool)
        case let array as [Any]:
            self = .array(array.map { STFlexibleValue($0) })
        case let dict as [String: Any]:
            self = .dictionary(dict.mapValues { STFlexibleValue($0) })
        case is NSNull:
            self = .null
        default:
            self = .string(String(describing: value))
        }
    }
    
    /// 转换为具体类型
    public func st_asString() -> String? {
        switch self {
        case .string(let value): return value
        case .int(let value): return String(value)
        case .double(let value): return String(value)
        case .bool(let value): return String(value)
        default: return nil
        }
    }
    
    public func st_asInt() -> Int? {
        switch self {
        case .int(let value): return value
        case .string(let value): return Int(value)
        case .double(let value): return Int(value)
        case .bool(let value): return value ? 1 : 0
        default: return nil
        }
    }
    
    public func st_asDouble() -> Double? {
        switch self {
        case .double(let value): return value
        case .int(let value): return Double(value)
        case .string(let value): return Double(value)
        case .bool(let value): return value ? 1.0 : 0.0
        default: return nil
        }
    }
    
    public func st_asBool() -> Bool? {
        switch self {
        case .bool(let value): return value
        case .int(let value): return value != 0
        case .string(let value): return value.lowercased() == "true" || value == "1"
        case .double(let value): return value != 0.0
        default: return nil
        }
    }
    
    public func st_asArray() -> [STFlexibleValue]? {
        switch self {
        case .array(let value): return value
        default: return nil
        }
    }
    
    public func st_asDictionary() -> [String: STFlexibleValue]? {
        switch self {
        case .dictionary(let value): return value
        default: return nil
        }
    }
    
    /// 安全获取值，提供默认值
    public func st_stringValue(default: String = "") -> String {
        return st_asString() ?? `default`
    }
    
    public func st_intValue(default: Int = 0) -> Int {
        return st_asInt() ?? `default`
    }
    
    public func st_doubleValue(default: Double = 0.0) -> Double {
        return st_asDouble() ?? `default`
    }
    
    public func st_boolValue(default: Bool = false) -> Bool {
        return st_asBool() ?? `default`
    }
    
    public func st_arrayValue(default: [STFlexibleValue] = []) -> [STFlexibleValue] {
        return st_asArray() ?? `default`
    }
    
    public func st_dictionaryValue(default: [String: STFlexibleValue] = [:]) -> [String: STFlexibleValue] {
        return st_asDictionary() ?? `default`
    }
}

// MARK: - 统一模型基类
open class STBaseModel: NSObject {
    
    // MARK: - 灵活模型支持
    /// 存储原始数据
    private var st_rawData: [String: STFlexibleValue] = [:]
    
    /// 存储处理后的数据
    private var st_processedData: [String: Any] = [:]
    
    /// 是否启用灵活模式
    open var st_isFlexibleMode: Bool = false
    
    // MARK: - 初始化
    public override init() {
        super.init()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    /// 从字典初始化
    public convenience init(from dictionary: [String: Any]) {
        self.init()
        self.st_update(from: dictionary)
    }
    
    // MARK: - 内存管理
    deinit {
        STBaseModel.st_debugPrint(content: "🌈 -> \(self) 🌈 ----> 🌈 dealloc")
    }
    
    // MARK: - 键值编码
    open override func value(forUndefinedKey key: String) -> Any? {
        STBaseModel.st_debugPrint(content: "⚠️ ⚠️ Key = \(key) isValueForUndefinedKey ⚠️ ⚠️")
        return nil
    }

    open override class func setValue(_ value: Any?, forUndefinedKey key: String) {
        STBaseModel.st_debugPrint(content: "⚠️ ⚠️ Key = \(key) isUndefinedKey ⚠️ ⚠️")
    }

    open override func setValue(_ value: Any?, forUndefinedKey key: String) {
        STBaseModel.st_debugPrint(content: "⚠️ ⚠️ Key = \(key) isUndefinedKey ⚠️ ⚠️")
    }
    
    // MARK: - 动态方法解析
    open override class func resolveInstanceMethod(_ sel: Selector!) -> Bool {
        if let aMethod = class_getInstanceMethod(self, NSSelectorFromString("st_unrecognizedSelectorSentToInstance")) {
            class_addMethod(self, sel, method_getImplementation(aMethod), method_getTypeEncoding(aMethod))
            return true
        }
        return super.resolveInstanceMethod(sel)
    }
    
    open override class func resolveClassMethod(_ sel: Selector!) -> Bool {
        if let aMethod = class_getClassMethod(self, NSSelectorFromString("st_unrecognizedSelectorSentToClass")) {
            class_addMethod(self, sel, method_getImplementation(aMethod), method_getTypeEncoding(aMethod))
            return true
        }
        return super.resolveClassMethod(sel)
    }
    
    // MARK: - 工具方法
    private func st_unrecognizedSelectorSentToInstance() {
        STBaseModel.st_debugPrint(content: "unrecognized selector sent to Instance")
    }
    
    private class func st_unrecognizedSelectorSentToClass() {
        STBaseModel.st_debugPrint(content: "unrecognized selector sent to class")
    }
    
    private class func st_debugPrint(content: String) {
#if DEBUG
        print(content)
#endif
    }
    
    // MARK: - 基础模型工具
    
    /// 获取模型的所有属性名称
    open class func st_propertyNames() -> [String] {
        var count: UInt32 = 0
        let properties = class_copyPropertyList(self, &count)
        var propertyNames: [String] = []
        
        for i in 0..<Int(count) {
            if let property = properties?[i] {
                let name = String(cString: property_getName(property))
                propertyNames.append(name)
            }
        }
        
        free(properties)
        return propertyNames
    }
    
    /// 获取当前实例的所有属性名称
    open func st_propertyNames() -> [String] {
        return type(of: self).st_propertyNames()
    }
    
    /// 将模型转换为字典
    open func st_toDictionary() -> [String: Any] {
        if st_isFlexibleMode {
            return st_processedData
        }
        
        var dict: [String: Any] = [:]
        let properties = self.st_propertyNames()
        
        for propertyName in properties {
            if let value = self.value(forKey: propertyName) {
                dict[propertyName] = value
            }
        }
        
        return dict
    }
    
    /// 从字典更新模型属性
    open func st_update(from dictionary: [String: Any]) {
        if st_isFlexibleMode {
            st_updateFlexible(from: dictionary)
        } else {
            st_updateStandard(from: dictionary)
        }
    }
    
    /// 清空所有数据
    private func st_clearAllData() {
        st_rawData.removeAll()
        st_processedData.removeAll()
    }
    
    /// 标准模式更新
    private func st_updateStandard(from dictionary: [String: Any]) {
        st_clearAllData()
        for (key, value) in dictionary {
            if self.responds(to: NSSelectorFromString("set\(key.prefix(1).uppercased() + key.dropFirst()):")) {
                self.setValue(value, forKey: key)
            }
        }
    }
    
    /// 灵活模式更新
    private func st_updateFlexible(from dictionary: [String: Any]) {
        st_clearAllData()
        for (key, value) in dictionary {
            st_rawData[key] = STFlexibleValue(value)
        }
        st_processRawData()
    }
    
    /// 处理原始数据
    private func st_processRawData() {
        st_processedData.removeAll()
        
        for (key, flexibleValue) in st_rawData {
            switch flexibleValue {
            case .string(let value):
                st_processedData[key] = value
            case .int(let value):
                st_processedData[key] = value
            case .double(let value):
                st_processedData[key] = value
            case .bool(let value):
                st_processedData[key] = value
            case .array(let value):
                st_processedData[key] = value.map { $0.value }
            case .dictionary(let value):
                st_processedData[key] = value.mapValues { $0.value }
            case .null:
                st_processedData[key] = NSNull()
            }
        }
    }
    
    // MARK: - 灵活模式数据访问
    
    /// 获取原始值
    open func st_getRawValue(forKey key: String) -> STFlexibleValue? {
        guard st_isFlexibleMode else { return nil }
        return st_rawData[key]
    }
    
    /// 获取处理后的值
    open func st_getValue(forKey key: String) -> Any? {
        guard st_isFlexibleMode else { return nil }
        return st_processedData[key]
    }
    
    /// 安全获取字符串值
    open func st_getString(forKey key: String, default: String = "") -> String {
        guard st_isFlexibleMode else { return `default` }
        return st_rawData[key]?.st_stringValue(default: `default`) ?? `default`
    }
    
    /// 安全获取整数值
    open func st_getInt(forKey key: String, default: Int = 0) -> Int {
        guard st_isFlexibleMode else { return `default` }
        return st_rawData[key]?.st_intValue(default: `default`) ?? `default`
    }
    
    /// 安全获取双精度值
    open func st_getDouble(forKey key: String, default: Double = 0.0) -> Double {
        guard st_isFlexibleMode else { return `default` }
        return st_rawData[key]?.st_doubleValue(default: `default`) ?? `default`
    }
    
    /// 安全获取布尔值
    open func st_getBool(forKey key: String, default: Bool = false) -> Bool {
        guard st_isFlexibleMode else { return `default` }
        return st_rawData[key]?.st_boolValue(default: `default`) ?? `default`
    }
    
    /// 安全获取数组值
    open func st_getArray(forKey key: String, default: [STFlexibleValue] = []) -> [STFlexibleValue] {
        guard st_isFlexibleMode else { return `default` }
        return st_rawData[key]?.st_arrayValue(default: `default`) ?? `default`
    }
    
    /// 安全获取字典值
    open func st_getDictionary(forKey key: String, default: [String: STFlexibleValue] = [:]) -> [String: STFlexibleValue] {
        guard st_isFlexibleMode else { return `default` }
        return st_rawData[key]?.st_dictionaryValue(default: `default`) ?? `default`
    }
    
    // MARK: - 灵活模式工具方法
    
    /// 转换为原始数据字典
    open func st_toRawDictionary() -> [String: STFlexibleValue] {
        guard st_isFlexibleMode else { return [:] }
        return st_rawData
    }
    
    /// 获取所有键
    open func st_getAllKeys() -> [String] {
        guard st_isFlexibleMode else { return [] }
        return Array(st_rawData.keys)
    }
    
    /// 检查是否包含键
    open func st_containsKey(_ key: String) -> Bool {
        guard st_isFlexibleMode else { return false }
        return st_rawData.keys.contains(key)
    }
    
    /// 获取数据类型
    open func st_getValueType(forKey key: String) -> String {
        guard st_isFlexibleMode, let value = st_rawData[key] else { return "undefined" }
        
        switch value {
        case .string: return "String"
        case .int: return "Int"
        case .double: return "Double"
        case .bool: return "Bool"
        case .array: return "Array"
        case .dictionary: return "Dictionary"
        case .null: return "Null"
        }
    }
    
    // MARK: - 模型描述
    open override var description: String {
        if st_isFlexibleMode {
            let className = String(describing: type(of: self))
            let keys = st_getAllKeys()
            var desc = "\(className) {\n"
            for key in keys {
                let value = st_getValue(forKey: key)
                desc += "  \(key): \(value)\n"
            }
            desc += "}"
            return desc
        } else {
            let className = String(describing: type(of: self))
            let properties = self.st_propertyNames()
            var desc = "\(className) {\n"
            for propertyName in properties {
                if let value = self.value(forKey: propertyName) {
                    desc += "  \(propertyName): \(value)\n"
                }
            }
            desc += "}"
            return desc
        }
    }
    
    /// 模型调试描述
    open override var debugDescription: String {
        return description
    }
    
    // MARK: - 复制和相等性
    open func st_copy() -> Any {
        let newInstance = type(of: self).init()
        if st_isFlexibleMode {
            newInstance.st_isFlexibleMode = true
            newInstance.st_update(from: st_toDictionary())
        } else {
            newInstance.st_update(from: st_toDictionary())
        }
        return newInstance
    }
    
    open override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? STBaseModel else { return false }
        let selfDict = self.st_toDictionary()
        let otherDict = other.st_toDictionary()
        return NSDictionary(dictionary: selfDict).isEqual(to: otherDict)
    }
    
    open override var hash: Int {
        return st_toDictionary().hashValue
    }
    
    // MARK: - 测试和调试方法
#if DEBUG
    /// 测试数据清理功能（仅DEBUG模式可用）
    open func st_testDataCleanup() {
        print("=== 数据清理测试 ===")
        
        // 第一次更新
        let data1 = ["name": "John", "age": 30, "city": "New York"]
        st_update(from: data1)
        print("第一次更新后键数量: \(st_getAllKeys().count)")
        print("第一次更新后键: \(st_getAllKeys())")
        
        // 第二次更新
        let data2 = ["title": "Developer", "salary": 50000, "experience": 5]
        st_update(from: data2)
        print("第二次更新后键数量: \(st_getAllKeys().count)")
        print("第二次更新后键: \(st_getAllKeys())")
        
        // 验证旧数据是否被清理
        let oldKeys = ["name", "age", "city"]
        let hasOldData = oldKeys.contains { st_containsKey($0) }
        print("是否包含旧数据: \(hasOldData)")
        
        print("=== 测试完成 ===\n")
    }
#endif
}

// MARK: - 网络响应模型
open class STBaseResponseModel<T: STBaseModel>: STBaseModel {
    
    /// 响应状态码
    open var st_code: Int {
        if st_isFlexibleMode {
            return st_getInt(forKey: "code", default: -1)
        }
        return 0
    }
    
    /// 响应消息
    open var st_message: String {
        if st_isFlexibleMode {
            return st_getString(forKey: "message", default: "")
        }
        return ""
    }
    
    /// 响应数据
    open var st_data: T? {
        if st_isFlexibleMode {
            if let dataDict = st_getDictionary(forKey: "data") {
                let model = T()
                model.st_isFlexibleMode = true
                var normalDict: [String: Any] = [:]
                for (key, value) in dataDict {
                    normalDict[key] = value.value
                }
                model.st_update(from: normalDict)
                return model
            }
        }
        return nil
    }
    
    /// 时间戳
    open var st_timestamp: TimeInterval {
        if st_isFlexibleMode {
            return st_getDouble(forKey: "timestamp", default: 0.0)
        }
        return 0.0
    }
    
    /// 是否成功
    open var st_isSuccess: Bool {
        return st_code == 200 || st_code == 0
    }
}

// MARK: - 分页响应模型
open class STBasePaginationModel<T: STBaseModel>: STBaseResponseModel<T> {
    
    /// 当前页码
    open var st_page: Int {
        return st_getInt(forKey: "page", default: 1)
    }
    
    /// 每页大小
    open var st_pageSize: Int {
        return st_getInt(forKey: "pageSize", default: 20)
    }
    
    /// 总数量
    open var st_totalCount: Int {
        return st_getInt(forKey: "totalCount", default: 0)
    }
    
    /// 总页数
    open var st_totalPages: Int {
        return st_getInt(forKey: "totalPages", default: 0)
    }
    
    /// 是否有下一页
    open var st_hasNextPage: Bool {
        return st_getBool(forKey: "hasNextPage", default: false)
    }
    
    /// 是否有上一页
    open var st_hasPreviousPage: Bool {
        return st_getBool(forKey: "hasPreviousPage", default: false)
    }
    
    /// 数据列表
    open var st_list: [T] {
        if let listArray = st_getArray(forKey: "list") {
            var items: [T] = []
            
            for item in listArray {
                if case .dictionary(let dict) = item {
                    let model = T()
                    model.st_isFlexibleMode = true
                    var normalDict: [String: Any] = [:]
                    for (key, value) in dict {
                        normalDict[key] = value.value
                    }
                    model.st_update(from: normalDict)
                    items.append(model)
                }
            }
            
            return items
        }
        return []
    }
}

// MARK: - Codable 支持
extension STBaseModel: Codable {
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: STCodingKeys.self)
        let properties = self.st_propertyNames()
        
        for propertyName in properties {
            if let value = self.value(forKey: propertyName) {
                try container.encode(STAnyCodable(value), forKey: STCodingKeys(stringValue: propertyName)!)
            }
        }
    }
    
    public required init(from decoder: Decoder) throws {
        super.init()
        let container = try decoder.container(keyedBy: STCodingKeys.self)
        let properties = self.st_propertyNames()
        for propertyName in properties {
            if container.contains(STCodingKeys(stringValue: propertyName)!) {
                let anyCodable = try container.decode(STAnyCodable.self, forKey: STCodingKeys(stringValue: propertyName)!)
                self.setValue(anyCodable.value, forKey: propertyName)
            }
        }
    }
}

// MARK: - 编码键
public struct STCodingKeys: CodingKey {
    public let stringValue: String
    public let intValue: Int?

    public init(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    public init(intValue: Int) {
        self.stringValue = String(intValue)
        self.intValue = intValue
    }
}

// MARK: - 任意类型编码支持
public struct STAnyCodable: Codable {
    public let value: Any
    
    public init(_ value: Any) {
        self.value = value
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if container.decodeNil() {
            self.value = NSNull()
        } else if let bool = try? container.decode(Bool.self) {
            self.value = bool
        } else if let int = try? container.decode(Int.self) {
            self.value = int
        } else if let uint = try? container.decode(UInt.self) {
            self.value = uint
        } else if let double = try? container.decode(Double.self) {
            self.value = double
        } else if let string = try? container.decode(String.self) {
            self.value = string
        } else if let array = try? container.decode([STAnyCodable].self) {
            self.value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: STAnyCodable].self) {
            self.value = dictionary.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "STAnyCodable value cannot be decoded")
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch self.value {
        case is NSNull:
            try container.encodeNil()
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let uint as UInt:
            try container.encode(uint)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { STAnyCodable($0) })
        case let dictionary as [String: Any]:
            try container.encode(dictionary.mapValues { STAnyCodable($0) })
        default:
            let context = EncodingError.Context(codingPath: container.codingPath, debugDescription: "STAnyCodable value cannot be encoded")
            throw EncodingError.invalidValue(self.value, context)
        }
    }
}