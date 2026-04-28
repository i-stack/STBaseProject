//
//  STKeychainHelper.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2022/1/15.
//

import UIKit
import Security
import LocalAuthentication

public enum STKeychainAccessControl {
    case whenUnlocked
    case whenUnlockedThisDeviceOnly
    case afterFirstUnlock
    case afterFirstUnlockThisDeviceOnly
    case whenPasscodeSetThisDeviceOnly
    case biometricAny
    case biometricCurrentSet
    case devicePasscode
    case applicationPassword
    case biometricAnyOrDevicePasscode
    case biometricCurrentSetOrDevicePasscode
    
    var secAccessControl: SecAccessControl? {
        var flags: SecAccessControlCreateFlags = []
        var accessible: CFString = kSecAttrAccessibleWhenUnlocked
        
        switch self {
        case .whenUnlocked:
            accessible = kSecAttrAccessibleWhenUnlocked
            flags = []
        case .whenUnlockedThisDeviceOnly:
            accessible = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            flags = []
        case .afterFirstUnlock:
            accessible = kSecAttrAccessibleAfterFirstUnlock
            flags = []
        case .afterFirstUnlockThisDeviceOnly:
            accessible = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            flags = []
        case .whenPasscodeSetThisDeviceOnly:
            accessible = kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly
            flags = []
        case .biometricAny:
            accessible = kSecAttrAccessibleWhenUnlocked
            flags = .biometryAny
        case .biometricCurrentSet:
            accessible = kSecAttrAccessibleWhenUnlocked
            flags = .biometryCurrentSet
        case .devicePasscode:
            accessible = kSecAttrAccessibleWhenUnlocked
            flags = .devicePasscode
        case .applicationPassword:
            accessible = kSecAttrAccessibleWhenUnlocked
            flags = .applicationPassword
        case .biometricAnyOrDevicePasscode:
            accessible = kSecAttrAccessibleWhenUnlocked
            flags = [.biometryAny, .or, .devicePasscode]
        case .biometricCurrentSetOrDevicePasscode:
            accessible = kSecAttrAccessibleWhenUnlocked
            flags = [.biometryCurrentSet, .or, .devicePasscode]
        }
        
        return SecAccessControlCreateWithFlags(
            kCFAllocatorDefault,
            accessible,
            flags,
            nil
        )
    }
}

public enum STKeychainSync {
    case none
    case iCloud
}

public enum STKeychainError: Error, LocalizedError {
    case itemNotFound
    case duplicateItem
    case invalidData
    case unexpectedPasswordData
    case unhandledError(status: OSStatus)
    case accessDenied
    case biometricNotAvailable
    case biometricNotEnrolled
    case biometricLockout
    case biometricNotInteractive
    
    public var errorDescription: String? {
        switch self {
        case .itemNotFound:
            return "Keychain 项目未找到"
        case .duplicateItem:
            return "Keychain 项目已存在"
        case .invalidData:
            return "无效的数据"
        case .unexpectedPasswordData:
            return "意外的密码数据"
        case .unhandledError(let status):
            return "未处理的错误，状态码: \(status)"
        case .accessDenied:
            return "访问被拒绝"
        case .biometricNotAvailable:
            return "生物识别不可用"
        case .biometricNotEnrolled:
            return "未注册生物识别"
        case .biometricLockout:
            return "生物识别被锁定"
        case .biometricNotInteractive:
            return "生物识别不可交互"
        }
    }
}

public class STKeychainHelper {
    
    private static let service = Bundle.main.bundleIdentifier ?? "com.STBaseProject.app"
    private static let accessGroup: String? = nil // 可以设置为 App Group 标识符
        
    /// 保存字符串到 Keychain
    /// - Parameters:
    ///   - key: 键名
    ///   - value: 字符串值
    ///   - accessControl: 访问控制（可选）
    ///   - sync: 同步设置（可选）
    /// - Throws: STKeychainError
    public static func st_save(_ key: String, value: String, accessControl: STKeychainAccessControl? = nil, sync: STKeychainSync = .none) throws {
        guard let data = value.data(using: .utf8) else {
            throw STKeychainError.invalidData
        }
        try st_saveData(key, data: data, accessControl: accessControl, sync: sync)
    }
    
    /// 从 Keychain 加载字符串
    /// - Parameters:
    ///   - key: 键名
    ///   - accessControl: 访问控制（可选）
    /// - Returns: 字符串值，如果不存在返回 nil
    /// - Throws: STKeychainError
    public static func st_load(_ key: String, accessControl: STKeychainAccessControl? = nil) throws -> String? {
        guard let data = try st_loadData(key, accessControl: accessControl) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }
    
