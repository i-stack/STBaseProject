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

open class STWebViewController: STBaseViewController {
    
    var url: URL?
    var titleText: String?
    var htmlString: String?
    var showProgress: Bool = true
    var progress: UIProgressView?
    var finishLoad: Bool = false

    var jsContext: JSContext?
    var orientationSupport: String?
    
    public init(url: String?, htmlString: String?, title: String?, showProgress: Bool) {
        super.init(nibName: nil, bundle: nil)
        if !(url?.isEmpty ?? true) {
            let customAllowedSet =  NSCharacterSet(charactersIn:"`%^{}\"[]|\\<> ").inverted
            let newUrl = url?.addingPercentEncoding(withAllowedCharacters: customAllowedSet)
            self.url = URL.init(string: newUrl ?? "")
        }
        self.htmlString = htmlString
        self.titleText = title
        self.showProgress = showProgress
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        self.configUI()
        self.configNav()
    }
    
    func configNav() {
        self.st_showNavBtnType(type: .showLeftBtn)
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
        if let html = self.htmlString, html.count > 0 {
            self.webView.loadHTMLString(html, baseURL: nil)
        } else if let newUrl = self.url {
            self.webView.load(URLRequest.init(url: newUrl))
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
