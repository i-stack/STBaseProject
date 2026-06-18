//
//  STBottomSheetViewController.swift
//  STBaseProjectExample
//
//  Created by 寒江孤影 on 2026/6/16.
//

import STBaseProject
import UIKit

final class STBottomSheetTestViewController: STBottomSheetViewController {
    
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let rows: [String] = (1...50).map { "这是第 \($0) 行内容，可以上下滑动测试" }
    
    override func setupContent() {
        super.setupContent()
        
        self.setupHeader()
        self.setupTableView()
    }
    
    private func setupHeader() {
        let titleLabel = UILabel()
        titleLabel.text = "半屏/全屏自适应弹窗"
        titleLabel.font = .boldSystemFont(ofSize: 18)
        titleLabel.textAlignment = .center
        
        self.contentView.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -16),
            titleLabel.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
    
    private func setupTableView() {
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.rowHeight = 56
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        self.contentScrollView = self.tableView
        
        self.contentView.addSubview(self.tableView)
        self.tableView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            self.tableView.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 60),
            self.tableView.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor),
            self.tableView.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor),
            self.tableView.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor)
        ])
    }
}

extension STBottomSheetTestViewController: UITableViewDelegate, UITableViewDataSource {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.bottomSheetScrollViewDidScroll(scrollView)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.rows.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = self.rows[indexPath.row]
        return cell
    }
}
