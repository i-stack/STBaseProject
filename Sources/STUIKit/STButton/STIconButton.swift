//
//  STIconButton.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2019/10/14.
//

import UIKit

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
        self.button?.iconPosition = position
        return self
    }
    
    /// 设置图标和文字之间的间距
    /// - Parameter spacing: 间距值
    /// - Returns: 构建器实例，支持链式调用
    @discardableResult
    public func spacing(_ spacing: CGFloat) -> STIconButtonBuilder {
        self.button?.spacing = spacing
        return self
    }

    /// 设置按钮内容边距
    @discardableResult
    public func contentInsets(_ insets: UIEdgeInsets) -> STIconButtonBuilder {
        self.button?.iconContentInsets = insets
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
        self.button?.setNeedsLayout()
    }
}

// MARK: - 图标按钮类
open class STIconButton: STBtn {
    
    /// 图标位置
    public var iconPosition: STIconPosition = .left {
        didSet {
            guard oldValue != iconPosition else { return }
            self.invalidateIntrinsicContentSize()
            self.setNeedsLayout()
        }
    }

    /// 图标和文字之间的间距
    public var spacing: CGFloat = 8 {
        didSet {
            guard oldValue != spacing else { return }
            self.invalidateIntrinsicContentSize()
            self.setNeedsLayout()
        }
    }

    /// 图文整体内容边距
    public var iconContentInsets: UIEdgeInsets = .zero {
        didSet {
            guard oldValue != iconContentInsets else { return }
            self.invalidateIntrinsicContentSize()
            self.setNeedsLayout()
        }
    }

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
        self.invalidateIntrinsicContentSize()
        self.setNeedsLayout()
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
        self.updateIconLayout()
    }

    open override func contentRect(forBounds bounds: CGRect) -> CGRect {
        super.contentRect(forBounds: bounds).inset(by: self.iconContentInsets)
    }

    open override var intrinsicContentSize: CGSize {
        let baseSize = self.computedContentSize()
        return CGSize(
            width: baseSize.width + self.iconContentInsets.left + self.iconContentInsets.right,
            height: baseSize.height + self.iconContentInsets.top + self.iconContentInsets.bottom
        )
    }

    open override func sizeThatFits(_ size: CGSize) -> CGSize {
        let baseSize = self.computedContentSize()
        return CGSize(
            width: min(size.width, baseSize.width + self.iconContentInsets.left + self.iconContentInsets.right),
            height: min(size.height, baseSize.height + self.iconContentInsets.top + self.iconContentInsets.bottom)
        )
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

    private func computedContentSize() -> CGSize {
        let imageSize = self.imageView?.intrinsicContentSize ?? .zero
        let titleSize = self.titleLabel?.intrinsicContentSize ?? .zero
        let hasImage = imageSize != .zero
        let hasTitle = titleSize != .zero
        let actualSpacing = (hasImage && hasTitle) ? self.spacing : 0

        switch self.iconPosition {
        case .left, .right:
            return CGSize(
                width: imageSize.width + titleSize.width + actualSpacing,
                height: max(imageSize.height, titleSize.height)
            )
        case .top, .bottom:
            return CGSize(
                width: max(imageSize.width, titleSize.width),
                height: imageSize.height + titleSize.height + actualSpacing
            )
        }
    }
}
