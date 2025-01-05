//
//  STDeviceInfo.swift
//  STBaseProject
//
//  Created by stack on 2019/02/10.
//

import UIKit
import Darwin
import Network
import Contacts
import AdSupport
import NetworkExtension
import SystemConfiguration.CaptiveNetwork

public struct STDeviceInfo {

    public static func st_currentAppVersion() -> String {
        let info = self.st_appInfo()
        if let appVersion = info["CFBundleShortVersionString"] as? String {
            return appVersion
        }
        return ""
    }
    
    public static func st_currentAppName() -> String {
        let info = self.st_appInfo()
        if let appName = info["CFBundleDisplayName"] as? String {
            return appName
        }
        if let appName = info["CFBundleName"] as? String {
            return appName
        }
        return ""
    }
    
    public static func st_appInfo() -> Dictionary<String, Any> {
        return Bundle.main.infoDictionary ?? Dictionary<String, Any>()
    }
    
    public static func st_isLandscape() -> Bool {
        let orientation = st_appInterfaceOrientation()
        if orientation == .landscapeLeft || orientation == .landscapeRight {
            return true
        }
        return false
    }
    
    public static func st_isPortrait() -> Bool {
        let orientation = st_appInterfaceOrientation()
        if orientation == .portrait || orientation == .portraitUpsideDown {
            return true
        }
        return false
    }

