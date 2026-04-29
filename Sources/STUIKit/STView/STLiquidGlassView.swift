//
//  STLiquidGlassView.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2026/4/27.
//

import UIKit
import ObjectiveC

@IBDesignable
open class STLiquidGlassView: UIView {
    
    @IBInspectable open var tintColorForGlass: UIColor = UIColor.white.withAlphaComponent(0.18) {
        didSet {
            self.updateAppearance()
        }
    }
    
    @IBInspectable open var highlightOpacity: Float = 0.45 {
        didSet {
            self.updateAppearance()
        }
    }
    
    @IBInspectable open var borderColorForGlass: UIColor = UIColor.white.withAlphaComponent(0.45) {
        didSet {
            self.updateAppearance()
        }
    }
    
    @IBInspectable open var glassCornerRadius: CGFloat {
        get {
            return self.layer.cornerRadius
        }
        set {
            self.layer.cornerRadius = newValue
            self.effectView.layer.cornerRadius = newValue
            self.updateLayerFrames()
        }
    }
    
    @IBInspectable open var stateAlpha: CGFloat = 1 {
        didSet {
            self.alpha = self.stateAlpha
        }
    }
    
    private let effectView: UIVisualEffectView
    private let highlightLayer = CAGradientLayer()
    private let borderLayer = CAShapeLayer()
    
    public override init(frame: CGRect) {
        self.effectView = STLiquidGlassView.makeEffectView()
        super.init(frame: frame)
        self.setupView()
    }
    
    public required init?(coder: NSCoder) {
        self.effectView = STLiquidGlassView.makeEffectView()
        super.init(coder: coder)
        self.setupView()
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        self.effectView.frame = self.bounds
        self.updateLayerFrames()
    }
    
    public func configure(
        tintColor: UIColor,
        highlightOpacity: Float,
        borderColor: UIColor,
        cornerRadius: CGFloat
    ) {
        self.tintColorForGlass = tintColor
        self.highlightOpacity = highlightOpacity
        self.borderColorForGlass = borderColor
        self.glassCornerRadius = cornerRadius
        self.updateAppearance()
    }
    
    public func setStateAlpha(_ alpha: CGFloat, animated: Bool) {
        self.stateAlpha = alpha
        guard animated else {
            self.alpha = alpha
            return
        }
        UIView.animate(withDuration: 0.18) {
            self.alpha = alpha
        }
    }
    
    private func setupView() {
        self.isUserInteractionEnabled = false
        self.clipsToBounds = true
        self.backgroundColor = .clear
        self.effectView.isUserInteractionEnabled = false
        self.effectView.clipsToBounds = true
        self.addSubview(self.effectView)
        self.effectView.contentView.layer.addSublayer(self.highlightLayer)
        self.effectView.contentView.layer.addSublayer(self.borderLayer)
        self.updateAppearance()
    }
    
    private func updateAppearance() {
        self.effectView.contentView.backgroundColor = self.tintColorForGlass
        self.highlightLayer.colors = [
            UIColor.white.withAlphaComponent(CGFloat(self.highlightOpacity)).cgColor,
            UIColor.white.withAlphaComponent(0.05).cgColor,
            UIColor.clear.cgColor
        ]
        self.highlightLayer.startPoint = CGPoint(x: 0, y: 0)
        self.highlightLayer.endPoint = CGPoint(x: 1, y: 1)
        self.borderLayer.fillColor = UIColor.clear.cgColor
        self.borderLayer.strokeColor = self.borderColorForGlass.cgColor
        self.borderLayer.lineWidth = 1 / UIScreen.main.scale
        self.updateLayerFrames()
    }
    
    private func updateLayerFrames() {
        let bounds = self.bounds
        self.highlightLayer.frame = bounds
        self.highlightLayer.cornerRadius = self.layer.cornerRadius
        self.borderLayer.frame = bounds
        self.borderLayer.path = UIBezierPath(
            roundedRect: bounds.insetBy(dx: 0.5, dy: 0.5),
            cornerRadius: max(0, self.layer.cornerRadius - 0.5)
        ).cgPath
    }
    
    private static func makeEffectView() -> UIVisualEffectView {
        return UIVisualEffectView(effect: STGlassEffectFactory.makeVisualEffect())
    }
}

private struct STLiquidGlassAssociationKey {
    static var viewKey: UInt8 = 0
}

public extension UIView {
    
    @discardableResult
    func st_enableLiquidGlassBackground(
        tintColor: UIColor = UIColor.white.withAlphaComponent(0.18),
        highlightOpacity: Float = 0.45,
        borderColor: UIColor = UIColor.white.withAlphaComponent(0.45)
    ) -> STLiquidGlassView {
        let glassView = self.st_liquidGlassBackgroundView ?? STLiquidGlassView()
        glassView.frame = self.bounds
        glassView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        glassView.configure(
            tintColor: tintColor,
            highlightOpacity: highlightOpacity,
            borderColor: borderColor,
            cornerRadius: self.layer.cornerRadius
        )
        if glassView.superview == nil {
            self.insertSubview(glassView, at: 0)
        } else {
            self.sendSubviewToBack(glassView)
        }
        self.st_liquidGlassBackgroundView = glassView
        return glassView
    }
    
    func st_disableLiquidGlassBackground() {
        self.st_liquidGlassBackgroundView?.removeFromSuperview()
        self.st_liquidGlassBackgroundView = nil
    }
    
    func st_updateLiquidGlassCornerRadius() {
        self.st_liquidGlassBackgroundView?.glassCornerRadius = self.layer.cornerRadius
    }
    
    private var st_liquidGlassBackgroundView: STLiquidGlassView? {
        get {
            return objc_getAssociatedObject(self, &STLiquidGlassAssociationKey.viewKey) as? STLiquidGlassView
        }
        set {
            objc_setAssociatedObject(self, &STLiquidGlassAssociationKey.viewKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}
