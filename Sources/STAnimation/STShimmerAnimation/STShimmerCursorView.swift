//
//  STShimmerCursorView.swift
//  Bajoseek
//
//  Created by 寒江孤影 on 2026/2/3.
//

import UIKit

public final class STShimmerCursorView: UIView {

    private var blinkAnimation: CABasicAnimation?

    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .label
        self.layer.cornerRadius = 1
        self.clipsToBounds = true
        self.isHidden = true
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.backgroundColor = .label
        self.layer.cornerRadius = 1
        self.clipsToBounds = true
        self.isHidden = true
    }

    public func updateFrame(_ rect: CGRect) {
        let newFrame = CGRect(
            x: rect.maxX + 1,
            y: rect.minY + 2,
            width: 2,
            height: max(4, rect.height - 4)
        )
        if self.frame != .zero && !self.isHidden {
            UIView.animate(withDuration: 0.05, delay: 0, options: [.curveLinear, .beginFromCurrentState]) {
                self.frame = newFrame
            }
        } else {
            self.frame = newFrame
        }
    }

    public func startBlink() {
        self.isHidden = false
        self.alpha = 1
        guard self.blinkAnimation == nil else { return }
        let anim = CABasicAnimation(keyPath: "opacity")
        anim.fromValue = 1.0
        anim.toValue = 0.0
        anim.duration = 0.5
        anim.autoreverses = true
        anim.repeatCount = .infinity
        anim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        self.layer.add(anim, forKey: "blink")
        self.blinkAnimation = anim
    }

    public func stopBlink() {
        self.layer.removeAnimation(forKey: "blink")
        self.blinkAnimation = nil
        self.alpha = 1
    }

    public func fadeOut(completion: (() -> Void)? = nil) {
        self.stopBlink()
        UIView.animate(withDuration: 0.3, animations: {
            self.alpha = 0
        }, completion: { _ in
            self.isHidden = true
            self.alpha = 1
            completion?()
        })
    }
}
