//
//  STView.swift
//  STBaseProject
//
//  Created by stack on 2019/10/14.
//

import UIKit

// MARK: - 圆角配置结构
public struct STCornerRadius {
    public var topLeft: CGFloat
    public var topRight: CGFloat
    public var bottomLeft: CGFloat
    public var bottomRight: CGFloat
    
    public init(topLeft: CGFloat = 0, topRight: CGFloat = 0, bottomLeft: CGFloat = 0, bottomRight: CGFloat = 0) {
        self.topLeft = topLeft
        self.topRight = topRight
        self.bottomLeft = bottomLeft
        self.bottomRight = bottomRight
    }
    
    public init(all: CGFloat) {
        self.topLeft = all
        self.topRight = all
        self.bottomLeft = all
        self.bottomRight = all
    }
}

// MARK: - 阴影配置结构
public struct STShadowConfig {
    public var color: UIColor
    public var offset: CGSize
    public var radius: CGFloat
    public var opacity: Float
    
    public init(color: UIColor = .black, offset: CGSize = CGSize(width: 0, height: 2), radius: CGFloat = 4, opacity: Float = 0.3) {
        self.color = color
        self.offset = offset
        self.radius = radius
        self.opacity = opacity
    }
}

// MARK: - 渐变配置结构
public struct STGradientConfig {
    public var colors: [UIColor]
    public var startPoint: CGPoint
    public var endPoint: CGPoint
    public var locations: [NSNumber]?
    
    public init(colors: [UIColor], startPoint: CGPoint = CGPoint(x: 0, y: 0), endPoint: CGPoint = CGPoint(x: 1, y: 1), locations: [NSNumber]? = nil) {
        self.colors = colors
        self.startPoint = startPoint
        self.endPoint = endPoint
        self.locations = locations
    }
}

// MARK: - UIView 圆角扩展
public extension UIView {
    
    /// 设置自定义圆角（修复原方法bug）
    /// - Parameters:
    ///   - topLeft: 左上角圆角半径
    ///   - topRight: 右上角圆角半径
    ///   - bottomLeft: 左下角圆角半径
    ///   - bottomRight: 右下角圆角半径
    func st_setCustomCorners(topLeft: CGFloat,
                          topRight: CGFloat,
                          bottomLeft: CGFloat,
                          bottomRight: CGFloat) {
        let cornerRadius = STCornerRadius(topLeft: topLeft, topRight: topRight, bottomLeft: bottomLeft, bottomRight: bottomRight)
        st_setCustomCorners(cornerRadius)
    }
    
    /// 使用配置结构设置圆角
    /// - Parameter cornerRadius: 圆角配置
    func st_setCustomCorners(_ cornerRadius: STCornerRadius) {
        // 确保视图已经布局
        layoutIfNeeded()
        
        let path = UIBezierPath()
        let bounds = self.bounds
        
        // 创建自定义圆角路径
        path.move(to: CGPoint(x: cornerRadius.topLeft, y: 0))
        path.addLine(to: CGPoint(x: bounds.width - cornerRadius.topRight, y: 0))
        path.addQuadCurve(to: CGPoint(x: bounds.width, y: cornerRadius.topRight), controlPoint: CGPoint(x: bounds.width, y: 0))
        path.addLine(to: CGPoint(x: bounds.width, y: bounds.height - cornerRadius.bottomRight))
        path.addQuadCurve(to: CGPoint(x: bounds.width - cornerRadius.bottomRight, y: bounds.height), controlPoint: CGPoint(x: bounds.width, y: bounds.height))
        path.addLine(to: CGPoint(x: cornerRadius.bottomLeft, y: bounds.height))
        path.addQuadCurve(to: CGPoint(x: 0, y: bounds.height - cornerRadius.bottomLeft), controlPoint: CGPoint(x: 0, y: bounds.height))
        path.addLine(to: CGPoint(x: 0, y: cornerRadius.topLeft))
        path.addQuadCurve(to: CGPoint(x: cornerRadius.topLeft, y: 0), controlPoint: CGPoint(x: 0, y: 0))
        path.close()
        
        let maskLayer = CAShapeLayer()
        maskLayer.frame = bounds
        maskLayer.path = path.cgPath
        self.layer.mask = maskLayer
    }
    
    /// 设置统一圆角
    /// - Parameter radius: 圆角半径
    func st_setCornerRadius(_ radius: CGFloat) {
        layer.cornerRadius = radius
        layer.masksToBounds = radius > 0
    }
    
