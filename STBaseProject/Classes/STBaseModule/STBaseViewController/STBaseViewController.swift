//
//  STBaseViewController.swift
//  STBaseProject
//
//  Created by stack on 2017/10/4.
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
    case light              // 浅色导航栏
    case dark               // 深色导航栏
    case custom             // 自定义导航栏
}

open class STBaseViewController: UIViewController {

    // MARK: - UI Components
    open var topBgView: UIView!
    open var navBgView: UIView!
    open var leftBtn: UIButton!
    open var rightBtn: UIButton!
    open var titleLabel: UILabel!
    
    // MARK: - Layout Constraints
    private var defaultValue: CGFloat = 44

    open var leftBtnAttributeLeft: NSLayoutConstraint!
    open var leftBtnAttributeWidth: NSLayoutConstraint!
    open var leftBtnAttributeHeight: NSLayoutConstraint!
    
    open var rightBtnAttributeRight: NSLayoutConstraint!
    open var rightBtnAttributeWidth: NSLayoutConstraint!
    open var rightBtnAttributeHeight: NSLayoutConstraint!
    
    open var titleLabelAttributeLeft: NSLayoutConstraint!
    open var titleLabelAttributeRight: NSLayoutConstraint!
    open var titleLabelAttributeHeight: NSLayoutConstraint!

    open var topViewAttributeHeight: NSLayoutConstraint!
    open var navBgViewAttributeHeight: NSLayoutConstraint!

    // MARK: - Navigation Bar Configuration
    open var navBarStyle: STNavBarStyle = .light
    open var navBarBackgroundColor: UIColor = UIColor.white
    open var navBarTitleColor: UIColor = UIColor.black
    open var navBarTitleFont: UIFont = UIFont.boldSystemFont(ofSize: 20)
    open var navBarHeight: CGFloat {
        return navHeight()
    }
    
    // MARK: - Button Configuration
    open var leftButtonImage: UIImage?
    open var rightButtonImage: UIImage?
    open var leftButtonTitle: String?
    open var rightButtonTitle: String?
    open var buttonTitleColor: UIColor = UIColor.systemBlue
    open var buttonTitleFont: UIFont = UIFont.systemFont(ofSize: 16)
    
    // MARK: - Status Bar Configuration
    open var statusBarStyle: UIStatusBarStyle = .default
    open var shouldHideStatusBar: Bool = false

    deinit {
        STLog("🌈 -> \(self) 🌈 ----> 🌈 dealloc")
    }

