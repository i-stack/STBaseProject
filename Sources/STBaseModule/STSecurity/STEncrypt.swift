//
//  STEncrypt.swift
//  STBaseProject
//
//  Created by stack on 2018/12/22.
//

import Foundation
import CryptoKit
import Security
import CommonCrypto
// STBaseModule 内部文件，不需要导入自己

// MARK: - 加密算法类型
public enum STEncryptionAlgorithm {
    case aes256GCM
    case aes256CBC
    case chaCha20Poly1305
}

// MARK: - 哈希算法类型
public enum STHashAlgorithm {
    case md5
    case sha1
    case sha256
    case sha384
    case sha512
}

// MARK: - 加密错误类型
public enum STEncryptionError: Error, LocalizedError {
    case invalidKey
    case invalidData
    case encryptionFailed
    case decryptionFailed
    case keyGenerationFailed
    case invalidAlgorithm
    case invalidSalt
    case invalidIterations
    
    public var errorDescription: String? {
        switch self {
        case .invalidKey:
            return "无效的密钥"
        case .invalidData:
            return "无效的数据"
        case .encryptionFailed:
            return "加密失败"
        case .decryptionFailed:
            return "解密失败"
        case .keyGenerationFailed:
            return "密钥生成失败"
        case .invalidAlgorithm:
            return "无效的算法"
        case .invalidSalt:
            return "无效的盐值"
        case .invalidIterations:
            return "无效的迭代次数"
        }
    }
}

// MARK: - String 加密扩展
public extension String {
    
    // MARK: - 哈希算法
    
    /// 计算字符串的哈希值
    /// - Parameter algorithm: 哈希算法
    /// - Returns: 哈希值字符串
    func st_hash(algorithm: STHashAlgorithm) -> String {
        let inputData = Data(self.utf8)
        return inputData.st_hash(algorithm: algorithm)
    }
    
    /// MD5 哈希
    /// - Returns: MD5 哈希字符串
    func st_md5() -> String {
        return st_hash(algorithm: .md5)
    }
    
    /// SHA1 哈希
    /// - Returns: SHA1 哈希字符串
    func st_sha1() -> String {
        return st_hash(algorithm: .sha1)
    }
    
    /// SHA256 哈希
    /// - Returns: SHA256 哈希字符串
    func st_sha256() -> String {
        return st_hash(algorithm: .sha256)
    }
    
    /// SHA384 哈希
    /// - Returns: SHA384 哈希字符串
    func st_sha384() -> String {
        return st_hash(algorithm: .sha384)
    }
    
    /// SHA512 哈希
    /// - Returns: SHA512 哈希字符串
    func st_sha512() -> String {
        return st_hash(algorithm: .sha512)
    }
    
    // MARK: - HMAC 算法
    
    /// 计算 HMAC
    /// - Parameters:
    ///   - key: 密钥字符串
    ///   - algorithm: 哈希算法
    /// - Returns: HMAC 字符串
    func st_hmac(key: String, algorithm: STHashAlgorithm) -> String {
        let data = Data(self.utf8)
        let keyData = Data(key.utf8)
        return data.st_hmac(key: keyData, algorithm: algorithm)
    }
    
    /// HMAC-SHA256
    /// - Parameter key: 密钥字符串
    /// - Returns: HMAC-SHA256 字符串
    func st_hmacSha256(key: String) -> String {
        return st_hmac(key: key, algorithm: .sha256)
    }
    
    /// HMAC-SHA512
    /// - Parameter key: 密钥字符串
    /// - Returns: HMAC-SHA512 字符串
    func st_hmacSha512(key: String) -> String {
        return st_hmac(key: key, algorithm: .sha512)
    }
    
    // MARK: - 对称加密
    
    /// AES-256-GCM 加密
    /// - Parameters:
    ///   - key: 密钥字符串
    ///   - nonce: 随机数（可选，自动生成）
    /// - Returns: 加密结果，包含密文和认证标签
    func st_encryptAES256GCM(key: String, nonce: AES.GCM.Nonce? = nil) throws -> (ciphertext: Data, nonce: AES.GCM.Nonce) {
        let data = Data(self.utf8)
        let keyData = Data(key.utf8)
        guard keyData.count == 32 else {
            throw STEncryptionError.invalidKey
        }
        
        let symmetricKey = SymmetricKey(data: keyData)
        let usedNonce = nonce ?? AES.GCM.Nonce()
        
        do {
            let sealedBox = try AES.GCM.seal(data, using: symmetricKey, nonce: usedNonce)
            return (sealedBox.ciphertext, usedNonce)
        } catch {
            throw STEncryptionError.encryptionFailed
        }
    }
    
