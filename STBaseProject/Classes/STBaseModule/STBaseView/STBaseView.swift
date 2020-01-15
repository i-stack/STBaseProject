//
//  STBaseView.swift
//  STBaseProject
//
//  Created by song on 2018/3/14.
//  Copyright © 2018 song. All rights reserved.
//

import UIKit

public protocol STBaseViewDelegate: NSObjectProtocol {
    func st_numberOfSections() -> Int
    func st_numberOfRowsIn(section: Int) -> Int
    func st_didSelectRowAt(section: Int, row: Int)
}

open class STBaseView: UIView {

    open weak var delegate: STBaseViewDelegate?
    
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
    
    func createTableView(frame: CGRect, style: UITableView.Style) -> UITableView {
        let tableView = UITableView.init(frame: frame, style: style)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        return tableView
    }
}

extension STBaseView: UITableViewDelegate, UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let newDelegate = self.delegate {
            return newDelegate.st_numberOfRowsIn(section: section)
        }
        return 0
    }
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        if let newDelegate = self.delegate {
            return newDelegate.st_numberOfSections()
        }
        return 0
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return UITableViewCell()
    }
}
