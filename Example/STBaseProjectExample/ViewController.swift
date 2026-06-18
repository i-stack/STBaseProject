//
//  ViewController.swift
//  STBaseProject_Example
//
//  Created by 寒江孤影 on 2022/8/4.
//

import UIKit
import STBaseProject

class ViewController: BaseViewController {

    private var dataSouces: [String: UIViewController] = [:]
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var topConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.titleLabel.text = "导航目录"
        self.topConstraint.constant = 0
        self.tableView.tableFooterView = UIView()
        self.applyLiquidGlassScrollLayout(self.tableView)
        self.configData()
    }

    private func configData() {
        let hudViewController = STHudViewController(nibName: "STHudViewController", bundle: nil)
        self.dataSouces["hud 测试"] = hudViewController
        
        let logViewController = STLogViewController()
        self.dataSouces["log 测试"] = logViewController
        
        let btnTestViewController = STBtnTestViewController()
        self.dataSouces["STBtn 测试"] = btnTestViewController
        
        self.dataSouces["STView 测试"] = STViewTestViewController()
        self.dataSouces["文本控件测试"] = STTextControlsTestViewController()
        self.dataSouces["TabBar 测试"] = STTabBarTestViewController()
        self.dataSouces["Log/HUD 背景测试"] = STLogAndHUDTestViewController()
        self.dataSouces["STTimer 功能测试"] = STTimerTestViewController()
        self.dataSouces["STTools 手动测试"] = STToolsManualTestViewController()
        self.dataSouces["Markdown 流式渲染测试"] = STMarkdownStreamingTestViewController()
        self.dataSouces["Shimmer 动画测试"] = STShimmerTextViewTestViewController()
        self.dataSouces["SSE 流式渲染测试"] = STSSEViewController(nibName: "STSSEViewController", bundle: nil)
        self.dataSouces["BottomSheet测试"] = STBottomSheetViewController()

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
        if key == "BottomSheet测试" {
            self.presentBootSheet()
        } else {
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    private func presentBootSheet() {
        let vc = STBottomSheetViewController()
        self.present(vc, animated: true)
    }
}
