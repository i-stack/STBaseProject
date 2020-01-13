//
//  STBaseViewController.swift
//  STBaseProject
//
//  Created by song on 2018/11/4.
//  Copyright © 2018年 song. All rights reserved.
//

import UIKit

public enum STNavBtnShowType {
    case showLeftBtn        // 显示左侧按钮和title
    case showRightBtn       // 显示右侧按钮和title
    case showBothBtn        // 显示左侧、右侧按钮和title
    case onlyShowTitle      // 只显示title （title 与左右间距14）
    case none               // 默认什么都不显示
}

open class STBaseViewController: UIViewController, UIGestureRecognizerDelegate {

    open var topBgView: UIView!
    open var leftBtn: UIButton!
    open var rightBtn: UIButton!
    open var titleLabel: UILabel!
    
    open var space: CGFloat = 0
    open var width: CGFloat = 44
    open var height: CGFloat = 44
    open var leftSpace: CGFloat = 37
    open var rightSpace: CGFloat = 14
    open var titleHeight: CGFloat = 44
    
    open var noDataView: UIView?
    open var networkNotReachView: UIView?
    
    open var leftBtnAttributeRight: NSLayoutConstraint!
    open var titleLabelAttributeLeft: NSLayoutConstraint!
    open var titleLabelAttributeRight: NSLayoutConstraint!
    open var rightBtnAttributeLeft: NSLayoutConstraint!

    deinit {
        NotificationCenter.default.removeObserver(self)
        print("🌈 -> \(self) 🌈 ----> 🌈 dealloc")
    }

    override open func viewDidLoad() {
        super.viewDidLoad()
        self.hidesBottomBarWhenPushed = true
        self.view.backgroundColor = UIColor.white
        self.automaticallyAdjustsScrollViewInsets = false
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true

        self.st_navigationBarView()
    }
    
    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let nav = self.navigationController {
            if nav.viewControllers.count <= 1 {
                self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
            }
        }
    }
    
    open func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let nav = self.navigationController {
            if nav.viewControllers.count <= 1 {
                return false
            }
        }
        return true
    }

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer.isKind(of: UIPanGestureRecognizer.self) == true && otherGestureRecognizer.isKind(of: UIScreenEdgePanGestureRecognizer.self) == true {
            return true
        }
        return true
    }
    
    private func st_navigationBarView() -> Void {
        self.topBgView = UIView.init()
        self.topBgView.isHidden = true
        self.topBgView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.topBgView)
        self.view.addConstraints([
            NSLayoutConstraint.init(item: self.topBgView!, attribute: NSLayoutConstraint.Attribute.top, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self.view, attribute: NSLayoutConstraint.Attribute.top, multiplier: 1, constant: 0),
            NSLayoutConstraint.init(item: self.topBgView!, attribute: NSLayoutConstraint.Attribute.left, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self.view, attribute: NSLayoutConstraint.Attribute.left, multiplier: 1, constant: 0),
            NSLayoutConstraint.init(item: self.topBgView!, attribute: NSLayoutConstraint.Attribute.right, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self.view, attribute: NSLayoutConstraint.Attribute.right, multiplier: 1, constant: 0),
            NSLayoutConstraint.init(item: self.topBgView!, attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1, constant: STConstants.st_navHeight())
            ])
        
        self.leftBtn = UIButton.init(type: UIButton.ButtonType.custom)
        self.leftBtn.isHidden = true
        self.leftBtn.translatesAutoresizingMaskIntoConstraints = false
        self.leftBtn.addTarget(self, action: #selector(st_leftBarBtnClick), for: UIControl.Event.touchUpInside)
        self.topBgView.addSubview(self.leftBtn)
        self.leftBtnAttributeRight = NSLayoutConstraint.init(item: self.leftBtn!, attribute: NSLayoutConstraint.Attribute.right, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self.topBgView, attribute: NSLayoutConstraint.Attribute.left, multiplier: 1, constant: width)
        self.view.addConstraints([
            NSLayoutConstraint.init(item: self.leftBtn!, attribute: NSLayoutConstraint.Attribute.left, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self.topBgView, attribute: NSLayoutConstraint.Attribute.left, multiplier: 1, constant: 0),
            NSLayoutConstraint.init(item: self.leftBtn!, attribute: NSLayoutConstraint.Attribute.bottom, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self.topBgView, attribute: NSLayoutConstraint.Attribute.bottom, multiplier: 1, constant: 0),
            self.leftBtnAttributeRight,
            NSLayoutConstraint.init(item: self.leftBtn!, attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1, constant: height)
            ])
        
        self.rightBtn = UIButton.init(type: UIButton.ButtonType.custom)
        self.rightBtn.isHidden = true
        self.rightBtn.translatesAutoresizingMaskIntoConstraints = false
        self.rightBtn.setTitleColor(self.st_titleColor(), for: UIControl.State.normal)
        self.rightBtn.addTarget(self, action: #selector(st_rightBarBtnClick), for: UIControl.Event.touchUpInside)
        self.topBgView.addSubview(self.rightBtn)
        self.rightBtnAttributeLeft = NSLayoutConstraint.init(item: self.rightBtn!, attribute: NSLayoutConstraint.Attribute.left, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self.topBgView, attribute: NSLayoutConstraint.Attribute.right, multiplier: 1, constant: -rightSpace - width)
        self.view.addConstraints([
            self.rightBtnAttributeLeft,
            NSLayoutConstraint.init(item: self.rightBtn!, attribute: NSLayoutConstraint.Attribute.bottom, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self.topBgView, attribute: NSLayoutConstraint.Attribute.bottom, multiplier: 1, constant: 0),
            NSLayoutConstraint.init(item: self.rightBtn!, attribute: NSLayoutConstraint.Attribute.right, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self.topBgView, attribute: NSLayoutConstraint.Attribute.right, multiplier: 1, constant: -rightSpace),
            NSLayoutConstraint.init(item: self.rightBtn!, attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1, constant: height)
            ])
        
        self.titleLabel = UILabel.init()
        self.titleLabel.textColor = self.st_titleColor()
        self.titleLabel.font = UIFont.boldSystemFont(ofSize: 20)
        self.titleLabel.textAlignment = NSTextAlignment.center
        self.titleLabel.translatesAutoresizingMaskIntoConstraints = false
        self.topBgView.addSubview(self.titleLabel)
        
        self.titleLabelAttributeLeft = NSLayoutConstraint.init(item: self.titleLabel!, attribute: NSLayoutConstraint.Attribute.left, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self.topBgView, attribute: NSLayoutConstraint.Attribute.left, multiplier: 1, constant: 5 + width)
        self.titleLabelAttributeRight = NSLayoutConstraint.init(item: self.titleLabel!, attribute: NSLayoutConstraint.Attribute.right, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self.topBgView, attribute: NSLayoutConstraint.Attribute.right, multiplier: 1, constant: -5 - rightSpace - width)

        self.view.addConstraints([
            NSLayoutConstraint.init(item: self.titleLabel!, attribute: NSLayoutConstraint.Attribute.bottom, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self.topBgView, attribute: NSLayoutConstraint.Attribute.bottom, multiplier: 1, constant: 0),
            self.titleLabelAttributeLeft!,
            self.titleLabelAttributeRight!,
            NSLayoutConstraint.init(item: self.titleLabel!, attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1, constant: titleHeight)
            ])
        self.st_showNavBtnType(type: .onlyShowTitle)
    }
    
    public func st_showNavBtnType(type: STNavBtnShowType) -> Void {
        switch type {
        case .showLeftBtn:
            self.leftBtn.isHidden = false
            self.rightBtn.isHidden = true
            self.topBgView.isHidden = false
            break
        case .showRightBtn:
            self.leftBtn.isHidden = true
            self.rightBtn.isHidden = false
            self.topBgView.isHidden = false
            break
        case .showBothBtn:
            self.leftBtn.isHidden = false
            self.rightBtn.isHidden = false
            self.topBgView.isHidden = false
            break
        case .onlyShowTitle:
            self.leftBtn.isHidden = true
            self.rightBtn.isHidden = true
            self.topBgView.isHidden = false
        default:
            self.leftBtn.isHidden = true
            self.rightBtn.isHidden = true
            self.topBgView.isHidden = true
            break
        }
    }
}

