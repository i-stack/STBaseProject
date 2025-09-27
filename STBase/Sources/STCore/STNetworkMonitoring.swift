//
//  STNetworkMonitoring.swift
//  STBaseProject
//
//  Created by stack on 2018/12/10.
//

import UIKit
import Network

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
}
