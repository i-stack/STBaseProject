//
//  STCustomURLProtocol.swift
//  STBaseProject_Example
//
//  Created by qcraft on 2022/3/10.
//  Copyright © 2022 STBaseProject. All rights reserved.
//

import UIKit
import STBaseProject
import WebKit

class STCustomWebViewController: STBaseWKViewController {
    
    deinit {
        STLog("🌈 -> \(self) 🌈 ----> 🌈 dealloc")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configWeb()
    }
    
    func configWeb() {
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.wkWebView.configuration.userContentController.removeScriptMessageHandler(forName: "reneging")
    }
    
    override func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        
    }
    
    override func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        self.wkWebView.evaluateJavaScript("document.title") { result, error in
            if let text = result {
                self.titleLabel.text = String.st_returnStr(object: text)
            }
        }
    }
}
