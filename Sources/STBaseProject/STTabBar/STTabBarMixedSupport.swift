//
//  STTabBarMixedSupport.swift
//  STBaseProject
//
//  Created by stack on 2024/01/01.
//

import UIKit

// MARK: - 混合 TabBar 支持
/// 支持系统 UITabBarItem 和自定义 STTabBarItemModel 混用的工具类
public class STTabBarMixedSupport {
    
    /// 混合 TabBar Item 类型
    public enum MixedTabBarItem {
        case system(UITabBarItem)
        case custom(STTabBarItemModel)
    }
    
    /// 创建混合 TabBar Controller
    /// - Parameters:
    ///   - viewControllers: ViewController 数组
    ///   - mixedItems: 混合 TabBar Item 数组
    ///   - config: TabBar 配置
    /// - Returns: 配置好的 STCustomTabBarController
    public static func createMixedTabBarController(
        viewControllers: [UIViewController],
        mixedItems: [MixedTabBarItem],
        config: STTabBarConfig = STTabBarConfig()
    ) -> STCustomTabBarController {
        let tabBarController = STCustomTabBarController()
        
        // 分离系统 TabBar Item 和自定义 TabBar Item
        var customItems: [STTabBarItemModel] = []
        var systemItems: [UITabBarItem] = []
        
        for item in mixedItems {
            switch item {
            case .system(let systemItem):
                systemItems.append(systemItem)
            case .custom(let customItem):
                customItems.append(customItem)
            }
        }
        
        // 设置 ViewControllers
        tabBarController.viewControllers = viewControllers
        
        // 如果有系统 TabBar Item，设置到对应的 ViewController
        for (index, systemItem) in systemItems.enumerated() {
            if index < viewControllers.count {
                viewControllers[index].tabBarItem = systemItem
            }
        }
        
        // 如果有自定义 TabBar Item，配置自定义 TabBar
        if !customItems.isEmpty {
            tabBarController.setViewControllers(
                viewControllers,
                tabBarItems: customItems,
                config: config
            )
        }
        
        return tabBarController
    }
    
    /// 将系统 UITabBarItem 转换为 STTabBarItemModel
    /// - Parameter systemItem: 系统 TabBar Item
    /// - Returns: STTabBarItemModel
    public static func convertSystemToCustom(_ systemItem: UITabBarItem) -> STTabBarItemModel {
        return STTabBarItemModel.fromUITabBarItem(systemItem)
    }
    
    /// 将 STTabBarItemModel 转换为系统 UITabBarItem
    /// - Parameter customItem: 自定义 TabBar Item
    /// - Returns: 系统 UITabBarItem
    public static func convertCustomToSystem(_ customItem: STTabBarItemModel) -> UITabBarItem {
        let item = UITabBarItem(title: customItem.title, image: customItem.normalImage, selectedImage: customItem.selectedImage)
        
        // 设置文字属性
        let font = UIFont(name: customItem.titleFontName, size: customItem.titleSize) ?? UIFont.systemFont(ofSize: customItem.titleSize)
        item.setTitleTextAttributes([
            .foregroundColor: customItem.normalTextColor,
            .font: font
        ], for: .normal)
        item.setTitleTextAttributes([
            .foregroundColor: customItem.selectedTextColor,
            .font: font
        ], for: .selected)
        
        // 设置徽章
        if customItem.badgeCount > 0 {
            item.badgeValue = customItem.badgeCount > 99 ? "99+" : "\(customItem.badgeCount)"
            item.badgeColor = customItem.badgeBackgroundColor
        }
        
        return item
    }
}

// MARK: - STCustomTabBarController 扩展
public extension STCustomTabBarController {
    
    /// 设置混合 TabBar Items
    /// - Parameters:
    ///   - viewControllers: ViewController 数组
    ///   - mixedItems: 混合 TabBar Item 数组
    ///   - config: TabBar 配置
    func setMixedTabBarItems(
        _ viewControllers: [UIViewController],
        mixedItems: [STTabBarMixedSupport.MixedTabBarItem],
        config: STTabBarConfig = STTabBarConfig()
    ) {
        // 分离系统 TabBar Item 和自定义 TabBar Item
        var customItems: [STTabBarItemModel] = []
        var systemItems: [UITabBarItem] = []
        
        for item in mixedItems {
            switch item {
            case .system(let systemItem):
                systemItems.append(systemItem)
            case .custom(let customItem):
                customItems.append(customItem)
            }
        }
        
        // 设置 ViewControllers
        self.viewControllers = viewControllers
        
        // 如果有系统 TabBar Item，设置到对应的 ViewController
        for (index, systemItem) in systemItems.enumerated() {
            if index < viewControllers.count {
                viewControllers[index].tabBarItem = systemItem
            }
        }
        
        // 如果有自定义 TabBar Item，配置自定义 TabBar
        if !customItems.isEmpty {
            self.setViewControllers(
                viewControllers,
                tabBarItems: customItems,
                config: config
            )
        }
    }
}

// MARK: - 使用示例
/*
// 创建混合 TabBar Controller
let homeVC = HomeViewController()
let messageVC = MessageViewController()
let profileVC = ProfileViewController()

let mixedItems: [STTabBarMixedSupport.MixedTabBarItem] = [
    .custom(STTabBarItemModel.createImageOnly(
        normalImageName: "home_normal",
        selectedImageName: "home_sel"
    )),
    .system(UITabBarItem(
        title: "消息",
        image: UIImage(named: "message_normal"),
        selectedImage: UIImage(named: "message_sel")
    )),
    .custom(STTabBarItemModel.createIrregular(
        title: "发布",
        normalImageName: "add_normal",
        selectedImageName: "add_sel"
    )),
    .custom(STTabBarItemModel.createTextOnly(
        title: "我的",
        titleSize: 14
    ))
]

let tabBarController = STTabBarMixedSupport.createMixedTabBarController(
    viewControllers: [homeVC, messageVC, profileVC],
    mixedItems: mixedItems
)
*/
