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
    case success      // 成功提示（有图标，自动隐藏）
    case error        // 错误提示（有图标，自动隐藏）
    case warning      // 警告提示（有图标，自动隐藏）
    case info         // 信息提示（有图标，自动隐藏）
    case loading      // 加载中（无图标，需手动关闭）
    case progress     // 进度显示（无图标，需手动关闭）
    case text         // 纯文本 Toast（无图标，自动隐藏）
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
    public var cornerRadius: CGFloat
    public var shadowEnabled: Bool
    public var successIconName: String?
    public var errorIconName: String?
    public var warningIconName: String?
    public var infoIconName: String?
    public var iconSize: CGSize
    public var labelFont: UIFont?
    public var detailLabelFont: UIFont?

    public init(backgroundColor: UIColor = UIColor.black.withAlphaComponent(0.8),
                textColor: UIColor = .white,
                detailTextColor: UIColor = .lightGray,
                successColor: UIColor = .systemGreen,
                errorColor: UIColor = .systemRed,
                warningColor: UIColor = .systemOrange,
                infoColor: UIColor = .systemBlue,
                cornerRadius: CGFloat = 8,
                shadowEnabled: Bool = true,
                successIconName: String? = nil,
                errorIconName: String? = nil,
                warningIconName: String? = nil,
                infoIconName: String? = nil,
                iconSize: CGSize = CGSize(width: 28, height: 28),
                labelFont: UIFont? = UIFont.st_systemFont(ofSize: 16, weight: .medium),
                detailLabelFont: UIFont? = UIFont.st_systemFont(ofSize: 14, weight: .regular)) {
        self.backgroundColor = backgroundColor
        self.textColor = textColor
        self.detailTextColor = detailTextColor
        self.successColor = successColor
        self.errorColor = errorColor
        self.warningColor = warningColor
        self.infoColor = infoColor
        self.cornerRadius = cornerRadius
        self.shadowEnabled = shadowEnabled
        self.successIconName = successIconName
        self.errorIconName = errorIconName
        self.warningIconName = warningIconName
        self.infoIconName = infoIconName
        self.iconSize = iconSize
        self.labelFont = labelFont
        self.detailLabelFont = detailLabelFont
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
        self.theme.backgroundColor = color
    }

    /// 设置文字颜色
    /// - Parameter color: 文字颜色
    public func setTextColor(_ color: UIColor) {
        self.theme.textColor = color
    }

    /// 设置详细文字颜色
    /// - Parameter color: 详细文字颜色
    public func setDetailTextColor(_ color: UIColor) {
        self.theme.detailTextColor = color
    }

    /// 设置成功颜色
    /// - Parameter color: 成功颜色
    public func setSuccessColor(_ color: UIColor) {
        self.theme.successColor = color
    }

    /// 设置错误颜色
    /// - Parameter color: 错误颜色
    public func setErrorColor(_ color: UIColor) {
        self.theme.errorColor = color
    }

    /// 设置警告颜色
    /// - Parameter color: 警告颜色
    public func setWarningColor(_ color: UIColor) {
        self.theme.warningColor = color
    }

    /// 设置信息颜色
    /// - Parameter color: 信息颜色
    public func setInfoColor(_ color: UIColor) {
        self.theme.infoColor = color
    }

    /// 设置圆角
    /// - Parameter radius: 圆角半径
    public func setCornerRadius(_ radius: CGFloat) {
        self.theme.cornerRadius = radius
    }

    /// 设置阴影
    /// - Parameter enabled: 是否启用阴影
    public func setShadowEnabled(_ enabled: Bool) {
        self.theme.shadowEnabled = enabled
    }

    /// 设置成功图标
    /// - Parameter iconName: 图标名称
    public func setSuccessIcon(_ iconName: String?) {
        self.theme.successIconName = iconName
    }

    /// 设置错误图标
    /// - Parameter iconName: 图标名称
    public func setErrorIcon(_ iconName: String?) {
        self.theme.errorIconName = iconName
    }

    /// 设置警告图标
    /// - Parameter iconName: 图标名称
    public func setWarningIcon(_ iconName: String?) {
        self.theme.warningIconName = iconName
    }

    /// 设置信息图标
    /// - Parameter iconName: 图标名称
    public func setInfoIcon(_ iconName: String?) {
        self.theme.infoIconName = iconName
    }

    /// 设置图标大小
    /// - Parameter size: 图标大小
    public func setIconSize(_ size: CGSize) {
        self.theme.iconSize = size
    }

    /// 设置标签字体
    /// - Parameter font: 字体
    public func setLabelFont(_ font: UIFont?) {
        self.theme.labelFont = font
    }

    /// 设置详细标签字体
    /// - Parameter font: 字体
    public func setDetailLabelFont(_ font: UIFont?) {
        self.theme.detailLabelFont = font
    }
        
    /// 使用配置显示 HUD
    /// - Parameter config: HUD 配置
    internal func show(with config: STHUDConfig) {
        let finalTitle = config.isLocalized ? config.title.localized : config.title
        let finalDetailText = config.detailText != nil ? (config.isLocalized ? config.detailText!.localized : config.detailText!) : nil
        let keyWindow = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first(where: \.isKeyWindow)
        if let window = keyWindow {
            if self.progressHUD?.superview != nil {
                self.progressHUD?.hide(animated: true)
            }
            self.progressHUD = STProgressHUD.init(withView: window)
            self.configHUBCommonProperty()
            if let hud = self.progressHUD { window.addSubview(hud) }
        }
        let isIconType: Bool = [.success, .error, .warning, .info].contains(config.type)
        if let customView = config.customView {
            // 用户传入自定义视图
            self.progressHUD?.customView = customView
            self.progressHUD?.mode = .customView
        } else if isIconType {
            // 有图标类型：customView 只放图标，label/detailsLabel 由 STProgressHUD 垂直排列
            self.progressHUD?.customView = createIconImageView(for: config.type, iconName: config.iconName)
            self.progressHUD?.mode = .customView
        } else {
            // 无图标类型（loading / text / progress）
            self.setMode(for: config.type)
        }

        self.progressHUD?.label.text = finalTitle
        self.progressHUD?.detailsLabel.text = finalDetailText

        // 设置位置偏移
        let offset = calculateOffset(for: config.location, in: self.progressHUD?.superview)
        self.progressHUD?.offset = offset

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
            iconName: self.theme.successIconName,
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
            iconName: self.theme.errorIconName,
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
            iconName: self.theme.warningIconName,
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
            iconName: self.theme.infoIconName,
            autoHide: autoHide
        )
        self.show(with: config)
    }
    
    /// 显示加载中（需手动调用 st_dismiss 关闭）
    /// - Parameters:
    ///   - title: 标题
    ///   - detailText: 详细文本
    internal func showLoading(title: String = "加载中...", detailText: String? = nil) {
        let config = STHUDConfig(
            type: .loading,
            title: title,
            detailText: detailText,
            autoHide: false
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
        if let hud = self.progressHUD { showInView.addSubview(hud) }
    }
    
    /// 配置通用属性
    private func configHUBCommonProperty() {
        guard let hud = self.progressHUD else { return }
        hud.delegate = self
        hud.label.numberOfLines = 0
        hud.contentColor = self.theme.textColor
        hud.removeFromSuperViewOnHide = true
        if let font = self.theme.labelFont {
            hud.label.font = font
        } else {
            hud.label.font = UIFont.st_systemFont(ofSize: 16, weight: .medium)
        }
        if let detailsLabelFont = self.theme.detailLabelFont {
            hud.detailsLabel.font = detailsLabelFont
        } else {
            hud.detailsLabel.font = UIFont.st_systemFont(ofSize: 14, weight: .regular)
        }
        hud.label.textColor = self.theme.textColor
        hud.detailsLabel.textColor = self.theme.detailTextColor
        hud.bezelView.backgroundColor = self.theme.backgroundColor
        hud.bezelView.style = .solidColor
        hud.bezelView.color = self.theme.backgroundColor
        
        if let hud = self.progressHUD {
            hud.bezelView.layer.cornerRadius = self.theme.cornerRadius
            if self.theme.shadowEnabled {
                hud.bezelView.layer.shadowColor = UIColor.black.cgColor
                hud.bezelView.layer.shadowOffset = CGSize(width: 0, height: 2)
                hud.bezelView.layer.shadowRadius = 4
                hud.bezelView.layer.shadowOpacity = 0.3
            }
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
     
    /// 应用主题
    /// - Parameter theme: 主题配置
    public func applyTheme(_ theme: STHUDTheme) {
        self.theme = theme
    }
    
    /// 设置无图标类型的 HUD 模式
    private func setMode(for type: STHUDType) {
        switch type {
        case .loading:  self.progressHUD?.mode = .indeterminate
        case .progress: self.progressHUD?.mode = .determinate
        default:        self.progressHUD?.mode = .text
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
        
    /// 创建图标视图（仅包含图标，文本由 STProgressHUD 的 label/detailsLabel 显示）
    private func createIconImageView(for type: STHUDType, iconName: String?) -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        let size = theme.iconSize
        imageView.frame = CGRect(origin: .zero, size: size)
        if let name = iconName, let customImage = UIImage(named: name) {
            imageView.image = customImage
        } else {
            let symbolConfig = UIImage.SymbolConfiguration(pointSize: size.width, weight: .semibold)
            imageView.image = UIImage(systemName: defaultSymbolName(for: type), withConfiguration: symbolConfig)?
                .withTintColor(iconColor(for: type), renderingMode: .alwaysOriginal)
        }
        return imageView
    }

    private func defaultSymbolName(for type: STHUDType) -> String {
        switch type {
        case .success: return "checkmark.circle.fill"
        case .error:   return "xmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .info:    return "info.circle.fill"
        default:       return "info.circle.fill"
        }
    }

    private func iconColor(for type: STHUDType) -> UIColor {
        switch type {
        case .success: return theme.successColor
        case .error:   return theme.errorColor
        case .warning: return theme.warningColor
        case .info:    return theme.infoColor
        default:       return theme.infoColor
        }
    }
}

// MARK: - STHUD 代理实现
extension STHUD: STProgressHUDDelegate {
    public func hudWasHidden(_ hud: STProgressHUD) {
        // HUD 隐藏完成
    }
}

// MARK: - STHUD 实用方法
public extension STHUD {
    /// 在异步任务期间显示加载指示器，任务结束后自动隐藏
    /// - Parameters:
    ///   - status: 加载文本
    ///   - task: 异步任务
    /// - Returns: 任务结果
    static func st_showWhileExecuting<T>(status: String? = "加载中...", task: @escaping () async throws -> T) async throws -> T {
        DispatchQueue.main.async {
            self.sharedHUD.showLoading(title: status ?? "加载中...")
        }
        do {
            let result = try await task()
            DispatchQueue.main.async { self.sharedHUD.hide(animated: true) }
            return result
        } catch {
            DispatchQueue.main.async { self.sharedHUD.hide(animated: true) }
            throw error
        }
    }

    /// 根据当前界面样式自动适配 HUD 样式（深色/浅色模式）
    static func st_adaptToUserInterfaceStyle() {
        let isDarkMode = UITraitCollection.current.userInterfaceStyle == .dark
        let bgColor = isDarkMode ? UIColor.black.withAlphaComponent(0.8) : UIColor.white.withAlphaComponent(0.9)
        let txtColor = isDarkMode ? UIColor.white : UIColor.black
        self.sharedHUD.setBackgroundColor(bgColor)
        self.sharedHUD.setTextColor(txtColor)
    }
}

// MARK: - UIView 扩展 - HUD 方法
public extension UIView {
    /// 显示成功提示（带图标，自动隐藏）
    func st_showSuccess(_ text: String, detailText: String? = nil) {
        DispatchQueue.main.async {
            STHUD.sharedHUD.showSuccess(title: text, detailText: detailText)
        }
    }

    /// 显示错误提示（带图标，自动隐藏）
    func st_showError(_ text: String, detailText: String? = nil) {
        DispatchQueue.main.async {
            STHUD.sharedHUD.showError(title: text, detailText: detailText)
        }
    }

    /// 显示警告提示（带图标，自动隐藏）
    func st_showWarning(_ text: String, detailText: String? = nil) {
        DispatchQueue.main.async {
            STHUD.sharedHUD.showWarning(title: text, detailText: detailText)
        }
    }

    /// 显示信息提示（带图标，自动隐藏）
    func st_showInfo(_ text: String, detailText: String? = nil) {
        DispatchQueue.main.async {
            STHUD.sharedHUD.showInfo(title: text, detailText: detailText)
        }
    }

    /// 显示加载指示器（需手动调用 st_dismiss 关闭）
    /// - Parameters:
    ///   - text: 加载文本
    ///   - detailText: 详细文本
    ///   - view: 挂载视图，nil 时挂载到全局 key window
    func st_showLoading(_ text: String = "", detailText: String? = nil, in view: UIView? = nil) {
        DispatchQueue.main.async {
            if let targetView = view {
                STHUD.sharedHUD.configManualHiddenHUD(showInView: targetView)
                STHUD.sharedHUD.progressHUD?.label.text = text
                STHUD.sharedHUD.progressHUD?.detailsLabel.text = detailText
                STHUD.sharedHUD.progressHUD?.show(animated: true)
            } else {
                STHUD.sharedHUD.showLoading(title: text, detailText: detailText)
            }
        }
    }

    /// 显示纯文本 Toast（无图标，自动隐藏）
    func st_showToast(_ text: String, detailText: String? = nil) {
        DispatchQueue.main.async {
            STHUD.sharedHUD.showText(title: text, detailText: detailText)
        }
    }

    /// 关闭 HUD
    func st_dismiss() {
        DispatchQueue.main.async {
            STHUD.sharedHUD.hide(animated: true)
        }
    }

    /// 使用自定义配置显示 HUD
    func st_showHUD(with config: STHUDConfig) {
        DispatchQueue.main.async {
            STHUD.sharedHUD.show(with: config)
        }
    }
}
