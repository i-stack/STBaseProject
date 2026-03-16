//
//  STBtn.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2019/10/14.
//

import UIKit

// MARK: - 按钮本地化常量
private struct STBtnLocalizationKey {
    static var localizedTitleKey: UInt8 = 0
    static var localizedSelectedTitleKey: UInt8 = 1
}

// MARK: - 自定义按钮类
open class STBtn: UIButton {
    
    open var identifier: Any?
    
    /// 字符串标识符（类型安全，推荐使用）
    /// 使用示例：
    /// ```
    /// button.stringIdentifier = "home_button"
    /// if button.stringIdentifier == "home_button" { ... }
    /// ```
    /// 注意：对于整数标识符，请使用 `tag` 属性：
    /// ```
    /// button.tag = 100
    /// if button.tag == 100 { ... }
    /// ```
    open var stringIdentifier: String?
    
    /// 类型安全的标识符访问（泛型方法）
    /// 使用示例：
    /// ```
    /// button.setIdentifier(STAlertBtnClickType.leftBtnClick)
    /// if let type: STAlertBtnClickType = button.getIdentifier() {
    ///     // 使用 type
    /// }
    /// ```
    /// - Parameter value: 要设置的标识符值
    public func setIdentifier<T>(_ value: T) {
        self.identifier = value
    }
    
    /// 类型安全的标识符获取（泛型方法）
    /// - Returns: 转换后的标识符值，如果类型不匹配则返回 nil
    public func getIdentifier<T>() -> T? {
        return self.identifier as? T
    }
    
