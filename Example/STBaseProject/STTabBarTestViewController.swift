//
//  STTabBarTestViewController.swift
//  STBaseProject_Example
//
//  Created by 寒江孤影 on 2026/4/27.
//

import UIKit
import STBaseProject

final class STTabBarTestViewController: STBaseViewController {
    
    private let customTabBar = STCustomTabBar()
    private let statusLabel = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.titleLabel.text = "TabBar 测试"
        self.st_showNavBtnType(type: .showLeftBtn)
        self.leftBtn.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        self.view.backgroundColor = .systemGroupedBackground
        self.setupViews()
        self.setupTabBar()
    }
    
    private func setupViews() {
        self.statusLabel.text = "当前选中：首页"
        self.statusLabel.textAlignment = .center
        self.statusLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        self.statusLabel.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.statusLabel)
        
        self.customTabBar.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.customTabBar)
        NSLayoutConstraint.activate([
            self.statusLabel.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            self.statusLabel.centerYAnchor.constraint(equalTo: self.view.centerYAnchor),
            self.customTabBar.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 20),
            self.customTabBar.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -20),
            self.customTabBar.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -24)
        ])
    }
    
    private func setupTabBar() {
        let items = [
            STTabBarItemModel(title: "首页", normalImage: UIImage(systemName: "house"), selectedImage: UIImage(systemName: "house.fill")),
            STTabBarItemModel(title: "消息", normalImage: UIImage(systemName: "message"), selectedImage: UIImage(systemName: "message.fill"), badge: STTabBarItemBadge(count: 8)),
            STTabBarItemModel(title: "我的", normalImage: UIImage(systemName: "person"), selectedImage: UIImage(systemName: "person.fill"))
        ]
        var config = STTabBarConfig()
        config.height = 64
        config.backgroundColor = .clear
        config.showShadow = true
        self.customTabBar.layer.cornerRadius = 22
        self.customTabBar.configure(items: items, config: config)
        self.customTabBar.st_setLiquidGlassBackground()
        self.customTabBar.delegate = self
    }
}

extension STTabBarTestViewController: STCustomTabBarDelegate {
    func customTabBar(_ tabBar: STCustomTabBar, didSelectItemAt index: Int) {
        tabBar.setSelectedIndex(index)
        let titles = ["首页", "消息", "我的"]
        self.statusLabel.text = "当前选中：\(titles[index])"
    }
}
