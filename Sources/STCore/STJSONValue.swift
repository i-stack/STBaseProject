//
//  STJSONValue.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2020/5/26.
//

import Foundation

/// JSON 值类型枚举，支持所有 JSON 数据类型
public enum STJSONValue: Codable {
    
    case int(Int)
    case bool(Bool)
    case double(Double)
    case string(String)
    case array([STJSONValue])
    case object([String: STJSONValue])
    case null

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode(Int.self) {
            self = .int(value)
        } else if let value = try? container.decode(Double.self) {
            self = .double(value)
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode([String: STJSONValue].self) {
            self = .object(value)
        } else if let value = try? container.decode([STJSONValue].self) {
            self = .array(value)
        } else {
            throw DecodingError.typeMismatch(
                STJSONValue.self,
                DecodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "Not a valid JSON value"
                )
            )
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .null:
            try container.encodeNil()
        case .string(let value):
            try container.encode(value)
        case .int(let value):
            try container.encode(value)
        case .double(let value):
            try container.encode(value)
        case .bool(let value):
            try container.encode(value)
        case .object(let value):
            try container.encode(value)
        case .array(let value):
            try container.encode(value)
        }
    }
        
    /// 获取字符串值
    public var stringValue: String? {
        switch self {
        case .string(let value): return value
        case .int(let value): return String(value)
        case .double(let value): return String(value)
        case .bool(let value): return String(value)
        default: return nil
        }
    }
    
    /// 获取整数值
    public var intValue: Int? {
        switch self {
        case .int(let value): return value
        case .string(let value): return Int(value)
        case .double(let value): return Int(value)
        case .bool(let value): return value ? 1 : 0
        default: return nil
        }
    }
    
    /// 获取双精度值
    public var doubleValue: Double? {
        switch self {
        case .double(let value): return value
        case .int(let value): return Double(value)
        case .string(let value): return Double(value)
        case .bool(let value): return value ? 1.0 : 0.0
        default: return nil
        }
    }
    
    /// 获取布尔值
    public var boolValue: Bool? {
        switch self {
        case .bool(let value): return value
        case .int(let value): return value != 0
        case .double(let value): return value != 0.0
        case .string(let value): return value.lowercased() == "true" || value == "1"
        default: return nil
        }
    }
    
    /// 获取数组值
    public var arrayValue: [STJSONValue]? {
        switch self {
        case .array(let value): return value
        default: return nil
        }
    }
    
    /// 获取对象值
    public var objectValue: [String: STJSONValue]? {
        switch self {
        case .object(let value): return value
        default: return nil
        }
    }
    
    /// 检查是否为空值
    public var isNull: Bool {
        switch self {
        case .null: return true
        default: return false
        }
    }
    
    /// 获取实际值
    public var value: Any {
        switch self {
        case .string(let value): return value
        case .int(let value): return value
        case .double(let value): return value
        case .bool(let value): return value
        case .array(let value): return value
        case .object(let value): return value
        case .null: return NSNull()
        }
    }
}

// MARK: - 兼容 STFlexibleValue API 扩展
public extension STJSONValue {
    
    /// 转换为字符串（兼容 STFlexibleValue API）
    func st_asString() -> String? {
        return self.stringValue
    }
    
    /// 转换为整数（兼容 STFlexibleValue API）
    func st_asInt() -> Int? {
        return self.intValue
    }
    
    /// 转换为双精度（兼容 STFlexibleValue API）
    func st_asDouble() -> Double? {
        return self.doubleValue
    }
    
    /// 转换为布尔值（兼容 STFlexibleValue API，支持 "1" 检查）
    func st_asBool() -> Bool? {
        switch self {
        case .bool(let value): return value
        case .int(let value): return value != 0
        case .string(let value): return value.lowercased() == "true" || value == "1"
        case .double(let value): return value != 0.0
        default: return nil
        }
    }
    
