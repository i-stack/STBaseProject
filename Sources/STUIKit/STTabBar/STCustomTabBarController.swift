//
//  STCustomTabBarController.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2024/01/01.
//

import UIKit

/// 继承自 UITabBarController 的自定义 TabBar Controller
/// 适用于需要系统 TabBar 功能但想要自定义样式的场景
open class STCustomTabBarController: UITabBarController {
    
    private var isCustomTabBarVisible: Bool = false
    private var customTabBarItems: [STTabBarItemModel] = []
    private var customTabBarConfig: STTabBarConfig = STTabBarConfig()
    private var hasInstalledCustomTabBar: Bool = false
    private var lastAppliedAdditionalBottomInset: CGFloat = 0

    private var shouldDisplayCustomTabBar: Bool {
        return !self.shouldUseSystemTabBar() && !self.customTabBarItems.isEmpty
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        self.applyPreferredTabBarMode()
    }

    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.st_syncCustomTabBarSafeAreaAndZOrder()
    }
    
    /// 自定义 tabbar 关闭时无需额外处理。
    private func st_syncCustomTabBarSafeAreaAndZOrder() {
        guard self.isCustomTabBarVisible else { return }
        self.updateCustomTabBarSafeArea()
        self.view.bringSubviewToFront(self.customTabBar)
    }

    private func shouldUseSystemTabBar() -> Bool {
        if #available(iOS 26.0, *) {
            return true
        }
        return false
    }

    private func applyPreferredTabBarMode() {
        if self.shouldDisplayCustomTabBar {
            self.setupCustomTabBarIfNeeded()
            self.setupCustomTabBar()
        } else {
            self.setupSystemTabBar()
        }
    }

    private func setupSystemTabBar() {
        self.tabBar.isHidden = false
        self.customTabBar.isHidden = true
        self.isCustomTabBarVisible = false
        self.applyAdditionalBottomSafeAreaInsetIfNeeded(0)
    }

    private func setupCustomTabBarIfNeeded() {
        guard !self.hasInstalledCustomTabBar else { return }
        self.view.addSubview(self.customTabBar)
        NSLayoutConstraint.activate([
            self.customTabBar.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.customTabBar.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            self.customTabBar.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        ])
        self.hasInstalledCustomTabBar = true
    }

    private func setupCustomTabBar() {
        self.setupCustomTabBarIfNeeded()
        self.tabBar.isHidden = true
        self.customTabBar.isHidden = false
        self.isCustomTabBarVisible = true
        self.customTabBar.configure(items: self.customTabBarItems, config: self.customTabBarConfig)
        self.customTabBar.setSelectedIndex(self.selectedIndex)
        self.updateCustomTabBarSafeArea()
    }

    private func updateCustomTabBarSafeArea() {
        guard self.isCustomTabBarVisible else { return }
        let baseSafeAreaBottom = max(0, self.view.safeAreaInsets.bottom - self.additionalSafeAreaInsets.bottom)
        let bottomInset = max(0, self.customTabBar.preferredLayoutHeight - baseSafeAreaBottom)
        self.applyAdditionalBottomSafeAreaInsetIfNeeded(bottomInset)
    }

    private func applyAdditionalBottomSafeAreaInsetIfNeeded(_ bottomInset: CGFloat) {
        guard abs(self.lastAppliedAdditionalBottomInset - bottomInset) > 0.5 else { return }
        self.lastAppliedAdditionalBottomInset = bottomInset
        self.additionalSafeAreaInsets.bottom = bottomInset
    }
    
    /// 配置自定义 TabBar
    /// - Parameters:
    ///   - items: TabBar Item 数据数组
    ///   - config: TabBar 配置
    public func configureCustomTabBar(items: [STTabBarItemModel], config: STTabBarConfig = STTabBarConfig()) {
        self.customTabBarItems = items
        self.customTabBarConfig = config
        self.applyPreferredTabBarMode()
    }
    
    /// 显示自定义 TabBar
    public func showCustomTabBar() {
        self.applyPreferredTabBarMode()
    }
    
    /// 隐藏自定义 TabBar，显示系统 TabBar（未配置过自定义栏时也可调用，用于仅系统 Tab 的场景）
    public func hideCustomTabBar() {
        self.setupSystemTabBar()
    }
    
    /// 切换 TabBar 显示模式
    public func toggleTabBarMode() {
        if self.shouldUseSystemTabBar() {
            self.setupSystemTabBar()
        } else if self.isCustomTabBarVisible {
            self.hideCustomTabBar()
        } else {
            self.showCustomTabBar()
        }
    }
    
    /// 更新指定 Item 的徽章数量
    /// - Parameters:
    ///   - index: Item 索引
    ///   - count: 徽章数量
    public func updateBadgeCount(at index: Int, count: Int) {
        if self.isCustomTabBarVisible {
            self.customTabBar.updateBadgeCount(at: index, count: count)
        } else {
            if let tabBarItems = tabBar.items, index < tabBarItems.count {
                tabBarItems[index].badgeValue = count > 0 ? "\(count)" : nil
            }
        }
    }
    
    /// 更新 TabBar 配置
    /// - Parameter config: 新的配置
    public func updateTabBarConfig(_ config: STTabBarConfig) {
        self.customTabBarConfig = config
        guard self.isCustomTabBarVisible else { return }
        self.customTabBar.updateConfig(config)
        self.updateCustomTabBarSafeArea()
    }
    
    // MARK: - 重写系统方法
    open override func setViewControllers(_ viewControllers: [UIViewController]?, animated: Bool) {
        super.setViewControllers(viewControllers, animated: animated)
        self.applyPreferredTabBarMode()
    }
    
    open override var selectedIndex: Int {
        didSet {
            if self.isCustomTabBarVisible {
                self.customTabBar.setSelectedIndex(self.selectedIndex)
            }
        }
    }
    
    open override var selectedViewController: UIViewController? {
        didSet {
            if self.isCustomTabBarVisible, let selectedVC = self.selectedViewController {
                if let index = viewControllers?.firstIndex(of: selectedVC) {
                    self.customTabBar.setSelectedIndex(index)
                }
            }
        }
    }
    
    private lazy var customTabBar: STCustomTabBar = {
        let tabBar = STCustomTabBar()
        tabBar.delegate = self
        tabBar.translatesAutoresizingMaskIntoConstraints = false
        return tabBar
    }()
}

