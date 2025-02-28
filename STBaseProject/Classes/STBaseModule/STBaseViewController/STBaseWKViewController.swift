//
//  STBaseWKViewController.swift
//  STBaseProject
//
//  Created by song on 2020/12/31.
//
import WebKit
import StoreKit

public struct STWebInfo {
    var url: String?
    var titleText: String?
    var htmlString: String?
    var bgColor: String?
    
    public init(url: String? = nil, titleText: String? = nil, htmlString: String? = nil, bgColor: String? = nil) {
        self.url = url
        self.bgColor = bgColor
        self.titleText = titleText
        self.htmlString = htmlString
    }
}

open class STBaseWKViewController: STBaseViewController {
    
    open var webInfo: STWebInfo?
    private var wkConfig: WKWebViewConfiguration?
    private var progressObserver: NSKeyValueObservation?

    deinit {
        if self.wkWebView.isLoading {
            self.wkWebView.stopLoading()
        }
        self.wkWebView.uiDelegate = nil
        self.wkWebView.navigationDelegate = nil
        self.wkWebView.scrollView.delegate = nil
        self.wkWebView.removeFromSuperview()
        self.progressObserver?.invalidate()
        self.progressObserver = nil
        self.progressView.removeFromSuperview()
        self.webInfo = nil
        STLog("🌈 -> \(self) 🌈 ----> 🌈 dealloc")
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        self.updateNav()
    }
    
    open func loadWebInfo() {
        if let html = self.webInfo?.htmlString, html.count > 0 {
            self.wkWebView.loadHTMLString(html, baseURL: nil)
        } else if let newUrl = self.webInfo?.url, newUrl.count > 0 {
            if let url = URL.init(string: newUrl) {
                self.wkWebView.load(URLRequest.init(url: url))
            }
        }
    }
    
    public func configWkWebView(config: WKWebViewConfiguration, showProgressView: Bool) {
        self.wkConfig = config
        self.view.addSubview(self.wkWebView)
        NSLayoutConstraint.activate([
            self.wkWebView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            self.wkWebView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.wkWebView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            self.wkWebView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: STBaseConstants.st_navHeight()),
        ])
        self.view.bringSubviewToFront(self.topBgView)
        if showProgressView {
            self.configProcessView()
        }
    }
    
    private func configProcessView() {
        self.view.addSubview(self.progressView)
        self.view.addConstraints([
            NSLayoutConstraint.init(item: self.progressView, attribute: .left, relatedBy: .equal, toItem: self.view, attribute: .left, multiplier: 1, constant: 0),
            NSLayoutConstraint.init(item: self.progressView, attribute: .right, relatedBy: .equal, toItem: self.view, attribute: .right, multiplier: 1, constant: 0),
            NSLayoutConstraint.init(item: self.progressView, attribute: .top, relatedBy: .equal, toItem: self.navBgView, attribute: .bottom, multiplier: 1, constant: 0),
        ])
        self.addProgressObserver()
    }
    
    private func updateNav() {
        self.st_showNavBtnType(type: .showLeftBtn)
        self.titleLabel.textAlignment = .center
    }
    
    private func addProgressObserver() {
        self.progressObserver = self.wkWebView.observe(\.estimatedProgress, options: .new) {[weak self] _, change in
            STLog("Progress: \(change.newValue ?? 0)")
            guard let strongSelf = self else { return }
            strongSelf.progressView.setProgress(Float(strongSelf.wkWebView.estimatedProgress), animated: true)
            if strongSelf.wkWebView.estimatedProgress >= 1.0 {
                UIView.animate(withDuration: 0.3, animations: {
                    strongSelf.progressView.alpha = 0
                }) { _ in
                    strongSelf.progressView.setProgress(0, animated: false)
                    strongSelf.progressView.alpha = 1
                }
            }
        }
    }
    
    open override func st_leftBarBtnClick() {
        if self.wkWebView.canGoBack {
            self.wkWebView.goBack()
        } else {
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    open lazy var wkWebView: WKWebView = {
        let webView = WKWebView(frame: .zero, configuration: self.wkConfig ?? WKWebViewConfiguration())
        webView.isOpaque = false
        webView.uiDelegate = self
        webView.navigationDelegate = self
        webView.backgroundColor = .clear
        webView.scrollView.contentInset = .zero
        webView.scrollView.backgroundColor = .clear
        webView.scrollView.scrollIndicatorInsets = .zero
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.translatesAutoresizingMaskIntoConstraints = false
        return webView
    }()

    open lazy var progressView: UIProgressView = {
        let view = UIProgressView(progressViewStyle: .bar)
        view.tintColor = .systemBlue
        view.trackTintColor = .clear
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
}

extension STBaseWKViewController: WKUIDelegate, WKNavigationDelegate, WKScriptMessageHandler {
    open func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        self.wkWebView.evaluateJavaScript("document.title") { result, error in
            if let text = result {
                self.titleLabel.text = String.st_returnStr(object: text)
            }
        }
    }
    
    open func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.wkWebView.evaluateJavaScript("document.title") { result, error in
            if let text = result {
                self.titleLabel.text = String.st_returnStr(object: text)
            }
        }
    }
    
    open func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        self.wkWebView.evaluateJavaScript("document.title") { result, error in
            if let text = result {
                self.titleLabel.text = String.st_returnStr(object: text)
            }
        }
    }
    
    open func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {}
}
