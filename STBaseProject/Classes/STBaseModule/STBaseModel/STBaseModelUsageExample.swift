//
//  STBaseModelUsageExample.swift
//  STBaseProject
//
//  Created by stack on 2018/3/14.
//

import UIKit

// MARK: - 标准模式用户模型示例
class STStandardUserModel: STBaseModel {
    var userId: String = ""
    var username: String = ""
    var email: String = ""
    var age: Int = 0
    var isActive: Bool = false
    var createTime: Date = Date()
    
    required override init() {
        super.init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    public required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
}

// MARK: - 灵活模式用户模型示例
class STFlexibleUserModel: STBaseModel {
    
    /// 用户ID - 可能是字符串或数字
    var userId: String {
        return st_getString(forKey: "userId", default: "")
    }
    
    /// 用户名
    var username: String {
        return st_getString(forKey: "username", default: "")
    }
    
    /// 可能是字符串或数字
    var age: Int {
        return st_getInt(forKey: "age", default: 0)
    }
    
    /// 可能是布尔值、字符串或数字
    var isActive: Bool {
        return st_getBool(forKey: "isActive", default: false)
    }
    
    /// 可能是字符串、整数或浮点数
    var points: Double {
        return st_getDouble(forKey: "points", default: 0.0)
    }
    
    /// 可能是字符串或时间戳
    var createTime: String {
        return st_getString(forKey: "createTime", default: "")
    }
    
    required override init() {
        super.init()
        // 启用灵活模式
        st_isFlexibleMode = true
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        st_isFlexibleMode = true
    }
    
    public required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
}

// MARK: - 产品模型示例
class STProductModel: STBaseModel {
    var productId: String = ""
    var name: String = ""
    var price: Double = 0.0
    var category: String = ""
    var tags: [String] = []
    var metadata: [String: Any] = [:]
    
    required override init() {
        super.init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    public required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
}

// MARK: - 网络响应模型示例
class STUserResponseModel: STBaseResponseModel {
    
    required override init() {
        super.init()
        st_isFlexibleMode = true
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        st_isFlexibleMode = true
    }
    
    required init(from decoder: any Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
}

class STProductListResponseModel: STBasePaginationModel {
    
    required override init() {
        super.init()
        st_isFlexibleMode = true
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        st_isFlexibleMode = true
    }
    
    required init(from decoder: any Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
}

// MARK: - 使用示例
class STBaseModelUsageExample {
    
    static func demonstrateStandardMode() {
        print("=== STBaseModel 标准模式示例 ===")
        
        // 1. 创建标准用户模型
        let user = STStandardUserModel()
        user.userId = "12345"
        user.username = "john_doe"
        user.email = "john@example.com"
        user.age = 30
        user.isActive = true
        
        // 2. 获取属性名称
        let properties = user.st_propertyNames()
        print("用户属性: \(properties)")
        
        // 3. 转换为字典
        let userDict = user.st_toDictionary()
        print("用户字典: \(userDict)")
        
        // 4. 模型描述
        print("用户描述: \(user)")
        
        // 5. 从字典更新
        let updateDict = ["age": 31, "isActive": false] as [String : Any]
        user.st_update(from: updateDict)
        print("更新后用户: \(user)")
        
        // 6. 复制模型
        let userCopy = user.st_copy() as! STStandardUserModel
        print("用户副本: \(userCopy)")
        
        // 7. 相等性比较
        let anotherUser = STStandardUserModel()
        anotherUser.userId = "12345"
        anotherUser.username = "john_doe"
        anotherUser.email = "john@example.com"
        anotherUser.age = 31
        anotherUser.isActive = false
        
        print("用户是否相等: \(user.isEqual(anotherUser))")
    }
    
    static func demonstrateFlexibleMode() {
        print("\n=== STBaseModel 灵活模式示例 ===")
        
        // 1. 模拟服务器返回的不同类型数据
        let serverData1: [String: Any] = [
            "userId": "12345",           // 字符串类型
            "username": "john_doe",
            "age": 30,                   // 数字类型
            "isActive": true,            // 布尔类型
            "points": 100.5,             // 浮点数
            "createTime": "2024-01-01",
            "tags": ["vip", "verified"], // 数组
            "metadata": [                 // 字典
                "level": "gold",
                "vipExpiry": "2024-12-31"
            ]
        ]
        
        let serverData2: [String: Any] = [
            "userId": 67890,             // 数字类型（与上面不同）
            "username": "jane_doe",
            "age": "25",                 // 字符串类型（与上面不同）
            "isActive": "1",             // 字符串类型（与上面不同）
            "points": "200",             // 字符串类型（与上面不同）
            "createTime": 1704067200,    // 时间戳（与上面不同）
            "tags": "premium",           // 字符串（与上面不同）
            "metadata": "special"        // 字符串（与上面不同）
        ]
        
        // 2. 创建灵活模式模型并更新数据
        let user1 = STFlexibleUserModel(from: serverData1)
        let user2 = STFlexibleUserModel(from: serverData2)
        
        // 3. 安全获取数据，无需担心类型问题
        print("用户1:")
        print("  ID: \(user1.userId) (类型: \(user1.st_getValueType(forKey: "userId")))")
        print("  年龄: \(user1.age) (类型: \(user1.st_getValueType(forKey: "age")))")
        print("  激活状态: \(user1.isActive) (类型: \(user1.st_getValueType(forKey: "isActive")))")
        print("  积分: \(user1.points) (类型: \(user1.st_getValueType(forKey: "points")))")
        
        print("\n用户2:")
        print("  ID: \(user2.userId) (类型: \(user2.st_getValueType(forKey: "userId")))")
        print("  年龄: \(user2.age) (类型: \(user2.st_getValueType(forKey: "age")))")
        print("  激活状态: \(user2.isActive) (类型: \(user2.st_getValueType(forKey: "isActive")))")
        print("  积分: \(user2.points) (类型: \(user2.st_getValueType(forKey: "points")))")
    }
    
