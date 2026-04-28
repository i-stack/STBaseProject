//
//  STSSLPinningConfig.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2018/12/10.
//

import Foundation
import Security
import CryptoKit

public enum STSSLPinningConfigError: Error, LocalizedError {
    case invalidCertificateData
    case publicKeyExtractionFailed

    public var errorDescription: String? {
        switch self {
        case .invalidCertificateData:
            return "无效的证书数据"
        case .publicKeyExtractionFailed:
            return "提取证书公钥失败"
        }
    }
}

// MARK: - SSL证书绑定配置
public struct STSSLPinningConfig: Codable {
    public let enabled: Bool
    public let certificates: [Data]
    public let publicKeyHashes: [String]
    public let validateHost: Bool
    public let allowInvalidCertificates: Bool
    
    public init(enabled: Bool = true,
                certificates: [Data] = [],
                publicKeyHashes: [String] = [],
                validateHost: Bool = true,
                allowInvalidCertificates: Bool = false) {
        self.enabled = enabled
        self.certificates = certificates
        self.publicKeyHashes = publicKeyHashes
        self.validateHost = validateHost
        self.allowInvalidCertificates = allowInvalidCertificates
    }
    
    // MARK: - Codable 实现
    private enum CodingKeys: String, CodingKey {
        case enabled
        case certificates
        case publicKeyHashes
        case validateHost
        case allowInvalidCertificates
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        enabled = try container.decode(Bool.self, forKey: .enabled)
        validateHost = try container.decode(Bool.self, forKey: .validateHost)
        allowInvalidCertificates = try container.decode(Bool.self, forKey: .allowInvalidCertificates)
        publicKeyHashes = try container.decode([String].self, forKey: .publicKeyHashes)
        
        // 解码 Base64 编码的证书数据
        let certificateStrings = try container.decode([String].self, forKey: .certificates)
        certificates = certificateStrings.compactMap { Data(base64Encoded: $0) }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(enabled, forKey: .enabled)
        try container.encode(validateHost, forKey: .validateHost)
        try container.encode(allowInvalidCertificates, forKey: .allowInvalidCertificates)
        try container.encode(publicKeyHashes, forKey: .publicKeyHashes)
        
        // 将证书数据编码为 Base64 字符串
        let certificateStrings = certificates.map { $0.base64EncodedString() }
        try container.encode(certificateStrings, forKey: .certificates)
    }

    /// 从证书数据生成公钥 SHA-256 哈希（Base64）
    public static func st_publicKeyHash(from certificateData: Data) throws -> String {
        guard let certificate = SecCertificateCreateWithData(nil, certificateData as CFData) else {
            throw STSSLPinningConfigError.invalidCertificateData
        }

        guard let key = SecCertificateCopyKey(certificate) else {
            throw STSSLPinningConfigError.publicKeyExtractionFailed
        }

        var error: Unmanaged<CFError>?
        guard let publicKeyData = SecKeyCopyExternalRepresentation(key, &error) as Data? else {
            throw STSSLPinningConfigError.publicKeyExtractionFailed
        }

        let digest = SHA256.hash(data: publicKeyData)
        return Data(digest).base64EncodedString()
    }

    /// 批量从证书数据生成公钥 SHA-256 哈希（Base64）
    public static func st_publicKeyHashes(from certificates: [Data]) throws -> [String] {
        return try certificates.map { try self.st_publicKeyHash(from: $0) }
    }
}
