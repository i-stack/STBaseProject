//
//  STCustomTabBar测试示例.swift
//  STBaseProject
//
//  Created by stack on 2024/01/01.
//

import UIKit
import SnapKit

// MARK: - 测试示例
/// 这是一个测试示例，展示如何使用 STCustomTabBar
class STCustomTabBarTestViewController: UIViewController {
    
    private var customTabBarController: STCustomTabBarController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCustomTabBar()
    }
    
    private func setupCustomTabBar() {
        // 创建测试用的 ViewControllers
        let homeVC = createTestViewController(title: "首页", backgroundColor: .systemBlue)
        let processVC = createTestViewController(title: "流程", backgroundColor: .systemGreen)
        let myVC = createTestViewController(title: "我的", backgroundColor: .systemOrange)
        
        // 创建 TabBar Items
        let items = [
            STTabBarItemModel(
                title: "首页",
                normalImage: UIImage(systemName: "house"),
                selectedImage: UIImage(systemName: "house.fill"),
                normalTextColor: .systemGray,
                selectedTextColor: .systemBlue,
                badgeCount: 5,
                badgeBackgroundColor: .systemRed,
                badgeTextColor: .white
            ),
            STTabBarItemModel(
                title: "流程",
                normalImage: UIImage(systemName: "list.bullet"),
                selectedImage: UIImage(systemName: "list.bullet.circle"),
                normalTextColor: .systemGray,
                selectedTextColor: .systemGreen
            ),
            STTabBarItemModel(
                title: "我的",
                normalImage: UIImage(systemName: "person"),
                selectedImage: UIImage(systemName: "person.fill"),
                normalTextColor: .systemGray,
                selectedTextColor: .systemOrange
            )
        ]
        
        // 创建 TabBar 配置
        let config = STTabBarConfig(
            backgroundColor: .systemBackground,
            height: 60.0,
            showTopBorder: true,
            topBorderColor: .systemGray4,
            showShadow: true,
            shadowColor: .black,
            shadowOffset: CGSize(width: 0, height: -2),
            shadowRadius: 4,
            shadowOpacity: 0.1,
            enableAnimation: true,
            animationDuration: 0.3,
            selectedScale: 1.1,
            unselectedAlpha: 0.7
        )
        
        // 创建自定义 TabBar Controller
        customTabBarController = STCustomTabBarController()
        customTabBarController.setViewControllers(
            [homeVC, processVC, myVC],
            tabBarItems: items,
            config: config
        )
        
        // 添加到当前视图
        addChild(customTabBarController)
        view.addSubview(customTabBarController.view)
        customTabBarController.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        customTabBarController.didMove(toParent: self)
        
        // 测试动态更新
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.customTabBarController.updateBadgeCount(at: 1, count: 10)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            self.customTabBarController.setSelectedIndex(1)
        }
    }
    
    private func createTestViewController(title: String, backgroundColor: UIColor) -> UIViewController {
        let vc = UIViewController()
        vc.view.backgroundColor = backgroundColor
        
        let label = UILabel()
        label.text = title
        label.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        label.textColor = .white
        label.textAlignment = .center
        vc.view.addSubview(label)
        
        label.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        return vc
    }
}

// MARK: - 简单使用示例
extension STCustomTabBarTestViewController {
    /// 展示最简单的使用方式
    func showSimpleUsage() {
        let homeVC = UIViewController()
        homeVC.view.backgroundColor = .systemBlue
        
        let processVC = UIViewController()
        processVC.view.backgroundColor = .systemGreen
        
        let myVC = UIViewController()
        myVC.view.backgroundColor = .systemOrange
        
        // 使用便捷方法创建
        let tabBarController = STCustomTabBarController.createSimple(
            viewControllers: [homeVC, processVC, myVC],
            titles: ["首页", "流程", "我的"],
            normalImages: [
                UIImage(systemName: "house"),
                UIImage(systemName: "list.bullet"),
                UIImage(systemName: "person")
            ],
            selectedImages: [
                UIImage(systemName: "house.fill"),
                UIImage(systemName: "list.bullet.circle"),
                UIImage(systemName: "person.fill")
            ]
        )
        
        present(tabBarController, animated: true)
    }
}
