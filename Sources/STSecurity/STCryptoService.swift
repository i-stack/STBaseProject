//
//  STCryptoService.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2018/12/10.
//

import CryptoKit
import Foundation
import CommonCrypto

// MARK: - 加密配置

public struct STCryptoConfig {
    public let algorithm: STCryptoAlgorithm
    public let keyLength: Int
    public let nonceLength: Int
    public let tagLength: Int

    public static let aes256GCM = STCryptoConfig(
        algorithm: .aes256GCM,
        keyLength: 32,
        nonceLength: 12,
        tagLength: 16
    )

    public static let aes256CBC = STCryptoConfig(
        algorithm: .aes256CBC,
        keyLength: 32,
        nonceLength: 16,
        tagLength: 0
    )

    public static let chaCha20Poly1305 = STCryptoConfig(
        algorithm: .chaCha20Poly1305,
        keyLength: 32,
        nonceLength: 12,
        tagLength: 16
    )
}

// MARK: - 加密服务

public class STCryptoService {

    public static let shared = STCryptoService()

    private var defaultConfig: STCryptoConfig = .aes256GCM

    private init() {}

    // MARK: - 配置

    public func st_setDefaultConfig(_ config: STCryptoConfig) {
        self.defaultConfig = config
    }

    public func st_getDefaultConfig() -> STCryptoConfig {
        return self.defaultConfig
    }

    // MARK: - 密钥管理

    public static func st_generateRandomKey(length: Int = 32) -> Data {
        return STDataUtils.randomData(length: length)
    }

    public static func st_generateKey(from keyString: String, config: STCryptoConfig = .aes256GCM) -> SymmetricKey {
        return SymmetricKey(data: st_deriveKeyData(from: keyString, config: config))
    }

    /// 兼容旧 API：当前无内存密钥缓存，保留空实现避免破坏调用端。
    public func st_clearKeyCache() {}

    // MARK: - 数据加密

    public static func st_encryptData(_ data: Data, keyString: String, config: STCryptoConfig = .aes256GCM) throws -> Data {
        guard !data.isEmpty else { throw STCryptoError.invalidData }
        guard !keyString.isEmpty else { throw STCryptoError.invalidKey }

        switch config.algorithm {
        case .aes256GCM:
            return try st_encryptAES256GCM(data, keyString: keyString, config: config)
        case .aes256CBC:
            return try st_encryptAES256CBC(data, keyString: keyString, config: config)
        case .chaCha20Poly1305:
            return try st_encryptChaCha20Poly1305(data, keyString: keyString, config: config)
        }
    }

    private static func st_encryptAES256GCM(_ data: Data, keyString: String, config: STCryptoConfig) throws -> Data {
        let symmetricKey = SymmetricKey(data: st_deriveKeyData(from: keyString, config: config))
        let nonce = AES.GCM.Nonce()
        let sealedBox = try AES.GCM.seal(data, using: symmetricKey, nonce: nonce)
        var result = Data()
        result.append(contentsOf: nonce)
        result.append(sealedBox.ciphertext)
        result.append(sealedBox.tag)
        return result
    }

    private static func st_encryptAES256CBC(_ data: Data, keyString: String, config: STCryptoConfig) throws -> Data {
        let key = st_deriveKeyData(from: keyString, config: config)
        let iv = STDataUtils.randomData(length: config.nonceLength)
        let encryptedData = try st_cipherCBC(operation: kCCEncrypt, data: data, key: key, iv: iv)
        var result = Data()
        result.append(iv)
        result.append(encryptedData)
        return result
    }

    private static func st_encryptChaCha20Poly1305(_ data: Data, keyString: String, config: STCryptoConfig) throws -> Data {
        let symmetricKey = SymmetricKey(data: st_deriveKeyData(from: keyString, config: config))
        let nonce = ChaChaPoly.Nonce()
        let sealedBox = try ChaChaPoly.seal(data, using: symmetricKey, nonce: nonce)
        var result = Data()
        result.append(contentsOf: nonce)
        result.append(sealedBox.ciphertext)
        result.append(sealedBox.tag)
        return result
    }

    // MARK: - 数据解密

