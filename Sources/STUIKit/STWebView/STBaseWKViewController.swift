//
//  STBaseWKViewController.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2020/12/31.
//
import WebKit
import StoreKit

public struct STWebInfo {
    var url: String?
    var titleText: String?
    var htmlString: String?
    var bgColor: String?
    var userAgent: String?
    var allowsBackForwardNavigationGestures: Bool = true
    var allowsLinkPreview: Bool = false
    var isScrollEnabled: Bool = true
    var showProgressView: Bool = true
    var enableJavaScript: Bool = true
    var enableZoom: Bool = true
    
    public init(url: String? = nil, 
                titleText: String? = nil, 
                htmlString: String? = nil, 
                bgColor: String? = nil,
                userAgent: String? = nil,
                allowsBackForwardNavigationGestures: Bool = true,
                allowsLinkPreview: Bool = false,
                isScrollEnabled: Bool = true,
                showProgressView: Bool = true,
                enableJavaScript: Bool = true,
                enableZoom: Bool = true) {
        self.url = url
        self.bgColor = bgColor
        self.titleText = titleText
        self.htmlString = htmlString
        self.userAgent = userAgent
        self.allowsBackForwardNavigationGestures = allowsBackForwardNavigationGestures
        self.allowsLinkPreview = allowsLinkPreview
        self.isScrollEnabled = isScrollEnabled
        self.showProgressView = showProgressView
        self.enableJavaScript = enableJavaScript
        self.enableZoom = enableZoom
    }
}

// MARK: - WebView 配置选项
public struct STWebViewConfig {
    var allowsInlineMediaPlayback: Bool = true
    var mediaTypesRequiringUserActionForPlayback: WKAudiovisualMediaTypes = []
    var suppressesIncrementalRendering: Bool = false
    var allowsAirPlayForMediaPlayback: Bool = true
    var allowsPictureInPictureMediaPlayback: Bool = true
    var applicationNameForUserAgent: String?
    var customUserAgent: String?
    var websiteDataStore: WKWebsiteDataStore = .default()
    var processPool: WKProcessPool = WKProcessPool()
    var preferences: WKPreferences = WKPreferences()
    var userContentController: WKUserContentController = WKUserContentController()
    
    public init(allowsInlineMediaPlayback: Bool = true,
                mediaTypesRequiringUserActionForPlayback: WKAudiovisualMediaTypes = [],
                suppressesIncrementalRendering: Bool = false,
                allowsAirPlayForMediaPlayback: Bool = true,
                allowsPictureInPictureMediaPlayback: Bool = true,
                applicationNameForUserAgent: String? = nil,
                customUserAgent: String? = nil,
                websiteDataStore: WKWebsiteDataStore = .default(),
                processPool: WKProcessPool = WKProcessPool(),
                preferences: WKPreferences = WKPreferences(),
                userContentController: WKUserContentController = WKUserContentController()) {
        self.allowsInlineMediaPlayback = allowsInlineMediaPlayback
        self.mediaTypesRequiringUserActionForPlayback = mediaTypesRequiringUserActionForPlayback
        self.suppressesIncrementalRendering = suppressesIncrementalRendering
        self.allowsAirPlayForMediaPlayback = allowsAirPlayForMediaPlayback
        self.allowsPictureInPictureMediaPlayback = allowsPictureInPictureMediaPlayback
        self.applicationNameForUserAgent = applicationNameForUserAgent
        self.customUserAgent = customUserAgent
        self.websiteDataStore = websiteDataStore
        self.processPool = processPool
        self.preferences = preferences
        self.userContentController = userContentController
    }
}

// MARK: - WebView 加载状态
public enum STWebViewLoadState {
    case idle
    case loading
    case loaded
    case failed(Error)
}

// MARK: - WebView 消息处理协议
public protocol STWebViewMessageHandler: AnyObject {
    func webView(_ webView: WKWebView, didReceiveMessage message: WKScriptMessage)
}

open class STBaseWKViewController: STBaseViewController {
    
