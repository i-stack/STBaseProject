//
//  STBaseViewController.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2018/3/14.
//

import UIKit

public enum STNavBtnShowType {
    case none  // show nothing
    case showBothBtn  // show left button right button and title
    case showLeftBtn  // show left button and title
    case showRightBtn  // show right button and title
    case onlyShowTitle  // only show title
}

open class STBaseViewController: UIViewController {

    public private(set) var navContainerView = UIView()
    public private(set) var navBackgroundView = UIView()
    public private(set) lazy var baseView: STBaseView = {
        let view = STBaseView()
        // 禁用 baseView 的外观管理，由 STBaseViewController 统一管理
        view.enableAppearanceManagement = false
        return view
    }()
    public private(set) var navGradientBar: STGradientNavigationBar?

    public private(set) var titleLabel = UILabel()
    public private(set) var leftBtn = UIButton(type: .custom)
    public private(set) var rightBtn = UIButton(type: .custom)

    public var leftBtnConstraints: [NSLayoutConstraint] = []
    public var rightBtnConstraints: [NSLayoutConstraint] = []
    public var baseViewConstraints: [NSLayoutConstraint] = []
    public var titleLabelConstraints: [NSLayoutConstraint] = []
    public var navContainerHeightConstraint: NSLayoutConstraint?

    public var navBarBackgroundColor: UIColor = .white
    public var navBarTitleColor: UIColor = .black
    public var buttonTitleColor: UIColor = .systemBlue
    public var buttonTitleFont: UIFont = .systemFont(ofSize: 16)
    public var navBarHeight: CGFloat = 88  // default for Notch devices
    public var navBarTitleFont: UIFont = .boldSystemFont(ofSize: 20)

    public var leftBtnImage: UIImage?
    public var rightBtnImage: UIImage?
    public var leftBtnTitle: String?
    public var rightBtnTitle: String?
    public var statusBarHidden: Bool = false
    public var statusBarStyle: UIStatusBarStyle = .default
    
    private var appearanceObserver: NSObjectProtocol?
    private var systemThemeObserver: NSObjectProtocol?
    private var contentOffsetObservation: NSKeyValueObservation?