    /// AES-256-GCM 解密
    /// - Parameters:
    ///   - ciphertext: 密文数据
    ///   - key: 密钥字符串
    ///   - nonce: 随机数
    /// - Returns: 解密后的字符串
    func st_decryptAES256GCM(ciphertext: Data, key: String, nonce: AES.GCM.Nonce) throws -> String {
        let keyData = Data(key.utf8)
        guard keyData.count == 32 else {
            throw STEncryptionError.invalidKey
        }
        
        let symmetricKey = SymmetricKey(data: keyData)
        
        do {
            let sealedBox = try AES.GCM.SealedBox(nonce: nonce, ciphertext: ciphertext, tag: Data())
            let decryptedData = try AES.GCM.open(sealedBox, using: symmetricKey)
            return String(data: decryptedData, encoding: .utf8) ?? ""
        } catch {
            throw STEncryptionError.decryptionFailed
        }
    }
    
    // MARK: - 密码派生
    
    /// PBKDF2 密钥派生
    /// - Parameters:
    ///   - salt: 盐值字符串
    ///   - iterations: 迭代次数
    ///   - keyLength: 密钥长度
    /// - Returns: 派生的密钥数据
    func st_pbkdf2(salt: String, iterations: Int = 10000, keyLength: Int = 32) throws -> Data {
        let passwordData = Data(self.utf8)
        let saltData = Data(salt.utf8)
        return try passwordData.st_pbkdf2(salt: saltData, iterations: iterations, keyLength: keyLength)
    }
    
    // MARK: - 随机数生成
    
    /// 生成随机字符串
    /// - Parameters:
    ///   - length: 字符串长度
    ///   - characters: 字符集
    /// - Returns: 随机字符串
    static func st_randomString(length: Int, characters: String = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789") -> String {
        return String((0..<length).map { _ in characters.randomElement()! })
    }
    
    /// 生成随机十六进制字符串
    /// - Parameter length: 字符串长度
    /// - Returns: 随机十六进制字符串
    static func st_randomHexString(length: Int) -> String {
        let randomData = STDataUtils.randomData(length: length / 2)
        return randomData.toHexString()
    }
}

// MARK: - Data 加密扩展
public extension Data {
    
    // MARK: - 哈希算法
    
    /// 计算数据的哈希值
    /// - Parameter algorithm: 哈希算法
    /// - Returns: 哈希值字符串
    func st_hash(algorithm: STHashAlgorithm) -> String {
        switch algorithm {
        case .md5:
            let digest = Insecure.MD5.hash(data: self)
            return digest.map { String(format: "%02x", $0) }.joined()
        case .sha1:
            let digest = Insecure.SHA1.hash(data: self)
            return digest.map { String(format: "%02x", $0) }.joined()
        case .sha256:
            let digest = SHA256.hash(data: self)
            return digest.map { String(format: "%02x", $0) }.joined()
        case .sha384:
            let digest = SHA384.hash(data: self)
            return digest.map { String(format: "%02x", $0) }.joined()
        case .sha512:
            let digest = SHA512.hash(data: self)
            return digest.map { String(format: "%02x", $0) }.joined()
        }
    }
    
    // MARK: - HMAC 算法
    
    /// 计算 HMAC
    /// - Parameters:
    ///   - key: 密钥数据
    ///   - algorithm: 哈希算法
    /// - Returns: HMAC 字符串
    func st_hmac(key: Data, algorithm: STHashAlgorithm) -> String {
        let symmetricKey = SymmetricKey(data: key)
        
        switch algorithm {
        case .sha256:
            let hmac = HMAC<SHA256>.authenticationCode(for: self, using: symmetricKey)
            return Data(hmac).toHexString()
        case .sha384:
            let hmac = HMAC<SHA384>.authenticationCode(for: self, using: symmetricKey)
            return Data(hmac).toHexString()
        case .sha512:
            let hmac = HMAC<SHA512>.authenticationCode(for: self, using: symmetricKey)
            return Data(hmac).toHexString()
        default:
            // 对于不支持的算法，使用 SHA256
            let hmac = HMAC<SHA256>.authenticationCode(for: self, using: symmetricKey)
            return Data(hmac).toHexString()
        }
    }
    
    // MARK: - 对称加密
    
    /// AES-256-GCM 加密
    /// - Parameters:
    ///   - key: 密钥数据
    ///   - nonce: 随机数（可选，自动生成）
    /// - Returns: 加密结果，包含密文和认证标签
    func st_encryptAES256GCM(key: Data, nonce: AES.GCM.Nonce? = nil) throws -> (ciphertext: Data, nonce: AES.GCM.Nonce) {
        guard key.count == 32 else {
            throw STEncryptionError.invalidKey
        }
        
        let symmetricKey = SymmetricKey(data: key)
        let usedNonce = nonce ?? AES.GCM.Nonce()
        
        do {
            let sealedBox = try AES.GCM.seal(self, using: symmetricKey, nonce: usedNonce)
            return (sealedBox.ciphertext, usedNonce)
        } catch {
            throw STEncryptionError.encryptionFailed
        }
    }
    
