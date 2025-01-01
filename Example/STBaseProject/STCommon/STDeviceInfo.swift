//
//  STDeviceInfo.swift
//  STBaseProject
//
//  Created by stack on 2019/02/10.
//

import UIKit

public struct STDeviceInfo {
    
    /// uuid
    public static func uuid() -> String {
        return UIDevice.current.identifierForVendor?.uuidString ?? ""
    }
    
    public static func currentSysVersion() -> String {
        return UIDevice.current.systemVersion
    }
    
    public static func currentAppVersion() -> String {
        let info = self.appInfo()
        if let appVersion = info["CFBundleShortVersionString"] as? String {
            return appVersion
        }
        return ""
    }
    
    public static func currentAppName() -> String {
        let info = self.appInfo()
        if let appName = info["CFBundleDisplayName"] as? String {
            return appName
        }
        if let appName = info["CFBundleName"] as? String {
            return appName
        }
        return ""
    }
    
    public static func appInfo() -> Dictionary<String, Any> {
        return Bundle.main.infoDictionary ?? Dictionary<String, Any>()
    }
    
    public static func isLandscape() -> Bool {
        let orientation = appInterfaceOrientation()
        if orientation == .landscapeLeft || orientation == .landscapeRight {
            return true
        }
        return false
    }
    
    public static func isPortrait() -> Bool {
        let orientation = appInterfaceOrientation()
        if orientation == .portrait || orientation == .portraitUpsideDown {
            return true
        }
        return false
    }

    public static func appStatusBarOrientation() -> UIInterfaceOrientation {
        return appInterfaceOrientation()
    }
    
    public static func appInterfaceOrientation() -> UIInterfaceOrientation {
        var orientation = UIInterfaceOrientation.unknown
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            orientation = windowScene.interfaceOrientation
        }
        return orientation
    }
}
