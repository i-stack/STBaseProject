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
    
    /// Gets the identifier from the system, such as "iPhone14,3".
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

    public static func st_getDeviceBatteryStatusInfo() -> [String: Any] {
        let device = UIDevice.current
        device.isBatteryMonitoringEnabled = true
        return [
            "battery_pct": device.batteryLevel * 100,
            "is_charging": device.batteryState == .charging ? 1 : 0
        ]
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

// MARK: - idfa, idfv
public extension STDeviceInfo {
    static func st_idfa() -> String {
        return ASIdentifierManager.shared().advertisingIdentifier.uuidString
    }
    
    static func st_idfv() -> String {
        return UIDevice.current.identifierForVendor?.uuidString ?? ""
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
}

// MARK: - device storage
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
