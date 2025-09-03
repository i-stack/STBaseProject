//
//  STNetworkSecurityConfig.swift
//  STBaseProject
//
//  Created by AI Assistant on 2024/12/19.
//

import Foundation
import Security

// MARK: - 网络安全配置
public class STNetworkSecurityConfig {
    
    // MARK: - 单例
    public static let shared = STNetworkSecurityConfig()
    
    // MARK: - 属性
    private var sslPinningConfig: STSSLPinningConfig
    private var encryptionConfig: STEncryptionConfig
    private var antiDebugConfig: STAntiDebugConfig
    
    // MARK: - 初始化
    private init() {
        self.sslPinningConfig = STSSLPinningConfig()
        self.encryptionConfig = STEncryptionConfig()
        self.antiDebugConfig = STAntiDebugConfig()
        st_loadConfiguration()
    }
    
    // MARK: - 配置管理
    
    /// 加载安全配置
    private func st_loadConfiguration() {
        // 从Keychain或配置文件加载安全配置
        st_loadSSLPinningConfig()
        st_loadEncryptionConfig()
        st_loadAntiDebugConfig()
    }
    
    /// 加载SSL绑定配置
    private func st_loadSSLPinningConfig() {
        do {
            if let configData = try STKeychainHelper.st_loadData("ssl_pinning_config") {
                let decoder = JSONDecoder()
                sslPinningConfig = try decoder.decode(STSSLPinningConfig.self, from: configData)
            }
        } catch {
            // 使用默认配置
            sslPinningConfig = STSSLPinningConfig()
        }
    }
    
    /// 加载加密配置
    private func st_loadEncryptionConfig() {
        do {
            if let configData = try STKeychainHelper.st_loadData("encryption_config") {
                let decoder = JSONDecoder()
                encryptionConfig = try decoder.decode(STEncryptionConfig.self, from: configData)
            }
        } catch {
            // 使用默认配置
            encryptionConfig = STEncryptionConfig()
        }
    }
    
    /// 加载反调试配置
    private func st_loadAntiDebugConfig() {
        do {
            if let configData = try STKeychainHelper.st_loadData("anti_debug_config") {
                let decoder = JSONDecoder()
                antiDebugConfig = try decoder.decode(STAntiDebugConfig.self, from: configData)
            }
        } catch {
            // 使用默认配置
            antiDebugConfig = STAntiDebugConfig()
        }
    }
    
    /// 保存SSL绑定配置
    public func st_saveSSLPinningConfig(_ config: STSSLPinningConfig) throws {
        let encoder = JSONEncoder()
        let configData = try encoder.encode(config)
        try STKeychainHelper.st_saveData("ssl_pinning_config", data: configData)
        self.sslPinningConfig = config
    }
    
    /// 保存加密配置
    public func st_saveEncryptionConfig(_ config: STEncryptionConfig) throws {
        let encoder = JSONEncoder()
        let configData = try encoder.encode(config)
        try STKeychainHelper.st_saveData("encryption_config", data: configData)
        self.encryptionConfig = config
    }
    
    /// 保存反调试配置
    public func st_saveAntiDebugConfig(_ config: STAntiDebugConfig) throws {
        let encoder = JSONEncoder()
        let configData = try encoder.encode(config)
        try STKeychainHelper.st_saveData("anti_debug_config", data: configData)
        self.antiDebugConfig = config
    }
    
    // MARK: - 获取配置
    
    /// 获取SSL绑定配置
    public func st_getSSLPinningConfig() -> STSSLPinningConfig {
        return sslPinningConfig
    }
    
    /// 获取加密配置
    public func st_getEncryptionConfig() -> STEncryptionConfig {
        return encryptionConfig
    }
    
    /// 获取反调试配置
    public func st_getAntiDebugConfig() -> STAntiDebugConfig {
        return antiDebugConfig
    }
    
    // MARK: - 安全检测
    
    /// 执行完整的安全检测
    public func st_performSecurityCheck() -> STSecurityCheckResult {
        var issues: [STSecurityIssue] = []
        
        // 检测代理
        if STNetworkSecurityDetector.st_detectProxy() {
            issues.append(.proxyDetected)
        }
        
        // 检测调试
        if STNetworkSecurityDetector.st_detectDebugging() {
            issues.append(.debuggingDetected)
        }
        
        // 检测越狱
        if STNetworkSecurityDetector.st_detectJailbreak() {
            issues.append(.jailbreakDetected)
        }
        
        // 检测Hook
        if st_detectHooking() {
            issues.append(.hookingDetected)
        }
        
        // 检测模拟器
        if STDeviceInfo.st_isRunningOnSimulator() {
            issues.append(.simulatorDetected)
        }
        
        return STSecurityCheckResult(issues: issues, isSecure: issues.isEmpty)
    }
    
