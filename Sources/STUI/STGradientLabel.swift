//
//  STGradientLabel.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2025/09/15.
//

import UIKit

public struct STGradientTextConfig {
    public var colors: [UIColor]
    public var startPoint: CGPoint
    public var endPoint: CGPoint
    public var locations: [NSNumber]?
    public var angle: CGFloat?
    
    public init(colors: [UIColor], startPoint: CGPoint = CGPoint(x: 0, y: 0), endPoint: CGPoint = CGPoint(x: 1, y: 1), locations: [NSNumber]? = nil, angle: CGFloat? = nil) {
        self.colors = colors
        self.startPoint = startPoint
        self.endPoint = endPoint
        self.locations = locations
        self.angle = angle
    }
    
    public init(colors: [UIColor], angle: CGFloat, locations: [NSNumber]? = nil) {
        self.colors = colors
        self.angle = angle
        self.locations = locations
        let (startPoint, endPoint) = STGradientTextConfig.calculatePointsForAngle(angle)
        self.startPoint = startPoint
        self.endPoint = endPoint
    }
    
    public static func calculatePointsForAngle(_ angle: CGFloat) -> (CGPoint, CGPoint) {
        let radians = angle * .pi / 180.0
        let x = cos(radians)
        let y = sin(radians)
        let startX = (1 - x) / 2
        let startY = (1 - y) / 2
        let endX = (1 + x) / 2
        let endY = (1 + y) / 2
        return (CGPoint(x: startX, y: startY), CGPoint(x: endX, y: endY))
    }
}

public struct STGradientAnimationConfig {
    public var alphaStep: CGFloat
    public var pulseFromValue: CGFloat
    public var pulseToValue: CGFloat
    public var scaleFromValue: CGFloat
    public var scaleToValue: CGFloat
    public var animationDuration: TimeInterval
    public var animationInterval: TimeInterval

    public init(animationInterval: TimeInterval, alphaStep: CGFloat, pulseFromValue: CGFloat, pulseToValue: CGFloat, scaleFromValue: CGFloat, scaleToValue: CGFloat, animationDuration: TimeInterval) {
        self.animationInterval = animationInterval
        self.alphaStep = alphaStep
        self.pulseFromValue = pulseFromValue
        self.pulseToValue = pulseToValue
        self.scaleFromValue = scaleFromValue
        self.scaleToValue = scaleToValue
        self.animationDuration = animationDuration
    }
}

public class STGradientLabel: UILabel {
    
    private var animationTimerName: String = ""
    private var currentAlpha: CGFloat = 0.0
    private var gradientLayer: CAGradientLayer?
    public var animationConfig: STGradientAnimationConfig

    public var gradientConfig: STGradientTextConfig {
        didSet {
            updateGradientConfig()
        }
    }

    public var isGradientEnabled: Bool = true {
        didSet {
            if isGradientEnabled {
                setupTextGradient()
            } else {
                removeGradient()
            }
        }
    }
    
    public init(frame: CGRect, gradientConfig: STGradientTextConfig, animationConfig: STGradientAnimationConfig) {
        self.gradientConfig = gradientConfig
        self.animationConfig = animationConfig
        super.init(frame: frame)
        setupLabel()
    }
    
    public required init?(coder: NSCoder) {
        self.gradientConfig = STGradientTextConfig(
            colors: [.black, .gray],
            startPoint: CGPoint(x: 0, y: 0),
            endPoint: CGPoint(x: 1, y: 1)
        )
        self.animationConfig = STGradientAnimationConfig(
            animationInterval: 0.05,
            alphaStep: 0.02,
            pulseFromValue: 0.3,
            pulseToValue: 1.0,
            scaleFromValue: 0.8,
            scaleToValue: 1.2,
            animationDuration: 1.0
        )
        super.init(coder: coder)
        setupLabel()
    }
    
    public override func awakeFromNib() {
        super.awakeFromNib()
        setupLabel()
    }
    
    private func setupLabel() {
        if isGradientEnabled {
            setupTextGradient()
        }
    }
    
    public override var text: String? {
        didSet {
            updateTextMask()
        }
    }
    
