//
//  STNetworkCrypto.swift
//  STBaseProject
//
//  Created by stack on 2018/12/10.
//

import Foundation
import CryptoKit
import CommonCrypto

// MARK: - 加密配置
public struct STCryptoConfig {
    let algorithm: String
    let keyLength: Int
    let nonceLength: Int
    let tagLength: Int
    
    public static let aes256GCM = STCryptoConfig(
        algorithm: "AES-256-GCM",
        keyLength: 32,
        nonceLength: 12,
        tagLength: 16
    )
    
    public static let aes256CBC = STCryptoConfig(
        algorithm: "AES-256-CBC",
        keyLength: 32,
        nonceLength: 16,
        tagLength: 0
    )
}

// MARK: - 加密错误类型
public enum STCryptoError: Error, LocalizedError {
    case invalidData
    case encryptionFailed
    case decryptionFailed
    case invalidSignature
    case invalidKey
    case invalidNonce
    case invalidTag
    case keyGenerationFailed
    case unsupportedAlgorithm
    
    public var errorDescription: String? {
        switch self {
        case .invalidData:
            return "无效的数据"
        case .encryptionFailed:
            return "加密失败"
        case .decryptionFailed:
            return "解密失败"
        case .invalidSignature:
            return "签名验证失败"
        case .invalidKey:
            return "无效的密钥"
        case .invalidNonce:
            return "无效的随机数"
        case .invalidTag:
            return "无效的认证标签"
        case .keyGenerationFailed:
            return "密钥生成失败"
        case .unsupportedAlgorithm:
            return "不支持的加密算法"
        }
    }
}

// MARK: - 网络加密工具类
public class STNetworkCrypto {
    
    // MARK: - 单例
    public static let shared = STNetworkCrypto()
    
    // MARK: - 属性
    private var defaultConfig: STCryptoConfig = .aes256GCM
    private var keyCache: [String: SymmetricKey] = [:]
    
    // MARK: - 初始化
    private init() {}
    
    // MARK: - 配置方法
    
    /// 设置默认加密配置
    /// - Parameter config: 加密配置
    public func st_setDefaultConfig(_ config: STCryptoConfig) {
        self.defaultConfig = config
    }
    
    /// 获取默认加密配置
    /// - Returns: 当前默认配置
    public func st_getDefaultConfig() -> STCryptoConfig {
        return defaultConfig
    }
    
    // MARK: - 密钥管理
    
    /// 生成随机密钥
    /// - Parameter length: 密钥长度
    /// - Returns: 随机密钥数据
    public static func st_generateRandomKey(length: Int = 32) -> Data {
        return STDataUtils.randomData(length: length)
    }
    
    /// 从字符串生成密钥
    /// - Parameters:
    ///   - keyString: 密钥字符串
    ///   - config: 加密配置
    /// - Returns: 对称密钥
    public static func st_generateKey(from keyString: String, config: STCryptoConfig = .aes256GCM) throws -> SymmetricKey {
        let keyString = keyString.st_sha256()
        let keyData = Data(keyString.utf8.prefix(config.keyLength))
        return SymmetricKey(data: keyData)
    }
    
    /// 获取缓存的密钥
    /// - Parameter keyString: 密钥字符串
    /// - Returns: 对称密钥
    private func st_getCachedKey(_ keyString: String) -> SymmetricKey? {
        return keyCache[keyString]
    }
    
    /// 缓存密钥
    /// - Parameters:
    ///   - keyString: 密钥字符串
    ///   - key: 对称密钥
    private func st_cacheKey(_ keyString: String, key: SymmetricKey) {
        keyCache[keyString] = key
    }
    
    /// 清除密钥缓存
    public func st_clearKeyCache() {
        keyCache.removeAll()
    }
    
    // MARK: - 数据加密
    
    /// 加密数据
    /// - Parameters:
    ///   - data: 要加密的数据
    ///   - keyString: 密钥字符串
    ///   - config: 加密配置
    /// - Returns: 加密后的数据（nonce + ciphertext + tag）
    public static func st_encryptData(_ data: Data, keyString: String, config: STCryptoConfig = .aes256GCM) throws -> Data {
        guard !data.isEmpty else {
            throw STCryptoError.invalidData
        }
        
        guard !keyString.isEmpty else {
            throw STCryptoError.invalidKey
        }
        
        do {
            switch config.algorithm {
            case "AES-256-GCM":
                return try st_encryptAES256GCM(data, keyString: keyString, config: config)
            case "AES-256-CBC":
                return try st_encryptAES256CBC(data, keyString: keyString, config: config)
            default:
                throw STCryptoError.unsupportedAlgorithm
            }
        } catch {
            throw STCryptoError.encryptionFailed
        }
    }
    