    public static func st_decryptData(_ encryptedData: Data, keyString: String, config: STCryptoConfig = .aes256GCM) throws -> Data {
        guard !encryptedData.isEmpty else { throw STCryptoError.invalidData }
        guard !keyString.isEmpty else { throw STCryptoError.invalidKey }

        switch config.algorithm {
        case .aes256GCM:
            return try st_decryptAES256GCM(encryptedData, keyString: keyString, config: config)
        case .aes256CBC:
            return try st_decryptAES256CBC(encryptedData, keyString: keyString, config: config)
        case .chaCha20Poly1305:
            return try st_decryptChaCha20Poly1305(encryptedData, keyString: keyString, config: config)
        }
    }

    private static func st_decryptAES256GCM(_ encryptedData: Data, keyString: String, config: STCryptoConfig) throws -> Data {
        guard encryptedData.count > config.nonceLength + config.tagLength else {
            throw STCryptoError.invalidData
        }
        let nonceData = encryptedData.prefix(config.nonceLength)
        let ciphertext = encryptedData.dropFirst(config.nonceLength).dropLast(config.tagLength)
        let tag = encryptedData.suffix(config.tagLength)
        let symmetricKey = SymmetricKey(data: st_deriveKeyData(from: keyString, config: config))
        let nonce = try AES.GCM.Nonce(data: nonceData)
        let sealedBox = try AES.GCM.SealedBox(nonce: nonce, ciphertext: Data(ciphertext), tag: Data(tag))
        return try AES.GCM.open(sealedBox, using: symmetricKey)
    }

    private static func st_decryptAES256CBC(_ encryptedData: Data, keyString: String, config: STCryptoConfig) throws -> Data {
        guard encryptedData.count > config.nonceLength else {
            throw STCryptoError.invalidData
        }
        let iv = encryptedData.prefix(config.nonceLength)
        let ciphertext = encryptedData.dropFirst(config.nonceLength)
        let key = st_deriveKeyData(from: keyString, config: config)
        return try st_cipherCBC(operation: kCCDecrypt, data: Data(ciphertext), key: key, iv: Data(iv))
    }

    private static func st_decryptChaCha20Poly1305(_ encryptedData: Data, keyString: String, config: STCryptoConfig) throws -> Data {
        guard encryptedData.count > config.nonceLength + config.tagLength else {
            throw STCryptoError.invalidData
        }
        let nonceData = encryptedData.prefix(config.nonceLength)
        let ciphertext = encryptedData.dropFirst(config.nonceLength).dropLast(config.tagLength)
        let tag = encryptedData.suffix(config.tagLength)
        let symmetricKey = SymmetricKey(data: st_deriveKeyData(from: keyString, config: config))
        let nonce = try ChaChaPoly.Nonce(data: nonceData)
        let sealedBox = try ChaChaPoly.SealedBox(nonce: nonce, ciphertext: Data(ciphertext), tag: Data(tag))
        return try ChaChaPoly.open(sealedBox, using: symmetricKey)
    }

    // AES-CBC / AES-256-CBC 共用底层 CCCrypt 调用
    private static func st_cipherCBC(operation: CCOperation, data: Data, key: Data, iv: Data) throws -> Data {
        let bufferSize = data.count + kCCBlockSizeAES128
        var buffer = Data(count: bufferSize)
        var numBytesProcessed: size_t = 0

        let status = buffer.withUnsafeMutableBytes { bufferBytes in
            data.withUnsafeBytes { dataBytes in
                key.withUnsafeBytes { keyBytes in
                    iv.withUnsafeBytes { ivBytes in
                        CCCrypt(
                            operation,
                            CCAlgorithm(kCCAlgorithmAES128),
                            CCOptions(kCCOptionPKCS7Padding),
                            keyBytes.bindMemory(to: UInt8.self).baseAddress, key.count,
                            ivBytes.bindMemory(to: UInt8.self).baseAddress,
                            dataBytes.bindMemory(to: UInt8.self).baseAddress, data.count,
                            bufferBytes.bindMemory(to: UInt8.self).baseAddress, bufferSize,
                            &numBytesProcessed
                        )
                    }
                }
            }
        }

        guard status == kCCSuccess else {
            throw operation == kCCEncrypt ? STCryptoError.encryptionFailed : STCryptoError.decryptionFailed
        }
        return buffer.prefix(numBytesProcessed)
    }

