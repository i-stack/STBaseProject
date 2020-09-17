//
//  STBaseView.swift
//  STBaseProject
//
//  Created by stack on 2018/3/14.
//  Copyright © 2018 ST. All rights reserved.
//

import UIKit

open class STBaseView: UIView {
    
    public var tableView: UITableView?
    public var baseContentView: UIView?
    public var baseScrollView: UIScrollView?

    deinit {
        print("🌈 -> \(self) 🌈 ----> 🌈 dealloc")
    }
    
    public func st_baseViewAddScrollView() -> Void {
        self.st_baseViewAddScrollView(customScrollView: createScrollView())
    }
    
    public func st_baseViewAddScrollView(customScrollView: UIScrollView) -> Void {
        self.baseScrollView = customScrollView
        self.addSubview(self.baseScrollView ?? UIScrollView())
        self.baseContentView = createContentView()
        self.baseScrollView?.addSubview(self.baseContentView ?? UIView())
    }
    
    public func st_baseViewAddTableView(frame: CGRect, style: UITableView.Style) -> Void {
        self.tableView = self.createTableView(frame: frame, style: style)
        self.addSubview(self.tableView ?? UITableView())
    }
    
    private func createScrollView() -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.isPagingEnabled = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        return scrollView
    }
    
    private func createContentView() -> UIView {
        let view = UIView()
        return view
    }
    
    private func createTableView(frame: CGRect, style: UITableView.Style) -> UITableView {
        let tableView = UITableView.init(frame: frame, style: style)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        return tableView
    }
}

extension STBaseView: UITableViewDelegate, UITableViewDataSource {
    open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }
    
    open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return UITableViewCell()
    }
}

extension UIView {
    public func currentViewController() -> (UIViewController?) {
        var window = UIApplication.shared.keyWindow
        if window?.windowLevel != UIWindow.Level.normal {
            let windows = UIApplication.shared.windows
            for windowTemp in windows {
                if windowTemp.windowLevel == UIWindow.Level.normal {
                    window = windowTemp
                    break
                }
            }
        }
        let vc = window?.rootViewController
        return currentViewController(vc)
    }

    func currentViewController(_ vc :UIViewController?) -> UIViewController? {
        if vc == nil {
            return nil
        }
        if let presentVC = vc?.presentedViewController {
            return currentViewController(presentVC)
        } else if let tabVC = vc as? UITabBarController {
            if let selectVC = tabVC.selectedViewController {
                return currentViewController(selectVC)
            }
            return nil
        } else if let naiVC = vc as? UINavigationController {
            return currentViewController(naiVC.visibleViewController)
        } else {
            return vc
        }
    }
}