    /// AES-256-GCM 加密
    private static func st_encryptAES256GCM(_ data: Data, keyString: String, config: STCryptoConfig) throws -> Data {
        // 生成密钥
        let keyString = keyString.st_sha256()
        let keyData = Data(keyString.utf8.prefix(config.keyLength))
        let symmetricKey = SymmetricKey(data: keyData)
        
        // 生成随机nonce
        let nonce = AES.GCM.Nonce()
        
        // 加密数据
        let sealedBox = try AES.GCM.seal(data, using: symmetricKey, nonce: nonce)
        
        // 组合nonce + 加密数据 + 认证标签
        var result = Data()
        result.append(Data(nonce))
        result.append(sealedBox.ciphertext)
        result.append(sealedBox.tag)
        
        return result
    }
    
    /// AES-256-CBC 加密
    private static func st_encryptAES256CBC(_ data: Data, keyString: String, config: STCryptoConfig) throws -> Data {
        // 生成密钥
        let keyString = keyString.st_sha256()
        let keyData = Data(keyString.utf8.prefix(config.keyLength))
        let key = keyData
        
        // 生成随机IV
        let iv = STDataUtils.randomData(length: config.nonceLength)
        
        // 使用CommonCrypto进行CBC加密
        let encryptedData = try st_encryptCBC(data: data, key: key, iv: iv)
        
        // 组合IV + 加密数据
        var result = Data()
        result.append(iv)
        result.append(encryptedData)
        
        return result
    }
    
    /// CBC加密实现
    private static func st_encryptCBC(data: Data, key: Data, iv: Data) throws -> Data {
        let dataLength = data.count
        let bufferSize = dataLength + kCCBlockSizeAES128
        var buffer = Data(count: bufferSize)
        var numBytesEncrypted: size_t = 0
        
        let status = buffer.withUnsafeMutableBytes { bufferBytes in
            data.withUnsafeBytes { dataBytes in
                key.withUnsafeBytes { keyBytes in
                    iv.withUnsafeBytes { ivBytes in
                        CCCrypt(
                            CCOperation(kCCEncrypt),
                            CCAlgorithm(kCCAlgorithmAES128),
                            CCOptions(kCCOptionPKCS7Padding),
                            keyBytes.bindMemory(to: UInt8.self).baseAddress, key.count,
                            ivBytes.bindMemory(to: UInt8.self).baseAddress,
                            dataBytes.bindMemory(to: UInt8.self).baseAddress, dataLength,
                            bufferBytes.bindMemory(to: UInt8.self).baseAddress, bufferSize,
                            &numBytesEncrypted
                        )
                    }
                }
            }
        }
        
        guard status == kCCSuccess else {
            throw STCryptoError.encryptionFailed
        }
        
        return buffer.prefix(numBytesEncrypted)
    }
    
    // MARK: - 数据解密
    
    /// 解密数据
    /// - Parameters:
    ///   - encryptedData: 加密的数据
    ///   - keyString: 密钥字符串
    ///   - config: 加密配置
    /// - Returns: 解密后的数据
    public static func st_decryptData(_ encryptedData: Data, keyString: String, config: STCryptoConfig = .aes256GCM) throws -> Data {
        guard !encryptedData.isEmpty else {
            throw STCryptoError.invalidData
        }
        
        guard !keyString.isEmpty else {
            throw STCryptoError.invalidKey
        }
        
        do {
            switch config.algorithm {
            case "AES-256-GCM":
                return try st_decryptAES256GCM(encryptedData, keyString: keyString, config: config)
            case "AES-256-CBC":
                return try st_decryptAES256CBC(encryptedData, keyString: keyString, config: config)
            default:
                throw STCryptoError.unsupportedAlgorithm
            }
        } catch {
            throw STCryptoError.decryptionFailed
        }
    }
    
    /// AES-256-GCM 解密
    private static func st_decryptAES256GCM(_ encryptedData: Data, keyString: String, config: STCryptoConfig) throws -> Data {
        guard encryptedData.count > config.nonceLength + config.tagLength else {
            throw STCryptoError.invalidData
        }
        
        // 提取组件
        let nonceData = encryptedData.prefix(config.nonceLength)
        let ciphertext = encryptedData.dropFirst(config.nonceLength).dropLast(config.tagLength)
        let tag = encryptedData.suffix(config.tagLength)
        
        // 生成密钥
        let keyString = keyString.st_sha256()
        let keyData = Data(keyString.utf8.prefix(config.keyLength))
        let symmetricKey = SymmetricKey(data: keyData)
        
        // 创建SealedBox
        let nonce = try AES.GCM.Nonce(data: nonceData)
        let sealedBox = try AES.GCM.SealedBox(nonce: nonce, ciphertext: Data(ciphertext), tag: Data(tag))
        
        // 解密数据
        return try AES.GCM.open(sealedBox, using: symmetricKey)
    }
    
