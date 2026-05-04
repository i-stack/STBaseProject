//
//  STBtn.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2019/10/14.
//

import UIKit

private struct STBtnLocalizationKey {
    static var localizedTitleKey: UInt8 = 0
    static var localizedSelectedTitleKey: UInt8 = 1
}

public enum STBtnBackgroundStyle: Int {
    case normal = 0
    case gradient = 1
    case liquidGlass = 2
}

@IBDesignable
open class STBtn: UIButton {
    
    open var identifier: Any?
    
    private var gradientLayer: CAGradientLayer?
    private var gradientColors: [UIColor]?
    private var gradientStartPoint: CGPoint = CGPoint(x: 0, y: 0)
    private var gradientEndPoint: CGPoint = CGPoint(x: 1, y: 1)
    private var liquidGlassView: STLiquidGlassView?
    
    public var backgroundStyle: STBtnBackgroundStyle = .normal {
        didSet {
            guard oldValue != self.backgroundStyle else { return }
            self.updateBackgroundStyle()
        }
    }
    
    @IBInspectable open var backgroundStyleRaw: Int {
        get {
            return self.backgroundStyle.rawValue
        }
        set {
            guard let style = STBtnBackgroundStyle(rawValue: newValue) else { return }
            self.backgroundStyle = style
        }
    }
    
    @IBInspectable open var isLiquidGlassEnabled: Bool {
        get {
            return self.backgroundStyle == .liquidGlass
        }
        set {
            self.backgroundStyle = newValue ? .liquidGlass : .normal
        }
    }
    
    @IBInspectable open var liquidGlassTintColor: UIColor = UIColor.white.withAlphaComponent(0.18) {
        didSet {
            self.updateLiquidGlassAppearance()
        }
    }
    
    @IBInspectable open var liquidGlassHighlightOpacity: Float = 0.45 {
        didSet {
            self.updateLiquidGlassAppearance()
        }
    }
    
