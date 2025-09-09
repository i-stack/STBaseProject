//
//  STNetworkSecurityDetector.swift
//  STBaseProject
//
//  Created by AI Assistant on 2024/12/19.
//

import Foundation
import Security
import SystemConfiguration
import Darwin

// MARK: - 网络安全检测
public class STNetworkSecurityDetector {
    
    /// 检测是否使用了代理
    public static func st_detectProxy() -> Bool {
        guard let proxySettings = CFNetworkCopySystemProxySettings()?.takeRetainedValue() as? [String: Any] else {
            return false
        }
        
        // 检查HTTP代理
        if let httpProxy = proxySettings["HTTPProxy"] as? String, !httpProxy.isEmpty {
            return true
        }
        
        // 检查HTTPS代理
        if let httpsProxy = proxySettings["HTTPSProxy"] as? String, !httpsProxy.isEmpty {
            return true
        }
        
        // 检查SOCKS代理
        if let socksProxy = proxySettings["SOCKSProxy"] as? String, !socksProxy.isEmpty {
            return true
        }
        
        return false
    }
    
    /// 检测是否在调试环境
    public static func st_detectDebugging() -> Bool {
        #if DEBUG
        return true
        #else
        // 检测调试器附加
        var info = kinfo_proc()
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
        var size = MemoryLayout<kinfo_proc>.stride
        
        let result = sysctl(&mib, u_int(mib.count), &info, &size, nil, 0)
        if result != 0 {
            return false
        }
        
        return (info.kp_proc.p_flag & P_TRACED) != 0
        #endif
    }
    
    /// 检测是否越狱环境
    public static func st_detectJailbreak() -> Bool {
        let jailbreakPaths = [
            "/Applications/Cydia.app",
            "/Applications/RockApp.app",
            "/Applications/Icy.app",
            "/usr/sbin/frida-server",
            "/etc/apt",
            "/private/var/lib/apt/",
            "/private/var/Users/",
            "/var/log/syslog",
            "/bin/bash",
            "/usr/sbin/sshd",
            "/etc/ssh/sshd_config",
            "/System/Library/LaunchDaemons/ssh.plist",
            "/usr/libexec/sftp-server",
            "/usr/bin/sshd",
            "/usr/sbin/sshd",
            "/var/log/apt",
            "/Applications/MxTube.app",
            "/Applications/RockApp.app",
            "/Applications/WinterBoard.app",
            "/Applications/SBSettings.app",
            "/Applications/MxTube.app",
            "/Applications/IntelliScreen.app",
            "/Applications/FakeCarrier.app",
            "/Applications/blackra1n.app",
            "/Applications/FakeCarrier.app",
            "/Applications/IntelliScreen.app",
            "/Applications/SBSettings.app",
            "/Applications/MxTube.app",
            "/Applications/WinterBoard.app",
            "/Applications/RockApp.app",
            "/Applications/MxTube.app",
            "/Applications/RockApp.app",
            "/Applications/Icy.app",
            "/usr/sbin/frida-server",
            "/etc/apt",
            "/private/var/lib/apt/",
            "/private/var/Users/",
            "/var/log/syslog",
            "/bin/bash",
            "/usr/sbin/sshd",
            "/etc/ssh/sshd_config",
            "/System/Library/LaunchDaemons/ssh.plist",
            "/usr/libexec/sftp-server",
            "/usr/bin/sshd",
            "/usr/sbin/sshd",
            "/var/log/apt"
        ]
        
        for path in jailbreakPaths {
            if FileManager.default.fileExists(atPath: path) {
                return true
            }
        }
        
        // 检测越狱相关的系统调用
        let jailbreakChecks = [
            "fork",
            "setsid",
            "setuid",
            "setgid",
            "setreuid",
            "setregid",
            "setgroups",
            "setlogin",
            "setpgid",
            "setpgrp",
            "setpriority",
            "setrlimit",
            "setsid",
            "setuid",
            "setgid",
            "setreuid",
            "setregid",
            "setgroups",
            "setlogin",
            "setpgid",
            "setpgrp",
            "setpriority",
            "setrlimit"
        ]
        
        for check in jailbreakChecks {
            if dlsym(dlopen(nil, RTLD_NOW), check) != nil {
                return true
            }
        }
        
        return false
    }
    
    /// 检测是否在模拟器环境
    public static func st_detectSimulator() -> Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }
    
    /// 检测网络连接状态
    public static func st_detectNetworkConnection() -> Bool {
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        let defaultRouteReachability = withUnsafePointer(to: &zeroAddress) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { zeroSockAddress in
                SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
            }
        }
        
        var flags = SCNetworkReachabilityFlags()
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) {
            return false
        }
        
        let isReachable = flags.contains(.reachable)
        let needsConnection = flags.contains(.connectionRequired)
        
        return (isReachable && !needsConnection)
    }
    
    /// 检测SSL证书绑定
    public static func st_detectSSLPinning() -> Bool {
        // 这里可以添加SSL证书绑定的检测逻辑
        // 例如检查是否有自定义的证书验证逻辑
        return false
    }
    
    /// 检测应用完整性
    public static func st_detectAppIntegrity() -> Bool {
        // 检查应用签名
        guard let bundlePath = Bundle.main.bundlePath.cString(using: .utf8) else {
            return false
        }
        
        let bundleURL = CFURLCreateFromFileSystemRepresentation(nil, bundlePath, strlen(bundlePath), true)
        guard let bundle = CFBundleCreate(nil, bundleURL) else {
            return false
        }
        
        guard let infoDict = CFBundleGetInfoDictionary(bundle) else {
            return false
        }
        
        // 检查签名信息
        let signature = CFDictionaryGetValue(infoDict, Unmanaged.passUnretained("CFBundleSignature" as CFString).toOpaque())
        return signature != nil
    }
}