    public static func st_appInterfaceOrientation() -> UIInterfaceOrientation {
        var orientation = UIInterfaceOrientation.unknown
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            orientation = windowScene.interfaceOrientation
        }
        return orientation
    }
    
    public static func st_getSystemVersion() -> String {
        return UIDevice.current.systemVersion
    }
    
    public static func st_getDeviceBrand() -> String {
        switch UIDevice.current.userInterfaceIdiom {
        case .phone:
            return "iPhone"
        case .pad:
            return "iPad"
        case .tv:
            return "Apple TV"
        case .carPlay:
            return "CarPlay"
        case .mac:
            return "Mac"
        default:
            return "Unknown"
        }
    }
    
    public static func st_getDeviceScreenInfo() -> (width: CGFloat, height: CGFloat, diagonal: Double) {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        let screenScale = UIScreen.main.scale
        let physicalWidth = screenWidth * screenScale
        let physicalHeight = screenHeight * screenScale
        let ppi: CGFloat = st_getDevicePPI()
        let widthInInches = physicalWidth / ppi
        let heightInInches = physicalHeight / ppi
        let diagonalInInches = sqrt(pow(widthInInches, 2) + pow(heightInInches, 2))
        return (width: screenWidth, height: screenHeight, diagonal: diagonalInInches)
    }
    
    public static func st_getDevicePPI() -> CGFloat {
        let deviceIdentifier = st_getDeviceIdentifier()
        let deviceModel = st_getDeviceModel(identifier: deviceIdentifier)
        switch deviceModel {
        case "iPhone 5s", "iPhone SE (1st generation)": return 326
        case "iPhone 6", "iPhone 6s", "iPhone 7", "iPhone 8": return 326
        case "iPhone 6 Plus", "iPhone 6s Plus", "iPhone 7 Plus", "iPhone 8 Plus": return 401
        case "iPhone X", "iPhone XS", "iPhone 11 Pro": return 458
        case "iPhone XR", "iPhone 11": return 326
        case "iPhone 11 Pro Max": return 458
        case "iPhone 12 mini": return 476
        case "iPhone 12", "iPhone 12 Pro", "iPhone 13", "iPhone 13 Pro": return 460
        case "iPhone 12 Pro Max", "iPhone 13 Pro Max": return 458
        case "iPhone 14", "iPhone 14 Plus": return 460
        case "iPhone 14 Pro": return 460
        case "iPhone 14 Pro Max": return 460
        case "iPhone 15", "iPhone 15 Plus": return 460
        case "iPhone 15 Pro", "iPhone 15 Pro Max": return 460
        default: return 326 // 默认返回 326
        }
    }
    
    // iPhone14,3
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

    // iPhone 13 Pro
    public static func st_getDeviceModel(identifier: String) -> String {
        switch identifier {
        case "iPhone6,1", "iPhone6,2": return "iPhone 5s"
        case "iPhone7,2": return "iPhone 6"
        case "iPhone7,1": return "iPhone 6 Plus"
        case "iPhone8,1": return "iPhone 6s"
        case "iPhone8,2": return "iPhone 6s Plus"
        case "iPhone8,4": return "iPhone SE (1st generation)"
        case "iPhone9,1", "iPhone9,3": return "iPhone 7"
        case "iPhone9,2", "iPhone9,4": return "iPhone 7 Plus"
        case "iPhone10,1", "iPhone10,4": return "iPhone 8"
        case "iPhone10,2", "iPhone10,5": return "iPhone 8 Plus"
        case "iPhone10,3", "iPhone10,6": return "iPhone X"
        case "iPhone11,8": return "iPhone XR"
        case "iPhone11,2": return "iPhone XS"
        case "iPhone11,4", "iPhone11,6": return "iPhone XS Max"
        case "iPhone12,1": return "iPhone 11"
        case "iPhone12,3": return "iPhone 11 Pro"
        case "iPhone12,5": return "iPhone 11 Pro Max"
        case "iPhone12,8": return "iPhone SE (2nd generation)"
        case "iPhone13,1": return "iPhone 12 mini"
        case "iPhone13,2": return "iPhone 12"
        case "iPhone13,3": return "iPhone 12 Pro"
        case "iPhone13,4": return "iPhone 12 Pro Max"
        case "iPhone14,4": return "iPhone 13 mini"
        case "iPhone14,5": return "iPhone 13"
        case "iPhone14,2": return "iPhone 13 Pro"
        case "iPhone14,3": return "iPhone 13 Pro Max"
        case "iPhone14,6": return "iPhone SE (3rd generation)"
        case "iPhone15,2": return "iPhone 14 Pro"
        case "iPhone15,3": return "iPhone 14 Pro Max"
        case "iPhone14,7": return "iPhone 14"
        case "iPhone14,8": return "iPhone 14 Plus"
        case "iPhone15,4": return "iPhone 15"
        case "iPhone15,5": return "iPhone 15 Plus"
        case "iPhone16,1": return "iPhone 15 Pro"
        case "iPhone16,2": return "iPhone 15 Pro Max"
        case "iPhone17,3": return "iPhone 16"
        case "iPhone17,4": return "iPhone 16 Plus"
        case "iPhone17,1": return "iPhone 16 Pro"
        case "iPhone17,2": return "iPhone 16 Pro Max"

        case "iPad4,1", "iPad4,2", "iPad4,3": return "iPad Air"
        case "iPad5,3", "iPad5,4": return "iPad Air 2"
        case "iPad6,7", "iPad6,8": return "iPad Pro (12.9-inch, 1st generation)"
        case "iPad7,1", "iPad7,2": return "iPad Pro (12.9-inch, 2nd generation)"
        case "iPad7,3", "iPad7,4": return "iPad Pro (10.5-inch)"
        case "iPad8,1", "iPad8,2", "iPad8,3", "iPad8,4": return "iPad Pro (11-inch, 1st generation)"
        case "iPad8,9", "iPad8,10": return "iPad Pro (11-inch, 2nd generation)"
        case "iPad8,5", "iPad8,6", "iPad8,7", "iPad8,8": return "iPad Pro (12.9-inch, 3rd generation)"
        case "iPad8,11", "iPad8,12": return "iPad Pro (12.9-inch, 4th generation)"
        case "iPad11,1", "iPad11,2": return "iPad mini (5th generation)"
        case "iPad11,3", "iPad11,4": return "iPad Air (3rd generation)"
        case "iPad13,1", "iPad13,2": return "iPad Air (4th generation)"
        case "iPad14,1", "iPad14,2": return "iPad Air (5th generation)"
        case "iPad13,4", "iPad13,5", "iPad13,6", "iPad13,7": return "iPad Pro (11-inch, 3rd generation)"
        case "iPad13,8", "iPad13,9", "iPad13,10", "iPad13,11": return "iPad Pro (12.9-inch, 5th generation)"
        case "iPad14,8", "iPad14,9": return "iPad Air (11 6th Gen)"
        case "iPad14,10", "iPad14,11": return "iPad Air (13 6th Gen)"
        case "iPad16,3", "iPad16,4": return "iPad Pro (11 5th Gen)"
        case "iPad16,5", "iPad16,6": return "iPad Pro (13 7th Gen)"
            
        case "Watch1,1", "Watch1,2": return "Apple Watch (1st generation)"
        case "Watch2,6", "Watch2,7": return "Apple Watch Series 1"
        case "Watch2,3", "Watch2,4": return "Apple Watch Series 2"
        case "Watch3,1", "Watch3,2", "Watch3,3", "Watch3,4": return "Apple Watch Series 3"
        case "Watch4,1", "Watch4,2", "Watch4,3", "Watch4,4": return "Apple Watch Series 4"
        case "Watch5,1", "Watch5,2", "Watch5,3", "Watch5,4": return "Apple Watch Series 5"
        case "Watch6,1", "Watch6,2", "Watch6,3", "Watch6,4": return "Apple Watch Series 6"
        case "WatchSE,1", "WatchSE,2": return "Apple Watch SE"
        case "Watch7,1", "Watch7,2", "Watch7,3", "Watch7,4": return "Apple Watch Series 7"
        case "Watch8,1", "Watch8,2", "Watch8,3", "Watch8,4": return "Apple Watch Series 8"
        case "WatchUltra1,1": return "Apple Watch Ultra"
            
        case "AppleTV5,3": return "Apple TV (4th generation)"
        case "AppleTV6,2": return "Apple TV 4K (1st generation)"
        case "AppleTV11,1": return "Apple TV 4K (2nd generation)"
        case "AppleTV14,1": return "Apple TV 4K (3rd generation)"
            
        default: return identifier
        }
    }
}

