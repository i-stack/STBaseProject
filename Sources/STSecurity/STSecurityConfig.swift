//
//  STSecurityConfig.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2022/1/15.
//

import Darwin
import Security
import Foundation
import SystemConfiguration

public class STSecurityConfig {

    public static let shared = STSecurityConfig()

    // 安全事件回调，透传给内部监控器
    public var onSecurityIssue: ((STSecurityIssue) -> Void)? {
        didSet {
            self.antiDebugMonitor?.onSecurityIssue = self.onSecurityIssue
        }
    }

    private var sslPinningConfig: STSSLPinningConfig
    private var encryptionConfig: STEncryptionConfig
    private var antiDebugConfig: STAntiDebugConfig?
    private var antiDebugMonitor: STAntiDebugMonitor?

    private init() {
        self.sslPinningConfig = STSSLPinningConfig()
        self.encryptionConfig = STEncryptionConfig()
        self.antiDebugConfig = nil
        self.st_loadConfiguration()
    }

    private func st_loadConfiguration() {
        self.st_loadSSLPinningConfig()
        self.st_loadEncryptionConfig()
        self.st_loadAntiDebugConfig()
        self.st_applySecurityConfiguration()
    }

    private func st_loadSSLPinningConfig() {
        do {
            if let configData = try STKeychainHelper.st_loadData(STSecurityStorageKey.sslPinningConfig) {
                self.sslPinningConfig = try JSONDecoder().decode(STSSLPinningConfig.self, from: configData)
            }
        } catch {
            self.sslPinningConfig = STSSLPinningConfig()
        }
    }

    private func st_loadEncryptionConfig() {
        do {
            if let configData = try STKeychainHelper.st_loadData(STSecurityStorageKey.encryptionConfig) {
                self.encryptionConfig = try JSONDecoder().decode(STEncryptionConfig.self, from: configData)
            }
        } catch {
            self.encryptionConfig = STEncryptionConfig()
        }
    }

    private func st_loadAntiDebugConfig() {
        do {
            if let configData = try STKeychainHelper.st_loadData(STSecurityStorageKey.antiDebugConfig) {
                self.antiDebugConfig = try JSONDecoder().decode(STAntiDebugConfig.self, from: configData)
            } else {
                self.antiDebugConfig = nil
            }
        } catch {
            self.antiDebugConfig = nil
        }
    }

    // MARK: - 持久化写入

    public func st_saveSSLPinningConfig(_ config: STSSLPinningConfig) throws {
        let configData = try JSONEncoder().encode(config)
        try STKeychainHelper.st_saveData(STSecurityStorageKey.sslPinningConfig, data: configData)
        self.sslPinningConfig = config
        self.st_applySecurityConfiguration()
    }

    public func st_saveEncryptionConfig(_ config: STEncryptionConfig) throws {
        let configData = try JSONEncoder().encode(config)
        try STKeychainHelper.st_saveData(STSecurityStorageKey.encryptionConfig, data: configData)
        self.encryptionConfig = config
        self.st_applySecurityConfiguration()
    }

    public func st_saveAntiDebugConfig(_ config: STAntiDebugConfig) throws {
        let configData = try JSONEncoder().encode(config)
        try STKeychainHelper.st_saveData(STSecurityStorageKey.antiDebugConfig, data: configData)
        self.antiDebugConfig = config
    }

    public func st_clearAntiDebugConfig() throws {
        try STKeychainHelper.st_delete(STSecurityStorageKey.antiDebugConfig)
        self.antiDebugConfig = nil
        self.st_updateAntiDebugMonitor()
    }

    // MARK: - 运行时应用

    public func st_applySecurityConfiguration(session: STHTTPSession = .shared) {
        session.sslPinningConfig = self.sslPinningConfig
        STCryptoService.shared.st_setDefaultConfig(self.st_resolvedCryptoConfig())
        self.st_updateAntiDebugMonitor()
    }

    private func st_updateAntiDebugMonitor() {
        self.antiDebugMonitor?.st_stopMonitoring()
        guard let antiDebugConfig, antiDebugConfig.enabled else {
            self.antiDebugMonitor = nil
            return
        }
        let monitor = STAntiDebugMonitor(config: antiDebugConfig)
        monitor.onSecurityIssue = self.onSecurityIssue
        self.antiDebugMonitor = monitor
        monitor.st_startMonitoring()
    }

    private func st_resolvedCryptoConfig() -> STCryptoConfig {
        switch self.encryptionConfig.algorithm {
        case .aes256CBC:          return .aes256CBC
        case .chaCha20Poly1305:   return .chaCha20Poly1305
        case .aes256GCM:          return .aes256GCM
        }
    }

