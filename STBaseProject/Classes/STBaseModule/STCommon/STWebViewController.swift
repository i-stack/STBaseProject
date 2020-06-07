//
//  STWebViewController.swift
//  STBaseProject
//
//  Created by stack on 2019/1/28.
//  Copyright © 2019年 ST. All rights reserved.
//

import UIKit
import WebKit
import JavaScriptCore

public struct STWebConfig {
    public var url: String?
    public var titleText: String?
    public var htmlString: String?
    public var backArrowIcon: String?
    public var showProgress: Bool?
    
    public init() {}
}

open class STWebViewController: STBaseViewController {
    var finishLoad: Bool = false

    var webConfig: STWebConfig?
    var jsContext: JSContext?
    var progress: UIProgressView?
    var orientationSupport: String?
    
    public init(config: STWebConfig) {
        super.init(nibName: nil, bundle: nil)
        self.webConfig = config
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        self.configUI()
        self.configNav()
    }
    
    func configNav() {
        self.st_showNavBtnType(type: .showLeftBtn)
        self.titleLabel.text = self.webConfig?.titleText
        if let backArrowIcon = self.webConfig?.backArrowIcon {
            self.leftBtn.setImage(UIImage.init(named: backArrowIcon), for: .normal)
        }
    }
    
    open override func st_rightBarBtnClick() {
        
    }
    
    func configUI() -> Void {
        self.view.addSubview(self.webView)
        self.view.addConstraints([
            NSLayoutConstraint.init(item: self.webView, attribute: .top, relatedBy: .equal, toItem: self.view, attribute: .top, multiplier: 1, constant: STConstants.st_navHeight()),
            NSLayoutConstraint.init(item: self.webView, attribute: .left, relatedBy: .equal, toItem: self.view, attribute: .left, multiplier: 1, constant: 0),
            NSLayoutConstraint.init(item: self.webView, attribute: .bottom, relatedBy: .equal, toItem: self.view, attribute: .bottom, multiplier: 1, constant: 0),
            NSLayoutConstraint.init(item: self.webView, attribute: .right, relatedBy: .equal, toItem: self.view, attribute: .right, multiplier: 1, constant: 0)
        ])
        if let html = self.webConfig?.htmlString, html.count > 0 {
            self.webView.loadHTMLString(html, baseURL: nil)
        } else if let newUrl = self.webConfig?.url, newUrl.count > 0 {
            if let url = URL.init(string: newUrl) {
                self.webView.load(URLRequest.init(url: url))
            }
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {

    }
    
    lazy var webView: WKWebView = {
        let view = WKWebView()
        view.uiDelegate = self
        view.navigationDelegate = self
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
}

extension STWebViewController: WKUIDelegate, WKNavigationDelegate {
    public func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        
    }
    
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        
    }
    
    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        
    }
}
