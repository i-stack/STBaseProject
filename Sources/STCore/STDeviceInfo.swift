//
//  STDeviceInfo.swift
//  STBaseProject
//
//  Created by stack on 2019/02/10.
//

import UIKit
import Darwin
import Network
import CoreTelephony
import SystemConfiguration

// MARK: - STDeviceInfo
public struct STDeviceInfo {
    
    // MARK: - App Information
    /// 获取当前应用版本号
    public static func st_currentAppVersion() -> String {
        let info = st_appInfo()
        return info["CFBundleShortVersionString"] as? String ?? ""
    }
    
    /// 获取当前应用名称
    public static func st_currentAppName() -> String {
        let info = st_appInfo()
        return info["CFBundleDisplayName"] as? String ?? 
               info["CFBundleName"] as? String ?? ""
    }
    
    /// 获取应用构建版本号
    public static func st_currentAppBuildVersion() -> String {
        let info = st_appInfo()
        return info["CFBundleVersion"] as? String ?? ""
    }
    
    /// 获取应用Bundle ID
    public static func st_currentAppBundleId() -> String {
        let info = st_appInfo()
        return info["CFBundleIdentifier"] as? String ?? ""
    }
    
    /// 获取应用信息字典
    public static func st_appInfo() -> [String: Any] {
        return Bundle.main.infoDictionary ?? [:]
    }
    
    // MARK: - Device Orientation
    /// 判断是否为横屏
    public static func st_isLandscape() -> Bool {
        let orientation = st_appInterfaceOrientation()
        return orientation == .landscapeLeft || orientation == .landscapeRight
    }
    
    /// 判断是否为竖屏
    public static func st_isPortrait() -> Bool {
        let orientation = st_appInterfaceOrientation()
        return orientation == .portrait || orientation == .portraitUpsideDown
    }
    
