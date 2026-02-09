//
//  STShimmerLabel.swift
//  Bajoseek
//
//  Created by 寒江孤影 on 2026/2/3.
//

import UIKit

public class STShimmerLabel: UILabel {
    
    private let gradientLayer = CAGradientLayer()
    private let textMaskLayer = CATextLayer()
    private let shimmerKey = "st.shimmer"
    
    var shimmerDuration: CFTimeInterval = 1.4
    var highlightWidth: CGFloat = 0.25 {
        didSet { self.updateGradient() }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setup()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        self.updateFrames()
    }

    public override var text: String? {
        didSet { self.updateTextMask() }
    }

    public override var attributedText: NSAttributedString? {
        didSet { self.updateTextMask() }
    }

    public override var font: UIFont! {
        didSet { self.updateTextMask() }
    }

    public override var textAlignment: NSTextAlignment {
        didSet { self.updateTextMask() }
    }

    public override var numberOfLines: Int {
        didSet { self.updateTextMask() }
    }

    private func setup() {
        self.textColor = UIColor.label.withAlphaComponent(0.6)
        self.gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        self.gradientLayer.endPoint   = CGPoint(x: 1, y: 0.5)
        self.layer.addSublayer(self.gradientLayer)
        self.gradientLayer.isHidden = true
        self.gradientLayer.mask = self.textMaskLayer
        self.textMaskLayer.contentsScale = UIScreen.main.scale
        self.textMaskLayer.isWrapped = true
        self.textMaskLayer.truncationMode = .none
        self.updateGradient()
        self.updateTextMask()
    }

    private func updateFrames() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        self.gradientLayer.frame = bounds
        self.textMaskLayer.frame = bounds
        CATransaction.commit()
    }

    private func updateGradient() {
        let highlight = self.highlightWidth
        self.gradientLayer.colors = [
            UIColor.clear.cgColor,
            UIColor.white.withAlphaComponent(0.9).cgColor,
            UIColor.clear.cgColor
        ]

        self.gradientLayer.locations = [
            NSNumber(value: 0.5 - highlight),
            NSNumber(value: 0.5),
            NSNumber(value: 0.5 + highlight)
        ]
    }

    private func updateTextMask() {
        if let attr = self.attributedText {
            self.textMaskLayer.string = attr
        } else {
            self.textMaskLayer.string = self.text
        }
        self.textMaskLayer.font = self.font
        self.textMaskLayer.fontSize = self.font.pointSize
        self.textMaskLayer.alignmentMode = self.alignmentMode(from: self.textAlignment)
    }

    private func alignmentMode(from alignment: NSTextAlignment) -> CATextLayerAlignmentMode {
        switch alignment {
        case .left:   return .left
        case .right:  return .right
        case .center: return .center
        case .justified: return .justified
        default: return .natural
        }
    }

    func startShimmer() {
        guard self.gradientLayer.animation(forKey: self.shimmerKey) == nil else { return }
        self.gradientLayer.isHidden = false
        self.gradientLayer.add(self.makeAnimation(), forKey: self.shimmerKey)
    }

    func stopShimmer(_ animated: Bool = true) {
        guard self.gradientLayer.animation(forKey: self.shimmerKey) != nil else { return }
        let finish = {
            self.gradientLayer.removeAnimation(forKey: self.shimmerKey)
            self.gradientLayer.isHidden = true
        }
        if animated {
            UIView.animate(withDuration: 0.18, animations: {
                self.alpha = 0
            }, completion: { _ in
                self.alpha = 1
                finish()
            })
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                finish()
            }
        }
    }
    
    private func makeAnimation() -> CABasicAnimation {
        let anim = CABasicAnimation(keyPath: "locations")
        anim.fromValue = [-1.0, -0.5, 0.0]
        anim.toValue = [1.0, 1.5, 2.0]
        anim.duration = self.shimmerDuration
        anim.repeatCount = .infinity
        anim.timingFunction = CAMediaTimingFunction(name: .linear)
        anim.isRemovedOnCompletion = false
        return anim
    }
}
