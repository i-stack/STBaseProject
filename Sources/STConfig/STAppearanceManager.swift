//
//  STAppearanceManager.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2018/3/14.
//

import UIKit
import Combine

/// SDK 统一的外观模式
public enum STAppearanceMode: Equatable {
    case system        // 跟随系统
    case light         // 强制浅色
    case dark          // 强制深色
}

/// 负责管理 SDK 中的深浅色模式
public final class STAppearanceManager {

    public static let shared = STAppearanceManager()

    private let lock = NSLock()
    private var _currentMode: STAppearanceMode = .system
    private var subscriptions: [UUID: CurrentValueSubject<STAppearanceMode, Never>] = [:]

    /// 当前生效模式（默认跟随系统）
    public var currentMode: STAppearanceMode {
        self.lock.lock()
        defer { self.lock.unlock() }
        return self._currentMode
    }

    /// 订阅此 publisher 以响应外观模式变化；新订阅者立即收到当前值
    public var appearanceModePublisher: AnyPublisher<STAppearanceMode, Never> {
        let id = UUID()
        let subject: CurrentValueSubject<STAppearanceMode, Never>
        self.lock.lock()
        subject = CurrentValueSubject(self._currentMode)
        self.subscriptions[id] = subject
        self.lock.unlock()
        return subject
            .handleEvents(receiveCancel: { [weak self] in
                self?.removeSubscription(id)
            })
            .eraseToAnyPublisher()
    }

    private init() {}

    /// 外部（宿主 App）调用此方法即可切换 SDK 内部的显示模式
    /// - Parameter mode: 目标模式
    public func apply(mode: STAppearanceMode) {
        self.lock.lock()
        let changed = self._currentMode != mode
        if changed {
            self._currentMode = mode
        }
        let subjects = Array(self.subscriptions.values)
        self.lock.unlock()
        guard changed else { return }

        let sendBlock = {
            subjects.forEach { $0.send(mode) }
        }
        if Thread.isMainThread {
            sendBlock()
            return
        }
        DispatchQueue.main.async {
            sendBlock()
        }
    }

    /// 计算在当前配置下应该使用的 UIUserInterfaceStyle
    /// - Parameter traitCollection: 参考的 trait（为空则回退到 key window 或系统当前 trait）
    public func resolvedInterfaceStyle(for traitCollection: UITraitCollection?) -> UIUserInterfaceStyle {
        switch self.currentMode {
        case .system:
            if let style = traitCollection?.userInterfaceStyle, style != .unspecified {
                return style
            }
            return self.systemInterfaceStyle()
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }

    /// 是否应展示深色内容
    /// - Parameter traitCollection: 参考的 trait
    public func shouldUseDarkAppearance(for traitCollection: UITraitCollection?) -> Bool {
        return self.resolvedInterfaceStyle(for: traitCollection) == .dark
    }

    /// 创建一个与 SDK 外观联动的动态颜色（可用于代码/XIB/SwiftUI）
    public func dynamicColor(light: UIColor, dark: UIColor) -> UIColor {
        return UIColor { [weak self] trait in
            guard let self = self else { return light }
            return self.shouldUseDarkAppearance(for: trait) ? dark : light
        }
    }

    /// 创建一个与 SDK 外观联动的动态图片
    /// - Parameters:
    ///   - light: 浅色图片（可为空，为空时使用 dark 兜底）
    ///   - dark: 深色图片（可为空，为空时使用 light 兜底）
    public func dynamicImage(light: UIImage?, dark: UIImage?) -> UIImage? {
        guard let lightImage = light ?? dark,
              let darkImage = dark ?? light else {
            return nil
        }
        let asset = UIImageAsset()
        asset.register(lightImage, with: UITraitCollection(userInterfaceStyle: .light))
        asset.register(darkImage, with: UITraitCollection(userInterfaceStyle: .dark))
        let style = self.resolvedInterfaceStyle(for: nil)
        let trait = UITraitCollection(userInterfaceStyle: style == .unspecified ? .light : style)
        return asset.image(with: trait)
    }

    /// 读取系统当前的外观（通过 key window 或其它可用 scene），用于 `.system` 模式下的兜底
    private func systemInterfaceStyle() -> UIUserInterfaceStyle {
        if Thread.isMainThread {
            return self.readKeyWindowStyle()
        }
        var style: UIUserInterfaceStyle = .unspecified
        DispatchQueue.main.sync {
            style = self.readKeyWindowStyle()
        }
        return style
    }

    private func readKeyWindowStyle() -> UIUserInterfaceStyle {
        let scenes = UIApplication.shared.connectedScenes
        for scene in scenes {
            guard let windowScene = scene as? UIWindowScene else { continue }
            if let keyWindow = windowScene.windows.first(where: { $0.isKeyWindow }) ?? windowScene.windows.first {
                return keyWindow.traitCollection.userInterfaceStyle
            }
        }
        return .unspecified
    }

    private func removeSubscription(_ id: UUID) {
        self.lock.lock()
        self.subscriptions[id] = nil
        self.lock.unlock()
    }
}

#if canImport(SwiftUI)
import SwiftUI

public extension Color {
    /// 根据 SDK 外观生成 Color
    static func st_dynamic(light: UIColor, dark: UIColor) -> Color {
        let uiColor = STAppearanceManager.shared.dynamicColor(light: light, dark: dark)
        return Color(uiColor)
    }
}
#endif
