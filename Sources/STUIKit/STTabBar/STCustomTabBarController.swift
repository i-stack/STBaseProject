//
//  STCustomTabBarController.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2024/01/01.
//

import UIKit

// MARK: - 自定义 TabBar Controller
/// 自定义 TabBar Controller
/// 继承自 UIViewController 以实现完全自定义的 TabBar
open class STCustomTabBarController: UIViewController {
    
    private var customTabBar: STCustomTabBar!
    private var contentView: UIView!
    public var viewControllers: [UIViewController] = []
    private var currentViewController: UIViewController?
    
    open override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    open func setupUI() {
        view.backgroundColor = .systemBackground
        
        // 创建内容视图
        contentView = UIView()
        contentView.backgroundColor = .clear
        view.addSubview(contentView)
        
        // 创建自定义 TabBar
        customTabBar = STCustomTabBar()
        customTabBar.delegate = self
        view.addSubview(customTabBar)
        
        // 设置约束
        contentView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: view.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: customTabBar.topAnchor)
        ])
        
        customTabBar.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            customTabBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            customTabBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            customTabBar.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            // 高度约束将在配置时设置
        ])
    }
    
    // MARK: - 公共方法
    /// 设置 ViewControllers
    /// - Parameters:
    ///   - viewControllers: ViewController 数组
    ///   - tabBarItems: TabBar Item 数据数组
    ///   - config: TabBar 配置
    public func setViewControllers(
        _ viewControllers: [UIViewController],
        tabBarItems: [STTabBarItemModel],
        config: STTabBarConfig = STTabBarConfig()
    ) {
        self.viewControllers = viewControllers
        
        // 配置 TabBar
        customTabBar.configure(items: tabBarItems, config: config)
        
        // 显示第一个 ViewController
        if !viewControllers.isEmpty {
            showViewController(at: 0)
        }
    }
    
    /// 设置选中的 ViewController
    /// - Parameter index: 索引
    public func setSelectedIndex(_ index: Int) {
        guard index >= 0 && index < viewControllers.count else { return }
        
        customTabBar.setSelectedIndex(index)
        showViewController(at: index)
    }
    
    /// 获取当前选中的索引
    public func getSelectedIndex() -> Int {
        return customTabBar.getSelectedIndex()
    }
    
    /// 更新指定 Item 的徽章数量
    /// - Parameters:
    ///   - index: Item 索引
    ///   - count: 徽章数量
    public func updateBadgeCount(at index: Int, count: Int) {
        customTabBar.updateBadgeCount(at: index, count: count)
    }
    
    /// 更新 TabBar 配置
    /// - Parameter config: 新的配置
    public func updateTabBarConfig(_ config: STTabBarConfig) {
        customTabBar.updateConfig(config)
    }
    
    // MARK: - 私有方法
    private func showViewController(at index: Int) {
        // 移除当前的 ViewController
        if let currentVC = currentViewController {
            currentVC.willMove(toParent: nil)
            currentVC.view.removeFromSuperview()
            currentVC.removeFromParent()
        }
        
        // 添加新的 ViewController
        let newVC = viewControllers[index]
        addChild(newVC)
        contentView.addSubview(newVC.view)
        newVC.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            newVC.view.topAnchor.constraint(equalTo: contentView.topAnchor),
            newVC.view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            newVC.view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            newVC.view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
        newVC.didMove(toParent: self)
        
        currentViewController = newVC
    }
}

// MARK: - STCustomTabBarDelegate
extension STCustomTabBarController: STCustomTabBarDelegate {
    public func customTabBar(_ tabBar: STCustomTabBar, didSelectItemAt index: Int) {
        showViewController(at: index)
    }
}

// MARK: - 便捷方法
extension STCustomTabBarController {
    /// 创建简单的 TabBar Controller
    /// - Parameters:
    ///   - viewControllers: ViewController 数组
    ///   - titles: 标题数组
    ///   - normalImages: 普通图标数组
    ///   - selectedImages: 选中图标数组
    ///   - config: TabBar 配置
    /// - Returns: 配置好的 TabBar Controller
    public static func createSimple(
        viewControllers: [UIViewController],
        titles: [String],
        normalImages: [UIImage?],
        selectedImages: [UIImage?],
        config: STTabBarConfig = STTabBarConfig()
    ) -> STCustomTabBarController {
        let tabBarController = STCustomTabBarController()
        
        // 创建 TabBar Items
        var tabBarItems: [STTabBarItemModel] = []
        for i in 0..<viewControllers.count {
            let model = STTabBarItemModel(
                title: i < titles.count ? titles[i] : "",
                normalImage: i < normalImages.count ? normalImages[i] : nil,
                selectedImage: i < selectedImages.count ? selectedImages[i] : nil
            )
            tabBarItems.append(model)
        }
        
        tabBarController.setViewControllers(viewControllers, tabBarItems: tabBarItems, config: config)
        return tabBarController
    }
}