    private func updateTextMask() {
        if let textLayer = gradientLayer?.mask as? CATextLayer {
            textLayer.string = text
        }
    }
    
    private func setupTextGradient() {
        removeGradient()
        guard gradientConfig.colors.count >= 2 else {
            print("⚠️ 渐变配置需要至少两个颜色")
            return
        }
        let gradient = CAGradientLayer()
        gradient.colors = gradientConfig.colors.map { $0.cgColor }
        gradient.startPoint = gradientConfig.startPoint
        gradient.endPoint = gradientConfig.endPoint
        gradient.locations = gradientConfig.locations
        gradient.frame = bounds
        layer.addSublayer(gradient)
        gradientLayer = gradient
        let textLayer = CATextLayer()
        textLayer.string = text
        textLayer.font = font
        textLayer.fontSize = font.pointSize
        textLayer.alignmentMode = .center
        textLayer.frame = bounds
        textLayer.contentsScale = UIScreen.main.scale
        textLayer.foregroundColor = UIColor.black.cgColor
        gradient.mask = textLayer
        textColor = .clear
    }
    
    private func updateGradientConfig() {
        guard let gradient = gradientLayer else { return }
        guard gradientConfig.colors.count >= 2 else {
            print("⚠️ 渐变配置需要至少两个颜色")
            return
        }
        gradient.colors = gradientConfig.colors.map { $0.cgColor }
        gradient.startPoint = gradientConfig.startPoint
        gradient.endPoint = gradientConfig.endPoint
        gradient.locations = gradientConfig.locations
    }
    
    private func removeGradient() {
        gradientLayer?.removeFromSuperlayer()
        gradientLayer = nil
        textColor = .white
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer?.frame = bounds
        if let textLayer = gradientLayer?.mask as? CATextLayer {
            textLayer.frame = bounds
        }
    }
    
    // MARK: - 动画控制
    public func startFadeInAnimation() {
        stopAnimation()
        currentAlpha = 0.0
        alpha = currentAlpha
        animationTimerName = STTimer.st_scheduledTimer(
            withTimeInterval: animationConfig.animationInterval,
            repeats: true,
            async: false
        ) { [weak self] _ in
            self?.updateAlpha()
        }
    }
    
    public func startFadeOutAnimation() {
        stopAnimation()
        currentAlpha = 1.0
        alpha = currentAlpha
        animationTimerName = STTimer.st_scheduledTimer(
            withTimeInterval: animationConfig.animationInterval,
            repeats: true,
            async: false
        ) { [weak self] _ in
            self?.updateAlphaFadeOut()
        }
    }
    
    public func startContinuousAnimation() {
        stopAnimation()
        currentAlpha = 0.0
        alpha = currentAlpha
        animationTimerName = STTimer.st_scheduledTimer(
            withTimeInterval: animationConfig.animationInterval,
            repeats: true,
            async: false
        ) { [weak self] _ in
            self?.updateContinuousAlpha()
        }
    }
    
    private func updateAlpha() {
        currentAlpha += animationConfig.alphaStep
        if currentAlpha >= 1.0 {
            currentAlpha = 1.0
            stopAnimation()
        }
        alpha = currentAlpha
    }
    
    private func updateAlphaFadeOut() {
        currentAlpha -= animationConfig.alphaStep
        if currentAlpha <= 0.0 {
            currentAlpha = 0.0
            stopAnimation()
        }
        alpha = currentAlpha
    }
    
    private func updateContinuousAlpha() {
        let time = Date().timeIntervalSince1970
        let sineValue = sin(time * 2)
        currentAlpha = (sineValue + 1) / 2
        alpha = currentAlpha
    }
    
    public func stopAnimation() {
        if !animationTimerName.isEmpty {
            STTimer.st_cancelTask(name: animationTimerName)
            animationTimerName = ""
        }
    }
    
    // MARK: - 高级动画效果
    public func startPulseAnimation() {
        stopAnimation()
        let pulseAnimation = CABasicAnimation(keyPath: "opacity")
        pulseAnimation.fromValue = animationConfig.pulseFromValue
        pulseAnimation.toValue = animationConfig.pulseToValue
        pulseAnimation.duration = animationConfig.animationDuration
        pulseAnimation.repeatCount = .infinity
        pulseAnimation.autoreverses = true
        layer.add(pulseAnimation, forKey: "pulse")
    }
    
