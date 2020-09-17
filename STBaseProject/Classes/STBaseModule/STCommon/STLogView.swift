//
//  STLogView.swift
//  STBaseProject
//
//  Created by stack on 2018/3/14.
//  Copyright © 2018 ST. All rights reserved.
//

import UIKit

public class STLogView: UIView {
    
    private var queryLogTimer: Timer?
    private var tableViewInBottom: Bool = false
    private var dataSources: [String] = [String]()
    private var documentController: UIDocumentInteractionController?

    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.configUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    private func configUI() {
//        self.addSubview(self.centerView)
        self.addSubview(self.backBtn)
        self.addSubview(self.cleanLogBtn)
        self.addSubview(self.outputLogBtn)
        self.addSubview(self.tableView)
        self.addConstraints([
            NSLayoutConstraint.init(item: self.outputLogBtn, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1, constant: 0),
            NSLayoutConstraint.init(item: self.outputLogBtn, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1, constant: 0),
            NSLayoutConstraint.init(item: self.outputLogBtn, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 100),
            NSLayoutConstraint.init(item: self.outputLogBtn, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 80)
        ])
//        self.addConstraints([
//            NSLayoutConstraint.init(item: self.centerView, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 0),
//            NSLayoutConstraint.init(item: self.centerView, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1, constant: 0),
//            NSLayoutConstraint.init(item: self.centerView, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1, constant: 0),
//            NSLayoutConstraint.init(item: self.centerView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 1)
//        ])
        self.addConstraints([
            NSLayoutConstraint.init(item: self.backBtn, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1, constant: 0),
            NSLayoutConstraint.init(item: self.backBtn, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1, constant: 0),
            NSLayoutConstraint.init(item: self.backBtn, attribute: .right, relatedBy: .equal, toItem: self.outputLogBtn, attribute: .left, multiplier: 1, constant: 0),
            NSLayoutConstraint.init(item: self.backBtn, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 80)
        ])
        self.addConstraints([
            NSLayoutConstraint.init(item: self.cleanLogBtn, attribute: .left, relatedBy: .equal, toItem: self.outputLogBtn, attribute: .right, multiplier: 1, constant: 0),
            NSLayoutConstraint.init(item: self.cleanLogBtn, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1, constant: 0),
            NSLayoutConstraint.init(item: self.cleanLogBtn, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1, constant: 0),
            NSLayoutConstraint.init(item: self.cleanLogBtn, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 80)
        ])
        self.addConstraints([
            NSLayoutConstraint.init(item: self.tableView, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 0),
            NSLayoutConstraint.init(item: self.tableView, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1, constant: 0),
            NSLayoutConstraint.init(item: self.tableView, attribute: .bottom, relatedBy: .equal, toItem: self.cleanLogBtn, attribute: .top, multiplier: 1, constant: 0),
            NSLayoutConstraint.init(item: self.tableView, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1, constant: 0)
        ])
    }
    
    func beginQueryLog() {
        self.stopQueryLog()
        self.queryLogTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true, block: {[weak self] (timer) in
            guard let strongSelf = self else { return }
            let content = STFileManager.readFromFile(filePath: "\(STFileManager.getLibraryCachePath())/outputLog/log.text")
            if content.count > 0 {
                if !strongSelf.dataSources.contains(content) {
                    strongSelf.dataSources.removeAll()
                    strongSelf.dataSources.append(content)
                    strongSelf.tableView.reloadData()
                }
            }
        })
    }
    
    func stopQueryLog() {
        if self.queryLogTimer?.isValid ?? false {
            self.queryLogTimer?.invalidate()
            self.queryLogTimer = nil
        }
    }

    public func update(log: String) {
        self.dataSources.append(log)
        self.tableView.reloadData()
        if self.tableViewInBottom {
            self.tableView.scrollToRow(at: IndexPath.init(row: self.dataSources.count - 1, section: 0), at: .bottom, animated: true)
        }
    }
        
    @objc private func backBtnClick() {
        self.stopQueryLog()
        self.removeFromSuperview()
    }
        
    @objc private func cleanLogBtnClick() {
        STFileManager.removeItem(atPath: "\(STFileManager.getLibraryCachePath())/outputLog/log.text")
        self.dataSources.removeAll()
        self.tableView.reloadData()
    }
    
    @objc private func outputLogBtnClick(sender: UIButton) {
        let path = "\(STFileManager.getLibraryCachePath())/outputLog/log.text"
        if let pathURL = URL.init(string: path) {
            documentController = UIDocumentInteractionController(url: pathURL)
            documentController?.delegate = self
            let result = documentController?.presentOpenInMenu(from: CGRect.init(x: 0, y: 0, width: self.bounds.size.width, height: 200), in: self, animated: true) ?? false
            if !result {
                print("打开失败")
            }
        }
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
    
    private lazy var outputLogBtn: UIButton = {
        let btn = UIButton()
        btn.setTitle("Output Log", for: .normal)
        btn.setTitleColor(UIColor.orange, for: .normal)
        btn.contentHorizontalAlignment = .center
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(outputLogBtnClick(sender:)), for: .touchUpInside)
        return btn
    }()
    
    private lazy var centerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.clear
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
}

extension STLogView: UITableViewDelegate, UITableViewDataSource {
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
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let height = scrollView.frame.size.height
        let contentOffsetY = scrollView.contentOffset.y
        let bottomOffset = scrollView.contentSize.height - contentOffsetY
        if bottomOffset <= height {
            self.tableViewInBottom = true
        } else {
            self.tableViewInBottom = false
        }
    }
}

extension STLogView: UIDocumentInteractionControllerDelegate {
    public func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
        return self.currentViewController() ?? UIViewController()
    }
    
    public func documentInteractionControllerViewForPreview(_ controller: UIDocumentInteractionController) -> UIView? {
        return self
    }
    
    public func documentInteractionControllerRectForPreview(_ controller: UIDocumentInteractionController) -> CGRect {
        return self.bounds
    }
}