    // MARK: - Getter

    public func st_getSSLPinningConfig() -> STSSLPinningConfig {
        return self.sslPinningConfig
    }

    public func st_getEncryptionConfig() -> STEncryptionConfig {
        return self.encryptionConfig
    }

    public func st_getAntiDebugConfig() -> STAntiDebugConfig? {
        return self.antiDebugConfig
    }

    // MARK: - 安全检测

    public func st_performSecurityCheck() -> STSecurityCheckResult {
        var issues: [STSecurityIssue] = []
        let antiDebugConfig = self.antiDebugConfig

        if Self.st_detectProxy() {
            issues.append(.proxyDetected)
        }

        if self.sslPinningConfig.enabled && !Self.st_detectSSLPinning() {
            issues.append(.sslPinningFailed)
        }

        if let cfg = antiDebugConfig, cfg.enabled {
            if cfg.enableAntiDebugging && Self.st_detectDebugging() {
                issues.append(.debuggingDetected)
            }
            if cfg.enableAntiTampering && STDeviceInfo.isDeviceJailbroken {
                issues.append(.jailbreakDetected)
            }
            if cfg.enableAntiHooking && self.st_detectHooking() {
                issues.append(.hookingDetected)
            }
            if cfg.enableAntiTampering && STDeviceInfo.isRunningOnSimulator {
                issues.append(.simulatorDetected)
            }
        }

        return STSecurityCheckResult(issues: issues, isSecure: issues.isEmpty)
    }

    // 检测文件系统中已知 Hook 框架路径，避免 dlopen 把目标框架加载进进程
    private func st_detectHooking() -> Bool {
        return STSecurityConstants.hookFrameworkPaths.contains {
            FileManager.default.fileExists(atPath: $0)
        }
    }
}

// MARK: - 静态安全检测

public extension STSecurityConfig {

    static func st_detectProxy() -> Bool {
        guard let proxySettings = CFNetworkCopySystemProxySettings()?.takeRetainedValue() as? [String: Any] else {
            return false
        }
        let keys = [STSecurityConstants.httpProxyKey, STSecurityConstants.httpsProxyKey, STSecurityConstants.socksProxyKey]
        return keys.contains {
            (proxySettings[$0] as? String).map { !$0.isEmpty } ?? false
        }
    }

    // 纯运行时调试器检测，不依赖编译期 DEBUG flag
    static func st_detectDebugging() -> Bool {
        var info = kinfo_proc()
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
        var size = MemoryLayout<kinfo_proc>.stride
        let result = sysctl(&mib, u_int(mib.count), &info, &size, nil, 0)
        guard result == 0 else { return false }
        return (info.kp_proc.p_flag & P_TRACED) != 0
    }

    static func st_detectSSLPinning(session: STHTTPSession = .shared) -> Bool {
        let config = session.sslPinningConfig
        guard config.enabled, !config.allowInvalidCertificates else { return false }
        return !config.certificates.isEmpty || !config.publicKeyHashes.isEmpty
    }

    static func st_detectAppIntegrity() -> Bool {
        guard let bundlePath = Bundle.main.bundlePath.cString(using: .utf8) else {
            return false
        }
        let bundleURL = CFURLCreateFromFileSystemRepresentation(nil, bundlePath, strlen(bundlePath), true)
        guard let bundleURL, let bundle = CFBundleCreate(nil, bundleURL) else {
            return false
        }
        guard let infoDict = CFBundleGetInfoDictionary(bundle) else { return false }
        let dictionary = infoDict as NSDictionary
        return dictionary["CFBundleSignature"] != nil || dictionary["CFBundleIdentifier"] != nil
    }
}

private enum STSecurityStorageKey {
    static let sslPinningConfig = "ssl_pinning_config"
    static let encryptionConfig = "encryption_config"
    static let antiDebugConfig  = "anti_debug_config"
}

private enum STSecurityConstants {
    static let httpProxyKey  = "HTTPProxy"
    static let httpsProxyKey = "HTTPSProxy"
    static let socksProxyKey = "SOCKSProxy"
    // 通过文件路径检测已知 Hook 框架，不使用 dlopen 以避免加载副作用
    static let hookFrameworkPaths = [
        "/Library/MobileSubstrate/MobileSubstrate.dylib",
        "/usr/lib/substrate/SubstrateBootstrap.dylib",
        "/usr/lib/substrate/SubstrateLoader.dylib",
        "/usr/lib/frida/frida-agent.dylib",
        "/usr/lib/libcycript.dylib",
    ]
}
