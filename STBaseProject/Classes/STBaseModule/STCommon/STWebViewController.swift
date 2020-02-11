//
//  STWebViewController.swift
//  STBaseFramework
//
//  Created by stack on 2019/1/28.
//  Copyright © 2019年 ST. All rights reserved.
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

    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {

    }
}
