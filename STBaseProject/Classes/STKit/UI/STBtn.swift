//
//  STBtn.swift
//  STBaseProject
//
//  Created by stack on 2019/10/14.
//

import UIKit

// MARK: - 按钮本地化常量
private struct STBtnLocalizationKey {
    static var localizedTitleKey: UInt8 = 0
    static var localizedSelectedTitleKey: UInt8 = 1
}

// MARK: - 按钮布局样式枚举
public enum STBtnEdgeInsetsStyle {
    case top    // 图片在上，文字在下
    case left   // 图片在左，文字在右
    case right  // 图片在右，文字在左
    case bottom // 图片在下，文字在上
    case reset  // 恢复默认布局
}

// MARK: - 按钮间距配置
public struct STBtnSpacing {
    public var spacing: CGFloat = 0
    public var topSpacing: CGFloat?
    public var leftSpacing: CGFloat?
    public var rightSpacing: CGFloat?
    public var bottomSpacing: CGFloat?
    
    public init() {}
    
    public init(spacing: CGFloat) {
        self.spacing = spacing
    }
    
    public init(spacing: CGFloat, topSpacing: CGFloat? = nil, leftSpacing: CGFloat? = nil, rightSpacing: CGFloat? = nil, bottomSpacing: CGFloat? = nil) {
        self.spacing = spacing
        self.topSpacing = topSpacing
        self.leftSpacing = leftSpacing
        self.rightSpacing = rightSpacing
        self.bottomSpacing = bottomSpacing
    }
}

// MARK: - 自定义按钮类
/// 自定义按钮类，支持图片和文字的不同位置布局以及圆角设置
open class STBtn: UIButton {
    
    // MARK: - 属性
    open var identifier: Any?
    
    private var hasSetLayout: Bool = false
    private var defaultTitleFrame: CGRect = .zero
    private var defaultImageFrame: CGRect = .zero
    private var style: STBtnEdgeInsetsStyle = .reset
    private var btnSpacing: STBtnSpacing = STBtnSpacing()
    
