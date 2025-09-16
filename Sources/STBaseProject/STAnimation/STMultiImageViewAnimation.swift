//
//  STMultiImageViewAnimation.swift
//  STBaseProject
//
//  Created by song on 2025/9/8.
//

import UIKit

/// 多图片视图动画工具类
public class STMultiImageViewAnimation: STBaseAnimation {
    
    /// 多图片动画配置结构体
    public struct MultiImageAnimationConfig {
        public var popupDuration: TimeInterval = 1.5  // 总弹出动画时间
        public var individualDuration: TimeInterval = 0.3  // 单个图片动画时间
        public var pulseDelay: TimeInterval = 0.5  // 脉冲动画延迟
        public var initialScale: CGFloat = 0.1  // 初始缩放比例
        
        public init() {}
    }
    
    private let imageViews: [UIImageView]
    private let multiConfig: MultiImageAnimationConfig
    private var completedAnimations = 0
    private var animationCompletion: (() -> Void)?
    
    /// 初始化多图片动画工具
    /// - Parameters:
    ///   - imageViews: 要执行动画的图片视图数组
    ///   - baseConfig: 基础动画配置
    ///   - multiConfig: 多图片动画配置
    public init(imageViews: [UIImageView], baseConfig: BaseAnimationConfig? = nil, multiConfig: MultiImageAnimationConfig? = nil) {
        self.imageViews = imageViews
        self.multiConfig = multiConfig ?? MultiImageAnimationConfig()
        super.init(config: baseConfig)
    }
    
    /// 开始完整的多图片动画序列
    /// - Parameter completion: 所有动画完成后的回调
    public func startAnimation(completion: (() -> Void)? = nil) {
        self.animationCompletion = completion
        setupInitialState()
        startPopupAnimation()
    }
    
    /// 停止所有动画
    public func stopAnimation() {
        super.stopAnimation(for: imageViews)
        completedAnimations = 0
    }
    
    /// 重置到初始状态
    public func resetToInitialState() {
        stopAnimation()
        setupInitialState()
    }
    
    // MARK: - Private Methods
    
    private func setupInitialState() {
        for imageView in imageViews {
            super.setupInitialState(for: imageView, alpha: 0.0, scale: multiConfig.initialScale)
        }
        completedAnimations = 0
    }
    
    private func startPopupAnimation() {
        let interval = multiConfig.popupDuration / Double(imageViews.count)
        for (index, imageView) in imageViews.enumerated() {
            let delay = Double(index) * interval
            performDelayedAction(delay: delay) { [weak self] in
                self?.animateImageView(imageView)
            }
        }
    }
    
    private func animateImageView(_ imageView: UIImageView) {
        let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
        scaleAnimation.fromValue = multiConfig.initialScale
        scaleAnimation.toValue = 1.0
        scaleAnimation.duration = multiConfig.individualDuration
        scaleAnimation.timingFunction = CAMediaTimingFunction(name: .easeOut)
        
        let alphaAnimation = CABasicAnimation(keyPath: "opacity")
        alphaAnimation.fromValue = 0.0
        alphaAnimation.toValue = 1.0
        alphaAnimation.duration = multiConfig.individualDuration
        alphaAnimation.timingFunction = CAMediaTimingFunction(name: .easeOut)
        
        let groupAnimation = CAAnimationGroup()
        groupAnimation.animations = [scaleAnimation, alphaAnimation]
        groupAnimation.duration = multiConfig.individualDuration
        groupAnimation.fillMode = .forwards
        groupAnimation.isRemovedOnCompletion = false
        imageView.layer.add(groupAnimation, forKey: "popupAnimation")
    
        performDelayedAction(delay: multiConfig.individualDuration) {
            imageView.alpha = 1.0
            imageView.transform = CGAffineTransform.identity
            imageView.layer.removeAllAnimations()
            
            // 增加完成计数
            self.completedAnimations += 1
            
            // 检查是否所有动画都完成了
            if self.completedAnimations == self.imageViews.count {
                self.startFadeInAnimation()
            }
        }
    }
    
    private func startFadeInAnimation() {
        performDelayedAction(delay: multiConfig.pulseDelay) { [weak self] in
            self?.performFadeInAnimation()
        }
    }
    
    private func performFadeInAnimation() {
        // 为所有图片视图执行淡入动画
        UIView.animate(
            withDuration: config.fadeInDuration,
            delay: 0.0,
            options: config.animationOptions,
            animations: { [weak self] in
                guard let self = self else { return }
                for imageView in self.imageViews {
                    imageView.alpha = 1.0
                }
            },
            completion: { [weak self] _ in
                self?.startPulseAnimation()
            }
        )
    }
    
    private func startPulseAnimation() {
        // 为所有图片视图执行脉冲动画
        UIView.animate(
            withDuration: config.pulseDuration,
            delay: 0.0,
            options: config.pulseOptions,
            animations: { [weak self] in
                guard let self = self else { return }
                for imageView in self.imageViews {
                    imageView.transform = CGAffineTransform(scaleX: self.config.pulseScale, y: self.config.pulseScale)
                }
            },
            completion: { [weak self] _ in
                self?.resetPulseAnimation()
            }
        )
    }
    
    private func resetPulseAnimation() {
        UIView.animate(withDuration: config.resetDuration) { [weak self] in
            guard let self = self else { return }
            for imageView in self.imageViews {
                imageView.transform = CGAffineTransform.identity
            }
        } completion: { [weak self] _ in
            self?.animationCompletion?()
        }
    }
}

// MARK: - Convenience Methods

extension STMultiImageViewAnimation {
    
    /// 创建默认配置的多图片动画实例
    /// - Parameter imageViews: 要执行动画的图片视图数组
    /// - Returns: 配置好的动画实例
    public static func createDefaultAnimation(for imageViews: [UIImageView]) -> STMultiImageViewAnimation {
        return STMultiImageViewAnimation(imageViews: imageViews)
    }
    
    /// 创建自定义配置的多图片动画实例
    /// - Parameters:
    ///   - imageViews: 要执行动画的图片视图数组
    ///   - popupDuration: 总弹出动画时间
    ///   - individualDuration: 单个图片动画时间
    ///   - pulseScale: 脉冲缩放比例
    /// - Returns: 配置好的动画实例
    public static func createCustomAnimation(
        for imageViews: [UIImageView],
        popupDuration: TimeInterval = 1.5,
        individualDuration: TimeInterval = 0.3,
        pulseScale: CGFloat = 1.05
    ) -> STMultiImageViewAnimation {
        let baseConfig = BaseAnimationConfig(pulseScale: pulseScale)
        let multiConfig = MultiImageAnimationConfig(
            popupDuration: popupDuration,
            individualDuration: individualDuration
        )
        return STMultiImageViewAnimation(imageViews: imageViews, baseConfig: baseConfig, multiConfig: multiConfig)
    }
}
