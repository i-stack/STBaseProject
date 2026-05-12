//
//  STBaseModelTests.swift
//  STBaseProjectExampleTests
//
//  覆盖 STBaseModel 关键修复：
//   - 嵌套模型 Codable 解码 / 编码
//   - st_update(from:) 嵌套对象 / 嵌套数组 / NSNull
//   - STJSONValue(_:) 对 NSNumber 桥接 Bool / Int / Double 的判别
//   - KVC 类型不匹配时的安全降级（不应崩溃）
//   - 多层继承属性枚举
//   - hash / isEqual 的一致性契约
//   - st_copy() 的深拷贝语义
//   - 灵活模式 st_getXxx
//

import XCTest
import Foundation
@testable import STBaseProject

// MARK: - Test Models

final class STAddressModel: STBaseModel {
    @objc var city: String = ""
    @objc var zip: String = ""
}

final class STContactModel: STBaseModel {
    @objc var name: String = ""
    @objc var phone: String = ""
}

class STUserBaseModel: STBaseModel {
    @objc var userId: Int = 0
    @objc var userName: String = ""
}

/// 多层继承 + 嵌套对象 + 嵌套数组 + 蛇形键映射。
final class STUserModel: STUserBaseModel {
    @objc var age: Int = 0
    @objc var isVip: Bool = false
    @objc var score: Double = 0.0
    @objc var address: STAddressModel?
    @objc var contacts: [STContactModel] = []
    @objc var nickname: String = ""

    override class func st_keyMapping() -> [String: String] {
        return [
            "user_id": "userId",
            "user_name": "userName",
            "is_vip": "isVip",
            "nick_name": "nickname"
        ]
    }

    override class func st_nestedModelTypes() -> [String: STBaseModel.Type] {
        return [
            "address": STAddressModel.self,
            "contacts": STContactModel.self
        ]
    }
}

// MARK: - Tests

final class STBaseModelTests: XCTestCase {

    // MARK: 嵌套对象 / 嵌套数组 / 字典初始化

    func test_st_update_handles_nested_object_and_array() {
        let dict: [String: Any] = [
            "user_id": 42,
            "user_name": "alice",
            "is_vip": true,
            "score": 98.5,
            "age": 30,
            "address": ["city": "BJ", "zip": "100000"],
            "contacts": [
                ["name": "bob", "phone": "12345"],
                ["name": "carol", "phone": "67890"]
            ]
        ]
        let user = STUserModel(from: dict)

        XCTAssertEqual(user.userId, 42)
        XCTAssertEqual(user.userName, "alice")
        XCTAssertTrue(user.isVip)
        XCTAssertEqual(user.score, 98.5, accuracy: 0.0001)
        XCTAssertEqual(user.age, 30)

        XCTAssertNotNil(user.address)
        XCTAssertEqual(user.address?.city, "BJ")
        XCTAssertEqual(user.address?.zip, "100000")

        XCTAssertEqual(user.contacts.count, 2)
        XCTAssertEqual(user.contacts[0].name, "bob")
        XCTAssertEqual(user.contacts[1].phone, "67890")
    }

    func test_st_update_filters_invalid_array_elements_via_compactMap() {
        let dict: [String: Any] = [
            "contacts": [
                ["name": "bob", "phone": "1"],
                "garbage",          // 非字典，应被过滤
                NSNull(),           // 同上
                ["name": "carol", "phone": "2"]
            ]
        ]
        let user = STUserModel(from: dict)
        XCTAssertEqual(user.contacts.count, 2)
        XCTAssertEqual(user.contacts.map { $0.name }, ["bob", "carol"])
    }

    func test_st_update_with_NSNull_does_not_crash_on_object_property() {
        let user = STUserModel()
        user.address = STAddressModel()
        user.st_update(from: ["address": NSNull()])
        // address 是对象属性，允许 nil
        XCTAssertNil(user.address)
    }

    // MARK: 多层继承属性枚举

