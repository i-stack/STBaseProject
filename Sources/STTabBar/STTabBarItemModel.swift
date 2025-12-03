//
//  STTabBarItemModel.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2024/01/01.
//

import UIKit

// MARK: - TabBar Item 显示模式
/// TabBar Item 显示模式
public enum STTabBarItemDisplayMode {
    case imageOnly          // 只显示图片
    case textOnly           // 只显示文字
    case imageAndText       // 显示图片和文字
    case custom             // 自定义视图
    case irregular          // 不规则（凸起按钮）
}

// MARK: - TabBar Item 数据模型
/// 统一的 TabBar Item 数据模型
/// 支持系统 TabBar 和自定义 TabBar
public struct STTabBarItemModel {
    /// 标题
    public var title: String
    /// 普通状态图标
    public var normalImage: UIImage?
    /// 选中状态图标
    public var selectedImage: UIImage?
    /// 普通状态文字颜色
    public var normalTextColor: UIColor
    /// 选中状态文字颜色
    public var selectedTextColor: UIColor
    /// 普通状态背景颜色
    public var normalBackgroundColor: UIColor
    /// 选中状态背景颜色
    public var selectedBackgroundColor: UIColor
    /// 是否启用
    public var isEnabled: Bool
    /// 徽章数量
    public var badgeCount: Int
    /// 徽章背景颜色
    public var badgeBackgroundColor: UIColor
    /// 徽章文字颜色
    public var badgeTextColor: UIColor
    /// 自定义视图（可选）
    public var customView: UIView?
    /// 标题字体大小
    public var titleSize: CGFloat
    /// 标题字体名称
    public var titleFontName: String
    /// 是否支持本地化
    public var isLocalized: Bool
    /// 图片大小（用于调整）
    public var imageSize: CGSize?
    /// 显示模式
    public var displayMode: STTabBarItemDisplayMode
    /// 是否为不规则按钮（凸起按钮）
    public var isIrregular: Bool
    /// 不规则按钮的额外高度
    public var irregularHeight: CGFloat
    /// 不规则按钮的圆角半径
    public var irregularCornerRadius: CGFloat
    /// 不规则按钮的背景颜色
    public var irregularBackgroundColor: UIColor
    /// 不规则按钮的阴影颜色
    public var irregularShadowColor: UIColor
    /// 不规则按钮的阴影偏移
    public var irregularShadowOffset: CGSize
    /// 不规则按钮的阴影半径
    public var irregularShadowRadius: CGFloat
    
    public init(
        title: String,
        normalImage: UIImage? = nil,
        selectedImage: UIImage? = nil,
        normalTextColor: UIColor = .systemGray,
        selectedTextColor: UIColor = .systemBlue,
        normalBackgroundColor: UIColor = .clear,
        selectedBackgroundColor: UIColor = .clear,
        isEnabled: Bool = true,
        badgeCount: Int = 0,
        badgeBackgroundColor: UIColor = .systemRed,
        badgeTextColor: UIColor = .white,
        customView: UIView? = nil,
        titleSize: CGFloat = 12.0,
        titleFontName: String = "PingFangSC-Regular",
        isLocalized: Bool = false,
        imageSize: CGSize? = nil,
        displayMode: STTabBarItemDisplayMode = .imageAndText,
        isIrregular: Bool = false,
        irregularHeight: CGFloat = 20.0,
        irregularCornerRadius: CGFloat = 25.0,
        irregularBackgroundColor: UIColor = .systemBlue,
        irregularShadowColor: UIColor = .black,
        irregularShadowOffset: CGSize = CGSize(width: 0, height: 2),
        irregularShadowRadius: CGFloat = 4.0
    ) {
        self.title = title
        self.normalImage = normalImage
        self.selectedImage = selectedImage
        self.normalTextColor = normalTextColor
        self.selectedTextColor = selectedTextColor
        self.normalBackgroundColor = normalBackgroundColor
        self.selectedBackgroundColor = selectedBackgroundColor
        self.isEnabled = isEnabled
        self.badgeCount = badgeCount
        self.badgeBackgroundColor = badgeBackgroundColor
        self.badgeTextColor = badgeTextColor
        self.customView = customView
        self.titleSize = titleSize
        self.titleFontName = titleFontName
        self.isLocalized = isLocalized
        self.imageSize = imageSize
        self.displayMode = displayMode
        self.isIrregular = isIrregular
        self.irregularHeight = irregularHeight
        self.irregularCornerRadius = irregularCornerRadius
        self.irregularBackgroundColor = irregularBackgroundColor
        self.irregularShadowColor = irregularShadowColor
        self.irregularShadowOffset = irregularShadowOffset
        self.irregularShadowRadius = irregularShadowRadius
    }
    
