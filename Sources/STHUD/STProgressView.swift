//
//  STHUD.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2017/10/14.
//

import UIKit
import CoreGraphics

class STProgressView: UIView {
    var progress: Float = 0.0 {
        didSet {
            guard oldValue != self.progress else { return }
            self.setNeedsDisplay()
        }
    }
}

class STBarProgressView: STProgressView {
    var lineColor = UIColor.white
    var progressColor = UIColor.white {
        didSet {
            guard self.progressColor != oldValue else { return }
            self.setNeedsDisplay()
        }
    }
    var progressRemainingColor = UIColor.clear {
        didSet {
            guard self.progressRemainingColor != oldValue else { return }
            self.setNeedsDisplay()
        }
    }

    convenience init() {
        self.init(frame: CGRect(x: 0, y: 0, width: 120, height: 20))
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.isOpaque = false
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: 120.0, height: 10.0)
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }

        context.setLineWidth(2.0)
        context.setStrokeColor(self.lineColor.cgColor)
        context.setFillColor(self.progressRemainingColor.cgColor)

        var radius = rect.size.height / 2 - 2.0
        context.move(to: CGPoint(x: 2, y: rect.size.height / 2))
        context.addArc(tangent1End: CGPoint(x: 2, y: 2), tangent2End: CGPoint(x: radius + 2.0, y: 2), radius: radius)
        context.addLine(to: CGPoint(x: rect.size.width - radius - 2.0, y: 2))
        context.addArc(tangent1End: CGPoint(x: rect.size.width - 2.0, y: 2), tangent2End: CGPoint(x: rect.size.width - 2, y: rect.size.height / 2), radius: radius)
        context.addArc(tangent1End: CGPoint(x: rect.size.width - 2, y: rect.size.height - 2), tangent2End: CGPoint(x: rect.size.width - radius - 2, y: rect.size.height - 2), radius: radius)
        context.addLine(to: CGPoint(x: radius + 2, y: rect.size.height - 2))
        context.addArc(tangent1End: CGPoint(x: 2, y: rect.size.height - 2), tangent2End: CGPoint(x: 2, y: rect.size.height / 2), radius: radius)
        context.fillPath()

        context.move(to: CGPoint(x: 2, y: rect.size.height / 2))
        context.addArc(tangent1End: CGPoint(x: 2, y: 2), tangent2End: CGPoint(x: radius + 2.0, y: 2), radius: radius)
        context.addLine(to: CGPoint(x: rect.size.width - radius - 2.0, y: 2))
        context.addArc(tangent1End: CGPoint(x: rect.size.width - 2.0, y: 2), tangent2End: CGPoint(x: rect.size.width - 2, y: rect.size.height / 2), radius: radius)
        context.addArc(tangent1End: CGPoint(x: rect.size.width - 2, y: rect.size.height - 2), tangent2End: CGPoint(x: rect.size.width - radius - 2, y: rect.size.height - 2), radius: radius)
        context.addLine(to: CGPoint(x: radius + 2, y: rect.size.height - 2))
        context.addArc(tangent1End: CGPoint(x: 2, y: rect.size.height - 2), tangent2End: CGPoint(x: 2, y: rect.size.height / 2), radius: radius)
        context.strokePath()

        context.setFillColor(self.progressColor.cgColor)
        radius -= 2.0
        let amount = CGFloat(self.progress) * rect.size.width

        if amount >= radius + 4.0 && amount <= rect.size.width - radius - 4.0 {
            context.move(to: CGPoint(x: 4, y: rect.size.height / 2))
            context.addArc(tangent1End: CGPoint(x: 4, y: 4), tangent2End: CGPoint(x: radius + 4, y: 4), radius: radius)
            context.addLine(to: CGPoint(x: amount, y: 4.0))
            context.addLine(to: CGPoint(x: amount, y: radius + 4))
            context.move(to: CGPoint(x: 4, y: rect.size.height / 2))
            context.addArc(tangent1End: CGPoint(x: 4, y: rect.size.height - 4), tangent2End: CGPoint(x: radius + 4, y: rect.size.height - 4), radius: radius)
            context.addLine(to: CGPoint(x: amount, y: rect.size.height - 4))
            context.addLine(to: CGPoint(x: amount, y: radius + 4))
            context.fillPath()
        } else if amount > radius + 4 {
            let x = amount - (rect.size.width - radius - 4.0)
            context.move(to: CGPoint(x: 4, y: rect.size.height / 2))
            context.addArc(tangent1End: CGPoint(x: 4, y: 4), tangent2End: CGPoint(x: radius + 4, y: 4), radius: radius)
            context.addLine(to: CGPoint(x: rect.size.width - radius - 4, y: 4))
            var angle = -acos(x / radius)
            if angle.isNaN { angle = 0.0 }
            context.addArc(center: CGPoint(x: rect.size.width - radius - 4, y: rect.size.height / 2), radius: radius, startAngle: .pi, endAngle: angle, clockwise: false)
            context.addLine(to: CGPoint(x: amount, y: rect.size.height / 2))
            context.move(to: CGPoint(x: 4, y: rect.size.height / 2))
            context.addArc(tangent1End: CGPoint(x: 4, y: rect.size.height - 4), tangent2End: CGPoint(x: radius + 4, y: rect.size.height - 4), radius: radius)
            context.addLine(to: CGPoint(x: rect.size.width - radius - 4, y: rect.size.height - 4))
            angle = acos(x / radius)
            if angle.isNaN { angle = 0.0 }
            context.addArc(center: CGPoint(x: rect.size.width - radius - 4, y: rect.size.height / 2), radius: radius, startAngle: -.pi, endAngle: angle, clockwise: true)
            context.addLine(to: CGPoint(x: amount, y: rect.size.height / 2))
            context.fillPath()
        } else if amount < radius + 4 && amount > 0 {
            context.move(to: CGPoint(x: 4, y: rect.size.height / 2))
            context.addArc(tangent1End: CGPoint(x: 4, y: 4), tangent2End: CGPoint(x: radius + 4, y: 4), radius: radius)
            context.addLine(to: CGPoint(x: radius + 4, y: rect.size.height / 2))
            context.move(to: CGPoint(x: 4, y: rect.size.height / 2))
            context.addArc(tangent1End: CGPoint(x: 4, y: rect.size.height - 4), tangent2End: CGPoint(x: radius + 4, y: rect.size.height - 4), radius: radius)
            context.addLine(to: CGPoint(x: radius + 4, y: rect.size.height / 2))
            context.fillPath()
        }
    }
}

