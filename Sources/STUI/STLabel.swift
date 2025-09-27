//
//  STLabel.swift
//  STBaseProject
//
//  Created by stack on 2017/10/14.
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

public class STLabel: UILabel {
    
    private var verticalAlignment: STLabelVerticalAlignment?
    
    public var contentEdgeInsets: UIEdgeInsets = .zero {
        didSet {
            invalidateIntrinsicContentSize()
            setNeedsLayout()
        }
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
    
    @IBInspectable var cornerRadius: CGFloat {
        set {
            layer.cornerRadius = newValue
            layer.masksToBounds = newValue > 0
        }
        get {
            return layer.cornerRadius
        }
    }
    
    @IBInspectable var borderWidth: CGFloat {
        set {
            layer.borderWidth = newValue > 0 ? newValue : 0
        }
        get {
            return layer.borderWidth
        }
    }
    
    @IBInspectable var borderColor: UIColor {
        set {
            layer.borderColor = newValue.cgColor
        }
        get {
            return UIColor(cgColor: layer.borderColor!)
        }
    }
    
    public init(frame: CGRect, type: STLabelVerticalAlignment) {
        super.init(frame: frame)
        self.verticalAlignment = type
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.verticalAlignment = STLabelVerticalAlignment.middle
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.verticalAlignment = STLabelVerticalAlignment.middle
        self.updateFontSize()
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    private func updateFontSize() {
        let fontName = self.font.fontName
        self.font = UIFont.st_systemFont(ofSize: self.font.pointSize, fontName: fontName)
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
            let textSize = self.text?.size(withAttributes: [.font: self.font]) ?? CGSize.zero
            
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
}