    /// 获取应用界面方向
    public static func st_appInterfaceOrientation() -> UIInterfaceOrientation {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            return windowScene.interfaceOrientation
        }
        return .unknown
    }
    
    // MARK: - System Information
    /// 获取系统版本
    public static func st_getSystemVersion() -> String {
        return UIDevice.current.systemVersion
    }
    
    /// 获取系统名称
    public static func st_getSystemName() -> String {
        return UIDevice.current.systemName
    }
    
    /// 获取设备名称
    public static func st_getDeviceName() -> String {
        return UIDevice.current.name
    }
    
    /// 获取设备型号标识符（如 "iPhone14,3"）
    public static func st_getDeviceIdentifier() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.compactMap { element in
            guard let value = element.value as? Int8, value != 0 else { return nil }
            return String(UnicodeScalar(UInt8(value)))
        }.joined()
        return identifier
    }

    /// 获取设备类型
    public static func st_getDeviceType() -> STDeviceType {
        let identifier = st_getDeviceIdentifier()
        return st_deviceType(for: identifier)
    }
    
    // MARK: - Battery Information
    /// 获取设备电池状态信息
    public static func st_getDeviceBatteryStatusInfo() -> [String: Any] {
        let device = UIDevice.current
        device.isBatteryMonitoringEnabled = true
        var batteryState = "unknown"
        switch device.batteryState {
        case .charging:
            batteryState = "charging"
        case .full:
            batteryState = "full"
        case .unplugged:
            batteryState = "unplugged"
        case .unknown:
            batteryState = "unknown"
        @unknown default:
            batteryState = "unknown"
        }
        return [
            "battery_level": device.batteryLevel,
            "battery_percentage": Int(device.batteryLevel * 100),
            "battery_state": batteryState,
            "is_charging": device.batteryState == .charging,
            "is_full": device.batteryState == .full
        ]
    }
    
    /// 获取电池电量百分比
    public static func st_getBatteryLevel() -> Int {
        let device = UIDevice.current
        device.isBatteryMonitoringEnabled = true
        return Int(device.batteryLevel * 100)
    }
    
    /// 判断是否正在充电
    public static func st_isCharging() -> Bool {
        let device = UIDevice.current
        device.isBatteryMonitoringEnabled = true
        return device.batteryState == .charging
    }
    
    // MARK: - Network Information
    /// 获取网络连接类型
    public static func st_getNetworkConnectionType() -> STNetworkConnectionType {
        let monitor = NWPathMonitor()
        var connectionType: STNetworkConnectionType = .unknown
        let group = DispatchGroup()
        group.enter()
        monitor.pathUpdateHandler = { path in
            if path.usesInterfaceType(.wifi) {
                connectionType = .wifi
            } else if path.usesInterfaceType(.cellular) {
                connectionType = .cellular
            } else if path.usesInterfaceType(.wiredEthernet) {
                connectionType = .ethernet
            } else {
                connectionType = .unknown
            }
            group.leave()
        }
        let queue = DispatchQueue(label: "NetworkMonitor")
        monitor.start(queue: queue)
        _ = group.wait(timeout: .now() + 1.0)
        monitor.cancel()
        return connectionType
    }
    
    /// 获取运营商信息
    public static func st_getCarrierInfo() -> [String: String] {
        let networkInfo = CTTelephonyNetworkInfo()
        var carrierInfo: [String: String] = [:]
        if #available(iOS 12.0, *) {
            if let carriers = networkInfo.serviceSubscriberCellularProviders {
                for (_, carrier) in carriers {
                    carrierInfo["carrier_name"] = carrier.carrierName ?? ""
                    carrierInfo["mobile_country_code"] = carrier.mobileCountryCode ?? ""
                    carrierInfo["mobile_network_code"] = carrier.mobileNetworkCode ?? ""
                    carrierInfo["iso_country_code"] = carrier.isoCountryCode ?? ""
                    carrierInfo["allows_voip"] = carrier.allowsVOIP ? "true" : "false"
                    break
                }
            }
        } else {
            if let carrier = networkInfo.subscriberCellularProvider {
                carrierInfo["carrier_name"] = carrier.carrierName ?? ""
                carrierInfo["mobile_country_code"] = carrier.mobileCountryCode ?? ""
                carrierInfo["mobile_network_code"] = carrier.mobileNetworkCode ?? ""
                carrierInfo["iso_country_code"] = carrier.isoCountryCode ?? ""
                carrierInfo["allows_voip"] = carrier.allowsVOIP ? "true" : "false"
            }
        }
        return carrierInfo
    }
    
    /// 获取设备IP地址（仅WiFi）
    public static func st_getDeviceIPAddress() -> String {
        var address: String = ""
        var ifaddr: UnsafeMutablePointer<ifaddrs>? = nil
        guard getifaddrs(&ifaddr) == 0 else { return "" }
        defer { freeifaddrs(ifaddr) }
        guard let firstAddr = ifaddr else { return "" }
        for ifptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ifptr.pointee
            let addrFamily = interface.ifa_addr.pointee.sa_family
            if addrFamily == UInt8(AF_INET) {
                let name = String(cString: interface.ifa_name)
                if name == "en0" { // Wi-Fi
                    var addr = interface.ifa_addr.pointee
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(&addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                               &hostname, socklen_t(hostname.count),
                               nil, socklen_t(0), NI_NUMERICHOST)
                    address = String(cString: hostname)
                    break
                }
            }
        }
        return address
    }
    
    // MARK: - Device Security
    /// 判断是否运行在模拟器上
    public static func st_isRunningOnSimulator() -> Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }
    
    /// 判断设备是否越狱
    public static func st_isDeviceJailbroken() -> Bool {
        let jailbreakPaths = [
            "/Applications/Cydia.app",
            "/Library/MobileSubstrate/MobileSubstrate.dylib",
            "/bin/bash",
            "/usr/sbin/sshd",
            "/etc/apt",
            "/private/var/lib/apt/",
            "/private/var/lib/cydia",
            "/private/var/mobile/Library/SBSettings/Themes"
        ]
        for path in jailbreakPaths {
            if FileManager.default.fileExists(atPath: path) {
                return true
            }
        }
        
        // 检查是否可以写入系统目录
        let testPath = "/private/jailbreak_test"
        do {
            try "test".write(toFile: testPath, atomically: true, encoding: .utf8)
            try FileManager.default.removeItem(atPath: testPath)
            return true
        } catch {
            return false
        }
    }
    
    // MARK: - Storage Information
    /// 获取总存储空间（字节）
    public static func st_getTotalStorage() -> Int64 {
        if let attributes = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory()),
           let totalSize = attributes[.systemSize] as? Int64 {
            return totalSize
        }
        return 0
    }
    
    /// 获取可用存储空间（字节）
    public static func st_getFreeStorage() -> Int64 {
        if let attributes = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory()),
           let freeSize = attributes[.systemFreeSize] as? Int64 {
            return freeSize
        }
        return 0
    }
    
    /// 获取已使用存储空间（字节）
    public static func st_getUsedStorage() -> Int64 {
        return st_getTotalStorage() - st_getFreeStorage()
    }
    
    /// 获取存储空间使用百分比
    public static func st_getStorageUsagePercentage() -> Double {
        let total = st_getTotalStorage()
        let used = st_getUsedStorage()
        return total > 0 ? Double(used) / Double(total) * 100.0 : 0.0
    }
    
    // MARK: - Memory Information
    /// 获取总内存（字节）
    public static func st_getTotalRAM() -> Int64 {
        return Int64(ProcessInfo.processInfo.physicalMemory)
    }
    
    /// 获取可用内存（字节）
    public static func st_getFreeRAM() -> Int64 {
        var vmStats = vm_statistics64()
        var size = mach_msg_type_number_t(MemoryLayout.size(ofValue: vmStats) / MemoryLayout<integer_t>.size)
        let hostPort = mach_host_self()
        let result = withUnsafeMutablePointer(to: &vmStats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(size)) {
                host_statistics64(hostPort, HOST_VM_INFO64, $0, &size)
            }
        }
        if result != KERN_SUCCESS {
            return 0
        }
        let freeMemory = UInt64(vmStats.free_count) * UInt64(vm_page_size)
        return Int64(freeMemory)
    }
    
    /// 获取内存使用百分比
    public static func st_getMemoryUsagePercentage() -> Double {
        let total = st_getTotalRAM()
        let free = st_getFreeRAM()
        let used = total - free
        return total > 0 ? Double(used) / Double(total) * 100.0 : 0.0
    }
    
    // MARK: - Basic Device Information
    private static func st_deviceType(for identifier: String) -> STDeviceType {
        if identifier.hasPrefix("iPhone") {
            return .iPhone
        } else if identifier.hasPrefix("iPad") {
            return .iPad
        } else if identifier.hasPrefix("iPod") {
            return .iPod
        } else if identifier.hasPrefix("AppleTV") {
            return .appleTV
        } else if identifier.hasPrefix("Watch") {
            return .appleWatch
        } else if identifier.hasPrefix("Mac") {
            return .mac
        } else {
            return .unknown
        }
    }
}

// MARK: - Enums
public enum STDeviceType {
    case iPhone
    case iPad
    case iPod
    case appleTV
    case appleWatch
    case mac
    case unknown
}

public enum STNetworkConnectionType {
    case wifi
    case cellular
    case ethernet
    case unknown
}

public enum STDevicePerformanceLevel {
    case low
    case medium
    case high
}