    open var webInfo: STWebInfo?
    open var webViewConfig: STWebViewConfig = STWebViewConfig()
    open var messageHandler: STWebViewMessageHandler?
    private var wkConfig: WKWebViewConfiguration?
    private var progressObserver: NSKeyValueObservation?
    private var loadState: STWebViewLoadState = .idle
    
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
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        self.st_setupWebView()
        self.st_setupUI()
        self.st_updateNavigationBar()
    }
    
    private func st_setupWebView() {
        self.st_createWebViewConfiguration()
        self.st_setupWebViewConstraints()
        self.st_configureWebView()
        if let webInfo = self.webInfo {
            self.st_loadWebContent(with: webInfo)
        }
    }
    
    private func st_createWebViewConfiguration() {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = self.webViewConfig.allowsInlineMediaPlayback
        config.mediaTypesRequiringUserActionForPlayback = self.webViewConfig.mediaTypesRequiringUserActionForPlayback
        config.suppressesIncrementalRendering = self.webViewConfig.suppressesIncrementalRendering
        config.allowsAirPlayForMediaPlayback = self.webViewConfig.allowsAirPlayForMediaPlayback
        config.allowsPictureInPictureMediaPlayback = self.webViewConfig.allowsPictureInPictureMediaPlayback
        
        if let customUserAgent = self.webViewConfig.customUserAgent {
            config.applicationNameForUserAgent = customUserAgent
        }
        // 数据存储
        config.websiteDataStore = self.webViewConfig.websiteDataStore
        config.processPool = self.webViewConfig.processPool
        
        // 偏好设置
        config.preferences = self.webViewConfig.preferences
        config.preferences.javaScriptEnabled = self.webInfo?.enableJavaScript ?? true
        
        // 用户内容控制器
        config.userContentController = self.webViewConfig.userContentController
        self.wkConfig = config
    }
    
    private func st_setupWebViewConstraints() {
        self.view.addSubview(self.wkWebView)
        NSLayoutConstraint.activate([
            self.wkWebView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            self.wkWebView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.wkWebView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            self.wkWebView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: STDeviceAdapter.navigationBarHeight),
        ])
    }
    
    private func st_configureWebView() {
        self.wkWebView.isOpaque = false
        self.wkWebView.uiDelegate = self
        self.wkWebView.navigationDelegate = self
        self.wkWebView.backgroundColor = .clear
        self.wkWebView.scrollView.contentInset = .zero
        self.wkWebView.scrollView.backgroundColor = .clear
        self.wkWebView.scrollView.scrollIndicatorInsets = .zero
        self.wkWebView.scrollView.contentInsetAdjustmentBehavior = .never
        
        // 手势配置
        self.wkWebView.allowsBackForwardNavigationGestures = self.webInfo?.allowsBackForwardNavigationGestures ?? true
        self.wkWebView.allowsLinkPreview = self.webInfo?.allowsLinkPreview ?? false
        
        // 滚动配置
        self.wkWebView.scrollView.isScrollEnabled = self.webInfo?.isScrollEnabled ?? true
        
        // 缩放配置
        if let enableZoom = self.webInfo?.enableZoom {
            self.wkWebView.scrollView.maximumZoomScale = enableZoom ? 3.0 : 1.0
            self.wkWebView.scrollView.minimumZoomScale = enableZoom ? 0.5 : 1.0
        }
        
        // 用户代理
        if let userAgent = self.webInfo?.userAgent {
            self.wkWebView.customUserAgent = userAgent
        }
    }
    
    private func st_setupUI() {
        // 添加加载指示器
        self.view.addSubview(self.loadingView)
        NSLayoutConstraint.activate([
            self.loadingView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            self.loadingView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor)
        ])
        
        // 添加错误视图
        self.view.addSubview(self.errorView)
        NSLayoutConstraint.activate([
            self.errorView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: STDeviceAdapter.navigationBarHeight),
            self.errorView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.errorView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            self.errorView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        ])
        
        // 配置进度条
        if self.webInfo?.showProgressView ?? true {
            self.st_setupProgressView()
        }
    }
    
    private func st_setupProgressView() {
        self.view.addSubview(self.progressView)
        self.view.addConstraints([
            NSLayoutConstraint.init(item: self.progressView, attribute: .left, relatedBy: .equal, toItem: self.view, attribute: .left, multiplier: 1, constant: 0),
            NSLayoutConstraint.init(item: self.progressView, attribute: .right, relatedBy: .equal, toItem: self.view, attribute: .right, multiplier: 1, constant: 0),
        ])
        self.st_addProgressObserver()
    }
    
    private func st_updateNavigationBar() {
        self.titleLabel.textAlignment = .center
        if let titleText = self.webInfo?.titleText {
            self.st_setTitle(titleText)
        }
    }
    
    open func st_loadWebInfo() {
        guard let webInfo = self.webInfo else { return }
        self.st_loadWebContent(with: webInfo)
    }
    
    private func st_loadWebContent(with webInfo: STWebInfo) {
        self.st_updateLoadState(.loading)
        
        if let html = webInfo.htmlString, !html.isEmpty {
            self.st_loadHTMLString(html)
        } else if let urlString = webInfo.url, !urlString.isEmpty {
            self.st_loadURL(urlString)
        }
    }
    
    private func st_loadHTMLString(_ html: String) {
        var modifiedHTML = html
        if let bgColor = self.webInfo?.bgColor {
            modifiedHTML = "<html><head><style>body { background-color: \(bgColor); margin: 0; padding: 0; }</style></head><body>\(html)</body></html>"
        }
        self.wkWebView.loadHTMLString(modifiedHTML, baseURL: nil)
    }
    
    private func st_loadURL(_ urlString: String) {
        guard let url = URL(string: urlString) else {
            self.st_handleLoadError(NSError(domain: "STWebView", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]))
            return
        }
        let request = URLRequest(url: url)
        self.wkWebView.load(request)
    }
    
    open func st_evaluateJavaScript(_ script: String, completion: ((Any?, Error?) -> Void)? = nil) {
        self.wkWebView.evaluateJavaScript(script, completionHandler: completion)
    }
    
    open func st_addScriptMessageHandler(name: String) {
        self.wkWebView.configuration.userContentController.add(self, name: name)
    }
    
    open func st_removeScriptMessageHandler(name: String) {
        self.wkWebView.configuration.userContentController.removeScriptMessageHandler(forName: name)
    }
    
    open func st_goBack() {
        if self.wkWebView.canGoBack {
            self.wkWebView.goBack()
        }
    }
    
    open func st_goForward() {
        if self.wkWebView.canGoForward {
            self.wkWebView.goForward()
        }
    }
    
    open func st_reload() {
        self.wkWebView.reload()
    }
    
    open func st_stopLoading() {
        self.wkWebView.stopLoading()
    }
    
    private func st_addProgressObserver() {
        self.progressObserver = self.wkWebView.observe(\.estimatedProgress, options: .new) { [weak self] _, change in
            guard let self = self else { return }
            let progress = change.newValue ?? 0
            self.progressView.setProgress(Float(progress), animated: true)
            if progress >= 1.0 {
                UIView.animate(withDuration: 0.3, animations: {
                    self.progressView.alpha = 0
                }) { _ in
                    self.progressView.setProgress(0, animated: false)
                    self.progressView.alpha = 1
                }
            }
        }
    }
    
    private func st_updateLoadState(_ state: STWebViewLoadState) {
        self.loadState = state
        DispatchQueue.main.async {
            switch state {
            case .idle:
                self.loadingView.stopAnimating()
                self.errorView.isHidden = true
                self.wkWebView.isHidden = false
                
            case .loading:
                self.loadingView.startAnimating()
                self.errorView.isHidden = true
                self.wkWebView.isHidden = false
                
            case .loaded:
                self.loadingView.stopAnimating()
                self.errorView.isHidden = true
                self.wkWebView.isHidden = false
                
            case .failed:
                self.loadingView.stopAnimating()
                self.errorView.isHidden = false
                self.wkWebView.isHidden = true
            }
        }
    }
    
    private func st_handleLoadError(_ error: Error) {
        self.st_updateLoadState(.failed(error))
    }
    
    @objc private func st_retryButtonTapped() {
        self.st_loadWebInfo()
    }
    
    open func st_leftBarBtnClick() {
        if self.wkWebView.canGoBack {
            self.wkWebView.goBack()
        } else {
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    open lazy var wkWebView: WKWebView = {
        let webView = WKWebView(frame: .zero, configuration: self.wkConfig ?? WKWebViewConfiguration())
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
    
    open lazy var loadingView: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .systemBlue
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    open lazy var errorView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.isHidden = true
        view.translatesAutoresizingMaskIntoConstraints = false
        
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "wifi.slash")
        imageView.tintColor = .systemGray
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageView)
        
        let titleLabel = UILabel()
        titleLabel.text = "加载失败"
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        titleLabel.textColor = .label
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)
        
        let messageLabel = UILabel()
        messageLabel.text = "网络连接异常，请检查网络后重试"
        messageLabel.font = UIFont.systemFont(ofSize: 14)
        messageLabel.textColor = .secondaryLabel
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(messageLabel)
        
        let retryButton = UIButton(type: .system)
        retryButton.setTitle("重新加载", for: .normal)
        retryButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        retryButton.addTarget(self, action: #selector(st_retryButtonTapped), for: .touchUpInside)
        retryButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(retryButton)
        
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.topAnchor.constraint(equalTo: view.topAnchor, constant: 100),
            imageView.widthAnchor.constraint(equalToConstant: 60),
            imageView.heightAnchor.constraint(equalToConstant: 60),
            
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            messageLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            messageLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            messageLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            retryButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            retryButton.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 30),
            retryButton.widthAnchor.constraint(equalToConstant: 120),
            retryButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        return view
    }()
}

