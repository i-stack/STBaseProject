//
//  STBaseModel.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2018/3/14.
//

import Foundation

open class STBaseModel: NSObject {

    private let lock = NSLock()

    private func withLock<T>(_ body: () throws -> T) rethrows -> T {
        self.lock.lock()
        defer { self.lock.unlock() }
        return try body()
    }

    /// 存储原始数据
    private var rawDataStorage: [String: STJSONValue] = [:]

    /// 存储处理后的数据
    private var processedDataStorage: [String: Any] = [:]

    /// 线程安全的原始数据访问
    private var rawData: [String: STJSONValue] {
        get { withLock { rawDataStorage } }
        set { withLock { rawDataStorage = newValue } }
    }

    /// 线程安全的处理数据访问
    private var processedData: [String: Any] {
        get { withLock { processedDataStorage } }
        set { withLock { processedDataStorage = newValue } }
    }

    /// 是否启用灵活模式
    open var st_isFlexibleMode: Bool = false

    deinit {
        STLog("dealloc: \(String(describing: type(of: self)))", level: .debug)
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
        let reverseMapping = type(of: self).st_reverseKeyMapping()
        let nestedTypes = type(of: self).st_nestedModelTypes()
        for propertyName in properties {
            let jsonKey = reverseMapping[propertyName] ?? propertyName
            let codingKey = STCodingKeys(stringValue: jsonKey)
            guard container.contains(codingKey) else { continue }
            let jsonValue = try container.decode(STJSONValue.self, forKey: codingKey)
            self.assign(jsonValue: jsonValue,
                        toProperty: propertyName,
                        nestedType: nestedTypes[propertyName])
        }
    }

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

    /// 子类重写此方法以提供 JSON 键名到属性名的映射
    /// 返回 [JSON键名: 属性名] 的字典
    /// 例如: ["user_name": "userName", "phone_number": "phoneNumber"]
    open class func st_keyMapping() -> [String: String] {
        return [:]
    }

    /// 获取反向映射 (属性名 -> JSON键名)，结果按类缓存。
    fileprivate class func st_reverseKeyMapping() -> [String: String] {
        let key = ObjectIdentifier(self)
        propertyNamesCacheLock.lock()
        if let cached = reverseKeyMappingCache[key] {
            propertyNamesCacheLock.unlock()
            return cached
        }
        propertyNamesCacheLock.unlock()
        let mapping = st_keyMapping()
        var reversed: [String: String] = [:]
        reversed.reserveCapacity(mapping.count)
        for (jsonKey, propertyName) in mapping {
            reversed[propertyName] = jsonKey
        }
        propertyNamesCacheLock.lock()
        reverseKeyMappingCache[key] = reversed
        propertyNamesCacheLock.unlock()
        return reversed
    }

    /// 子类重写此方法以声明嵌套模型类型
    /// 返回 [属性名: 模型类型] 的字典
    /// 例如: ["address": AddressModel.self, "contacts": ContactModel.self]
    open class func st_nestedModelTypes() -> [String: STBaseModel.Type] {
        return [:]
    }

    /// `STBaseModel` 自身声明、不应该出现在 JSON 序列化结果里的内部属性名。
    private static let reservedPropertyNames: Set<String> = [
        "st_isFlexibleMode"
    ]

    /// 类级别的属性名缓存，避免每次 encode/decode 都走 runtime 反射。
    private static let propertyNamesCacheLock = NSLock()
    private static var propertyNamesCache: [ObjectIdentifier: [String]] = [:]
    private static var propertyAttributesCache: [ObjectIdentifier: [String: STPropertyType]] = [:]
    private static var reverseKeyMappingCache: [ObjectIdentifier: [String: String]] = [:]
    private static var optionalPropertyNamesCache: [ObjectIdentifier: Set<String>] = [:]

