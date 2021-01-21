//
//  STBtn.swift
//  STBaseProject
//
//  Created by stack on 2017/10/14.
//  Copyright © 2017年 ST. All rights reserved.
//

import UIKit
import MBProgressHUD

public enum STHUDLocation {
    case center
    case top
    case bottom
}

/// 监听`hud`状态
/// - Parameter state: `hud` 是否展示
/// - Returns: `true` hud is show elsewise `hud` is hidden
public typealias STHUDCompletionBlock = (_ state: Bool) -> Void

open class STHUD: MBProgressHUD {

    open var labelFont: UIFont?
    open var labelColor: UIColor?
    open var detailLabelFont: UIFont?
    open var detailLabelColor: UIColor?
    open var customBgColor: UIColor?
    open var activityViewColor: UIColor?
    open var errorIconImageStr: String?
    open var afterDelay: TimeInterval = 1.5
    
    public static let sharedHUD: STHUD = STHUD()
    private var stCompletionBlock: STHUDCompletionBlock?
    
    override private init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    override public init(view: UIView) {
        super.init(view: view)
        let hud = MBProgressHUD.init(view: view)
        hud.removeFromSuperViewOnHide = true
        view.addSubview(hud)
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    public func show(text: String) -> Void {
        self.show(text: text, detailText: "")
    }
    
    public func show(text: String, detailText: String) -> Void {
        self.areDefaultMotionEffectsEnabled = false
        self.label.text = text
        self.detailsLabel.text = detailText
        self.show(animated: true)
        if let block = self.stCompletionBlock {
            block(true)
        }
    }
    
    /// 配置展示
    @objc open func configHUD() -> Void {
        self.label.numberOfLines = 0
        self.contentColor = UIColor.white
        self.bezelView.style = .solidColor
        if let font = self.labelFont {
            self.label.font = font
        } else {
            self.label.font = UIFont.st_systemFont(ofSize: 14, weight: .medium)
        }
        if let color = self.labelColor {
            self.label.textColor = color
        } else {
            self.label.textColor = UIColor.black
        }
        if let detailsLabelFont = self.labelFont {
            self.detailsLabel.font = detailsLabelFont
        } else {
            self.detailsLabel.font = UIFont.st_systemFont(ofSize: 14, weight: .medium)
        }
        if let detailsLabelColor = self.detailLabelColor {
            self.detailsLabel.textColor = detailsLabelColor
        } else {
            self.detailsLabel.textColor = UIColor.white
        }
        if let customColor = self.customBgColor {
            self.bezelView.backgroundColor = customColor
        } else {
            self.bezelView.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        }
        if let color = self.activityViewColor {
            self.bezelView.color = color
        } else {
            self.bezelView.color = UIColor.black.withAlphaComponent(0.6)
        }
    }
    
    open override func hide(animated: Bool) {
        super.hide(animated: animated)
        if let block = self.stCompletionBlock {
            block(true)
        }
    }
    
    public func hudComplection(block: @escaping STHUDCompletionBlock) -> Void {
        self.stCompletionBlock = block
    }
}

public extension UIView {
    /// 显示HUD
    ///
    /// 完成后会自动关闭，默认添加到`UIApplication.shared.keyWindow`
    ///
    /// - Parameter text: 展示文字
    func showAutoHidden(text: String) -> Void {
        self.showAutoHidden(text: text, toView: UIApplication.shared.keyWindow ?? UIView())
    }
    
    /// 显示HUD
    ///
    /// 完成后会自动关闭
    ///
    /// - Parameter text: 展示文字
    /// - Parameter toView: 添加到指定`view`
    func showAutoHidden(text: String, toView: UIView) -> Void {
        self.showAutoHidden(text: text, detailText: "", toView: toView)
    }
    
    func showAutoHidden(text: String, detailText: String) -> Void {
        self.showAutoHidden(text: text, detailText: detailText, toView: UIApplication.shared.keyWindow ?? UIView())
    }
    
    func showAutoHidden(text: String, detailText: String, toView: UIView) -> Void {
        self.showAutoHidden(text: text, detailText: detailText, offset: CGPoint.zero, toView: toView)
    }
    