    open override func viewDidLoad() {
        super.viewDidLoad()
        self.setupNavigationBar()
        self.setupAppearanceObservation()
        self.applyNavButtons()
        self.finalizeLayout()
    }

    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.view.bringSubviewToFront(self.navContainerView)
    }

    deinit {
        self.contentOffsetObservation?.invalidate()
        if let observer = self.appearanceObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = self.systemThemeObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        #if DEBUG
            print("STBaseViewController deinit: \(String(describing: type(of: self)))")
        #endif
    }

    private func setupNavigationBar() {
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        self.navContainerView.translatesAutoresizingMaskIntoConstraints = false
        self.navBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        self.titleLabel.translatesAutoresizingMaskIntoConstraints = false
        self.leftBtn.translatesAutoresizingMaskIntoConstraints = false
        self.rightBtn.translatesAutoresizingMaskIntoConstraints = false

        self.view.addSubview(self.navContainerView)
        self.navContainerView.addSubview(self.navBackgroundView)
        self.navContainerView.addSubview(self.titleLabel)
        self.navContainerView.addSubview(self.leftBtn)
        self.navContainerView.addSubview(self.rightBtn)

        let h = self.navContainerView.heightAnchor.constraint(equalToConstant: self.navBarHeight)
        h.isActive = true
        self.navContainerHeightConstraint = h

        NSLayoutConstraint.activate([
            self.navContainerView.topAnchor.constraint(equalTo: self.view.topAnchor),
            self.navContainerView.leftAnchor.constraint(equalTo: self.view.leftAnchor),
            self.navContainerView.rightAnchor.constraint(equalTo: self.view.rightAnchor),
        ])

        NSLayoutConstraint.activate([
            self.navBackgroundView.topAnchor.constraint(equalTo: self.navContainerView.topAnchor),
            self.navBackgroundView.leftAnchor.constraint(equalTo: self.navContainerView.leftAnchor),
            self.navBackgroundView.rightAnchor.constraint(
                equalTo: self.navContainerView.rightAnchor),
            self.navBackgroundView.bottomAnchor.constraint(
                equalTo: self.navContainerView.bottomAnchor),
        ])

        self.titleLabelConstraints = [
            self.titleLabel.centerXAnchor.constraint(equalTo: self.navContainerView.centerXAnchor),
            self.titleLabel.bottomAnchor.constraint(
                equalTo: self.navContainerView.bottomAnchor, constant: -8),
        ]
        NSLayoutConstraint.activate(self.titleLabelConstraints)

        let leftWidth = self.leftBtn.widthAnchor.constraint(greaterThanOrEqualToConstant: 44)
        leftWidth.priority = .required
        self.leftBtnConstraints = [
            self.leftBtn.leftAnchor.constraint(
                equalTo: self.navContainerView.leftAnchor, constant: 8),
            self.leftBtn.centerYAnchor.constraint(equalTo: self.titleLabel.centerYAnchor),
            leftWidth,
            self.leftBtn.heightAnchor.constraint(equalToConstant: 44),
        ]
        NSLayoutConstraint.activate(self.leftBtnConstraints)

        let rightWidth = self.rightBtn.widthAnchor.constraint(greaterThanOrEqualToConstant: 44)
        rightWidth.priority = .required
        self.rightBtnConstraints = [
            self.rightBtn.rightAnchor.constraint(
                equalTo: self.navContainerView.rightAnchor, constant: -8),
            self.rightBtn.centerYAnchor.constraint(equalTo: self.titleLabel.centerYAnchor),
            rightWidth,
            self.rightBtn.heightAnchor.constraint(equalToConstant: 44),
        ]
        NSLayoutConstraint.activate(self.rightBtnConstraints)

        self.leftBtn.addTarget(self, action: #selector(self.onLeftBtnTap), for: .touchUpInside)
        self.rightBtn.addTarget(self, action: #selector(self.onRightBtnTap), for: .touchUpInside)

        self.view.addSubview(self.baseView)
        self.baseViewConstraints = [
            self.baseView.topAnchor.constraint(equalTo: self.navContainerView.bottomAnchor),
            self.baseView.leftAnchor.constraint(equalTo: self.view.leftAnchor),
            self.baseView.rightAnchor.constraint(equalTo: self.view.rightAnchor),
            self.baseView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
        ]
        NSLayoutConstraint.activate(self.baseViewConstraints)
    }

    private func applyNavButtons() {
        if let img = self.leftBtnImage { self.leftBtn.setImage(img, for: .normal) }
        if let txt = self.leftBtnTitle { self.leftBtn.setTitle(txt, for: .normal) }
        if let img = self.rightBtnImage { self.rightBtn.setImage(img, for: .normal) }
        if let txt = self.rightBtnTitle { self.rightBtn.setTitle(txt, for: .normal) }
    }

    private func finalizeLayout() {
        self.leftBtn.titleLabel?.font = self.buttonTitleFont
        self.rightBtn.titleLabel?.font = self.buttonTitleFont
    }

    private func setupAppearanceObservation() {
        // 监听当通过 st_setAppearanceMode 设置时
        self.appearanceObserver = NotificationCenter.default.addObserver(
            forName: .stAppearanceDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let strongSelf = self else { return }
            strongSelf.st_refreshAppearance(animated: true)
        }

        // 监听系统深浅模式切换通知（仅当模式为 .system 时生效）
        if #available(iOS 13.0, *) {
            self.systemThemeObserver = NotificationCenter.default.addObserver(
                forName: UIApplication.willEnterForegroundNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                guard let strongSelf = self else { return }
                strongSelf.checkSystemThemeChange()
            }
        }
        self.st_refreshAppearance()
    }
    
    /// 检查系统主题变化（当模式为 .system 时）
    @available(iOS 13.0, *)
    private func checkSystemThemeChange() {
        guard STAppearanceManager.shared.currentMode == .system else { return }
        // 这里主要用于应用回到前台时的同步
        self.st_refreshAppearance(animated: false)
    }

    private func st_refreshAppearance(animated: Bool = false) {
        let style = STAppearanceManager.shared.resolvedInterfaceStyle(for: self.traitCollection)
        if #available(iOS 13.0, *) {
            switch STAppearanceManager.shared.currentMode {
            case .system:
                self.overrideUserInterfaceStyle = .unspecified
            case .light:
                self.overrideUserInterfaceStyle = .light
            case .dark:
                self.overrideUserInterfaceStyle = .dark
            }
        }

        let resolvedStyle = style == .unspecified ? .light : style
        let applyBlock = { [weak self] in
            guard let strongSelf = self else { return }
            // 通知子类外观已变化，子类可以重写此方法来自定义处理
            strongSelf.st_appearanceDidChange(resolvedStyle: resolvedStyle)
        }

        if animated {
            UIView.transition(
                with: self.view, duration: 0.25,
                options: [.transitionCrossDissolve, .allowUserInteraction], animations: applyBlock,
                completion: nil)
        } else {
            applyBlock()
        }
    }
    
    /// 外观模式变化时的回调方法（可重写）
    /// SDK 只负责设置 overrideUserInterfaceStyle，具体的颜色设置由使用者在外界或重写此方法时处理
    /// - Parameter resolvedStyle: 解析后的外观样式（.light 或 .dark）
    /// 
    /// 默认实现为空，使用者可以：
    /// 1. 在外界通过属性（如 navBarBackgroundColor、baseView.backgroundColor）设置颜色
    /// 2. 重写此方法来自定义外观变化时的颜色设置逻辑
    open func st_appearanceDidChange(resolvedStyle: UIUserInterfaceStyle) {
        // 默认不自动设置颜色，保持使用者在外界设置的颜色
        // 使用者可以重写此方法来自定义处理逻辑
    }

    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard #available(iOS 13.0, *) else { return }
        
        // 监听系统深浅模式切换
        // 只有当 STAppearanceManager 的模式为 .system（跟随系统）时，才响应系统切换
        guard STAppearanceManager.shared.currentMode == .system else { return }
        
        // 检查系统用户界面风格是否发生变化
        let previousStyle = previousTraitCollection?.userInterfaceStyle ?? .unspecified
        let currentStyle = self.traitCollection.userInterfaceStyle
        if previousStyle != currentStyle && previousStyle != .unspecified {
            // 系统深浅模式切换，自动更新外观
            self.st_refreshAppearance(animated: true)
        }
    }

    public func st_showNavBtnType(type: STNavBtnShowType) {
        switch type {
        case .showLeftBtn:
            self.leftBtn.isHidden = false
            self.rightBtn.isHidden = true
            self.navContainerView.isHidden = false
            self.navBackgroundView.isHidden = false
            break
        case .showRightBtn:
            self.leftBtn.isHidden = true
            self.rightBtn.isHidden = false
            self.navContainerView.isHidden = false
            self.navBackgroundView.isHidden = false
            break
        case .showBothBtn:
            self.leftBtn.isHidden = false
            self.rightBtn.isHidden = false
            self.navContainerView.isHidden = false
            self.navBackgroundView.isHidden = false
            break
        case .onlyShowTitle:
            self.leftBtn.isHidden = true
            self.rightBtn.isHidden = true
            self.navContainerView.isHidden = false
            self.navBackgroundView.isHidden = false
        default:
            self.leftBtn.isHidden = true
            self.rightBtn.isHidden = true
            self.navContainerView.isHidden = true
            self.navBackgroundView.isHidden = true
            break
        }
    }

    @discardableResult
    open func st_setTitle(_ text: String) -> Self {
        self.titleLabel.text = text
        return self
    }

    @discardableResult
    open func st_setNavigationBarColor(_ color: UIColor) -> Self {
        self.navBarBackgroundColor = color
        self.navBackgroundView.backgroundColor = color
        return self
    }

    @discardableResult
    open func st_setNavigationBarHeight(_ height: CGFloat) -> Self {
        self.navBarHeight = height
        self.navContainerHeightConstraint?.constant = height
        self.view.layoutIfNeeded()
        return self
    }

    @discardableResult
    open func st_setLeftBtn(image: UIImage? = nil, title: String? = nil) -> Self {
        self.leftBtnImage = image
        self.leftBtnTitle = title
        if let img = image { self.leftBtn.setImage(img, for: .normal) }
        if let txt = title { self.leftBtn.setTitle(txt, for: .normal) }
        return self
    }

    @discardableResult
    open func st_setRightBtn(image: UIImage? = nil, title: String? = nil) -> Self {
        self.rightBtnImage = image
        self.rightBtnTitle = title
        if let img = image { self.rightBtn.setImage(img, for: .normal) }
        if let txt = title { self.rightBtn.setTitle(txt, for: .normal) }
        return self
    }

    @discardableResult
    open func st_enableGradientNavigationBar(startColor: UIColor, endColor: UIColor) -> Self {
        let gradient = STGradientNavigationBar()
        gradient.startColor = startColor
        gradient.endColor = endColor
        gradient.translatesAutoresizingMaskIntoConstraints = false
        self.navBackgroundView.addSubview(gradient)
        NSLayoutConstraint.activate([
            gradient.topAnchor.constraint(equalTo: self.navBackgroundView.topAnchor),
            gradient.bottomAnchor.constraint(equalTo: self.navBackgroundView.bottomAnchor),
            gradient.leftAnchor.constraint(equalTo: self.navBackgroundView.leftAnchor),
            gradient.rightAnchor.constraint(equalTo: self.navBackgroundView.rightAnchor),
        ])
        self.navGradientBar = gradient
        return self
    }

    @discardableResult
    open func st_linkScrollAlpha(_ scrollView: UIScrollView) -> Self {
        self.contentOffsetObservation?.invalidate()
        self.contentOffsetObservation = scrollView.observe(
            \.contentOffset, options: [.new, .initial],
            changeHandler: { [weak self] scroll, change in
                guard let self = self else { return }
                let offset = scroll.contentOffset.y
                let alpha = max(0, min(1, offset / 120))
                self.navBackgroundView.alpha = alpha
                self.navGradientBar?.alpha = alpha
            })
        return self
    }

    @objc open func onLeftBtnTap() {
        if let nav = self.navigationController, nav.viewControllers.count > 1 {
            nav.popViewController(animated: true)
        } else {
            self.dismiss(animated: true)
        }
    }

    @objc open func onRightBtnTap() {
        // override in subclass
    }

    open override var preferredStatusBarStyle: UIStatusBarStyle { self.statusBarStyle }
    open override var prefersStatusBarHidden: Bool { self.statusBarHidden }
}