    /// 保存 Data 到 Keychain
    /// - Parameters:
    ///   - key: 键名
    ///   - data: 数据
    ///   - accessControl: 访问控制（可选）
    ///   - sync: 同步设置（可选）
    /// - Throws: STKeychainError
    public static func st_saveData(_ key: String, data: Data, accessControl: STKeychainAccessControl? = nil, sync: STKeychainSync = .none) throws {
        try? st_delete(key)
        var query = st_baseQuery(for: key)
        query[kSecValueData as String] = data
        if let accessControl = accessControl {
            query[kSecAttrAccessControl as String] = accessControl.secAccessControl
        }
        if sync != .none {
            query[kSecAttrSynchronizable as String] = kCFBooleanTrue!
        }
        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw STKeychainError.unhandledError(status: status)
        }
    }
    
    /// 从 Keychain 加载 Data
    /// - Parameters:
    ///   - key: 键名
    ///   - accessControl: 访问控制（可选）
    /// - Returns: 数据，如果不存在返回 nil
    /// - Throws: STKeychainError
    public static func st_loadData(_ key: String,
                                   accessControl: STKeychainAccessControl? = nil,
                                   authenticationContext: LAContext? = nil,
                                   authenticationPrompt: String? = nil) throws -> Data? {
        var query = st_baseQuery(for: key)
        query[kSecReturnData as String] = kCFBooleanTrue!
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        if let accessControl = accessControl {
            query[kSecAttrAccessControl as String] = accessControl.secAccessControl
        }
        if let authenticationContext {
            query[kSecUseAuthenticationContext as String] = authenticationContext
        }
        if let authenticationPrompt, !authenticationPrompt.isEmpty {
            query[kSecUseOperationPrompt as String] = authenticationPrompt
        }
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        switch status {
        case errSecSuccess:
            return result as? Data
        case errSecItemNotFound:
            return nil
        case errSecUserCanceled, errSecAuthFailed:
            throw STKeychainError.accessDenied
        default:
            throw STKeychainError.unhandledError(status: status)
        }
    }
    
    /// 删除 Keychain 项目
    /// - Parameter key: 键名
    /// - Throws: STKeychainError
    public static func st_delete(_ key: String) throws {
        let query = st_baseQuery(for: key)
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw STKeychainError.unhandledError(status: status)
        }
    }
    
    /// 检查 Keychain 项目是否存在
    /// - Parameter key: 键名
    /// - Returns: 是否存在
    public static func st_exists(_ key: String) -> Bool {
        var query = st_baseQuery(for: key)
        query[kSecReturnData as String] = kCFBooleanFalse!
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        let status = SecItemCopyMatching(query as CFDictionary, nil)
        return status == errSecSuccess
    }
        
    /// 保存布尔值到 Keychain
    /// - Parameters:
    ///   - key: 键名
    ///   - value: 布尔值
    ///   - accessControl: 访问控制（可选）
    ///   - sync: 同步设置（可选）
    /// - Throws: STKeychainError
    public static func st_saveBool(_ key: String, value: Bool, accessControl: STKeychainAccessControl? = nil, sync: STKeychainSync = .none) throws {
        let data = Data([value ? 1 : 0])
        try st_saveData(key, data: data, accessControl: accessControl, sync: sync)
    }
    
    /// 从 Keychain 加载布尔值
    /// - Parameters:
    ///   - key: 键名
    ///   - defaultValue: 默认值
    ///   - accessControl: 访问控制（可选）
    /// - Returns: 布尔值
    /// - Throws: STKeychainError
    public static func st_loadBool(_ key: String, defaultValue: Bool = false, accessControl: STKeychainAccessControl? = nil) throws -> Bool {
        guard let data = try st_loadData(key, accessControl: accessControl) else {
            return defaultValue
        }
        return data.first == 1
    }
    
    /// 保存整数到 Keychain
    /// - Parameters:
    ///   - key: 键名
    ///   - value: 整数值
    ///   - accessControl: 访问控制（可选）
    ///   - sync: 同步设置（可选）
    /// - Throws: STKeychainError
    public static func st_saveInt(_ key: String, value: Int, accessControl: STKeychainAccessControl? = nil, sync: STKeychainSync = .none) throws {
        let data = withUnsafeBytes(of: value.bigEndian) { Data($0) }
        try st_saveData(key, data: data, accessControl: accessControl, sync: sync)
    }
    
    /// 从 Keychain 加载整数
    /// - Parameters:
    ///   - key: 键名
    ///   - defaultValue: 默认值
    ///   - accessControl: 访问控制（可选）
    /// - Returns: 整数值
    /// - Throws: STKeychainError
    public static func st_loadInt(_ key: String, defaultValue: Int = 0, accessControl: STKeychainAccessControl? = nil) throws -> Int {
        guard let data = try st_loadData(key, accessControl: accessControl) else {
            return defaultValue
        }
        return data.withUnsafeBytes { $0.load(as: Int.self).bigEndian }
    }
    
    /// 保存浮点数到 Keychain
    /// - Parameters:
    ///   - key: 键名
    ///   - value: 浮点数值
    ///   - accessControl: 访问控制（可选）
    ///   - sync: 同步设置（可选）
    /// - Throws: STKeychainError
    public static func st_saveDouble(_ key: String, value: Double, accessControl: STKeychainAccessControl? = nil, sync: STKeychainSync = .none) throws {
        let data = withUnsafeBytes(of: value.bitPattern.bigEndian) { Data($0) }
        try st_saveData(key, data: data, accessControl: accessControl, sync: sync)
    }
    
    /// 从 Keychain 加载浮点数
    /// - Parameters:
    ///   - key: 键名
    ///   - defaultValue: 默认值
    ///   - accessControl: 访问控制（可选）
    /// - Returns: 浮点数值
    /// - Throws: STKeychainError
    public static func st_loadDouble(_ key: String, defaultValue: Double = 0.0, accessControl: STKeychainAccessControl? = nil) throws -> Double {
        guard let data = try st_loadData(key, accessControl: accessControl) else {
            return defaultValue
        }
        let bitPattern = data.withUnsafeBytes { $0.load(as: UInt64.self).bigEndian }
        return Double(bitPattern: bitPattern)
    }
        
    /// 批量保存数据到 Keychain
    /// - Parameter items: 键值对字典
    /// - Throws: STKeychainError
    public static func st_saveBatch(_ items: [String: Any]) throws {
        for (key, value) in items {
            if let stringValue = value as? String {
                try st_save(key, value: stringValue, accessControl: nil, sync: .none)
            } else if let dataValue = value as? Data {
                try st_saveData(key, data: dataValue)
            } else if let boolValue = value as? Bool {
                try st_saveBool(key, value: boolValue)
            } else if let intValue = value as? Int {
                try st_saveInt(key, value: intValue)
            } else if let doubleValue = value as? Double {
                try st_saveDouble(key, value: doubleValue)
            }
        }
    }
    
    /// 批量删除 Keychain 项目
    /// - Parameter keys: 键名数组
    /// - Throws: STKeychainError
    public static func st_deleteBatch(_ keys: [String]) throws {
        for key in keys {
            try st_delete(key)
        }
    }
    
    /// 获取所有 Keychain 项目的键名
    /// - Returns: 键名数组
    /// - Throws: STKeychainError
    public static func st_getAllKeys() throws -> [String] {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecReturnAttributes as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitAll
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                return []
            }
            throw STKeychainError.unhandledError(status: status)
        }
        guard let items = result as? [[String: Any]] else {
            return []
        }
        return items.compactMap { $0[kSecAttrAccount as String] as? String }
    }
        
    /// 检查生物识别是否可用
    /// - Returns: 是否可用
    public static func st_isBiometricAvailable() -> Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }
    
    /// 检查生物识别类型
    /// - Returns: 生物识别类型
    public static func st_getBiometricType() -> LABiometryType {
        let context = LAContext()
        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            return context.biometryType
        }
        return .none
    }
    
    /// 使用生物识别保存数据到 Keychain（保存时无需生物识别提示，提示仅在读取时出现）
    public static func st_saveWithBiometric(_ key: String, data: Data) throws {
        guard st_isBiometricAvailable() else {
            throw STKeychainError.biometricNotAvailable
        }
        try st_saveData(key, data: data, accessControl: .biometricCurrentSet)
    }
    
    /// 使用生物识别从 Keychain 加载数据
    /// - Parameters:
    ///   - key: 键名
    ///   - reason: 生物识别提示原因
    /// - Returns: 数据
    /// - Throws: STKeychainError
    public static func st_loadWithBiometric(_ key: String, reason: String = "使用生物识别访问您的数据") throws -> Data? {
        guard st_isBiometricAvailable() else {
            throw STKeychainError.biometricNotAvailable
        }
        let context = LAContext()
        return try st_loadData(
            key,
            accessControl: .biometricCurrentSet,
            authenticationContext: context,
            authenticationPrompt: reason
        )
    }
    
    // MARK: - 工具方法
    
    /// 清空所有 Keychain 项目
    /// - Throws: STKeychainError
    public static func st_clearAll() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw STKeychainError.unhandledError(status: status)
        }
    }
    
    /// 获取 Keychain 项目数量
    /// - Returns: 项目数量
    /// - Throws: STKeychainError
    public static func st_getItemCount() throws -> Int {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecReturnAttributes as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitAll
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                return 0
            }
            throw STKeychainError.unhandledError(status: status)
        }
        guard let items = result as? [[String: Any]] else {
            return 0
        }
        return items.count
    }

    private static func st_baseQuery(for key: String) -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: service
        ]
        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        return query
    }
}