    func showAutoHidden(text: String, detailText: String, offset: CGPoint, toView: UIView) -> Void {
        self.show(text: text, detailText: detailText, icon: "", offset: offset, afterDelay: STHUD.sharedHUD.afterDelay, toView: toView)
    }
    
    func showAutoHidden(text: String, location: STHUDLocation) -> Void {
        self.showAutoHidden(text: text, location: location, toView: UIApplication.shared.keyWindow ?? UIView())
    }
    
    func showAutoHidden(text: String, location: STHUDLocation, toView: UIView) -> Void {
        self.showAutoHidden(text: text, detailText: "", location: location, toView: toView)
    }
    
    func showAutoHidden(text: String, detailText: String, location: STHUDLocation) -> Void {
        self.showAutoHidden(text: text, detailText: detailText, location: location, toView: UIApplication.shared.keyWindow ?? UIView())
    }
    
    func showAutoHidden(text: String, detailText: String, location: STHUDLocation, toView: UIView) -> Void {
        self.show(text: text, detailText: detailText, icon: "", afterDelay: STHUD.sharedHUD.afterDelay, location: location, toView: toView)
    }
}

public extension UIView {
    /// 显示HUD
    ///
    /// 切记需要手动关闭
    func showLoadingManualMHidden() -> Void {
        self.showLoadingManualMHidden(text: "")
    }
    
    func showLoadingManualMHidden(text: String) -> Void {
        self.showLoadingManualMHidden(text: text, toView: UIApplication.shared.keyWindow ?? UIView())
    }
    
    func showLoadingManualMHidden(text: String, toView: UIView) -> Void {
        self.showMessageManualMHidden(text: text, detailText: "", toView: toView)
    }

    private func showMessageManualMHidden(text: String, detailText: String, toView: UIView) -> Void {
        DispatchQueue.main.async {
            let hud = STHUD.sharedHUD
            if let spView = toView.superview {
                spView.addSubview(hud)
            } else {
                UIApplication.shared.keyWindow?.addSubview(hud)
            }
            hud.show(text: text, detailText: detailText)
        }
    }

    /// 关闭MBProgressHUD
    func hideHUD() -> Void {
        DispatchQueue.main.async {
            let hud = STHUD.sharedHUD
            hud.hide(animated: true)
            hud.removeFromSuperview()
        }
    }
}

public extension UIView {
    func show(text: String, icon: String, toView: UIView) -> Void {
        self.show(text: text, detailText: "", icon: icon, toView: toView)
    }
    
    func show(text: String, detailText: String, icon: String, toView: UIView) -> Void {
        self.show(text: text, detailText: detailText, icon: icon, offset: CGPoint.zero, afterDelay: STHUD.sharedHUD.afterDelay, toView: toView)
    }
    
    private func show(text: String, detailText: String, icon: String, afterDelay: TimeInterval, location: STHUDLocation, toView: UIView) -> Void {
        var point = CGPoint.zero
        if location == .top {
            point = CGPoint.init(x: 0, y: -toView.frame.size.height / 6.0)
        } else if location == .bottom {
            point = CGPoint.init(x: 0, y: toView.frame.size.height / 6.0)
        }
        self.show(text: text, detailText: detailText, icon: icon, offset: point, afterDelay: afterDelay, toView: toView)
    }
    
    private func show(text: String, detailText: String, icon: String, offset: CGPoint, afterDelay: TimeInterval, toView: UIView) -> Void {
        self.hideHUD()
        var view: UIView = UIApplication.shared.windows.last ?? UIView()
        if let spView = toView.superview {
            view = spView
        }
        let hud = STHUD.showAdded(to: view, animated: true)
        hud.configHUD()
        hud.show(text: text, detailText: detailText)
        if icon.count > 0 {
            hud.customView = UIImageView.init(image: UIImage.init(named: icon))
            hud.mode = .customView
        } else {
            hud.mode = .text
        }
        hud.offset = offset
        hud.removeFromSuperViewOnHide = true
        hud.hide(animated: true, afterDelay: afterDelay)
    }
}
