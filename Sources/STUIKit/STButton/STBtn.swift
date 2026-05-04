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
    
    /// 通用标识符，已废弃。
    /// `Any?` 无法提供类型安全、也无法稳定契约化。请改用：
    /// - 字符串标识：`stringIdentifier`
    /// - 整数标识：`tag`（UIKit 原生）
    /// - 无障碍/UI 测试标识：`accessibilityIdentifier`
    @available(*, deprecated, message: "Use stringIdentifier, tag, or accessibilityIdentifier instead.")
    open var identifier: Any?
    
    private var gradientLayer: CAGradientLayer?
    private var gradientColors: [UIColor]?
    private var gradientStartPoint: CGPoint = CGPoint(x: 0, y: 0)
    private var gradientEndPoint: CGPoint = CGPoint(x: 1, y: 1)
    private var liquidGlassView: STLiquidGlassView?
    /// 按 `UIControl.State.rawValue` 存储的 Configuration 背景色，由 `st_setBackgroundColor(_:for:)` 维护。
    private var stateBackgroundColors: [UInt: UIColor] = [:]
    
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
    
    /// 传入 Localization **key**，setter 通过 `String.localized` 扩展立即解析为当前语言文案并写入 `.normal` title。
    ///
    /// 行为说明：
    /// - 传入值是 key（会查 `Localizable.strings`），不是最终文案；
    /// - 原始 key 通过关联对象保存，可通过 getter 回读；
    /// - 解析发生在赋值时刻，**不会自动响应运行时语言切换**；如需切换语言后刷新，请重新赋值或在语言切换通知中再次调用。
    @IBInspectable open var localizedTitle: String {
        get {
            return objc_getAssociatedObject(self, &STBtnLocalizationKey.localizedTitleKey) as? String ?? ""
        }
        set {
            objc_setAssociatedObject(self, &STBtnLocalizationKey.localizedTitleKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            self.setTitle(newValue.localized, for: .normal)
        }
    }

    /// 传入 Localization **key**，setter 通过 `String.localized` 扩展立即解析为当前语言文案并写入 `.selected` title。
    /// 行为与 `localizedTitle` 一致，**不会自动响应运行时语言切换**。
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
            self.setNeedsUpdateConfiguration()
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
    
    /// 是否将 `titleLabel.font` 替换为项目级字体 `UIFont.st_systemFont(ofSize:)`。
    ///
    /// ⚠️ 命名保留是为向后兼容，**不是 `adjustsFontSizeToFitWidth` 语义的自动缩放**：
    /// 它只在开启时读取当前字号、用项目字体重建一个同字号的 `UIFont`，用于统一品牌字体。
    /// 如需"文本自动缩放以适配宽度"，请另设 `titleLabel?.adjustsFontSizeToFitWidth` 与 `minimumScaleFactor`。
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

    /// 基础 `contentInsets` 快照，在首次安装 Configuration 或检测到外部变更 Configuration 时自动刷新。
    /// 每次 `configurationUpdateHandler` 触发都会将 `contentInsets` 先重置为该快照，
    /// 再叠加水平 padding / 子类图标内边距，避免多次触发时增量累加（高亮、动态字体等会反复触发 update）。
    private var baseContentInsets: NSDirectionalEdgeInsets = .zero

    /// 上一次 handler 写回 `button.configuration` 时实际使用的 `contentInsets`。
    /// 下一次 update 到来时若 `config.contentInsets` 与此值不一致，说明外部替换了 configuration，
    /// 自动把 `baseContentInsets` 重捕获为新值，免去调用方手动 `refreshBaseContentInsets()`。
    private var lastAppliedContentInsets: NSDirectionalEdgeInsets?

    /// 外部扩展点：每次 Configuration 更新时在 STBtn 内部逻辑 **之后** 调用，
    /// 允许调用方追加字段调整而不必直接接管 `configurationUpdateHandler`。
    /// ⚠️ 请勿直接给 `self.configurationUpdateHandler` 赋值 —— 那会把 STBtn 的 `contentInsets`、
    /// state 背景、字体注入等逻辑全部覆盖。所有"每次 update 要做的事"都应写在这里。
    ///
    /// 使用示例：
    /// ```
    /// button.onConfigurationUpdate = { btn, config in
    ///     config.background.strokeColor = btn.isSelected ? .systemBlue : .clear
    ///     config.background.strokeWidth = 1
    /// }
    /// ```
    public var onConfigurationUpdate: ((UIButton, inout UIButton.Configuration) -> Void)?

    private func setupButton() {
        self.titleLabel?.adjustsFontForContentSizeCategory = true
        self.titleLabel?.textAlignment = .natural
        self.titleLabel?.numberOfLines = 1
        self.titleLabel?.lineBreakMode = .byTruncatingTail
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
            // 外部（调用方或 UIKit 内部）替换 configuration 或手动改 contentInsets 后，
            // 本次传入的 insets 与上次我们写出的值不一致 → 重新捕获 baseline，避免拿旧快照覆盖新值。
            if let last = self.lastAppliedContentInsets, config.contentInsets != last {
                self.baseContentInsets = config.contentInsets
            }
            config.contentInsets = self.baseContentInsets
            // 单行 + 尾部省略，匹配迁移前 UIButton 的默认行为；
            // Configuration 默认允许多行，中文无词边界会被按字符纵向拆开
            config.titleLineBreakMode = .byTruncatingTail
            config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { [weak self] attrs in
                // Configuration 生效后 titleLabel.font 不再驱动渲染；
                // 保留 titleLabel.font 作为字体入口（大量存量调用点都这么写），
                // 通过 transformer 每次渲染时把它注入到 attributedTitle。
                // 同时显式接管 foregroundColor，阻断系统在 highlighted/disabled 下
                // 对标题色做 alpha 衰减 / 灰化 —— "自定义按钮 = 调用点说了算"。
                var updated = attrs
                guard let self else { return updated }
                if let font = self.titleLabel?.font {
                    updated.font = font
                }
                if let color = self.titleColor(for: self.state) {
                    updated.foregroundColor = color
                }
                return updated
            }
            // 关掉系统对 image tint 在 highlighted/disabled 下的自动变换
            config.imageColorTransformer = UIConfigurationColorTransformer { $0 }
            self.refineButtonConfiguration(button, configuration: &config)
            self.onConfigurationUpdate?(button, &config)
            self.lastAppliedContentInsets = config.contentInsets
            button.configuration = config
            // Configuration 应用 attributedTitle 时会回写 titleLabel，可能把 numberOfLines 重置成 0；
            // 这里重新锁回单行，保证中文窄 label 不会按字符拆行
            self.titleLabel?.numberOfLines = 1
            self.titleLabel?.lineBreakMode = .byTruncatingTail
        }
        self.setNeedsUpdateConfiguration()
    }

    /// 强制重新捕获 `baseContentInsets` 基线。
    /// handler 已在检测到外部 insets 变动时自动重捕获，绝大多数场景不需要手动调用；
    /// 仅在想在下次 state 变化前**立即**应用新基线时使用。
    public func refreshBaseContentInsets() {
        self.baseContentInsets = self.configuration?.contentInsets ?? .zero
        self.lastAppliedContentInsets = nil
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
        // 让 Configuration 管理的 background 子视图与 `layer.cornerRadius` 对齐，
        // 避免 `masksToBounds = false`（如 `st_setShadow`）或 `config.background.backgroundColor`
        // 非空时背景按 0 半径绘制、把 `layer.cornerRadius` 盖住。
        config.background.cornerRadius = self.layer.cornerRadius
        // 无条件阻断系统在 highlighted/selected 下对 background 的 tint 过渡，
        // 保证"自定义按钮 = 调用点说了算"；调用方若需要恢复系统 tint，可在 `onConfigurationUpdate` 内重置此 transformer。
        config.background.backgroundColorTransformer = UIConfigurationColorTransformer { $0 }
        if let color = self.resolvedStateBackgroundColor(for: button.state) {
            config.background.backgroundColor = color
        }
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
        self.layer.shadowColor = color.cgColor
        self.layer.shadowOffset = offset
        self.layer.shadowRadius = radius
        self.layer.shadowOpacity = opacity
        self.layer.masksToBounds = false
    }

    /// 按状态设置按钮背景色（写入 `UIButton.Configuration.background.backgroundColor`）。
    ///
    /// 命中优先级：`disabled` > `highlighted` > `selected` > `normal`；未设置的状态回退到 `.normal`。
    /// 传入 `nil` 清除该状态的设置。
    ///
    /// 使用示例：
    /// ```
    /// button.st_setBackgroundColor(.systemBlue, for: .normal)
    /// button.st_setBackgroundColor(.systemIndigo, for: .highlighted)
    /// button.st_setBackgroundColor(.systemGray3, for: .disabled)
    /// ```
    public func st_setBackgroundColor(_ color: UIColor?, for state: UIControl.State) {
        let key = state.rawValue
        if let color {
            self.stateBackgroundColors[key] = color
        } else {
            self.stateBackgroundColors.removeValue(forKey: key)
        }
        self.setNeedsUpdateConfiguration()
    }

    /// 读取指定状态下已设置的背景色（不含回退推导）。
    public func st_backgroundColor(for state: UIControl.State) -> UIColor? {
        return self.stateBackgroundColors[state.rawValue]
    }

    /// 按当前 `button.state` 解析实际命中的背景色，内部使用。
    private func resolvedStateBackgroundColor(for state: UIControl.State) -> UIColor? {
        guard !self.stateBackgroundColors.isEmpty else { return nil }
        if let color = self.stateBackgroundColors[state.rawValue] {
            return color
        }
        if state.contains(.disabled), let color = self.stateBackgroundColors[UIControl.State.disabled.rawValue] {
            return color
        }
        if state.contains(.highlighted), let color = self.stateBackgroundColors[UIControl.State.highlighted.rawValue] {
            return color
        }
        if state.contains(.selected), let color = self.stateBackgroundColors[UIControl.State.selected.rawValue] {
            return color
        }
        return self.stateBackgroundColors[UIControl.State.normal.rawValue]
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