    func test_propertyNames_include_super_class_properties() {
        let names = STUserModel.st_propertyNames()
        // 父类属性
        XCTAssertTrue(names.contains("userId"), "should include super-class property userId")
        XCTAssertTrue(names.contains("userName"))
        // 子类属性
        XCTAssertTrue(names.contains("age"))
        XCTAssertTrue(names.contains("address"))
        // 不应泄漏内部属性
        XCTAssertFalse(names.contains("st_isFlexibleMode"))
    }

    // MARK: Codable —— 关键修复 #1 / #2

    func test_codable_round_trip_preserves_nested_objects_and_arrays() throws {
        let user = STUserModel(from: [
            "user_id": 7,
            "user_name": "ada",
            "is_vip": false,
            "score": 1.5,
            "age": 18,
            "nick_name": "lovelace",
            "address": ["city": "London", "zip": "SW1"],
            "contacts": [
                ["name": "babbage", "phone": "111"]
            ]
        ])

        let data = try JSONEncoder().encode(user)
        let decoded = try JSONDecoder().decode(STUserModel.self, from: data)

        XCTAssertEqual(decoded.userId, 7)
        XCTAssertEqual(decoded.userName, "ada")
        XCTAssertFalse(decoded.isVip)
        XCTAssertEqual(decoded.score, 1.5, accuracy: 0.0001)
        XCTAssertEqual(decoded.age, 18)
        XCTAssertEqual(decoded.nickname, "lovelace")

        XCTAssertEqual(decoded.address?.city, "London")
        XCTAssertEqual(decoded.address?.zip, "SW1")

        XCTAssertEqual(decoded.contacts.count, 1)
        XCTAssertEqual(decoded.contacts[0].name, "babbage")
        XCTAssertEqual(decoded.contacts[0].phone, "111")
    }

    func test_codable_uses_json_keys_from_st_keyMapping() throws {
        let user = STUserModel()
        user.userId = 1
        user.userName = "n"
        user.isVip = true
        user.nickname = "nn"

        let data = try JSONEncoder().encode(user)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertNotNil(json["user_id"])
        XCTAssertNotNil(json["user_name"])
        XCTAssertNotNil(json["is_vip"])
        XCTAssertNotNil(json["nick_name"])
        // 不应同时出现属性原名
        XCTAssertNil(json["userId"])
        XCTAssertNil(json["userName"])
    }

    // MARK: STJSONValue NSNumber 桥接 —— 关键修复 #3

    func test_STJSONValue_init_distinguishes_NSNumber_bool_from_int() {
        // 直接 Swift Bool / Int 字面量
        if case .bool(let b) = STJSONValue(true) { XCTAssertTrue(b) } else {
            XCTFail("Bool literal should map to .bool")
        }
        if case .int(let i) = STJSONValue(42) { XCTAssertEqual(i, 42) } else {
            XCTFail("Int literal should map to .int")
        }

        // NSNumber 桥接（最容易踩坑）
        let nsTrue: Any = NSNumber(value: true)
        let nsInt: Any = NSNumber(value: 7)
        let nsDouble: Any = NSNumber(value: 1.5)

        switch STJSONValue(nsTrue) {
        case .bool(let b): XCTAssertTrue(b)
        default: XCTFail("NSNumber(true) should map to .bool, got \(STJSONValue(nsTrue))")
        }
        switch STJSONValue(nsInt) {
        case .int(let i): XCTAssertEqual(i, 7)
        default: XCTFail("NSNumber(7) should map to .int")
        }
        switch STJSONValue(nsDouble) {
        case .double(let d): XCTAssertEqual(d, 1.5, accuracy: 0.0001)
        default: XCTFail("NSNumber(1.5) should map to .double")
        }
    }