// Navigation bar click event
extension STBaseViewController {
    @objc open func st_leftBarBtnClick() -> Void {
        if self.navigationController?.viewControllers.count ?? 0 > 1 {
            self.navigationController?.popViewController(animated: true)
        } else {
            self.dismiss(animated: true) {
                
            }
        }
    }
    
    @objc open func st_rightBarBtnClick() -> Void {
        
    }
}

extension STBaseViewController {
    open func st_showError(message: String) -> Void {
        self.st_showError(message: message, title: "提示")
    }
    
    open func st_showError(message: String, title: String) -> Void {
        let alert = UIAlertController.init(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        let action: UIAlertAction = UIAlertAction.init(title: "我知道了", style: UIAlertAction.Style.cancel) { (action) in}
        alert.addAction(action)
        self.present(alert, animated: true) {}
    }
    
    /// 延时操作器
    open func st_performTaskWithTimeInterval(timeInterval: Double, complection: @escaping(Result<Bool, Error>) -> Void) {
        let delayTime = DispatchTime.now() + timeInterval
        DispatchQueue.main.asyncAfter(deadline: delayTime){
            complection(.success(true))
        }
    }
    
    open func st_imageIsEmpty(image: UIImage) -> Bool {
        var cgImageIsEmpty: Bool = false
        if let _: CGImage = image.cgImage {
            cgImageIsEmpty = false
        } else {
            cgImageIsEmpty = true
        }
        
        var ciImageIsEmpty: Bool = false
        if let _: CIImage = image.ciImage {
            ciImageIsEmpty = false
        } else {
            ciImageIsEmpty = true
        }
        if cgImageIsEmpty == true, ciImageIsEmpty == true {
            return true
        }
        return false
    }
    
    open func st_stringToDouble(string: String) -> Double {
        let formatter = NumberFormatter()
        formatter.locale = Locale.current
        formatter.decimalSeparator = "."
        if let result = formatter.number(from: string) {
            return result.doubleValue
        } else {
            formatter.decimalSeparator = ","
            if let result = formatter.number(from: string) {
                return result.doubleValue
            }
        }
        return 0
    }
}

extension STBaseViewController {
    func st_titleColor() -> UIColor {
        return UIColor.init(red: 80, green: 81, blue: 96, alpha: 1)
    }
}
