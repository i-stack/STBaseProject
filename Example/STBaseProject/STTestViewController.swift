//
//  STTestViewController.swift
//  STBaseProject_Example
//
//  Created by song on 2021/1/28.
//  Copyright © 2021 STBaseProject. All rights reserved.
//

import UIKit
import WebKit
import STBaseProject

class STTestViewController: STBaseViewController {
    
    deinit {
        STLogP("STTestViewController dealloc")
    }
    
    var count: Int = 0
    override func viewDidLoad() {
        super.viewDidLoad()
        self.titleLabel.text = "STTestViewController"
        self.st_showNavBtnType(type: .showLeftBtn)
        self.view.backgroundColor = UIColor.blue
        
        self.beginLoadingWeb()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
    }
    
    private lazy var webView: WKWebView = {
        let config = WKWebViewConfiguration()
        config.setURLSchemeHandler(self, forURLScheme: "app")
        config.setURLSchemeHandler(self, forURLScheme: "myapp")
        let view = WKWebView.init(frame: self.view.bounds, configuration: config)
        return view
    }()
    
    private func beginLoadingWeb() {
        self.view.addSubview(self.webView)
//        URLProtocol.registerClass(STCustomURLProtocol.self)
        
        if let localHtmlFilePath = Bundle.main.path(forResource: "file", ofType: "html") {
            let localHtmlFileURL = "file://\(localHtmlFilePath)"
            if let url = URL.init(string: localHtmlFileURL) {
                self.webView.load(URLRequest.init(url: url))
            }
            
            if let html = try? String.init(contentsOfFile: localHtmlFilePath, encoding: .utf8) {
                self.webView.loadHTMLString(html, baseURL: nil)
            }
        }
    }
}

extension STTestViewController: WKURLSchemeHandler {
    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
        
    }
    
    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        if let url = urlSchemeTask.request.url {
            if url.scheme?.caseInsensitiveCompare("myapp") == .orderedSame {
                let response = URLResponse.init(url: url, mimeType: "image/png", expectedContentLength: -1, textEncodingName: nil)
                if let data = UIImage.init(named: url.host ?? "")?.pngData() {
                    urlSchemeTask.didReceive(response)
                    urlSchemeTask.didReceive(data)
                    urlSchemeTask.didFinish()
                }
            }
            
            if url.scheme?.caseInsensitiveCompare("app") == .orderedSame {
                let response = URLResponse.init(url: url, mimeType: "image/png", expectedContentLength: -1, textEncodingName: nil)
                if let data = UIImage.init(named: url.host ?? "")?.pngData() {
                    urlSchemeTask.didReceive(response)
                    urlSchemeTask.didReceive(data)
                    urlSchemeTask.didFinish()
                }
            }
        }
    }
}