    func test_STJSONValue_init_handles_JSONSerialization_bridged_bool() throws {
        let raw = #"{"flag": true, "count": 3, "ratio": 2.5}"#.data(using: .utf8)!
        let dict = try XCTUnwrap(JSONSerialization.jsonObject(with: raw) as? [String: Any])

        switch STJSONValue(dict["flag"]!) {
        case .bool(let b): XCTAssertTrue(b)
        default: XCTFail("flag from JSONSerialization should map to .bool")
        }
        switch STJSONValue(dict["count"]!) {
        case .int(let i): XCTAssertEqual(i, 3)
        default: XCTFail("count from JSONSerialization should map to .int")
        }
        switch STJSONValue(dict["ratio"]!) {
        case .double(let d): XCTAssertEqual(d, 2.5, accuracy: 0.0001)
        default: XCTFail("ratio from JSONSerialization should map to .double")
        }
    }

    // MARK: KVC 类型安全 —— 不再因类型不匹配崩溃

    func test_safeSetValue_does_not_crash_on_type_mismatch() {
        let user = STUserModel()
        // 把一个 String 喂给 Int 属性 userId：旧实现会抛 NSInvalidArgumentException 而崩溃。
        XCTAssertNoThrow(user.st_update(from: ["user_id": "not-a-number"]))
        // 行为约定：无法转换的值不写入，userId 保持默认 0。
        XCTAssertEqual(user.userId, 0)
    }

    func test_safeSetValue_coerces_string_number_to_int() {
        let user = STUserModel()
        user.st_update(from: ["user_id": "123"])
        XCTAssertEqual(user.userId, 123)
    }

    func test_safeSetValue_coerces_NSNumber_to_bool() {
        let user = STUserModel()
        user.st_update(from: ["is_vip": NSNumber(value: 1)])
        XCTAssertTrue(user.isVip)
    }

    // MARK: hash / isEqual 一致性 —— 关键修复 #12

    func test_isEqual_and_hash_consistency() {
        let dict: [String: Any] = [
            "user_id": 1,
            "user_name": "a",
            "address": ["city": "X", "zip": "0"]
        ]
        let a = STUserModel(from: dict)
        let b = STUserModel(from: dict)
        XCTAssertTrue(a.isEqual(b))
        XCTAssertEqual(a.hash, b.hash, "isEqual ⇒ hash equality")

        let set = NSMutableSet()
        set.add(a)
        XCTAssertTrue(set.contains(b), "two equal STBaseModel instances must collide in NSSet")
    }

    func test_isEqual_returns_false_for_different_types() {
        let user = STUserModel()
        let address = STAddressModel()
        XCTAssertFalse(user.isEqual(address))
    }

    // MARK: st_copy() 深拷贝语义

    func test_st_copy_deep_copies_nested_object() {
        let original = STUserModel(from: [
            "user_id": 1,
            "user_name": "a",
            "address": ["city": "BJ", "zip": "100"]
        ])

        let copy = original.st_copy() as! STUserModel
        XCTAssertNotNil(copy.address)
        XCTAssertEqual(copy.address?.city, "BJ")

        // 不应共享同一个 address 实例
        XCTAssertFalse(copy.address === original.address,
                       "address should be a new instance after st_copy()")

        // 修改 copy 的 address 不影响原对象
        copy.address?.city = "SH"
        XCTAssertEqual(original.address?.city, "BJ")
        XCTAssertEqual(copy.address?.city, "SH")
    }

    func test_st_copy_deep_copies_nested_array_elements() {
        let original = STUserModel(from: [
            "contacts": [
                ["name": "bob", "phone": "1"],
                ["name": "carol", "phone": "2"]
            ]
        ])

        let copy = original.st_copy() as! STUserModel
        XCTAssertEqual(copy.contacts.count, 2)
        // 元素也必须是新实例
        XCTAssertFalse(copy.contacts[0] === original.contacts[0])

        copy.contacts[0].name = "BOB"
        XCTAssertEqual(original.contacts[0].name, "bob")
    }

