//
//  STHUD.swift
//  STBaseProject
//
//  Created by stack on 2017/10/14.
//

import UIKit
import STBaseModule

// MARK: - HUD 位置枚举
public enum STHUDLocation {
    case center
    case top
    case bottom
}

// MARK: - HUD 类型枚举
public enum STHUDType {
    case success      // 成功提示
    case error        // 错误提示
    case warning      // 警告提示
    case info         // 信息提示
    case loading      // 加载中
    case progress     // 进度显示
    case custom       // 自定义
}

// MARK: - HUD 主题配置
public struct STHUDTheme {
    public var backgroundColor: UIColor
    public var textColor: UIColor
    public var detailTextColor: UIColor
    public var successColor: UIColor
    public var errorColor: UIColor
    public var warningColor: UIColor
    public var infoColor: UIColor
    public var loadingColor: UIColor
    public var cornerRadius: CGFloat
    public var shadowEnabled: Bool
    
    public init(backgroundColor: UIColor = UIColor.black.withAlphaComponent(0.8),
                textColor: UIColor = .white,
                detailTextColor: UIColor = .lightGray,
                successColor: UIColor = .systemGreen,
                errorColor: UIColor = .systemRed,
                warningColor: UIColor = .systemOrange,
                infoColor: UIColor = .systemBlue,
                loadingColor: UIColor = .systemBlue,
                cornerRadius: CGFloat = 8,
                shadowEnabled: Bool = true) {
        self.backgroundColor = backgroundColor
        self.textColor = textColor
        self.detailTextColor = detailTextColor
        self.successColor = successColor
        self.errorColor = errorColor
        self.warningColor = warningColor
        self.infoColor = infoColor
        self.loadingColor = loadingColor
        self.cornerRadius = cornerRadius
        self.shadowEnabled = shadowEnabled
    }
    
    /// 默认主题
    public static let `default` = STHUDTheme()
    
    /// 浅色主题
    public static let light = STHUDTheme(
        backgroundColor: UIColor.white.withAlphaComponent(0.9),
        textColor: .black,
        detailTextColor: .darkGray,
        successColor: .systemGreen,
        errorColor: .systemRed,
        warningColor: .systemOrange,
        infoColor: .systemBlue,
        loadingColor: .systemBlue
    )
    
    /// 深色主题
    public static let dark = STHUDTheme(
        backgroundColor: UIColor.black.withAlphaComponent(0.9),
        textColor: .white,
        detailTextColor: .lightGray,
        successColor: .systemGreen,
        errorColor: .systemRed,
        warningColor: .systemOrange,
        infoColor: .systemBlue,
        loadingColor: .systemBlue
    )
}

// MARK: - HUD 配置结构
public struct STHUDConfig {
    public var type: STHUDType
    public var title: String
    public var detailText: String?
    public var iconName: String?
    public var customView: UIView?
    public var location: STHUDLocation
    public var autoHide: Bool
    public var hideDelay: TimeInterval
    public var theme: STHUDTheme
    public var isLocalized: Bool
    
    public init(type: STHUDType = .info,
                title: String,
                detailText: String? = nil,
                iconName: String? = nil,
                customView: UIView? = nil,
                location: STHUDLocation = .center,
                autoHide: Bool = true,
                hideDelay: TimeInterval = 1.5,
                theme: STHUDTheme = .default,
                isLocalized: Bool = true) {
        self.type = type
        self.title = title
        self.detailText = detailText
        self.iconName = iconName
        self.customView = customView
        self.location = location
        self.autoHide = autoHide
        self.hideDelay = hideDelay
        self.theme = theme
        self.isLocalized = isLocalized
    }
}

// MARK: - 完成回调类型
public typealias STHUDCompletionBlock = (_ state: Bool) -> Void

// MARK: - STHUD 主类
/// 功能强大的 HUD 提示组件，支持多种类型、主题和自定义配置
open class STHUD: NSObject {
    
