//
//  STTestViewController.swift
//  STBaseProject
//
//  Created for integration testing of STBaseViewController.
//

import UIKit

open class STTestViewController: STBaseViewController {

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let dataSource: [String] = (0..<40).map { "示例数据 - \($0)" }

    override func viewDidLoad() {
        self.navBarStyle = .custom
        self.navBarBackgroundColor = .clear
        self.navBarTitleFont = UIFont.systemFont(ofSize: 18, weight: .semibold)
        self.statusBarStyle = .lightContent

        super.viewDidLoad()

        self.st_setTitle("测试导航栏控制器")
        self.st_setLeftButton(title: "返回")
        self.st_setRightButton(title: "更多")
        self.st_enableGradientNavigationBar(startColor: UIColor.systemPurple, endColor: UIColor.systemBlue)

        self.setupTableView()
        self.st_linkScrollAlpha(self.tableView)
    }

    override func onRightButtonTap() {
        super.onRightButtonTap()
        let alert = UIAlertController(title: "提示", message: "右侧按钮点击事件", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "好的", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }

    private func setupTableView() {
        self.tableView.translatesAutoresizingMaskIntoConstraints = false
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.contentInsetAdjustmentBehavior = .never

        self.baseView.addSubview(self.tableView)

        NSLayoutConstraint.activate([
            self.tableView.topAnchor.constraint(equalTo: self.baseView.topAnchor, constant: self.navBarHeight),
            self.tableView.leftAnchor.constraint(equalTo: self.baseView.leftAnchor),
            self.tableView.rightAnchor.constraint(equalTo: self.baseView.rightAnchor),
            self.tableView.bottomAnchor.constraint(equalTo: self.baseView.bottomAnchor)
        ])
    }
}

extension STTestViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dataSource.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let reuseId = "cell"
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseId) ??
            UITableViewCell(style: .default, reuseIdentifier: reuseId)
        cell.textLabel?.text = self.dataSource[indexPath.row]
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