    @IBInspectable open var localizedTitle: String {
        get {
            return objc_getAssociatedObject(self, &STBtnLocalizationKey.localizedTitleKey) as? String ?? ""
        }
        set {
            objc_setAssociatedObject(self, &STBtnLocalizationKey.localizedTitleKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            self.setTitle(newValue.localized, for: .normal)
        }
    }
    
    @IBInspectable open var localizedSelectedTitle: String {
        get {
            return objc_getAssociatedObject(self, &STBtnLocalizationKey.localizedSelectedTitleKey) as? String ?? ""
        }
        set {
            objc_setAssociatedObject(self, &STBtnLocalizationKey.localizedSelectedTitleKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            self.setTitle(newValue.localized, for: .selected)
        }
    }
    
    @IBInspectable open var borderWidth: CGFloat {
        set {
            self.layer.borderWidth = newValue
        }
        get {
            return self.layer.borderWidth
        }
    }
    
    @IBInspectable open var cornerRadius: CGFloat {
        set {
            self.layer.cornerRadius = newValue
            self.layer.masksToBounds = newValue > 0
        }
        get {
            return self.layer.cornerRadius
        }
    }
    
    @IBInspectable open var borderColor: UIColor? {
        set {
            guard let uiColor = newValue else { return }
            self.layer.borderColor = uiColor.cgColor
        }
        get {
            guard let color = self.layer.borderColor else { return nil }
            return UIColor(cgColor: color)
        }
    }
    
    @IBInspectable open var autoAdaptFontSize: Bool = true {
        didSet {
            if self.autoAdaptFontSize {
                self.updateFontSize()
            }
        }
    }
    
    /// 高亮时是否自动调整图片（IBInspectable）
    /// 当为 true 时，按钮高亮时会自动调整图片的亮度
    @IBInspectable open override var adjustsImageWhenHighlighted: Bool {
        get {
            return super.adjustsImageWhenHighlighted
        }
        set {
            super.adjustsImageWhenHighlighted = newValue
        }
    }
    
    /// 禁用时是否自动调整图片（IBInspectable）
    /// 当为 true 时，按钮禁用时会自动调整图片的亮度
    @IBInspectable open override var adjustsImageWhenDisabled: Bool {
        get {
            return super.adjustsImageWhenDisabled
        }
        set {
            super.adjustsImageWhenDisabled = newValue
        }
    }
    
    /// 高亮时是否显示触摸效果（IBInspectable）
    /// 当为 true 时，按钮高亮时会显示一个圆形的高亮效果
    @IBInspectable open override var showsTouchWhenHighlighted: Bool {
        get {
            return super.showsTouchWhenHighlighted
        }
        set {
            super.showsTouchWhenHighlighted = newValue
        }
    }
    
    /// 阴影颜色（IBInspectable）
    @IBInspectable open var shadowColor: UIColor? {
        get {
            guard let cgColor = self.layer.shadowColor else { return nil }
            return UIColor(cgColor: cgColor)
        }
        set {
            self.layer.shadowColor = newValue?.cgColor
        }
    }
    
    /// 阴影偏移宽度（IBInspectable）
    @IBInspectable open var shadowOffsetWidth: CGFloat {
        get {
            return self.layer.shadowOffset.width
        }
        set {
            self.layer.shadowOffset = CGSize(width: newValue, height: self.layer.shadowOffset.height)
        }
    }
    
    /// 阴影偏移高度（IBInspectable）
    @IBInspectable open var shadowOffsetHeight: CGFloat {
        get {
            return self.layer.shadowOffset.height
        }
        set {
            self.layer.shadowOffset = CGSize(width: self.layer.shadowOffset.width, height: newValue)
        }
    }
    
    /// 阴影半径（IBInspectable）
    @IBInspectable open var shadowRadius: CGFloat {
        get {
            return self.layer.shadowRadius
        }
        set {
            self.layer.shadowRadius = newValue
        }
    }
    
    /// 阴影透明度（IBInspectable，范围 0.0-1.0）
    @IBInspectable open var shadowOpacity: Float {
        get {
            return self.layer.shadowOpacity
        }
        set {
            self.layer.shadowOpacity = newValue
        }
    }
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        self.setupButton()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setupButton()
    }
    
    /// 内容水平对齐时的边距（IBInspectable）
    /// 当 contentHorizontalAlignment 为 .left 或 .right 时，此属性控制内容与边缘的间距
    /// 使用示例：
    /// ```
    /// button.contentHorizontalAlignment = .left
    /// button.contentHorizontalPadding = 16  // 左边距 16
    /// ```
    /// 注意：布局更新会在下一个布局周期自动生效，无需手动调用 `setNeedsLayout()`
    /// `layoutSubviews` 方法会在系统需要时自动调用，并更新边距
    @IBInspectable open var contentHorizontalPadding: CGFloat = 0
    
    private func setupButton() {
        self.titleLabel?.adjustsFontForContentSizeCategory = true
        self.titleLabel?.textAlignment = .natural
        self.imageView?.contentMode = .scaleAspectFit
        if self.autoAdaptFontSize {
            self.updateFontSize()
        }
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        self.updateContentHorizontalPadding()
    }
    
    /// 更新内容水平对齐时的边距
    private func updateContentHorizontalPadding() {
        guard self.contentHorizontalPadding > 0 else {
            // 如果边距为 0，清除水平方向的边距，保留垂直方向的边距
            let currentInsets = self.contentEdgeInsets
            if currentInsets.left != 0 || currentInsets.right != 0 {
                self.contentEdgeInsets = UIEdgeInsets(
                    top: currentInsets.top,
                    left: 0,
                    bottom: currentInsets.bottom,
                    right: 0
                )
            }
            return
        }
        
        // 保存当前的垂直边距
        let currentInsets = self.contentEdgeInsets
        let top = currentInsets.top
        let bottom = currentInsets.bottom
        
        // 根据 contentHorizontalAlignment 设置水平边距
        switch self.contentHorizontalAlignment {
        case .left:
            // 左对齐时，只设置左边距
            self.contentEdgeInsets = UIEdgeInsets(
                top: top,
                left: self.contentHorizontalPadding,
                bottom: bottom,
                right: 0
            )
        case .right:
            // 右对齐时，只设置右边距
            self.contentEdgeInsets = UIEdgeInsets(
                top: top,
                left: 0,
                bottom: bottom,
                right: self.contentHorizontalPadding
            )
        case .leading:
            // Leading 对齐时，根据布局方向设置
            if UIView.userInterfaceLayoutDirection(for: self.semanticContentAttribute) == .rightToLeft {
                // RTL 布局，设置右边距
                self.contentEdgeInsets = UIEdgeInsets(
                    top: top,
                    left: 0,
                    bottom: bottom,
                    right: self.contentHorizontalPadding
                )
            } else {
                // LTR 布局，设置左边距
                self.contentEdgeInsets = UIEdgeInsets(
                    top: top,
                    left: self.contentHorizontalPadding,
                    bottom: bottom,
                    right: 0
                )
            }
        case .trailing:
            // Trailing 对齐时，根据布局方向设置
            if UIView.userInterfaceLayoutDirection(for: self.semanticContentAttribute) == .rightToLeft {
                // RTL 布局，设置左边距
                self.contentEdgeInsets = UIEdgeInsets(
                    top: top,
                    left: self.contentHorizontalPadding,
                    bottom: bottom,
                    right: 0
                )
            } else {
                // LTR 布局，设置右边距
                self.contentEdgeInsets = UIEdgeInsets(
                    top: top,
                    left: 0,
                    bottom: bottom,
                    right: self.contentHorizontalPadding
                )
            }
        default:
            // 居中对齐等其他情况，清除水平边距
            if currentInsets.left != 0 || currentInsets.right != 0 {
                self.contentEdgeInsets = UIEdgeInsets(
                    top: top,
                    left: 0,
                    bottom: bottom,
                    right: 0
                )
            }
        }
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
        self.layer.sublayers?.removeAll { $0 is CAGradientLayer }
        self.layer.insertSublayer(gradientLayer, at: 0)
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
    
    private func updateFontSize() {
        guard let fontName = self.titleLabel?.font.fontName,
              let fontSize = self.titleLabel?.font.pointSize else { return }
        self.titleLabel?.font = UIFont.st_font(name: fontName, size: fontSize)
    }
}