    // MARK: - 公开属性
    open var labelFont: UIFont?
    open var customView: UIView?
    open var labelColor: UIColor?
    open var customBgColor: UIColor?
    open var detailLabelFont: UIFont?
    open var errorIconImageStr: String?
    open var detailLabelColor: UIColor?
    open var activityViewColor: UIColor?
    open var afterDelay: TimeInterval = 1.5
    open var theme: STHUDTheme = .default
    
    // MARK: - 内部属性
    public var progressHUD: STProgressHUD?
    public static let sharedHUD: STHUD = STHUD()
    private var stCompletionBlock: STHUDCompletionBlock?
    open var hudMode: STProgressHUD.HudMode = STProgressHUD.HudMode.customView
    
    // MARK: - 单例初始化
    private override init() {
        super.init()
        setupDefaultConfiguration()
    }
    
    // MARK: - 默认配置
    private func setupDefaultConfiguration() {
        labelFont = UIFont.systemFont(ofSize: 16, weight: .medium)
        detailLabelFont = UIFont.systemFont(ofSize: 14, weight: .regular)
        labelColor = theme.textColor
        detailLabelColor = theme.detailTextColor
        customBgColor = theme.backgroundColor
        activityViewColor = theme.loadingColor
    }

    // MARK: - 主要显示方法
    
    /// 显示 HUD（兼容原有方法）
    /// - Parameter text: 显示文本
    public func show(text: String) -> Void {
        self.show(text: text, detailText: "")
    }
    
    /// 显示 HUD（兼容原有方法）
    /// - Parameters:
    ///   - text: 主文本
    ///   - detailText: 详细文本
    public func show(text: String, detailText: String) -> Void {
        let finalText = text.localized
        let finalDetailText = detailText.localized
        
        self.progressHUD?.label?.text = finalText
        self.progressHUD?.detailsLabel?.text = finalDetailText
        self.progressHUD?.show(animated: true)
        
        if let block = self.stCompletionBlock {
            block(true)
        }
        
        STLog("✅ STHUD: 显示成功 - 文本: \(finalText)")
    }
    
    /// 使用配置显示 HUD
    /// - Parameter config: HUD 配置
    public func show(with config: STHUDConfig) {
        let finalTitle = config.isLocalized ? config.title.localized : config.title
        let finalDetailText = config.detailText != nil ? (config.isLocalized ? config.detailText!.localized : config.detailText!) : nil
        
        // 应用主题
        applyTheme(config.theme)
        
        // 设置图标或自定义视图
        if let customView = config.customView {
            self.progressHUD?.customView = customView
            self.progressHUD?.mode = .customView
        } else if let iconName = config.iconName {
            if let iconImage = UIImage(named: iconName) {
                self.progressHUD?.customView = UIImageView(image: iconImage)
                self.progressHUD?.mode = .customView
            } else {
                STLog("⚠️ STHUD: 图标加载失败 - \(iconName)")
                self.progressHUD?.mode = .text
            }
        } else {
            // 根据类型设置默认图标
            setDefaultIcon(for: config.type)
        }
        
        // 设置位置偏移
        let offset = calculateOffset(for: config.location, in: self.progressHUD?.superview)
        self.progressHUD?.offset = offset
        
        // 显示文本
        self.progressHUD?.label?.text = finalTitle
        self.progressHUD?.detailsLabel?.text = finalDetailText
        
        // 显示 HUD
        self.progressHUD?.show(animated: true)
        
        // 自动隐藏
        if config.autoHide {
            self.progressHUD?.hide(animated: true, afterDelay: config.hideDelay)
        }
        
        if let block = self.stCompletionBlock {
            block(true)
        }
        
        STLog("✅ STHUD: 配置显示成功 - 类型: \(config.type), 文本: \(finalTitle)")
    }
    
    // MARK: - 便捷显示方法
    
    /// 显示成功提示
    /// - Parameters:
    ///   - title: 标题
    ///   - detailText: 详细文本
    ///   - autoHide: 是否自动隐藏
    public func showSuccess(title: String, detailText: String? = nil, autoHide: Bool = true) {
        let config = STHUDConfig(
            type: .success,
            title: title,
            detailText: detailText,
            iconName: "hud_success",
            autoHide: autoHide,
            hideDelay: 2.0
        )
        show(with: config)
    }
    
