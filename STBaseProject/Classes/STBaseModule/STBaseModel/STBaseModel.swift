//
//  STBaseModel.swift
//  STBaseProject
//
//  Created by stack on 2018/3/14.
//  Copyright © 2018 ST. All rights reserved.
//

import UIKit

open class STBaseModel: NSObject {
    
    deinit {
        print("🌈 -> \(self) 🌈 ----> 🌈 dealloc")
    }
    
    open override func value(forUndefinedKey key: String) -> Any? {
        print("⚠️ ⚠️ Key = \(key) isUndefinedKey ⚠️ ⚠️")
        return nil
    }

    open override class func setValue(_ value: Any?, forUndefinedKey key: String) {
        print("⚠️ ⚠️ Key = \(key) isUndefinedKey ⚠️ ⚠️")
    }

    open override func setValue(_ value: Any?, forUndefinedKey key: String) {
        print("⚠️ ⚠️ Key = \(key) isUndefinedKey ⚠️ ⚠️")
    }
}

public extension STBaseModel {
    /// json转model
    func st_jsonToModel<T>(_ type: T.Type, value: Any) -> T? where T : Decodable {
        if JSONSerialization.isValidJSONObject(value) {
            var jsonData: Any = value
            if let newValue = value as? String {
                if let data = newValue.data(using: .utf8) {
                    do {
                        let dict = try JSONSerialization.jsonObject(with: data, options: .mutableContainers)
                        jsonData = dict
                        guard let data = try? JSONSerialization.data(withJSONObject: jsonData) else { return nil }
                        let decoder = JSONDecoder()
                        do {
                            return try decoder.decode(type, from: data)
                        } catch {
                            return nil
                        }
                    } catch {
                        return nil
                    }
                }
            }
        }
        return nil
    }
    
    static func jsonToModel<T>(_ type: T.Type, value: Any) -> T? where T : Decodable {
        return STBaseModel().st_jsonToModel(type, value: value)
    }
    
    /// model转json
    func st_modelToJson<T>(value: T) -> String where T : Encodable {
        if let jsonData = try? JSONEncoder().encode(value) {
            if let jsonString = String.init(data: jsonData, encoding: String.Encoding.utf8) {
                return jsonString
            }
        }
        return ""
    }
    
    static func modelToJson<T>(value: T) -> String where T : Encodable {
        return STBaseModel().st_modelToJson(value: value)
    }
    
    /// array转json
    func st_arrayToJson<T>(value: T) -> String where T : Encodable {
        var jsonStr = ""
        if JSONSerialization.isValidJSONObject(value) {
            do {
                let data = try JSONSerialization.data(withJSONObject: value, options: .prettyPrinted)
                if let str = String.init(data: data, encoding: .utf8) {
                    jsonStr = str
                }
            } catch {
                
            }
        }
        return jsonStr
    }
    
    static func arrayToJson<T>(value: T) -> String where T : Encodable {
        return STBaseModel().st_arrayToJson(value: value)
    }
}