    @IBInspectable open var liquidGlassBorderColor: UIColor = UIColor.white.withAlphaComponent(0.45) {
        didSet {
            self.updateLiquidGlassAppearance()
        }
    }
    
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
    @IBInspectable open var stringIdentifier: String?
    
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
            self.updateGradientLayerCornerRadius()
            self.updateLiquidGlassCornerRadius()
        }
        get {
            return self.layer.cornerRadius
        }
    }
    
    @IBInspectable open var clipsContentToBounds: Bool {
        get {
            return self.layer.masksToBounds
        }
        set {
            self.layer.masksToBounds = newValue
        }
    }
    
    @IBInspectable open var borderColor: UIColor? {
        set {
            self.layer.borderColor = newValue?.cgColor
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
    
    open override var isHighlighted: Bool {
        didSet {
            self.updateLiquidGlassState(animated: true)
        }
    }
    
    open override var isEnabled: Bool {
        didSet {
            self.updateLiquidGlassState(animated: false)
        }
    }
    
    /// 内容水平对齐时的边距（IBInspectable）
    /// 当 contentHorizontalAlignment 为 .left/.right/.leading/.trailing 时，此属性在 `UIButton.Configuration.contentInsets` 之上叠加额外间距。
    @IBInspectable open var contentHorizontalPadding: CGFloat = 0 {
        didSet {
            guard oldValue != self.contentHorizontalPadding else { return }
            self.setNeedsUpdateConfiguration()
        }
    }

    open override var contentHorizontalAlignment: UIControl.ContentHorizontalAlignment {
        get { super.contentHorizontalAlignment }
        set {
            super.contentHorizontalAlignment = newValue
            self.setNeedsUpdateConfiguration()
        }
    }

    /// 基础 `contentInsets` 快照，在首次安装 Configuration 时捕获。
    /// 每次 `configurationUpdateHandler` 触发都会将 `contentInsets` 先重置为该快照，
    /// 再叠加水平 padding / 子类图标内边距，避免多次触发时增量累加（高亮、动态字体等会反复触发 update）。
    /// 若外部整体替换了 `self.configuration`，请调用 `refreshBaseContentInsets()` 同步新的基线。
    private var baseContentInsets: NSDirectionalEdgeInsets = .zero

    private func setupButton() {
        self.titleLabel?.adjustsFontForContentSizeCategory = true
        self.titleLabel?.textAlignment = .natural
        self.imageView?.contentMode = .scaleAspectFit
        self.installModernButtonConfiguration()
    }

    /// `contentEdgeInsets` 在启用 `UIButton.Configuration` 后被废弃（iOS 16 起全面迁移）；
    /// 通过 `configurationUpdateHandler` 在每次 update 中基于快照重算 `contentInsets`。
    private func installModernButtonConfiguration() {
        if self.configuration == nil {
            self.configuration = UIButton.Configuration.plain()
        }
        self.baseContentInsets = self.configuration?.contentInsets ?? .zero
        self.configurationUpdateHandler = { [weak self] button in
            guard let self, var config = button.configuration else { return }
            config.contentInsets = self.baseContentInsets
            self.refineButtonConfiguration(button, configuration: &config)
            button.configuration = config
        }
        self.setNeedsUpdateConfiguration()
    }

    /// 若外部替换了 `self.configuration`，调用此方法重新捕获基线以保证水平 padding / 图标内边距正确叠加。
    public func refreshBaseContentInsets() {
        self.baseContentInsets = self.configuration?.contentInsets ?? .zero
        self.setNeedsUpdateConfiguration()
    }

    /// 子类（如 `STIconBtn`）覆写以写入图文布局，再调用 `super` 叠加水平边距。
    /// 调用前 `config.contentInsets` 已被重置为 `baseContentInsets`，可直接做 `+=` 增量。
    open func refineButtonConfiguration(_ button: UIButton, configuration config: inout UIButton.Configuration) {
        let layoutDirection = UIView.userInterfaceLayoutDirection(for: button.semanticContentAttribute)
        let (extraLeading, extraTrailing) = self.horizontalPaddingExtras(layoutDirection: layoutDirection)
        var inset = config.contentInsets
        inset.leading += extraLeading
        inset.trailing += extraTrailing
        config.contentInsets = inset
    }

    private func horizontalPaddingExtras(layoutDirection: UIUserInterfaceLayoutDirection) -> (CGFloat, CGFloat) {
        guard self.contentHorizontalPadding > 0 else { return (0, 0) }
        let alignment = self.contentHorizontalAlignment
        let padding = self.contentHorizontalPadding
        switch alignment {
        case .left:
            return layoutDirection == .rightToLeft ? (0, padding) : (padding, 0)
        case .right:
            return layoutDirection == .rightToLeft ? (padding, 0) : (0, padding)
        case .leading:
            return (padding, 0)
        case .trailing:
            return (0, padding)
        default:
            return (0, 0)
        }
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
        self.updateGradientLayerFrame()
        self.updateLiquidGlassFrame()
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
        self.clipsContentToBounds = true
        self.borderWidth = borderWidth
        self.borderColor = borderColor
    }
    
    /// 设置渐变背景
    /// - Parameters:
    ///   - colors: 渐变色数组
    ///   - startPoint: 起始点
    ///   - endPoint: 结束点
    public func st_setGradientBackground(colors: [UIColor], startPoint: CGPoint = CGPoint(x: 0, y: 0), endPoint: CGPoint = CGPoint(x: 1, y: 1)) {
        self.gradientColors = colors
        self.gradientStartPoint = startPoint
        self.gradientEndPoint = endPoint
        self.backgroundStyle = .gradient
        self.updateBackgroundStyle()
    }
    
    public func st_setLiquidGlassBackground(
        tintColor: UIColor = UIColor.white.withAlphaComponent(0.18),
        highlightOpacity: Float = 0.45,
        borderColor: UIColor = UIColor.white.withAlphaComponent(0.45)
    ) {
        self.liquidGlassTintColor = tintColor
        self.liquidGlassHighlightOpacity = highlightOpacity
        self.liquidGlassBorderColor = borderColor
        self.backgroundStyle = .liquidGlass
        self.updateBackgroundStyle()
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
        guard let fontSize = self.titleLabel?.font.pointSize else { return }
        self.titleLabel?.font = UIFont.st_systemFont(ofSize: fontSize)
    }
    
    private func updateBackgroundStyle() {
        switch self.backgroundStyle {
        case .normal:
            self.removeGradientLayer()
            self.removeLiquidGlassView()
        case .gradient:
            self.removeLiquidGlassView()
            self.updateGradientLayer()
        case .liquidGlass:
            self.removeGradientLayer()
            self.updateLiquidGlassView()
        }
    }
    
    private func updateGradientLayer() {
        guard let colors = self.gradientColors else { return }
        let gradientLayer = self.gradientLayer ?? CAGradientLayer()
        gradientLayer.colors = colors.map { $0.cgColor }
        gradientLayer.startPoint = self.gradientStartPoint
        gradientLayer.endPoint = self.gradientEndPoint
        gradientLayer.frame = self.bounds
        gradientLayer.cornerRadius = self.layer.cornerRadius
        if gradientLayer.superlayer == nil {
            self.layer.insertSublayer(gradientLayer, at: 0)
        }
        self.gradientLayer = gradientLayer
    }
    
    private func removeGradientLayer() {
        self.gradientLayer?.removeFromSuperlayer()
        self.gradientLayer = nil
    }
    
    private func updateGradientLayerFrame() {
        guard let gradientLayer = self.gradientLayer else { return }
        gradientLayer.frame = self.bounds
        gradientLayer.cornerRadius = self.layer.cornerRadius
    }
    
    private func updateGradientLayerCornerRadius() {
        self.gradientLayer?.cornerRadius = self.layer.cornerRadius
    }
    
    private func updateLiquidGlassView() {
        let glassView = self.liquidGlassView ?? STLiquidGlassView()
        if glassView.superview == nil {
            self.insertSubview(glassView, at: 0)
        }
        self.liquidGlassView = glassView
        self.updateLiquidGlassFrame()
        self.updateLiquidGlassAppearance()
    }

    private func updateLiquidGlassFrame() {
        guard let glassView = self.liquidGlassView else { return }
        glassView.frame = self.bounds
        glassView.glassCornerRadius = self.layer.cornerRadius
        self.sendSubviewToBack(glassView)
    }
    
    private func updateLiquidGlassAppearance() {
        guard let glassView = self.liquidGlassView else { return }
        glassView.configure(
            tintColor: self.liquidGlassTintColor,
            highlightOpacity: self.liquidGlassHighlightOpacity,
            borderColor: self.liquidGlassBorderColor,
            cornerRadius: self.layer.cornerRadius
        )
        self.updateLiquidGlassState(animated: false)
    }
    
    private func updateLiquidGlassCornerRadius() {
        self.liquidGlassView?.glassCornerRadius = self.layer.cornerRadius
    }
    
    private func updateLiquidGlassState(animated: Bool) {
        guard let glassView = self.liquidGlassView else { return }
        let alpha: CGFloat
        if !self.isEnabled {
            alpha = 0.45
        } else if self.isHighlighted {
            alpha = 0.82
        } else {
            alpha = 1
        }
        glassView.setStateAlpha(alpha, animated: animated)
    }
    
    private func removeLiquidGlassView() {
        self.liquidGlassView?.removeFromSuperview()
        self.liquidGlassView = nil
    }
}