    /// 检测Hook
    private func st_detectHooking() -> Bool {
        // 检测常见的Hook框架
        let hookFrameworks = [
            "Substrate",
            "CydiaSubstrate",
            "libsubstrate.dylib",
            "MobileSubstrate",
            "FridaGadget",
            "frida-agent"
        ]
        
        for framework in hookFrameworks {
            if dlopen(framework, RTLD_NOW) != nil {
                return true
            }
        }
        
        return false
    }
}

// MARK: - 加密配置
public struct STEncryptionConfig: Codable {
    let enabled: Bool
    let algorithm: String
    let keyRotationInterval: TimeInterval
    let enableRequestSigning: Bool
    let enableResponseSigning: Bool
    
    public init(enabled: Bool = true,
                algorithm: String = "AES-256-GCM",
                keyRotationInterval: TimeInterval = 86400, // 24小时
                enableRequestSigning: Bool = true,
                enableResponseSigning: Bool = true) {
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
    
    public init(enabled: Bool = true,
                checkInterval: TimeInterval = 5.0,
                enableAntiDebugging: Bool = true,
                enableAntiHooking: Bool = true,
                enableAntiTampering: Bool = true) {
        self.enabled = enabled
        self.checkInterval = checkInterval
        self.enableAntiDebugging = enableAntiDebugging
        self.enableAntiHooking = enableAntiHooking
        self.enableAntiTampering = enableAntiTampering
    }
}

// MARK: - 安全检测结果
public struct STSecurityCheckResult {
    let issues: [STSecurityIssue]
    let isSecure: Bool
    let timestamp: Date
    
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
    case encryptionFailed = "encryption_failed"
    case signatureVerificationFailed = "signature_verification_failed"
    
    public var description: String {
        switch self {
        case .proxyDetected:
            return "检测到代理环境"
        case .debuggingDetected:
            return "检测到调试环境"
        case .jailbreakDetected:
            return "检测到越狱环境"
        case .hookingDetected:
            return "检测到Hook框架"
        case .simulatorDetected:
            return "检测到模拟器环境"
        case .sslPinningFailed:
            return "SSL证书绑定失败"
        case .encryptionFailed:
            return "数据加密失败"
        case .signatureVerificationFailed:
            return "签名验证失败"
        }
    }
    
    public var severity: STSecuritySeverity {
        switch self {
        case .proxyDetected, .debuggingDetected, .hookingDetected:
            return .high
        case .jailbreakDetected, .sslPinningFailed, .encryptionFailed, .signatureVerificationFailed:
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

// MARK: - 反调试监控器
public class STAntiDebugMonitor {
    
    private var timer: Timer?
    private var isMonitoring = false
    
    public init() {}
    
    /// 开始监控
    public func st_startMonitoring() {
        guard !isMonitoring else { return }
        
        let config = STNetworkSecurityConfig.shared.st_getAntiDebugConfig()
        guard config.enabled else { return }
        
        isMonitoring = true
        timer = Timer.scheduledTimer(withTimeInterval: config.checkInterval, repeats: true) { [weak self] _ in
            self?.st_performSecurityCheck()
        }
    }
    
    /// 停止监控
    public func st_stopMonitoring() {
        timer?.invalidate()
        timer = nil
        isMonitoring = false
    }
    
    /// 执行安全检测
    private func st_performSecurityCheck() {
        let result = STNetworkSecurityConfig.shared.st_performSecurityCheck()
        
        if !result.isSecure {
            st_handleSecurityIssues(result.issues)
        }
    }
    
    /// 处理安全问题
    private func st_handleSecurityIssues(_ issues: [STSecurityIssue]) {
        for issue in issues {
            switch issue.severity {
            case .critical:
                st_handleCriticalIssue(issue)
            case .high:
                st_handleHighIssue(issue)
            case .medium:
                st_handleMediumIssue(issue)
            case .low:
                st_handleLowIssue(issue)
            }
        }
    }
    
    private func st_handleCriticalIssue(_ issue: STSecurityIssue) {
        print("🚨 严重安全问题: \(issue.description)")
        // 可以在这里实现更严格的安全措施，如退出应用
    }
    
    private func st_handleHighIssue(_ issue: STSecurityIssue) {
        print("⚠️ 高危险安全问题: \(issue.description)")
        // 可以在这里实现安全警告或限制功能
    }
    
    private func st_handleMediumIssue(_ issue: STSecurityIssue) {
        print("⚠️ 中等安全问题: \(issue.description)")
        // 可以在这里记录日志或发送警告
    }
    
    private func st_handleLowIssue(_ issue: STSecurityIssue) {
        print("ℹ️ 低风险安全问题: \(issue.description)")
        // 可以在这里记录日志
    }
    
    deinit {
        st_stopMonitoring()
    }
}
