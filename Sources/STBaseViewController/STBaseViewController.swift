//
//  STBaseViewController.swift
//  STBaseProject
//
//  Created by stack on 2018/3/14.
//

import UIKit

public enum STNavBtnShowType {
    case none               // show nothing
    case showBothBtn        // show left button right button and title
    case showLeftBtn        // show left button and title
    case showRightBtn       // show right button and title
    case onlyShowTitle      // only show title
}

public enum STNavBarStyle {
    case system      // 跟随当前外观
    case light
    case dark
    case custom
}

open class STBaseViewController: UIViewController {

    public private(set) var baseView: STBaseView!
    public private(set) var navContainerView = UIView()
    public private(set) var navBackgroundView = UIView()
    public private(set) var navGradientBar: STGradientNavigationBar?
    
    public private(set) var titleLabel = UILabel()
    public private(set) var leftBtn = UIButton(type: .custom)
    public private(set) var rightBtn = UIButton(type: .custom)

    public var leftBtnConstraints: [NSLayoutConstraint] = []
    public var rightBtnConstraints: [NSLayoutConstraint] = []
    public var titleLabelConstraints: [NSLayoutConstraint] = []
    public var navContainerHeightConstraint: NSLayoutConstraint?

    public var navBarStyle: STNavBarStyle = .system {
        didSet {
            guard oldValue != navBarStyle else { return }
            if self.isViewLoaded {
                self.st_refreshAppearance()
            }
        }
    }
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
    private var contentOffsetObservation: NSKeyValueObservation?
    private var appearanceObserver: NSObjectProtocol?

    open override func loadView() {
        self.baseView = STBaseView()
        self.view = self.baseView
    }

    open override func viewDidLoad() {
        super.viewDidLoad()
        self.selfSetupNavigationBar()
        self.st_setupAppearanceObservation()
        self.selfApplyNavButtons()
        self.selfFinalizeLayout()
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
        #if DEBUG
        print("STBaseViewController deinit: \(String(describing: type(of: self)))")
        #endif
    }