    /// AES-256-GCM 解密
    /// - Parameters:
    ///   - ciphertext: 密文数据
    ///   - key: 密钥数据
    ///   - nonce: 随机数
    /// - Returns: 解密后的数据
    func st_decryptAES256GCM(ciphertext: Data, key: Data, nonce: AES.GCM.Nonce) throws -> Data {
        guard key.count == 32 else {
            throw STEncryptionError.invalidKey
        }
        
        let symmetricKey = SymmetricKey(data: key)
        
        do {
            let sealedBox = try AES.GCM.SealedBox(nonce: nonce, ciphertext: ciphertext, tag: Data())
            return try AES.GCM.open(sealedBox, using: symmetricKey)
        } catch {
            throw STEncryptionError.decryptionFailed
        }
    }
    
    // MARK: - 密码派生
    
    /// PBKDF2 密钥派生
    /// - Parameters:
    ///   - salt: 盐值数据
    ///   - iterations: 迭代次数
    ///   - keyLength: 密钥长度
    /// - Returns: 派生的密钥数据
    func st_pbkdf2(salt: Data, iterations: Int = 10000, keyLength: Int = 32) throws -> Data {
        guard iterations > 0 else {
            throw STEncryptionError.invalidIterations
        }
        
        guard keyLength > 0 else {
            throw STEncryptionError.invalidKey
        }
        
        var derivedKey = Data(count: keyLength)
        let result = derivedKey.withUnsafeMutableBytes { derivedKeyBytes in
            self.withUnsafeBytes { passwordBytes in
                salt.withUnsafeBytes { saltBytes in
                    CCKeyDerivationPBKDF(
                        CCPBKDFAlgorithm(kCCPBKDF2),
                        passwordBytes.bindMemory(to: Int8.self).baseAddress,
                        self.count,
                        saltBytes.bindMemory(to: UInt8.self).baseAddress,
                        salt.count,
                        CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
                        UInt32(iterations),
                        derivedKeyBytes.bindMemory(to: UInt8.self).baseAddress,
                        keyLength
                    )
                }
            }
        }
        
        guard result == kCCSuccess else {
            throw STEncryptionError.keyGenerationFailed
        }
        
        return derivedKey
    }
}

// MARK: - 加密工具类
public struct STEncryptionUtils {
    
    /// 生成随机密钥
    /// - Parameter length: 密钥长度（字节）
    /// - Returns: 随机密钥数据
    public static func st_generateRandomKey(length: Int = 32) -> Data {
        return STDataUtils.randomData(length: length)
    }
    
    /// 生成随机盐值
    /// - Parameter length: 盐值长度（字节）
    /// - Returns: 随机盐值数据
    public static func st_generateRandomSalt(length: Int = 16) -> Data {
        return STDataUtils.randomData(length: length)
    }
    
    /// 验证密钥强度
    /// - Parameter key: 密钥字符串
    /// - Returns: 密钥强度评分（0-100）
    public static func st_validateKeyStrength(_ key: String) -> Int {
        var score = 0
        
        // 长度评分
        if key.count >= 8 { score += 20 }
        if key.count >= 12 { score += 20 }
        if key.count >= 16 { score += 20 }
        
        // 字符类型评分
        if key.rangeOfCharacter(from: .lowercaseLetters) != nil { score += 10 }
        if key.rangeOfCharacter(from: .uppercaseLetters) != nil { score += 10 }
        if key.rangeOfCharacter(from: .decimalDigits) != nil { score += 10 }
        if key.rangeOfCharacter(from: .punctuationCharacters) != nil { score += 10 }
        
        return min(score, 100)
    }
    
    /// 安全的字符串比较（防止时序攻击）
    /// - Parameters:
    ///   - lhs: 第一个字符串
    ///   - rhs: 第二个字符串
    /// - Returns: 是否相等
    public static func st_secureCompare(_ lhs: String, _ rhs: String) -> Bool {
        let lhsData = Data(lhs.utf8)
        let rhsData = Data(rhs.utf8)
        return STDataUtils.constantTimeEquals(lhsData, rhsData)
    }
    
    /// 生成安全的随机令牌
    /// - Parameter length: 令牌长度
    /// - Returns: 随机令牌字符串
    public static func st_generateSecureToken(length: Int = 32) -> String {
        let randomData = STDataUtils.randomData(length: length)
        return randomData.toBase64URLSafeString()
    }
}
