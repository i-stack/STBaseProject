//
//  STToast.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2024/01/01.
//

import UIKit

/// Toast 位置枚举
public enum STToastPosition {
    case top
    case center
    case bottom
}

/// Toast 样式配置
public struct STToastStyle {
    public var backgroundColor: UIColor
    public var textColor: UIColor
    public var font: UIFont
    public var cornerRadius: CGFloat
    public var horizontalPadding: CGFloat
    public var verticalPadding: CGFloat
    public var imageSize: CGSize?
    
    public init(backgroundColor: UIColor = UIColor.black.withAlphaComponent(0.8),
                textColor: UIColor = .white,
                font: UIFont = UIFont.systemFont(ofSize: 16, weight: .semibold),
                cornerRadius: CGFloat = 18,
                horizontalPadding: CGFloat = 18,
                verticalPadding: CGFloat = 20,
                imageSize: CGSize? = CGSize(width: 18, height: 18)) {
        self.backgroundColor = backgroundColor
        self.textColor = textColor
        self.font = font
        self.cornerRadius = cornerRadius
        self.horizontalPadding = horizontalPadding
        self.verticalPadding = verticalPadding
        self.imageSize = imageSize
    }
}

/// Toast 提示工具类
public class STToast {
    
    public static let shared = STToast()
    
    private var toastView: UIView?
    private var defaultStyle = STToastStyle()
    
    private init() {}
    
    /// 设置默认样式
    /// - Parameter style: Toast 样式
    public func st_setDefaultStyle(_ style: STToastStyle) {
        self.defaultStyle = style
    }
    
