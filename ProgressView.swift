//
//  ProgressView.swift
//  ProgressHUD
//
//  Created by kang huawei on 2017/3/20.
//  Copyright © 2017年 huaweikang. All rights reserved.
//

import UIKit
import CoreGraphics


class ProgressView: UIView {
    var progress: Float = 0.0 {
        didSet {
            if(oldValue != progress) {
                setNeedsDisplay()
            }
        }
    }

}

class BarProgressView: ProgressView {
    var lineColor = UIColor.white
    var progressRemainingColor = UIColor.clear {
        didSet {
            if(progressRemainingColor != oldValue) {
                setNeedsDisplay()
            }
        }
    }
    var progressColor = UIColor.white {
        didSet {
            if(progressColor != oldValue) {
                setNeedsDisplay()
            }
        }
    }
    
    convenience init() {
        self.init(frame: CGRect(x: 0, y: 0, width: 120, height: 20))
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        isOpaque = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Layout
    override var intrinsicContentSize: CGSize {
        return CGSize(width: 120.0, height: 10.0)
    }
    
    // MARK: Drawing
    override func draw(_ rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        
        context?.setLineWidth(2.0)
        context?.setStrokeColor(lineColor.cgColor)
        context?.setFillColor(progressRemainingColor.cgColor)
        
        // Draw background
        var radius = rect.size.height / 2 - 2.0
        context?.move(to: CGPoint(x: 2, y: rect.size.height / 2))
        context?.addArc(tangent1End: CGPoint(x: 2, y: 2), tangent2End: CGPoint(x: radius + 2.0, y: 2), radius: radius)
        context?.addLine(to: CGPoint(x: rect.size.width - radius - 2.0, y: 2))
        context?.addArc(tangent1End: CGPoint(x: rect.size.width - 2.0, y: 2), tangent2End: CGPoint(x: rect.size.width - 2, y: rect.size.height / 2), radius: radius)
        context?.addArc(tangent1End: CGPoint(x: rect.size.width - 2, y: rect.size.height - 2), tangent2End: CGPoint(x: rect.size.width - radius - 2, y: rect.size.height - 2), radius: radius)
        context?.addLine(to: CGPoint(x: radius + 2, y: rect.size.height - 2))
        context?.addArc(tangent1End: CGPoint(x: 2, y: rect.size.height - 2), tangent2End: CGPoint(x: 2, y: rect.size.height / 2), radius: radius)
        context?.fillPath()
        
        // Draw border
        context?.move(to: CGPoint(x: 2, y: rect.size.height / 2))
        context?.addArc(tangent1End: CGPoint(x: 2, y: 2), tangent2End: CGPoint(x: radius + 2.0, y: 2), radius: radius)
        context?.addLine(to: CGPoint(x: rect.size.width - radius - 2.0, y: 2))
        context?.addArc(tangent1End: CGPoint(x: rect.size.width - 2.0, y: 2), tangent2End: CGPoint(x: rect.size.width - 2, y: rect.size.height / 2), radius: radius)
        context?.addArc(tangent1End: CGPoint(x: rect.size.width - 2, y: rect.size.height - 2), tangent2End: CGPoint(x: rect.size.width - radius - 2, y: rect.size.height - 2), radius: radius)
        context?.addLine(to: CGPoint(x: radius + 2, y: rect.size.height - 2))
        context?.addArc(tangent1End: CGPoint(x: 2, y: rect.size.height - 2), tangent2End: CGPoint(x: 2, y: rect.size.height / 2), radius: radius)
        context?.strokePath()
        
        context?.setFillColor(progressColor.cgColor)
        radius = radius - 2.0
        let amount = CGFloat(progress) * rect.size.width
        // Progress in the middle area
        if (amount >= radius + 4.0 && amount <= (rect.size.width - radius - 4.0)) {
            context?.move(to: CGPoint(x: 4, y: rect.size.height / 2))
            context?.addArc(tangent1End: CGPoint(x: 4, y: 4), tangent2End: CGPoint(x: radius + 4, y: 4), radius: radius)
            context?.addLine(to: CGPoint(x: amount, y: 4.0))
            context?.addLine(to: CGPoint(x: amount, y: radius + 4))
            
            context?.move(to: CGPoint(x: 4, y: rect.size.height / 2))
            context?.addArc(tangent1End: CGPoint(x: 4, y: rect.size.height - 4), tangent2End: CGPoint(x: radius + 4, y: rect.size.height - 4), radius: radius)
            context?.addLine(to: CGPoint(x: amount, y: rect.size.height - 4))
            context?.addLine(to: CGPoint(x: amount, y: radius + 4))
            
            context?.fillPath()
        }
        // Progress in the right arc
        else if (amount > radius + 4) {
            let x = amount - (rect.size.width - radius - 4.0)
            
            context?.move(to: CGPoint(x: 4, y: rect.size.height / 2))
            context?.addArc(tangent1End: CGPoint(x: 4, y: 4), tangent2End: CGPoint(x: radius + 4, y: 4), radius: radius)
            context?.addLine(to: CGPoint(x: rect.size.width - radius - 4, y: 4))
            var angle = -acos(x / radius)
            if (angle.isNaN) {
                angle = 0.0
            }
            context?.addArc(center: CGPoint(x: rect.size.width - radius - 4, y: rect.size.height/2), radius: radius, startAngle: CGFloat.pi, endAngle: angle, clockwise: false)
            context?.addLine(to: CGPoint(x: amount, y: rect.size.height / 2))
            
            context?.move(to: CGPoint(x: 4, y: rect.size.height / 2))
            context?.addArc(tangent1End: CGPoint(x: 4, y: rect.size.height - 4), tangent2End: CGPoint(x: radius + 4, y: rect.size.height - 4), radius: radius)
            context?.addLine(to: CGPoint(x: rect.size.width - radius - 4, y: rect.size.height - 4))
            angle = acos(x / radius)
            if (angle.isNaN) {
                angle = 0.0
            }
            context?.addArc(center: CGPoint(x: rect.size.width - radius - 4, y: rect.size.height/2), radius: radius, startAngle: -CGFloat.pi, endAngle: angle, clockwise: true)
            context?.addLine(to: CGPoint(x: amount, y: rect.size.height / 2))
            
            context?.fillPath()
        }
        // Progress is in the left arc
        else if (amount < radius + 4 && amount > 0) {
            context?.move(to: CGPoint(x: 4, y: rect.size.height / 2))
            context?.addArc(tangent1End: CGPoint(x: 4, y: 4), tangent2End: CGPoint(x: radius + 4, y: 4), radius: radius)
            context?.addLine(to: CGPoint(x: radius + 4, y: rect.size.height / 2))
            
            context?.move(to: CGPoint(x: 4, y: rect.size.height / 2))
            context?.addArc(tangent1End: CGPoint(x: 4, y: rect.size.height - 4), tangent2End: CGPoint(x: radius + 4, y: rect.size.height - 4), radius: radius)
            context?.addLine(to: CGPoint(x: radius + 4, y: rect.size.height / 2))
            
            context?.fillPath()
        }
        
    }
}

class CircleProcessView: ProgressView {         // base class of Round and Annular viw
    // Indicator progress color, default white
    var progressTintColor: UIColor = UIColor.red {
        didSet {
            if oldValue != progressTintColor {
                setNeedsDisplay()
            }
        }
    }
    
