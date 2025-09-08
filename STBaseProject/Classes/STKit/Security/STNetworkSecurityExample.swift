//
//  STNetworkSecurityExample.swift
//  STBaseProject
//
//  Created by AI Assistant on 2024/12/19.
//

import Foundation

// MARK: - 网络安全使用示例
public class STNetworkSecurityExample {
    
    // MARK: - 基础安全配置示例
    
    /// 配置SSL证书绑定
    public static func st_setupSSLPinning() {
        // 从Bundle中加载证书
        guard let certificatePath = Bundle.main.path(forResource: "server_cert", ofType: "cer"),
              let certificateData = NSData(contentsOfFile: certificatePath) else {
            print("❌ 无法加载SSL证书")
            return
        }
        
        // 计算公钥哈希
        let publicKeyHash = certificateData.base64EncodedString().st_sha256()
        
        // 配置SSL绑定
        let sslConfig = STSSLPinningConfig(
            enabled: true,
            certificates: [certificateData as Data],
            publicKeyHashes: [publicKeyHash],
            validateHost: true,
            allowInvalidCertificates: false
        )
        
        // 保存配置
        do {
            try STNetworkSecurityConfig.shared.st_saveSSLPinningConfig(sslConfig)
            print("✅ SSL证书绑定配置成功")
        } catch {
            print("❌ SSL证书绑定配置失败: \(error)")
        }
    }
    
    /// 配置数据加密
    public static func st_setupEncryption() {
        let encryptionConfig = STEncryptionConfig(
            enabled: true,
            algorithm: "AES-256-GCM",
            keyRotationInterval: 86400, // 24小时
            enableRequestSigning: true,
            enableResponseSigning: true
        )
        
        do {
            try STNetworkSecurityConfig.shared.st_saveEncryptionConfig(encryptionConfig)
            print("✅ 数据加密配置成功")
        } catch {
            print("❌ 数据加密配置失败: \(error)")
        }
    }
    
    /// 配置反调试
    public static func st_setupAntiDebug() {
        let antiDebugConfig = STAntiDebugConfig(
            enabled: true,
            checkInterval: 5.0,
            enableAntiDebugging: true,
            enableAntiHooking: true,
            enableAntiTampering: true
        )
        
        do {
            try STNetworkSecurityConfig.shared.st_saveAntiDebugConfig(antiDebugConfig)
            print("✅ 反调试配置成功")
        } catch {
            print("❌ 反调试配置失败: \(error)")
        }
    }
    
    // MARK: - 安全网络请求示例
    
    /// 发送加密的POST请求
    public static func st_sendSecurePostRequest() {
        let url = "https://api.example.com/secure-endpoint"
        let parameters = [
            "username": "user123",
            "password": "securePassword",
            "data": "sensitive information"
        ]
        
        // 配置安全请求
        let requestConfig = STRequestConfig(
            timeoutInterval: 30,
            enableEncryption: true,
            encryptionKey: "your-encryption-key-here",
            enableRequestSigning: true,
            signingSecret: "your-signing-secret-here"
        )
        
        // 发送请求
        STHTTPSession.shared.st_post(
            url: url,
            parameters: parameters,
            encodingType: .json,
            requestConfig: requestConfig
        ) { response in
            if response.isSuccess {
                print("✅ 安全请求成功")
                if let data = response.businessData {
                    print("📦 响应数据: \(data)")
                }
            } else {
                print("❌ 安全请求失败: \(response.error?.localizedDescription ?? "未知错误")")
            }
        }
    }
    
    /// 发送带SSL绑定的GET请求
    public static func st_sendSecureGetRequest() {
        let url = "https://api.example.com/secure-data"
        let parameters = [
            "token": "user-token",
            "timestamp": String(Int(Date().timeIntervalSince1970))
        ]
        
        // 配置请求头
        let requestHeaders = STRequestHeaders()
        requestHeaders.st_setAuthorization("Bearer your-jwt-token")
        requestHeaders.st_setHeader("X-Client-Version", forKey: "1.0.0")
        requestHeaders.st_setHeader("X-Device-ID", forKey: UIDevice.current.identifierForVendor?.uuidString ?? "")
        
        // 发送请求
        STHTTPSession.shared.st_get(
            url: url,
            parameters: parameters,
            requestHeaders: requestHeaders
        ) { response in
            if response.isSuccess {
                print("✅ 安全GET请求成功")
            } else {
                print("❌ 安全GET请求失败: \(response.error?.localizedDescription ?? "未知错误")")
            }
        }
    }
    