    // MARK: - 便捷创建方法
    /// 从图片名称创建（类似 STTabBarItemConfig）
    /// - Parameters:
    ///   - title: 标题
    ///   - normalImageName: 普通状态图片名称
    ///   - selectedImageName: 选中状态图片名称
    ///   - titleSize: 标题字体大小
    ///   - titleFontName: 标题字体名称
    ///   - normalTitleColor: 普通状态文字颜色
    ///   - selectedTitleColor: 选中状态文字颜色
    ///   - backgroundColor: 背景颜色
    ///   - imageSize: 图片大小
    ///   - badgeValue: 徽章值
    ///   - badgeColor: 徽章颜色
    ///   - isLocalized: 是否本地化
    /// - Returns: STTabBarItemModel
    public static func createWithImageNames(
        title: String,
        normalImageName: String,
        selectedImageName: String,
        titleSize: CGFloat = 12.0,
        titleFontName: String = "PingFangSC-Regular",
        normalTitleColor: UIColor = .systemGray,
        selectedTitleColor: UIColor = .systemBlue,
        backgroundColor: UIColor = .clear,
        imageSize: CGSize? = nil,
        badgeValue: String? = nil,
        badgeColor: UIColor = .systemRed,
        isLocalized: Bool = false
    ) -> STTabBarItemModel {
        let finalTitle = isLocalized ? title.localized : title
        let normalImage = loadImage(named: normalImageName, imageSize: imageSize)
        let selectedImage = loadImage(named: selectedImageName, imageSize: imageSize)
        let badgeCount = badgeCountFromString(badgeValue)
        
        return STTabBarItemModel(
            title: finalTitle,
            normalImage: normalImage,
            selectedImage: selectedImage,
            normalTextColor: normalTitleColor,
            selectedTextColor: selectedTitleColor,
            normalBackgroundColor: backgroundColor,
            selectedBackgroundColor: backgroundColor,
            badgeCount: badgeCount,
            badgeBackgroundColor: badgeColor,
            titleSize: titleSize,
            titleFontName: titleFontName,
            isLocalized: isLocalized,
            imageSize: imageSize
        )
    }
    
    /// 创建本地化 TabBar Item
    /// - Parameters:
    ///   - localizedTitle: 本地化标题键
    ///   - normalImageName: 普通状态图片名称
    ///   - selectedImageName: 选中状态图片名称
    ///   - normalColor: 普通状态颜色
    ///   - selectedColor: 选中状态颜色
    /// - Returns: STTabBarItemModel
    public static func createLocalized(
        localizedTitle: String,
        normalImageName: String,
        selectedImageName: String,
        normalColor: UIColor = .systemGray,
        selectedColor: UIColor = .systemBlue
    ) -> STTabBarItemModel {
        return createWithImageNames(
            title: localizedTitle,
            normalImageName: normalImageName,
            selectedImageName: selectedImageName,
            normalTitleColor: normalColor,
            selectedTitleColor: selectedColor,
            isLocalized: true
        )
    }
    
    /// 从 UITabBarItem 创建
    /// - Parameter tabBarItem: 系统 TabBarItem
    /// - Returns: STTabBarItemModel
    public static func fromUITabBarItem(_ tabBarItem: UITabBarItem) -> STTabBarItemModel {
        return STTabBarItemModel(
            title: tabBarItem.title ?? "",
            normalImage: tabBarItem.image,
            selectedImage: tabBarItem.selectedImage,
            normalTextColor: .systemGray,
            selectedTextColor: .systemBlue,
            badgeCount: badgeCountFromString(tabBarItem.badgeValue),
            badgeBackgroundColor: tabBarItem.badgeColor ?? .systemRed,
            titleSize: 12.0,
            titleFontName: "PingFangSC-Regular",
            isLocalized: false
        )
    }
    
