//
//  STBaseView.swift
//  STBaseProject
//
//  Created by song on 2018/3/14.
//  Copyright © 2018 song. All rights reserved.
//

import UIKit

open class STBaseView: UIView {

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
    
    func createScrollView() -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.isPagingEnabled = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        return scrollView
    }
    
    func createContentView() -> UIView {
        let view = UIView()
        return view
    }
}
