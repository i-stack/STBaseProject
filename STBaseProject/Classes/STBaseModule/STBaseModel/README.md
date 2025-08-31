# STBaseModel - 统一iOS模型基类

## 概述

`STBaseModel` 是一个功能强大的统一iOS模型基类，为iOS项目提供完整的模型管理解决方案。通过继承该类，可以快速构建具有丰富功能的模型类，支持标准模式和灵活模式两种使用方式。

## 设计原则

为了避免与使用者的类或方法冲突，所有公共接口都添加了 `ST` 前缀和 `st_` 方法前缀：

- **类名**: `STBaseModel`, `STFlexibleValue`, `STBaseResponseModel` 等
- **方法名**: `st_update()`, `st_toDictionary()`, `st_getString()` 等
- **属性名**: `st_isFlexibleMode`, `st_code`, `st_message` 等

## 主要特性

### 1. 双模式支持
- **标准模式**: 适用于数据结构稳定、字段类型固定的场景
- **灵活模式**: 适用于处理服务器端字段类型不统一的场景
- **模式切换**: 通过 `st_isFlexibleMode` 属性轻松切换

### 2. 基础功能
- **内存管理**: 自动内存泄漏检测和调试信息
- **键值编码**: 安全的键值编码处理，避免崩溃
- **动态方法解析**: 优雅处理未识别的方法调用

### 3. 模型工具
- **属性反射**: 动态获取模型的所有属性名称
- **字典转换**: 模型与字典之间的双向转换
- **属性更新**: 从字典批量更新模型属性
- **模型描述**: 自动生成可读的模型描述

### 4. 高级功能
- **对象复制**: 支持模型对象的深拷贝
- **相等性比较**: 基于属性值的相等性判断
- **哈希支持**: 自动生成基于属性的哈希值
- **Codable支持**: 完整的JSON编码解码支持
- **类型转换**: 智能处理不同类型数据的转换

## 使用方法

### 1. 标准模式 (Standard Mode)

标准模式适用于数据结构稳定、字段类型固定的场景：

```swift
import STBaseProject

class STStandardUserModel: STBaseModel {
    var userId: String = ""
    var username: String = ""
    var email: String = ""
    var age: Int = 0
    var isActive: Bool = false
}

// 创建实例
let user = STStandardUserModel()
user.userId = "12345"
user.username = "john_doe"
user.email = "john@example.com"
user.age = 30
user.isActive = true

// 使用标准模式方法
let properties = user.st_propertyNames()
let userDict = user.st_toDictionary()
user.st_update(from: updateDict)
```

### 2. 灵活模式 (Flexible Mode)

灵活模式适用于处理服务器端字段类型不统一的场景：

```swift
class STFlexibleUserModel: STBaseModel {
    
    /// 用户ID - 可能是字符串或数字
    var userId: String {
        return st_getString(forKey: "userId", default: "")
    }
    
    /// 年龄 - 可能是字符串或数字
    var age: Int {
        return st_getInt(forKey: "age", default: 0)
    }
    
    /// 是否激活 - 可能是布尔值、字符串或数字
    var isActive: Bool {
        return st_getBool(forKey: "isActive", default: false)
    }
    
    override init() {
        super.init()
        // 启用灵活模式
        st_isFlexibleMode = true
    }
}
```

### 属性反射

```swift
// 获取所有属性名称
let properties = user.st_propertyNames()
print(properties) // ["userId", "username", "email", "age", "isActive"]

// 获取类属性名称
let classProperties = STStandardUserModel.st_propertyNames()
```

### 字典转换

```swift
// 模型转字典
let userDict = user.st_toDictionary()
print(userDict)
// ["userId": "12345", "username": "john_doe", "email": "john@example.com", "age": 30, "isActive": true]

// 从字典更新模型
let updateDict = ["age": 31, "isActive": false]
user.st_update(from: updateDict)
```

### 模型描述

```swift
// 自动生成描述
print(user)
// UserModel {
//   userId: 12345
//   username: john_doe
//   email: john@example.com
//   age: 31
//   isActive: false
// }
```

### 对象复制

```swift
// 复制模型
let userCopy = user.st_copy() as! STStandardUserModel
userCopy.username = "jane_doe"
```

### 相等性比较

```swift
let anotherUser = STStandardUserModel()
anotherUser.userId = "12345"
anotherUser.username = "john_doe"
anotherUser.email = "john@example.com"
anotherUser.age = 31
anotherUser.isActive = false

print(user.isEqual(anotherUser)) // true
```

### JSON编码解码

```swift
// 编码为JSON
do {
    let encoder = JSONEncoder()
    let data = try encoder.encode(user)
    let jsonString = String(data: data, encoding: .utf8)
    print(jsonString ?? "")
} catch {
    print("编码错误: \(error)")
}

// 从JSON解码
do {
    let decoder = JSONDecoder()
    let decodedUser = try decoder.decode(UserModel.self, from: data)
    print(decodedUser)
} catch {
    print("解码错误: \(error)")
}
```

### AnyCodable 使用

`AnyCodable` 是一个公开的结构体，可以用于处理任意类型的JSON编码解码：

```swift
// 基本类型包装
let stringValue = AnyCodable("Hello World")
let intValue = AnyCodable(42)
let boolValue = AnyCodable(true)

// 复杂类型包装
let arrayValue = AnyCodable([1, 2, 3, "four", 5.0])
let dictValue = AnyCodable([
    "name": "John",
    "age": 30,
    "isActive": true
])

// JSON编码
let encoder = JSONEncoder()
let data = try encoder.encode(dictValue)
let jsonString = String(data: data, encoding: .utf8)

// JSON解码
let decoder = JSONDecoder()
let decodedDict = try decoder.decode([String: AnyCodable].self, from: data)
for (key, value) in decodedDict {
    print("\(key): \(value.value)")
}
```

