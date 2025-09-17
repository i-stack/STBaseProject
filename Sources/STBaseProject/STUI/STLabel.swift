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
    
    /// 内边距支持
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
        let adjustedBounds = bounds.inset(by: contentEdgeInsets)
        return super.textRect(forBounds: adjustedBounds, limitedToNumberOfLines: numberOfLines)
    }
    
    public override func draw(_ rect: CGRect) {
        let adjustedRect = rect.inset(by: contentEdgeInsets)
        super.drawText(in: adjustedRect)
    }
        
    public override var intrinsicContentSize: CGSize {
        let originalSize = super.intrinsicContentSize
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
        return CGSize(width: originalSize.width + contentEdgeInsets.left + contentEdgeInsets.right,
                     height: originalSize.height + contentEdgeInsets.top + contentEdgeInsets.bottom)
    }
    
    public override func sizeThatFits(_ size: CGSize) -> CGSize {
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
