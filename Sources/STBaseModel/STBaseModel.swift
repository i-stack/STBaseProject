//
//  STBaseModel.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2018/3/14.
//

import Foundation

open class STBaseModel: NSObject {

    private let st_lock = NSLock()

    private func st_withLock<T>(_ body: () throws -> T) rethrows -> T {
        st_lock.lock()
        defer { st_lock.unlock() }
        return try body()
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
        STLog("dealloc: \(String(describing: type(of: self)))", level: .debug)
    }

    public required override init() {
        super.init()
    }

    public required init?(coder: NSCoder) {
        // NSObject 本身没有 init?(coder:)；保留 NSCoding 入口仅是为 storyboard / NSKeyedUnarchiver 流程占位。
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
            self.st_assign(jsonValue: jsonValue,
                           toProperty: propertyName,
                           nestedType: nestedTypes[propertyName])
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

    // MARK: - 工具方法

    /// 子类重写此方法以提供 JSON 键名到属性名的映射
    /// 返回 [JSON键名: 属性名] 的字典
    /// 例如: ["user_name": "userName", "phone_number": "phoneNumber"]
    open class func st_keyMapping() -> [String: String] {
        return [:]
    }

    /// 获取反向映射 (属性名 -> JSON键名)，结果按类缓存。
    fileprivate class func st_reverseKeyMapping() -> [String: String] {
        let key = ObjectIdentifier(self)
        st_propertyNamesCacheLock.lock()
        if let cached = st_reverseKeyMappingCache[key] {
            st_propertyNamesCacheLock.unlock()
            return cached
        }
        st_propertyNamesCacheLock.unlock()

        let mapping = st_keyMapping()
        var reversed: [String: String] = [:]
        reversed.reserveCapacity(mapping.count)
        for (jsonKey, propertyName) in mapping {
            reversed[propertyName] = jsonKey
        }

        st_propertyNamesCacheLock.lock()
        st_reverseKeyMappingCache[key] = reversed
        st_propertyNamesCacheLock.unlock()
        return reversed
    }

    /// 子类重写此方法以声明嵌套模型类型
    /// 返回 [属性名: 模型类型] 的字典
    /// 例如: ["address": AddressModel.self, "contacts": ContactModel.self]
    open class func st_nestedModelTypes() -> [String: STBaseModel.Type] {
        return [:]
    }

    /// `STBaseModel` 自身声明、不应该出现在 JSON 序列化结果里的内部属性名。
    private static let st_reservedPropertyNames: Set<String> = [
        "st_isFlexibleMode"
    ]

    /// 类级别的属性名缓存，避免每次 encode/decode 都走 runtime 反射。
    private static let st_propertyNamesCacheLock = NSLock()
    private static var st_propertyNamesCache: [ObjectIdentifier: [String]] = [:]
    private static var st_propertyAttributesCache: [ObjectIdentifier: [String: STPropertyType]] = [:]
    private static var st_reverseKeyMappingCache: [ObjectIdentifier: [String: String]] = [:]
    private static var st_optionalPropertyNamesCache: [ObjectIdentifier: Set<String>] = [:]

    /// 获取模型的所有属性名称（沿父类链向上枚举，不会越过 `STBaseModel` 自身）。
    open class func st_propertyNames() -> [String] {
        let key = ObjectIdentifier(self)
        st_propertyNamesCacheLock.lock()
        if let cached = st_propertyNamesCache[key] {
            st_propertyNamesCacheLock.unlock()
            return cached
        }
        st_propertyNamesCacheLock.unlock()

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
                    if st_reservedPropertyNames.contains(name) { continue }
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

        st_propertyNamesCacheLock.lock()
        st_propertyNamesCache[key] = collected
        st_propertyAttributesCache[key] = attributes
        st_propertyNamesCacheLock.unlock()
        return collected
    }

    /// 获取属性的运行时类型描述（已缓存）。
    fileprivate class func st_propertyType(for name: String) -> STPropertyType? {
        // 先确保缓存被构建
        _ = st_propertyNames()
        let key = ObjectIdentifier(self)
        st_propertyNamesCacheLock.lock()
        defer { st_propertyNamesCacheLock.unlock() }
        return st_propertyAttributesCache[key]?[name]
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
        let mapping = type(of: self).st_keyMapping()
        let nestedTypes = type(of: self).st_nestedModelTypes()

        for (key, value) in dictionary {
            let propertyName = mapping[key] ?? key
            guard self.st_hasSetter(for: propertyName) else { continue }

            if let nestedModelType = nestedTypes[propertyName] {
                if let nestedDict = value as? [String: Any] {
                    let nestedModel = nestedModelType.init()
                    nestedModel.st_update(from: nestedDict)
                    self.st_safeSetValue(nestedModel, forProperty: propertyName)
                } else if let nestedArray = value as? [Any] {
                    let models = nestedArray.compactMap { element -> STBaseModel? in
                        guard let dict = element as? [String: Any] else { return nil }
                        let model = nestedModelType.init()
                        model.st_update(from: dict)
                        return model
                    }
                    self.st_safeSetValue(models, forProperty: propertyName)
                } else if value is NSNull {
                    self.st_safeSetValue(nil, forProperty: propertyName)
                } else {
                    self.st_safeSetValue(value, forProperty: propertyName)
                }
            } else if value is NSNull {
                self.st_safeSetValue(nil, forProperty: propertyName)
            } else {
                self.st_safeSetValue(value, forProperty: propertyName)
            }
        }
    }

    /// 判断属性是否拥有 KVC setter，用于过滤只读属性 / 计算属性。
    private func st_hasSetter(for propertyName: String) -> Bool {
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
    private func st_safeSetValue(_ value: Any?, forProperty propertyName: String) {
        guard let value = value else {
            // nil 写入：先按 ObjC type encoding 过滤明确不可空的标量，再用 Mirror 判断对象属性可空性。
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
            // 缺少属性元数据时退回普通 KVC（理论上不会走到，st_hasSetter 已过滤）。
            self.setValue(value, forKey: propertyName)
            return
        }

        if let coerced = type.coerce(value) {
            self.setValue(coerced, forKey: propertyName)
        } else {
            STLog("Type mismatch on property \(propertyName): expected \(type.debugName), got \(Swift.type(of: value))", level: .warning)
        }
    }

    /// 用 Swift `Mirror` 判断某个属性在声明处是否为 `Optional`。结果按类型缓存，
    /// 避免每次 nil 写都重建 Mirror。
    fileprivate class func st_isOptionalProperty(_ propertyName: String) -> Bool {
        let key = ObjectIdentifier(self)
        st_propertyNamesCacheLock.lock()
        if let cached = st_optionalPropertyNamesCache[key] {
            st_propertyNamesCacheLock.unlock()
            return cached.contains(propertyName)
        }
        st_propertyNamesCacheLock.unlock()

        // 构造一个默认实例用于反射，遍历自身与父类的所有 Swift 声明属性。
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

        st_propertyNamesCacheLock.lock()
        st_optionalPropertyNamesCache[key] = optionals
        st_propertyNamesCacheLock.unlock()
        return optionals.contains(propertyName)
    }

    /// 把 `STJSONValue` 写到 KVC 属性，必要时构造嵌套 `STBaseModel`。
    /// 用于 `init(from decoder:)` 这条入口。
    private func st_assign(jsonValue: STJSONValue,
                           toProperty propertyName: String,
                           nestedType: STBaseModel.Type?) {
        guard self.st_hasSetter(for: propertyName) else { return }

        if let nestedType = nestedType {
            switch jsonValue {
            case .object(let dict):
                let nestedModel = nestedType.init()
                nestedModel.st_update(from: dict.mapValues { $0.value })
                self.st_safeSetValue(nestedModel, forProperty: propertyName)
            case .array(let items):
                let models = items.compactMap { item -> STBaseModel? in
                    guard case .object(let dict) = item else { return nil }
                    let model = nestedType.init()
                    model.st_update(from: dict.mapValues { $0.value })
                    return model
                }
                self.st_safeSetValue(models, forProperty: propertyName)
            case .null:
                self.st_safeSetValue(nil, forProperty: propertyName)
            default:
                self.st_safeSetValue(jsonValue.value, forProperty: propertyName)
            }
            return
        }

        switch jsonValue {
        case .null:
            self.st_safeSetValue(nil, forProperty: propertyName)
        default:
            self.st_safeSetValue(jsonValue.value, forProperty: propertyName)
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
        guard self.st_assertFlexibleMode(api: #function) else { return nil }
        return self.st_rawData[key]
    }

    /// 获取处理后的值
    open func st_getValue(forKey key: String) -> Any? {
        guard self.st_assertFlexibleMode(api: #function) else { return nil }
        return self.st_processedData[key]
    }

    /// 安全获取字符串值
    open func st_getString(forKey key: String, default defaultValue: String = "") -> String {
        guard self.st_assertFlexibleMode(api: #function) else { return defaultValue }
        return self.st_rawData[key]?.string(or: defaultValue) ?? defaultValue
    }

    /// 安全获取整数值
    open func st_getInt(forKey key: String, default defaultValue: Int = 0) -> Int {
        guard self.st_assertFlexibleMode(api: #function) else { return defaultValue }
        return self.st_rawData[key]?.int(or: defaultValue) ?? defaultValue
    }

    /// 安全获取双精度值
    open func st_getDouble(forKey key: String, default defaultValue: Double = 0.0) -> Double {
        guard self.st_assertFlexibleMode(api: #function) else { return defaultValue }
        return self.st_rawData[key]?.double(or: defaultValue) ?? defaultValue
    }

    /// 安全获取布尔值
    open func st_getBool(forKey key: String, default defaultValue: Bool = false) -> Bool {
        guard self.st_assertFlexibleMode(api: #function) else { return defaultValue }
        return self.st_rawData[key]?.bool(or: defaultValue) ?? defaultValue
    }

    /// 安全获取数组值
    open func st_getArray(forKey key: String, default defaultValue: [STJSONValue] = []) -> [STJSONValue] {
        guard self.st_assertFlexibleMode(api: #function) else { return defaultValue }
        return self.st_rawData[key]?.array(or: defaultValue) ?? defaultValue
    }

    /// 安全获取字典值
    open func st_getDictionary(forKey key: String, default defaultValue: [String: STJSONValue] = [:]) -> [String: STJSONValue] {
        guard self.st_assertFlexibleMode(api: #function) else { return defaultValue }
        return self.st_rawData[key]?.object(or: defaultValue) ?? defaultValue
    }

    /// 转换为原始数据字典
    open func st_toRawDictionary() -> [String: STJSONValue] {
        guard self.st_assertFlexibleMode(api: #function) else { return [:] }
        return self.st_rawData
    }

    /// 获取所有键
    open func st_getAllKeys() -> [String] {
        guard self.st_assertFlexibleMode(api: #function) else { return [] }
        return Array(self.st_rawData.keys)
    }

    /// 检查是否包含键
    open func st_containsKey(_ key: String) -> Bool {
        guard self.st_assertFlexibleMode(api: #function) else { return false }
        return self.st_rawData.keys.contains(key)
    }

    /// 这些 API 仅在灵活模式下生效；非灵活模式调用属于编程错误，DEBUG 下断言提示，
    /// Release 下记录警告日志并返回默认值。
    @inline(__always)
    private func st_assertFlexibleMode(api: String) -> Bool {
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
    open func st_valueKind(forKey key: String) -> STValueKind {
        guard self.st_isFlexibleMode, let value = self.st_rawData[key] else { return .undefined }
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
    open func st_getValueType(forKey key: String) -> String {
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

    /// 深拷贝模型（正确处理子类类型）。
    ///
    /// 语义：
    /// - 返回与原对象同子类类型的全新实例；
    /// - 标准模式：嵌套属性（`STBaseModel` / `[STBaseModel]` / `[String: STBaseModel]`）递归 `st_copy()`；
    /// - 灵活模式：`_st_rawData` 由 `STJSONValue` 枚举值组成（值语义），通过 `st_update(from:)` 重建即可；
    /// - 标量 / 不可变值类型（`String`、`Int` 等）直接复用，不做克隆。
    open func st_copy() -> STBaseModel {
        let newInstance = type(of: self).init()
        newInstance.st_isFlexibleMode = self.st_isFlexibleMode

        if self.st_isFlexibleMode {
            // STJSONValue 是值类型，rawData 字典里的所有节点都是 deep-by-value，st_update 会重建。
            newInstance.st_update(from: self.st_toDictionary())
            return newInstance
        }

        // 标准模式：逐属性递归深拷贝。
        let properties = self.st_propertyNames()
        for propertyName in properties {
            guard let value = self.value(forKey: propertyName) else { continue }
            let copied = STBaseModel.st_deepCopy(value: value)
            newInstance.st_safeSetValue(copied, forProperty: propertyName)
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
            // 同上，必须早于 [String: Any] 分支。
            let copy = NSMutableDictionary(capacity: mutableDict.count)
            for (k, v) in mutableDict {
                copy.setObject(st_deepCopy(value: v), forKey: k as! NSCopying)
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
        return self.st_normalizedDictionary().isEqual(other.st_normalizedDictionary())
    }

    open override var hash: Int {
        return self.st_normalizedDictionary().hash
    }

    /// 把模型转换为 JSON 友好的、可与 NSDictionary 互比的归一化字典，
    /// 使 `isEqual` 与 `hash` 共用同一份语义，保证 `a == b ⇒ hash(a) == hash(b)`。
    private func st_normalizedDictionary() -> NSDictionary {
        let dict = self.st_toDictionary()
        let normalized = st_normalize(dict) as? [String: Any] ?? [:]
        return NSDictionary(dictionary: normalized)
    }

    /// 递归把任意值标准化为 `NSDictionary` / `NSArray` / `NSObject`。
    private func st_normalize(_ value: Any) -> Any {
        switch value {
        case let model as STBaseModel:
            return model.st_normalizedDictionary()
        case let dict as [String: Any]:
            var result: [String: Any] = [:]
            result.reserveCapacity(dict.count)
            for (key, sub) in dict {
                result[key] = st_normalize(sub)
            }
            return result
        case let array as [Any]:
            return array.map { st_normalize($0) }
        case let jsonValue as STJSONValue:
            return st_normalize(jsonValue.value)
        case is NSNull:
            return NSNull()
        default:
            return value as? NSObject ?? NSString(string: String(describing: value))
        }
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
                guard let value = self.value(forKey: propertyName) else { continue }
                let jsonKey = reverseMapping[propertyName] ?? propertyName
                let codingKey = STCodingKeys(stringValue: jsonKey)
                // 优先识别嵌套模型 / 嵌套模型数组 / 嵌套模型字典，递归编码而不是退化成字符串。
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
    /// 属性是否允许 nil（对象类型恒允许；带 _Nullable 标记的也允许）。
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
        // 没有具体类名（裸 id）时直接接受
        guard let className = expectedClassName else { return value }
        let resolvedClass: AnyClass? = NSClassFromString(className)
        // 已经是期望类
        if let cls = resolvedClass,
           let object = value as? NSObject, object.isKind(of: cls) {
            return object
        }
        // 数字 -> NSString 等常见容错
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
            // Swift 的 [Any] 通过 KVC 写入会桥接成不可变的 _SwiftDeferredNSArray，
            // 属性声明为 NSMutableArray 时再调用 .add(_:) 会因不识别 selector 崩溃。
            // 显式构造可变实例保证后续 mutation 调用安全。
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
            // 类名可被 Obj-C runtime 解析但实例类型不匹配 —— 直接拒绝，
            // 避免 KVC 把错误类型写进 @objc 属性引发后续崩溃。
            if resolvedClass != nil { return nil }
            // 解析不到的类名（纯 Swift 非 @objc 类等）无法校验，放行由 KVC 处理。
            return value
        }
    }
}
