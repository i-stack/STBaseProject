//
//  STJSONValue.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2020/5/26.
//

import Foundation

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
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Int.self) {
            self = .int(value)
        } else if let value = try? container.decode(Double.self) {
            self = .double(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
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

    public func bool(or defaultValue: Bool = false) -> Bool {
        switch self {
        case .bool(let value):
            return value
        case .int(let value):
            return value != 0
        case .string(let value):
            return value.lowercased() == "true" || value == "1"
        case .double(let value):
            return value != 0.0
        default:
            return defaultValue
        }
    }

    public func string(or defaultValue: String = "") -> String {
        stringValue ?? defaultValue
    }

    public func int(or defaultValue: Int = 0) -> Int {
        intValue ?? defaultValue
    }

    public func double(or defaultValue: Double = 0.0) -> Double {
        doubleValue ?? defaultValue
    }

    public func array(or defaultValue: [STJSONValue] = []) -> [STJSONValue] {
        arrayValue ?? defaultValue
    }

    public func object(or defaultValue: [String: STJSONValue] = [:]) -> [String: STJSONValue] {
        objectValue ?? defaultValue
    }
}

public extension STJSONValue {
    init(_ value: Any) {
        // NSNumber 路径优先：JSONSerialization / KVC 取出来的数值都是桥接 NSNumber，
        // 直接用 `as? Bool` / `as? Int` 顺序匹配会让所有 Bool 都命中 Int（`NSNumber(true) as? Int == 1`）。
        if let number = value as? NSNumber {
            // 区分布尔：CFBooleanRef 的 typeID 与 NSNumber 不同
            if CFGetTypeID(number) == CFBooleanGetTypeID() {
                self = .bool(number.boolValue)
                return
            }
            let objCType = String(cString: number.objCType)
            switch objCType {
            case "f", "d":
                self = .double(number.doubleValue)
            default:
                self = .int(number.intValue)
            }
            return
        }
        switch value {
        case let string as String:
            self = .string(string)
        case let bool as Bool:
            self = .bool(bool)
        case let int as Int:
            self = .int(int)
        case let double as Double:
            self = .double(double)
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

public extension Data {
    func jsonObject(options: JSONSerialization.ReadingOptions = []) -> Any? {
        do {
            return try JSONSerialization.jsonObject(with: self, options: options)
        } catch {
            return nil
        }
    }

    var jsonDictionary: [String: Any]? {
        jsonObject() as? [String: Any]
    }

    var jsonArray: [Any]? {
        jsonObject() as? [Any]
    }

    static func jsonData(from object: Any, options: JSONSerialization.WritingOptions = []) -> Data? {
        guard JSONSerialization.isValidJSONObject(object) else { return nil }
        do {
            return try JSONSerialization.data(withJSONObject: object, options: options)
        } catch {
            return nil
        }
    }

    var isJSONData: Bool {
        jsonObject() != nil
    }

    func decoded<T: Codable>(_ type: T.Type, using decoder: JSONDecoder = JSONDecoder()) -> T? {
        do {
            return try decoder.decode(type, from: self)
        } catch {
            return nil
        }
    }

    func decodeResult<T: Codable>(_ type: T.Type, using decoder: JSONDecoder = JSONDecoder()) -> Result<T, Error> {
        do {
            let result = try decoder.decode(type, from: self)
            return .success(result)
        } catch {
            return .failure(error)
        }
    }
}

public extension String {
    var jsonDictionary: [String: Any]? {
        data(using: .utf8)?.jsonDictionary
    }

    var jsonArray: [Any]? {
        data(using: .utf8)?.jsonArray
    }

    var jsonObject: Any? {
        data(using: .utf8)?.jsonObject()
    }

    var isJSONText: Bool {
        jsonObject != nil
    }

    func decoded<T: Codable>(_ type: T.Type, using decoder: JSONDecoder = JSONDecoder()) -> T? {
        guard let data = data(using: .utf8) else { return nil }
        return data.decoded(type, using: decoder)
    }

    func decodeResult<T: Codable>(_ type: T.Type, using decoder: JSONDecoder = JSONDecoder()) -> Result<T, Error> {
        guard let data = data(using: .utf8) else {
            return .failure(NSError(domain: "STJSONValue", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid string encoding"]))
        }
        return data.decodeResult(type, using: decoder)
    }
}

public extension Dictionary {
    func jsonString(prettyPrinted: Bool = false) -> String? {
        jsonData(prettyPrinted: prettyPrinted).flatMap { String(data: $0, encoding: .utf8) }
    }

    func jsonData(prettyPrinted: Bool = false) -> Data? {
        do {
            return try JSONSerialization.data(withJSONObject: self, options: prettyPrinted ? .prettyPrinted : [])
        } catch {
            return nil
        }
    }

    var isJSONCompatible: Bool {
        JSONSerialization.isValidJSONObject(self)
    }
}

public extension Array {
    func jsonString(prettyPrinted: Bool = false) -> String? {
        jsonData(prettyPrinted: prettyPrinted).flatMap { String(data: $0, encoding: .utf8) }
    }

    func jsonData(prettyPrinted: Bool = false) -> Data? {
        do {
            return try JSONSerialization.data(withJSONObject: self, options: prettyPrinted ? .prettyPrinted : [])
        } catch {
            return nil
        }
    }

    var isJSONCompatible: Bool {
        JSONSerialization.isValidJSONObject(self)
    }
}

public extension Encodable {
    func jsonData(using encoder: JSONEncoder = JSONEncoder()) -> Data? {
        do {
            return try encoder.encode(self)
        } catch {
            return nil
        }
    }

    func jsonString(using encoder: JSONEncoder = JSONEncoder()) -> String? {
        guard let data = jsonData(using: encoder) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func encodeToJSONData(using encoder: JSONEncoder = JSONEncoder()) -> Result<Data, Error> {
        do {
            let data = try encoder.encode(self)
            return .success(data)
        } catch {
            return .failure(error)
        }
    }

    func encodeToJSONString(using encoder: JSONEncoder = JSONEncoder()) -> Result<String, Error> {
        let dataResult = encodeToJSONData(using: encoder)
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

    func dictionaryRepresentation() -> [String: Any]? {
        do {
            let data = try JSONEncoder().encode(self)
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
            return jsonObject as? [String: Any]
        } catch {
            return nil
        }
    }
}

public enum STJSONUtils {
    public static func prettyPrintedString(from object: Any) -> String? {
        guard let data = Data.jsonData(from: object, options: .prettyPrinted) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    public static func isValid(jsonString: String) -> Bool {
        jsonString.isJSONText
    }

    public static func isValid(data: Data) -> Bool {
        data.isJSONData
    }

    public static func areEqual(_ lhs: Any, _ rhs: Any) -> Bool {
        guard let lhsData = Data.jsonData(from: lhs), let rhsData = Data.jsonData(from: rhs) else {
            return false
        }
        return lhsData == rhsData
    }

    public static func merge(_ lhs: [String: Any], _ rhs: [String: Any]) -> [String: Any] {
        var result = lhs
        for (key, value) in rhs {
            if let existingValue = result[key] as? [String: Any],
               let newValue = value as? [String: Any] {
                result[key] = merge(existingValue, newValue)
            } else {
                result[key] = value
            }
        }
        return result
    }

    public static func readJSON(fromFile path: String) -> Any? {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else { return nil }
        return data.jsonObject()
    }

    @discardableResult
    public static func writeJSON(_ object: Any, toFile path: String, prettyPrinted: Bool = false) -> Bool {
        guard let data = Data.jsonData(from: object, options: prettyPrinted ? .prettyPrinted : []) else { return false }
        do {
            try data.write(to: URL(fileURLWithPath: path))
            return true
        } catch {
            return false
        }
    }

    public static func readJSONFromBundle(named name: String, bundle: Bundle = .main) -> Any? {
        guard let path = bundle.path(forResource: name, ofType: "json") else { return nil }
        return readJSON(fromFile: path)
    }

    public static func decodeBundleJSON<T: Codable>(named name: String, as type: T.Type, bundle: Bundle = .main) -> T? {
        guard let path = bundle.path(forResource: name, ofType: "json"),
              let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else { return nil }
        return data.decoded(type)
    }

    public static func prettyPrintedJSONString(from jsonString: String?) -> String {
        guard let string = jsonString, !string.isEmpty else { return "" }
        do {
            guard let jsonData = string.data(using: .utf8) else { return string }
            let jsonObject = try JSONSerialization.jsonObject(with: jsonData, options: [])
            let prettyJsonData = try JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted)
            return String(data: prettyJsonData, encoding: .utf8) ?? string
        } catch {
            return string
        }
    }

    public static func jsonString(from dictionary: [String: Any]) -> String {
        dictionary.jsonString() ?? ""
    }
}

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