    // MARK: - 安全检测示例
    
    /// 执行完整的安全检测
    public static func st_performSecurityCheck() {
        let result = STNetworkSecurityConfig.shared.st_performSecurityCheck()
        
        if result.isSecure {
            print("✅ 安全检测通过，环境安全")
        } else {
            print("⚠️ 检测到安全问题:")
            for issue in result.issues {
                print("  - \(issue.description) (严重程度: \(issue.severity.rawValue))")
            }
        }
    }
    
    /// 启动反调试监控
    public static func st_startAntiDebugMonitoring() {
        let monitor = STAntiDebugMonitor()
        monitor.st_startMonitoring()
        print("✅ 反调试监控已启动")
    }
    
    // MARK: - 高级安全功能示例
    
    /// 使用生物识别保护敏感数据
    public static func st_protectSensitiveDataWithBiometric() {
        let sensitiveData = "这是敏感数据".data(using: .utf8)!
        
        do {
            try STKeychainHelper.st_saveWithBiometric(
                "sensitive_data",
                data: sensitiveData,
                reason: "使用生物识别保护您的敏感数据"
            )
            print("✅ 敏感数据已使用生物识别保护")
        } catch {
            print("❌ 生物识别保护失败: \(error)")
        }
    }
    
    /// 生成安全的API密钥
    public static func st_generateSecureAPIKey() -> String {
        let apiKey = STEncryptionUtils.st_generateSecureToken(length: 32)
        print("🔑 生成的安全API密钥: \(apiKey)")
        return apiKey
    }
    
    /// 验证数据完整性
    public static func st_verifyDataIntegrity(data: Data, expectedHash: String) -> Bool {
        let actualHash = data.base64EncodedString().st_sha256()
        let isValid = STEncryptionUtils.st_secureCompare(actualHash, expectedHash)
        
        if isValid {
            print("✅ 数据完整性验证通过")
        } else {
            print("❌ 数据完整性验证失败")
        }
        
        return isValid
    }
    
    // MARK: - 完整的安全初始化示例
    
    /// 完整的安全初始化
    public static func st_initializeSecurity() {
        print("🔒 开始初始化网络安全...")
        
        // 1. 配置SSL证书绑定
        st_setupSSLPinning()
        
        // 2. 配置数据加密
        st_setupEncryption()
        
        // 3. 配置反调试
        st_setupAntiDebug()
        
        // 4. 执行安全检测
        st_performSecurityCheck()
        
        // 5. 启动反调试监控
        st_startAntiDebugMonitoring()
        
        print("✅ 网络安全初始化完成")
    }
}

// MARK: - 网络安全最佳实践
public extension STNetworkSecurityExample {
    
    /// 网络安全最佳实践指南
    static func st_securityBestPractices() {
        print("""
        🔒 iOS网络安全最佳实践:
        
        1. SSL证书绑定 (SSL Pinning)
           - 使用公钥绑定而非证书绑定，更灵活
           - 定期更新证书和公钥
           - 在开发环境禁用，生产环境启用
        
        2. 数据加密
           - 使用AES-256-GCM等强加密算法
           - 定期轮换加密密钥
           - 对敏感数据进行端到端加密
        
        3. 请求签名
           - 使用HMAC-SHA256进行请求签名
           - 包含时间戳防止重放攻击
           - 验证响应签名确保数据完整性
        
        4. 反调试保护
           - 检测调试器附加
           - 检测Hook框架
           - 检测越狱环境
        
        5. 环境检测
           - 检测代理设置
           - 检测模拟器环境
           - 检测Hook工具
        
        6. 密钥管理
           - 使用Keychain存储敏感密钥
           - 使用生物识别保护关键数据
           - 实现密钥轮换机制
        
        7. 错误处理
           - 不暴露敏感错误信息
           - 记录安全事件日志
           - 实现安全降级策略
        """)
    }
}
