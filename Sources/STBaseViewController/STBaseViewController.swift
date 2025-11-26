//  STBaseViewController_Modern_Revised.swift
//  2025 – Modern Architecture
//  Includes: STBaseView integration, full custom navigation bar,
//  exposed constraints for subclasses to modify button/title positions.

import UIKit

public enum STNavBtnShowType {
    case none               // show nothing
    case showBothBtn        // show left button right button and title
    case showLeftBtn        // show left button and title
    case showRightBtn       // show right button and title
    case onlyShowTitle      // only show title
}

public enum STNavBarStyle {
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

    public var navBarStyle: STNavBarStyle = .light
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

    open override func loadView() {
        self.baseView = STBaseView()
        self.view = self.baseView
    }

    open override func viewDidLoad() {
        super.viewDidLoad()
        self.selfSetupNavigationBar()
        self.selfApplyNavBarStyle()
        self.selfApplyNavButtons()
        self.selfFinalizeLayout()
    }

    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.view.bringSubviewToFront(self.navContainerView)
    }

    deinit {
        self.contentOffsetObservation?.invalidate()
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

    private func selfApplyNavBarStyle() {
        switch self.navBarStyle {
        case .light:
            self.navBarBackgroundColor = .white
            self.navBarTitleColor = .black
            self.buttonTitleColor = .systemBlue
            self.statusBarStyle = .default
        case .dark:
            self.navBarBackgroundColor = .black
            self.navBarTitleColor = .white
            self.buttonTitleColor = .white
            self.statusBarStyle = .lightContent
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
