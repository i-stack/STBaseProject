//
//  STIconBtn.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2019/10/14.
//

import UIKit

public enum STIconPosition: Int {
    case left = 0
    case right = 1
    case top = 2
    case bottom = 3
}

public class STIconBtnBuilder {
    
    private weak var button: STIconBtn?
    
    init(button: STIconBtn) {
        self.button = button
    }
    
    /// 设置图标位置
    /// - Parameter position: 图标位置
    /// - Returns: 构建器实例，支持链式调用
    @discardableResult
    public func iconPosition(_ position: STIconPosition) -> STIconBtnBuilder {
        self.button?.iconPosition = position
        return self
    }
    
    /// 设置图标和文字之间的间距
    /// - Parameter spacing: 间距值
    /// - Returns: 构建器实例，支持链式调用
    @discardableResult
    public func spacing(_ spacing: CGFloat) -> STIconBtnBuilder {
        self.button?.spacing = spacing
        return self
    }

    /// 设置按钮内容边距
    @discardableResult
    public func contentInsets(_ insets: UIEdgeInsets) -> STIconBtnBuilder {
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
@IBDesignable
open class STIconBtn: STBtn {
    
    /// 图标位置
    public var iconPosition: STIconPosition = .left {
        didSet {
            guard oldValue != iconPosition else { return }
            self.invalidateIntrinsicContentSize()
            self.setNeedsUpdateConfiguration()
        }
    }

    /// 图标和文字之间的间距
    public var spacing: CGFloat = 8 {
        didSet {
            guard oldValue != spacing else { return }
            self.invalidateIntrinsicContentSize()
            self.setNeedsUpdateConfiguration()
        }
    }

    /// 图文整体内容边距
    public var iconContentInsets: UIEdgeInsets = .zero {
        didSet {
            guard oldValue != iconContentInsets else { return }
            self.invalidateIntrinsicContentSize()
            self.setNeedsUpdateConfiguration()
        }
    }
    
    /// xib 中配置图标位置：0 左、1 右、2 上、3 下
    @IBInspectable open var iconPositionRaw: Int {
        get {
            return self.iconPosition.rawValue
        }
        set {
            guard let position = STIconPosition(rawValue: newValue) else { return }
            self.iconPosition = position
        }
    }
    
    @IBInspectable open var iconSpacing: CGFloat {
        get {
            return self.spacing
        }
        set {
            self.spacing = newValue
        }
    }
    
    @IBInspectable open var iconContentInsetTop: CGFloat {
        get {
            return self.iconContentInsets.top
        }
        set {
            self.iconContentInsets.top = newValue
        }
    }
    
    @IBInspectable open var iconContentInsetLeft: CGFloat {
        get {
            return self.iconContentInsets.left
        }
        set {
            self.iconContentInsets.left = newValue
        }
    }
    
    @IBInspectable open var iconContentInsetBottom: CGFloat {
        get {
            return self.iconContentInsets.bottom
        }
        set {
            self.iconContentInsets.bottom = newValue
        }
    }
    
    @IBInspectable open var iconContentInsetRight: CGFloat {
        get {
            return self.iconContentInsets.right
        }
        set {
            self.iconContentInsets.right = newValue
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
    public func configure() -> STIconBtnBuilder {
        return STIconBtnBuilder(button: self)
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
        self.setNeedsUpdateConfiguration()
    }

    open override func refineButtonConfiguration(_ button: UIButton, configuration config: inout UIButton.Configuration) {
        let icon = self.iconContentInsets
        var inset = config.contentInsets
        inset.top += icon.top
        inset.bottom += icon.bottom
        inset.leading += icon.left
        inset.trailing += icon.right
        config.contentInsets = inset

        let hasImage = self.currentImage != nil
        let hasTitle = !(self.currentTitle?.isEmpty ?? true) || self.currentAttributedTitle != nil
        switch self.iconPosition {
        case .left:
            config.imagePlacement = .leading
        case .right:
            config.imagePlacement = .trailing
        case .top:
            config.imagePlacement = .top
        case .bottom:
            config.imagePlacement = .bottom
        }
        config.imagePadding = (hasImage && hasTitle) ? self.spacing : 0

        super.refineButtonConfiguration(button, configuration: &config)
    }
}
