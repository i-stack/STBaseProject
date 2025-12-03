//
//  STHUD.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2017/10/14.
//

import UIKit

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
    case text         // 纯文本
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
    
    public var successIconName: String?
    public var errorIconName: String?
    public var warningIconName: String?
    public var infoIconName: String?
    public var loadingIconName: String?
    
    public var iconSize: CGSize
    public var hudSize: CGSize
    
    public var labelFont: UIFont?
    public var detailLabelFont: UIFont?
    public var customView: UIView?
    public var customBgColor: UIColor?
    public var activityViewColor: UIColor?
    
    public init(backgroundColor: UIColor = UIColor.black.withAlphaComponent(0.8),
                textColor: UIColor = .white,
                detailTextColor: UIColor = .lightGray,
                successColor: UIColor = .systemGreen,
                errorColor: UIColor = .systemRed,
                warningColor: UIColor = .systemOrange,
                infoColor: UIColor = .systemBlue,
                loadingColor: UIColor = .systemBlue,
                cornerRadius: CGFloat = 8,
                shadowEnabled: Bool = true,
                successIconName: String? = nil,
                errorIconName: String? = nil,
                warningIconName: String? = nil,
                infoIconName: String? = nil,
                loadingIconName: String? = nil,
                iconSize: CGSize = CGSize(width: 28, height: 28),
                hudSize: CGSize = CGSize(width: 120, height: 120),
                labelFont: UIFont? = UIFont.systemFont(ofSize: 16, weight: .medium),
                detailLabelFont: UIFont? = UIFont.systemFont(ofSize: 14, weight: .regular),
                customView: UIView? = nil,
                customBgColor: UIColor? = nil,
                activityViewColor: UIColor? = nil) {
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
        self.successIconName = successIconName
        self.errorIconName = errorIconName
        self.warningIconName = warningIconName
        self.infoIconName = infoIconName
        self.loadingIconName = loadingIconName
        self.iconSize = iconSize
        self.hudSize = hudSize
        self.labelFont = labelFont
        self.detailLabelFont = detailLabelFont
        self.customView = customView
        self.customBgColor = customBgColor
        self.activityViewColor = activityViewColor
    }
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
                theme: STHUDTheme = STHUDTheme(),
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


// MARK: - STHUD 主类
/// 功能强大的 HUD 提示组件，支持多种类型、主题和自定义配置
open class STHUD: NSObject {
    
    public var progressHUD: STProgressHUD?
    open var theme: STHUDTheme = STHUDTheme()
    public static let sharedHUD: STHUD = STHUD()
    open var hudMode: STProgressHUD.HudMode = STProgressHUD.HudMode.customView
    
    private override init() {
        super.init()
    }
    
    /// 设置背景颜色
    /// - Parameter color: 背景颜色
    public func setBackgroundColor(_ color: UIColor) {
        theme.backgroundColor = color
    }
    
    /// 设置文字颜色
    /// - Parameter color: 文字颜色
    public func setTextColor(_ color: UIColor) {
        theme.textColor = color
    }
    
    /// 设置详细文字颜色
    /// - Parameter color: 详细文字颜色
    public func setDetailTextColor(_ color: UIColor) {
        theme.detailTextColor = color
    }
    
    /// 设置成功颜色
    /// - Parameter color: 成功颜色
    public func setSuccessColor(_ color: UIColor) {
        theme.successColor = color
    }
    
    /// 设置错误颜色
    /// - Parameter color: 错误颜色
    public func setErrorColor(_ color: UIColor) {
        theme.errorColor = color
    }
    
    /// 设置警告颜色
    /// - Parameter color: 警告颜色
    public func setWarningColor(_ color: UIColor) {
        theme.warningColor = color
    }
    
    /// 设置信息颜色
    /// - Parameter color: 信息颜色
    public func setInfoColor(_ color: UIColor) {
        theme.infoColor = color
    }
    
    /// 设置加载颜色
    /// - Parameter color: 加载颜色
    public func setLoadingColor(_ color: UIColor) {
        theme.loadingColor = color
    }
    
    /// 设置圆角
    /// - Parameter radius: 圆角半径
    public func setCornerRadius(_ radius: CGFloat) {
        theme.cornerRadius = radius
    }
    
    /// 设置阴影
    /// - Parameter enabled: 是否启用阴影
    public func setShadowEnabled(_ enabled: Bool) {
        theme.shadowEnabled = enabled
    }
    
