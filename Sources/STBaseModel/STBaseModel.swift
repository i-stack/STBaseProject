//
//  STBaseModel.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2018/3/14.
//

import Foundation

open class STBaseModel: NSObject {

    private let st_lock = NSLock()

    private func st_withLock<T>(_ body: () -> T) -> T {
        st_lock.lock()
        defer { st_lock.unlock() }
        return body()
    }

    /// 存储原始数据
    private var _st_rawData: [String: STJSONValue] = [:]

    /// 存储处理后的数据
    private var _st_processedData: [String: Any] = [:]

    /// 线程安全的原始数据访问
    private var st_rawData: [String: STJSONValue] {
        get { st_withLock { _st_rawData } }
        set { st_withLock { _st_rawData = newValue } }
    }

    /// 线程安全的处理数据访问
    private var st_processedData: [String: Any] {
        get { st_withLock { _st_processedData } }
        set { st_withLock { _st_processedData = newValue } }
    }

    /// 是否启用灵活模式
    open var st_isFlexibleMode: Bool = false

    deinit {
        STLog("dealloc: \(self)", level: .debug)
    }

    public required override init() {
        super.init()
    }

    public required init?(coder: NSCoder) {
        super.init()
    }

    public required init(from decoder: Decoder) throws {
        super.init()
        let container = try decoder.container(keyedBy: STCodingKeys.self)
        let properties = self.st_propertyNames()
        let mapping = type(of: self).st_keyMapping()
        let reverseMapping = type(of: self).st_reverseKeyMapping()

        for propertyName in properties {
            let jsonKey = reverseMapping[propertyName] ?? propertyName
            let codingKey = STCodingKeys(stringValue: jsonKey)
            if container.contains(codingKey) {
                let jsonValue = try container.decode(STJSONValue.self, forKey: codingKey)
                self.setValue(jsonValue.value, forKey: propertyName)
            }
        }
    }

    /// 从字典初始化
    public convenience init(from dictionary: [String: Any]) {
        self.init()
        self.st_update(from: dictionary)
    }

    open override func value(forUndefinedKey key: String) -> Any? {
        STLog("Key = \(key) isValueForUndefinedKey", level: .warning)
        return nil
    }

    open override class func setValue(_ value: Any?, forUndefinedKey key: String) {
        STLog("Key = \(key) isUndefinedKey", level: .warning)
    }

    open override func setValue(_ value: Any?, forUndefinedKey key: String) {
        STLog("Key = \(key) isUndefinedKey", level: .warning)
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
        STLog("unrecognized selector sent to Instance", level: .error)
    }

    private class func st_unrecognizedSelectorSentToClass() {
        STLog("unrecognized selector sent to class", level: .error)
    }

    /// 子类重写此方法以提供 JSON 键名到属性名的映射
    /// 返回 [JSON键名: 属性名] 的字典
    /// 例如: ["user_name": "userName", "phone_number": "phoneNumber"]
    open class func st_keyMapping() -> [String: String] {
        return [:]
    }

    /// 获取反向映射 (属性名 -> JSON键名)
    private class func st_reverseKeyMapping() -> [String: String] {
        let mapping = st_keyMapping()
        var reversed: [String: String] = [:]
        for (jsonKey, propertyName) in mapping {
            reversed[propertyName] = jsonKey
        }
        return reversed
    }

    /// 子类重写此方法以声明嵌套模型类型
    /// 返回 [属性名: 模型类型] 的字典
    /// 例如: ["address": AddressModel.self, "contacts": ContactModel.self]
    open class func st_nestedModelTypes() -> [String: STBaseModel.Type] {
        return [:]
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
        let reverseMapping = type(of: self).st_reverseKeyMapping()
        for propertyName in properties {
            if let value = self.value(forKey: propertyName) {
                let outputKey = reverseMapping[propertyName] ?? propertyName
                dict[outputKey] = value
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
        self._st_rawData.removeAll()
        self._st_processedData.removeAll()
    }

    /// 标准模式更新
    private func st_updateStandard(from dictionary: [String: Any]) {
        st_withLock {
            self.st_clearAllData()
        }
        let mapping = type(of: self).st_keyMapping()
        let nestedTypes = type(of: self).st_nestedModelTypes()

        for (key, value) in dictionary {
            let propertyName = mapping[key] ?? key
            guard self.responds(to: NSSelectorFromString("set\(propertyName.prefix(1).uppercased() + propertyName.dropFirst()):")) else {
                continue
            }

            if let nestedModelType = nestedTypes[propertyName] {
                if let nestedDict = value as? [String: Any] {
                    let nestedModel = nestedModelType.init()
                    nestedModel.st_update(from: nestedDict)
                    self.setValue(nestedModel, forKey: propertyName)
                } else if let nestedArray = value as? [[String: Any]] {
                    let models = nestedArray.map { dict -> STBaseModel in
                        let model = nestedModelType.init()
                        model.st_update(from: dict)
                        return model
                    }
                    self.setValue(models, forKey: propertyName)
                } else {
                    self.setValue(value, forKey: propertyName)
                }
            } else {
                self.setValue(value, forKey: propertyName)
            }
        }
    }

    /// 灵活模式更新
    private func st_updateFlexible(from dictionary: [String: Any]) {
        st_withLock {
            self.st_clearAllData()
            for (key, value) in dictionary {
                self._st_rawData[key] = STJSONValue(value)
            }
            self.st_processRawData()
        }
    }

    /// 处理原始数据
    private func st_processRawData() {
        self._st_processedData.removeAll()
        for (key, jsonValue) in self._st_rawData {
            switch jsonValue {
            case .string(let value):
                self._st_processedData[key] = value
            case .int(let value):
                self._st_processedData[key] = value
            case .double(let value):
                self._st_processedData[key] = value
            case .bool(let value):
                self._st_processedData[key] = value
            case .array(let value):
                self._st_processedData[key] = value.map { $0.value }
            case .object(let value):
                self._st_processedData[key] = value.mapValues { $0.value }
            case .null:
                self._st_processedData[key] = NSNull()
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

    /// 复制模型（正确处理子类类型）
    open func st_copy() -> STBaseModel {
        let newInstance = type(of: self).init()
        newInstance.st_isFlexibleMode = self.st_isFlexibleMode
        newInstance.st_update(from: self.st_toDictionary())
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

    /// 从字典数组创建模型数组
    open class func st_fromArray(_ array: [[String: Any]]) -> [STBaseModel] {
        return array.map { dict in
            let model = self.init()
            model.st_update(from: dict)
            return model
        }
    }

    /// 从 JSON Data 解析模型数组
    open class func st_fromJSONArray(_ data: Data) -> [STBaseModel]? {
        guard let array = data.jsonArray as? [[String: Any]] else { return nil }
        return st_fromArray(array)
    }
}

// MARK: - Codable 支持
extension STBaseModel: Codable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: STCodingKeys.self)
        if self.st_isFlexibleMode {
            let rawData = self.st_rawData
            for (key, jsonValue) in rawData {
                try container.encode(jsonValue, forKey: STCodingKeys(stringValue: key))
            }
        } else {
            let properties = self.st_propertyNames()
            let reverseMapping = type(of: self).st_reverseKeyMapping()
            for propertyName in properties {
                if let value = self.value(forKey: propertyName) {
                    let jsonKey = reverseMapping[propertyName] ?? propertyName
                    let jsonValue = STJSONValue(value)
                    try container.encode(jsonValue, forKey: STCodingKeys(stringValue: jsonKey))
                }
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