    // SHA256 原始字节派生密钥，确保完整 256-bit 熵
    private static func st_deriveKeyData(from keyString: String, config: STCryptoConfig) -> Data {
        let digest = SHA256.hash(data: Data(keyString.utf8))
        return Data(digest.prefix(config.keyLength))
    }

    // MARK: - 签名和验证

    public static func st_signData(_ data: Data, secret: String, timestamp: TimeInterval) -> String {
        let signString = "\(data.base64EncodedString())\(Int(timestamp))\(secret)"
        return signString.st_hmacSha256(key: secret)
    }

    public static func st_verifySignature(_ data: Data, signature: String, secret: String, timestamp: TimeInterval) -> Bool {
        let expectedSignature = st_signData(data, secret: secret, timestamp: timestamp)
        return STEncryptionUtils.st_secureCompare(signature, expectedSignature)
    }

    // MARK: - 便捷方法

    public static func st_encryptString(_ string: String, keyString: String, config: STCryptoConfig = .aes256GCM) throws -> Data {
        guard let data = string.data(using: .utf8) else { throw STCryptoError.invalidData }
        return try st_encryptData(data, keyString: keyString, config: config)
    }

    public static func st_decryptToString(_ encryptedData: Data, keyString: String, config: STCryptoConfig = .aes256GCM) throws -> String {
        let decryptedData = try st_decryptData(encryptedData, keyString: keyString, config: config)
        guard let string = String(data: decryptedData, encoding: .utf8) else {
            throw STCryptoError.decryptionFailed
        }
        return string
    }

    public static func st_encryptDictionary(_ dictionary: [String: Any], keyString: String, config: STCryptoConfig = .aes256GCM) throws -> Data {
        let jsonData = try JSONSerialization.data(withJSONObject: dictionary)
        return try st_encryptData(jsonData, keyString: keyString, config: config)
    }

    public static func st_decryptToDictionary(_ encryptedData: Data, keyString: String, config: STCryptoConfig = .aes256GCM) throws -> [String: Any] {
        let decryptedData = try st_decryptData(encryptedData, keyString: keyString, config: config)
        guard let dictionary = try JSONSerialization.jsonObject(with: decryptedData) as? [String: Any] else {
            throw STCryptoError.decryptionFailed
        }
        return dictionary
    }
}

// MARK: - 批量操作

public extension STCryptoService {

    static func st_encryptBatch(_ dataArray: [Data], keyString: String, config: STCryptoConfig = .aes256GCM) throws -> [Data] {
        return try dataArray.map { try st_encryptData($0, keyString: keyString, config: config) }
    }

    static func st_decryptBatch(_ encryptedArray: [Data], keyString: String, config: STCryptoConfig = .aes256GCM) throws -> [Data] {
        return try encryptedArray.map { try st_decryptData($0, keyString: keyString, config: config) }
    }

    static func st_verifyDataIntegrity(_ data: Data, encryptedData: Data, keyString: String, config: STCryptoConfig = .aes256GCM) -> Bool {
        guard let decryptedData = try? st_decryptData(encryptedData, keyString: keyString, config: config) else {
            return false
        }
        return data == decryptedData
    }
}

// MARK: - 异步操作

public extension STCryptoService {

    static func st_encryptDataAsync(
        _ data: Data,
        keyString: String,
        config: STCryptoConfig = .aes256GCM,
        completion: @escaping (Result<Data, STCryptoError>) -> Void
    ) {
        DispatchQueue.global(qos: .userInitiated).async {
            let result = Result { try st_encryptData(data, keyString: keyString, config: config) }
                .mapError { $0 as? STCryptoError ?? .encryptionFailed }
            DispatchQueue.main.async { completion(result) }
        }
    }

    static func st_decryptDataAsync(
        _ encryptedData: Data,
        keyString: String,
        config: STCryptoConfig = .aes256GCM,
        completion: @escaping (Result<Data, STCryptoError>) -> Void
    ) {
        DispatchQueue.global(qos: .userInitiated).async {
            let result = Result { try st_decryptData(encryptedData, keyString: keyString, config: config) }
                .mapError { $0 as? STCryptoError ?? .decryptionFailed }
            DispatchQueue.main.async { completion(result) }
        }
    }
}