    /// 设置成功图标
    /// - Parameter iconName: 图标名称
    public func setSuccessIcon(_ iconName: String?) {
        theme.successIconName = iconName
    }
    
    /// 设置错误图标
    /// - Parameter iconName: 图标名称
    public func setErrorIcon(_ iconName: String?) {
        theme.errorIconName = iconName
    }
    
    /// 设置警告图标
    /// - Parameter iconName: 图标名称
    public func setWarningIcon(_ iconName: String?) {
        theme.warningIconName = iconName
    }
    
    /// 设置信息图标
    /// - Parameter iconName: 图标名称
    public func setInfoIcon(_ iconName: String?) {
        theme.infoIconName = iconName
    }
    
    /// 设置加载图标
    /// - Parameter iconName: 图标名称
    public func setLoadingIcon(_ iconName: String?) {
        theme.loadingIconName = iconName
    }
    
    /// 设置图标大小
    /// - Parameter size: 图标大小
    public func setIconSize(_ size: CGSize) {
        theme.iconSize = size
    }
    
    /// 设置HUD大小
    /// - Parameter size: HUD大小
    public func setHudSize(_ size: CGSize) {
        theme.hudSize = size
    }
    
    /// 立即更新当前显示的HUD大小
    /// - Parameter size: 目标大小
    public func updateCurrentHudSize(_ size: CGSize) {
        updateHudSize(size)
    }
    
    /// 设置标签字体
    /// - Parameter font: 字体
    public func setLabelFont(_ font: UIFont?) {
        theme.labelFont = font
    }
    
    /// 设置详细标签字体
    /// - Parameter font: 字体
    public func setDetailLabelFont(_ font: UIFont?) {
        theme.detailLabelFont = font
    }
    
    /// 设置自定义视图
    /// - Parameter view: 自定义视图
    public func setCustomView(_ view: UIView?) {
        theme.customView = view
    }
    
    /// 设置自定义背景颜色
    /// - Parameter color: 背景颜色
    public func setCustomBgColor(_ color: UIColor?) {
        theme.customBgColor = color
    }
    
    /// 设置活动视图颜色
    /// - Parameter color: 活动视图颜色
    public func setActivityViewColor(_ color: UIColor?) {
        theme.activityViewColor = color
    }
        
