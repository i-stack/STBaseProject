//
//  STTabBarItem.swift
//  STBaseProject
//
//  Created by stack on 2017/12/16.
//  Updated by AI Assistant on 2024/12/19.
//

import UIKit
import Foundation

// MARK: - TabBarItem 本地化常量
private struct STTabBarItemLocalizationKey {
    static var localizedTitleKey: UInt8 = 0
}

// MARK: - TabBarItem 配置模型
public struct STTabBarItemConfig {
    public var title: String
    public var titleSize: CGFloat
    public var titleFontName: String
    public var normalImage: String
    public var selectedImage: String
    public var imageSize: CGSize?
    public var normalTitleColor: UIColor
    public var selectedTitleColor: UIColor
    public var backgroundColor: UIColor
    public var badgeValue: String?
    public var badgeColor: UIColor?
    public var isLocalized: Bool
    
    public init(title: String,
                titleSize: CGFloat = 12,
                titleFontName: String = "PingFangSC-Regular",
                normalImage: String,
                selectedImage: String,
                imageSize: CGSize? = nil,
                normalTitleColor: UIColor = .systemGray,
                selectedTitleColor: UIColor = .systemBlue,
                backgroundColor: UIColor = .clear,
                badgeValue: String? = nil,
                badgeColor: UIColor? = .systemRed,
                isLocalized: Bool = true) {
        self.title = title
        self.titleSize = titleSize
        self.titleFontName = titleFontName
        self.normalImage = normalImage
        self.selectedImage = selectedImage
        self.imageSize = imageSize
        self.normalTitleColor = normalTitleColor
        self.selectedTitleColor = selectedTitleColor
        self.backgroundColor = backgroundColor
        self.badgeValue = badgeValue
        self.badgeColor = badgeColor
        self.isLocalized = isLocalized
    }
}

// MARK: - 自定义 TabBarItem 类
/// 自定义 TabBarItem 类，支持本地化、徽章、多种配置选项
public class STTabBarItem: NSObject {
    