extension STBaseWKViewController: WKUIDelegate, WKNavigationDelegate, WKScriptMessageHandler {
    open func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        self.st_updateLoadState(.loading)
    }
    
    open func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        self.st_updateLoadState(.loading)
        self.st_updateTitle()
    }
    
    open func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.st_updateLoadState(.loaded)
        self.st_updateTitle()
    }
    
    open func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        self.st_handleLoadError(error)
        self.st_updateTitle()
    }
    
    open func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        self.st_handleLoadError(error)
    }
    
    open func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil {
            webView.load(navigationAction.request)
        }
        return nil
    }
    
    open func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let alert = UIAlertController(title: "提示", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default) { _ in
            completionHandler()
        })
        self.present(alert, animated: true)
    }
    
    open func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let alert = UIAlertController(title: "确认", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel) { _ in
            completionHandler(false)
        })
        alert.addAction(UIAlertAction(title: "确定", style: .default) { _ in
            completionHandler(true)
        })
        self.present(alert, animated: true)
    }
    
    open func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
        let alert = UIAlertController(title: "输入", message: prompt, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.text = defaultText
        }
        alert.addAction(UIAlertAction(title: "取消", style: .cancel) { _ in
            completionHandler(nil)
        })
        alert.addAction(UIAlertAction(title: "确定", style: .default) { _ in
            completionHandler(alert.textFields?.first?.text)
        })
        self.present(alert, animated: true)
    }
    
    open func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        self.messageHandler?.webView(self.wkWebView, didReceiveMessage: message)
        self.st_handleScriptMessage(message)
    }
    
    private func st_updateTitle() {
        self.wkWebView.evaluateJavaScript("document.title") { [weak self] result, error in
            guard let self = self else { return }
            if let text = result as? String, !text.isEmpty {
                self.st_setTitle(text)
            }
        }
    }
    
    private func st_handleScriptMessage(_ message: WKScriptMessage) {
        
    }
}