    /// 转换为数组（兼容 STFlexibleValue API）
    func st_asArray() -> [STJSONValue]? {
        return self.arrayValue
    }
    
    /// 转换为字典（兼容 STFlexibleValue API）
    func st_asDictionary() -> [String: STJSONValue]? {
        return self.objectValue
    }
    
    /// 安全获取字符串值，提供默认值
    func st_stringValue(default defaultValue: String = "") -> String {
        return self.st_asString() ?? defaultValue
    }
    
    /// 安全获取整数值，提供默认值
    func st_intValue(default defaultValue: Int = 0) -> Int {
        return self.st_asInt() ?? defaultValue
    }
    
    /// 安全获取双精度值，提供默认值
    func st_doubleValue(default defaultValue: Double = 0.0) -> Double {
        return self.st_asDouble() ?? defaultValue
    }
    
    /// 安全获取布尔值，提供默认值
    func st_boolValue(default defaultValue: Bool = false) -> Bool {
        return self.st_asBool() ?? defaultValue
    }
    
    /// 安全获取数组值，提供默认值
    func st_arrayValue(default defaultValue: [STJSONValue] = []) -> [STJSONValue] {
        return self.st_asArray() ?? defaultValue
    }
    
    /// 安全获取字典值，提供默认值
    func st_dictionaryValue(default defaultValue: [String: STJSONValue] = [:]) -> [String: STJSONValue] {
        return self.st_asDictionary() ?? defaultValue
    }
}

// MARK: - 从 Any 初始化扩展
public extension STJSONValue {
    
    /// 从任意值创建 STJSONValue
    /// - Parameter value: 任意值
    init(_ value: Any) {
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
            self = .array(array.map { STJSONValue($0) })
        case let dict as [String: Any]:
            self = .object(dict.mapValues { STJSONValue($0) })
        case is NSNull:
            self = .null
        default:
            self = .string(String(describing: value))
        }
    }
}

// MARK: - 可选值扩展
extension Optional {
    func or(_ other: Optional) -> Optional {
        switch self {
        case .none: return other
        case .some: return self
        }
    }
    
    func resolve(with error: @autoclosure () -> Error) throws -> Wrapped {
        switch self {
        case .none: throw error()
        case .some(let wrapped): return wrapped
        }
    }
}

// MARK: - Data JSON 扩展
public extension Data {
        
    /// 转换为 JSON 对象
    /// - Parameter options: JSON 读取选项
    /// - Returns: JSON 对象，失败返回 nil
    func st_toJSONObject(options: JSONSerialization.ReadingOptions = []) -> Any? {
        do {
            return try JSONSerialization.jsonObject(with: self, options: options)
        } catch {
            return nil
        }
    }
    
    /// 转换为字典
    /// - Returns: 字典对象，失败返回 nil
    func st_toDictionary() -> [String: Any]? {
        return st_toJSONObject() as? [String: Any]
    }
    
    /// 转换为数组
    /// - Returns: 数组对象，失败返回 nil
    func st_toArray() -> [Any]? {
        return st_toJSONObject() as? [Any]
    }
    
    /// 从 JSON 对象创建 Data
    /// - Parameters:
    ///   - jsonObject: JSON 对象
    ///   - options: JSON 写入选项
    /// - Returns: Data 对象，失败返回 nil
    static func st_fromJSONObject(_ jsonObject: Any, options: JSONSerialization.WritingOptions = []) -> Data? {
        guard JSONSerialization.isValidJSONObject(jsonObject) else { return nil }
        do {
            return try JSONSerialization.data(withJSONObject: jsonObject, options: options)
        } catch {
            return nil
        }
    }
    
    /// 是否为有效的 JSON 数据
    var st_isValidJSON: Bool {
        return st_toJSONObject() != nil
    }
        
    /// 解码为指定类型
    /// - Parameter type: 目标类型
    /// - Returns: 解码结果
    func st_decode<T: Codable>(_ type: T.Type) -> T? {
        do {
            return try JSONDecoder().decode(type, from: self)
        } catch {
            return nil
        }
    }
    