    // MARK: - 本地化标题属性
    public var localizedTitle: String {
        get {
            return objc_getAssociatedObject(self, &STTabBarItemLocalizationKey.localizedTitleKey) as? String ?? ""
        }
        set {
            objc_setAssociatedObject(self, &STTabBarItemLocalizationKey.localizedTitleKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    // MARK: - 主要方法
    /// 创建自定义 TabBarItem（兼容原有方法）
    /// - Parameters:
    ///   - title: 标题
    ///   - titleSize: 标题字体大小
    ///   - titleFontName: 标题字体名称
    ///   - normalImage: 普通状态图片名称
    ///   - selectedImage: 选中状态图片名称
    ///   - imageSize: 图片大小
    ///   - normalTitleColor: 普通状态标题颜色
    ///   - selectedTitleColor: 选中状态标题颜色
    ///   - backgroundColor: 背景颜色
    /// - Returns: 配置好的 UITabBarItem
    public class func st_setTabBarItem(title: String,
                                       titleSize: CGFloat,
                                       titleFontName: String,
                                       normalImage: String,
                                       selectedImage: String,
                                       imageSize: CGSize? = nil,
                                       normalTitleColor: UIColor,
                                       selectedTitleColor: UIColor,
                                       backgroundColor: UIColor) -> UITabBarItem {
        let config = STTabBarItemConfig(
            title: title,
            titleSize: titleSize,
            titleFontName: titleFontName,
            normalImage: normalImage,
            selectedImage: selectedImage,
            imageSize: imageSize,
            normalTitleColor: normalTitleColor,
            selectedTitleColor: selectedTitleColor,
            backgroundColor: backgroundColor,
            isLocalized: false
        )
        return st_createTabBarItem(with: config)
    }
    
    /// 使用配置模型创建 TabBarItem
    /// - Parameter config: TabBarItem 配置模型
    /// - Returns: 配置好的 UITabBarItem
    public class func st_createTabBarItem(with config: STTabBarItemConfig) -> UITabBarItem {
        let finalTitle = config.isLocalized ? config.title.localized : config.title
        let normalImage = st_loadImage(named: config.normalImage, imageSize: config.imageSize)
        let selectedImage = st_loadImage(named: config.selectedImage, imageSize: config.imageSize)
        let item = UITabBarItem(title: finalTitle, image: normalImage, selectedImage: selectedImage)
        let font = UIFont(name: config.titleFontName, size: config.titleSize) ?? UIFont.systemFont(ofSize: config.titleSize)
        item.setTitleTextAttributes([
            .foregroundColor: config.normalTitleColor,
            .backgroundColor: config.backgroundColor,
            .font: font
        ], for: .normal)
        item.setTitleTextAttributes([
            .foregroundColor: config.selectedTitleColor,
            .font: font
        ], for: .selected)
        if let badgeValue = config.badgeValue {
            item.badgeValue = badgeValue
            if let badgeColor = config.badgeColor {
                item.badgeColor = badgeColor
            }
        }
        return item
    }
    
    /// 快速创建带本地化的 TabBarItem
    /// - Parameters:
    ///   - localizedTitle: 本地化标题键
    ///   - normalImage: 普通状态图片名称
    ///   - selectedImage: 选中状态图片名称
    ///   - imageSize: 图片大小
    ///   - normalColor: 普通状态颜色
    ///   - selectedColor: 选中状态颜色
    /// - Returns: 配置好的 UITabBarItem
    public class func st_createLocalizedTabBarItem(localizedTitle: String,
                                                   normalImage: String,
                                                   selectedImage: String,
                                                   imageSize: CGSize? = nil,
                                                   normalColor: UIColor = .systemGray,
                                                   selectedColor: UIColor = .systemBlue) -> UITabBarItem {
        let config = STTabBarItemConfig(
            title: localizedTitle,
            normalImage: normalImage,
            selectedImage: selectedImage,
            imageSize: imageSize,
            normalTitleColor: normalColor,
            selectedTitleColor: selectedColor,
            isLocalized: true
        )
        return st_createTabBarItem(with: config)
    }
    
    /// 批量创建 TabBarItems
    /// - Parameter configs: 配置数组
    /// - Returns: TabBarItem 数组
    public class func st_createTabBarItems(with configs: [STTabBarItemConfig]) -> [UITabBarItem] {
        return configs.map { st_createTabBarItem(with: $0) }
    }
    
    // MARK: - 私有辅助方法
    /// 安全加载图片
    /// - Parameter imageName: 图片名称
    /// - Returns: UIImage 对象
    private class func st_loadImage(named imageName: String, imageSize: CGSize? = nil) -> UIImage? {
        guard var image = UIImage(named: imageName) else {
            STLog("⚠️ STTabBarItem: 图片加载失败 - \(imageName)")
            return nil
        }
        if let size = imageSize {
            image = image.imageResized(to: size) ?? image
        }
        return image.withRenderingMode(.alwaysOriginal)
    }
    
    /// 更新本地化文本
    /// - Parameter item: 要更新的 TabBarItem
    /// - Parameter localizedTitle: 本地化标题键
    public class func st_updateLocalizedTitle(for item: UITabBarItem, localizedTitle: String) {
        item.title = localizedTitle.localized
        STLog("✅ STTabBarItem: 本地化标题已更新 - \(localizedTitle)")
    }
}

// MARK: - UITabBarItem 扩展
public extension UITabBarItem {
    
    /// 设置徽章
    /// - Parameters:
    ///   - value: 徽章值
    ///   - color: 徽章颜色
    func st_setBadge(value: String?, color: UIColor = .systemRed) {
        self.badgeValue = value
        self.badgeColor = color
    }
    
    /// 清除徽章
    func st_clearBadge() {
        self.badgeValue = nil
    }
    
    /// 设置自定义图片
    /// - Parameters:
    ///   - normalImage: 普通状态图片
    ///   - selectedImage: 选中状态图片
    func st_setCustomImages(normalImage: UIImage?, selectedImage: UIImage?) {
        self.image = normalImage?.withRenderingMode(.alwaysOriginal)
        self.selectedImage = selectedImage?.withRenderingMode(.alwaysOriginal)
    }
    
    /// 设置自定义图片（通过名称）
    /// - Parameters:
    ///   - normalImageName: 普通状态图片名称
    ///   - selectedImageName: 选中状态图片名称
    func st_setCustomImages(normalImageName: String, selectedImageName: String) {
        let normalImage = UIImage(named: normalImageName)?.withRenderingMode(.alwaysOriginal)
        let selectedImage = UIImage(named: selectedImageName)?.withRenderingMode(.alwaysOriginal)
        st_setCustomImages(normalImage: normalImage, selectedImage: selectedImage)
    }
}