public extension STDeviceInfo {
    func st_requestContactPermission(complete: @escaping((Bool, [CNContact], String) -> Void)) {
        CNContactStore().requestAccess(for: .contacts) { (granted, error) in
            if granted {
                self.st_fetchContactInfo(complete: complete)
            } else {
                complete(false, [], "Access denied: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }

    func st_fetchContactInfo(complete: @escaping((Bool, [CNContact], String) -> Void)) {
        let contactStore = CNContactStore()
        let keysDescriptor = [
            CNContactFormatter.descriptorForRequiredKeys(for: .fullName),
            CNContactPhoneNumbersKey as CNKeyDescriptor
        ]
        do {
            let containers = try contactStore.containers(matching: nil)
            var allContacts: [CNContact] = []
            for container in containers {
                let fetchPredicate = CNContact.predicateForContactsInContainer(withIdentifier: container.identifier)
                let contacts = try contactStore.unifiedContacts(matching: fetchPredicate, keysToFetch: keysDescriptor)
                allContacts.append(contentsOf: contacts)
            }
            complete(true, allContacts, "")
        } catch {
            complete(false, [], "Error fetching contacts: \(error.localizedDescription)")
        }
    }
}

public extension STDeviceInfo {
    
    static func st_idfa() -> String {
        return ASIdentifierManager.shared().advertisingIdentifier.uuidString
    }
    
    static func st_uuid() -> String { // idfv
        return UIDevice.current.identifierForVendor?.uuidString ?? ""
    }
    
    static func st_currentSysVersion() -> String {
        return UIDevice.current.systemVersion
    }
    
    static func st_getDeviceBatteryStatusInfo() -> [String: Any] {
        let device = UIDevice.current
        device.isBatteryMonitoringEnabled = true
        return [
            "battery_pct": device.batteryLevel * 100,
            "is_charging": device.batteryState == .charging ? 1 : 0
        ]
    }
}

public extension STDeviceInfo {
    static func st_getNetworkInfo() -> [String: Any] {
        var networkInfo: [String: Any] = [:]
        if let interfaces = CNCopySupportedInterfaces() as? [String] {
            for interface in interfaces {
                if let unsafeInterfaceData = CNCopyCurrentNetworkInfo(interface as CFString) as? [String: Any] {
                    let bssid = unsafeInterfaceData["BSSID"] as? String ?? ""
                    let ssid = unsafeInterfaceData["SSID"] as? String ?? ""
                    networkInfo["bssid"] = bssid
                    networkInfo["ssid"] = ssid
                    networkInfo["mac"] = bssid
                    networkInfo["name"] = ssid
                }
            }
        }
        return networkInfo
    }
}

public extension STDeviceInfo {
    static func st_isRunningOnSimulator() -> Bool {
        return TARGET_OS_SIMULATOR != 0
    }

    static func st_isDeviceJailbroken() -> Bool {
        let jailbreakPaths = [
            "/Applications/Cydia.app",
            "/Library/MobileSubstrate/MobileSubstrate.dylib",
            "/bin/bash",
            "/usr/sbin/sshd",
            "/etc/apt"
        ]
        for path in jailbreakPaths {
            if FileManager.default.fileExists(atPath: path) {
                return true
            }
        }
        return false
    }
    
    static func st_isUseVPNConnected() -> Bool {
        let vpnManager = NEVPNManager.shared()
        var vpnIsConnected: Bool = false
        vpnManager.loadFromPreferences { error in
            if error != nil {
                vpnIsConnected = false
            } else {
                vpnIsConnected = vpnManager.connection.status == .connected
            }
        }
        
        return vpnIsConnected
    }
    
    static func st_getDeviceIPAddress() -> String {
        var address: String = ""
        var ifaddr: UnsafeMutablePointer<ifaddrs>? = nil
        guard getifaddrs(&ifaddr) == 0 else { return "" }
        guard let firstAddr = ifaddr else { return "" }
        for ifptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ifptr.pointee
            let addrFamily = interface.ifa_addr.pointee.sa_family
            if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6) {
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
        freeifaddrs(ifaddr)
        return address
    }
}

public extension STDeviceInfo {
    static func st_getTotalStorage() -> Int64 {
        if let attributes = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory()),
           let totalSize = attributes[.systemSize] as? Int64 {
            return totalSize
        }
        return 0
    }

    static func st_getFreeStorage() -> Int64 {
        if let attributes = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory()),
           let freeSize = attributes[.systemFreeSize] as? Int64 {
            return freeSize
        }
        return 0
    }

    static func st_getTotalRAM() -> Int64 {
        return Int64(ProcessInfo.processInfo.physicalMemory)
    }

    static func st_getFreeRAM() -> Int64 {
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
}
