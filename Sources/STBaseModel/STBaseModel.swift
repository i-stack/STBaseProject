//
//  STBaseModel.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2018/3/14.
//

import UIKit
import Foundation

open class STBaseModel: NSObject {
    
    /// 存储原始数据
    private var st_rawData: [String: STJSONValue] = [:]
    
    /// 存储处理后的数据
    private var st_processedData: [String: Any] = [:]
    
    /// 是否启用灵活模式
    open var st_isFlexibleMode: Bool = false

    deinit {
        STBaseModel.st_debugPrint(content: "🌈 -> \(self) 🌈 ----> 🌈 dealloc")
    }
    
    public override init() {
        super.init()
    }
    
    public required init?(coder: NSCoder) {
        super.init()
    }
    
    public required init(from decoder: Decoder) throws {
        super.init()
        let container = try decoder.container(keyedBy: STCodingKeys.self)
        let properties = self.st_propertyNames()
        for propertyName in properties {
            if container.contains(STCodingKeys(stringValue: propertyName)) {
                let anyCodable = try container.decode(STAnyCodable.self, forKey: STCodingKeys(stringValue: propertyName))
                self.setValue(anyCodable.value, forKey: propertyName)
            }
        }
    }
    
    /// 从字典初始化
    public convenience init(from dictionary: [String: Any]) {
        self.init()
        self.st_update(from: dictionary)
    }
    
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
        if self.st_isFlexibleMode {
            return self.st_processedData
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
        if self.st_isFlexibleMode {
            self.st_updateFlexible(from: dictionary)
        } else {
            self.st_updateStandard(from: dictionary)
        }
    }
    
    /// 清空所有数据
    private func st_clearAllData() {
        self.st_rawData.removeAll()
        self.st_processedData.removeAll()
    }
    
    /// 标准模式更新
    private func st_updateStandard(from dictionary: [String: Any]) {
        self.st_clearAllData()
        for (key, value) in dictionary {
            if self.responds(to: NSSelectorFromString("set\(key.prefix(1).uppercased() + key.dropFirst()):")) {
                self.setValue(value, forKey: key)
            }
        }
    }
    
    /// 灵活模式更新
    private func st_updateFlexible(from dictionary: [String: Any]) {
        self.st_clearAllData()
        for (key, value) in dictionary {
            self.st_rawData[key] = STJSONValue(value)
        }
        self.st_processRawData()
    }
    
    /// 处理原始数据
    private func st_processRawData() {
        self.st_processedData.removeAll()
        for (key, jsonValue) in self.st_rawData {
            switch jsonValue {
            case .string(let value):
                self.st_processedData[key] = value
            case .int(let value):
                self.st_processedData[key] = value
            case .double(let value):
                self.st_processedData[key] = value
            case .bool(let value):
                self.st_processedData[key] = value
            case .array(let value):
                self.st_processedData[key] = value.map { $0.value }
            case .object(let value):
                self.st_processedData[key] = value.mapValues { $0.value }
            case .null:
                self.st_processedData[key] = NSNull()
            }
        }
    }
    
    /// 获取原始值
    open func st_getRawValue(forKey key: String) -> STJSONValue? {
        guard self.st_isFlexibleMode else { return nil }
        return self.st_rawData[key]
    }
    
    /// 获取处理后的值
    open func st_getValue(forKey key: String) -> Any? {
        guard self.st_isFlexibleMode else { return nil }
        return self.st_processedData[key]
    }
    
    /// 安全获取字符串值
    open func st_getString(forKey key: String, default: String = "") -> String {
        guard self.st_isFlexibleMode else { return `default` }
        return self.st_rawData[key]?.string(or: `default`) ?? `default`
    }
    
    /// 安全获取整数值
    open func st_getInt(forKey key: String, default: Int = 0) -> Int {
        guard self.st_isFlexibleMode else { return `default` }
        return self.st_rawData[key]?.int(or: `default`) ?? `default`
    }
    
    /// 安全获取双精度值
    open func st_getDouble(forKey key: String, default: Double = 0.0) -> Double {
        guard self.st_isFlexibleMode else { return `default` }
        return self.st_rawData[key]?.double(or: `default`) ?? `default`
    }
    
    /// 安全获取布尔值
    open func st_getBool(forKey key: String, default: Bool = false) -> Bool {
        guard self.st_isFlexibleMode else { return `default` }
        return self.st_rawData[key]?.bool(or: `default`) ?? `default`
    }
    
    /// 安全获取数组值
    open func st_getArray(forKey key: String, default: [STJSONValue] = []) -> [STJSONValue] {
        guard self.st_isFlexibleMode else { return `default` }
        return self.st_rawData[key]?.array(or: `default`) ?? `default`
    }
    
    /// 安全获取字典值
    open func st_getDictionary(forKey key: String, default: [String: STJSONValue] = [:]) -> [String: STJSONValue] {
        guard self.st_isFlexibleMode else { return `default` }
        return self.st_rawData[key]?.object(or: `default`) ?? `default`
    }
        
    /// 转换为原始数据字典
    open func st_toRawDictionary() -> [String: STJSONValue] {
        guard self.st_isFlexibleMode else { return [:] }
        return self.st_rawData
    }
    
    /// 获取所有键
    open func st_getAllKeys() -> [String] {
        guard self.st_isFlexibleMode else { return [] }
        return Array(self.st_rawData.keys)
    }
    
    /// 检查是否包含键
    open func st_containsKey(_ key: String) -> Bool {
        guard self.st_isFlexibleMode else { return false }
        return self.st_rawData.keys.contains(key)
    }
    
    /// 获取数据类型
    open func st_getValueType(forKey key: String) -> String {
        guard self.st_isFlexibleMode, let value = self.st_rawData[key] else { return "undefined" }
        
        switch value {
        case .string: return "String"
        case .int: return "Int"
        case .double: return "Double"
        case .bool: return "Bool"
        case .array: return "Array"
        case .object: return "Dictionary"
        case .null: return "Null"
        }
    }
    
    // MARK: - 模型描述
    open override var description: String {
        if self.st_isFlexibleMode {
            let className = String(describing: type(of: self))
            let keys = self.st_getAllKeys()
            var desc = "\(className) {\n"
            for key in keys {
                let value = self.st_getValue(forKey: key)
                desc += "  \(key): \(value ?? "")\n"
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
        let newInstance = STBaseModel()
        if self.st_isFlexibleMode {
            newInstance.st_isFlexibleMode = true
            newInstance.st_update(from: self.st_toDictionary())
        } else {
            newInstance.st_update(from: self.st_toDictionary())
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
        let dict = self.st_toDictionary()
        var hasher = Hasher()
        for (key, value) in dict.sorted(by: { $0.key < $1.key }) {
            hasher.combine(key)
            if let hashable = value as? AnyHashable {
                hasher.combine(hashable)
            } else {
                hasher.combine(String(describing: value))
            }
        }
        return hasher.finalize()
    }
}

// MARK: - Codable 支持
extension STBaseModel: Codable {
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: STCodingKeys.self)
        let properties = self.st_propertyNames()
        
        for propertyName in properties {
            if let value = self.value(forKey: propertyName) {
                try container.encode(STAnyCodable(value), forKey: STCodingKeys(stringValue: propertyName))
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