    /// 显示错误提示
    /// - Parameters:
    ///   - title: 标题
    ///   - detailText: 详细文本
    ///   - autoHide: 是否自动隐藏
    public func showError(title: String, detailText: String? = nil, autoHide: Bool = true) {
        let config = STHUDConfig(
            type: .error,
            title: title,
            detailText: detailText,
            iconName: "hud_error",
            autoHide: autoHide,
            hideDelay: 3.0
        )
        show(with: config)
    }
    
    /// 显示警告提示
    /// - Parameters:
    ///   - title: 标题
    ///   - detailText: 详细文本
    ///   - autoHide: 是否自动隐藏
    public func showWarning(title: String, detailText: String? = nil, autoHide: Bool = true) {
        let config = STHUDConfig(
            type: .warning,
            title: title,
            detailText: detailText,
            iconName: "hud_warning",
            autoHide: autoHide,
            hideDelay: 2.5
        )
        show(with: config)
    }
    
    /// 显示信息提示
    /// - Parameters:
    ///   - title: 标题
    ///   - detailText: 详细文本
    ///   - autoHide: 是否自动隐藏
    public func showInfo(title: String, detailText: String? = nil, autoHide: Bool = true) {
        let config = STHUDConfig(
            type: .info,
            title: title,
            detailText: detailText,
            iconName: "hud_info",
            autoHide: autoHide
        )
        show(with: config)
    }
    
    /// 显示加载中
    /// - Parameters:
    ///   - title: 标题
    ///   - detailText: 详细文本
    public func showLoading(title: String = "加载中...", detailText: String? = nil) {
        let config = STHUDConfig(
            type: .loading,
            title: title,
            detailText: detailText,
            autoHide: false
        )
        show(with: config)
    }
    
    // MARK: - 配置方法
    
    /// 配置 HUD（兼容原有方法）
    /// - Parameters:
    ///   - showInView: 显示视图
    ///   - icon: 图标名称
    ///   - offset: 偏移量
    @objc public func configHUD(showInView: UIView, icon: String, offset: CGPoint) -> Void {
        self.progressHUD?.isHidden = true
        if self.progressHUD?.superview != nil {
            self.progressHUD?.hide(animated: true)
        }
        self.progressHUD = STProgressHUD.init(withView: showInView)
        self.configHUBCommonProperty()
        if icon.count > 0 {
            self.progressHUD?.customView = UIImageView.init(image: UIImage.init(named: icon))
            self.progressHUD?.mode = .customView
        } else {
            self.progressHUD?.mode = .text
        }
        self.progressHUD?.offset = offset
        self.progressHUD?.isHidden = false
        showInView.addSubview(self.progressHUD ?? STProgressHUD())
    }
    
    /// 配置手动隐藏的 HUD（兼容原有方法）
    /// - Parameter showInView: 显示视图
    @objc public func configManualHiddenHUD(showInView: UIView) -> Void {
        if self.progressHUD?.superview != nil {
            self.progressHUD?.hide(animated: true)
        }
        self.progressHUD = STProgressHUD.init(withView: showInView)
        self.configHUBCommonProperty()
        showInView.addSubview(self.progressHUD ?? STProgressHUD())
    }
    