    func test_st_copy_returns_same_subclass_type() {
        let original: STUserBaseModel = STUserModel()
        let copy = original.st_copy()
        XCTAssertTrue(copy is STUserModel,
                      "st_copy must return the runtime subclass, not STBaseModel")
    }

    // MARK: 灵活模式

    func test_flexible_mode_get_xxx_returns_typed_values() {
        let model = STBaseModel()
        model.st_isFlexibleMode = true
        model.st_update(from: [
            "name": "alice",
            "age": 30,
            "isVip": true,
            "score": 1.5,
            "extra": NSNull()
        ])

        XCTAssertEqual(model.st_getString(forKey: "name"), "alice")
        XCTAssertEqual(model.st_getInt(forKey: "age"), 30)
        XCTAssertTrue(model.st_getBool(forKey: "isVip"))
        XCTAssertEqual(model.st_getDouble(forKey: "score"), 1.5, accuracy: 0.0001)

        XCTAssertEqual(model.st_valueKind(forKey: "name"), .string)
        XCTAssertEqual(model.st_valueKind(forKey: "age"), .int)
        XCTAssertEqual(model.st_valueKind(forKey: "isVip"), .bool)
        XCTAssertEqual(model.st_valueKind(forKey: "score"), .double)
        XCTAssertEqual(model.st_valueKind(forKey: "extra"), .null)
        XCTAssertEqual(model.st_valueKind(forKey: "missing"), .undefined)

        XCTAssertTrue(model.st_containsKey("name"))
        XCTAssertFalse(model.st_containsKey("missing"))
    }

    func test_flexible_mode_st_copy_does_not_share_storage() {
        let original = STBaseModel()
        original.st_isFlexibleMode = true
        original.st_update(from: ["name": "alice", "age": 30])

        let copy = original.st_copy()
        copy.st_update(from: ["name": "bob"])

        XCTAssertEqual(original.st_getString(forKey: "name"), "alice")
        XCTAssertEqual(copy.st_getString(forKey: "name"), "bob")
    }

    // MARK: nil 写入非 Optional 引用属性的保护

    func test_st_update_with_NSNull_skips_non_optional_reference_property() {
        // 非 Optional 引用属性：NSNull 写入会被跳过，保留原值，避免后续访问崩溃。
        let model = STNonOptionalRefModel()
        let original = model.payload
        model.st_update(from: ["payload": NSNull()])
        XCTAssertTrue(model.payload === original, "non-optional reference should not be nilled by NSNull")
    }

    func test_st_update_with_NSNull_still_clears_optional_reference() {
        // 回归测试：Optional 引用属性仍然可以被 NSNull 清空。
        let user = STUserModel()
        user.address = STAddressModel()
        user.st_update(from: ["address": NSNull()])
        XCTAssertNil(user.address)
    }

    // MARK: NSMutableArray / NSMutableDictionary 属性的可变性

    func test_st_update_preserves_NSMutableArray_mutability() {
        let model = STMutableContainerModel()
        model.st_update(from: ["items": [1, 2, 3]])
        XCTAssertEqual(model.items.count, 3)
        // 直接调用 mutable API：若内部存的是 Swift 桥接不可变数组，这里会崩。
        model.items.add(4)
        XCTAssertEqual(model.items.count, 4)
        XCTAssertEqual(model.items.lastObject as? Int, 4)
    }

    func test_st_update_preserves_NSMutableDictionary_mutability() {
        let model = STMutableContainerModel()
        model.st_update(from: ["mapping": ["a": 1, "b": 2]])
        XCTAssertEqual(model.mapping.count, 2)
        model.mapping.setObject(3, forKey: "c" as NSString)
        XCTAssertEqual(model.mapping.count, 3)
        XCTAssertEqual(model.mapping["c"] as? Int, 3)
    }

    // MARK: - st_toDictionary (standard mode)

