//
//  STBaseViewController.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2018/3/14.
//

import Combine
import UIKit

public enum STNavBtnShowType {
    case none
    case showBothBtn
    case showLeftBtn
    case showRightBtn
    case onlyShowTitle
}

open class STBaseViewController: UIViewController {

    public private(set) var navigationBarView = UIView()
    public private(set) var navigationBarItemsView = UIView()
    public private(set) var navGradientBar: STGradientNavigationBar?
    public var contentTopAnchor: NSLayoutYAxisAnchor { self.navigationBarView.bottomAnchor }

    public private(set) var titleLabel = UILabel()
    public private(set) var leftBtn = UIButton(type: .custom)
    public private(set) var rightBtn = UIButton(type: .custom)

    public var navBarBackgroundColor: UIColor = .white
    public var navBarTitleColor: UIColor = .black
    public var buttonTitleColor: UIColor = .systemBlue
    public var buttonTitleFont: UIFont = .st_systemFont(ofSize: 16)
    public var navBarTitleFont: UIFont = .st_boldSystemFont(ofSize: 20)
    public lazy var navBarHeight: CGFloat = STDeviceAdapter.navigationBarHeight

    public var leftBtnImage: UIImage? {
        didSet {
            self.leftBtn.setImage(self.leftBtnImage, for: .normal)
        }
    }
    public var rightBtnImage: UIImage? {
        didSet {
            self.rightBtn.setImage(self.rightBtnImage, for: .normal)
        }
    }
    public var leftBtnTitle: String? {
        didSet {
            self.leftBtn.setTitle(self.leftBtnTitle, for: .normal)
        }
    }
    public var rightBtnTitle: String? {
        didSet {
            self.rightBtn.setTitle(self.rightBtnTitle, for: .normal)
        }
    }
    public var statusBarHidden: Bool = false
    public var statusBarStyle: UIStatusBarStyle = .default
    open var prefersSystemNavigationBarHidden: Bool { true }

    private var appearanceCancellable: AnyCancellable?
    private var contentOffsetObservation: NSKeyValueObservation?
    public var leftBtnConstraints: [NSLayoutConstraint] = []
    public var rightBtnConstraints: [NSLayoutConstraint] = []
    public var titleLabelConstraints: [NSLayoutConstraint] = []

