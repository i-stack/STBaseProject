//
//  STIconButton.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2019/10/14.
//

import UIKit

// MARK: - 图标位置枚举
public enum STIconPosition {
    case left
    case right
    case top
    case bottom
}

public class STIconButtonBuilder {
    private weak var button: STIconButton?
    
    init(button: STIconButton) {
        self.button = button
    }
    
    /// 设置图标位置
    /// - Parameter position: 图标位置
    /// - Returns: 构建器实例，支持链式调用
    @discardableResult
    public func iconPosition(_ position: STIconPosition) -> STIconButtonBuilder {
        button?.iconPosition = position
        return self
    }
    
    /// 设置图标和文字之间的间距
    /// - Parameter spacing: 间距值
    /// - Returns: 构建器实例，支持链式调用
    @discardableResult
    public func spacing(_ spacing: CGFloat) -> STIconButtonBuilder {
        button?.spacing = spacing
        return self
    }
    
    /// 完成配置，执行布局更新
    /// 使用示例：
    /// ```
    /// button.configure()
    ///     .iconPosition(.right)
    ///     .spacing(12)
    ///     .done()
    /// ```
    public func done() {
        button?.setNeedsLayout()
    }
}

// MARK: - 图标按钮类
open class STIconButton: STBtn {
    
    /// 图标位置
    public var iconPosition: STIconPosition = .left

    /// 图标和文字之间的间距
    public var spacing: CGFloat = 8
    
    /// 开始链式调用配置
    /// 使用示例：
    /// ```
    /// button.configure()
    ///     .iconPosition(.right)
    ///     .spacing(12)
    ///     .done()
    /// ```
    /// - Returns: 构建器实例
    public func configure() -> STIconButtonBuilder {
        return STIconButtonBuilder(button: self)
    }
    
    /// 更新布局（当直接设置属性时使用）
    /// 使用示例：
    /// ```
    /// button.iconPosition = .right
    /// button.spacing = 12
    /// button.updateLayout()
    /// ```
    public func updateLayout() {
        self.setNeedsLayout()
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
        self.updateIconLayout()
    }

    private func updateIconLayout() {
        guard
            let imageSize = self.imageView?.intrinsicContentSize,
            let titleSize = self.titleLabel?.intrinsicContentSize
        else { return }
        let halfSpace = self.spacing / 2
        switch self.iconPosition {
        case .left:
            self.imageEdgeInsets = UIEdgeInsets(
                top: 0,
                left: -halfSpace,
                bottom: 0,
                right: halfSpace
            )
            self.titleEdgeInsets = UIEdgeInsets(
                top: 0,
                left: halfSpace,
                bottom: 0,
                right: -halfSpace
            )
        case .right:
            self.imageEdgeInsets = UIEdgeInsets(
                top: 0,
                left: titleSize.width + halfSpace,
                bottom: 0,
                right: -(titleSize.width + halfSpace)
            )
            self.titleEdgeInsets = UIEdgeInsets(
                top: 0,
                left: -(imageSize.width + halfSpace),
                bottom: 0,
                right: imageSize.width + halfSpace
            )
        case .top:
            self.imageEdgeInsets = UIEdgeInsets(
                top: -(titleSize.height + self.spacing),
                left: titleSize.width / 2,
                bottom: 0,
                right: -titleSize.width / 2
            )
            self.titleEdgeInsets = UIEdgeInsets(
                top: 0,
                left: -imageSize.width / 2,
                bottom: -(imageSize.height + self.spacing),
                right: imageSize.width / 2
            )
        case .bottom:
            self.imageEdgeInsets = UIEdgeInsets(
                top: 0,
                left: titleSize.width / 2,
                bottom: -(titleSize.height + self.spacing),
                right: -titleSize.width / 2
            )
            self.titleEdgeInsets = UIEdgeInsets(
                top: -(imageSize.height + self.spacing),
                left: -imageSize.width / 2,
                bottom: 0,
                right: imageSize.width / 2
            )
        }
    }
}
