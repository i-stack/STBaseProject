//
//  STTabBarConfig.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2024/01/01.
//

import UIKit

/// 自定义 TabBar 整体外观与动效配置
public struct STTabBarConfig {
    /// TabBar 背景颜色（有背景图时通常设为 `.clear`，由 `backgroundImage` 负责底图）
    public var backgroundColor: UIColor
    /// TabBar 背景图（可选，置于最底层；与 `backgroundColor` 可同时使用，例如半透明色叠在图上）
    public var backgroundImage: UIImage?
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
        backgroundImage: UIImage? = nil,
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
        self.backgroundImage = backgroundImage
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