    private func selfSetupNavigationBar() {
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
            self.navContainerView.rightAnchor.constraint(equalTo: self.view.rightAnchor)
        ])

        NSLayoutConstraint.activate([
            self.navBackgroundView.topAnchor.constraint(equalTo: self.navContainerView.topAnchor),
            self.navBackgroundView.leftAnchor.constraint(equalTo: self.navContainerView.leftAnchor),
            self.navBackgroundView.rightAnchor.constraint(equalTo: self.navContainerView.rightAnchor),
            self.navBackgroundView.bottomAnchor.constraint(equalTo: self.navContainerView.bottomAnchor)
        ])

        self.titleLabelConstraints = [
            self.titleLabel.centerXAnchor.constraint(equalTo: self.navContainerView.centerXAnchor),
            self.titleLabel.bottomAnchor.constraint(equalTo: self.navContainerView.bottomAnchor, constant: -8)
        ]
        NSLayoutConstraint.activate(self.titleLabelConstraints)

        let leftWidth = self.leftBtn.widthAnchor.constraint(greaterThanOrEqualToConstant: 44)
        leftWidth.priority = .required
        self.leftBtnConstraints = [
            self.leftBtn.leftAnchor.constraint(equalTo: self.navContainerView.leftAnchor, constant: 8),
            self.leftBtn.centerYAnchor.constraint(equalTo: self.titleLabel.centerYAnchor),
            leftWidth,
            self.leftBtn.heightAnchor.constraint(equalToConstant: 44)
        ]
        NSLayoutConstraint.activate(self.leftBtnConstraints)

        let rightWidth = self.rightBtn.widthAnchor.constraint(greaterThanOrEqualToConstant: 44)
        rightWidth.priority = .required
        self.rightBtnConstraints = [
            self.rightBtn.rightAnchor.constraint(equalTo: self.navContainerView.rightAnchor, constant: -8),
            self.rightBtn.centerYAnchor.constraint(equalTo: self.titleLabel.centerYAnchor),
            rightWidth,
            self.rightBtn.heightAnchor.constraint(equalToConstant: 44)
        ]
        NSLayoutConstraint.activate(self.rightBtnConstraints)

        self.leftBtn.addTarget(self, action: #selector(self.onLeftBtnTap), for: .touchUpInside)
        self.rightBtn.addTarget(self, action: #selector(self.onRightBtnTap), for: .touchUpInside)
    }

    private func selfApplyNavBarStyle(resolvedStyle: UIUserInterfaceStyle) {
        switch self.navBarStyle {
        case .system:
            self.applyPresetNavColors(isDark: resolvedStyle == .dark)
        case .light:
            self.applyPresetNavColors(isDark: false)
        case .dark:
            self.applyPresetNavColors(isDark: true)
        case .custom:
            break
        }

        self.navBackgroundView.backgroundColor = self.navBarBackgroundColor
        self.titleLabel.textColor = self.navBarTitleColor
        self.titleLabel.font = self.navBarTitleFont
        self.leftBtn.setTitleColor(self.buttonTitleColor, for: .normal)
        self.rightBtn.setTitleColor(self.buttonTitleColor, for: .normal)
    }

    private func selfApplyNavButtons() {
        if let img = self.leftBtnImage { self.leftBtn.setImage(img, for: .normal) }
        if let txt = self.leftBtnTitle { self.leftBtn.setTitle(txt, for: .normal) }
        if let img = self.rightBtnImage { self.rightBtn.setImage(img, for: .normal) }
        if let txt = self.rightBtnTitle { self.rightBtn.setTitle(txt, for: .normal) }
    }

    private func selfFinalizeLayout() {
        self.leftBtn.titleLabel?.font = self.buttonTitleFont
        self.rightBtn.titleLabel?.font = self.buttonTitleFont
    }

    private func applyPresetNavColors(isDark: Bool) {
        if isDark {
            self.navBarBackgroundColor = .black
            self.navBarTitleColor = .white
            self.buttonTitleColor = .white
            self.statusBarStyle = .lightContent
        } else {
            self.navBarBackgroundColor = .white
            self.navBarTitleColor = .black
            self.buttonTitleColor = .systemBlue
            if #available(iOS 13.0, *) {
                self.statusBarStyle = .darkContent
            } else {
                self.statusBarStyle = .default
            }
        }
    }

    private func st_setupAppearanceObservation() {
        self.appearanceObserver = NotificationCenter.default.addObserver(
            forName: .stAppearanceDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.st_refreshAppearance(animated: true)
        }
        self.st_refreshAppearance()
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

        let applyBlock = { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.selfApplyNavBarStyle(resolvedStyle: style == .unspecified ? .light : style)
            strongSelf.baseView?.st_applyAppearance(style == .unspecified ? .light : style)
            strongSelf.setNeedsStatusBarAppearanceUpdate()
        }

        if animated {
            UIView.transition(with: self.view, duration: 0.25, options: [.transitionCrossDissolve, .allowUserInteraction], animations: applyBlock, completion: nil)
        } else {
            applyBlock()
        }
    }

    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard #available(iOS 13.0, *) else { return }
        guard STAppearanceManager.shared.currentMode == .system else { return }
        if previousTraitCollection?.userInterfaceStyle != self.traitCollection.userInterfaceStyle {
            self.st_refreshAppearance()
        }
    }
    
    public func st_showNavBtnType(type: STNavBtnShowType) -> Void {
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
            gradient.rightAnchor.constraint(equalTo: self.navBackgroundView.rightAnchor)
        ])
        self.navGradientBar = gradient
        return self
    }

    @discardableResult
    open func st_linkScrollAlpha(_ scrollView: UIScrollView) -> Self {
        self.contentOffsetObservation?.invalidate()
        self.contentOffsetObservation = scrollView.observe(\.contentOffset, options: [.new, .initial], changeHandler: { [weak self] scroll, change in
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