    /// 显示 Toast
    /// - Parameters:
    ///   - message: 消息文本
    ///   - duration: 显示时长，默认1.5秒
    ///   - position: 显示位置，默认居中
    ///   - image: 图标图片，可选
    ///   - style: 自定义样式，如果为 nil 则使用默认样式
    public func st_show(_ message: String,
                       duration: TimeInterval = 1.5,
                       position: STToastPosition = .center,
                       image: UIImage? = nil,
                       style: STToastStyle? = nil) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.st_dismiss()
            self.st_createAndShowToast(message: message, duration: duration, position: position, image: image, style: style ?? self.defaultStyle)
        }
    }
    
    /// 显示成功 Toast
    /// - Parameters:
    ///   - message: 消息文本
    ///   - duration: 显示时长
    ///   - image: 成功图标
    public func st_showSuccess(_ message: String,
                              duration: TimeInterval = 1.5,
                              image: UIImage? = nil) {
        var style = defaultStyle
        if let imageSize = style.imageSize {
            style.imageSize = imageSize
        }
        st_show(message, duration: duration, position: .center, image: image, style: style)
    }
    
    /// 显示失败 Toast
    /// - Parameters:
    ///   - message: 消息文本
    ///   - duration: 显示时长
    public func st_showFail(_ message: String,
                           duration: TimeInterval = 1.5) {
        var style = defaultStyle
        st_show(message, duration: duration, position: .center, style: style)
    }
    
    /// 显示警告 Toast
    /// - Parameters:
    ///   - message: 消息文本
    ///   - duration: 显示时长
    public func st_showWarning(_ message: String,
                              duration: TimeInterval = 1.5) {
        var style = defaultStyle
        st_show(message, duration: duration, position: .center, style: style)
    }
    
    /// 隐藏 Toast
    public func st_dismiss() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.toastView?.removeFromSuperview()
            self.toastView = nil
        }
    }
    
    // MARK: - Private Methods
    
    private func st_createAndShowToast(message: String,
                                      duration: TimeInterval,
                                      position: STToastPosition,
                                      image: UIImage?,
                                      style: STToastStyle) {
        guard let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) ?? UIApplication.shared.windows.first else {
            return
        }
        
        let containerView = UIView()
        containerView.backgroundColor = style.backgroundColor
        containerView.layer.cornerRadius = style.cornerRadius
        containerView.clipsToBounds = true
        containerView.alpha = 0
        
        // 创建内容视图
        let contentView = UIView()
        containerView.addSubview(contentView)
        
        var leadingConstraint: NSLayoutConstraint?
        var trailingConstraint: NSLayoutConstraint?
        var centerXConstraint: NSLayoutConstraint?
        
        // 添加图标（如果有）
        if let image = image {
            let imageView = UIImageView(image: image)
            imageView.contentMode = .scaleAspectFit
            imageView.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(imageView)
            
            NSLayoutConstraint.activate([
                imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                imageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
                imageView.widthAnchor.constraint(equalToConstant: style.imageSize?.width ?? 18),
                imageView.heightAnchor.constraint(equalToConstant: style.imageSize?.height ?? 18)
            ])
        }
        
        // 添加文本标签
        let label = UILabel()
        label.text = message
        label.textColor = style.textColor
        label.font = style.font
        label.numberOfLines = 0
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(label)
        
        if let image = image {
            NSLayoutConstraint.activate([
                label.leadingAnchor.constraint(equalTo: contentView.subviews.first!.trailingAnchor, constant: 8),
                label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                label.topAnchor.constraint(equalTo: contentView.topAnchor),
                label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
                label.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
            ])
        } else {
            NSLayoutConstraint.activate([
                label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                label.topAnchor.constraint(equalTo: contentView.topAnchor),
                label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
            ])
        }
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(contentView)
        
        NSLayoutConstraint.activate([
            contentView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: style.horizontalPadding),
            contentView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -style.horizontalPadding),
            contentView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: style.verticalPadding),
            contentView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -style.verticalPadding)
        ])
        
        // 添加到窗口
        containerView.translatesAutoresizingMaskIntoConstraints = false
        window.addSubview(containerView)
        
        // 设置位置约束
        centerXConstraint = containerView.centerXAnchor.constraint(equalTo: window.centerXAnchor)
        centerXConstraint?.isActive = true
        
        switch position {
        case .top:
            containerView.topAnchor.constraint(equalTo: window.safeAreaLayoutGuide.topAnchor, constant: 50).isActive = true
        case .center:
            containerView.centerYAnchor.constraint(equalTo: window.centerYAnchor).isActive = true
        case .bottom:
            containerView.bottomAnchor.constraint(equalTo: window.safeAreaLayoutGuide.bottomAnchor, constant: -50).isActive = true
        }
        
        // 设置最大宽度
        containerView.widthAnchor.constraint(lessThanOrEqualToConstant: window.bounds.width - 80).isActive = true
        
        self.toastView = containerView
        
        // 显示动画
        UIView.animate(withDuration: 0.3, animations: {
            containerView.alpha = 1
        }) { _ in
            // 自动隐藏
            UIView.animate(withDuration: 0.3, delay: duration, options: [], animations: {
                containerView.alpha = 0
            }) { _ in
                containerView.removeFromSuperview()
                self.toastView = nil
            }
        }
    }
}

// MARK: - UIView Extension
public extension UIView {
    /// 显示 Toast
    /// - Parameters:
    ///   - message: 消息文本
    ///   - duration: 显示时长
    ///   - position: 显示位置
    func st_showToast(_ message: String,
                     duration: TimeInterval = 1.5,
                     position: STToastPosition = .center) {
        STToast.shared.st_show(message, duration: duration, position: position)
    }
    
    /// 显示成功 Toast
    /// - Parameters:
    ///   - message: 消息文本
    ///   - duration: 显示时长
    func st_showSuccessToast(_ message: String,
                             duration: TimeInterval = 1.5) {
        STToast.shared.st_showSuccess(message, duration: duration)
    }
    
    /// 显示失败 Toast
    /// - Parameters:
    ///   - message: 消息文本
    ///   - duration: 显示时长
    func st_showFailToast(_ message: String,
                          duration: TimeInterval = 1.5) {
        STToast.shared.st_showFail(message, duration: duration)
    }
    
    /// 显示警告 Toast
    /// - Parameters:
    ///   - message: 消息文本
    ///   - duration: 显示时长
    func st_showWarningToast(_ message: String,
                             duration: TimeInterval = 1.5) {
        STToast.shared.st_showWarning(message, duration: duration)
    }
}

