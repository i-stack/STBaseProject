//
//  STTabBarItemModel.swift
//  STBaseProject
//
//  Created by stack on 2024/01/01.
//

import UIKit

// MARK: - TabBar Item 数据模型
/// 自定义 TabBar Item 数据模型
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
        customView: UIView? = nil
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
