//
//  STSecurityModels.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2018/12/10.
//

import Foundation

// MARK: - 加密算法
public enum STCryptoAlgorithm: String, Codable {
    case aes256GCM = "AES-256-GCM"
    case aes256CBC = "AES-256-CBC"
    case chaCha20Poly1305 = "ChaCha20-Poly1305"
}

// MARK: - 统一加密错误
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
    case invalidSalt
    case invalidIterations

    public var errorDescription: String? {
        switch self {
        case .invalidData:          return "无效的数据"
        case .encryptionFailed:     return "加密失败"
        case .decryptionFailed:     return "解密失败"
        case .invalidSignature:     return "签名验证失败"
        case .invalidKey:           return "无效的密钥"
        case .invalidNonce:         return "无效的随机数"
        case .invalidTag:           return "无效的认证标签"
        case .keyGenerationFailed:  return "密钥生成失败"
        case .unsupportedAlgorithm: return "不支持的加密算法"
        case .invalidSalt:          return "无效的盐值"
        case .invalidIterations:    return "无效的迭代次数"
        }
    }
}

// MARK: - 加密配置
public struct STEncryptionConfig: Codable {
    let enabled: Bool
    let algorithm: STCryptoAlgorithm
    let keyRotationInterval: TimeInterval
    let enableRequestSigning: Bool
    let enableResponseSigning: Bool

    public init(
        enabled: Bool = true,
        algorithm: STCryptoAlgorithm = .aes256GCM,
        keyRotationInterval: TimeInterval = 86400,
        enableRequestSigning: Bool = true,
        enableResponseSigning: Bool = true
    ) {
        self.enabled = enabled
        self.algorithm = algorithm
        self.keyRotationInterval = keyRotationInterval
        self.enableRequestSigning = enableRequestSigning
        self.enableResponseSigning = enableResponseSigning
    }
}

// MARK: - 反调试配置
public struct STAntiDebugConfig: Codable {
    let enabled: Bool
    let checkInterval: TimeInterval
    let enableAntiDebugging: Bool
    let enableAntiHooking: Bool
    let enableAntiTampering: Bool

    public init(
        enabled: Bool = true,
        checkInterval: TimeInterval = 5.0,
        enableAntiDebugging: Bool = true,
        enableAntiHooking: Bool = true,
        enableAntiTampering: Bool = true
    ) {
        self.enabled = enabled
        self.checkInterval = checkInterval
        self.enableAntiDebugging = enableAntiDebugging
        self.enableAntiHooking = enableAntiHooking
        self.enableAntiTampering = enableAntiTampering
    }
}

// MARK: - 安全检测结果
public struct STSecurityCheckResult {
    public let issues: [STSecurityIssue]
    public let isSecure: Bool
    public let timestamp: Date

    public init(issues: [STSecurityIssue], isSecure: Bool) {
        self.issues = issues
        self.isSecure = isSecure
        self.timestamp = Date()
    }
}

// MARK: - 安全问题类型
public enum STSecurityIssue: String, Codable {
    case proxyDetected = "proxy_detected"
    case debuggingDetected = "debugging_detected"
    case jailbreakDetected = "jailbreak_detected"
    case hookingDetected = "hooking_detected"
    case simulatorDetected = "simulator_detected"
    case sslPinningFailed = "ssl_pinning_failed"

    public var description: String {
        switch self {
        case .proxyDetected:     return "检测到代理环境"
        case .debuggingDetected: return "检测到调试环境"
        case .jailbreakDetected: return "检测到越狱环境"
        case .hookingDetected:   return "检测到Hook框架"
        case .simulatorDetected: return "检测到模拟器环境"
        case .sslPinningFailed:  return "SSL证书绑定失败"
        }
    }

    public var severity: STSecuritySeverity {
        switch self {
        case .proxyDetected, .debuggingDetected, .hookingDetected:
            return .high
        case .jailbreakDetected, .sslPinningFailed:
            return .critical
        case .simulatorDetected:
            return .medium
        }
    }
}

// MARK: - 安全严重程度
public enum STSecuritySeverity: String, Codable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
}
