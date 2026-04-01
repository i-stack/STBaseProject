//
//  STDeviceInfo.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2019/02/10.
//

import UIKit
import Darwin
import Network

public struct STDeviceInfo {

    public struct STAppInfo: Sendable {
        public let version: String
        public let buildVersion: String
        public let bundleIdentifier: String
        public let displayName: String
    }

    public struct STBatteryInfo: Sendable {
        public let level: Float
        public let percentage: Int
        public let state: STBatteryState

        public var isCharging: Bool {
            state == .charging
        }

        public var isFull: Bool {
            state == .full
        }

        fileprivate var legacyDictionary: [String: Any] {
            [
                "battery_level": level,
                "battery_percentage": percentage,
                "battery_state": state.rawValue,
                "is_charging": isCharging,
                "is_full": isFull
            ]
        }
    }

    public struct STStorageInfo: Sendable {
        public let total: Int64
        public let free: Int64

        public var used: Int64 {
            max(total - free, 0)
        }

        public var usagePercentage: Double {
            total > 0 ? Double(used) / Double(total) * 100.0 : 0.0
        }
    }

    public struct STMemoryInfo: Sendable {
        public let total: Int64
        public let free: Int64

        public var used: Int64 {
            max(total - free, 0)
        }

        public var usagePercentage: Double {
            total > 0 ? Double(used) / Double(total) * 100.0 : 0.0
        }
    }
}

// MARK: - App Information
public extension STDeviceInfo {

    static var appInfoDictionary: [String: Any] {
        Bundle.main.infoDictionary ?? [:]
    }

    static var appInfo: STAppInfo {
        STAppInfo(
            version: bundleString(for: "CFBundleShortVersionString"),
            buildVersion: bundleString(for: "CFBundleVersion"),
            bundleIdentifier: Bundle.main.bundleIdentifier ?? "",
            displayName: bundleString(for: "CFBundleDisplayName", fallbackKey: "CFBundleName")
        )
    }

    static var appVersion: String {
        appInfo.version
    }

    static var appName: String {
        appInfo.displayName
    }

    static var appBuildVersion: String {
        appInfo.buildVersion
    }

    static var appBundleIdentifier: String {
        appInfo.bundleIdentifier
    }
}

// MARK: - Screen & Orientation
public extension STDeviceInfo {

    @MainActor
    static var interfaceOrientation: UIInterfaceOrientation {
        preferredWindowScene()?.interfaceOrientation ?? .unknown
    }

    @MainActor
    static var isLandscape: Bool {
        interfaceOrientation.isLandscape
    }

    @MainActor
    static var isPortrait: Bool {
        interfaceOrientation.isPortrait
    }

    @MainActor
    static var screenBounds: CGRect {
        UIScreen.main.bounds
    }

    @MainActor
    static var screenSize: CGSize {
        screenBounds.size
    }

    @MainActor
    static var screenScale: CGFloat {
        UIScreen.main.scale
    }

    /// 屏幕宽度
    @MainActor
    static var screenWidth: CGFloat {
        screenBounds.width
    }

    /// 屏幕高度
    @MainActor
    static var screenHeight: CGFloat {
        screenBounds.height
    }

    /// 顶部 / 底部安全区（基于当前 key window）
    @MainActor
    static var safeAreaInsets: UIEdgeInsets {
        preferredWindowScene()?.windows.first(where: \.isKeyWindow)?.safeAreaInsets ?? .zero
    }

    @MainActor
    static var topSafeAreaHeight: CGFloat {
        safeAreaInsets.top
    }

    @MainActor
    static var bottomSafeAreaHeight: CGFloat {
        safeAreaInsets.bottom
    }

    /// 是否是带刘海设备（通过顶部安全区高度粗略判断）
    @MainActor
    static var hasNotch: Bool {
        topSafeAreaHeight > 20
    }

    /// 状态栏高度
    @MainActor
    static var statusBarHeight: CGFloat {
        preferredWindowScene()?.statusBarManager?.statusBarFrame.height ?? 0
    }

    /// 默认导航栏高度
    static let navigationBarHeight: CGFloat = 44.0

    /// 默认标签栏高度
    static let tabBarHeight: CGFloat = 49.0
}

// MARK: - Device Information
public extension STDeviceInfo {

    static var systemVersion: String {
        UIDevice.current.systemVersion
    }

    /// iOS 主版本号（如 18.2 -> 18）
    static var systemMajorVersion: Int {
        Int(systemVersion.split(separator: ".").first ?? "0") ?? 0
    }

    static var systemName: String {
        UIDevice.current.systemName
    }

    static var deviceName: String {
        UIDevice.current.name
    }

    static var deviceModelName: String {
        UIDevice.current.model
    }