## 高级用法

### 泛型模型

```swift
class NetworkResponseModel<T: STBaseModel>: STBaseModel {
    var code: Int = 0
    var message: String = ""
    var data: T?
    var timestamp: TimeInterval = 0
}

// 使用泛型模型
let response = NetworkResponseModel<UserModel>()
response.code = 200
response.message = "success"
response.data = user
```

### 分页模型

```swift
class PaginationModel: STBaseModel {
    var page: Int = 1
    var pageSize: Int = 20
    var totalCount: Int = 0
    var totalPages: Int = 0
    var hasNextPage: Bool = false
    var hasPreviousPage: Bool = false
    
    // 计算属性
    var startIndex: Int {
        return (page - 1) * pageSize
    }
    
    var endIndex: Int {
        return min(startIndex + pageSize, totalCount)
    }
}
```

### 缓存模型

```swift
class CacheModel<T: STBaseModel>: STBaseModel {
    var key: String = ""
    var data: T?
    var expireTime: TimeInterval = 0
    var createTime: TimeInterval = 0
    
    var isExpired: Bool {
        return Date().timeIntervalSince1970 > expireTime
    }
    
    var age: TimeInterval {
        return Date().timeIntervalSince1970 - createTime
    }
}
```

## 模式选择指导

### 何时使用标准模式
- **数据结构稳定**: 服务器返回的字段类型和结构基本不变
- **类型安全要求高**: 需要编译时类型检查
- **性能要求高**: 避免运行时类型转换的开销
- **团队协作**: 多个开发者共同维护，需要明确的接口定义

### 何时使用灵活模式
- **字段类型不统一**: 同一个接口返回的字段类型可能不同
- **第三方API集成**: 处理不稳定的第三方接口
- **数据迁移**: 不同版本间的数据兼容
- **快速原型**: 需要快速处理各种数据格式

### 模式切换
```swift
class MyModel: STBaseModel {
    override init() {
        super.init()
        // 启用灵活模式
        st_isFlexibleMode = true
    }
    
    // 或者动态切换
    func enableFlexibleMode() {
        st_isFlexibleMode = true
    }
    
    func disableFlexibleMode() {
        st_isFlexibleMode = false
    }
}
```

### 数据清理机制
STBaseModel 在每次更新数据时都会自动清理之前的数据，确保数据一致性：

```swift
let model = STBaseModel()
model.st_isFlexibleMode = true

// 第一次更新
model.st_update(from: ["name": "John", "age": 30])
print(model.st_getAllKeys()) // ["name", "age"]

// 第二次更新 - 会自动清空之前的数据
model.st_update(from: ["title": "Developer", "salary": 50000])
print(model.st_getAllKeys()) // ["title", "salary"] - 之前的数据已被清空
```

**重要**: 这种自动清理机制确保了：
- 不会出现旧数据残留
- 每次更新都是全新的数据状态
- 避免了数据污染问题

## 最佳实践

### 1. 属性初始化
- 为所有属性提供默认值
- 使用适当的类型（避免使用 `Any` 类型）
- 考虑使用可选类型处理可能为空的值

### 2. 内存管理
- 在 `deinit` 中清理资源
- 避免循环引用
- 使用 `weak` 和 `unowned` 关键字

### 3. 性能优化
- 缓存 `propertyNames()` 结果
- 避免频繁调用 `toDictionary()`
- 使用计算属性优化性能

### 4. 错误处理
- 在 `update(from:)` 方法中验证数据
- 使用 `Codable` 的错误处理机制
- 提供有意义的错误信息

## AnyCodable 详解

`AnyCodable` 是 `STBaseModel` 提供的一个强大工具，用于处理任意类型的JSON编码解码。

### 主要特性

- **类型安全**: 包装任意类型，保持类型信息
- **JSON兼容**: 完全支持JSON编码解码
- **嵌套支持**: 支持数组和字典的嵌套结构
- **空值处理**: 正确处理 `null` 值

### 使用场景

1. **动态数据**: 处理未知结构的数据
2. **配置管理**: 存储和读取应用配置
3. **API响应**: 处理灵活的API响应数据
4. **缓存系统**: 存储任意类型的数据

### 性能考虑

- 对于已知类型的属性，建议直接使用具体类型
- `AnyCodable` 适合处理动态或未知类型的数据
- 大量使用可能影响性能，建议适度使用

## 注意事项

1. **属性类型**: 确保所有属性类型都支持 `Codable` 协议
2. **内存管理**: 避免在模型中使用强引用的闭包
3. **线程安全**: 模型类不是线程安全的，需要在主线程中使用
4. **性能考虑**: 大型模型可能影响性能，考虑使用懒加载
5. **数据清理**: 每次调用 `st_update(from:)` 方法时，会自动清空之前的数据，确保数据一致性
6. **模式切换**: 在同一个实例上切换模式时，建议重新调用 `st_update(from:)` 方法

## 更新日志

### v2.0.0
- 添加 Codable 支持
- 新增属性反射功能
- 优化字典转换性能
- 修复动态方法解析问题

### v1.0.0
- 基础模型功能
- 内存管理支持
- 键值编码处理
- 动态方法解析

## 许可证

本项目采用 MIT 许可证，详见 LICENSE 文件。
