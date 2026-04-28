//
//  STLabel.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2017/10/14.
//

import UIKit

private struct STLabelLocalizationKey {
    static var localizedTextKey: UInt8 = 0
}

public enum STLabelVerticalAlignment {
    case top
    case middle
    case bottom
}

@IBDesignable
open class STLabel: UILabel, STLocalizable {
    
    private var verticalAlignment: STLabelVerticalAlignment?
    
    public var contentEdgeInsets: UIEdgeInsets = .zero {
        didSet {
            invalidateIntrinsicContentSize()
            setNeedsLayout()
        }
    }
    
    @IBInspectable open var contentInsetTop: CGFloat {
        get { return self.contentEdgeInsets.top }
        set { self.contentEdgeInsets.top = max(0, newValue) }
    }
    
    @IBInspectable open var contentInsetLeft: CGFloat {
        get { return self.contentEdgeInsets.left }
        set { self.contentEdgeInsets.left = max(0, newValue) }
    }
    
    @IBInspectable open var contentInsetBottom: CGFloat {
        get { return self.contentEdgeInsets.bottom }
        set { self.contentEdgeInsets.bottom = max(0, newValue) }
    }
    
    @IBInspectable open var contentInsetRight: CGFloat {
        get { return self.contentEdgeInsets.right }
        set { self.contentEdgeInsets.right = max(0, newValue) }
    }
    
    @IBInspectable open var localizedText: String {
        get {
            return objc_getAssociatedObject(self, &STLabelLocalizationKey.localizedTextKey) as? String ?? ""
        }
        set {
            objc_setAssociatedObject(self, &STLabelLocalizationKey.localizedTextKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            self.text = newValue.localized
        }
    }

    /// 优先使用 localizedText 存储的原始 key 重新本地化，支持运行时语言切换。
    /// 未通过 localizedText 设置 key 时不处理（避免将动态赋值的 text 误作 key 查询）。
    public func st_updateLocalizedText() {
        let key = self.localizedText
        guard !key.isEmpty else { return }
        self.text = key.localized
    }
    
    @IBInspectable open var cornerRadius: CGFloat {
        set {
            layer.cornerRadius = newValue
            self.st_updateLiquidGlassCornerRadius()
        }
        get {
            return layer.cornerRadius
        }
    }
    
    @IBInspectable open var clipsContentToBounds: Bool {
        get {
            return self.layer.masksToBounds
        }
        set {
            self.layer.masksToBounds = newValue
        }
    }
    
    @IBInspectable open var borderWidth: CGFloat {
        set {
            layer.borderWidth = newValue > 0 ? newValue : 0
        }
        get {
            return layer.borderWidth
        }
    }
    
    @IBInspectable open var borderColor: UIColor? {
        set {
            layer.borderColor = newValue?.cgColor
        }
        get {
            guard let color = self.layer.borderColor else { return nil }
            return UIColor(cgColor: color)
        }
    }
    
    @IBInspectable open var isLiquidGlassEnabled: Bool = false {
        didSet {
            if self.isLiquidGlassEnabled {
                self.updateLiquidGlassBackground()
            } else {
                self.st_disableLiquidGlassBackground()
            }
        }
    }
    
    @IBInspectable open var liquidGlassTintColor: UIColor = UIColor.white.withAlphaComponent(0.18) {
        didSet {
            self.updateLiquidGlassBackground()
        }
    }
    
    @IBInspectable open var liquidGlassHighlightOpacity: Float = 0.45 {
        didSet {
            self.updateLiquidGlassBackground()
        }
    }
    
    @IBInspectable open var liquidGlassBorderColor: UIColor = UIColor.white.withAlphaComponent(0.45) {
        didSet {
            self.updateLiquidGlassBackground()
        }
    }
    
    public init(frame: CGRect, type: STLabelVerticalAlignment) {
        super.init(frame: frame)
        self.verticalAlignment = type
        self.adjustsFontForContentSizeCategory = true
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.verticalAlignment = STLabelVerticalAlignment.middle
        self.adjustsFontForContentSizeCategory = true
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.verticalAlignment = STLabelVerticalAlignment.middle
        self.adjustsFontForContentSizeCategory = true
        self.updateFontSize()
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        self.st_updateLiquidGlassCornerRadius()
        if let glassView = self.subviews.first(where: { $0 is STLiquidGlassView }) {
            self.sendSubviewToBack(glassView)
        }
    }
    
    private func updateFontSize() {
        self.font = UIFont.st_systemFont(ofSize: self.font.pointSize)
    }
    
    public override func textRect(forBounds bounds: CGRect, limitedToNumberOfLines numberOfLines: Int) -> CGRect {
        // 考虑内边距调整边界
        let adjustedBounds = bounds.inset(by: contentEdgeInsets)
        return super.textRect(forBounds: adjustedBounds, limitedToNumberOfLines: numberOfLines)
    }
    
    public override func draw(_ rect: CGRect) {
        // 考虑内边距调整绘制区域
        let adjustedRect = rect.inset(by: contentEdgeInsets)
        super.drawText(in: adjustedRect)
    }
        
    public override var intrinsicContentSize: CGSize {
        // 使用 super 的 intrinsicContentSize 来获取正确的文本尺寸
        let originalSize = super.intrinsicContentSize
        // 如果原始尺寸为零，尝试手动计算
        if originalSize == .zero {
            let currentFont = self.font ?? UIFont.st_systemFont(ofSize: UIFont.systemFontSize)
            let textSize = self.text?.size(withAttributes: [.font: currentFont]) ?? CGSize.zero
            
            if let attributedText = self.attributedText {
                let attributedSize = attributedText.size()
                return CGSize(width: attributedSize.width + contentEdgeInsets.left + contentEdgeInsets.right,
                             height: attributedSize.height + contentEdgeInsets.top + contentEdgeInsets.bottom)
            }
            return CGSize(width: textSize.width + contentEdgeInsets.left + contentEdgeInsets.right,
                         height: textSize.height + contentEdgeInsets.top + contentEdgeInsets.bottom)
        }
        
        // 在原始尺寸基础上加上内边距
        return CGSize(width: originalSize.width + contentEdgeInsets.left + contentEdgeInsets.right,
                     height: originalSize.height + contentEdgeInsets.top + contentEdgeInsets.bottom)
    }
    
    public override func sizeThatFits(_ size: CGSize) -> CGSize {
        // 如果可用空间小于内边距，返回最小尺寸
        let availableWidth = size.width - contentEdgeInsets.left - contentEdgeInsets.right
        let availableHeight = size.height - contentEdgeInsets.top - contentEdgeInsets.bottom
        if availableWidth <= 0 || availableHeight <= 0 {
            return CGSize(width: contentEdgeInsets.left + contentEdgeInsets.right,
                         height: contentEdgeInsets.top + contentEdgeInsets.bottom)
        }
        let adjustedSize = CGSize(width: availableWidth, height: availableHeight)
        let originalSize = super.sizeThatFits(adjustedSize)
        return CGSize(width: originalSize.width + contentEdgeInsets.left + contentEdgeInsets.right,
                     height: originalSize.height + contentEdgeInsets.top + contentEdgeInsets.bottom)
    }
    
    private func updateLiquidGlassBackground() {
        guard self.isLiquidGlassEnabled else { return }
        self.st_enableLiquidGlassBackground(
            tintColor: self.liquidGlassTintColor,
            highlightOpacity: self.liquidGlassHighlightOpacity,
            borderColor: self.liquidGlassBorderColor
        )
    }
}