    // Indicator background (non - progress) color, default to translucent white (alpha 0.1)
    var backgroundTintColor = UIColor(white: 1.0, alpha: 0.1) {
        didSet {
            if oldValue != backgroundTintColor {
                setNeedsDisplay()
            }
        }
    }
    
    convenience init() {
        self.init(frame: CGRect(x: 0, y: 0, width: 37, height: 37))
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.clear
        isOpaque = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Layout
    override var intrinsicContentSize: CGSize {
        return CGSize(width: 37, height: 37)
    }
}

class RoundProgressView: CircleProcessView {
    // MARK: Drawing
    override func draw(_ rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        
        let lineWidth: CGFloat = 2
        let allRect = bounds
        let circleRect = allRect.insetBy(dx: lineWidth / 2, dy: lineWidth / 2)
        progressTintColor.setStroke()
        context?.setLineWidth(lineWidth)
        context?.strokeEllipse(in: circleRect)
 
        // 90 degrees
        let startAngle = -(CGFloat.pi / 2.0)
        // Draw Progress
        let processPath = UIBezierPath()
        processPath.lineCapStyle = .butt
        processPath.lineWidth = lineWidth * 2.0
        let radius = bounds.width / 2.0 - processPath.lineWidth / 2
        let endAngle = CGFloat(progress * 2 * Float.pi) + startAngle
        let pathCenter = CGPoint(x: bounds.midX, y: bounds.midY)
        processPath.addArc(withCenter: pathCenter, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
        // Ensure that we don't get color overlaping when progressTintColor alpha < 1
        context?.setBlendMode(.copy)
        progressTintColor.set()
        processPath.stroke()
    }
}

class AnnularProgressView: CircleProcessView {
    // MARK: Drawing
    override func draw(_ rect: CGRect) {
        // Draw background
        let lineWidth: CGFloat = 2.0
        let processBackgroundPath = UIBezierPath()
        processBackgroundPath.lineWidth = lineWidth
        processBackgroundPath.lineCapStyle = .butt
        let pathCenter = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = (bounds.size.width - lineWidth) / 2.0
        let startAngle = -(CGFloat.pi / 2)
        var endAngle = 2 * CGFloat.pi + startAngle
        processBackgroundPath.addArc(withCenter: pathCenter, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
        backgroundTintColor.set()
        processBackgroundPath.stroke()
        // Draw progress
        let processPath = UIBezierPath()
        processPath.lineCapStyle = .square
        processPath.lineWidth = lineWidth
        endAngle = CGFloat(progress * 2 * Float.pi) + startAngle
        processPath.addArc(withCenter: pathCenter, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
        progressTintColor.set()
        processPath.stroke()
    }
}