    /// 配置通用属性
    private func configHUBCommonProperty() {
        guard self.progressHUD != nil else { return }
        self.progressHUD?.delegate = self
        self.progressHUD?.label?.numberOfLines = 0
        self.progressHUD?.contentColor = theme.textColor
        self.progressHUD?.bezelView?.style = .solidColor
        self.progressHUD?.removeFromSuperViewOnHide = true
        
        // 设置字体
        if let font = self.labelFont {
            self.progressHUD?.label?.font = font
        } else {
            self.progressHUD?.label?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        }
        
        if let detailsLabelFont = self.detailLabelFont {
            self.progressHUD?.detailsLabel?.font = detailsLabelFont
        } else {
            self.progressHUD?.detailsLabel?.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        }
        
        // 设置颜色
        if let color = self.labelColor {
            self.progressHUD?.label?.textColor = color
        } else {
            self.progressHUD?.label?.textColor = theme.textColor
        }
        
        if let detailsLabelColor = self.detailLabelColor {
            self.progressHUD?.detailsLabel?.textColor = detailsLabelColor
        } else {
            self.progressHUD?.detailsLabel?.textColor = theme.detailTextColor
        }
        
        // 设置背景
        if let customColor = self.customBgColor {
            self.progressHUD?.bezelView?.backgroundColor = customColor
        } else {
            self.progressHUD?.bezelView?.backgroundColor = theme.backgroundColor
        }
        
        if let color = self.activityViewColor {
            self.progressHUD?.bezelView?.color = color
        } else {
            self.progressHUD?.bezelView?.color = theme.loadingColor
        }
        
        // 设置圆角和阴影
        if let bezelView = self.progressHUD?.bezelView {
            bezelView.layer.cornerRadius = theme.cornerRadius
            if theme.shadowEnabled {
                bezelView.layer.shadowColor = UIColor.black.cgColor
                bezelView.layer.shadowOffset = CGSize(width: 0, height: 2)
                bezelView.layer.shadowRadius = 4
                bezelView.layer.shadowOpacity = 0.3
            }
        }
        
        // 设置自定义视图
        if let cusView = self.customView {
            self.progressHUD?.customView = cusView
        }
        
        self.progressHUD?.mode = self.hudMode
    }
    
    // MARK: - 隐藏方法
    
    /// 隐藏 HUD
    /// - Parameter animated: 是否动画
    public func hide(animated: Bool) {
        if self.progressHUD?.superview != nil {
            self.progressHUD?.hide(animated: animated)
        }
    }
    
    /// 延迟隐藏 HUD
    /// - Parameters:
    ///   - animated: 是否动画
    ///   - afterDelay: 延迟时间
    public func hide(animated: Bool, afterDelay: TimeInterval) {
        if self.progressHUD?.superview != nil {
            self.progressHUD?.hide(animated: animated, afterDelay: afterDelay)
        }
    }
    
    // MARK: - 回调设置
    
    /// 设置完成回调
    /// - Parameter block: 回调块
    public func hudComplection(block: @escaping STHUDCompletionBlock) -> Void {
        self.stCompletionBlock = block
    }
    
    // MARK: - 主题和配置
    
    /// 应用主题
    /// - Parameter theme: 主题配置
    public func applyTheme(_ theme: STHUDTheme) {
        self.theme = theme
        self.labelColor = theme.textColor
        self.detailLabelColor = theme.detailTextColor
        self.customBgColor = theme.backgroundColor
        self.activityViewColor = theme.loadingColor
    }
    
    /// 设置默认图标
    /// - Parameter type: HUD 类型
    private func setDefaultIcon(for type: STHUDType) {
        switch type {
        case .success:
            self.progressHUD?.mode = .customView
            self.progressHUD?.customView = createSuccessIcon()
        case .error:
            self.progressHUD?.mode = .customView
            self.progressHUD?.customView = createErrorIcon()
        case .warning:
            self.progressHUD?.mode = .customView
            self.progressHUD?.customView = createWarningIcon()
        case .info:
            self.progressHUD?.mode = .customView
            self.progressHUD?.customView = createInfoIcon()
        case .loading:
            self.progressHUD?.mode = .indeterminate
        case .progress:
            self.progressHUD?.mode = .determinate
        case .custom:
            self.progressHUD?.mode = .customView
        }
    }
    
    /// 计算位置偏移
    /// - Parameters:
    ///   - location: 位置
    ///   - superview: 父视图
    /// - Returns: 偏移量
    private func calculateOffset(for location: STHUDLocation, in superview: UIView?) -> CGPoint {
        guard let superview = superview else { return .zero }
        
        switch location {
        case .center:
            return .zero
        case .top:
            return CGPoint(x: 0, y: -superview.frame.size.height / 6.0)
        case .bottom:
            return CGPoint(x: 0, y: superview.frame.size.height / 6.0)
        }
    }
    