    /// 设置圆角和边框
    /// - Parameters:
    ///   - radius: 圆角半径
    ///   - borderWidth: 边框宽度
    ///   - borderColor: 边框颜色
    func st_setCornerRadius(_ radius: CGFloat, borderWidth: CGFloat, borderColor: UIColor) {
        st_setCornerRadius(radius)
        layer.borderWidth = borderWidth
        layer.borderColor = borderColor.cgColor
    }
}

// MARK: - UIView 阴影扩展
public extension UIView {
    
    /// 设置阴影
    /// - Parameters:
    ///   - color: 阴影颜色
    ///   - offset: 阴影偏移
    ///   - radius: 阴影半径
    ///   - opacity: 阴影透明度
    @objc func st_setShadow(color: UIColor = .black, offset: CGSize = CGSize(width: 0, height: 2), radius: CGFloat = 4, opacity: Float = 0.3) {
        layer.shadowColor = color.cgColor
        layer.shadowOffset = offset
        layer.shadowRadius = radius
        layer.shadowOpacity = opacity
        layer.masksToBounds = false
    }
    
    /// 使用配置结构设置阴影
    /// - Parameter config: 阴影配置
    func st_setShadow(_ config: STShadowConfig) {
        st_setShadow(color: config.color, offset: config.offset, radius: config.radius, opacity: config.opacity)
    }
    
    /// 清除阴影
    func st_clearShadow() {
        layer.shadowColor = nil
        layer.shadowOffset = CGSize.zero
        layer.shadowRadius = 0
        layer.shadowOpacity = 0
    }
}

// MARK: - UIView 渐变扩展
public extension UIView {
    
    /// 设置渐变背景
    /// - Parameters:
    ///   - colors: 渐变色数组
    ///   - startPoint: 起始点
    ///   - endPoint: 结束点
    ///   - locations: 颜色位置数组
    func st_setGradientBackground(colors: [UIColor], startPoint: CGPoint = CGPoint(x: 0, y: 0), endPoint: CGPoint = CGPoint(x: 1, y: 1), locations: [NSNumber]? = nil) {
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = bounds
        gradientLayer.colors = colors.map { $0.cgColor }
        gradientLayer.startPoint = startPoint
        gradientLayer.endPoint = endPoint
        gradientLayer.locations = locations
        
        // 移除之前的渐变层
        layer.sublayers?.removeAll { $0 is CAGradientLayer }
        layer.insertSublayer(gradientLayer, at: 0)
    }
    
    /// 使用配置结构设置渐变背景
    /// - Parameter config: 渐变配置
    func st_setGradientBackground(_ config: STGradientConfig) {
        st_setGradientBackground(colors: config.colors, startPoint: config.startPoint, endPoint: config.endPoint, locations: config.locations)
    }
    
    /// 清除渐变背景
    func st_clearGradientBackground() {
        layer.sublayers?.removeAll { $0 is CAGradientLayer }
    }
}

// MARK: - UIView 动画扩展
public extension UIView {
    
    /// 淡入动画
    /// - Parameters:
    ///   - duration: 动画时长
    ///   - completion: 完成回调
    func st_fadeIn(duration: TimeInterval = 0.3, completion: (() -> Void)? = nil) {
        alpha = 0
        UIView.animate(withDuration: duration, animations: {
            self.alpha = 1
        }) { _ in
            completion?()
        }
    }
    
    /// 淡出动画
    /// - Parameters:
    ///   - duration: 动画时长
    ///   - completion: 完成回调
    func st_fadeOut(duration: TimeInterval = 0.3, completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: duration, animations: {
            self.alpha = 0
        }) { _ in
            completion?()
        }
    }
    
    /// 缩放动画
    /// - Parameters:
    ///   - scale: 缩放比例
    ///   - duration: 动画时长
    ///   - completion: 完成回调
    func st_scaleAnimation(scale: CGFloat, duration: TimeInterval = 0.3, completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: duration, animations: {
            self.transform = CGAffineTransform(scaleX: scale, y: scale)
        }) { _ in
            completion?()
        }
    }
    
    /// 弹性动画
    /// - Parameters:
    ///   - scale: 缩放比例
    ///   - duration: 动画时长
    ///   - completion: 完成回调
    func st_springAnimation(scale: CGFloat = 1.1, duration: TimeInterval = 0.6, completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.8, options: [], animations: {
            self.transform = CGAffineTransform(scaleX: scale, y: scale)
        }) { _ in
            UIView.animate(withDuration: duration * 0.5, animations: {
                self.transform = .identity
            }) { _ in
                completion?()
            }
        }
    }
    
    /// 震动动画
    /// - Parameters:
    ///   - intensity: 震动强度
    ///   - duration: 动画时长
    ///   - completion: 完成回调
    func st_shakeAnimation(intensity: CGFloat = 10, duration: TimeInterval = 0.5, completion: (() -> Void)? = nil) {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        animation.duration = duration
        animation.values = [-intensity, intensity, -intensity, intensity, -intensity/2, intensity/2, -intensity/4, intensity/4, 0]
        layer.add(animation, forKey: "shake")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            completion?()
        }
    }
}