    // MARK: - IBInspectable 属性
    /// 本地化标题键（支持 Storyboard 设置，支持动态语言切换）
    @IBInspectable open var localizedTitle: String {
        get {
            return objc_getAssociatedObject(self, &STBtnLocalizationKey.localizedTitleKey) as? String ?? ""
        }
        set {
            objc_setAssociatedObject(self, &STBtnLocalizationKey.localizedTitleKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            self.setTitle(newValue.localized, for: .normal)
        }
    }
    
    /// 本地化选中状态标题键（支持 Storyboard 设置，支持动态语言切换）
    @IBInspectable open var localizedSelectedTitle: String {
        get {
            return objc_getAssociatedObject(self, &STBtnLocalizationKey.localizedSelectedTitleKey) as? String ?? ""
        }
        set {
            objc_setAssociatedObject(self, &STBtnLocalizationKey.localizedSelectedTitleKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            self.setTitle(newValue.localized, for: .selected)
        }
    }
    
    /// 边框宽度
    @IBInspectable open var borderWidth: CGFloat {
        set {
            layer.borderWidth = newValue
        }
        get {
            return layer.borderWidth
        }
    }
    
    /// 圆角半径
    @IBInspectable open var cornerRadius: CGFloat {
        set {
            layer.cornerRadius = newValue
            layer.masksToBounds = newValue > 0
        }
        get {
            return layer.cornerRadius
        }
    }
    
    /// 边框颜色
    @IBInspectable open var borderColor: UIColor? {
        set {
            guard let uiColor = newValue else { return }
            layer.borderColor = uiColor.cgColor
        }
        get {
            guard let color = layer.borderColor else { return nil }
            return UIColor(cgColor: color)
        }
    }
    
    /// 是否自动适配字体大小
    @IBInspectable open var autoAdaptFontSize: Bool = true {
        didSet {
            if autoAdaptFontSize {
                updateFontSize()
            }
        }
    }
    
    // MARK: - 初始化
    override public init(frame: CGRect) {
        super.init(frame: frame)
        setupButton()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupButton()
    }
    
    // MARK: - 设置
    private func setupButton() {
        titleLabel?.textAlignment = .center
        imageView?.contentMode = .scaleAspectFit
        if autoAdaptFontSize {
            updateFontSize()
        }
    }
    
    // MARK: - 布局
    open override func layoutSubviews() {
        super.layoutSubviews()
        
        guard let titleLabel = self.titleLabel,
              let imageView = self.imageView,
              self.hasSetLayout else { return }
        
        // 保存默认布局
        if self.defaultTitleFrame == .zero {
            self.defaultTitleFrame = titleLabel.frame
            self.defaultImageFrame = imageView.frame
        }
        
        // 根据样式重新布局
        switch self.style {
        case .top:
            layoutImageTopTitleBottom(titleLabel: titleLabel, imageView: imageView)
        case .left:
            layoutImageLeftTitleRight(titleLabel: titleLabel, imageView: imageView)
        case .right:
            layoutImageRightTitleLeft(titleLabel: titleLabel, imageView: imageView)
        case .bottom:
            layoutImageBottomTitleTop(titleLabel: titleLabel, imageView: imageView)
        case .reset:
            titleLabel.frame = self.defaultTitleFrame
            imageView.frame = self.defaultImageFrame
        }
    }
    
    // MARK: - 布局方法
    private func layoutImageTopTitleBottom(titleLabel: UILabel, imageView: UIImageView) {
        let titleWidth = titleLabel.intrinsicContentSize.width
        let imageWidth = imageView.intrinsicContentSize.width
        let totalWidth = self.bounds.width
        let spacing = self.btnSpacing.spacing
        let topSpacing = self.btnSpacing.topSpacing ?? 0
        
        // 图片居中
        imageView.frame = CGRect(
            x: (totalWidth - imageWidth) / 2,
            y: topSpacing,
            width: imageWidth,
            height: imageView.frame.height
        )
        
        // 文字居中，在图片下方
        titleLabel.frame = CGRect(
            x: (totalWidth - titleWidth) / 2,
            y: imageView.frame.maxY + spacing,
            width: titleWidth,
            height: titleLabel.frame.height
        )
    }
    
    private func layoutImageLeftTitleRight(titleLabel: UILabel, imageView: UIImageView) {
        let titleWidth = titleLabel.intrinsicContentSize.width
        let imageWidth = imageView.intrinsicContentSize.width
        let totalWidth = self.bounds.width
        let spacing = self.btnSpacing.spacing
        
        let (imageViewX, titleLabelX) = calculateHorizontalPositions(
            totalWidth: totalWidth,
            imageWidth: imageWidth,
            titleWidth: titleWidth,
            spacing: spacing,
            imageFirst: true
        )
        
        titleLabel.frame = CGRect(
            x: titleLabelX,
            y: titleLabel.frame.origin.y,
            width: titleWidth,
            height: titleLabel.frame.height
        )
        
        imageView.frame = CGRect(
            x: imageViewX,
            y: imageView.frame.origin.y,
            width: imageWidth,
            height: imageView.frame.height
        )
    }
    
    private func layoutImageRightTitleLeft(titleLabel: UILabel, imageView: UIImageView) {
        let titleWidth = titleLabel.intrinsicContentSize.width
        let imageWidth = imageView.intrinsicContentSize.width
        let totalWidth = self.bounds.width
        let spacing = self.btnSpacing.spacing
        
        let (titleLabelX, imageViewX) = calculateHorizontalPositions(
            totalWidth: totalWidth,
            imageWidth: imageWidth,
            titleWidth: titleWidth,
            spacing: spacing,
            imageFirst: false
        )
        
        titleLabel.frame = CGRect(
            x: titleLabelX,
            y: titleLabel.frame.origin.y,
            width: titleWidth,
            height: titleLabel.frame.height
        )
        
        imageView.frame = CGRect(
            x: imageViewX,
            y: imageView.frame.origin.y,
            width: imageWidth,
            height: imageView.frame.height
        )
    }
    
    private func layoutImageBottomTitleTop(titleLabel: UILabel, imageView: UIImageView) {
        let titleWidth = titleLabel.intrinsicContentSize.width
        let imageWidth = imageView.intrinsicContentSize.width
        let totalWidth = self.bounds.width
        let spacing = self.btnSpacing.spacing
        let topSpacing = self.btnSpacing.topSpacing ?? 0
        
        // 文字居中
        titleLabel.frame = CGRect(
            x: (totalWidth - titleWidth) / 2,
            y: topSpacing,
            width: titleWidth,
            height: titleLabel.frame.height
        )
        
        // 图片居中，在文字下方
        imageView.frame = CGRect(
            x: (totalWidth - imageWidth) / 2,
            y: titleLabel.frame.maxY + spacing,
            width: imageWidth,
            height: imageView.frame.height
        )
    }
    
    // MARK: - 辅助方法
    private func calculateHorizontalPositions(
        totalWidth: CGFloat,
        imageWidth: CGFloat,
        titleWidth: CGFloat,
        spacing: CGFloat,
        imageFirst: Bool
    ) -> (CGFloat, CGFloat) {
        let leftSpacing = self.btnSpacing.leftSpacing
        let rightSpacing = self.btnSpacing.rightSpacing
        
        if let leftSpacing = leftSpacing, let rightSpacing = rightSpacing {
            // 左右间距都指定
            if imageFirst {
                let imageViewX = leftSpacing
                let titleLabelX = totalWidth - titleWidth - rightSpacing
                return (imageViewX, titleLabelX)
            } else {
                let titleLabelX = leftSpacing
                let imageViewX = totalWidth - imageWidth - rightSpacing
                return (titleLabelX, imageViewX)
            }
        } else if let leftSpacing = leftSpacing {
            // 只指定左间距
            if imageFirst {
                let imageViewX = leftSpacing
                let titleLabelX = imageViewX + imageWidth + spacing
                return (imageViewX, titleLabelX)
            } else {
                let titleLabelX = leftSpacing
                let imageViewX = titleLabelX + titleWidth + spacing
                return (titleLabelX, imageViewX)
            }
        } else if let rightSpacing = rightSpacing {
            // 只指定右间距
            if imageFirst {
                let titleLabelX = totalWidth - rightSpacing - titleWidth
                let imageViewX = titleLabelX - spacing - imageWidth
                return (imageViewX, titleLabelX)
            } else {
                let imageViewX = totalWidth - imageWidth - rightSpacing
                let titleLabelX = imageViewX - spacing - titleWidth
                return (titleLabelX, imageViewX)
            }
        } else {
            // 居中布局
            let centerX = (totalWidth - titleWidth - imageWidth - spacing) / 2
            if imageFirst {
                let imageViewX = centerX
                let titleLabelX = imageViewX + imageWidth + spacing
                return (imageViewX, titleLabelX)
            } else {
                let titleLabelX = centerX
                let imageViewX = titleLabelX + titleWidth + spacing
                return (titleLabelX, imageViewX)
            }
        }
    }
    
    // MARK: - 公共方法
    /// 设置按钮布局样式和间距
    /// - Parameters:
    ///   - style: 布局样式
    ///   - spacing: 间距配置
    public func st_layoutButtonWithEdgeInsets(style: STBtnEdgeInsetsStyle, spacing: STBtnSpacing) {
        self.style = style
        self.btnSpacing = spacing
        self.hasSetLayout = true
        self.setNeedsLayout()
    }
    
    /// 设置圆角按钮
    /// - Parameter cornerRadius: 圆角半径
    public func st_roundedButton(cornerRadius: CGFloat) {
        self.st_roundedButton(cornerRadius: cornerRadius, borderWidth: 0, borderColor: UIColor.clear)
    }
    
    /// 设置圆角按钮
    /// - Parameters:
    ///   - cornerRadius: 圆角半径
    ///   - borderWidth: 边框宽度
    ///   - borderColor: 边框颜色
    public func st_roundedButton(cornerRadius: CGFloat, borderWidth: CGFloat, borderColor: UIColor) {
        self.cornerRadius = cornerRadius
        self.borderWidth = borderWidth
        self.borderColor = borderColor
    }
    
    /// 设置渐变背景
    /// - Parameters:
    ///   - colors: 渐变色数组
    ///   - startPoint: 起始点
    ///   - endPoint: 结束点
    public func st_setGradientBackground(colors: [UIColor], startPoint: CGPoint = CGPoint(x: 0, y: 0), endPoint: CGPoint = CGPoint(x: 1, y: 1)) {
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = bounds
        gradientLayer.colors = colors.map { $0.cgColor }
        gradientLayer.startPoint = startPoint
        gradientLayer.endPoint = endPoint
        
        // 移除之前的渐变层
        layer.sublayers?.removeAll { $0 is CAGradientLayer }
        layer.insertSublayer(gradientLayer, at: 0)
    }
    
    /// 设置阴影
    /// - Parameters:
    ///   - color: 阴影颜色
    ///   - offset: 阴影偏移
    ///   - radius: 阴影半径
    ///   - opacity: 阴影透明度
    public override func st_setShadow(color: UIColor = .black, offset: CGSize = CGSize(width: 0, height: 2), radius: CGFloat = 4, opacity: Float = 0.3) {
        layer.shadowColor = color.cgColor
        layer.shadowOffset = offset
        layer.shadowRadius = radius
        layer.shadowOpacity = opacity
        layer.masksToBounds = false
    }
    
    /// 重置为默认布局
    public func st_resetLayout() {
        self.style = .reset
        self.hasSetLayout = false
        self.defaultTitleFrame = .zero
        self.defaultImageFrame = .zero
        self.setNeedsLayout()
    }
    
    /// 更新本地化文本
    public func st_updateLocalizedText() {
        if !localizedTitle.isEmpty {
            self.setTitle(localizedTitle.localized, for: .normal)
        }
        if !localizedSelectedTitle.isEmpty {
            self.setTitle(localizedSelectedTitle.localized, for: .selected)
        }
    }
    
    // MARK: - 私有方法
    private func updateFontSize() {
        guard let fontName = self.titleLabel?.font.fontName,
              let fontSize = self.titleLabel?.font.pointSize else { return }
        
        self.titleLabel?.font = UIFont.st_systemFont(ofSize: fontSize, fontName: fontName)
    }
}

// MARK: - 便捷扩展
public extension STBtn {
    
    /// 快速设置图片在上、文字在下的布局
    /// - Parameter spacing: 图片和文字之间的间距
    func st_setImageTopTitleBottom(spacing: CGFloat = 8) {
        let btnSpacing = STBtnSpacing(spacing: spacing)
        st_layoutButtonWithEdgeInsets(style: .top, spacing: btnSpacing)
    }
    
    /// 快速设置图片在左、文字在右的布局
    /// - Parameter spacing: 图片和文字之间的间距
    func st_setImageLeftTitleRight(spacing: CGFloat = 8) {
        let btnSpacing = STBtnSpacing(spacing: spacing)
        st_layoutButtonWithEdgeInsets(style: .left, spacing: btnSpacing)
    }
    
    /// 快速设置图片在右、文字在左的布局
    /// - Parameter spacing: 图片和文字之间的间距
    func st_setImageRightTitleLeft(spacing: CGFloat = 8) {
        let btnSpacing = STBtnSpacing(spacing: spacing)
        st_layoutButtonWithEdgeInsets(style: .right, spacing: btnSpacing)
    }
    
    /// 快速设置图片在下、文字在上的布局
    /// - Parameter spacing: 图片和文字之间的间距
    func st_setImageBottomTitleTop(spacing: CGFloat = 8) {
        let btnSpacing = STBtnSpacing(spacing: spacing)
        st_layoutButtonWithEdgeInsets(style: .bottom, spacing: btnSpacing)
    }
}