    /// 解码为指定类型（带错误处理）
    /// - Parameter type: 目标类型
    /// - Returns: 解码结果
    func st_decodeWithError<T: Codable>(_ type: T.Type) -> Result<T, Error> {
        do {
            let result = try JSONDecoder().decode(type, from: self)
            return .success(result)
        } catch {
            return .failure(error)
        }
    }
}

// MARK: - String JSON 扩展
public extension String {
        
    /// 从 JSON 字符串创建字典
    /// - Returns: 字典对象，失败返回 nil
    func st_toDictionary() -> [String: Any]? {
        guard let data = self.data(using: .utf8) else { return nil }
        return data.st_toDictionary()
    }
    
    /// 从 JSON 字符串创建数组
    /// - Returns: 数组对象，失败返回 nil
    func st_toArray() -> [Any]? {
        guard let data = self.data(using: .utf8) else { return nil }
        return data.st_toArray()
    }
    
    /// 从 JSON 字符串创建任意对象
    /// - Returns: JSON 对象，失败返回 nil
    func st_toJSONObject() -> Any? {
        guard let data = self.data(using: .utf8) else { return nil }
        return data.st_toJSONObject()
    }
    
    /// 检查是否为有效的 JSON 字符串
    var st_isValidJSON: Bool {
        return st_toJSONObject() != nil
    }
        
    /// 解码为指定类型
    /// - Parameter type: 目标类型
    /// - Returns: 解码结果
    func st_decode<T: Codable>(_ type: T.Type) -> T? {
        guard let data = self.data(using: .utf8) else { return nil }
        return data.st_decode(type)
    }
    
