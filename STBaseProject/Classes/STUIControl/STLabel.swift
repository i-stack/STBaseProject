//
//  STLabel.swift
//  STBaseProject
//
//  Created by stack on 2017/10/14.
//

import UIKit

public enum STLabelVerticalAlignment {
    case top
    case middle
    case bottom
}

public class STLabel: UILabel {
    
    private var verticalAlignment: STLabelVerticalAlignment?
    
    @IBInspectable open var autoFont: UIFont {
        set {
            let fontName = self.font.fontName
            self.font = UIFont.st_systemFont(ofSize: self.font.pointSize, fontName: fontName)
        }
        get {
            return self.font
        }
    }
    
    @IBInspectable open var localizedTitle: String {
        set {
            self.text = Bundle.st_localizedString(key: newValue)
        }
        get {
            return self.text ?? ""
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
