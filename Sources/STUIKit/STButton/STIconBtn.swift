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
        var newImageInsets = UIEdgeInsets.zero
        var newTitleInsets = UIEdgeInsets.zero
        defer {
            if self.imageEdgeInsets != newImageInsets { self.imageEdgeInsets = newImageInsets }
            if self.titleEdgeInsets != newTitleInsets { self.titleEdgeInsets = newTitleInsets }
        }
        guard
            let imageSize = self.currentImageSize(),
            let titleSize = self.currentTitleSize()
        else { return }
        let halfSpace = self.spacing / 2
        switch self.iconPosition {
        case .left:
            newImageInsets = UIEdgeInsets(top: 0, left: -halfSpace, bottom: 0, right: halfSpace)
            newTitleInsets = UIEdgeInsets(top: 0, left: halfSpace, bottom: 0, right: -halfSpace)
        case .right:
            newImageInsets = UIEdgeInsets(top: 0, left: titleSize.width + halfSpace, bottom: 0, right: -(titleSize.width + halfSpace))
            newTitleInsets = UIEdgeInsets(top: 0, left: -(imageSize.width + halfSpace), bottom: 0, right: imageSize.width + halfSpace)
        case .top:
            newImageInsets = UIEdgeInsets(top: -(titleSize.height + self.spacing), left: titleSize.width / 2, bottom: 0, right: -titleSize.width / 2)
            newTitleInsets = UIEdgeInsets(top: 0, left: -imageSize.width / 2, bottom: -(imageSize.height + self.spacing), right: imageSize.width / 2)
        case .bottom:
            newImageInsets = UIEdgeInsets(top: 0, left: titleSize.width / 2, bottom: -(titleSize.height + self.spacing), right: -titleSize.width / 2)
            newTitleInsets = UIEdgeInsets(top: -(imageSize.height + self.spacing), left: -imageSize.width / 2, bottom: 0, right: imageSize.width / 2)
        }
    }

    private func computedContentSize() -> CGSize {
        let imageSize = self.currentImageSize() ?? .zero
        let titleSize = self.currentTitleSize() ?? .zero
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
    
    private func currentImageSize() -> CGSize? {
        guard self.currentImage != nil else { return nil }
        let imageSize = self.imageView?.intrinsicContentSize ?? .zero
        return imageSize == .zero ? nil : imageSize
    }
    
    private func currentTitleSize() -> CGSize? {
        let hasTitle = !(self.currentTitle?.isEmpty ?? true) || self.currentAttributedTitle != nil
        guard hasTitle else { return nil }
        let titleSize = self.titleLabel?.intrinsicContentSize ?? .zero
        return titleSize == .zero ? nil : titleSize
    }
}