// MARK: - UIView 约束和布局扩展
public extension UIView {
    
    /// 添加子视图并设置约束
    /// - Parameters:
    ///   - subview: 子视图
    ///   - insets: 边距
    func st_addSubview(_ subview: UIView, withInsets insets: UIEdgeInsets = .zero) {
        addSubview(subview)
        subview.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            subview.topAnchor.constraint(equalTo: topAnchor, constant: insets.top),
            subview.leadingAnchor.constraint(equalTo: leadingAnchor, constant: insets.left),
            subview.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -insets.right),
            subview.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -insets.bottom)
        ])
    }
    
    /// 居中添加子视图
    /// - Parameters:
    ///   - subview: 子视图
    ///   - size: 尺寸
    func st_addSubviewCentered(_ subview: UIView, size: CGSize? = nil) {
        addSubview(subview)
        subview.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            subview.centerXAnchor.constraint(equalTo: centerXAnchor),
            subview.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
        
        if let size = size {
            NSLayoutConstraint.activate([
                subview.widthAnchor.constraint(equalToConstant: size.width),
                subview.heightAnchor.constraint(equalToConstant: size.height)
            ])
        }
    }
    
    /// 设置固定尺寸
    /// - Parameter size: 尺寸
    func st_setSize(_ size: CGSize) {
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: size.width),
            heightAnchor.constraint(equalToConstant: size.height)
        ])
    }
    
    /// 设置宽高比
    /// - Parameter ratio: 宽高比
    func st_setAspectRatio(_ ratio: CGFloat) {
        translatesAutoresizingMaskIntoConstraints = false
        widthAnchor.constraint(equalTo: heightAnchor, multiplier: ratio).isActive = true
    }
}

// MARK: - UIView 视图控制器查找扩展
public extension UIView {
    
    /// 获取当前视图控制器
    /// - Returns: 当前视图控制器
    func st_currentViewController() -> UIViewController? {
        return st_currentViewController(st_keyWindow()?.rootViewController)
    }
    
    /// 递归查找视图控制器
    /// - Parameter vc: 视图控制器
    /// - Returns: 找到的视图控制器
    func st_currentViewController(_ vc: UIViewController?) -> UIViewController? {
        if vc == nil { return nil }
        if let presentVC = vc?.presentedViewController {
            return st_currentViewController(presentVC)
        }
        if let tabVC = vc as? UITabBarController {
            if let selectVC = tabVC.selectedViewController {
                return st_currentViewController(selectVC)
            }
            return nil
        }
        if let navVC = vc as? UINavigationController {
            return st_currentViewController(navVC.visibleViewController)
        }
        return vc
    }
    
}

// MARK: - UIView 便捷方法扩展
public extension UIView {
    
    /// 截图
    /// - Returns: 截图图片
    func st_screenshot() -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(bounds.size, false, UIScreen.main.scale)
        defer { UIGraphicsEndImageContext() }
        
        if let context = UIGraphicsGetCurrentContext() {
            layer.render(in: context)
            return UIGraphicsGetImageFromCurrentImageContext()
        }
        return nil
    }
    
    /// 移除所有子视图
    func st_removeAllSubviews() {
        subviews.forEach { $0.removeFromSuperview() }
    }
    
    /// 设置背景色（支持十六进制）
    /// - Parameter hex: 十六进制颜色值
    func st_setBackgroundColor(hex: String) {
        backgroundColor = UIColor.st_color(hexString: hex)
    }
    
    /// 设置边框
    /// - Parameters:
    ///   - width: 边框宽度
    ///   - color: 边框颜色
    func st_setBorder(width: CGFloat, color: UIColor) {
        layer.borderWidth = width
        layer.borderColor = color.cgColor
    }
    
    /// 清除所有样式
    func st_clearAllStyles() {
        layer.cornerRadius = 0
        layer.borderWidth = 0
        layer.borderColor = nil
        layer.shadowColor = nil
        layer.shadowOffset = CGSize.zero
        layer.shadowRadius = 0
        layer.shadowOpacity = 0
        layer.mask = nil
        st_clearGradientBackground()
    }
}