    override open func viewDidLoad() {
        super.viewDidLoad()
        self.st_baseConfig()
        self.st_navigationBarView()
        self.st_configureNavigationBar()
    }
    
    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.st_updateStatusBarStyle()
    }
    
    private func st_baseConfig() -> Void {
        self.hidesBottomBarWhenPushed = true
        self.view.backgroundColor = UIColor.white
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        self.navigationController?.interactivePopGestureRecognizer?.delegate = nil
    }
    
    private func st_navigationBarView() -> Void {
        self.topBgView = UIView()
        self.topBgView.isHidden = true
        self.topBgView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.topBgView)
        
        self.navBgView = UIView()
        self.navBgView.isHidden = true
        self.navBgView.translatesAutoresizingMaskIntoConstraints = false
        self.topBgView.addSubview(self.navBgView)
        
        self.titleLabel = UILabel()
        self.titleLabel.textAlignment = NSTextAlignment.center
        self.titleLabel.font = self.navBarTitleFont
        self.titleLabel.textColor = self.navBarTitleColor
        self.titleLabel.translatesAutoresizingMaskIntoConstraints = false
        self.navBgView.addSubview(self.titleLabel)
    
        self.leftBtn = UIButton.init(type: UIButton.ButtonType.custom)
        self.leftBtn.isHidden = true
        self.leftBtn.translatesAutoresizingMaskIntoConstraints = false
        self.leftBtn.titleLabel?.font = self.buttonTitleFont
        self.leftBtn.setTitleColor(self.buttonTitleColor, for: .normal)
        self.leftBtn.addTarget(self, action: #selector(st_leftBarBtnClick), for: UIControl.Event.touchUpInside)
        self.navBgView.addSubview(self.leftBtn)
        
        self.rightBtn = UIButton.init(type: UIButton.ButtonType.custom)
        self.rightBtn.isHidden = true
        self.rightBtn.translatesAutoresizingMaskIntoConstraints = false
        self.rightBtn.titleLabel?.font = self.buttonTitleFont
        self.rightBtn.setTitleColor(self.buttonTitleColor, for: .normal)
        self.rightBtn.addTarget(self, action: #selector(st_rightBarBtnClick), for: UIControl.Event.touchUpInside)
        self.navBgView.addSubview(self.rightBtn)
        
        self.st_beginLayoutSubviews()
    }
    
    // MARK: - Navigation Bar Configuration Methods
    open func st_configureNavigationBar() {
        self.st_applyNavBarStyle()
        self.st_configureButtons()
    }
    
    open func st_applyNavBarStyle() {
        switch self.navBarStyle {
        case .light:
            self.navBarBackgroundColor = UIColor.white
            self.navBarTitleColor = UIColor.black
            self.buttonTitleColor = UIColor.systemBlue
            self.statusBarStyle = .default
        case .dark:
            self.navBarBackgroundColor = UIColor.black
            self.navBarTitleColor = UIColor.white
            self.buttonTitleColor = UIColor.white
            self.statusBarStyle = .lightContent
        case .custom:
            break
        }
        
        self.navBgView.backgroundColor = self.navBarBackgroundColor
        self.titleLabel.textColor = self.navBarTitleColor
        self.titleLabel.font = self.navBarTitleFont
        self.leftBtn.setTitleColor(self.buttonTitleColor, for: .normal)
        self.rightBtn.setTitleColor(self.buttonTitleColor, for: .normal)
    }
    
    open func st_configureButtons() {
        if let leftImage = self.leftButtonImage {
            self.leftBtn.setImage(leftImage, for: .normal)
        }
        if let rightImage = self.rightButtonImage {
            self.rightBtn.setImage(rightImage, for: .normal)
        }
        if let leftTitle = self.leftButtonTitle {
            self.leftBtn.setTitle(leftTitle, for: .normal)
        }
        if let rightTitle = self.rightButtonTitle {
            self.rightBtn.setTitle(rightTitle, for: .normal)
        }
    }
    
    open func st_updateStatusBarStyle() {
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    public func st_showNavBtnType(type: STNavBtnShowType) -> Void {
        switch type {
        case .showLeftBtn:
            self.leftBtn.isHidden = false
            self.rightBtn.isHidden = true
            self.topBgView.isHidden = false
            self.navBgView.isHidden = false
            break
        case .showRightBtn:
            self.leftBtn.isHidden = true
            self.rightBtn.isHidden = false
            self.topBgView.isHidden = false
            self.navBgView.isHidden = false
            break
        case .showBothBtn:
            self.leftBtn.isHidden = false
            self.rightBtn.isHidden = false
            self.topBgView.isHidden = false
            self.navBgView.isHidden = false
            break
        case .onlyShowTitle:
            self.leftBtn.isHidden = true
            self.rightBtn.isHidden = true
            self.topBgView.isHidden = false
            self.navBgView.isHidden = false
        default:
            self.leftBtn.isHidden = true
            self.rightBtn.isHidden = true
            self.topBgView.isHidden = true
            self.navBgView.isHidden = true
            break
        }
    }
    
    // MARK: - Public Configuration Methods
    open func st_setNavigationBarStyle(_ style: STNavBarStyle) {
        self.navBarStyle = style
        self.st_applyNavBarStyle()
    }
    
    open func st_setNavigationBarBackgroundColor(_ color: UIColor) {
        self.navBarBackgroundColor = color
        self.navBgView.backgroundColor = color
    }
    
    open func st_setNavigationBarTitleColor(_ color: UIColor) {
        self.navBarTitleColor = color
        self.titleLabel.textColor = color
    }
    
    open func st_setNavigationBarTitleFont(_ font: UIFont) {
        self.navBarTitleFont = font
        self.titleLabel.font = font
    }
    
    open func st_setButtonTitleColor(_ color: UIColor) {
        self.buttonTitleColor = color
        self.leftBtn.setTitleColor(color, for: .normal)
        self.rightBtn.setTitleColor(color, for: .normal)
    }
    
    open func st_setButtonTitleFont(_ font: UIFont) {
        self.buttonTitleFont = font
        self.leftBtn.titleLabel?.font = font
        self.rightBtn.titleLabel?.font = font
    }
    
    open func st_setLeftButton(image: UIImage?, title: String? = nil) {
        self.leftButtonImage = image
        self.leftButtonTitle = title
        if let image = image {
            self.leftBtn.setImage(image, for: .normal)
        }
        if let title = title {
            self.leftBtn.setTitle(title, for: .normal)
        }
    }
    
    open func st_setRightButton(image: UIImage?, title: String? = nil) {
        self.rightButtonImage = image
        self.rightButtonTitle = title
        if let image = image {
            self.rightBtn.setImage(image, for: .normal)
        }
        if let title = title {
            self.rightBtn.setTitle(title, for: .normal)
        }
    }
    
    open func st_setNavigationBarHeight(_ height: CGFloat) {
        self.topViewAttributeHeight.constant = height
        self.view.layoutIfNeeded()
    }
    
    open func st_setStatusBarHidden(_ hidden: Bool) {
        self.shouldHideStatusBar = hidden
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    open func st_setTitle(_ title: String) {
        self.titleLabel.text = title
    }
    
    open func st_setTitleView(_ titleView: UIView) {
        self.titleLabel.removeFromSuperview()
        titleView.translatesAutoresizingMaskIntoConstraints = false
        self.navBgView.addSubview(titleView)
        NSLayoutConstraint.activate([
            titleView.centerXAnchor.constraint(equalTo: self.navBgView.centerXAnchor),
            titleView.centerYAnchor.constraint(equalTo: self.navBgView.centerYAnchor),
            titleView.heightAnchor.constraint(equalToConstant: self.defaultValue)
        ])
    }
    
    private func st_beginLayoutSubviews() -> Void {
        self.topViewAttributeHeight = NSLayoutConstraint.init(item: self.topBgView!, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: self.navHeight())
        self.view.addConstraints([
            NSLayoutConstraint.init(item: self.topBgView!, attribute: .top, relatedBy: .equal, toItem: self.view, attribute: .top, multiplier: 1, constant: 0),
            NSLayoutConstraint.init(item: self.topBgView!, attribute: .left, relatedBy: .equal, toItem: self.view, attribute: .left, multiplier: 1, constant: 0),
            NSLayoutConstraint.init(item: self.topBgView!, attribute: .right, relatedBy: .equal, toItem: self.view, attribute: .right, multiplier: 1, constant: 0),
            self.topViewAttributeHeight
        ])
        
        self.navBgViewAttributeHeight = NSLayoutConstraint.init(item: self.navBgView!, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 44)
        self.view.addConstraints([
            NSLayoutConstraint.init(item: self.navBgView!, attribute: .bottom, relatedBy: .equal, toItem: self.topBgView, attribute: .bottom, multiplier: 1, constant: 0),
            NSLayoutConstraint.init(item: self.navBgView!, attribute: .left, relatedBy: .equal, toItem: self.topBgView, attribute: .left, multiplier: 1, constant: 0),
            NSLayoutConstraint.init(item: self.navBgView!, attribute: .right, relatedBy: .equal, toItem: self.topBgView, attribute: .right, multiplier: 1, constant: 0),
            self.navBgViewAttributeHeight
        ])
        
        self.titleLabelAttributeLeft = NSLayoutConstraint.init(item: self.titleLabel!, attribute: .left, relatedBy: .equal, toItem: self.navBgView, attribute: .left, multiplier: 1, constant: 0)
        self.titleLabelAttributeRight = NSLayoutConstraint.init(item: self.titleLabel!, attribute: .right, relatedBy: .equal, toItem: self.navBgView, attribute: .right, multiplier: 1, constant: 0)
        self.titleLabelAttributeHeight = NSLayoutConstraint.init(item: self.titleLabel!, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: defaultValue)
        self.view.addConstraints([
            NSLayoutConstraint.init(item: self.titleLabel!, attribute: .centerY, relatedBy: .equal, toItem: self.navBgView, attribute: .centerY, multiplier: 1, constant: 0),
            self.titleLabelAttributeLeft,
            self.titleLabelAttributeRight,
            self.titleLabelAttributeHeight
        ])
        
        self.leftBtnAttributeLeft = NSLayoutConstraint.init(item: self.leftBtn!, attribute: .left, relatedBy: .equal, toItem: self.navBgView, attribute: .left, multiplier: 1, constant: 0)
        self.leftBtnAttributeWidth = NSLayoutConstraint.init(item: self.leftBtn!, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: defaultValue)
        self.leftBtnAttributeHeight = NSLayoutConstraint.init(item: self.leftBtn!, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: defaultValue)
        self.view.addConstraints([
            NSLayoutConstraint.init(item: self.leftBtn!, attribute: .centerY, relatedBy: .equal, toItem: self.navBgView, attribute: .centerY, multiplier: 1, constant: 0),
            self.leftBtnAttributeLeft,
            self.leftBtnAttributeHeight,
            self.leftBtnAttributeWidth
        ])
                
        self.rightBtnAttributeWidth = NSLayoutConstraint.init(item: self.rightBtn!, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: defaultValue)
        self.rightBtnAttributeHeight = NSLayoutConstraint.init(item: self.rightBtn!, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: defaultValue)
        self.rightBtnAttributeRight = NSLayoutConstraint.init(item: self.rightBtn!, attribute: .right, relatedBy: .equal, toItem: self.navBgView, attribute: .right, multiplier: 1, constant: 0)
        self.view.addConstraints([
            NSLayoutConstraint.init(item: self.rightBtn!, attribute: .centerY, relatedBy: .equal, toItem: self.navBgView, attribute: .centerY, multiplier: 1, constant: 0),
            self.rightBtnAttributeRight,
            self.rightBtnAttributeHeight,
            self.rightBtnAttributeWidth
        ])
    }
    
    @objc open func st_leftBarBtnClick() -> Void {
        if self.navigationController != nil, self.navigationController?.viewControllers.count ?? 0 > 1 {
            self.navigationController?.popViewController(animated: true)
        } else {
            self.dismiss(animated: true) {}
        }
    }
    
    @objc open func st_rightBarBtnClick() -> Void {}
    
    private func navHeight() -> CGFloat {
        if UIScreen.main.bounds.size.height > 736 {
            return 88.0
        }
        return 64.0
    }
    
    // MARK: - Status Bar Override
    override open var preferredStatusBarStyle: UIStatusBarStyle {
        return self.statusBarStyle
    }
    
    override open var prefersStatusBarHidden: Bool {
        return self.shouldHideStatusBar
    }
}

extension STBaseViewController: UIGestureRecognizerDelegate {
    open func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let nav = self.navigationController {
            if nav.viewControllers.count <= 1 {
                return false
            }
        }
        return true
    }

    open func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer.isKind(of: UIPanGestureRecognizer.self) == true && otherGestureRecognizer.isKind(of: UIScreenEdgePanGestureRecognizer.self) == true {
            return true
        }
        return false
    }
}