    open override func viewDidLoad() {
        super.viewDidLoad()
        self.setupNavigationBar()
        self.setupAppearanceObservation()
        self.setupLocalizationObservation()
        self.finalizeLayout()
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(self.prefersSystemNavigationBarHidden, animated: false)
    }

    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.view.bringSubviewToFront(self.navigationBarView)
    }

    deinit {
        self.contentOffsetObservation?.invalidate()
        NotificationCenter.default.removeObserver(self, name: .stLanguageDidChange, object: nil)
    }

    private func setupNavigationBar() {
        self.navigationBarView.translatesAutoresizingMaskIntoConstraints = false
        self.navigationBarItemsView.translatesAutoresizingMaskIntoConstraints = false
        self.titleLabel.translatesAutoresizingMaskIntoConstraints = false
        self.leftBtn.translatesAutoresizingMaskIntoConstraints = false
        self.rightBtn.translatesAutoresizingMaskIntoConstraints = false

        self.view.addSubview(self.navigationBarView)
        self.navigationBarView.addSubview(self.navigationBarItemsView)
        NSLayoutConstraint.activate([
            self.navigationBarView.topAnchor.constraint(equalTo: self.view.topAnchor),
            self.navigationBarView.leftAnchor.constraint(equalTo: self.view.leftAnchor),
            self.navigationBarView.rightAnchor.constraint(equalTo: self.view.rightAnchor),
            self.navigationBarView.bottomAnchor.constraint(equalTo: self.navigationBarItemsView.bottomAnchor)
        ])

        NSLayoutConstraint.activate([
            self.navigationBarItemsView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
            self.navigationBarItemsView.heightAnchor.constraint(equalToConstant: STDeviceAdapter.navigationBarContainerHeight),
            self.navigationBarItemsView.leftAnchor.constraint(equalTo: self.navigationBarView.leftAnchor),
            self.navigationBarItemsView.rightAnchor.constraint(equalTo: self.navigationBarView.rightAnchor)
        ])

        self.navigationBarItemsView.addSubview(self.titleLabel)
        self.titleLabelConstraints = self.st_titleLabelConstraints(in: self.navigationBarItemsView)
        NSLayoutConstraint.activate(self.titleLabelConstraints)

        self.navigationBarItemsView.addSubview(self.leftBtn)
        self.leftBtnConstraints = self.st_leftButtonConstraints(in: self.navigationBarItemsView)
        NSLayoutConstraint.activate(self.leftBtnConstraints)

        self.navigationBarItemsView.addSubview(self.rightBtn)
        self.rightBtnConstraints = self.st_rightButtonConstraints(in: self.navigationBarItemsView)
        NSLayoutConstraint.activate(self.rightBtnConstraints)

        self.leftBtn.addTarget(self, action: #selector(self.onLeftBtnTap), for: .touchUpInside)
        self.rightBtn.addTarget(self, action: #selector(self.onRightBtnTap), for: .touchUpInside)
    }

    /// 子类重写此方法以自定义左按钮约束
    open func st_leftButtonConstraints(in container: UIView) -> [NSLayoutConstraint] {
        let widthConstraint = self.leftBtn.widthAnchor.constraint(greaterThanOrEqualToConstant: 44)
        widthConstraint.priority = .required
        return [
            self.leftBtn.leftAnchor.constraint(equalTo: container.leftAnchor, constant: 8),
            self.leftBtn.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            widthConstraint,
            self.leftBtn.heightAnchor.constraint(equalToConstant: 44)
        ]
    }

    /// 子类重写此方法以自定义右按钮约束
    open func st_rightButtonConstraints(in container: UIView) -> [NSLayoutConstraint] {
        let widthConstraint = self.rightBtn.widthAnchor.constraint(greaterThanOrEqualToConstant: 44)
        widthConstraint.priority = .required
        return [
            self.rightBtn.rightAnchor.constraint(equalTo: container.rightAnchor, constant: -8),
            self.rightBtn.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            widthConstraint,
            self.rightBtn.heightAnchor.constraint(equalToConstant: 44)
        ]
    }

    /// 子类重写此方法以自定义标题约束
    open func st_titleLabelConstraints(in container: UIView) -> [NSLayoutConstraint] {
        return [
            self.titleLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            self.titleLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor)
        ]
    }

    private func finalizeLayout() {
        self.leftBtn.titleLabel?.font = self.buttonTitleFont
        self.rightBtn.titleLabel?.font = self.buttonTitleFont
    }

    private func setupLocalizationObservation() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.st_updateLocalizedTexts),
            name: .stLanguageDidChange,
            object: nil
        )
    }

    private func setupAppearanceObservation() {
        self.st_refreshAppearance(animated: false)
        self.appearanceCancellable = STAppearanceManager.shared.appearanceModePublisher
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.st_refreshAppearance(animated: true)
            }
    }

    /// 外观变化回调，子类重写以自定义颜色处理逻辑
    open func st_appearanceDidChange(resolvedStyle: UIUserInterfaceStyle) {}

    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard STAppearanceManager.shared.currentMode == .system else { return }

        let previousStyle = previousTraitCollection?.userInterfaceStyle ?? .unspecified
        let currentStyle = self.traitCollection.userInterfaceStyle
        if previousStyle != currentStyle && previousStyle != .unspecified {
            self.st_refreshAppearance(animated: true)
        }
    }

    private func st_refreshAppearance(animated: Bool = false) {
        let style = STAppearanceManager.shared.resolvedInterfaceStyle(for: self.traitCollection)
        switch STAppearanceManager.shared.currentMode {
        case .system: self.overrideUserInterfaceStyle = .unspecified
        case .light:  self.overrideUserInterfaceStyle = .light
        case .dark:   self.overrideUserInterfaceStyle = .dark
        }

        let resolvedStyle: UIUserInterfaceStyle = style == .unspecified ? .light : style
        let applyBlock = { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.st_appearanceDidChange(resolvedStyle: resolvedStyle)
        }

        if animated {
            UIView.transition(
                with: self.view, duration: 0.25,
                options: [.transitionCrossDissolve, .allowUserInteraction],
                animations: applyBlock,
                completion: nil)
        } else {
            applyBlock()
        }
    }

    public func st_showNavBtnType(type: STNavBtnShowType) {
        switch type {
        case .showLeftBtn:
            self.leftBtn.isHidden = false
            self.rightBtn.isHidden = true
            self.navigationBarView.isHidden = false
            self.navigationBarItemsView.isHidden = false
        case .showRightBtn:
            self.leftBtn.isHidden = true
            self.rightBtn.isHidden = false
            self.navigationBarView.isHidden = false
            self.navigationBarItemsView.isHidden = false
        case .showBothBtn:
            self.leftBtn.isHidden = false
            self.rightBtn.isHidden = false
            self.navigationBarView.isHidden = false
            self.navigationBarItemsView.isHidden = false
        case .onlyShowTitle:
            self.leftBtn.isHidden = true
            self.rightBtn.isHidden = true
            self.navigationBarView.isHidden = false
            self.navigationBarItemsView.isHidden = false
        case .none:
            self.leftBtn.isHidden = true
            self.rightBtn.isHidden = true
            self.navigationBarView.isHidden = true
            self.navigationBarItemsView.isHidden = true
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
        if self.liquidGlassContainerView == nil {
            self.navigationBarView.backgroundColor = color
        }
        return self
    }

    @discardableResult
    open func st_setLeftBtn(image: UIImage? = nil, title: String? = nil) -> Self {
        if let image { self.leftBtnImage = image }
        if let title { self.leftBtnTitle = title }
        return self
    }

    @discardableResult
    open func st_setRightBtn(image: UIImage? = nil, title: String? = nil) -> Self {
        if let image { self.rightBtnImage = image }
        if let title { self.rightBtnTitle = title }
        return self
    }

    @discardableResult
    open func st_enableGradientNavigationBar(startColor: UIColor, endColor: UIColor) -> Self {
        let gradient = STGradientNavigationBar()
        gradient.startColor = startColor
        gradient.endColor = endColor
        gradient.translatesAutoresizingMaskIntoConstraints = false
        self.navigationBarView.addSubview(gradient)
        NSLayoutConstraint.activate([
            gradient.topAnchor.constraint(equalTo: self.navigationBarView.topAnchor),
            gradient.bottomAnchor.constraint(equalTo: self.navigationBarView.bottomAnchor),
            gradient.leftAnchor.constraint(equalTo: self.navigationBarView.leftAnchor),
            gradient.rightAnchor.constraint(equalTo: self.navigationBarView.rightAnchor)
        ])
        self.navGradientBar = gradient
        return self
    }

    @discardableResult
    open func st_linkScrollAlpha(_ scrollView: UIScrollView) -> Self {
        self.contentOffsetObservation?.invalidate()
        self.contentOffsetObservation = scrollView.observe(
            \.contentOffset, options: [.new, .initial],
            changeHandler: { [weak self] scroll, _ in
                guard let self = self else { return }
                let alpha = max(0, min(1, scroll.contentOffset.y / 120))
                self.navigationBarView.alpha = alpha
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

    @objc open func onRightBtnTap() {}

    open override var preferredStatusBarStyle: UIStatusBarStyle { self.statusBarStyle }
    open override var prefersStatusBarHidden: Bool { self.statusBarHidden }
}

extension STBaseViewController {
    public static func st_setAppearanceMode(_ mode: STAppearanceMode, animated: Bool = true) {
        STAppearanceManager.shared.st_apply(mode: mode)
    }

    public static func st_getCurrentAppearanceMode() -> STAppearanceMode {
        STAppearanceManager.shared.currentMode
    }
}

// MARK: - Liquid Glass
extension STBaseViewController {

    private static var liquidGlassKey: UInt8 = 0

    fileprivate var liquidGlassContainerView: UIView? {
        get { objc_getAssociatedObject(self, &Self.liquidGlassKey) as? UIView }
        set { objc_setAssociatedObject(self, &Self.liquidGlassKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    public var isLiquidGlassEnabled: Bool {
        if #available(iOS 26.0, *) { return self.liquidGlassContainerView != nil }
        return false
    }

    @discardableResult
    public func st_enableLiquidGlass() -> Self {
        guard #available(iOS 26.0, *) else { return self }
        guard self.liquidGlassContainerView == nil else { return self }

        let container = UIVisualEffectView(effect: STGlassEffectFactory.makeVisualEffect())
        container.translatesAutoresizingMaskIntoConstraints = false
        self.navigationBarView.insertSubview(container, at: 0)
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: self.navigationBarView.topAnchor),
            container.bottomAnchor.constraint(equalTo: self.navigationBarView.bottomAnchor),
            container.leftAnchor.constraint(equalTo: self.navigationBarView.leftAnchor),
            container.rightAnchor.constraint(equalTo: self.navigationBarView.rightAnchor)
        ])
        self.liquidGlassContainerView = container
        self.navigationBarView.backgroundColor = .clear
        self.navGradientBar?.isHidden = true
        return self
    }

    public func st_disableLiquidGlass() {
        self.liquidGlassContainerView?.removeFromSuperview()
        self.liquidGlassContainerView = nil
        self.navigationBarView.backgroundColor = self.navBarBackgroundColor
        self.navGradientBar?.isHidden = false
    }
}