    public func startScaleAnimation() {
        stopAnimation()
        let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
        scaleAnimation.fromValue = animationConfig.scaleFromValue
        scaleAnimation.toValue = animationConfig.scaleToValue
        scaleAnimation.duration = animationConfig.animationDuration * 1.5
        scaleAnimation.repeatCount = .infinity
        scaleAnimation.autoreverses = true
        layer.add(scaleAnimation, forKey: "scale")
    }
    
    public func startGradientAnimation() {
        stopAnimation()
        guard let gradient = gradientLayer else { return }
        guard gradientConfig.colors.count >= 2 else { return }
        let colorAnimation = CABasicAnimation(keyPath: "colors")
        colorAnimation.fromValue = gradientConfig.colors.map { $0.cgColor }
        colorAnimation.toValue = gradientConfig.colors.reversed().map { $0.cgColor }
        colorAnimation.duration = animationConfig.animationDuration * 2.0
        colorAnimation.repeatCount = .infinity
        colorAnimation.autoreverses = true
        gradient.add(colorAnimation, forKey: "gradient")
    }
    
    public func startCombinedAnimation() {
        stopAnimation()
        startContinuousAnimation()
        startPulseAnimation()
        startGradientAnimation()
    }
    
    public func setGradientColors(_ colors: [UIColor]) {
        gradientConfig = STGradientTextConfig(
            colors: colors,
            startPoint: gradientConfig.startPoint,
            endPoint: gradientConfig.endPoint,
            locations: gradientConfig.locations,
            angle: gradientConfig.angle
        )
    }
    
    public func setGradientColors(startColor: UIColor, endColor: UIColor) {
        gradientConfig = STGradientTextConfig(
            colors: [startColor, endColor],
            startPoint: gradientConfig.startPoint,
            endPoint: gradientConfig.endPoint,
            locations: gradientConfig.locations,
            angle: gradientConfig.angle
        )
    }
    
    public func setGradientColors(startColor: UIColor, middleColor: UIColor, endColor: UIColor) {
        gradientConfig = STGradientTextConfig(
            colors: [startColor, middleColor, endColor],
            startPoint: gradientConfig.startPoint,
            endPoint: gradientConfig.endPoint,
            locations: gradientConfig.locations,
            angle: gradientConfig.angle
        )
    }
    
    public func setGradientDirection(startPoint: CGPoint, endPoint: CGPoint) {
        gradientConfig = STGradientTextConfig(
            colors: gradientConfig.colors,
            startPoint: startPoint,
            endPoint: endPoint,
            locations: gradientConfig.locations,
            angle: gradientConfig.angle
        )
    }
    
    public func setGradientLocations(_ locations: [NSNumber]) {
        gradientConfig = STGradientTextConfig(
            colors: gradientConfig.colors,
            startPoint: gradientConfig.startPoint,
            endPoint: gradientConfig.endPoint,
            locations: locations,
            angle: gradientConfig.angle
        )
    }
    
    public func setGradientAngle(_ angle: CGFloat) {
        gradientConfig = STGradientTextConfig(
            colors: gradientConfig.colors,
            angle: angle,
            locations: gradientConfig.locations
        )
    }
    
    public func setAnimationSpeed(interval: TimeInterval, alphaStep: CGFloat) {
        animationConfig.animationInterval = interval
        animationConfig.alphaStep = alphaStep
    }
    
    public func setPulseAnimation(fromValue: CGFloat, toValue: CGFloat, duration: TimeInterval) {
        animationConfig.pulseFromValue = fromValue
        animationConfig.pulseToValue = toValue
        animationConfig.animationDuration = duration
    }
    
    public func setScaleAnimation(fromValue: CGFloat, toValue: CGFloat, duration: TimeInterval) {
        animationConfig.scaleFromValue = fromValue
        animationConfig.scaleToValue = toValue
        animationConfig.animationDuration = duration
    }
    
    deinit {
        stopAnimation()
    }
}
