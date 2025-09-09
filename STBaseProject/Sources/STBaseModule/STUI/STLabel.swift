//
//  STLabel.swift
//  STBaseProject
//
//  Created by stack on 2017/10/14.
//

import UIKit

// MARK: - 标签本地化常量
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
    
    /// 本地化标题（支持 Storyboard 设置，支持动态语言切换）
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
        var textRect: CGRect = super.textRect(forBounds: bounds, limitedToNumberOfLines: numberOfLines)
        switch self.verticalAlignment {
        case .top?:
            textRect.origin.y = bounds.origin.y
        case .bottom?:
            textRect.origin.y = bounds.origin.y + bounds.size.height - textRect.size.height
        case .middle?:
            fallthrough
        default:
            textRect.origin.y = bounds.origin.y + (bounds.size.height - textRect.size.height) / 2.0
        }
        return textRect
    }
    
    public override func draw(_ rect: CGRect) {
        let rect: CGRect = self.textRect(forBounds: rect, limitedToNumberOfLines: self.numberOfLines)
        super.drawText(in: rect)
    }

}
