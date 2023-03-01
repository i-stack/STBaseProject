//
//  AriaBackgroundManager.swift
//  AriaM3U8Downloader
//
//  Created by 神崎H亚里亚 on 2019/11/29.
//  Copyright © 2019 moxcomic. All rights reserved.
//

import UIKit
import Alamofire
import RxAlamofire

public class AriaBackgroundManager: NSObject {
    @objc
    public static let shared = AriaBackgroundManager()
    
    /// 供OC调用设置 backgroundCompletionHandler
    /// - Parameter block: backgroundCompletionHandler
    @objc
    public func setBackgroundCompletionHandler(block: (() -> ())?) {
        manager.backgroundCompletionHandler = block
    }
    
    public let manager: SessionManager = {
        let configuration = URLSessionConfiguration.background(withIdentifier: "com.moxcomic.AriaM3U8Downloader")
        configuration.httpAdditionalHeaders = SessionManager.defaultHTTPHeaders
        configuration.timeoutIntervalForRequest = 10
        configuration.timeoutIntervalForResource = 10
        configuration.sharedContainerIdentifier = "com.moxcomic.AriaM3U8Downloader"
        return SessionManager(configuration: configuration)
    }()
}
