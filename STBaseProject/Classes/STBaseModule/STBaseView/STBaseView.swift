//
//  STBaseView.swift
//  STBaseProject
//
//  Created by stack on 2018/3/14.
//

import UIKit

open class STBaseView: UIView {
    
    private var extraContentSizeOffset: CGFloat = 0
        
    deinit {
#if DEBUG
        print("🌈 -> \(self) 🌈 ----> 🌈 dealloc")
#endif
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.st_baseViewAddScrollView()
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        self.st_baseViewAddScrollView()
    }
    
    private func st_baseViewAddScrollView() -> Void {
        self.addSubview(self.baseScrollView )
        self.baseScrollView.addSubview(self.baseContentView)
        self.addConstraints([
                            NSLayoutConstraint.init(item: self.baseScrollView, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 0),
                            NSLayoutConstraint.init(item: self.baseScrollView, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1, constant: 0),
                            NSLayoutConstraint.init(item: self.baseScrollView, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1, constant: 0),
                            NSLayoutConstraint.init(item: self.baseScrollView, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1, constant: 0)
        ])
        self.baseScrollView.addConstraints([
                                            NSLayoutConstraint.init(item: self.baseContentView, attribute: .width, relatedBy: .equal, toItem: self.baseScrollView, attribute: .width, multiplier: 1, constant: 0),
                                            NSLayoutConstraint.init(item: self.baseContentView, attribute: .top, relatedBy: .equal, toItem: self.baseScrollView, attribute: .top, multiplier: 1, constant: 0),
                                            NSLayoutConstraint.init(item: self.baseContentView, attribute: .leading, relatedBy: .equal, toItem: self.baseScrollView, attribute: .leading, multiplier: 1, constant: 0),
                                            NSLayoutConstraint.init(item: self.baseContentView, attribute: .bottom, relatedBy: .equal, toItem: self.baseScrollView, attribute: .bottom, multiplier: 1, constant: 0),
                                            NSLayoutConstraint.init(item: self.baseContentView, attribute: .trailing, relatedBy: .equal, toItem: self.baseScrollView, attribute: .trailing, multiplier: 1, constant: 0)
        ])
    }
    
    public func updateExtraContentSize(offset: CGFloat) {
        self.extraContentSizeOffset = offset
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            var height: CGFloat = 0
            if let lastView = self.baseContentView.subviews.last {
                height = lastView.frame.maxY
            }
            self.baseScrollView.contentSize = CGSize.init(width: self.bounds.size.width, height: height + self.extraContentSizeOffset)
        }
    }
    
    public lazy var baseScrollView: STBaseScrollerView = {
        let scrollView = STBaseScrollerView()
        scrollView.isPagingEnabled = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()
    
    public lazy var baseContentView: UIView = {
        let contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        return contentView
    }()
}

extension UIView {
    public func currentViewController() -> (UIViewController?) {
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

open class STBaseScrollerView: UIScrollView {
    open override func touchesShouldCancel(in view: UIView) -> Bool {
        if view.isKind(of: UIButton.self) {
            return true
        }
        return super.touchesShouldCancel(in: view)
    }
}
