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

/// 默认导航栏按钮与标题布局数值；与 `STBaseViewController` 内置约束实现配套。
/// 若子类重写 `st_leftButtonConstraints` / `st_rightButtonConstraints` / `st_titleLabelConstraints`，请同步调整标题最大宽度等约束。
public enum STDefaultNavigationBarItemMetrics {
    public static let horizontalInset: CGFloat = 8
    public static let buttonMinTouchSize: CGFloat = 44
    /// 按钮与标题之间的默认间距（与 `horizontalInset` 一致）
    public static let titleToButtonSpacing: CGFloat = horizontalInset
    /// 单侧为标题预留的横向空间：边距 + 最小触摸宽度
    public static var reservedWidthPerSide: CGFloat { horizontalInset + buttonMinTouchSize }
    /// `titleLabel.width <= container.width + constant` 中的 constant（两侧各 `reservedWidthPerSide`）
    public static var titleMaxWidthLayoutConstant: CGFloat { -2 * reservedWidthPerSide }
}

open class STBaseViewController: UIViewController {

    public private(set) var navigationBarView = UIView()
    public private(set) var navigationBarItemsView = UIView()
    public private(set) var navGradientBar: STGradientNavigationBar?
    public var contentTopAnchor: NSLayoutYAxisAnchor { self.navigationBarView.bottomAnchor }

    public private(set) var titleLabel = UILabel()
    public private(set) var leftBtn = UIButton(type: .custom)
    public private(set) var rightBtn = UIButton(type: .custom)

    public var navBarBackgroundColor: UIColor = .white {
        didSet {
            if self.liquidGlassContainerView == nil {
                self.navigationBarView.backgroundColor = self.navBarBackgroundColor
            }
        }
    }
    public var navBarTitleColor: UIColor = .black {
        didSet { self.titleLabel.textColor = self.navBarTitleColor }
    }
    public var buttonTitleColor: UIColor = .systemBlue {
        didSet {
            self.leftBtn.setTitleColor(self.buttonTitleColor, for: .normal)
            self.rightBtn.setTitleColor(self.buttonTitleColor, for: .normal)
        }
    }
    public var buttonTitleFont: UIFont = .st_systemFont(ofSize: 16) {
        didSet {
            self.leftBtn.titleLabel?.font = self.buttonTitleFont
            self.rightBtn.titleLabel?.font = self.buttonTitleFont
        }
    }
    public var navBarTitleFont: UIFont = .st_boldSystemFont(ofSize: 20) {
        didSet { self.titleLabel.font = self.navBarTitleFont }
    }
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
    private var lastAppliedInterfaceStyle: UIUserInterfaceStyle?
    public var leftBtnConstraints: [NSLayoutConstraint] = [] {
        didSet {
            NSLayoutConstraint.deactivate(oldValue)
            NSLayoutConstraint.activate(self.leftBtnConstraints)
        }
    }
    public var rightBtnConstraints: [NSLayoutConstraint] = [] {
        didSet {
            NSLayoutConstraint.deactivate(oldValue)
            NSLayoutConstraint.activate(self.rightBtnConstraints)
        }
    }
    public var titleLabelConstraints: [NSLayoutConstraint] = [] {
        didSet {
            NSLayoutConstraint.deactivate(oldValue)
            NSLayoutConstraint.activate(self.titleLabelConstraints)
        }
    }