public extension STBaseViewController {
    func st_isDark() -> Bool {
        if #available(iOS 12.0, *) {
            if self.traitCollection.userInterfaceStyle == .dark {
                return true
            }
        }
        return false
    }
    
    // effect as present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil)
    func st_setPushAnimatedPresentWithTransition(customSelf: UINavigationController) {
        let animation = CATransition.init()
        animation.duration = 0.3
        animation.type = CATransitionType.moveIn
        animation.subtype = CATransitionSubtype.fromTop
        customSelf.view.layer.add(animation, forKey: nil)
    }
    
    // effect as dismiss(animated: Bool, completion: (() -> Void)? = nil)
    func st_setPushAnimatedDismissWithTransition(customSelf: UINavigationController) {
        let animation = CATransition.init()
        animation.duration = 0.3
        animation.type = CATransitionType.moveIn
        animation.subtype = CATransitionSubtype.fromBottom
        customSelf.view.layer.add(animation, forKey: nil)
    }
    
    func st_currentVC() -> UIViewController {
        if let keyWindow = self.view.st_keyWindow() {
            if let rootViewController = keyWindow.rootViewController {
                let currentViewController = self.st_getCurrentViewControllerFrom(rootVC: rootViewController)
                return currentViewController
            }
        }
        return UIViewController()
    }
    
    func st_getCurrentViewControllerFrom(rootVC: UIViewController) -> UIViewController {
        var currentVC = rootVC
        if let currentViewContoller = rootVC.presentedViewController {
            currentVC = currentViewContoller
        }
        if rootVC.isKind(of: UINavigationController.self) {
            let nav = rootVC as! UINavigationController
            if let visibleViewController = nav.visibleViewController {
                currentVC = self.st_getCurrentViewControllerFrom(rootVC: visibleViewController)
            }
        } else if rootVC.isKind(of: UITabBarController.self) {
            let tabBar = rootVC as! UITabBarController
            if let selectedViewController = tabBar.selectedViewController {
                currentVC = self.st_getCurrentViewControllerFrom(rootVC: selectedViewController)
            }
        }
        return currentVC
    }
}
