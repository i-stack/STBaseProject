//
//  STBtn.swift
//  STBaseProject
//
//  Created by stack on 2019/10/14.
//
import UIKit

public extension UIView {
    func st_setCustomCorners(topLeft: CGFloat,
                          topRight: CGFloat,
                          bottomLeft: CGFloat,
                          bottomRight: CGFloat) {
        let path = UIBezierPath(
            roundedRect: self.bounds,
            byRoundingCorners: [.topLeft, .topRight, .bottomLeft, .bottomRight],
            cornerRadii: CGSize(width: topLeft, height: topRight)
        )
        let maskLayer = CAShapeLayer()
        maskLayer.frame = self.bounds
        maskLayer.path = path.cgPath
        self.layer.mask = maskLayer
    }
}

public extension UIView {
    func currentViewController() -> (UIViewController?) {
        let keyWindow: UIWindow? = st_keyWindow()
        return currentViewController(keyWindow?.rootViewController)
    }

    func currentViewController(_ vc: UIViewController?) -> UIViewController? {
        if vc == nil { return nil }
        if let presentVC = vc?.presentedViewController {
            return currentViewController(presentVC)
        }
        if let tabVC = vc as? UITabBarController {
            if let selectVC = tabVC.selectedViewController {
                return currentViewController(selectVC)
            }
            return nil
        }
        if let naiVC = vc as? UINavigationController {
            return currentViewController(naiVC.visibleViewController)
        }
        return vc
    }
    
    func st_keyWindow() -> UIWindow? {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            for window in windowScene.windows {
                if window.isKeyWindow {
                    return window
                }
            }
        }
        return nil
    }
}