    /// AES-256-CBC 解密
    private static func st_decryptAES256CBC(_ encryptedData: Data, keyString: String, config: STCryptoConfig) throws -> Data {
        guard encryptedData.count > config.nonceLength else {
            throw STCryptoError.invalidData
        }
        
        // 提取IV和加密数据
        let iv = encryptedData.prefix(config.nonceLength)
        let ciphertext = encryptedData.dropFirst(config.nonceLength)
        
        // 生成密钥
        let keyString = keyString.st_sha256()
        let keyData = Data(keyString.utf8.prefix(config.keyLength))
        let key = keyData
        
        // 使用CommonCrypto进行CBC解密
        return try st_decryptCBC(data: Data(ciphertext), key: key, iv: Data(iv))
    }
    
    /// CBC解密实现
    private static func st_decryptCBC(data: Data, key: Data, iv: Data) throws -> Data {
        let dataLength = data.count
        let bufferSize = dataLength + kCCBlockSizeAES128
        var buffer = Data(count: bufferSize)
        var numBytesDecrypted: size_t = 0
        
        let status = buffer.withUnsafeMutableBytes { bufferBytes in
            data.withUnsafeBytes { dataBytes in
                key.withUnsafeBytes { keyBytes in
                    iv.withUnsafeBytes { ivBytes in
                        CCCrypt(
                            CCOperation(kCCDecrypt),
                            CCAlgorithm(kCCAlgorithmAES128),
                            CCOptions(kCCOptionPKCS7Padding),
                            keyBytes.bindMemory(to: UInt8.self).baseAddress, key.count,
                            ivBytes.bindMemory(to: UInt8.self).baseAddress,
                            dataBytes.bindMemory(to: UInt8.self).baseAddress, dataLength,
                            bufferBytes.bindMemory(to: UInt8.self).baseAddress, bufferSize,
                            &numBytesDecrypted
                        )
                    }
                }
            }
        }
        
        guard status == kCCSuccess else {
            throw STCryptoError.decryptionFailed
        }
        
        return buffer.prefix(numBytesDecrypted)
    }
    
    // MARK: - 签名和验证
    
    /// 生成数据签名
    /// - Parameters:
    ///   - data: 要签名的数据
    ///   - secret: 签名密钥
    ///   - timestamp: 时间戳
    /// - Returns: 签名字符串
    public static func st_signData(_ data: Data, secret: String, timestamp: TimeInterval) -> String {
        let timestampString = String(Int(timestamp))
        let dataString = data.base64EncodedString()
        let signString = "\(dataString)\(timestampString)\(secret)"
        return signString.st_hmacSha256(key: secret)
    }
    
    /// 验证数据签名
    /// - Parameters:
    ///   - data: 要验证的数据
    ///   - signature: 签名
    ///   - secret: 签名密钥
    ///   - timestamp: 时间戳
    /// - Returns: 是否验证通过
    public static func st_verifySignature(_ data: Data, signature: String, secret: String, timestamp: TimeInterval) -> Bool {
        let expectedSignature = st_signData(data, secret: secret, timestamp: timestamp)
        return STEncryptionUtils.st_secureCompare(signature, expectedSignature)
    }
    
    // MARK: - 便捷方法
    
    /// 加密字符串
    /// - Parameters:
    ///   - string: 要加密的字符串
    ///   - keyString: 密钥字符串
    ///   - config: 加密配置
    /// - Returns: 加密后的数据
    public static func st_encryptString(_ string: String, keyString: String, config: STCryptoConfig = .aes256GCM) throws -> Data {
        guard let data = string.data(using: .utf8) else {
            throw STCryptoError.invalidData
        }
        return try st_encryptData(data, keyString: keyString, config: config)
    }
    
    /// 解密为字符串
    /// - Parameters:
    ///   - encryptedData: 加密的数据
    ///   - keyString: 密钥字符串
    ///   - config: 加密配置
    /// - Returns: 解密后的字符串
    public static func st_decryptToString(_ encryptedData: Data, keyString: String, config: STCryptoConfig = .aes256GCM) throws -> String {
        let decryptedData = try st_decryptData(encryptedData, keyString: keyString, config: config)
        guard let string = String(data: decryptedData, encoding: .utf8) else {
            throw STCryptoError.decryptionFailed
        }
        return string
    }
    