    // MARK: - 显示模式便捷创建方法
    
    /// 创建只显示图片的 TabBar Item
    /// - Parameters:
    ///   - normalImageName: 普通状态图片名称
    ///   - selectedImageName: 选中状态图片名称
    ///   - imageSize: 图片大小
    ///   - backgroundColor: 背景颜色
    ///   - badgeValue: 徽章值
    /// - Returns: STTabBarItemModel
    public static func createImageOnly(
        normalImageName: String,
        selectedImageName: String,
        imageSize: CGSize = CGSize(width: 24, height: 24),
        backgroundColor: UIColor = .clear,
        badgeValue: String? = nil
    ) -> STTabBarItemModel {
        let normalImage = loadImage(named: normalImageName, imageSize: imageSize)
        let selectedImage = loadImage(named: selectedImageName, imageSize: imageSize)
        let badgeCount = badgeCountFromString(badgeValue)
        
        return STTabBarItemModel(
            title: "",
            normalImage: normalImage,
            selectedImage: selectedImage,
            normalBackgroundColor: backgroundColor,
            selectedBackgroundColor: backgroundColor,
            badgeCount: badgeCount,
            imageSize: imageSize,
            displayMode: .imageOnly
        )
    }
    
    /// 创建只显示文字的 TabBar Item
    /// - Parameters:
    ///   - title: 标题
    ///   - titleSize: 字体大小
    ///   - titleFontName: 字体名称
    ///   - normalTitleColor: 普通状态文字颜色
    ///   - selectedTitleColor: 选中状态文字颜色
    ///   - backgroundColor: 背景颜色
    ///   - isLocalized: 是否本地化
    /// - Returns: STTabBarItemModel
    public static func createTextOnly(
        title: String,
        titleSize: CGFloat = 14.0,
        titleFontName: String = "PingFangSC-Medium",
        normalTitleColor: UIColor = .systemGray,
        selectedTitleColor: UIColor = .systemBlue,
        backgroundColor: UIColor = .clear,
        isLocalized: Bool = false
    ) -> STTabBarItemModel {
        let finalTitle = isLocalized ? title.localized : title
        
        return STTabBarItemModel(
            title: finalTitle,
            normalTextColor: normalTitleColor,
            selectedTextColor: selectedTitleColor,
            normalBackgroundColor: backgroundColor,
            selectedBackgroundColor: backgroundColor,
            titleSize: titleSize,
            titleFontName: titleFontName,
            isLocalized: isLocalized,
            displayMode: .textOnly
        )
    }
    
    /// 创建不规则（凸起）按钮
    /// - Parameters:
    ///   - title: 标题
    ///   - normalImageName: 普通状态图片名称
    ///   - selectedImageName: 选中状态图片名称
    ///   - irregularHeight: 额外高度
    ///   - irregularCornerRadius: 圆角半径
    ///   - irregularBackgroundColor: 背景颜色
    ///   - titleSize: 字体大小
    ///   - imageSize: 图片大小
    /// - Returns: STTabBarItemModel
    public static func createIrregular(
        title: String,
        normalImageName: String,
        selectedImageName: String,
        irregularHeight: CGFloat = 20.0,
        irregularCornerRadius: CGFloat = 25.0,
        irregularBackgroundColor: UIColor = .systemBlue,
        titleSize: CGFloat = 12.0,
        imageSize: CGSize = CGSize(width: 24, height: 24)
    ) -> STTabBarItemModel {
        let normalImage = loadImage(named: normalImageName, imageSize: imageSize)
        let selectedImage = loadImage(named: selectedImageName, imageSize: imageSize)
        
        return STTabBarItemModel(
            title: title,
            normalImage: normalImage,
            selectedImage: selectedImage,
            normalTextColor: .white,
            selectedTextColor: .white,
            normalBackgroundColor: irregularBackgroundColor,
            selectedBackgroundColor: irregularBackgroundColor,
            titleSize: titleSize,
            imageSize: imageSize,
            displayMode: .irregular,
            isIrregular: true,
            irregularHeight: irregularHeight,
            irregularCornerRadius: irregularCornerRadius,
            irregularBackgroundColor: irregularBackgroundColor
        )
    }
    