    // MARK: - 图标创建方法
    
    /// 创建成功图标
    /// - Returns: 成功图标视图
    private func createSuccessIcon() -> UIView {
        let iconView = UIView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        iconView.backgroundColor = theme.successColor
        iconView.layer.cornerRadius = 20
        
        let checkmark = UILabel(frame: iconView.bounds)
        checkmark.text = "✓"
        checkmark.textColor = .white
        checkmark.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        checkmark.textAlignment = .center
        iconView.addSubview(checkmark)
        
        return iconView
    }
    
    /// 创建错误图标
    /// - Returns: 错误图标视图
    private func createErrorIcon() -> UIView {
        let iconView = UIView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        iconView.backgroundColor = theme.errorColor
        iconView.layer.cornerRadius = 20
        
        let cross = UILabel(frame: iconView.bounds)
        cross.text = "✕"
        cross.textColor = .white
        cross.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        cross.textAlignment = .center
        iconView.addSubview(cross)
        
        return iconView
    }
    
    /// 创建警告图标
    /// - Returns: 警告图标视图
    private func createWarningIcon() -> UIView {
        let iconView = UIView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        iconView.backgroundColor = theme.warningColor
        iconView.layer.cornerRadius = 20
        
        let warning = UILabel(frame: iconView.bounds)
        warning.text = "!"
        warning.textColor = .white
        warning.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        warning.textAlignment = .center
        iconView.addSubview(warning)
        
        return iconView
    }
    
    /// 创建信息图标
    /// - Returns: 信息图标视图
    private func createInfoIcon() -> UIView {
        let iconView = UIView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        iconView.backgroundColor = theme.infoColor
        iconView.layer.cornerRadius = 20
        
        let info = UILabel(frame: iconView.bounds)
        info.text = "i"
        info.textColor = .white
        info.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        info.textAlignment = .center
        iconView.addSubview(info)
        
        return iconView
    }
}

// MARK: - STHUD 代理实现
extension STHUD: STProgressHUDDelegate {
    public func hudWasHidden(_ hud: STProgressHUD) {
        if let block = self.stCompletionBlock {
            block(false)
        }
        STLog("✅ STHUD: 隐藏完成")
    }
}

// MARK: - UIView 扩展 - 自动隐藏 HUD
public extension UIView {
    
    /// 显示自动隐藏的 HUD
    /// - Parameter text: 显示文本
    func st_showAutoHidden(text: String) -> Void {
        self.st_showAutoHidden(text: text, toView: self.st_keyWindow() ?? UIView())
    }
    
    /// 显示自动隐藏的 HUD
    /// - Parameters:
    ///   - text: 显示文本
    ///   - toView: 显示视图
    func st_showAutoHidden(text: String, toView: UIView) -> Void {
        self.st_showAutoHidden(text: text, detailText: "", toView: toView)
    }
    
    /// 显示自动隐藏的 HUD
    /// - Parameters:
    ///   - text: 主文本
    ///   - detailText: 详细文本
    func st_showAutoHidden(text: String, detailText: String) -> Void {
        self.st_showAutoHidden(text: text, detailText: detailText, toView: self.st_keyWindow() ?? UIView())
    }
    
    /// 显示自动隐藏的 HUD
    /// - Parameters:
    ///   - text: 主文本
    ///   - detailText: 详细文本
    ///   - toView: 显示视图
    func st_showAutoHidden(text: String, detailText: String, toView: UIView) -> Void {
        self.st_showAutoHidden(text: text, detailText: detailText, offset: CGPoint.zero, toView: toView)
    }
    
    /// 显示自动隐藏的 HUD
    /// - Parameters:
    ///   - text: 主文本
    ///   - detailText: 详细文本
    ///   - offset: 偏移量
    ///   - toView: 显示视图
    func st_showAutoHidden(text: String, detailText: String, offset: CGPoint, toView: UIView) -> Void {
        self.st_show(text: text, detailText: detailText, icon: "", offset: offset, afterDelay: STHUD.sharedHUD.afterDelay, toView: toView)
    }
    
