//
//  STViewController.swift
//  STBaseProject
//
//  Created by song on 2020/12/31.
//

public extension UIViewController {
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