    func test_st_toDictionary_standard_mode_applies_key_mapping_and_skips_internal_properties() {
        func toInt(_ value: Any?) -> Int? {
            if let i = value as? Int { return i }
            if let n = value as? NSNumber { return n.intValue }
            return nil
        }

        func toDouble(_ value: Any?) -> Double? {
            if let d = value as? Double { return d }
            if let n = value as? NSNumber { return n.doubleValue }
            return nil
        }

        func toBool(_ value: Any?) -> Bool? {
            if let b = value as? Bool { return b }
            if let n = value as? NSNumber { return n.boolValue }
            return nil
        }

        func toString(_ value: Any?) -> String? {
            if let s = value as? String { return s }
            if let ns = value as? NSString { return String(ns) }
            return nil
        }

        let user = STUserModel()
        user.userId = 1
        user.userName = "n"
        user.isVip = true
        user.score = 2.5
        user.age = 3
        user.nickname = "nn"
        user.address = STAddressModel()
        user.address?.city = "BJ"
        user.address?.zip = "100000"

        let dict = user.st_toDictionary()

        XCTAssertEqual(toInt(dict["user_id"]) ?? -1, 1)
        XCTAssertEqual(toString(dict["user_name"]) ?? "", "n")
        XCTAssertEqual(toBool(dict["is_vip"]) ?? false, true)
        XCTAssertEqual(toDouble(dict["score"]) ?? 0.0, 2.5, accuracy: 0.0001)
        XCTAssertEqual(toInt(dict["age"]) ?? -1, 3)
        XCTAssertEqual(toString(dict["nick_name"]) ?? "", "nn")

        // key mapping 之后不应泄漏属性名
        XCTAssertNil(dict["userId"])
        XCTAssertNil(dict["userName"])
        XCTAssertNil(dict["isVip"])
        XCTAssertNil(dict["nickname"])

        // 内部 reserved 属性名不应出现在序列化结果中
        XCTAssertNil(dict["st_isFlexibleMode"])
    }

    // MARK: - st_getArray / st_getDictionary / st_toRawDictionary (flexible mode)

    func test_flexible_mode_st_getArray_st_getDictionary_and_toRawDictionary() {
        let model = STBaseModel()
        model.st_isFlexibleMode = true
        model.st_update(from: [
            "name": "alice",
            "age": 30,
            "arr": [1, "2", NSNull(), true],
            "dict": ["k1": "v1", "k2": 2],
            "extra": NSNull()
        ])

        XCTAssertEqual(model.st_getString(forKey: "name"), "alice")
        XCTAssertEqual(model.st_getInt(forKey: "age"), 30)
        XCTAssertEqual(model.st_valueKind(forKey: "arr"), .array)
        XCTAssertEqual(model.st_valueKind(forKey: "dict"), .dictionary)
        XCTAssertEqual(model.st_valueKind(forKey: "extra"), .null)

        let raw = model.st_toRawDictionary()
        XCTAssertEqual((raw["name"]?.stringValue), "alice")

        // Array: [Int, String, Null, Bool]
        let arr = model.st_getArray(forKey: "arr")
        XCTAssertEqual(arr.count, 4)
        XCTAssertEqual(arr[0].intValue, 1)
        XCTAssertEqual(arr[1].stringValue, "2")
        XCTAssertEqual(arr[2].isNull, true)
        XCTAssertEqual(arr[3].boolValue, true)

        // Dictionary: {"k1":"v1","k2":2}
        let dict = model.st_getDictionary(forKey: "dict")
        XCTAssertEqual(dict.count, 2)
        XCTAssertEqual(dict["k1"]?.stringValue, "v1")
        XCTAssertEqual(dict["k2"]?.intValue, 2)

        // processedData: should return concrete Any values
        let processedArr = model.st_getValue(forKey: "arr") as? [Any]
        XCTAssertEqual(processedArr?.count, 4)
        XCTAssertEqual(processedArr?[0] as? Int, 1)
        XCTAssertEqual(processedArr?[1] as? String, "2")

        let processedExtra = model.st_getValue(forKey: "extra")
        XCTAssertTrue(processedExtra is NSNull)
    }