    static var deviceIdentifier: String {
        currentDeviceIdentifier()
    }

    static var deviceType: STDeviceType {
        deviceType(for: deviceIdentifier)
    }

    /// 是否运行在 iPhone 设备
    static var isIPhone: Bool {
        deviceType == .iPhone
    }

    /// 是否运行在 iPad 设备
    static var isIPad: Bool {
        deviceType == .iPad
    }

    static var devicePerformanceLevel: STDevicePerformanceLevel {
        performanceLevel(totalRAM: totalRAM, cpuCoreCount: ProcessInfo.processInfo.activeProcessorCount)
    }
}

// MARK: - Battery & Runtime
public extension STDeviceInfo {

    static var batteryInfo: STBatteryInfo {
        withBatteryMonitoring(makeBatteryInfo)
    }

    static var batteryLevel: Int {
        batteryInfo.percentage
    }

    static var isCharging: Bool {
        batteryInfo.isCharging
    }

    static var isRunningOnSimulator: Bool {
        #if targetEnvironment(simulator)
        true
        #else
        false
        #endif
    }

    static var isDeviceJailbroken: Bool {
        guard !isRunningOnSimulator else {
            return false
        }

        for path in jailbreakPaths where FileManager.default.fileExists(atPath: path) {
            return true
        }

        return canWriteToRestrictedPath()
    }

    static var isLowPowerModeEnabled: Bool {
        ProcessInfo.processInfo.isLowPowerModeEnabled
    }

    static var thermalState: STThermalState {
        STThermalState(ProcessInfo.processInfo.thermalState)
    }
}

// MARK: - Storage
public extension STDeviceInfo {

    static var storageInfo: STStorageInfo {
        let attributes = fileSystemAttributes()
        let total = attributes[.systemSize] as? Int64 ?? 0
        let free = attributes[.systemFreeSize] as? Int64 ?? 0
        return STStorageInfo(total: total, free: free)
    }

    static var totalStorage: Int64 {
        storageInfo.total
    }

    static var freeStorage: Int64 {
        storageInfo.free
    }

    static var usedStorage: Int64 {
        storageInfo.used
    }

    static var storageUsagePercentage: Double {
        storageInfo.usagePercentage
    }
}

// MARK: - Memory
public extension STDeviceInfo {

    static var totalRAM: Int64 {
        Int64(ProcessInfo.processInfo.physicalMemory)
    }

    static var memoryInfo: STMemoryInfo {
        STMemoryInfo(total: totalRAM, free: freeMemoryBytes())
    }

    static var freeRAM: Int64 {
        memoryInfo.free
    }

    static var usedRAM: Int64 {
        memoryInfo.used
    }

    static var memoryUsagePercentage: Double {
        memoryInfo.usagePercentage
    }
}

// MARK: - Network
public extension STDeviceInfo {

    static func currentNetworkConnectionType(completion: @escaping @Sendable (STNetworkConnectionType) -> Void) {
        let monitor = NWPathMonitor()
        let queue = DispatchQueue(label: "com.stbaseproject.deviceinfo.network")
        monitor.pathUpdateHandler = { path in
            completion(connectionType(for: path))
            monitor.cancel()
        }
        monitor.start(queue: queue)
    }

    static func currentNetworkConnectionType() async -> STNetworkConnectionType {
        await withCheckedContinuation { continuation in
            currentNetworkConnectionType { connectionType in
                continuation.resume(returning: connectionType)
            }
        }
    }
}

// MARK: - Private Helpers
private extension STDeviceInfo {

    static let jailbreakPaths = [
        "/Applications/Cydia.app",
        "/Library/MobileSubstrate/MobileSubstrate.dylib",
        "/bin/bash",
        "/usr/sbin/sshd",
        "/etc/apt",
        "/private/var/lib/apt/",
        "/private/var/lib/cydia",
        "/private/var/mobile/Library/SBSettings/Themes"
    ]

    static func bundleString(for key: String, fallbackKey: String? = nil) -> String {
        if let value = Bundle.main.object(forInfoDictionaryKey: key) as? String, !value.isEmpty {
            return value
        }

        guard let fallbackKey, let value = Bundle.main.object(forInfoDictionaryKey: fallbackKey) as? String else {
            return ""
        }

        return value
    }

