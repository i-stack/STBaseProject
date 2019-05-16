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
    open var rightTitleBtn: UIButton!
    
    open var space: CGFloat = 0
    open var width: CGFloat = 44
    open var height: CGFloat = 44
    open var leftSpace: CGFloat = 37
    open var rightSpace: CGFloat = 14
    open var titleHeight: CGFloat = 44
    
    open var noDataView: UIView?
    open var networkNotReachView: UIView?
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        print("🌈 -> \(self) 🌈 ----> 🌈 dealloc")
    }

    override open func viewDidLoad() {
        super.viewDidLoad()
        self.hidesBottomBarWhenPushed = true
        self.view.backgroundColor = self.bgColor()
        self.automaticallyAdjustsScrollViewInsets = false
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true

        self.addNotification()
        self.navigationBarView()
    }
    
    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override open func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
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

    open func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer.isKind(of: UIPanGestureRecognizer.self) == true && otherGestureRecognizer.isKind(of: UIScreenEdgePanGestureRecognizer.self) == true {
            return true
        }
        return true
    }
    
    private func navigationBarView() -> Void {
        self.topBgView = UIView.init()
        self.topBgView.isHidden = true
        self.topBgView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.topBgView)
        self.view.addConstraints([
            NSLayoutConstraint.init(item: self.topBgView!, attribute: NSLayoutConstraint.Attribute.top, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self.view, attribute: NSLayoutConstraint.Attribute.top, multiplier: 1, constant: 0),
            NSLayoutConstraint.init(item: self.topBgView!, attribute: NSLayoutConstraint.Attribute.left, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self.view, attribute: NSLayoutConstraint.Attribute.left, multiplier: 1, constant: 0),
            NSLayoutConstraint.init(item: self.topBgView!, attribute: NSLayoutConstraint.Attribute.right, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self.view, attribute: NSLayoutConstraint.Attribute.right, multiplier: 1, constant: 0),
            NSLayoutConstraint.init(item: self.topBgView!, attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1, constant: ST_NavHeight)
            ])
        
        self.leftBtn = UIButton.init(type: UIButton.ButtonType.custom)
        self.leftBtn.isHidden = true
        self.leftBtn.setImage(UIImage.init(named: "back_arrow"), for: UIControl.State.normal)
        self.leftBtn.setImage(UIImage.init(named: "back_arrow"), for: UIControl.State.highlighted)
        self.leftBtn.translatesAutoresizingMaskIntoConstraints = false
        self.leftBtn.addTarget(self, action: #selector(leftBarBtnClick), for: UIControl.Event.touchUpInside)
        self.topBgView.addSubview(self.leftBtn)
        self.view.addConstraints([
            NSLayoutConstraint.init(item: self.leftBtn!, attribute: NSLayoutConstraint.Attribute.bottom, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self.topBgView, attribute: NSLayoutConstraint.Attribute.bottom, multiplier: 1, constant: 0),
            NSLayoutConstraint.init(item: self.leftBtn!, attribute: NSLayoutConstraint.Attribute.left, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self.topBgView, attribute: NSLayoutConstraint.Attribute.left, multiplier: 1, constant: 0),
            NSLayoutConstraint.init(item: self.leftBtn!, attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1, constant: width),
            NSLayoutConstraint.init(item: self.leftBtn!, attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1, constant: height)
            ])
        
        self.rightBtn = UIButton.init(type: UIButton.ButtonType.custom)
        self.rightBtn.isHidden = true
        self.rightBtn.translatesAutoresizingMaskIntoConstraints = false
        self.rightBtn.setTitleColor(self.titleColor(), for: UIControl.State.normal)
        self.rightBtn.addTarget(self, action: #selector(rightBarBtnClick), for: UIControl.Event.touchUpInside)
        self.topBgView.addSubview(self.rightBtn)
        self.view.addConstraints([
            NSLayoutConstraint.init(item: self.rightBtn!, attribute: NSLayoutConstraint.Attribute.bottom, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self.topBgView, attribute: NSLayoutConstraint.Attribute.bottom, multiplier: 1, constant: 0),
            NSLayoutConstraint.init(item: self.rightBtn!, attribute: NSLayoutConstraint.Attribute.right, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self.topBgView, attribute: NSLayoutConstraint.Attribute.right, multiplier: 1, constant: -rightSpace),
            NSLayoutConstraint.init(item: self.rightBtn!, attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1, constant: width),
            NSLayoutConstraint.init(item: self.rightBtn!, attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1, constant: height)
            ])
        
        self.rightTitleBtn = UIButton.init(type: UIButton.ButtonType.custom)
        self.rightTitleBtn.translatesAutoresizingMaskIntoConstraints = false
        self.rightTitleBtn.contentHorizontalAlignment = UIControl.ContentHorizontalAlignment.right
        self.rightTitleBtn.setTitleColor(self.titleColor(), for: UIControl.State.normal)
        self.rightTitleBtn.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: UIFont.Weight.medium)
        self.rightTitleBtn.addTarget(self, action: #selector(rightBarBtnClick), for: UIControl.Event.touchUpInside)
        self.topBgView.addSubview(self.rightTitleBtn)
        self.view.addConstraints([
            NSLayoutConstraint.init(item: self.rightTitleBtn!, attribute: NSLayoutConstraint.Attribute.bottom, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self.topBgView, attribute: NSLayoutConstraint.Attribute.bottom, multiplier: 1, constant: 0),
            NSLayoutConstraint.init(item: self.rightTitleBtn!, attribute: NSLayoutConstraint.Attribute.right, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self.topBgView, attribute: NSLayoutConstraint.Attribute.right, multiplier: 1, constant: -rightSpace),
            NSLayoutConstraint.init(item: self.rightTitleBtn!, attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1, constant: height),
            NSLayoutConstraint.init(item: self.rightTitleBtn!, attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1, constant: width * 2)
            ])
        
        self.titleLabel = UILabel.init()
        self.titleLabel.textColor = self.titleColor()
        self.titleLabel.font = UIFont.boldSystemFont(ofSize: 20)
        self.titleLabel.textAlignment = NSTextAlignment.center
        self.titleLabel.translatesAutoresizingMaskIntoConstraints = false
        self.topBgView.addSubview(self.titleLabel)
        self.view.addConstraints([
            NSLayoutConstraint.init(item: self.titleLabel!, attribute: NSLayoutConstraint.Attribute.bottom, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self.topBgView, attribute: NSLayoutConstraint.Attribute.bottom, multiplier: 1, constant: 0),
            NSLayoutConstraint.init(item: self.titleLabel!, attribute: NSLayoutConstraint.Attribute.right, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self.rightBtn, attribute: NSLayoutConstraint.Attribute.left, multiplier: 1, constant: -5 + rightSpace),
            NSLayoutConstraint.init(item: self.titleLabel!, attribute: NSLayoutConstraint.Attribute.left, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self.leftBtn, attribute: NSLayoutConstraint.Attribute.right, multiplier: 1, constant: 5),
            NSLayoutConstraint.init(item: self.titleLabel!, attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1, constant: titleHeight)
            ])
        self.showNavBtnType(type: .onlyShowTitle)
    }
    
    public func showNavBtnType(type: STNavBtnShowType) -> Void {
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
    @objc open func leftBarBtnClick() -> Void {
        if self.navigationController?.viewControllers.count ?? 0 > 1 {
            self.navigationController?.popViewController(animated: true)
        } else {
            self.dismiss(animated: true) {
                
            }
        }
    }
    
    @objc open func rightBarBtnClick() -> Void {
        
    }
}

extension STBaseViewController {
    func titleColor() -> UIColor {
        return UIColor.init(red: 80, green: 81, blue: 96, alpha: 1)
    }
    
    func bgColor() -> UIColor {
        return UIColor.init(red: 237, green: 237, blue: 237, alpha: 1)
    }
}