// MARK: - 对外接口：设置外观模式
extension STBaseViewController {
    
    /// 设置 SDK 的外观模式（对外接口）
    /// 这是全局方法，会影响所有使用 STBaseViewController 的控制器
    /// - Parameters:
    ///   - mode: 外观模式，支持 .system（跟随系统）、.light（浅色）、.dark（深色）
    ///   - animated: 是否使用动画过渡，默认 true（注意：动画参数仅在实例方法中生效）
    /// 
    /// 使用示例：
    /// ```swift
    /// // 设置为跟随系统
    /// STBaseViewController.st_setAppearanceMode(.system)
    /// 
    /// // 设置为深色模式
    /// STBaseViewController.st_setAppearanceMode(.dark)
    /// 
    /// // 设置为浅色模式
    /// STBaseViewController.st_setAppearanceMode(.light)
    /// ```
    public static func st_setAppearanceMode(_ mode: STAppearanceMode, animated: Bool = true) {
        STAppearanceManager.shared.st_apply(mode: mode)
        // 通知已通过 STAppearanceManager 自动发送，所有 STBaseViewController 实例会自动响应
    }
    
    /// 实例方法：设置当前控制器的外观模式
    /// - Parameters:
    ///   - mode: 外观模式，支持 .system（跟随系统）、.light（浅色）、.dark（深色）
    ///   - animated: 是否使用动画过渡，默认 true
    /// - Returns: 返回自身，支持链式调用
    @discardableResult
    public func st_setAppearanceMode(_ mode: STAppearanceMode, animated: Bool = true) -> Self {
        STAppearanceManager.shared.st_apply(mode: mode)
        // 通知已通过 STAppearanceManager 自动发送，当前控制器会自动响应
        return self
    }
    
    /// 获取当前的外观模式
    public static func st_getCurrentAppearanceMode() -> STAppearanceMode {
        return STAppearanceManager.shared.currentMode
    }
    
    /// 获取当前的外观模式（实例方法）
    public func st_getCurrentAppearanceMode() -> STAppearanceMode {
        return STAppearanceManager.shared.currentMode
    }
}
