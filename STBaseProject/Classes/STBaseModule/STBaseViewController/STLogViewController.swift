//
//  STLogViewController.swift
//  STBaseProject
//
//  Created by stack on 2017/10/4.
//  Copyright © 2017年 ST. All rights reserved.
//

import UIKit

public class STLogViewController: UIViewController {
    
    private var scrollToBottom: Bool = false
    private var lastContentOffsetY: CGFloat = 0
    
    private var logText: String = "🌈 -> <STBaseProject_Example.ViewController: 0x11d80c0c0> 🌈 ----> 🌈 dealloc\n🌈 -> <STBaseProject_Example.ViewController: 0x11d80c0c0> 🌈 ----> 🌈 dealloc\n🌈 -> <STBaseProject_Example.ViewController: 0x11d80c0c0> 🌈 ----> 🌈 dealloc\n🌈 -> <STBaseProject_Example.ViewController: 0x11d80c0c0> 🌈 ----> 🌈 dealloc\n🌈 -> <STBaseProject_Example.ViewController: 0x11d80c0c0> 🌈 ----> 🌈 dealloc\n🌈 -> <STBaseProject_Example.ViewController: 0x11d80c0c0> 🌈 ----> 🌈 dealloc\n🌈 -> <STBaseProject_Example.ViewController: 0x11d80c0c0> 🌈 ----> 🌈 dealloc\n🌈 -> <STBaseProject_Example.ViewController: 0x11d80c0c0> 🌈 ----> 🌈 dealloc\n🌈 -> <STBaseProject_Example.ViewController: 0x11d80c0c0> 🌈 ----> 🌈 dealloc\n🌈 -> <STBaseProject_Example.ViewController: 0x11d80c0c0> 🌈 ----> 🌈 dealloc\n🌈 -> <STBaseProject_Example.ViewController: 0x11d80c0c0> 🌈 ----> 🌈 dealloc\n🌈 -> <STBaseProject_Example.ViewController: 0x11d80c0c0> 🌈 ----> 🌈 dealloc\n🌈 -> <STBaseProject_Example.ViewController: 0x11d80c0c0> 🌈 ----> 🌈 dealloc\n🌈 -> <STBaseProject_Example.ViewController: 0x11d80c0c0> 🌈 ----> 🌈 dealloc\n🌈 -> <STBaseProject_Example.ViewController: 0x11d80c0c0> 🌈 ----> 🌈 dealloc\n🌈 -> <STBaseProject_Example.ViewController: 0x11d80c0c0> 🌈 ----> 🌈 dealloc\n🌈 -> <STBaseProject_Example.ViewController: 0x11d80c0c0> 🌈 ----> 🌈 dealloc\n🌈 -> <STBaseProject_Example.ViewController: 0x11d80c0c0> 🌈 ----> 🌈 dealloc\n🌈 -> <STBaseProject_Example.ViewController: 0x11d80c0c0> 🌈 ----> 🌈 dealloc\n🌈 -> <STBaseProject_Example.ViewController: 0x11d80c0c0> 🌈 ----> 🌈 dealloc\n🌈 -> <STBaseProject_Example.ViewController: 0x11d80c0c0> 🌈 ----> 🌈 dealloc\n🌈 -> <STBaseProject_Example.ViewController: 0x11d80c0c0> 🌈 ----> 🌈 dealloc\n🌈 -> <STBaseProject_Example.ViewController: 0x11d80c0c0> 🌈 ----> 🌈 dealloc\n🌈 -> <STBaseProject_Example.ViewController: 0x11d80c0c0> 🌈 ----> 🌈 dealloc\n🌈 -> <STBaseProject_Example.ViewController: 0x11d80c0c0> 🌈 ----> 🌈 dealloc\n🌈 -> <STBaseProject_Example.ViewController: 0x11d80c0c0> 🌈 ----> 🌈 dealloc\n🌈 -> <STBaseProject_Example.ViewController: 0x11d80c0c0> 🌈 ----> 🌈 dealloc\n🌈 -> <STBaseProject_Example.ViewController: 0x11d80c0c0> 🌈 ----> 🌈 dealloc\n🌈 -> <STBaseProject_Example.ViewController: 0x11d80c0c0> 🌈 ----> 🌈 dealloc\n🌈 -> <STBaseProject_Example.ViewController: 0x11d80c0c0> 🌈 ----> 🌈 dealloc\n🌈 -> <STBaseProject_Example.ViewController: 0x11d80c0c0> 🌈 ----> 🌈 dealloc\n🌈 -> <STBaseProject_Example.ViewController: 0x11d80c0c0> 🌈 ----> 🌈 dealloc\n🌈 -> <STBaseProject_Example.ViewController: 0x11d80c0c0> 🌈 ----> 🌈 dealloc\n"
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        self.configUI()
        self.st_baseConfig()
        self.textView.text = self.logText
    }
    
    private func st_baseConfig() -> Void {
        self.hidesBottomBarWhenPushed = true
        self.view.backgroundColor = UIColor.black
        self.automaticallyAdjustsScrollViewInsets = false
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    private func configUI() {
        self.view.addSubview(self.centerView)
        self.view.addSubview(self.backBtn)
        self.view.addSubview(self.cleanLogBtn)
        self.view.addSubview(self.textView)
        self.view.addConstraints([
            NSLayoutConstraint.init(item: self.centerView, attribute: .top, relatedBy: .equal, toItem: self.view, attribute: .top, multiplier: 1, constant: 0),
            NSLayoutConstraint.init(item: self.centerView, attribute: .bottom, relatedBy: .equal, toItem: self.view, attribute: .bottom, multiplier: 1, constant: 0),
            NSLayoutConstraint.init(item: self.centerView, attribute: .centerX, relatedBy: .equal, toItem: self.view, attribute: .centerX, multiplier: 1, constant: 0),
            NSLayoutConstraint.init(item: self.centerView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 1)
        ])
        self.view.addConstraints([
            NSLayoutConstraint.init(item: self.backBtn, attribute: .left, relatedBy: .equal, toItem: self.view, attribute: .left, multiplier: 1, constant: 0),
            NSLayoutConstraint.init(item: self.backBtn, attribute: .bottom, relatedBy: .equal, toItem: self.view, attribute: .bottom, multiplier: 1, constant: 0),
            NSLayoutConstraint.init(item: self.backBtn, attribute: .right, relatedBy: .equal, toItem: self.centerView, attribute: .left, multiplier: 1, constant: 0),
            NSLayoutConstraint.init(item: self.backBtn, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 80)
        ])
        self.view.addConstraints([
            NSLayoutConstraint.init(item: self.cleanLogBtn, attribute: .left, relatedBy: .equal, toItem: self.centerView, attribute: .right, multiplier: 1, constant: 0),
            NSLayoutConstraint.init(item: self.cleanLogBtn, attribute: .bottom, relatedBy: .equal, toItem: self.view, attribute: .bottom, multiplier: 1, constant: 0),
            NSLayoutConstraint.init(item: self.cleanLogBtn, attribute: .right, relatedBy: .equal, toItem: self.view, attribute: .right, multiplier: 1, constant: 0),
            NSLayoutConstraint.init(item: self.cleanLogBtn, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 80)
        ])
        self.view.addConstraints([
            NSLayoutConstraint.init(item: self.textView, attribute: .top, relatedBy: .equal, toItem: self.view, attribute: .top, multiplier: 1, constant: STConstants.st_navHeight()),
            NSLayoutConstraint.init(item: self.textView, attribute: .left, relatedBy: .equal, toItem: self.view, attribute: .left, multiplier: 1, constant: 0),
            NSLayoutConstraint.init(item: self.textView, attribute: .bottom, relatedBy: .equal, toItem: self.cleanLogBtn, attribute: .top, multiplier: 1, constant: 0),
            NSLayoutConstraint.init(item: self.textView, attribute: .right, relatedBy: .equal, toItem: self.view, attribute: .right, multiplier: 1, constant: 0)
        ])
    }

    public func update(log: String) {
        self.textView.text.append(contentsOf: "\n\(log)")
        let height = self.textView.bounds.size.height
        let contentOffSetY = self.textView.contentOffset.y
        let contentSizeHeight = self.textView.contentSize.height
        let distanceFromBottom = contentSizeHeight - contentOffSetY
        if self.lastContentOffsetY == 0 {
            self.textView.scrollRangeToVisible(NSRange.init(location: self.textView.text.count, length: 1))
        } else {
            if distanceFromBottom < height {
                self.scrollToBottom = true
                if self.lastContentOffsetY < contentOffSetY {
                    self.textView.scrollRangeToVisible(NSRange.init(location: self.textView.text.count, length: 1))
                }
            } else {
                self.scrollToBottom = false
            }
        }
    }
    
    @objc private func backBtnClick() {
        if self.navigationController != nil {
            self.navigationController?.popViewController(animated: true)
        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    @objc private func cleanLogBtnClick() {
        self.logText = ""
        self.textView.text = self.logText
    }
    
    private lazy var textView: UITextView = {
        let textView = UITextView()
        textView.isEditable = false
        textView.delegate = self
        textView.textColor = UIColor.green
        textView.backgroundColor = UIColor.black
        textView.layoutManager.allowsNonContiguousLayout = false
        textView.translatesAutoresizingMaskIntoConstraints = false
        return textView
    }()
    
    private lazy var backBtn: UIButton = {
        let btn = UIButton()
        btn.setTitle("Back", for: .normal)
        btn.setTitleColor(UIColor.orange, for: .normal)
        btn.contentHorizontalAlignment = .center
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(backBtnClick), for: .touchUpInside)
        return btn
    }()
    
    private lazy var cleanLogBtn: UIButton = {
        let btn = UIButton()
        btn.setTitle("Clean Log", for: .normal)
        btn.setTitleColor(UIColor.orange, for: .normal)
        btn.contentHorizontalAlignment = .center
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(cleanLogBtnClick), for: .touchUpInside)
        return btn
    }()
    
    private lazy var centerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.clear
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
}

extension STLogViewController: UITextViewDelegate {
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.lastContentOffsetY = scrollView.contentOffset.y
    }
    
//    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
//        let height = self.textView.bounds.size.height
//        let contentOffsetY = scrollView.contentOffset.y
//        let contentSizeHeight = scrollView.contentSize.height
//        let distanceFromBottom = contentSizeHeight - contentOffsetY
//        if distanceFromBottom < height {
//            print("end of table")
//            self.scrollToBottom = true
//        } else {
//            print("not end of table")
//            self.scrollToBottom = false
//        }
//    }
}
