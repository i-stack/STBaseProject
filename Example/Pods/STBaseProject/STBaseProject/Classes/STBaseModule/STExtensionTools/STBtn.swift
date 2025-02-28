//
//  STBtn.swift
//  STBaseProject
//
//  Created by stack on 2019/10/14.
//

import UIKit

public enum STBtnEdgeInsetsStyle {
    case top    // image on top, label below
    case left   // image on the left, label on the right
    case right  // image on the right, label on the left
    case bottom // image at the bottom, label on top
    case reset  // restore
}

public struct STBtnSpacing {
    var spacing: CGFloat = 0
    var topSpacing: CGFloat?
    var leftSpacing: CGFloat?
    var rightSpacing: CGFloat?
    
    public init() {}
    
    public init(spacing: CGFloat) {
        self.spacing = spacing
    }
    
    public init(spacing: CGFloat, topSpacing: CGFloat? = nil) {
        self.spacing = spacing
        self.topSpacing = topSpacing
    }
    
    public init(spacing: CGFloat, leftSpacing: CGFloat? = nil) {
        self.spacing = spacing
        self.leftSpacing = leftSpacing
    }
    
    public init(spacing: CGFloat, rightSpacing: CGFloat? = nil) {
        self.spacing = spacing
        self.rightSpacing = rightSpacing
    }

    public init(spacing: CGFloat, leftSpacing: CGFloat? = nil, rightSpacing: CGFloat? = nil) {
        self.spacing = spacing
        self.leftSpacing = leftSpacing
        self.rightSpacing = rightSpacing
    }
}

open class STBtn: UIButton {
    
    open var identifier: Any?
    
    private var hasSetLayout: Bool = false
    private var defaultTitleFrame: CGRect = .zero
    private var defaultImageFrame: CGRect = .zero
    private var style: STBtnEdgeInsetsStyle = .reset
    private var btnSpacing: STBtnSpacing = STBtnSpacing()
    
    @IBInspectable open var localizedTitle: String {
        set {
            self.setTitle(Bundle.st_localizedString(key: newValue), for: .normal)
        }
        get {
            return self.titleLabel?.text ?? ""
        }
    }

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
        super.init(coder: aDecoder)
        self.updateFontSize()
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        guard let titleLabel = self.titleLabel, let imageView = self.imageView, self.hasSetLayout else { return }
        if self.defaultTitleFrame == .zero {
            self.defaultTitleFrame = titleLabel.frame
            self.defaultImageFrame = imageView.frame
        }
        let titleWidth = titleLabel.intrinsicContentSize.width
        let imageWidth = imageView.intrinsicContentSize.width
        let totalWidth = self.bounds.width
        let spacing = self.btnSpacing.spacing
        switch (self.style) {
        case .top:
            imageView.frame = CGRect(x: (totalWidth - imageWidth) / 2,
                                     y: self.btnSpacing.topSpacing ?? 0,
                                     width: imageWidth,
                                     height: imageView.frame.height)
            titleLabel.frame = CGRect(x: (totalWidth - titleWidth) / 2,
                                      y: imageView.frame.maxY + spacing,
                                      width: titleWidth,
                                      height: titleLabel.frame.height)
        case .left:
            var imageViewX = 0.0
            var titleLabelX = 0.0
            if let spacingLeft = self.btnSpacing.leftSpacing, let spacingRight = self.btnSpacing.rightSpacing {
                imageViewX = spacingLeft
                titleLabelX = totalWidth - titleWidth - spacingRight
            } else if let spacingLeft = self.btnSpacing.leftSpacing {
                imageViewX = spacingLeft
                titleLabelX = imageViewX + imageWidth + spacing
            } else if let spacingRight = self.btnSpacing.rightSpacing {
                titleLabelX = totalWidth - spacingRight - titleWidth
                imageViewX = titleLabelX - spacing - imageWidth
            } else {
                imageViewX = (totalWidth - titleWidth - imageWidth - spacing) / 2
                titleLabelX = imageViewX + imageWidth + spacing
            }
            titleLabel.frame = CGRect(x: titleLabelX,
                                      y: titleLabel.frame.origin.y,
                                      width: titleWidth,
                                      height: titleLabel.frame.height)
            imageView.frame = CGRect(x: imageViewX,
                                     y: imageView.frame.origin.y,
                                     width: imageWidth,
                                     height: imageView.frame.height)
        case .bottom:
            titleLabel.frame = CGRect(x: (totalWidth - titleWidth) / 2,
                                      y: self.btnSpacing.topSpacing ?? 0,
                                      width: titleWidth,
                                      height: titleLabel.frame.height)
            imageView.frame = CGRect(x: (totalWidth - imageWidth) / 2,
                                     y: titleLabel.frame.maxY + spacing,
                                     width: imageWidth,
                                     height: imageView.frame.height)
        case .right:
            var imageViewX = 0.0
            var titleLabelX = 0.0
            if let spacingLeft = self.btnSpacing.leftSpacing, let spacingRight = self.btnSpacing.rightSpacing {
                titleLabelX = spacingLeft
                imageViewX = totalWidth - imageWidth - spacingRight
            } else if let spacingLeft = self.btnSpacing.leftSpacing {
                titleLabelX = spacingLeft
                imageViewX = titleLabelX + titleWidth + spacing
            } else if let spacingRight = self.btnSpacing.rightSpacing {
                imageViewX = totalWidth - imageWidth - spacingRight
                titleLabelX = imageViewX - spacing - titleWidth
            } else {
                titleLabelX = (totalWidth - titleWidth - imageWidth - spacing) / 2
                imageViewX = titleLabelX + titleWidth + spacing
            }
            titleLabel.frame = CGRect(x: titleLabelX,
                                      y: titleLabel.frame.origin.y,
                                      width: titleWidth,
                                      height: titleLabel.frame.height)
            imageView.frame = CGRect(x: imageViewX,
                                     y: imageView.frame.origin.y,
                                     width: imageWidth,
                                     height: imageView.frame.height)
        case .reset:
            titleLabel.frame = self.defaultTitleFrame
            imageView.frame = self.defaultImageFrame
        }
    }
    
    public func st_layoutButtonWithEdgeInsets(style: STBtnEdgeInsetsStyle, spacing: STBtnSpacing) -> Void {
        self.style = style
        self.btnSpacing = spacing
        self.hasSetLayout = true
        self.setNeedsLayout()
    }
    
    public func st_roundedButton(cornerRadius: CGFloat) -> Void {
        self.st_roundedButton(cornerRadius: cornerRadius, borderWidth: 0, borderWidthColor: UIColor.clear)
    }
    
    public func st_roundedButton(cornerRadius: CGFloat, borderWidth: CGFloat, borderWidthColor: UIColor) -> Void {
        self.borderWidth = borderWidth
        self.cornerRadius = cornerRadius
        self.borderColor = borderWidthColor
    }
    
    private func updateFontSize() {
        if let fontName = self.titleLabel?.font.fontName, let fontSize = self.titleLabel?.font.pointSize {
            self.titleLabel?.font = UIFont.st_systemFont(ofSize: fontSize, fontName: fontName)
        }
    }
}
