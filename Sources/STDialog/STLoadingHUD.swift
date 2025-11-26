//
//  STLoadingHUD.swift
//  STBaseProject
//
//  Created by stack on 2024/01/01.
//

import UIKit

/// 加载指示器封装类，基于 STHUD
public class STLoadingHUD {
    
    // MARK: - 单例
    public static let shared = STLoadingHUD()
    
    // MARK: - 初始化
    private init() {
        st_configureDefaultSettings()
    }
    
    // MARK: - 配置
    
    /// 配置默认设置
    private func st_configureDefaultSettings() {
        // 使用 STHUD 的默认配置
        // 可以通过 STHUD.sharedHUD 进行自定义配置
    }
    
    /// 自定义配置
    /// - Parameters:
    ///   - backgroundColor: 背景颜色
    ///   - textColor: 文字颜色
    ///   - cornerRadius: 圆角半径
    public func st_configure(backgroundColor: UIColor? = nil,
                           textColor: UIColor? = nil,
                           cornerRadius: CGFloat? = nil) {
        if let bgColor = backgroundColor {
            STHUD.sharedHUD.setBackgroundColor(bgColor)
        }
        if let txtColor = textColor {
            STHUD.sharedHUD.setTextColor(txtColor)
        }
        if let radius = cornerRadius {
            STHUD.sharedHUD.setCornerRadius(radius)
        }
    }
    
    // MARK: - 显示方法
    
    /// 显示加载指示器
    /// - Parameters:
    ///   - status: 显示的文本信息
    public func st_show(status: String? = nil) {
        DispatchQueue.main.async {
            if let status = status, !status.isEmpty {
                STHUD.sharedHUD.showLoading(title: status)
            } else {
                STHUD.sharedHUD.showLoading()
            }
        }
    }
    
    /// 显示进度
    /// - Parameters:
    ///   - progress: 进度值 (0.0 - 1.0)
    ///   - status: 显示的文本信息
    public func st_showProgress(_ progress: Float, status: String? = nil) {
        DispatchQueue.main.async {
            // STHUD 暂不支持进度显示，使用加载中代替
            if let status = status, !status.isEmpty {
                STHUD.sharedHUD.showLoading(title: status)
            } else {
                STHUD.sharedHUD.showLoading()
            }
        }
    }
    