    static func preferredWindowScene() -> UIWindowScene? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        if let activeScene = scenes.first(where: {
            $0.activationState == .foregroundActive && $0.windows.contains(where: \.isKeyWindow)
        }) {
            return activeScene
        }
        if let foregroundScene = scenes.first(where: { $0.activationState == .foregroundActive }) {
            return foregroundScene
        }
        return scenes.first
    }

    static func withBatteryMonitoring<T>(_ operation: (UIDevice) -> T) -> T {
        let device = UIDevice.current
        let previousValue = device.isBatteryMonitoringEnabled
        if !previousValue {
            device.isBatteryMonitoringEnabled = true
        }
        defer {
            if !previousValue {
                device.isBatteryMonitoringEnabled = false
            }
        }
        return operation(device)
    }

    static func currentDeviceIdentifier() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        return withUnsafePointer(to: &systemInfo.machine) { pointer in
            pointer.withMemoryRebound(to: CChar.self, capacity: 1) {
                String(cString: $0)
            }
        }
    }

    static func deviceType(for identifier: String) -> STDeviceType {
        if identifier.hasPrefix("iPhone") {
            return .iPhone
        }

        if identifier.hasPrefix("iPad") {
            return .iPad
        }

        if identifier.hasPrefix("iPod") {
            return .iPod
        }

        if identifier.hasPrefix("AppleTV") {
            return .appleTV
        }

        if identifier.hasPrefix("Watch") {
            return .appleWatch
        }

        if identifier.hasPrefix("Mac") {
            return .mac
        }

        return .unknown
    }

    static func performanceLevel(totalRAM: Int64, cpuCoreCount: Int) -> STDevicePerformanceLevel {
        let totalRAMInGB = Double(totalRAM) / 1_073_741_824.0

        if totalRAMInGB >= 6.0 || cpuCoreCount >= 6 {
            return .high
        }

        if totalRAMInGB >= 3.0 || cpuCoreCount >= 4 {
            return .medium
        }

        return .low
    }

    static func makeBatteryInfo(for device: UIDevice) -> STBatteryInfo {
        let batteryState = STBatteryState(device.batteryState)
        let batteryLevel = device.batteryLevel
        let percentage = batteryLevel >= 0 ? Int((batteryLevel * 100.0).rounded()) : -1

        return STBatteryInfo(
            level: batteryLevel,
            percentage: percentage,
            state: batteryState
        )
    }

    static func canWriteToRestrictedPath() -> Bool {
        let testPath = "/private/jailbreak_test"

        do {
            try "test".write(toFile: testPath, atomically: true, encoding: .utf8)
            try FileManager.default.removeItem(atPath: testPath)
            return true
        } catch {
            return false
        }
    }

    static func fileSystemAttributes() -> [FileAttributeKey: Any] {
        (try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory())) ?? [:]
    }

    static func freeMemoryBytes() -> Int64 {
        var vmStats = vm_statistics64()
        var size = mach_msg_type_number_t(MemoryLayout.size(ofValue: vmStats) / MemoryLayout<integer_t>.size)
        let hostPort = mach_host_self()

        let result = withUnsafeMutablePointer(to: &vmStats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(size)) {
                host_statistics64(hostPort, HOST_VM_INFO64, $0, &size)
            }
        }

        guard result == KERN_SUCCESS else {
            return 0
        }

        let freeMemory = UInt64(vmStats.free_count) * UInt64(vm_page_size)
        return Int64(freeMemory)
    }

    static func connectionType(for path: NWPath) -> STNetworkConnectionType {
        if path.usesInterfaceType(.wifi) {
            return .wifi
        }

        if path.usesInterfaceType(.cellular) {
            return .cellular
        }

        if path.usesInterfaceType(.wiredEthernet) {
            return .ethernet
        }

        return .unknown
    }
}

// MARK: - Enums

public enum STBatteryState: String, Sendable {
    case charging
    case full
    case unplugged
    case unknown

    fileprivate init(_ state: UIDevice.BatteryState) {
        switch state {
        case .charging:
            self = .charging
        case .full:
            self = .full
        case .unplugged:
            self = .unplugged
        case .unknown:
            self = .unknown
        @unknown default:
            self = .unknown
        }
    }
}

public enum STDeviceType: String, Sendable {
    case iPhone = "iphone"
    case iPad = "ipad"
    case iPod = "ipod"
    case appleTV = "apple_tv"
    case appleWatch = "apple_watch"
    case mac = "mac"
    case unknown = "unknown"
}

public enum STNetworkConnectionType: String, Sendable {
    case wifi = "wifi"
    case cellular = "cellular"
    case ethernet = "ethernet"
    case unknown = "unknown"
}

public enum STDevicePerformanceLevel: String, Sendable {
    case low = "low"
    case medium = "medium"
    case high = "high"
}

public enum STThermalState: String, Sendable {
    case nominal = "nominal"
    case fair = "fair"
    case serious = "serious"
    case critical = "critical"
    case unknown = "unknown"

    fileprivate init(_ state: ProcessInfo.ThermalState) {
        switch state {
        case .nominal:
            self = .nominal
        case .fair:
            self = .fair
        case .serious:
            self = .serious
        case .critical:
            self = .critical
        @unknown default:
            self = .unknown
        }
    }
}
