//
//  STNetworkMonitoring.swift
//  STBaseProject
//
//  Created by stack on 2018/12/10.
//

import UIKit
import Network
import SystemConfiguration.CaptiveNetwork

public enum STNetworkStatus: Int, @unchecked Sendable {
    case WiFi = 0
    case Cellular = 1
    case NoNetwork = 2
}

public class STNetworkMonitoring: NSObject {
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "STNetworkMonitoring")

    public func st_startMonitoring(networkStatusChanged: @escaping ((STNetworkStatus, String) -> Void)) {
        monitor.pathUpdateHandler = { path in
            if path.status == .satisfied {
                if path.usesInterfaceType(.wifi) {
                    networkStatusChanged(.WiFi, "Connected to Wi-Fi")
                } else if path.usesInterfaceType(.cellular) {
                    networkStatusChanged(.Cellular, "Connected to Cellular")
                }
            } else {
                networkStatusChanged(.NoNetwork, "No network connection")
            }
        }
        monitor.start(queue: queue)
    }

    public func st_stopMonitoring() {
        monitor.cancel()
    }
    
    static func st_getNetworkInfo() -> [String: String] {
        var networkInfo: [String: String] = [:]
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
