//
//  STBtn.swift
//  STBaseProject
//
//  Created by song on 2018/11/14.
//  Copyright © 2018年 song. All rights reserved.
//

import UIKit

public enum STBtnEdgeInsetsStyle {
    case STBtnEdgeInsetsStyle_Top    // image在上，label在下
    case STBtnEdgeInsetsStyle_Left   // image在左，label在右
    case STBtnEdgeInsetsStyle_Right  // image在右，label在左
    case STBtnEdgeInsetsStyle_Bottom // image在下，label在上
}

open class STBtn: UIButton {
    @IBInspectable open var borderWidth: CGFloat {
        set {
            layer.borderWidth = newValue
        }
        get {
            return layer.borderWidth
        }
    }
    
    @IBInspectable open var cornerRadius: CGFloat {
        set {
            layer.cornerRadius = newValue
        }
        get {
            return layer.cornerRadius
        }
    }
    
    @IBInspectable open var borderColor: UIColor? {
        set {
            guard let uiColor = newValue else { return }
            layer.borderColor = uiColor.cgColor
        }
        get {
            guard let color = layer.borderColor else { return nil }
            return UIColor(cgColor: color)
        }
    }
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func st_layoutButtonWithEdgeInsets(style: STBtnEdgeInsetsStyle, imageTitleSpace: CGFloat) -> Void {
        let imageWith: CGFloat = self.imageView?.image?.size.width ?? 0.0
        let imageHeight: CGFloat = self.imageView?.image?.size.height ?? 0.0
        
        let labelWidth: CGFloat = self.titleLabel?.intrinsicContentSize.width ?? 0.0
        let labelHeight: CGFloat = self.titleLabel?.intrinsicContentSize.height ?? 0.0
        
        var imageEdgeInsets = UIEdgeInsets.zero
        var labelEdgeInsets = UIEdgeInsets.zero
        
        switch (style) {
        case .STBtnEdgeInsetsStyle_Top:
            imageEdgeInsets = UIEdgeInsets.init(top: -labelHeight - imageTitleSpace / 2.0, left: 0, bottom: 0, right: -labelWidth)
            labelEdgeInsets = UIEdgeInsets.init(top: 0, left: -imageWith, bottom: -imageHeight - imageTitleSpace / 2.0, right: 0)
            break
        case .STBtnEdgeInsetsStyle_Left:
            imageEdgeInsets = UIEdgeInsets.init(top: 0, left: -imageTitleSpace / 2.0, bottom: 0, right: imageTitleSpace / 2.0)
            labelEdgeInsets = UIEdgeInsets.init(top: 0, left: imageTitleSpace / 2.0, bottom: 0, right: -imageTitleSpace / 2.0)
            break
        case .STBtnEdgeInsetsStyle_Bottom:
            imageEdgeInsets = UIEdgeInsets.init(top: 0, left: 0, bottom: -labelHeight - imageTitleSpace / 2.0, right: -labelWidth)
            labelEdgeInsets = UIEdgeInsets.init(top: -imageHeight - imageTitleSpace / 2.0, left: -imageWith, bottom: 0, right: 0)
            break
        case .STBtnEdgeInsetsStyle_Right:
            imageEdgeInsets = UIEdgeInsets.init(top: 0, left: labelWidth + imageTitleSpace / 2.0, bottom: 0, right: -labelWidth - imageTitleSpace / 2.0)
            labelEdgeInsets = UIEdgeInsets.init(top: 0, left: -imageWith - imageTitleSpace / 2.0, bottom: 0, right: imageWith + imageTitleSpace / 2.0)
            break
        }
        
        self.titleEdgeInsets = labelEdgeInsets
        self.imageEdgeInsets = imageEdgeInsets
    }
    
    public func st_roundedButton(cornerRadius: CGFloat) -> Void {
        self.st_roundedButton(cornerRadius: cornerRadius, borderWidth: 0, borderWidthColor: UIColor.clear)
    }
    
    public func st_roundedButton(cornerRadius: CGFloat, borderWidth: CGFloat, borderWidthColor: UIColor) -> Void {
        self.cornerRadius = cornerRadius
        self.borderWidth = borderWidth
        self.borderColor = borderWidthColor
    }
}