    /// 获取模型的所有属性名称（沿父类链向上枚举，不会越过 `STBaseModel` 自身）。
    public class func st_propertyNames() -> [String] {
        let key = ObjectIdentifier(self)
        propertyNamesCacheLock.lock()
        if let cached = propertyNamesCache[key] {
            propertyNamesCacheLock.unlock()
            return cached
        }
        propertyNamesCacheLock.unlock()
        var collected: [String] = []
        var attributes: [String: STPropertyType] = [:]
        var seen = Set<String>()
        var current: AnyClass? = self
        while let cls = current, cls !== STBaseModel.self {
            var count: UInt32 = 0
            if let properties = class_copyPropertyList(cls, &count) {
                for i in 0..<Int(count) {
                    let property = properties[i]
                    let name = String(cString: property_getName(property))
                    if reservedPropertyNames.contains(name) { continue }
                    if seen.insert(name).inserted {
                        collected.append(name)
                        let attrs = property_getAttributes(property).flatMap { String(cString: $0) } ?? ""
                        attributes[name] = STPropertyType(attributes: attrs)
                    }
                }
                free(properties)
            }
            current = class_getSuperclass(cls)
        }
        propertyNamesCacheLock.lock()
        propertyNamesCache[key] = collected
        propertyAttributesCache[key] = attributes
        propertyNamesCacheLock.unlock()
        return collected
    }

    /// 获取属性的运行时类型描述（已缓存）。
    fileprivate class func st_propertyType(for name: String) -> STPropertyType? {
        _ = st_propertyNames()
        let key = ObjectIdentifier(self)
        propertyNamesCacheLock.lock()
        defer { propertyNamesCacheLock.unlock() }
        return propertyAttributesCache[key]?[name]
    }

    /// 获取当前实例的所有属性名称
    public func st_propertyNames() -> [String] {
        return type(of: self).st_propertyNames()
    }

