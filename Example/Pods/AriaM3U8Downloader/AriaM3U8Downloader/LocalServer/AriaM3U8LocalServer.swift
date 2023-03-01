//
//  AriaM3U8LocalServer.swift
//  AriaM3U8Downloader
//
//  Created by 神崎H亚里亚 on 2019/11/29.
//  Copyright © 2019 moxcomic. All rights reserved.
//

import UIKit
import GCDWebServer

public class AriaM3U8LocalServer: NSObject {
    @objc
    public static let shared = AriaM3U8LocalServer()
    
    fileprivate var webServer: GCDWebServer!
    
    /// 开启本地服务
    /// - Parameters:
    ///   - path: 需要开放的主路径
    ///   - port: 端口, 默认 8080
    ///   - bonjourName: 本地服务名称, 默认 AriaM3U8LocalServer
    @objc
    public func start(withPath path: String, port: UInt = 8080, bonjourName: String = "AriaM3U8LocalServer") {
        if webServer != nil { print("本地服务已开启,请勿重复开启"); return }
        webServer = GCDWebDAVServer(uploadDirectory: path)
        webServer.start(withPort: port, bonjourName: bonjourName)
    }
    
    /// 停止本地服务
    @objc
    public func stop() {
        webServer.stop()
        webServer = nil
    }
    
    /// 获取本地服务URL
    /// 拼接需要以 / 开头
    @objc
    public func getLocalServerURLString() -> String? {
        if webServer == nil { return nil }
        return "http://localhost:\(webServer.port)"
    }
}
