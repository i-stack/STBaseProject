//
//  STCustomURLProtocol.swift
//  STBaseProject_Example
//
//  Created by qcraft on 2022/3/10.
//  Copyright © 2022 STBaseProject. All rights reserved.
//

import UIKit

class STCustomURLProtocol: URLProtocol {
    
    /// 适用于UIWebView
    override class func canInit(with request: URLRequest) -> Bool {
        if request.url?.scheme?.caseInsensitiveCompare("myapp") == .orderedSame {
            return true
        }
        return true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        let response = URLResponse.init(url: request.url!, mimeType: "image/png", expectedContentLength: -1, textEncodingName: nil)
        if let data = UIImage.init(named: "bg_content")?.pngData() {
            self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            self.client?.urlProtocol(self, didLoad: data)
            self.client?.urlProtocolDidFinishLoading(self)
        }
    }
    
    override func stopLoading() {
        
    }
}