    static func demonstrateNetworkResponse() {
        print("\n=== 网络响应示例 ===")
        
        // 1. 模拟网络响应
        let responseData: [String: Any] = [
            "code": 200,
            "message": "success",
            "timestamp": 1704067200.0,
            "data": [
                "userId": "12345",
                "username": "john_doe",
                "age": 30,
                "isActive": true
            ]
        ]
        
        let response = STUserResponseModel(from: responseData)
        print("网络响应:")
        print("  状态码: \(response.st_code)")
        print("  消息: \(response.st_message)")
        print("  是否成功: \(response.st_isSuccess)")
        
        // 2. 模拟分页响应
        let paginationData: [String: Any] = [
            "code": 200,
            "message": "success",
            "page": 1,
            "pageSize": 10,
            "totalCount": 100,
            "totalPages": 10,
            "hasNextPage": true,
            "hasPreviousPage": false,
            "list": [
                [
                    "productId": "P001",
                    "name": "iPhone 15",
                    "price": 999.99
                ],
                [
                    "productId": "P002",
                    "name": "MacBook Pro",
                    "price": 1999.99
                ]
            ]
        ]
        
        let paginationResponse = STProductListResponseModel(from: paginationData)
        print("\n分页响应:")
        print("  当前页: \(paginationResponse.st_page)")
        print("  每页大小: \(paginationResponse.st_pageSize)")
        print("  总数量: \(paginationResponse.st_totalCount)")
        print("  总页数: \(paginationResponse.st_totalPages)")
        print("  是否有下一页: \(paginationResponse.st_hasNextPage)")
        print("  产品数量: \(paginationResponse.st_list.count)")
    }
    
    static func demonstrateTypeHandling() {
        print("\n=== 类型处理示例 ===")
        
        // 演示不同类型的值如何处理
        let testData: [String: Any] = [
            "stringAsInt": "42",
            "intAsString": 123,
            "boolAsString": "true",
            "boolAsInt": 1,
            "doubleAsString": "3.14",
            "arrayAsString": "item1,item2,item3",
            "nullValue": NSNull(),
            "mixedArray": [1, "two", 3.0, true, NSNull()]
        ]
        
        let testModel = STFlexibleUserModel(from: testData)
        
        print("类型转换示例:")
        print("  '42' -> Int: \(testModel.st_getInt(forKey: "stringAsInt", default: -1))")
        print("  123 -> String: \(testModel.st_getString(forKey: "intAsString", default: ""))")
        print("  'true' -> Bool: \(testModel.st_getBool(forKey: "boolAsString", default: false))")
        print("  1 -> Bool: \(testModel.st_getBool(forKey: "boolAsInt", default: false))")
        print("  '3.14' -> Double: \(testModel.st_getDouble(forKey: "doubleAsString", default: 0.0))")
        print("  空值处理: \(testModel.st_getString(forKey: "nullValue", default: "默认值"))")
        
        // 获取原始值类型
        print("\n原始数据类型:")
        for key in testModel.st_getAllKeys() {
            let type = testModel.st_getValueType(forKey: key)
            print("  \(key): \(type)")
        }
    }
    
    static func demonstrateDataCleanup() {
        print("\n=== 数据清理示例 ===")
        
        let model = STFlexibleUserModel()
        
        // 第一次更新
        let data1 = ["name": "John", "age": 30, "city": "New York"] as [String : Any]
        model.st_update(from: data1)
        print("第一次更新后键数量: \(model.st_getAllKeys().count)")
        print("第一次更新后键: \(model.st_getAllKeys())")
        
        // 第二次更新
        let data2 = ["title": "Developer", "salary": 50000, "experience": 5] as [String : Any]
        model.st_update(from: data2)
        print("第二次更新后键数量: \(model.st_getAllKeys().count)")
        print("第二次更新后键: \(model.st_getAllKeys())")
        
        // 验证旧数据是否被清理
        let oldKeys = ["name", "age", "city"]
        let hasOldData = oldKeys.contains { model.st_containsKey($0) }
        print("是否包含旧数据: \(hasOldData)")
        
        // 验证新数据是否正确
        let newKeys = ["title", "salary", "experience"]
        let hasNewData = newKeys.allSatisfy { model.st_containsKey($0) }
        print("是否包含新数据: \(hasNewData)")
    }
    
    static func demonstrateCodable() {
        print("\n=== Codable 支持示例 ===")
        
        let user = STStandardUserModel()
        user.userId = "12345"
        user.username = "john_doe"
        user.email = "john@example.com"
        user.age = 30
        user.isActive = true
        
        // JSON 编码
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            
            let data = try encoder.encode(user)
            let jsonString = String(data: data, encoding: .utf8) ?? ""
            print("编码后的JSON: \(jsonString)")
            
            // JSON 解码
            let decoder = JSONDecoder()
            let decodedUser = try decoder.decode(STStandardUserModel.self, from: data)
            print("解码后的用户: \(decodedUser)")
            
        } catch {
            print("编码/解码错误: \(error)")
        }
    }
}