    func test_flexible_mode_st_getAllKeys_and_st_containsKey() {
        let model = STBaseModel()
        model.st_isFlexibleMode = true
        model.st_update(from: ["name": "alice", "age": 30])

        let keys = Set(model.st_getAllKeys())
        XCTAssertTrue(keys.contains("name"))
        XCTAssertTrue(keys.contains("age"))
        XCTAssertFalse(model.st_containsKey("missing"))
    }

    func test_flexible_mode_st_getValueType_string_compat() {
        let model = STBaseModel()
        model.st_isFlexibleMode = true
        model.st_update(from: [
            "name": "alice",
            "age": 30,
            "isVip": true,
            "score": 1.5,
            "arr": [1, 2],
            "dict": ["k": "v"],
            "extra": NSNull()
        ])

        XCTAssertEqual(model.st_getValueType(forKey: "name"), "String")
        XCTAssertEqual(model.st_getValueType(forKey: "age"), "Int")
        XCTAssertEqual(model.st_getValueType(forKey: "isVip"), "Bool")
        XCTAssertEqual(model.st_getValueType(forKey: "score"), "Double")
        XCTAssertEqual(model.st_getValueType(forKey: "arr"), "Array")
        XCTAssertEqual(model.st_getValueType(forKey: "dict"), "Dictionary")
        XCTAssertEqual(model.st_getValueType(forKey: "extra"), "Null")
        XCTAssertEqual(model.st_getValueType(forKey: "missing"), "undefined")
    }

    // MARK: - Codable encode (flexible mode)

    func test_codable_encode_flexible_mode_uses_rawData_keys_and_values() throws {
        let model = STBaseModel()
        model.st_isFlexibleMode = true
        model.st_update(from: [
            "name": "alice",
            "age": 30,
            "isVip": true,
            "score": 1.5,
            "extra": NSNull(),
            "arr": [1, 2],
            "dict": ["k": "v"]
        ])

        let data = try JSONEncoder().encode(model)
        let decoded = try JSONDecoder().decode([String: STJSONValue].self, from: data)

        XCTAssertEqual(decoded["name"]?.stringValue, "alice")
        XCTAssertEqual(decoded["age"]?.intValue, 30)
        XCTAssertEqual(decoded["isVip"]?.boolValue, true)
        XCTAssertEqual(decoded["score"]?.doubleValue ?? 0.0, 1.5, accuracy: 0.0001)
        XCTAssertEqual(decoded["extra"]?.isNull, true)
        XCTAssertEqual(decoded["arr"]?.arrayValue?.count, 2)
        XCTAssertEqual(decoded["dict"]?.objectValue?["k"]?.stringValue, "v")
    }

    // MARK: - st_fromArray / st_fromJSONArray

    func test_st_fromArray_returns_subclass_instances() {
        let models = STUserModel.st_fromArray([
            ["user_id": 1, "user_name": "alice", "is_vip": false, "score": 1.0, "age": 18, "nick_name": "n1"],
            ["user_id": 2, "user_name": "bob", "is_vip": true, "score": 2.0, "age": 20, "nick_name": "n2"]
        ])

        XCTAssertEqual(models.count, 2)
        XCTAssertEqual((models[0] as? STUserModel)?.userId, 1)
        XCTAssertEqual((models[1] as? STUserModel)?.userId, 2)
        XCTAssertTrue(models.allSatisfy { $0 is STUserModel })
    }

    func test_st_fromJSONArray_parses_json_array_into_models() throws {
        let rawArray: [[String: Any]] = [
            ["user_id": 7, "user_name": "ada", "is_vip": false, "score": 1.5, "age": 18, "nick_name": "lovelace"]
        ]
        let data = try JSONSerialization.data(withJSONObject: rawArray, options: [])

        let models = try XCTUnwrap(STUserModel.st_fromJSONArray(data))
        XCTAssertEqual(models.count, 1)

        let user = try XCTUnwrap(models.first as? STUserModel)
        XCTAssertEqual(user.userId, 7)
        XCTAssertEqual(user.userName, "ada")
        XCTAssertFalse(user.isVip)
        XCTAssertEqual(user.score, 1.5, accuracy: 0.0001)
        XCTAssertEqual(user.age, 18)
        XCTAssertEqual(user.nickname, "lovelace")
    }