    /// 创建自定义视图的 TabBar Item
    /// - Parameters:
    ///   - customView: 自定义视图
    ///   - title: 标题（用于标识）
    /// - Returns: STTabBarItemModel
    public static func createCustom(
        customView: UIView,
        title: String = ""
    ) -> STTabBarItemModel {
        return STTabBarItemModel(
            title: title,
            customView: customView,
            displayMode: .custom
        )
    }
    
    /// 安全加载图片
    /// - Parameters:
    ///   - imageName: 图片名称
    ///   - imageSize: 图片大小
    /// - Returns: UIImage 对象
    private static func loadImage(named imageName: String, imageSize: CGSize? = nil) -> UIImage? {
        guard let image = UIImage(named: imageName) else {
            print("⚠️ STTabBarItemModel: 图片加载失败 - \(imageName)")
            return nil
        }
//        if let size = imageSize {
//            UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
//            image.draw(in: CGRect(origin: .zero, size: size))
//            if let resizedImage = UIGraphicsGetImageFromCurrentImageContext() {
//                image = resizedImage
//            }
//            UIGraphicsEndImageContext()
//        }
        return image.withRenderingMode(.alwaysOriginal)
    }
    
    /// 从字符串解析徽章数量
    /// - Parameter badgeValue: 徽章值字符串
    /// - Returns: 徽章数量
    private static func badgeCountFromString(_ badgeValue: String?) -> Int {
        guard let badgeValue = badgeValue else { return 0 }
        if badgeValue == "99+" {
            return 100 // 特殊处理 99+
        }
        return Int(badgeValue) ?? 0
    }
}

// MARK: - TabBar 配置模型
/// 自定义 TabBar 配置模型
public struct STTabBarConfig {
    /// TabBar 背景颜色
    public var backgroundColor: UIColor
    /// TabBar 高度
    public var height: CGFloat
    /// 是否显示顶部边框
    public var showTopBorder: Bool
    /// 顶部边框颜色
    public var topBorderColor: UIColor
    /// 顶部边框宽度
    public var topBorderWidth: CGFloat
    /// 是否显示阴影
    public var showShadow: Bool
    /// 阴影颜色
    public var shadowColor: UIColor
    /// 阴影偏移
    public var shadowOffset: CGSize
    /// 阴影半径
    public var shadowRadius: CGFloat
    /// 阴影透明度
    public var shadowOpacity: Float
    /// 是否支持动画
    public var enableAnimation: Bool
    /// 动画持续时间
    public var animationDuration: TimeInterval
    /// 选中项缩放比例
    public var selectedScale: CGFloat
    /// 未选中项透明度
    public var unselectedAlpha: CGFloat
    
    public init(
        backgroundColor: UIColor = .systemBackground,
        height: CGFloat = 49.0,
        showTopBorder: Bool = true,
        topBorderColor: UIColor = .systemGray4,
        topBorderWidth: CGFloat = 0.5,
        showShadow: Bool = true,
        shadowColor: UIColor = .black,
        shadowOffset: CGSize = CGSize(width: 0, height: -2),
        shadowRadius: CGFloat = 4,
        shadowOpacity: Float = 0.1,
        enableAnimation: Bool = true,
        animationDuration: TimeInterval = 0.3,
        selectedScale: CGFloat = 1.1,
        unselectedAlpha: CGFloat = 0.7
    ) {
        self.backgroundColor = backgroundColor
        self.height = height
        self.showTopBorder = showTopBorder
        self.topBorderColor = topBorderColor
        self.topBorderWidth = topBorderWidth
        self.showShadow = showShadow
        self.shadowColor = shadowColor
        self.shadowOffset = shadowOffset
        self.shadowRadius = shadowRadius
        self.shadowOpacity = shadowOpacity
        self.enableAnimation = enableAnimation
        self.animationDuration = animationDuration
        self.selectedScale = selectedScale
        self.unselectedAlpha = unselectedAlpha
    }
}