    /// 显示成功信息
    /// - Parameters:
    ///   - status: 显示的文本信息
    ///   - delay: 延迟自动隐藏的时间，默认 1.5 秒
    ///   - completion: 完成后的回调
    public func st_showSuccess(status: String? = nil,
                               delay: TimeInterval = 1.5,
                               completion: (() -> Void)? = nil) {
        DispatchQueue.main.async {
            STHUD.sharedHUD.showSuccess(title: status ?? "成功")
            if let completion = completion {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    STHUD.sharedHUD.hide(animated: true)
                    completion()
                }
            }
        }
    }
    
    /// 显示错误信息
    /// - Parameters:
    ///   - status: 显示的文本信息
    ///   - delay: 延迟自动隐藏的时间，默认 1.5 秒
    ///   - completion: 完成后的回调
    public func st_showError(status: String? = nil,
                            delay: TimeInterval = 1.5,
                            completion: (() -> Void)? = nil) {
        DispatchQueue.main.async {
            STHUD.sharedHUD.showError(title: status ?? "错误")
            if let completion = completion {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    STHUD.sharedHUD.hide(animated: true)
                    completion()
                }
            }
        }
    }
    
    /// 显示信息
    /// - Parameters:
    ///   - status: 显示的文本信息
    ///   - delay: 延迟自动隐藏的时间，默认 1.5 秒
    ///   - completion: 完成后的回调
    public func st_showInfo(status: String,
                           delay: TimeInterval = 1.5,
                           completion: (() -> Void)? = nil) {
        DispatchQueue.main.async {
            STHUD.sharedHUD.showInfo(title: status)
            if let completion = completion {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    STHUD.sharedHUD.hide(animated: true)
                    completion()
                }
            }
        }
    }
    
    /// 显示自定义图片
    /// - Parameters:
    ///   - image: 自定义图片
    ///   - status: 显示的文本信息
    ///   - delay: 延迟自动隐藏的时间，默认 1.5 秒
    ///   - completion: 完成后的回调
    public func st_showImage(_ image: UIImage,
                            status: String? = nil,
                            delay: TimeInterval = 1.5,
                            completion: (() -> Void)? = nil) {
        DispatchQueue.main.async {
            let imageView = UIImageView(image: image)
            STHUD.sharedHUD.setCustomView(imageView)
            if let status = status {
                STHUD.sharedHUD.showText(title: status)
            } else {
                STHUD.sharedHUD.showText(title: "")
            }
            if let completion = completion {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    STHUD.sharedHUD.hide(animated: true)
                    completion()
                }
            }
        }
    }
    
    // MARK: - 隐藏方法
    
    /// 隐藏加载指示器
    /// - Parameters:
    ///   - delay: 延迟隐藏的时间
    ///   - completion: 完成后的回调
    public func st_dismiss(delay: TimeInterval = 0, completion: (() -> Void)? = nil) {
        DispatchQueue.main.async {
            if delay > 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    STHUD.sharedHUD.hide(animated: true)
                    completion?()
                }
            } else {
                STHUD.sharedHUD.hide(animated: true)
                completion?()
            }
        }
    }
    
    // MARK: - 实用方法
    
    /// 在网络请求期间显示加载指示器
    /// - Parameters:
    ///   - status: 显示的文本信息
    ///   - task: 异步任务
    ///   - completion: 完成后的回调，返回任务结果
    public func st_showWhileExecuting<T>(status: String? = "加载中...",
                                        task: @escaping () async throws -> T) async throws -> T {
        st_show(status: status)
        
        do {
            let result = try await task()
            st_dismiss()
            return result
        } catch {
            st_dismiss()
            throw error
        }
    }
    
    /// 设置加载指示器的偏移量
    /// - Parameter offset: 偏移量
    public func st_setOffset(_ offset: UIOffset) {
        // STHUD 暂不支持偏移量设置
    }
    
    /// 重置加载指示器的偏移量
    public func st_resetOffset() {
        // STHUD 暂不支持偏移量设置
    }
    
    /// 根据当前界面样式自动适配 HUD 样式
    public func st_adaptToUserInterfaceStyle() {
        let isDarkMode = UITraitCollection.current.userInterfaceStyle == .dark
        let bgColor = isDarkMode ? UIColor.black.withAlphaComponent(0.8) : UIColor.white.withAlphaComponent(0.9)
        let txtColor = isDarkMode ? UIColor.white : UIColor.black
        
        st_configure(backgroundColor: bgColor, textColor: txtColor)
    }
}

// MARK: - 便捷静态方法
public extension STLoadingHUD {
    /// 快速显示加载指示器
    static func st_show(_ status: String? = nil) {
        STLoadingHUD.shared.st_show(status: status)
    }
    
    /// 快速显示进度
    static func st_showProgress(_ progress: Float, status: String? = nil) {
        STLoadingHUD.shared.st_showProgress(progress, status: status)
    }
    
    /// 快速显示成功信息
    static func st_showSuccess(_ status: String? = nil,
                               delay: TimeInterval = 1.5,
                               completion: (() -> Void)? = nil) {
        STLoadingHUD.shared.st_showSuccess(status: status, delay: delay, completion: completion)
    }
    
    /// 快速显示错误信息
    static func st_showError(_ status: String? = nil,
                            delay: TimeInterval = 1.5,
                            completion: (() -> Void)? = nil) {
        STLoadingHUD.shared.st_showError(status: status, delay: delay, completion: completion)
    }
    
    /// 快速显示信息
    static func st_showInfo(_ status: String,
                           delay: TimeInterval = 1.5,
                           completion: (() -> Void)? = nil) {
        STLoadingHUD.shared.st_showInfo(status: status, delay: delay, completion: completion)
    }
    
    /// 快速隐藏加载指示器
    static func st_dismiss(delay: TimeInterval = 0, completion: (() -> Void)? = nil) {
        STLoadingHUD.shared.st_dismiss(delay: delay, completion: completion)
    }
}