    public func st_toDictionary() -> [String: Any] {
        if self.st_isFlexibleMode {
            return self.processedData
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
    public func st_update(from dictionary: [String: Any]) {
        if self.st_isFlexibleMode {
            self.updateFlexible(from: dictionary)
        } else {
            self.updateStandard(from: dictionary)
        }
    }

    /// 清空所有数据
    private func clearAllData() {
        self.rawDataStorage.removeAll()
        self.processedDataStorage.removeAll()
    }

    /// 标准模式更新
    private func updateStandard(from dictionary: [String: Any]) {
        let mapping = type(of: self).st_keyMapping()
        let nestedTypes = type(of: self).st_nestedModelTypes()
        for (key, value) in dictionary {
            let propertyName = mapping[key] ?? key
            guard self.hasSetter(for: propertyName) else { continue }
            if let nestedModelType = nestedTypes[propertyName] {
                if let nestedDict = value as? [String: Any] {
                    let nestedModel = nestedModelType.init()
                    nestedModel.st_update(from: nestedDict)
                    self.safeSetValue(nestedModel, forProperty: propertyName)
                } else if let nestedArray = value as? [Any] {
                    let models = nestedArray.compactMap { element -> STBaseModel? in
                        guard let dict = element as? [String: Any] else { return nil }
                        let model = nestedModelType.init()
                        model.st_update(from: dict)
                        return model
                    }
                    self.safeSetValue(models, forProperty: propertyName)
                } else if value is NSNull {
                    self.safeSetValue(nil, forProperty: propertyName)
                } else {
                    self.safeSetValue(value, forProperty: propertyName)
                }
            } else if value is NSNull {
                self.safeSetValue(nil, forProperty: propertyName)
            } else {
                self.safeSetValue(value, forProperty: propertyName)
            }
        }
    }

    /// 判断属性是否拥有 KVC setter，用于过滤只读属性 / 计算属性。
    private func hasSetter(for propertyName: String) -> Bool {
        guard let first = propertyName.first else { return false }
        let setterName = "set\(first.uppercased())\(propertyName.dropFirst()):"
        return self.responds(to: NSSelectorFromString(setterName))
    }

    /// 类型安全的 KVC 写入：在写入前根据属性 ObjC type encoding 做校验/转换，
    /// 避免直接 `setValue(_:forKey:)` 因为类型不匹配触发 `NSInvalidArgumentException` 而崩溃。
    ///
    /// nil 写入策略（对象类型）：Obj-C runtime attributes 没有稳定的 nullability 信息，但 Swift
    /// `Mirror` 可以按声明类型看出 Optional。只有声明为 Optional 的对象属性才允许 KVC 写 nil；
    /// 非 Optional 引用属性（`@objc var foo: Foo = Foo()`）写 nil 会导致后续访问崩溃，这里跳过。
    private func safeSetValue(_ value: Any?, forProperty propertyName: String) {
        guard let value = value else {
            if let type = type(of: self).st_propertyType(for: propertyName), !type.allowsNil {
                STLog("Skip setting nil to non-optional property: \(propertyName)", level: .warning)
                return
            }
            if !type(of: self).st_isOptionalProperty(propertyName) {
                STLog("Skip writing nil to non-optional reference property: \(propertyName)", level: .warning)
                return
            }
            self.setValue(nil, forKey: propertyName)
            return
        }
        guard let type = type(of: self).st_propertyType(for: propertyName) else {
            self.setValue(value, forKey: propertyName)
            return
        }
        if let coerced = type.coerce(value) {
            self.setValue(coerced, forKey: propertyName)
        } else {
            STLog("Type mismatch on property \(propertyName): expected \(type.debugName), got \(Swift.type(of: value))", level: .warning)
        }
    }

    fileprivate class func st_isOptionalProperty(_ propertyName: String) -> Bool {
        let key = ObjectIdentifier(self)
        propertyNamesCacheLock.lock()
        if let cached = optionalPropertyNamesCache[key] {
            propertyNamesCacheLock.unlock()
            return cached.contains(propertyName)
        }
        propertyNamesCacheLock.unlock()
        let instance = self.init()
        var optionals: Set<String> = []
        var mirror: Mirror? = Mirror(reflecting: instance)
        while let m = mirror {
            for child in m.children {
                guard let label = child.label else { continue }
                if Mirror(reflecting: child.value).displayStyle == .optional {
                    optionals.insert(label)
                }
            }
            mirror = m.superclassMirror
        }
        propertyNamesCacheLock.lock()
        optionalPropertyNamesCache[key] = optionals
        propertyNamesCacheLock.unlock()
        return optionals.contains(propertyName)
    }

    /// 把 `STJSONValue` 写到 KVC 属性，必要时构造嵌套 `STBaseModel`。
    /// 用于 `init(from decoder:)` 这条入口。
    private func assign(jsonValue: STJSONValue, toProperty propertyName: String, nestedType: STBaseModel.Type?) {
        guard self.hasSetter(for: propertyName) else { return }
        if let nestedType = nestedType {
            switch jsonValue {
            case .object(let dict):
                let nestedModel = nestedType.init()
                nestedModel.st_update(from: dict.mapValues { $0.value })
                self.safeSetValue(nestedModel, forProperty: propertyName)
            case .array(let items):
                let models = items.compactMap { item -> STBaseModel? in
                    guard case .object(let dict) = item else { return nil }
                    let model = nestedType.init()
                    model.st_update(from: dict.mapValues { $0.value })
                    return model
                }
                self.safeSetValue(models, forProperty: propertyName)
            case .null:
                self.safeSetValue(nil, forProperty: propertyName)
            default:
                self.safeSetValue(jsonValue.value, forProperty: propertyName)
            }
            return
        }
        switch jsonValue {
        case .null:
            self.safeSetValue(nil, forProperty: propertyName)
        default:
            self.safeSetValue(jsonValue.value, forProperty: propertyName)
        }
    }

    private func updateFlexible(from dictionary: [String: Any]) {
        withLock {
            self.clearAllData()
            for (key, value) in dictionary {
                self.rawDataStorage[key] = STJSONValue(value)
            }
            self.processRawData()
        }
    }

    /// 处理原始数据
    private func processRawData() {
        self.processedDataStorage.removeAll()
        for (key, jsonValue) in self.rawDataStorage {
            switch jsonValue {
            case .string(let value):
                self.processedDataStorage[key] = value
            case .int(let value):
                self.processedDataStorage[key] = value
            case .double(let value):
                self.processedDataStorage[key] = value
            case .bool(let value):
                self.processedDataStorage[key] = value
            case .array(let value):
                self.processedDataStorage[key] = value.map { $0.value }
            case .object(let value):
                self.processedDataStorage[key] = value.mapValues { $0.value }
            case .null:
                self.processedDataStorage[key] = NSNull()
            }
        }
    }

    /// 获取原始值
    public func st_getRawValue(forKey key: String) -> STJSONValue? {
        guard self.assertFlexibleMode(api: #function) else { return nil }
        return self.rawData[key]
    }

    /// 获取处理后的值
    public func st_getValue(forKey key: String) -> Any? {
        guard self.assertFlexibleMode(api: #function) else { return nil }
        return self.processedData[key]
    }

    /// 安全获取字符串值
    public func st_getString(forKey key: String, default defaultValue: String = "") -> String {
        guard self.assertFlexibleMode(api: #function) else { return defaultValue }
        return self.rawData[key]?.string(or: defaultValue) ?? defaultValue
    }

    /// 安全获取整数值
    public func st_getInt(forKey key: String, default defaultValue: Int = 0) -> Int {
        guard self.assertFlexibleMode(api: #function) else { return defaultValue }
        return self.rawData[key]?.int(or: defaultValue) ?? defaultValue
    }

    /// 安全获取双精度值
    public func st_getDouble(forKey key: String, default defaultValue: Double = 0.0) -> Double {
        guard self.assertFlexibleMode(api: #function) else { return defaultValue }
        return self.rawData[key]?.double(or: defaultValue) ?? defaultValue
    }

    /// 安全获取布尔值
    public func st_getBool(forKey key: String, default defaultValue: Bool = false) -> Bool {
        guard self.assertFlexibleMode(api: #function) else { return defaultValue }
        return self.rawData[key]?.bool(or: defaultValue) ?? defaultValue
    }

    /// 安全获取数组值
    public func st_getArray(forKey key: String, default defaultValue: [STJSONValue] = []) -> [STJSONValue] {
        guard self.assertFlexibleMode(api: #function) else { return defaultValue }
        return self.rawData[key]?.array(or: defaultValue) ?? defaultValue
    }

    /// 安全获取字典值
    public func st_getDictionary(forKey key: String, default defaultValue: [String: STJSONValue] = [:]) -> [String: STJSONValue] {
        guard self.assertFlexibleMode(api: #function) else { return defaultValue }
        return self.rawData[key]?.object(or: defaultValue) ?? defaultValue
    }

    /// 转换为原始数据字典
    public func st_toRawDictionary() -> [String: STJSONValue] {
        guard self.assertFlexibleMode(api: #function) else { return [:] }
        return self.rawData
    }

    /// 获取所有键
    public func st_getAllKeys() -> [String] {
        guard self.assertFlexibleMode(api: #function) else { return [] }
        return Array(self.rawData.keys)
    }

    /// 检查是否包含键
    public func st_containsKey(_ key: String) -> Bool {
        guard self.assertFlexibleMode(api: #function) else { return false }
        return self.rawData.keys.contains(key)
    }

    /// 这些 API 仅在灵活模式下生效；非灵活模式调用属于编程错误，DEBUG 下断言提示，
    /// Release 下记录警告日志并返回默认值。
    @inline(__always)
    private func assertFlexibleMode(api: String) -> Bool {
        if self.st_isFlexibleMode { return true }
        STLog("\(api) requires st_isFlexibleMode == true; returning default value.", level: .warning)
        assertionFailure("\(api) called without enabling st_isFlexibleMode")
        return false
    }

    /// 数据类型枚举（推荐使用，便于 `switch`）。
    public enum STValueKind: String {
        case string
        case int
        case double
        case bool
        case array
        case dictionary
        case null
        case undefined
    }

    /// 获取数据类型枚举值。
    public func st_valueKind(forKey key: String) -> STValueKind {
        guard self.st_isFlexibleMode, let value = self.rawData[key] else { return .undefined }
        switch value {
        case .string: return .string
        case .int: return .int
        case .double: return .double
        case .bool: return .bool
        case .array: return .array
        case .object: return .dictionary
        case .null: return .null
        }
    }

    /// 获取数据类型字符串描述（保留以兼容旧调用方；新代码请用 `st_valueKind`）。
    public func st_getValueType(forKey key: String) -> String {
        switch st_valueKind(forKey: key) {
        case .undefined: return "undefined"
        case .string: return "String"
        case .int: return "Int"
        case .double: return "Double"
        case .bool: return "Bool"
        case .array: return "Array"
        case .dictionary: return "Dictionary"
        case .null: return "Null"
        }
    }

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

    /// 深拷贝模型（正确处理子类类型）。
    ///
    /// 语义：
    /// - 返回与原对象同子类类型的全新实例；
    /// - 标准模式：嵌套属性（`STBaseModel` / `[STBaseModel]` / `[String: STBaseModel]`）递归 `st_copy()`；
    /// - 灵活模式：`rawData` 由 `STJSONValue` 枚举值组成（值语义），通过 `st_update(from:)` 重建即可；
    /// - 标量 / 不可变值类型（`String`、`Int` 等）直接复用，不做克隆。
    public func st_copy() -> STBaseModel {
        let newInstance = type(of: self).init()
        newInstance.st_isFlexibleMode = self.st_isFlexibleMode
        if self.st_isFlexibleMode {
            newInstance.st_update(from: self.st_toDictionary())
            return newInstance
        }
        let properties = self.st_propertyNames()
        for propertyName in properties {
            guard let value = self.value(forKey: propertyName) else { continue }
            let copied = STBaseModel.st_deepCopy(value: value)
            newInstance.safeSetValue(copied, forProperty: propertyName)
        }
        return newInstance
    }

    /// 递归深拷贝任意值；只对需要克隆的类型（`STBaseModel`、容器、可变集合）做实际拷贝。
    fileprivate static func st_deepCopy(value: Any) -> Any {
        switch value {
        case let model as STBaseModel:
            return model.st_copy()
        case let mutableArray as NSMutableArray:
            // 必须放在 [Any] 分支之前：NSMutableArray 可以桥接为 [Any]，若顺序颠倒
            // 这里就永远不会命中，原属性会被换成 Swift 数组，破坏 NSMutableArray 语义。
            let copy = NSMutableArray(capacity: mutableArray.count)
            for element in mutableArray {
                copy.add(st_deepCopy(value: element))
            }
            return copy
        case let mutableDict as NSMutableDictionary:
            let copy = NSMutableDictionary(capacity: mutableDict.count)
            for (k, v) in mutableDict {
                guard let key = k as? NSCopying else {
                    assertionFailure("NSMutableDictionary key does not conform to NSCopying.")
                    continue
                }
                copy.setObject(st_deepCopy(value: v), forKey: key)
            }
            return copy
        case let array as [Any]:
            return array.map { st_deepCopy(value: $0) }
        case let dict as [String: Any]:
            var copied: [String: Any] = [:]
            copied.reserveCapacity(dict.count)
            for (key, sub) in dict {
                copied[key] = st_deepCopy(value: sub)
            }
            return copied
        case let copying as NSCopying:
            // 不可变 Foundation 对象（NSString / NSNumber / NSDate / NSData ...）天然可被共享，
            // 但调用 copy() 在不可变实现上几乎是常量时间，且更安全，避免外界拿到 mutable 子类。
            return copying.copy()
        default:
            return value
        }
    }

    open override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? STBaseModel else { return false }
        guard type(of: self) == type(of: other) else { return false }
        return self.normalizedDictionary().isEqual(other.normalizedDictionary())
    }

    open override var hash: Int {
        return self.normalizedDictionary().hash
    }

    /// 把模型转换为 JSON 友好的、可与 NSDictionary 互比的归一化字典，
    /// 使 `isEqual` 与 `hash` 共用同一份语义，保证 `a == b ⇒ hash(a) == hash(b)`。
    private func normalizedDictionary() -> NSDictionary {
        let dict = self.st_toDictionary()
        let normalized = normalize(dict) as? [String: Any] ?? [:]
        return NSDictionary(dictionary: normalized)
    }

    /// 递归把任意值标准化为 `NSDictionary` / `NSArray` / `NSObject`。
    private func normalize(_ value: Any) -> Any {
        switch value {
        case let model as STBaseModel:
            return model.normalizedDictionary()
        case let dict as [String: Any]:
            var result: [String: Any] = [:]
            result.reserveCapacity(dict.count)
            for (key, sub) in dict {
                result[key] = normalize(sub)
            }
            return result
        case let array as [Any]:
            return array.map { normalize($0) }
        case let jsonValue as STJSONValue:
            return normalize(jsonValue.value)
        case is NSNull:
            return NSNull()
        default:
            return value as? NSObject ?? NSString(string: String(describing: value))
        }
    }

    /// 从字典数组创建模型数组
    public class func st_fromArray(_ array: [[String: Any]]) -> [STBaseModel] {
        return array.map { dict in
            let model = self.init()
            model.st_update(from: dict)
            return model
        }
    }

    /// 从 JSON Data 解析模型数组
    public class func st_fromJSONArray(_ data: Data) -> [STBaseModel]? {
        guard let array = data.jsonArray as? [[String: Any]] else { return nil }
        return st_fromArray(array)
    }
}

// MARK: - Codable 支持
extension STBaseModel: Codable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: STCodingKeys.self)
        if self.st_isFlexibleMode {
            let rawData = self.rawData
            for (key, jsonValue) in rawData {
                try container.encode(jsonValue, forKey: STCodingKeys(stringValue: key))
            }
        } else {
            let properties = self.st_propertyNames()
            let reverseMapping = type(of: self).st_reverseKeyMapping()
            for propertyName in properties {
                guard let value = self.value(forKey: propertyName) else { continue }
                let jsonKey = reverseMapping[propertyName] ?? propertyName
                let codingKey = STCodingKeys(stringValue: jsonKey)
                if let nestedModel = value as? STBaseModel {
                    try container.encode(nestedModel, forKey: codingKey)
                } else if let nestedArray = value as? [STBaseModel] {
                    try container.encode(nestedArray, forKey: codingKey)
                } else if let nestedDict = value as? [String: STBaseModel] {
                    try container.encode(nestedDict, forKey: codingKey)
                } else {
                    try container.encode(STJSONValue(value), forKey: codingKey)
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

// MARK: - 属性类型解析（用于 KVC 类型安全写入）
/// 由 `property_getAttributes` 解析出的、与 KVC 写入兼容性相关的属性类型描述。
fileprivate struct STPropertyType {
    enum Kind {
        case object(className: String?)         // @"NSString" / @"NSArray<...>" / @ (id)
        case block                              // @?
        case bool                               // B / c (BOOL on most ABIs is signed char)
        case integer                            // i, s, q, l, I, S, Q, L
        case floating                           // f, d
        case unknown(String)
    }
    let kind: Kind
    let allowsNil: Bool

    init(attributes: String) {
        // attributes 形如：T@"NSString",&,N,V_name
        // 第一段以 'T' 开头，描述类型编码。
        var typeEncoding = ""
        for component in attributes.split(separator: ",") {
            if component.first == "T" {
                typeEncoding = String(component.dropFirst())
                break
            }
        }
        self.kind = STPropertyType.parseKind(typeEncoding)
        switch self.kind {
        case .object, .block:
            self.allowsNil = true
        default:
            self.allowsNil = false
        }
    }

    private static func parseKind(_ encoding: String) -> Kind {
        guard let first = encoding.first else { return .unknown(encoding) }
        switch first {
        case "@":
            // @"ClassName" 形式
            if encoding.count > 1 {
                let trimmed = encoding.dropFirst()
                if trimmed.first == "\"" {
                    let inner = trimmed.dropFirst().dropLast()
                    // 可能形如 NSArray<NSString *>
                    let className = inner.split(separator: "<").first.map(String.init) ?? String(inner)
                    return .object(className: className)
                }
                if trimmed.first == "?" {
                    return .block
                }
            }
            return .object(className: nil)
        case "B":
            return .bool
        case "c", "C":
            // BOOL 在 64-bit iOS 上是 signed char，无法在编码中区分 BOOL 与 char；
            // 实际项目里 char 类型属性基本不存在，按 bool 处理。
            return .bool
        case "i", "s", "l", "q", "I", "S", "L", "Q":
            return .integer
        case "f", "d":
            return .floating
        default:
            return .unknown(encoding)
        }
    }

    var debugName: String {
        switch kind {
        case .object(let name): return name ?? "id"
        case .block: return "block"
        case .bool: return "Bool"
        case .integer: return "Int"
        case .floating: return "Double"
        case .unknown(let raw): return "unknown(\(raw))"
        }
    }

    /// 把传入值尝试转换为属性接受的形式；不兼容时返回 nil。
    func coerce(_ value: Any) -> Any? {
        switch kind {
        case .object(let className):
            return STPropertyType.coerceObject(value, expectedClassName: className)
        case .block:
            return value
        case .bool:
            if let bool = value as? Bool { return bool }
            if let number = value as? NSNumber { return number.boolValue }
            if let string = value as? String {
                if string.compare("true", options: .caseInsensitive) == .orderedSame { return true }
                if string.compare("false", options: .caseInsensitive) == .orderedSame { return false }
                if string == "1" { return true }
                if string == "0" { return false }
            }
            return nil
        case .integer:
            if let number = value as? NSNumber { return number.intValue }
            if let int = value as? Int { return int }
            if let string = value as? String, let int = Int(string) { return int }
            if let double = value as? Double { return Int(double) }
            return nil
        case .floating:
            if let number = value as? NSNumber { return number.doubleValue }
            if let double = value as? Double { return double }
            if let int = value as? Int { return Double(int) }
            if let string = value as? String, let double = Double(string) { return double }
            return nil
        case .unknown:
            return value
        }
    }

    private static func coerceObject(_ value: Any, expectedClassName: String?) -> Any? {
        guard let className = expectedClassName else { return value }
        let resolvedClass: AnyClass? = NSClassFromString(className)
        if let cls = resolvedClass,
           let object = value as? NSObject, object.isKind(of: cls) {
            return object
        }
        switch className {
        case "NSString":
            if let string = value as? String { return string }
            if let number = value as? NSNumber { return number.stringValue }
            return nil
        case "NSNumber":
            if let number = value as? NSNumber { return number }
            if let int = value as? Int { return NSNumber(value: int) }
            if let double = value as? Double { return NSNumber(value: double) }
            if let bool = value as? Bool { return NSNumber(value: bool) }
            return nil
        case "NSArray":
            return value as? [Any]
        case "NSMutableArray":
            if let mutable = value as? NSMutableArray { return mutable }
            if let array = value as? NSArray { return NSMutableArray(array: array) }
            if let array = value as? [Any] { return NSMutableArray(array: array) }
            return nil
        case "NSDictionary":
            return value as? [AnyHashable: Any]
        case "NSMutableDictionary":
            if let mutable = value as? NSMutableDictionary { return mutable }
            if let dict = value as? NSDictionary { return NSMutableDictionary(dictionary: dict) }
            if let dict = value as? [AnyHashable: Any] { return NSMutableDictionary(dictionary: dict) }
            return nil
        default:
            if resolvedClass != nil { return nil }
            return value
        }
    }
}