    // MARK: - st_copy deep copy of mutable containers with model values

    func test_st_copy_deep_copies_mutable_array_elements_when_elements_are_models() {
        let container = STArrayModelContainer()
        let a = STAddressModel()
        a.city = "BJ"
        a.zip = "100"

        container.addressList = NSMutableArray(array: [a])
        let copy = container.st_copy() as! STArrayModelContainer

        XCTAssertFalse(copy.addressList === container.addressList)
        let copyA = copy.addressList.firstObject as? STAddressModel
        let originalA = container.addressList.firstObject as? STAddressModel
        XCTAssertNotNil(copyA)
        XCTAssertNotNil(originalA)
        XCTAssertFalse(copyA === originalA)
        XCTAssertEqual(copyA?.city, "BJ")

        copyA?.city = "SH"
        XCTAssertEqual(originalA?.city, "BJ")
        XCTAssertEqual(copyA?.city, "SH")
    }

    func test_st_copy_deep_copies_mutable_dictionary_values_when_values_are_models() {
        let container = STDictionaryModelContainer()
        let a = STAddressModel()
        a.city = "BJ"
        a.zip = "100"

        container.addressByKey["k1"] = a
        let copy = container.st_copy() as! STDictionaryModelContainer

        XCTAssertFalse(copy.addressByKey === container.addressByKey)
        let copyA = copy.addressByKey["k1"] as? STAddressModel
        let originalA = container.addressByKey["k1"] as? STAddressModel
        XCTAssertNotNil(copyA)
        XCTAssertNotNil(originalA)
        XCTAssertFalse(copyA === originalA)
        XCTAssertEqual(copyA?.city, "BJ")

        copyA?.city = "SH"
        XCTAssertEqual(originalA?.city, "BJ")
        XCTAssertEqual(copyA?.city, "SH")
    }

    // MARK: - description / debugDescription (smoke)

    func test_description_contains_key_information_in_standard_and_flexible_modes() {
        let standard = STUserModel()
        standard.userId = 1
        standard.userName = "alice"
        standard.isVip = true
        let standardDesc = standard.description
        XCTAssertTrue(standardDesc.contains("userId"))
        XCTAssertTrue(standardDesc.contains("userName"))
        XCTAssertTrue(standardDesc.contains("isVip"))

        let flexible = STBaseModel()
        flexible.st_isFlexibleMode = true
        flexible.st_update(from: ["name": "alice", "age": 30])
        let flexDesc = flexible.description
        XCTAssertTrue(flexDesc.contains("name"))
        XCTAssertTrue(flexDesc.contains("alice"))
        XCTAssertTrue(flexDesc.contains("age"))
        XCTAssertTrue(flexDesc.contains("30"))
    }
}

// MARK: - Additional Test Models

/// 非 Optional 引用属性：用来验证 NSNull 不会把它写成无效状态。
final class STNonOptionalRefModel: STBaseModel {
    @objc var payload: STAddressModel = STAddressModel()
}

/// 可变容器属性：用来验证 st_update 写入后仍保持 NSMutable* 类型。
final class STMutableContainerModel: STBaseModel {
    @objc var items: NSMutableArray = NSMutableArray()
    @objc var mapping: NSMutableDictionary = NSMutableDictionary()
}

final class STArrayModelContainer: STBaseModel {
    @objc var addressList: NSMutableArray = NSMutableArray()
}

final class STDictionaryModelContainer: STBaseModel {
    @objc var addressByKey: NSMutableDictionary = NSMutableDictionary()
}
