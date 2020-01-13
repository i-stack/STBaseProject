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
    open var scrollViewTopConstraint: NSLayoutConstraint?
    open var contentViewBottomConstraint: NSLayoutConstraint?

    deinit {
        print("🌈 -> \(self) 🌈 ----> 🌈 dealloc")
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    public func baseViewAddScrollView() -> Void {
        self.baseViewAddScrollView(customScrollView: createScrollView())
    }
    
    public func baseViewAddScrollView(customScrollView: UIScrollView) -> Void {
        self.baseScrollView = customScrollView
        self.addSubview(self.baseScrollView ?? UIScrollView())
        self.scrollViewTopConstraint = NSLayoutConstraint.init(item: self.baseScrollView ?? UIScrollView(), attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 0)
        self.addConstraints([
            self.scrollViewTopConstraint!,
            NSLayoutConstraint.init(item: self.baseScrollView ?? UIScrollView(), attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1, constant: 0),
            NSLayoutConstraint.init(item: self.baseScrollView ?? UIScrollView(), attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1, constant: 0),
            NSLayoutConstraint.init(item: self.baseScrollView ?? UIScrollView(), attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1, constant: 0)
        ])
        
        self.baseContentView = createContentView()
        self.baseScrollView?.addSubview(self.baseContentView ?? UIView())
        self.contentViewBottomConstraint = NSLayoutConstraint.init(item: self.baseContentView ?? UIView(), attribute: .bottom, relatedBy: .equal, toItem: self.baseScrollView ?? UIScrollView(), attribute: .bottom, multiplier: 1, constant: 0)
        self.addConstraints([
            self.contentViewBottomConstraint!,
            NSLayoutConstraint.init(item: self.baseContentView ?? UIView(), attribute: .left, relatedBy: .equal, toItem: self.baseScrollView ?? UIScrollView(), attribute: .left, multiplier: 1, constant: 0),
            NSLayoutConstraint.init(item: self.baseContentView ?? UIView(), attribute: .right, relatedBy: .equal, toItem: self.baseScrollView ?? UIScrollView(), attribute: .right, multiplier: 1, constant: 0),
            NSLayoutConstraint.init(item: self.baseContentView ?? UIView(), attribute: .top, relatedBy: .equal, toItem: self.baseScrollView ?? UIScrollView(), attribute: .top, multiplier: 1, constant: 0),
            NSLayoutConstraint.init(item: self.baseContentView ?? UIView(), attribute: .width, relatedBy: .equal, toItem: self.baseContentView ?? UIView(), attribute: .width, multiplier: 1, constant: 0)
        ])
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