    /// 显示自动隐藏的 HUD（指定位置）
    /// - Parameters:
    ///   - text: 主文本
    ///   - location: 显示位置
    func st_showAutoHidden(text: String, location: STHUDLocation) -> Void {
        self.st_showAutoHidden(text: text, location: location, toView: self.st_keyWindow() ?? self)
    }
    
    /// 显示自动隐藏的 HUD（指定位置）
    /// - Parameters:
    ///   - text: 主文本
    ///   - location: 显示位置
    ///   - toView: 显示视图
    func st_showAutoHidden(text: String, location: STHUDLocation, toView: UIView) -> Void {
        self.st_showAutoHidden(text: text, detailText: "", location: location, toView: toView)
    }
    
    /// 显示自动隐藏的 HUD（指定位置）
    /// - Parameters:
    ///   - text: 主文本
    ///   - detailText: 详细文本
    ///   - location: 显示位置
    func st_showAutoHidden(text: String, detailText: String, location: STHUDLocation) -> Void {
        self.st_showAutoHidden(text: text, detailText: detailText, location: location, toView: self.st_keyWindow() ?? self)
    }
    
    /// 显示自动隐藏的 HUD（指定位置）
    /// - Parameters:
    ///   - text: 主文本
    ///   - detailText: 详细文本
    ///   - location: 显示位置
    ///   - toView: 显示视图
    func st_showAutoHidden(text: String, detailText: String, location: STHUDLocation, toView: UIView) -> Void {
        self.st_show(text: text, detailText: detailText, icon: "", afterDelay: STHUD.sharedHUD.afterDelay, location: location, toView: toView)
    }
}

// MARK: - UIView 扩展 - 手动隐藏 HUD
public extension UIView {
    
    /// 显示加载中 HUD（需要手动隐藏）
    func st_showLoading() -> Void {
        self.st_showLoading(text: "")
    }
    
    /// 显示加载中 HUD（需要手动隐藏）
    /// - Parameter text: 加载文本
    func st_showLoading(text: String) -> Void {
        self.st_showLoading(text: text, toView: self.st_keyWindow() ?? self)
    }
    
    /// 显示加载中 HUD（需要手动隐藏）
    /// - Parameters:
    ///   - text: 加载文本
    ///   - toView: 显示视图
    func st_showLoading(text: String, toView: UIView) -> Void {
        self.st_showLoading(text: text, detailText: "", toView: toView)
    }

    /// 显示加载中 HUD（内部方法）
    /// - Parameters:
    ///   - text: 主文本
    ///   - detailText: 详细文本
    ///   - toView: 显示视图
    private func st_showLoading(text: String, detailText: String, toView: UIView) -> Void {
        DispatchQueue.main.async {
            let hud = STHUD.sharedHUD
            if toView.superview != nil {
                hud.configManualHiddenHUD(showInView: toView)
            } else {
                hud.configManualHiddenHUD(showInView: self.st_keyWindow() ?? self)
            }
            hud.show(text: text, detailText: detailText)
        }
    }

    /// 隐藏 HUD
    func st_hideHUD() -> Void {
        DispatchQueue.main.async {
            STHUD.sharedHUD.hide(animated: true)
        }
    }
}

// MARK: - UIView 扩展 - 便捷 HUD 方法
public extension UIView {
    
    /// 显示成功提示
    /// - Parameters:
    ///   - title: 标题
    ///   - detailText: 详细文本
    func st_showSuccess(title: String, detailText: String? = nil) {
        DispatchQueue.main.async {
            let hud = STHUD.sharedHUD
            let targetView = self.st_keyWindow() ?? self
            hud.configHUD(showInView: targetView, icon: "", offset: .zero)
            hud.showSuccess(title: title, detailText: detailText)
        }
    }
    
    /// 显示错误提示
    /// - Parameters:
    ///   - title: 标题
    ///   - detailText: 详细文本
    func st_showError(title: String, detailText: String? = nil) {
        DispatchQueue.main.async {
            let hud = STHUD.sharedHUD
            let targetView = self.st_keyWindow() ?? self
            hud.configHUD(showInView: targetView, icon: "", offset: .zero)
            hud.showError(title: title, detailText: detailText)
        }
    }
    
