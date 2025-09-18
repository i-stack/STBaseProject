//
//  STCustomUITabBarController.swift
//  STBaseProject
//
//  Created by stack on 2024/01/01.
//

import UIKit

// MARK: - 自定义 UITabBarController
/// 继承自 UITabBarController 的自定义 TabBar Controller
/// 适用于需要系统 TabBar 功能但想要自定义样式的场景
open class STCustomUITabBarController: UITabBarController {
    
    private var customTabBar: STCustomTabBar!
    private var isCustomTabBarVisible: Bool = false
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        setupCustomTabBar()
    }
    
    private func setupCustomTabBar() {
        tabBar.isHidden = true
        customTabBar = STCustomTabBar()
        customTabBar.delegate = self
        view.addSubview(customTabBar)
        customTabBar.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            customTabBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            customTabBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            customTabBar.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            customTabBar.heightAnchor.constraint(equalToConstant: 49) // 默认高度，会被配置覆盖
        ])
    }
    
    // MARK: - 公共方法
    /// 配置自定义 TabBar
    /// - Parameters:
    ///   - items: TabBar Item 数据数组
    ///   - config: TabBar 配置
    public func configureCustomTabBar(items: [STTabBarItemModel], config: STTabBarConfig = STTabBarConfig()) {
        customTabBar.configure(items: items, config: config)
        isCustomTabBarVisible = true
    }
    
    /// 显示自定义 TabBar
    public func showCustomTabBar() {
        guard !isCustomTabBarVisible else { return }
        customTabBar.isHidden = false
        tabBar.isHidden = true
        isCustomTabBarVisible = true
    }
    
    /// 隐藏自定义 TabBar，显示系统 TabBar
    public func hideCustomTabBar() {
        guard isCustomTabBarVisible else { return }
        customTabBar.isHidden = true
        tabBar.isHidden = false
        isCustomTabBarVisible = false
    }
    
    /// 切换 TabBar 显示模式
    public func toggleTabBarMode() {
        if isCustomTabBarVisible {
            hideCustomTabBar()
        } else {
            showCustomTabBar()
        }
    }
    
    /// 更新指定 Item 的徽章数量
    /// - Parameters:
    ///   - index: Item 索引
    ///   - count: 徽章数量
    public func updateBadgeCount(at index: Int, count: Int) {
        if isCustomTabBarVisible {
            customTabBar.updateBadgeCount(at: index, count: count)
        } else {
            if let tabBarItems = tabBar.items, index < tabBarItems.count {
                tabBarItems[index].badgeValue = count > 0 ? "\(count)" : nil
            }
        }
    }
    
    /// 更新 TabBar 配置
    /// - Parameter config: 新的配置
    public func updateTabBarConfig(_ config: STTabBarConfig) {
        customTabBar.updateConfig(config)
    }
    
    // MARK: - 重写系统方法
    open override func setViewControllers(_ viewControllers: [UIViewController]?, animated: Bool) {
        super.setViewControllers(viewControllers, animated: animated)
        if isCustomTabBarVisible {
            customTabBar.setSelectedIndex(selectedIndex)
        }
    }
    
    open override var selectedIndex: Int {
        didSet {
            if isCustomTabBarVisible {
                customTabBar.setSelectedIndex(selectedIndex)
            }
        }
    }
    
    open override var selectedViewController: UIViewController? {
        didSet {
            if isCustomTabBarVisible, let selectedVC = selectedViewController {
                if let index = viewControllers?.firstIndex(of: selectedVC) {
                    customTabBar.setSelectedIndex(index)
                }
            }
        }
    }
}

// MARK: - STCustomTabBarDelegate
extension STCustomUITabBarController: STCustomTabBarDelegate {
    public func customTabBar(_ tabBar: STCustomTabBar, didSelectItemAt index: Int) {
        selectedIndex = index
    }
}

// MARK: - 便捷方法
extension STCustomUITabBarController {
    /// 创建并配置自定义 TabBar Controller
    /// - Parameters:
    ///   - viewControllers: ViewController 数组
    ///   - tabBarItems: TabBar Item 数据数组
    ///   - config: TabBar 配置
    /// - Returns: 配置好的 TabBar Controller
    public static func createWithCustomTabBar(
        viewControllers: [UIViewController],
        tabBarItems: [STTabBarItemModel],
        config: STTabBarConfig = STTabBarConfig()
    ) -> STCustomUITabBarController {
        let tabBarController = STCustomUITabBarController()
        tabBarController.setViewControllers(viewControllers, animated: false)
        tabBarController.configureCustomTabBar(items: tabBarItems, config: config)
        return tabBarController
    }
    
    /// 创建简单的自定义 TabBar Controller
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
    ) -> STCustomUITabBarController {
        var tabBarItems: [STTabBarItemModel] = []
        for i in 0..<viewControllers.count {
            let model = STTabBarItemModel(
                title: i < titles.count ? titles[i] : "",
                normalImage: i < normalImages.count ? normalImages[i] : nil,
                selectedImage: i < selectedImages.count ? selectedImages[i] : nil
            )
            tabBarItems.append(model)
        }
        return createWithCustomTabBar(
            viewControllers: viewControllers,
            tabBarItems: tabBarItems,
            config: config
        )
    }
}
