//
//  STBaseAnimation.swift
//  STBaseProject
//
//  Created by song on 2025/9/8.
//

#if canImport(UIKit)
import UIKit
#endif

/// 动画基类，提供公共的动画功能
public class STBaseAnimation {
    
    /// 基础动画配置结构体
    public struct BaseAnimationConfig {
        public var fadeInDuration: TimeInterval = 1.0
        public var pulseDuration: TimeInterval = 0.8
        public var pulseScale: CGFloat = 1.05
        public var resetDuration: TimeInterval = 0.3
        public var animationOptions: UIView.AnimationOptions = [.curveEaseInOut]
        public var pulseOptions: UIView.AnimationOptions = [.repeat, .autoreverse, .curveEaseInOut]
        
        public init() {}
        
        public init(
            fadeInDuration: TimeInterval = 1.0,
            pulseDuration: TimeInterval = 0.8,
            pulseScale: CGFloat = 1.05,
            resetDuration: TimeInterval = 0.3,
            animationOptions: UIView.AnimationOptions = [.curveEaseInOut],
            pulseOptions: UIView.AnimationOptions = [.repeat, .autoreverse, .curveEaseInOut]
        ) {
            self.fadeInDuration = fadeInDuration
            self.pulseDuration = pulseDuration
            self.pulseScale = pulseScale
            self.resetDuration = resetDuration
            self.animationOptions = animationOptions
            self.pulseOptions = pulseOptions
        }
    }
    
    let config: BaseAnimationConfig
    
    public init(config: BaseAnimationConfig? = nil) {
        self.config = config ?? BaseAnimationConfig()
    }
    
    // MARK: - 公共动画方法
    
    /// 执行淡入动画
    /// - Parameters:
    ///   - imageView: 要执行动画的图片视图
    ///   - completion: 动画完成回调
    public func performFadeInAnimation(for imageView: UIImageView, completion: (() -> Void)? = nil) {
        UIView.animate(
            withDuration: config.fadeInDuration,
            delay: 0.0,
            options: config.animationOptions,
            animations: {
                imageView.alpha = 1.0
            },
            completion: { _ in
                completion?()
            }
        )
    }
    
    /// 执行脉冲动画
    /// - Parameters:
    ///   - imageView: 要执行动画的图片视图
    ///   - completion: 动画完成回调
    public func performPulseAnimation(for imageView: UIImageView, completion: (() -> Void)? = nil) {
        UIView.animate(
            withDuration: config.pulseDuration,
            delay: 0.0,
            options: config.pulseOptions,
            animations: {
                imageView.transform = CGAffineTransform(scaleX: self.config.pulseScale, y: self.config.pulseScale)
            },
            completion: { _ in
                completion?()
            }
        )
    }
    
    /// 执行重置动画
    /// - Parameters:
    ///   - imageView: 要执行动画的图片视图
    ///   - completion: 动画完成回调
    public func performResetAnimation(for imageView: UIImageView, completion: (() -> Void)? = nil) {
        UIView.animate(
            withDuration: config.resetDuration,
            animations: {
                imageView.transform = CGAffineTransform.identity
            },
            completion: { _ in
                completion?()
            }
        )
    }
    
    /// 设置初始状态
    /// - Parameters:
    ///   - imageView: 要设置的图片视图
    ///   - alpha: 透明度，默认为0.0
    ///   - scale: 缩放比例，默认为1.0
    public func setupInitialState(for imageView: UIImageView, alpha: CGFloat = 0.0, scale: CGFloat = 1.0) {
        imageView.alpha = alpha
        imageView.transform = CGAffineTransform(scaleX: scale, y: scale)
    }
    
    /// 停止单个图片视图的动画
    /// - Parameter imageView: 要停止动画的图片视图
    public func stopAnimation(for imageView: UIImageView) {
        imageView.layer.removeAllAnimations()
        imageView.transform = CGAffineTransform.identity
        imageView.alpha = 1.0
    }
    
    /// 停止多个图片视图的动画
    /// - Parameter imageViews: 要停止动画的图片视图数组
    public func stopAnimation(for imageViews: [UIImageView]) {
        for imageView in imageViews {
            stopAnimation(for: imageView)
        }
    }
    
    /// 执行延迟操作
    /// - Parameters:
    ///   - delay: 延迟时间
    ///   - action: 要执行的操作
    public func performDelayedAction(delay: TimeInterval, action: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            action()
        }
    }
}

// MARK: - 便捷方法

extension STBaseAnimation {
    
    /// 创建默认配置的基类实例
    /// - Returns: 配置好的基类实例
    public static func createDefault() -> STBaseAnimation {
        return STBaseAnimation()
    }
    
    /// 创建自定义配置的基类实例
    /// - Parameters:
    ///   - fadeInDuration: 淡入动画时间
    ///   - pulseDuration: 脉冲动画时间
    ///   - pulseScale: 脉冲缩放比例
    /// - Returns: 配置好的基类实例
    public static func createCustom(
        fadeInDuration: TimeInterval = 1.0,
        pulseDuration: TimeInterval = 0.8,
        pulseScale: CGFloat = 1.05
    ) -> STBaseAnimation {
        let config = BaseAnimationConfig(
            fadeInDuration: fadeInDuration,
            pulseDuration: pulseDuration,
            pulseScale: pulseScale
        )
        return STBaseAnimation(config: config)
    }
}