class STCircleProgressView: STProgressView {
    
    convenience init() {
        self.init(frame: CGRect(x: 0, y: 0, width: 37, height: 37))
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .clear
        self.isOpaque = false
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: 37, height: 37)
    }
    
    var progressTintColor: UIColor = .red {
        didSet {
            guard oldValue != self.progressTintColor else { return }
            self.setNeedsDisplay()
        }
    }

    var backgroundTintColor = UIColor(white: 1.0, alpha: 0.1) {
        didSet {
            guard oldValue != self.backgroundTintColor else { return }
            self.setNeedsDisplay()
        }
    }
}

class STRoundProgressView: STCircleProgressView {
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }

        let lineWidth: CGFloat = 2
        let circleRect = self.bounds.insetBy(dx: lineWidth / 2, dy: lineWidth / 2)
        self.progressTintColor.setStroke()
        context.setLineWidth(lineWidth)
        context.strokeEllipse(in: circleRect)

        let startAngle = -(CGFloat.pi / 2.0)
        let endAngle = CGFloat(self.progress * 2 * .pi) + startAngle
        let pathCenter = CGPoint(x: self.bounds.midX, y: self.bounds.midY)

        let processPath = UIBezierPath()
        processPath.lineCapStyle = .butt
        processPath.lineWidth = lineWidth * 2.0
        let radius = self.bounds.width / 2.0 - processPath.lineWidth / 2
        processPath.addArc(withCenter: pathCenter, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
        context.setBlendMode(.copy)
        self.progressTintColor.set()
        processPath.stroke()
    }
}

class STAnnularProgressView: STCircleProgressView {
    
    override func draw(_ rect: CGRect) {
        let lineWidth: CGFloat = 2.0
        let pathCenter = CGPoint(x: self.bounds.midX, y: self.bounds.midY)
        let radius = (self.bounds.size.width - lineWidth) / 2.0
        let startAngle = -(CGFloat.pi / 2)

        let backgroundPath = UIBezierPath()
        backgroundPath.lineWidth = lineWidth
        backgroundPath.lineCapStyle = .butt
        backgroundPath.addArc(withCenter: pathCenter, radius: radius, startAngle: startAngle, endAngle: 2 * .pi + startAngle, clockwise: true)
        self.backgroundTintColor.set()
        backgroundPath.stroke()

        let progressPath = UIBezierPath()
        progressPath.lineCapStyle = .square
        progressPath.lineWidth = lineWidth
        let endAngle = CGFloat(self.progress * 2 * .pi) + startAngle
        progressPath.addArc(withCenter: pathCenter, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
        self.progressTintColor.set()
        progressPath.stroke()
    }
}
