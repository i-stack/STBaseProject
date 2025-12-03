//
//  STAppearanceManager.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2018/3/14.
//

import UIKit

/// SDK 统一的外观模式
public enum STAppearanceMode: Equatable {
    case system        // 跟随系统
    case light         // 强制浅色
    case dark          // 强制深色
}

/// 外观变化通知
public extension Notification.Name {
    static let stAppearanceDidChange = Notification.Name("com.stbaseproject.appearance.didChange")
}

/// 负责管理 SDK 中的深浅色模式
public final class STAppearanceManager {
    
    public static let shared = STAppearanceManager()
    
    /// 当前生效模式（默认跟随系统）
    public private(set) var currentMode: STAppearanceMode = .system {
        didSet {
            guard oldValue != currentMode else { return }
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: .stAppearanceDidChange,
                    object: self,
                    userInfo: ["mode": self.currentMode]
                )
            }
        }
    }
    
    private init() {}
    
    /// 外部（宿主 App）调用此方法即可切换 SDK 内部的显示模式
    /// - Parameter mode: 目标模式
    public func st_apply(mode: STAppearanceMode) {
        DispatchQueue.main.async {
            self.currentMode = mode
        }
    }
    
    /// 计算在当前配置下应该使用的 UIUserInterfaceStyle
    /// - Parameter traitCollection: 参考的 trait（为空则只根据 currentMode 决定）
    public func resolvedInterfaceStyle(for traitCollection: UITraitCollection?) -> UIUserInterfaceStyle {
        #if swift(>=5.1)
        if #available(iOS 13.0, *) {
            switch currentMode {
            case .system:
                return traitCollection?.userInterfaceStyle ?? .unspecified
            case .light:
                return .light
            case .dark:
                return .dark
            }
        }
        #endif
        // iOS 12 及以下仅支持浅色
        return .light
    }
    
    /// 是否应展示深色内容
    /// - Parameter traitCollection: 参考的 trait
    public func shouldUseDarkAppearance(for traitCollection: UITraitCollection?) -> Bool {
        if #available(iOS 13.0, *) {
            let style = resolvedInterfaceStyle(for: traitCollection)
            if currentMode == .system && style == .unspecified {
                return traitCollection?.userInterfaceStyle == .dark
            }
            return style == .dark
        }
        return currentMode == .dark
    }
    
    /// 创建一个与 SDK 外观联动的动态颜色（可用于代码/XIB/SwiftUI）
    public func dynamicColor(light: UIColor, dark: UIColor) -> UIColor {
        if #available(iOS 13.0, *) {
            return UIColor { [weak self] trait in
                guard let self = self else { return light }
                return self.shouldUseDarkAppearance(for: trait) ? dark : light
            }
        } else {
            return currentMode == .dark ? dark : light
        }
    }
    
    /// 创建一个与 SDK 外观联动的动态图片
    /// - Parameters:
    ///   - light: 浅色图片
    ///   - dark: 深色图片（可为空，默认为浅色图）
    public func dynamicImage(light: UIImage?, dark: UIImage?) -> UIImage? {
        guard let light = light else { return dark }
        if #available(iOS 13.0, *) {
            let asset = UIImageAsset()
            asset.register(light, with: UITraitCollection(userInterfaceStyle: .light))
            asset.register((dark ?? light), with: UITraitCollection(userInterfaceStyle: .dark))
            let style = resolvedInterfaceStyle(for: nil)
            let trait = UITraitCollection(userInterfaceStyle: style == .unspecified ? .light : style)
            return asset.image(with: trait)
        } else {
            return currentMode == .dark ? (dark ?? light) : light
        }
    }
}

#if canImport(SwiftUI)
import SwiftUI

@available(iOS 13.0, *)
public extension Color {
    /// SwiftUI 快捷方法：根据 SDK 外观生成 Color
    static func st_dynamic(light: UIColor, dark: UIColor) -> Color {
        let uiColor = STAppearanceManager.shared.dynamicColor(light: light, dark: dark)
        return Color(uiColor)
    }
}
#endif