    /// 解码为指定类型（带错误处理）
    /// - Parameter type: 目标类型
    /// - Returns: 解码结果
    func st_decodeWithError<T: Codable>(_ type: T.Type) -> Result<T, Error> {
        guard let data = self.data(using: .utf8) else {
            return .failure(NSError(domain: "STJSONValue", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid string encoding"]))
        }
        return data.st_decodeWithError(type)
    }
}

// MARK: - Dictionary JSON 扩展
public extension Dictionary {
        
    /// 将字典转换为 JSON 字符串
    /// - Parameter prettyPrinted: 是否美化输出
    /// - Returns: JSON 字符串
    func st_toJSONString(prettyPrinted: Bool = false) -> String? {
        do {
            let data = try JSONSerialization.data(withJSONObject: self, options: prettyPrinted ? .prettyPrinted : [])
            return String(data: data, encoding: .utf8)
        } catch {
            return nil
        }
    }
    
    /// 将字典转换为 JSON 数据
    /// - Parameter prettyPrinted: 是否美化输出
    /// - Returns: JSON 数据
    func st_toJSONData(prettyPrinted: Bool = false) -> Data? {
        do {
            return try JSONSerialization.data(withJSONObject: self, options: prettyPrinted ? .prettyPrinted : [])
        } catch {
            return nil
        }
    }
    
    /// 检查字典是否为有效的 JSON 对象
    var st_isValidJSON: Bool {
        return JSONSerialization.isValidJSONObject(self)
    }
}

// MARK: - Array JSON 扩展
public extension Array {
        
    /// 将数组转换为 JSON 字符串
    /// - Parameter prettyPrinted: 是否美化输出
    /// - Returns: JSON 字符串
    func st_toJSONString(prettyPrinted: Bool = false) -> String? {
        do {
            let data = try JSONSerialization.data(withJSONObject: self, options: prettyPrinted ? .prettyPrinted : [])
            return String(data: data, encoding: .utf8)
        } catch {
            return nil
        }
    }
    
    /// 将数组转换为 JSON 数据
    /// - Parameter prettyPrinted: 是否美化输出
    /// - Returns: JSON 数据
    func st_toJSONData(prettyPrinted: Bool = false) -> Data? {
        do {
            return try JSONSerialization.data(withJSONObject: self, options: prettyPrinted ? .prettyPrinted : [])
        } catch {
            return nil
        }
    }
    
    /// 检查数组是否为有效的 JSON 对象
    var st_isValidJSON: Bool {
        return JSONSerialization.isValidJSONObject(self)
    }
}

// MARK: - Codable 扩展
public extension Encodable {
    
    /// 编码为 JSON 数据
    /// - Parameter encoder: JSON 编码器
    /// - Returns: JSON 数据
    func st_toJSONData(encoder: JSONEncoder = JSONEncoder()) -> Data? {
        do {
            return try encoder.encode(self)
        } catch {
            return nil
        }
    }
    
    /// 编码为 JSON 字符串
    /// - Parameter encoder: JSON 编码器
    /// - Returns: JSON 字符串
    func st_toJSONString(encoder: JSONEncoder = JSONEncoder()) -> String? {
        guard let data = st_toJSONData(encoder: encoder) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    /// 编码为 JSON 数据（带错误处理）
    /// - Parameter encoder: JSON 编码器
    /// - Returns: 编码结果
    func st_toJSONDataWithError(encoder: JSONEncoder = JSONEncoder()) -> Result<Data, Error> {
        do {
            let data = try encoder.encode(self)
            return .success(data)
        } catch {
            return .failure(error)
        }
    }
    
    /// 编码为 JSON 字符串（带错误处理）
    /// - Parameter encoder: JSON 编码器
    /// - Returns: 编码结果
    func st_toJSONStringWithError(encoder: JSONEncoder = JSONEncoder()) -> Result<String, Error> {
        let dataResult = st_toJSONDataWithError(encoder: encoder)
        switch dataResult {
        case .success(let data):
            if let string = String(data: data, encoding: .utf8) {
                return .success(string)
            } else {
                return .failure(NSError(domain: "STJSONValue", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert data to string"]))
            }
        case .failure(let error):
            return .failure(error)
        }
    }
    
    func st_toDictionary() -> [String: Any]? {
        do {
            let data = try JSONEncoder().encode(self)  // struct -> Data
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
            return jsonObject as? [String: Any]
        } catch {
            print("❌ 转换失败: \(error)")
            return nil
        }
    }
}

// MARK: - JSON 工具类
public class STJSONUtils {
        
    /// 创建美化的 JSON 字符串
    /// - Parameter object: 要转换的对象
    /// - Returns: 美化的 JSON 字符串
    public static func st_prettyJSONString(from object: Any) -> String? {
        guard let data = Data.st_fromJSONObject(object, options: .prettyPrinted) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    /// 验证 JSON 字符串
    /// - Parameter jsonString: JSON 字符串
    /// - Returns: 是否有效
    public static func st_validateJSON(_ jsonString: String) -> Bool {
        return jsonString.st_isValidJSON
    }
    
    /// 验证 JSON 数据
    /// - Parameter data: JSON 数据
    /// - Returns: 是否有效
    public static func st_validateJSONData(_ data: Data) -> Bool {
        return data.st_isValidJSON
    }
    
    /// 比较两个 JSON 对象是否相等
    /// - Parameters:
    ///   - lhs: 左操作数
    ///   - rhs: 右操作数
    /// - Returns: 是否相等
    public static func st_areEqual(_ lhs: Any, _ rhs: Any) -> Bool {
        guard let lhsData = Data.st_fromJSONObject(lhs),
              let rhsData = Data.st_fromJSONObject(rhs) else {
            return false
        }
        return lhsData == rhsData
    }
    
    /// 深度合并两个 JSON 对象
    /// - Parameters:
    ///   - lhs: 左操作数
    ///   - rhs: 右操作数
    /// - Returns: 合并后的对象
    public static func st_merge(_ lhs: [String: Any], _ rhs: [String: Any]) -> [String: Any] {
        var result = lhs
        for (key, value) in rhs {
            if let existingValue = result[key] as? [String: Any],
               let newValue = value as? [String: Any] {
                result[key] = st_merge(existingValue, newValue)
            } else {
                result[key] = value
            }
        }
        return result
    }
    
    /// 从文件读取 JSON
    /// - Parameter path: 文件路径
    /// - Returns: JSON 对象
    public static func st_readJSONFromFile(_ path: String) -> Any? {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else { return nil }
        return data.st_toJSONObject()
    }
    
    /// 将 JSON 写入文件
    /// - Parameters:
    ///   - object: JSON 对象
    ///   - path: 文件路径
    ///   - prettyPrinted: 是否美化输出
    /// - Returns: 是否成功
    @discardableResult
    public static func st_writeJSONToFile(_ object: Any, path: String, prettyPrinted: Bool = false) -> Bool {
        guard let data = Data.st_fromJSONObject(object, options: prettyPrinted ? .prettyPrinted : []) else { return false }
        do {
            try data.write(to: URL(fileURLWithPath: path))
            return true
        } catch {
            return false
        }
    }
    
    /// 从 Bundle 读取 JSON 文件
    /// - Parameters:
    ///   - name: 文件名（不含扩展名）
    ///   - bundle: Bundle 对象
    /// - Returns: JSON 对象
    public static func st_readJSONFromBundle(name: String, bundle: Bundle = Bundle.main) -> Any? {
        guard let path = bundle.path(forResource: name, ofType: "json") else { return nil }
        return st_readJSONFromFile(path)
    }
    
    /// 从 Bundle 读取 JSON 文件并解码为指定类型
    /// - Parameters:
    ///   - name: 文件名（不含扩展名）
    ///   - type: 目标类型
    ///   - bundle: Bundle 对象
    /// - Returns: 解码结果
    public static func st_readJSONFromBundle<T: Codable>(name: String, type: T.Type, bundle: Bundle = Bundle.main) -> T? {
        guard let path = bundle.path(forResource: name, ofType: "json"),
              let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else { return nil }
        return data.st_decode(type)
    }
    
    /// 将 JSON 字符串转换为美化格式
    /// - Parameter jsonString: JSON 字符串
    /// - Returns: 美化后的 JSON 字符串
    public static func st_jsonStringToPrettyPrintedJson(jsonString: String?) -> String {
        guard let str = jsonString, !str.isEmpty else { return "" }
        
        do {
            guard let jsonData = str.data(using: .utf8) else { return str }
            let jsonObject = try JSONSerialization.jsonObject(with: jsonData, options: [])
            let prettyJsonData = try JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted)
            return String(data: prettyJsonData, encoding: .utf8) ?? str
        } catch {
            return str
        }
    }
    
    /// 将字典转换为 JSON 字符串
    /// - Parameter dict: 字典对象
    /// - Returns: JSON 字符串
    public static func st_dictToJSON(dict: [String: Any]) -> String {
        guard !dict.isEmpty else { return "" }
        
        do {
            let data = try JSONSerialization.data(withJSONObject: dict, options: [])
            return String(data: data, encoding: .utf8) ?? ""
        } catch {
            return ""
        }
    }
}

// MARK: - JSON 错误类型
public enum STJSONError: Error, LocalizedError {
    case invalidJSON
    case encodingFailed
    case decodingFailed
    case invalidPath
    case fileNotFound
    case fileReadFailed
    case fileWriteFailed
    
    public var errorDescription: String? {
        switch self {
        case .invalidJSON:
            return "无效的 JSON 格式"
        case .encodingFailed:
            return "JSON 编码失败"
        case .decodingFailed:
            return "JSON 解码失败"
        case .invalidPath:
            return "无效的文件路径"
        case .fileNotFound:
            return "文件未找到"
        case .fileReadFailed:
            return "文件读取失败"
        case .fileWriteFailed:
            return "文件写入失败"
        }
    }
}
