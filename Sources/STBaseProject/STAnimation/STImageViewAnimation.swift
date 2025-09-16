//
//  STImageViewAnimation.swift
//  STBaseProject
//
//  Created by song on 2025/9/8.
//

import UIKit

/// 图片视图动画工具类
public class STImageViewAnimation: STBaseAnimation {
    
    /// 单图片动画配置结构体
    public struct SingleImageAnimationConfig {
        public var initialDelay: TimeInterval = 0.3
        
        public init() {}
    }
    
    private let imageView: UIImageView
    private let singleConfig: SingleImageAnimationConfig
    
    /// 初始化动画工具
    /// - Parameters:
    ///   - imageView: 要执行动画的图片视图
    ///   - baseConfig: 基础动画配置
    ///   - singleConfig: 单图片动画配置
    public init(imageView: UIImageView, baseConfig: BaseAnimationConfig? = nil, singleConfig: SingleImageAnimationConfig? = nil) {
        self.imageView = imageView
        self.singleConfig = singleConfig ?? SingleImageAnimationConfig()
        super.init(config: baseConfig)
    }
    
    /// 开始完整的图片动画序列
    public func startAnimation() {
        setupInitialState()
        scheduleFadeInAnimation()
    }
    
    /// 停止所有动画
    public func stopAnimation() {
        super.stopAnimation(for: imageView)
    }
    
    /// 重置到初始状态
    public func resetToInitialState() {
        stopAnimation()
        setupInitialState()
    }
    
    /// 仅设置初始状态，不开始动画
    public func setupInitialStateOnly() {
        setupInitialState()
    }
    
    // MARK: - Private Methods
    
    private func setupInitialState() {
        super.setupInitialState(for: imageView)
    }
    
    private func scheduleFadeInAnimation() {
        performDelayedAction(delay: singleConfig.initialDelay) { [weak self] in
            self?.startFadeInAnimation()
        }
    }
    
    private func startFadeInAnimation() {
        performFadeInAnimation(for: imageView) { [weak self] in
            self?.startPulseAnimation()
        }
    }
    
    private func startPulseAnimation() {
        performPulseAnimation(for: imageView) { [weak self] in
            self?.resetPulseAnimation()
        }
    }
    
    private func resetPulseAnimation() {
        performResetAnimation(for: imageView)
    }
}

// MARK: - Convenience Methods

extension STImageViewAnimation {
    
    /// 创建默认配置的动画实例
    /// - Parameter imageView: 要执行动画的图片视图
    /// - Returns: 配置好的动画实例
    public static func createDefaultAnimation(for imageView: UIImageView) -> STImageViewAnimation {
        return STImageViewAnimation(imageView: imageView)
    }
    
    /// 创建自定义配置的动画实例
    /// - Parameters:
    ///   - imageView: 要执行动画的图片视图
    ///   - initialDelay: 初始延迟时间
    ///   - fadeInDuration: 淡入动画持续时间
    ///   - pulseScale: 脉冲缩放比例
    /// - Returns: 配置好的动画实例
    public static func createCustomAnimation(
        for imageView: UIImageView,
        initialDelay: TimeInterval = 0.3,
        fadeInDuration: TimeInterval = 1.0,
        pulseScale: CGFloat = 1.05
    ) -> STImageViewAnimation {
        let baseConfig = BaseAnimationConfig(
            fadeInDuration: fadeInDuration,
            pulseScale: pulseScale
        )
        let singleConfig = SingleImageAnimationConfig(
            initialDelay: initialDelay
        )
        return STImageViewAnimation(imageView: imageView, baseConfig: baseConfig, singleConfig: singleConfig)
    }
}
