//
//  STWebViewController.swift
//  TronLink
//
//  Created by SQLing on 2019/1/28.
//  Copyright © 2019年 Tron. All rights reserved.
//

import UIKit
import WebKit
import JavaScriptCore

class STWebViewController: STBaseViewController {
    
    var url: URL?
    var titleText: String?
    var htmlString: String?
    var showProgress: Bool = true
    var progress: UIProgressView?
    var finishLoad: Bool = false

    var jsContext: JSContext?
    var orientationSupport: String?
    
    @objc init(url: String?, htmlString: String?, title: String?, showProgress: Bool) {
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configUI()
    }
    
    override func st_rightBarBtnClick() {
        
    }
    
    func configUI() -> Void {
//        if webType == .helpCenterType {
//            self.st_showNavBtnType(type:.showBothBtn)
//            self.titleLabel.text = self.titleText
//            self.rightBtn.setImage(UIImage.init(named: "kefu"), for: UIControl.State.normal)
//        } else {
//            self.st_showNavBtnType(type: .showBothBtn)
//            self.titleLabel.text = self.titleText
//            self.titleLabel.textAlignment = .left
//        }
//
//        self.webView = UIWebView.init(frame: CGRect.init(x: 0, y: TRX_NavHeight, width: TRX_APPW, height: TRX_APPH - TRX_NavHeight))
//        self.webView.delegate = self
//        self.webView.scrollView.showsVerticalScrollIndicator = false
//        if #available(iOS 11.0, *) {
//            self.webView.scrollView.contentInsetAdjustmentBehavior = UIScrollView.ContentInsetAdjustmentBehavior.never
//            if TRXDeviceInfo.hasSafeEdge() {
//                self.webView.frame = CGRect.init(x: 0, y: 88, width: TRX_APPW, height: TRX_APPH - 88 - (UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? 0))
//            }
//        } else {
//            self.automaticallyAdjustsScrollViewInsets = false
//        }
//
//        self.view.addSubview(self.webView)
//        self.view.backgroundColor = UIColor.white
//        self.webView.backgroundColor = UIColor.white
//
//        if self.url != nil {
//            let urlRequest = URLRequest(url: self.url!, cachePolicy: .reloadIgnoringCacheData, timeoutInterval: 20)
//            self.webView.loadRequest(urlRequest)
//        } else if self.htmlString != nil {
//            self.webView.loadHTMLString(self.htmlString!, baseURL: nil)
//        }
//
//        if self.showProgress {
//            self.progress = UIProgressView.init(frame: CGRect(x: 0, y: self.webView.frame.origin.y, width: TRX_APPW, height: 2))
//            self.progress?.tintColor = UIColor.theme()
//            self.progress?.trackTintColor = UIColor.white
//            self.view.addSubview(self.progress ?? UIView())
//
//            self.progressTimer = Timer.init(timeInterval: 0.1667, repeats: true, block: { [weak self] (timer) in
//                guard let strongSelf = self else { return }
//                if let newProgress = strongSelf.progress {
//                    if strongSelf.finishLoad {
//                        strongSelf.st_removeProgressTimer()
//                    } else {
//                        newProgress.progress = newProgress.progress + 0.025
//                        if newProgress.progress >= 0.95 {
//                            newProgress.progress = 0.95
//                        }
//                    }
//                }
//            })
//            RunLoop.current.add(progressTimer!, forMode: .common)
//        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
//        if self.webView != nil {
//            if self.webView.delegate != nil {
//                self.webView.delegate = nil
//            }
//
//            if self.webView.scrollView.delegate != nil {
//                self.webView.scrollView.delegate = nil
//            }
//
//            if self.webView.isLoading {
//                self.webView.stopLoading()
//            }
//        }
//        self.st_removeJSTimer()
//        self.st_removeProgressTimer()
        NotificationCenter.default.removeObserver(self)
    }
}