    /// 加密字典
    /// - Parameters:
    ///   - dictionary: 要加密的字典
    ///   - keyString: 密钥字符串
    ///   - config: 加密配置
    /// - Returns: 加密后的数据
    public static func st_encryptDictionary(_ dictionary: [String: Any], keyString: String, config: STCryptoConfig = .aes256GCM) throws -> Data {
        let jsonData = try JSONSerialization.data(withJSONObject: dictionary)
        return try st_encryptData(jsonData, keyString: keyString, config: config)
    }
    
    /// 解密为字典
    /// - Parameters:
    ///   - encryptedData: 加密的数据
    ///   - keyString: 密钥字符串
    ///   - config: 加密配置
    /// - Returns: 解密后的字典
    public static func st_decryptToDictionary(_ encryptedData: Data, keyString: String, config: STCryptoConfig = .aes256GCM) throws -> [String: Any] {
        let decryptedData = try st_decryptData(encryptedData, keyString: keyString, config: config)
        guard let dictionary = try JSONSerialization.jsonObject(with: decryptedData) as? [String: Any] else {
            throw STCryptoError.decryptionFailed
        }
        return dictionary
    }
}

// MARK: - 扩展方法
public extension STNetworkCrypto {
    
    /// 批量加密数据
    /// - Parameters:
    ///   - dataArray: 数据数组
    ///   - keyString: 密钥字符串
    ///   - config: 加密配置
    /// - Returns: 加密后的数据数组
    static func st_encryptBatch(_ dataArray: [Data], keyString: String, config: STCryptoConfig = .aes256GCM) throws -> [Data] {
        var encryptedArray: [Data] = []
        
        for data in dataArray {
            let encryptedData = try st_encryptData(data, keyString: keyString, config: config)
            encryptedArray.append(encryptedData)
        }
        
        return encryptedArray
    }
    
    /// 批量解密数据
    /// - Parameters:
    ///   - encryptedArray: 加密数据数组
    ///   - keyString: 密钥字符串
    ///   - config: 加密配置
    /// - Returns: 解密后的数据数组
    static func st_decryptBatch(_ encryptedArray: [Data], keyString: String, config: STCryptoConfig = .aes256GCM) throws -> [Data] {
        var decryptedArray: [Data] = []
        
        for encryptedData in encryptedArray {
            let decryptedData = try st_decryptData(encryptedData, keyString: keyString, config: config)
            decryptedArray.append(decryptedData)
        }
        
        return decryptedArray
    }
    
    /// 验证数据完整性
    /// - Parameters:
    ///   - data: 原始数据
    ///   - encryptedData: 加密数据
    ///   - keyString: 密钥字符串
    ///   - config: 加密配置
    /// - Returns: 是否完整
    static func st_verifyDataIntegrity(_ data: Data, encryptedData: Data, keyString: String, config: STCryptoConfig = .aes256GCM) -> Bool {
        do {
            let decryptedData = try st_decryptData(encryptedData, keyString: keyString, config: config)
            return data == decryptedData
        } catch {
            return false
        }
    }
}

// MARK: - 性能优化
public extension STNetworkCrypto {
    
    /// 异步加密数据
    /// - Parameters:
    ///   - data: 要加密的数据
    ///   - keyString: 密钥字符串
    ///   - config: 加密配置
    ///   - completion: 完成回调
    static func st_encryptDataAsync(_ data: Data, keyString: String, config: STCryptoConfig = .aes256GCM, completion: @escaping (Result<Data, STCryptoError>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let encryptedData = try st_encryptData(data, keyString: keyString, config: config)
                DispatchQueue.main.async {
                    completion(.success(encryptedData))
                }
            } catch let error as STCryptoError {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(.encryptionFailed))
                }
            }
        }
    }
    
    /// 异步解密数据
    /// - Parameters:
    ///   - encryptedData: 加密的数据
    ///   - keyString: 密钥字符串
    ///   - config: 加密配置
    ///   - completion: 完成回调
    static func st_decryptDataAsync(_ encryptedData: Data, keyString: String, config: STCryptoConfig = .aes256GCM, completion: @escaping (Result<Data, STCryptoError>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let decryptedData = try st_decryptData(encryptedData, keyString: keyString, config: config)
                DispatchQueue.main.async {
                    completion(.success(decryptedData))
                }
            } catch let error as STCryptoError {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(.decryptionFailed))
                }
            }
        }
    }
}