    /// 使用配置显示 HUD
    /// - Parameter config: HUD 配置
    internal func show(with config: STHUDConfig) {
        let finalTitle = config.isLocalized ? config.title.localized : config.title
        let finalDetailText = config.detailText != nil ? (config.isLocalized ? config.detailText!.localized : config.detailText!) : nil
        if let window = UIApplication.shared.windows.first {
            if self.progressHUD?.superview != nil {
                self.progressHUD?.hide(animated: true)
            }
            self.progressHUD = STProgressHUD.init(withView: window)
            self.configHUBCommonProperty()
            window.addSubview(self.progressHUD ?? STProgressHUD())
        }
        if let customView = config.customView {
            self.progressHUD?.customView = customView
            self.progressHUD?.mode = .customView
        } else if let iconName = config.iconName {
            if let iconImage = UIImage(named: iconName) {
                self.progressHUD?.customView = UIImageView(image: iconImage)
                self.progressHUD?.mode = .customView
            } else {
                self.progressHUD?.mode = .text
            }
        } else {
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
    
        if config.autoHide {
            self.progressHUD?.hide(animated: true, afterDelay: config.hideDelay)
        }
    }
        
    /// 显示成功提示
    /// - Parameters:
    ///   - title: 标题
    ///   - detailText: 详细文本
    ///   - autoHide: 是否自动隐藏
    internal func showSuccess(title: String, detailText: String? = nil, autoHide: Bool = true) {
        let config = STHUDConfig(
            type: .success,
            title: title,
            detailText: detailText,
            iconName: theme.successIconName,
            autoHide: autoHide,
            hideDelay: 2.0
        )
        self.show(with: config)
    }
    
    /// 显示错误提示
    /// - Parameters:
    ///   - title: 标题
    ///   - detailText: 详细文本
    ///   - autoHide: 是否自动隐藏
    internal func showError(title: String, detailText: String? = nil, autoHide: Bool = true) {
        let config = STHUDConfig(
            type: .error,
            title: title,
            detailText: detailText,
            iconName: theme.errorIconName,
            autoHide: autoHide,
            hideDelay: 3.0
        )
        self.show(with: config)
    }
    
    /// 显示警告提示
    /// - Parameters:
    ///   - title: 标题
    ///   - detailText: 详细文本
    ///   - autoHide: 是否自动隐藏
    internal func showWarning(title: String, detailText: String? = nil, autoHide: Bool = true) {
        let config = STHUDConfig(
            type: .warning,
            title: title,
            detailText: detailText,
            iconName: theme.warningIconName,
            autoHide: autoHide,
            hideDelay: 2.5
        )
        self.show(with: config)
    }
    
    /// 显示信息提示
    /// - Parameters:
    ///   - title: 标题
    ///   - detailText: 详细文本
    ///   - autoHide: 是否自动隐藏
    internal func showInfo(title: String, detailText: String? = nil, autoHide: Bool = true) {
        let config = STHUDConfig(
            type: .info,
            title: title,
            detailText: detailText,
            iconName: theme.infoIconName,
            autoHide: autoHide
        )
        self.show(with: config)
    }
    
    /// 显示加载中
    /// - Parameters:
    ///   - title: 标题
    ///   - detailText: 详细文本
    internal func showLoading(title: String = "加载中...", detailText: String? = nil) {
        let config = STHUDConfig(
            type: .loading,
            title: title,
            detailText: detailText,
            autoHide: true
        )
        self.show(with: config)
    }
    
    /// 显示纯文本提示
    /// - Parameters:
    ///   - title: 标题
    ///   - detailText: 详细文本
    ///   - autoHide: 是否自动隐藏
    internal func showText(title: String, detailText: String? = nil, autoHide: Bool = true) {
        let config = STHUDConfig(
            type: .text,
            title: title,
            detailText: detailText,
            autoHide: autoHide,
            hideDelay: 2.0
        )
        self.show(with: config)
    }
        
    /// 配置手动隐藏的 HUD
    /// - Parameter showInView: 显示视图
    internal func configManualHiddenHUD(showInView: UIView) {
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
        if let font = theme.labelFont {
            self.progressHUD?.label?.font = font
        } else {
            self.progressHUD?.label?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        }
        
        if let detailsLabelFont = theme.detailLabelFont {
            self.progressHUD?.detailsLabel?.font = detailsLabelFont
        } else {
            self.progressHUD?.detailsLabel?.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        }
        
        self.progressHUD?.label?.textColor = theme.textColor
        self.progressHUD?.detailsLabel?.textColor = theme.detailTextColor
        
        let backgroundColor = theme.customBgColor ?? theme.backgroundColor
        self.progressHUD?.bezelView?.backgroundColor = backgroundColor
        self.progressHUD?.bezelView?.style = .solidColor
        self.progressHUD?.bezelView?.color = backgroundColor
        
        if let bezelView = self.progressHUD?.bezelView {
            bezelView.layer.cornerRadius = theme.cornerRadius
            if theme.shadowEnabled {
                bezelView.layer.shadowColor = UIColor.black.cgColor
                bezelView.layer.shadowOffset = CGSize(width: 0, height: 2)
                bezelView.layer.shadowRadius = 4
                bezelView.layer.shadowOpacity = 0.3
            }
        }
        
//        let hudSize = theme.hudSize
//        updateHudSize(hudSize)
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
//            if let bezelView = self.progressHUD?.bezelView {
//                let currentFrame = bezelView.frame
//                bezelView.frame = CGRect(
//                    x: currentFrame.origin.x,
//                    y: currentFrame.origin.y,
//                    width: hudSize.width,
//                    height: hudSize.height
//                )
//            }
//        }
//        if let bezelView = self.progressHUD?.bezelView {
//            let currentFrame = bezelView.frame
//            bezelView.frame = CGRect(
//                x: currentFrame.origin.x,
//                y: currentFrame.origin.y,
//                width: hudSize.width,
//                height: hudSize.height
//            )
//        }
        if let cusView = theme.customView {
            self.progressHUD?.customView = cusView
        }
        self.progressHUD?.mode = self.hudMode
    }
        
    /// 隐藏 HUD
    /// - Parameter animated: 是否动画
    internal func hide(animated: Bool) {
        if self.progressHUD?.superview != nil {
            self.progressHUD?.hide(animated: animated)
        }
    }
    
    /// 延迟隐藏 HUD
    /// - Parameters:
    ///   - animated: 是否动画
    ///   - afterDelay: 延迟时间
    internal func hide(animated: Bool, afterDelay: TimeInterval) {
        if self.progressHUD?.superview != nil {
            self.progressHUD?.hide(animated: animated, afterDelay: afterDelay)
        }
    }
     
    /// 更新 HUD 大小
    /// - Parameter size: 目标大小
    private func updateHudSize(_ size: CGSize) {
        guard let progressHUD = self.progressHUD else { return }
        
        // 方法1：通过约束更新大小
        if let bezelView = progressHUD.bezelView {
            bezelView.translatesAutoresizingMaskIntoConstraints = false
            
            // 移除现有的大小约束
            NSLayoutConstraint.deactivate(bezelView.constraints.filter { constraint in
                constraint.firstAttribute == .width || constraint.firstAttribute == .height
            })
            
            // 添加新的大小约束
            NSLayoutConstraint.activate([
                bezelView.widthAnchor.constraint(equalToConstant: size.width),
                bezelView.heightAnchor.constraint(equalToConstant: size.height)
            ])
            
            // 强制布局更新
            bezelView.setNeedsLayout()
            bezelView.layoutIfNeeded()
        }
        
        // 方法2：如果约束不生效，直接设置 frame（作为备选）
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
//            if let bezelView = progressHUD.bezelView {
//                let currentFrame = bezelView.frame
//                bezelView.frame = CGRect(
//                    x: currentFrame.origin.x,
//                    y: currentFrame.origin.y,
//                    width: size.width,
//                    height: size.height
//                )
//            }
//        }
    }
    
    /// 应用主题
    /// - Parameter theme: 主题配置
    internal func applyTheme(_ theme: STHUDTheme) {
        self.theme = theme
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
//            self.progressHUD?.customView = createInfoIcon()
        case .loading:
            self.progressHUD?.mode = .indeterminate
        case .progress:
            self.progressHUD?.mode = .determinate
        case .text:
            self.progressHUD?.mode = .text
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
        
    /// 创建成功图标
    /// - Returns: 成功图标视图
    private func createSuccessIcon() -> UIView {
        return createIconView(iconName: theme.successIconName ?? nil,
                              backgroundColor: theme.successColor,
                              text: "✓")
    }
    
    /// 创建错误图标
    /// - Returns: 错误图标视图
    private func createErrorIcon() -> UIView {
        return createIconView(iconName: theme.errorIconName ?? nil,
                              backgroundColor: theme.errorColor,
                              text: "✕")
    }
    
    /// 创建警告图标
    /// - Returns: 警告图标视图
    private func createWarningIcon() -> UIView {
        return createIconView(iconName: theme.warningIconName ?? nil,
                              backgroundColor: theme.warningColor,
                              text: "i")
    }
    
    /// 创建信息图标
    /// - Returns: 信息图标视图
    private func createInfoIcon() -> UIView {
        return createIconView(iconName: theme.infoIconName ?? nil,
                              backgroundColor: theme.infoColor,
                              text: "i")
    }
    
    /// 创建加载图标
    /// - Returns: 加载图标视图
    private func createLoadingIcon() -> UIView {
        return createIconView(iconName: theme.loadingIconName ?? nil,
                              backgroundColor: theme.loadingColor,
                              text: "⟳")
    }
    
    private func createIconView(iconName: String? = nil, backgroundColor: UIColor, text: String) -> UIView {
        let iconSize = self.theme.iconSize
        let iconWidth = iconSize.width
        let iconHeight = iconSize.height
        if let icon = iconName, let iconImage = UIImage(named: icon) {
            let imageView = UIImageView(image: iconImage)
            imageView.contentMode = .scaleAspectFit
            imageView.frame = CGRect(x: 0, y: 0, width: iconWidth, height: iconHeight)
            return imageView
        }
        let iconView = UIView(frame: CGRect(x: 0, y: 0, width: iconWidth, height: iconHeight))
        iconView.backgroundColor = backgroundColor
        iconView.layer.cornerRadius = iconWidth / 2
        let loading = UILabel(frame: iconView.bounds)
        loading.text = text
        loading.textColor = .white
        loading.font = UIFont.systemFont(ofSize: iconWidth * 0.6, weight: .bold)
        loading.textAlignment = .center
        iconView.addSubview(loading)
        return iconView
    }
}

// MARK: - STHUD 代理实现
extension STHUD: STProgressHUDDelegate {
    public func hudWasHidden(_ hud: STProgressHUD) {
        // HUD 隐藏完成
    }
}

// MARK: - UIView 扩展 - HUD 方法
public extension UIView {
    
    /// 显示成功提示
    /// - Parameter text: 显示文本
    func st_showSuccess(_ text: String) {
        self.st_showSuccess(text, detailText: nil)
    }
    
    /// 显示成功提示
    /// - Parameters:
    ///   - text: 主文本
    ///   - detailText: 详细文本
    func st_showSuccess(_ text: String, detailText: String? = nil) {
        DispatchQueue.main.async {
            STHUD.sharedHUD.showSuccess(title: text, detailText: detailText)
        }
    }
    
    /// 显示错误提示
    /// - Parameter text: 显示文本
    func st_showError(_ text: String) {
        self.st_showError(text, detailText: nil)
    }
    
    /// 显示错误提示
    /// - Parameters:
    ///   - text: 主文本
    ///   - detailText: 详细文本
    func st_showError(_ text: String, detailText: String? = nil) {
        DispatchQueue.main.async {
            STHUD.sharedHUD.showError(title: text, detailText: detailText)
        }
    }
    
    /// 显示警告提示
    /// - Parameter text: 显示文本
    func st_showWarning(_ text: String) {
        self.st_showWarning(text, detailText: nil)
    }
    
    /// 显示警告提示
    /// - Parameters:
    ///   - text: 主文本
    ///   - detailText: 详细文本
    func st_showWarning(_ text: String, detailText: String? = nil) {
        DispatchQueue.main.async {
            STHUD.sharedHUD.showWarning(title: text, detailText: detailText)
        }
    }
    
    /// 显示信息提示
    /// - Parameter text: 显示文本
    func st_showInfo(_ text: String) {
        self.st_showInfo(text, detailText: nil)
    }
    
    /// 显示信息提示
    /// - Parameters:
    ///   - text: 主文本
    ///   - detailText: 详细文本
    func st_showInfo(_ text: String, detailText: String? = nil) {
        DispatchQueue.main.async {
            STHUD.sharedHUD.showInfo(title: text, detailText: detailText)
        }
    }
    
    /// 显示加载中（自动隐藏）
    /// - Parameter text: 加载文本
    func st_showLoading(_ text: String = "") {
        DispatchQueue.main.async {
            STHUD.sharedHUD.showLoading(title: text)
        }
    }
    
    /// 显示纯文本提示
    /// - Parameter text: 显示文本
    func st_showText(_ text: String) {
        self.st_showText(text, detailText: nil)
    }
    
    /// 显示纯文本提示
    /// - Parameters:
    ///   - text: 主文本
    ///   - detailText: 详细文本
    func st_showText(_ text: String, detailText: String? = nil) {
        DispatchQueue.main.async {
            STHUD.sharedHUD.showText(title: text, detailText: detailText)
        }
    }
    
    /// 显示手动隐藏的加载中 HUD
    /// - Parameter text: 加载文本
    func st_showManualLoading(_ text: String = "") {
        self.st_showManual(text: text, detailText: nil)
    }
    
    /// 显示手动隐藏的 HUD
    /// - Parameters:
    ///   - text: 主文本
    ///   - detailText: 详细文本
    func st_showManual(text: String, detailText: String? = nil) {
        DispatchQueue.main.async {
            STHUD.sharedHUD.configManualHiddenHUD(showInView: self)
            STHUD.sharedHUD.progressHUD?.label?.text = text
            STHUD.sharedHUD.progressHUD?.detailsLabel?.text = detailText
            STHUD.sharedHUD.progressHUD?.show(animated: true)
        }
    }
    
    func showManualLoading(_ text: String = "") {
        self.st_showManual(text: text, detailText: nil)
    }
    
    func showManualLoading(_ text: String = "", detailText: String? = nil) {
        self.st_showManual(text: text, detailText: detailText)
    }
    
    /// 隐藏 HUD
    func st_hideHUD() {
        DispatchQueue.main.async {
            STHUD.sharedHUD.hide(animated: true)
        }
    }
    
    func hideHud() {
        self.st_hideHUD()
    }
    
    /// 使用配置显示 HUD
    /// - Parameter config: HUD 配置
    func st_showHUD(with config: STHUDConfig) {
        DispatchQueue.main.async {
            STHUD.sharedHUD.show(with: config)
        }
    }
}