extension STCustomTabBarController: STCustomTabBarDelegate {
    public func customTabBar(_ tabBar: STCustomTabBar, didSelectItemAt index: Int) {
        guard let targetViewController = self.targetViewController(at: index) else {
            self.customTabBar.setSelectedIndex(self.selectedIndex)
            return
        }
        let shouldSelect = self.delegate?.tabBarController?(self, shouldSelect: targetViewController) ?? true
        guard shouldSelect else {
            self.customTabBar.setSelectedIndex(self.selectedIndex)
            return
        }
        self.selectedIndex = index
        self.delegate?.tabBarController?(self, didSelect: targetViewController)
    }
}

extension STCustomTabBarController {
    private func targetViewController(at index: Int) -> UIViewController? {
        guard let viewControllers = self.viewControllers,
              index >= 0,
              index < viewControllers.count else {
            return nil
        }
        return viewControllers[index]
    }

    /// 设置子页面并配置自定义 TabBar
    public func setViewControllers(_ viewControllers: [UIViewController], tabBarItems: [STTabBarItemModel], config: STTabBarConfig = STTabBarConfig()) {
        self.customTabBarItems = tabBarItems
        self.customTabBarConfig = config
        self.setViewControllers(viewControllers, animated: false)
    }
    
    /// 创建并配置自定义 TabBar Controller
    /// - Parameters:
    ///   - viewControllers: ViewController 数组
    ///   - tabBarItems: TabBar Item 数据数组
    ///   - config: TabBar 配置
    /// - Returns: 配置好的 TabBar Controller
    public static func createWithCustomTabBar(viewControllers: [UIViewController], tabBarItems: [STTabBarItemModel], config: STTabBarConfig = STTabBarConfig()) -> STCustomTabBarController {
        let tabBarController = STCustomTabBarController()
        tabBarController.setViewControllers(viewControllers, tabBarItems: tabBarItems, config: config)
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
    public static func createSimple(viewControllers: [UIViewController], titles: [String], normalImages: [UIImage?], selectedImages: [UIImage?], config: STTabBarConfig = STTabBarConfig()) -> STCustomTabBarController {
        var tabBarItems: [STTabBarItemModel] = []
        for i in 0..<viewControllers.count {
            let model = STTabBarItemModel(title: i < titles.count ? titles[i] : "", normalImage: i < normalImages.count ? normalImages[i] : nil, selectedImage: i < selectedImages.count ? selectedImages[i] : nil)
            tabBarItems.append(model)
        }
        return createWithCustomTabBar(viewControllers: viewControllers, tabBarItems: tabBarItems, config: config)
    }
}
