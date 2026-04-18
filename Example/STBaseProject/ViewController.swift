//
//  ViewController.swift
//  STBaseProject_Example
//
//  Created by 寒江孤影 on 2022/8/4.
//  Copyright © 2022 STBaseProject. All rights reserved.
//

import UIKit
import STBaseProject

class ViewController: STBaseViewController {

    private var dataSouces: [String: UIViewController] = [:]
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var topConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.titleLabel.text = "导航目录"
        self.topConstraint.constant = STDeviceAdapter.navigationBarHeight
        self.configData()
    }

    private func configData() {
        let hudViewController = STHudViewController(nibName: "STHudViewController", bundle: nil)
        self.dataSouces["hud 测试"] = hudViewController
        
        let logViewController = STLogViewController()
        self.dataSouces["log 测试"] = logViewController
        
        self.tableView.reloadData()
    }
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dataSouces.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "ViewControllerCell")
        if (cell == nil) {
            cell = UITableViewCell.init(style: .default, reuseIdentifier: "ViewControllerCell")
            cell?.selectionStyle = .none
            cell?.backgroundColor = .clear
        }
        var config = UIListContentConfiguration.cell()
        let key = Array(self.dataSouces.keys)[indexPath.row]
        config.text = key
        cell?.contentConfiguration = config
        return cell ?? UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let key = Array(self.dataSouces.keys)[indexPath.row]
        guard let vc = self.dataSouces[key] else { return }
        self.navigationController?.pushViewController(vc, animated: true)
    }
}