    /// 显示警告提示
    /// - Parameters:
    ///   - title: 标题
    ///   - detailText: 详细文本
    func st_showWarning(title: String, detailText: String? = nil) {
        DispatchQueue.main.async {
            let hud = STHUD.sharedHUD
            let targetView = self.st_keyWindow() ?? self
            hud.configHUD(showInView: targetView, icon: "", offset: .zero)
            hud.showWarning(title: title, detailText: detailText)
        }
    }
    
    /// 显示信息提示
    /// - Parameters:
    ///   - title: 标题
    ///   - detailText: 详细文本
    func st_showInfo(title: String, detailText: String? = nil) {
        DispatchQueue.main.async {
            let hud = STHUD.sharedHUD
            let targetView = self.st_keyWindow() ?? self
            hud.configHUD(showInView: targetView, icon: "", offset: .zero)
            hud.showInfo(title: title, detailText: detailText)
        }
    }
    
    /// 使用配置显示 HUD
    /// - Parameter config: HUD 配置
    func st_showHUD(with config: STHUDConfig) {
        DispatchQueue.main.async {
            let hud = STHUD.sharedHUD
            let targetView = self.st_keyWindow() ?? self
            hud.configHUD(showInView: targetView, icon: config.iconName ?? "", offset: .zero)
            hud.show(with: config)
        }
    }
}

// MARK: - UIView 扩展 - 内部方法
public extension UIView {
    
    /// 显示 HUD（内部方法）
    /// - Parameters:
    ///   - text: 主文本
    ///   - icon: 图标名称
    ///   - toView: 显示视图
    func st_show(text: String, icon: String, toView: UIView) -> Void {
        self.st_show(text: text, detailText: "", icon: icon, toView: toView)
    }
    
    /// 显示 HUD（内部方法）
    /// - Parameters:
    ///   - text: 主文本
    ///   - detailText: 详细文本
    ///   - icon: 图标名称
    ///   - toView: 显示视图
    func st_show(text: String, detailText: String, icon: String, toView: UIView) -> Void {
        self.st_show(text: text, detailText: detailText, icon: icon, offset: CGPoint.zero, afterDelay: STHUD.sharedHUD.afterDelay, toView: toView)
    }
    
    /// 显示 HUD（内部方法）
    /// - Parameters:
    ///   - text: 主文本
    ///   - detailText: 详细文本
    ///   - icon: 图标名称
    ///   - afterDelay: 延迟时间
    ///   - location: 显示位置
    ///   - toView: 显示视图
    private func st_show(text: String, detailText: String, icon: String, afterDelay: TimeInterval, location: STHUDLocation, toView: UIView) -> Void {
        var point = CGPoint.zero
        if location == .top {
            point = CGPoint.init(x: 0, y: -toView.frame.size.height / 6.0)
        } else if location == .bottom {
            point = CGPoint.init(x: 0, y: toView.frame.size.height / 6.0)
        }
        self.st_show(text: text, detailText: detailText, icon: icon, offset: point, afterDelay: afterDelay, toView: toView)
    }
    
    /// 显示 HUD（内部方法）
    /// - Parameters:
    ///   - text: 主文本
    ///   - detailText: 详细文本
    ///   - icon: 图标名称
    ///   - offset: 偏移量
    ///   - afterDelay: 延迟时间
    ///   - toView: 显示视图
    private func st_show(text: String, detailText: String, icon: String, offset: CGPoint, afterDelay: TimeInterval, toView: UIView) -> Void {
        let hud = STHUD.sharedHUD
        if toView.superview != nil {
            hud.configHUD(showInView: toView, icon: icon, offset: offset)
        } else {
            hud.configHUD(showInView: self.st_keyWindow() ?? self, icon: icon, offset: offset)
        }
        hud.show(text: text, detailText: detailText)
        hud.hide(animated: true, afterDelay: afterDelay)
    }
}