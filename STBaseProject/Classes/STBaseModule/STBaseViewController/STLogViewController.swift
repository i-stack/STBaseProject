//
//  STLogViewController.swift
//  STBaseProject
//
//  Created by stack on 2017/10/4.
//  Copyright © 2017年 ST. All rights reserved.
//

import UIKit

public class STLogViewController: UIViewController {
    
    private var dataSources: [String] = [String]()

    private var logText: String = "🌈 -> <STBaseProject_Example.ViewController: 0x11d80c0c0> 🌈 ----> 🌈 dealloc\n🌈 -> <STBaseProject_Example.ViewController: 0x11d80c0c0> 🌈 ----> 🌈 dealloc\n🌈 -> <STBaseProject_Example.ViewController: 0x11d80c0c0> 🌈 ----> 🌈 dealloc\n🌈 -> <STBaseProject_Example.ViewController: 0x11d80c0c0> 🌈 ----> 🌈 dealloc\n🌈 -> <STBaseProject_Example.ViewController: 0x11d80c0c0> 🌈 ----> 🌈 dealloc\n🌈 -> <STBaseProject_Example.ViewController: 0x11d80c0c0> 🌈 ----> 🌈 dealloc\n🌈 -> <STBaseProject_Example.ViewController: 0x11d80c0c0> 🌈 ----> 🌈 dealloc\n🌈 -> <STBaseProject_Example.ViewController: 0x11d80c0c0> 🌈 ----> 🌈 dealloc\n🌈 -> <STBaseProject_Example.ViewController: 0x11d80c0c0> 🌈 ----> 🌈 dealloc\n🌈 -> <STBaseProject_Example.ViewController: 0x11d80c0c0> 🌈 ----> 🌈 dealloc\n🌈 -> <STBaseProject_Example.ViewController: 0x11d80c0c0> 🌈 ----> 🌈 dealloc\n🌈 -> <STBaseProject_Example.ViewController: 0x11d80c0c0> 🌈 ----> 🌈 dealloc\n🌈 -> <STBaseProject_Example.ViewController: 0x11d80c0c0> 🌈 ----> 🌈 dealloc\n🌈 -> <STBaseProject_Example.ViewController: 0x11d80c0c0> 🌈 ----> 🌈 dealloc\n🌈 -> <STBaseProject_Example.ViewController: 0x11d80c0c0> 🌈 ----> 🌈 dealloc\n🌈 -> <STBaseProject_Example.ViewController: 0x11d80c0c0> 🌈 ----> 🌈 dealloc\n🌈 -> <STBaseProject_Example.ViewController: 0x11d80c0c0> 🌈 ----> 🌈 dealloc\n🌈 -> <STBaseProject_Example.ViewController: 0x11d80c0c0> 🌈 ----> 🌈 dealloc\n🌈 -> <STBaseProject_Example.ViewController: 0x11d80c0c0> 🌈 ----> 🌈 dealloc\n🌈 -> <STBaseProject_Example.ViewController: 0x11d80c0c0> 🌈 ----> 🌈 dealloc\n🌈 -> <STBaseProject_Example.ViewController: 0x11d80c0c0> 🌈 ----> 🌈 dealloc\n🌈 -> <STBaseProject_Example.ViewController: 0x11d80c0c0> 🌈 ----> 🌈 dealloc\n🌈 -> <STBaseProject_Example.ViewController: 0x11d80c0c0> 🌈 ----> 🌈 dealloc\n🌈 -> <STBaseProject_Example.ViewController: 0x11d80c0c0> 🌈 ----> 🌈 dealloc\n🌈 -> <STBaseProject_Example.ViewController: 0x11d80c0c0> 🌈 ----> 🌈 dealloc\n🌈 -> <STBaseProject_Example.ViewController: 0x11d80c0c0> 🌈 ----> 🌈 dealloc\n🌈 -> <STBaseProject_Example.ViewController: 0x11d80c0c0> 🌈 ----> 🌈 dealloc\n🌈 -> <STBaseProject_Example.ViewController: 0x11d80c0c0> 🌈 ----> 🌈 dealloc\n🌈 -> <STBaseProject_Example.ViewController: 0x11d80c0c0> 🌈 ----> 🌈 dealloc\n🌈 -> <STBaseProject_Example.ViewController: 0x11d80c0c0> 🌈 ----> 🌈 dealloc\n🌈 -> <STBaseProject_Example.ViewController: 0x11d80c0c0> 🌈 ----> 🌈 dealloc\n🌈 -> <STBaseProject_Example.ViewController: 0x11d80c0c0> 🌈 ----> 🌈 dealloc\n🌈 -> <STBaseProject_Example.ViewController: 0x11d80c0c0> 🌈 ----> 🌈 dealloc\n"
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        self.dataSources.append(self.logText)
        self.configUI()
        self.st_baseConfig()
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
        self.view.addSubview(self.tableView)
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
            NSLayoutConstraint.init(item: self.tableView, attribute: .top, relatedBy: .equal, toItem: self.view, attribute: .top, multiplier: 1, constant: STConstants.st_navHeight()),
            NSLayoutConstraint.init(item: self.tableView, attribute: .left, relatedBy: .equal, toItem: self.view, attribute: .left, multiplier: 1, constant: 0),
            NSLayoutConstraint.init(item: self.tableView, attribute: .bottom, relatedBy: .equal, toItem: self.cleanLogBtn, attribute: .top, multiplier: 1, constant: 0),
            NSLayoutConstraint.init(item: self.tableView, attribute: .right, relatedBy: .equal, toItem: self.view, attribute: .right, multiplier: 1, constant: 0)
        ])
    }

    public func update(log: String) {
        self.dataSources.append(log)
        self.tableView.reloadData()
        self.tableView.scrollToRow(at: IndexPath.init(row: self.dataSources.count - 1, section: 0), at: .bottom, animated: true)
    }
    
    @objc private func backBtnClick() {
        if self.navigationController != nil {
            self.navigationController?.popViewController(animated: true)
        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    @objc private func cleanLogBtnClick() {
        self.dataSources.removeAll()
        self.tableView.reloadData()
    }
    
    private lazy var tableView: UITableView = {
        let view = UITableView.init(frame: .zero, style: .plain)
        view.delegate = self
        view.dataSource = self
        view.separatorStyle = .none
        view.tableFooterView = UIView()
        view.backgroundColor = UIColor.black
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
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

extension STLogViewController: UITableViewDelegate, UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dataSources.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "STLogViewController")
        if cell == nil {
            cell = UITableViewCell.init(style: .default, reuseIdentifier: "STLogViewController")
            cell?.selectionStyle = .none
            cell?.backgroundColor = UIColor.black
            cell?.textLabel?.numberOfLines = 0
            cell?.textLabel?.textColor = UIColor.green
        }
        
        let text = self.dataSources[indexPath.row]
        cell?.textLabel?.text = text
        return cell ?? UITableViewCell()
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}