    open override func viewDidLoad() {
        super.viewDidLoad()
        self.setupNavigationBar()
        self.setupAppearanceObservation()
        self.setupLocalizationObservation()
        self.applyDefaultNavigationBarStyle()
        self.st_updateLocalizedTexts()
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let nav = self.navigationController,
           nav.isNavigationBarHidden != self.prefersSystemNavigationBarHidden {
            nav.setNavigationBarHidden(self.prefersSystemNavigationBarHidden, animated: animated)
        }
    }

    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if self.view.subviews.last !== self.navigationBarView {
            self.view.bringSubviewToFront(self.navigationBarView)
        }
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
            self.navigationBarView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.navigationBarView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            self.navigationBarView.bottomAnchor.constraint(equalTo: self.navigationBarItemsView.bottomAnchor)
        ])

        NSLayoutConstraint.activate([
            self.navigationBarItemsView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
            self.navigationBarItemsView.heightAnchor.constraint(equalToConstant: STDeviceAdapter.navigationBarContainerHeight),
            self.navigationBarItemsView.leadingAnchor.constraint(equalTo: self.navigationBarView.leadingAnchor),
            self.navigationBarItemsView.trailingAnchor.constraint(equalTo: self.navigationBarView.trailingAnchor)
        ])

        self.navigationBarItemsView.addSubview(self.titleLabel)
        self.configureDefaultTitleLabelAppearance()
        self.titleLabelConstraints = self.st_titleLabelConstraints(in: self.navigationBarItemsView)

        self.navigationBarItemsView.addSubview(self.leftBtn)
        self.leftBtnConstraints = self.st_leftButtonConstraints(in: self.navigationBarItemsView)

        self.navigationBarItemsView.addSubview(self.rightBtn)
        self.rightBtnConstraints = self.st_rightButtonConstraints(in: self.navigationBarItemsView)

        self.leftBtn.addTarget(self, action: #selector(self.onLeftBtnTap), for: .touchUpInside)
        self.rightBtn.addTarget(self, action: #selector(self.onRightBtnTap), for: .touchUpInside)

        self.view.bringSubviewToFront(self.navigationBarView)
    }

    private func configureDefaultTitleLabelAppearance() {
        self.titleLabel.numberOfLines = 1
        self.titleLabel.lineBreakMode = .byTruncatingTail
        self.titleLabel.textAlignment = .center
        self.titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        self.titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
    }

    /// 子类重写此方法以自定义左按钮约束
    open func st_leftButtonConstraints(in container: UIView) -> [NSLayoutConstraint] {
        let inset = STDefaultNavigationBarItemMetrics.horizontalInset
        let minSize = STDefaultNavigationBarItemMetrics.buttonMinTouchSize
        let gap = STDefaultNavigationBarItemMetrics.titleToButtonSpacing
        let avoidTitleOverlap = self.leftBtn.trailingAnchor.constraint(lessThanOrEqualTo: self.titleLabel.leadingAnchor, constant: -gap)
        avoidTitleOverlap.priority = .defaultHigh
        return [
            self.leftBtn.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: inset),
            self.leftBtn.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            self.leftBtn.widthAnchor.constraint(greaterThanOrEqualToConstant: minSize),
            self.leftBtn.heightAnchor.constraint(equalToConstant: minSize),
            avoidTitleOverlap
        ]
    }

    /// 子类重写此方法以自定义右按钮约束
    open func st_rightButtonConstraints(in container: UIView) -> [NSLayoutConstraint] {
        let inset = STDefaultNavigationBarItemMetrics.horizontalInset
        let minSize = STDefaultNavigationBarItemMetrics.buttonMinTouchSize
        let gap = STDefaultNavigationBarItemMetrics.titleToButtonSpacing
        let avoidTitleOverlap = self.rightBtn.leadingAnchor.constraint(greaterThanOrEqualTo: self.titleLabel.trailingAnchor, constant: gap)
        avoidTitleOverlap.priority = .defaultHigh
        return [
            self.rightBtn.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -inset),
            self.rightBtn.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            self.rightBtn.widthAnchor.constraint(greaterThanOrEqualToConstant: minSize),
            self.rightBtn.heightAnchor.constraint(equalToConstant: minSize),
            avoidTitleOverlap
        ]
    }

    /// 子类重写此方法以自定义标题约束
    open func st_titleLabelConstraints(in container: UIView) -> [NSLayoutConstraint] {
        return [
            self.titleLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            self.titleLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            self.titleLabel.widthAnchor.constraint(
                lessThanOrEqualTo: container.widthAnchor,
                constant: STDefaultNavigationBarItemMetrics.titleMaxWidthLayoutConstant
            )
        ]
    }

    /// 替换左按钮约束；自动停用旧约束、启用新约束
    @discardableResult
    public func st_replaceLeftButtonConstraints(_ builder: (UIView) -> [NSLayoutConstraint]) -> Self {
        self.leftBtnConstraints = builder(self.navigationBarItemsView)
        return self
    }

    /// 替换右按钮约束；自动停用旧约束、启用新约束
    @discardableResult
    public func st_replaceRightButtonConstraints(_ builder: (UIView) -> [NSLayoutConstraint]) -> Self {
        self.rightBtnConstraints = builder(self.navigationBarItemsView)
        return self
    }

    /// 替换标题约束；自动停用旧约束、启用新约束
    @discardableResult
    public func st_replaceTitleLabelConstraints(_ builder: (UIView) -> [NSLayoutConstraint]) -> Self {
        self.titleLabelConstraints = builder(self.navigationBarItemsView)
        return self
    }

    private func applyDefaultNavigationBarStyle() {
        if self.liquidGlassContainerView == nil {
            self.navigationBarView.backgroundColor = self.navBarBackgroundColor
        }
        self.titleLabel.textColor = self.navBarTitleColor
        self.titleLabel.font = self.navBarTitleFont
        self.leftBtn.titleLabel?.font = self.buttonTitleFont
        self.rightBtn.titleLabel?.font = self.buttonTitleFont
        self.leftBtn.setTitleColor(self.buttonTitleColor, for: .normal)
        self.rightBtn.setTitleColor(self.buttonTitleColor, for: .normal)
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
        let targetOverride: UIUserInterfaceStyle
        switch STAppearanceManager.shared.currentMode {
        case .system: targetOverride = .unspecified
        case .light:  targetOverride = .light
        case .dark:   targetOverride = .dark
        }
        if self.overrideUserInterfaceStyle != targetOverride {
            self.overrideUserInterfaceStyle = targetOverride
        }

        let resolvedStyle: UIUserInterfaceStyle = style == .unspecified ? .light : style
        if self.lastAppliedInterfaceStyle == resolvedStyle { return }
        self.lastAppliedInterfaceStyle = resolvedStyle

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
        let hideBar = (type == .none)
        self.navigationBarView.isHidden = hideBar
        self.navigationBarItemsView.isHidden = hideBar
        switch type {
        case .showLeftBtn:
            self.leftBtn.isHidden = false
            self.rightBtn.isHidden = true
        case .showRightBtn:
            self.leftBtn.isHidden = true
            self.rightBtn.isHidden = false
        case .showBothBtn:
            self.leftBtn.isHidden = false
            self.rightBtn.isHidden = false
        case .onlyShowTitle, .none:
            self.leftBtn.isHidden = true
            self.rightBtn.isHidden = true
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
        self.navGradientBar?.removeFromSuperview()
        let gradient = STGradientNavigationBar()
        gradient.startColor = startColor
        gradient.endColor = endColor
        gradient.translatesAutoresizingMaskIntoConstraints = false
        // 始终插在 gradient 层次最底部（液态玻璃容器若存在则在其下方），并在玻璃启用时默认隐藏，
        // 与 st_enableLiquidGlass() 的语义保持一致："Liquid Glass 优先，Gradient 让位"
        self.navigationBarView.insertSubview(gradient, at: 0)
        if self.liquidGlassContainerView != nil {
            gradient.isHidden = true
        }
        NSLayoutConstraint.activate([
            gradient.topAnchor.constraint(equalTo: self.navigationBarView.topAnchor),
            gradient.bottomAnchor.constraint(equalTo: self.navigationBarView.bottomAnchor),
            gradient.leadingAnchor.constraint(equalTo: self.navigationBarView.leadingAnchor),
            gradient.trailingAnchor.constraint(equalTo: self.navigationBarView.trailingAnchor)
        ])
        self.navGradientBar = gradient
        return self
    }

    @discardableResult
    open func st_linkScrollAlpha(_ scrollView: UIScrollView, threshold: CGFloat = 120) -> Self {
        self.contentOffsetObservation?.invalidate()
        let clampedThreshold = max(1, threshold)
        self.contentOffsetObservation = scrollView.observe(
            \.contentOffset, options: [.new, .initial],
            changeHandler: { [weak self] scroll, _ in
                guard let self = self else { return }
                let alpha = max(0, min(1, scroll.contentOffset.y / clampedThreshold))
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
            container.leadingAnchor.constraint(equalTo: self.navigationBarView.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: self.navigationBarView.trailingAnchor)
        ])
        self.liquidGlassContainerView = container
        self.navigationBarView.backgroundColor = .clear
        self.navGradientBar?.isHidden = true
        return self
    }

    public func st_disableLiquidGlass() {
        guard self.liquidGlassContainerView != nil else { return }
        self.liquidGlassContainerView?.removeFromSuperview()
        self.liquidGlassContainerView = nil
        self.navigationBarView.backgroundColor = self.navBarBackgroundColor
        self.navGradientBar?.isHidden = false
    }
}
