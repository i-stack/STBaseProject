//
//  STDeviceAdapter.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2019/03/16.
//

import UIKit

// MARK: - Bar Heights

public struct STBarHeightsConfiguration: Sendable, Equatable {

    public var navigationBarRegularHeight: CGFloat = 64.0
    public var navigationBarSafeAreaHeight: CGFloat = 88.0
    public var navigationBarContainerHeight: CGFloat = 50.0
    public var tabBarRegularHeight: CGFloat = 49.0
    public var tabBarSafeAreaHeight: CGFloat = 83.0

    public init() {}
}

// MARK: - Scale Strategy

public struct STScaleStrategy: Sendable, Equatable {

    public var minScale: CGFloat?
    public var maxScale: CGFloat?
    public var rounding: FloatingPointRoundingRule

    public init(minScale: CGFloat? = nil, maxScale: CGFloat? = nil, rounding: FloatingPointRoundingRule = .up) {
        self.minScale = minScale
        self.maxScale = maxScale
        self.rounding = rounding
    }

    /// 默认策略:不做 clamp,向上对齐到物理像素(保护分割线/细边框/最小间距不被压小)
    public static let `default` = STScaleStrategy()

    /// iPad 场景常用策略:限制最大缩放倍率,避免字号/间距过度放大
    public static let padFriendly = STScaleStrategy(maxScale: 1.3)
}

// MARK: - Device Metrics Snapshot

public struct STDeviceMetrics: Sendable, Equatable {
    public let screenBounds: CGRect
    public let screenScale: CGFloat
    public let safeAreaInsets: UIEdgeInsets
    public let interfaceOrientation: UIInterfaceOrientation
    public let statusBarHeight: CGFloat
    public let isNotchScreen: Bool
}

// MARK: - Protocol Abstraction

public protocol STDeviceAdapting: AnyObject {
    var designSize: CGSize? { get }
    var barHeights: STBarHeightsConfiguration { get }
    var scaleStrategy: STScaleStrategy { get }
    var currentMetrics: STDeviceMetrics { get }
}

// MARK: - STDeviceAdapter

/// 设备/屏幕适配器。
///
/// **线程要求**:本类型的所有公开方法与静态属性都会访问 `UIApplication` / `UIWindow` / `UIScreen`,
/// 仅能在主线程调用。目前未以 `@MainActor` 约束(为避免 UIFont 扩展与 STMarkdown 渲染层产生级联 actor 迁移)。
/// 后续计划:待 STMarkdown 渲染层并发模型梳理后,整体加上 `@MainActor`。
public final class STDeviceAdapter: STDeviceAdapting {

    public static let shared = STDeviceAdapter()

    public static let configurationDidChangeNotification = Notification.Name("STDeviceAdapterConfigurationDidChange")

    public private(set) var designSize: CGSize?
    public private(set) var barHeights = STBarHeightsConfiguration()
    public private(set) var scaleStrategy: STScaleStrategy = .default

    private init() {}

    // MARK: - Configuration

    public func configure(designSize: CGSize?) {
        if let size = designSize, (size.width <= 0 || size.height <= 0) {
            self.designSize = nil
        } else {
            self.designSize = designSize
        }
        self.postConfigurationChange()
    }

    public func configureNavigationBar(regularHeight: CGFloat, safeAreaHeight: CGFloat, containerHeight: CGFloat? = nil) {
        guard regularHeight >= 0, safeAreaHeight >= 0 else { return }
        self.barHeights.navigationBarRegularHeight = regularHeight
        self.barHeights.navigationBarSafeAreaHeight = safeAreaHeight
        if let containerHeight = containerHeight, containerHeight >= 0 {
            self.barHeights.navigationBarContainerHeight = containerHeight
        }
        self.postConfigurationChange()
    }

    public func configureTabBar(regularHeight: CGFloat, safeAreaHeight: CGFloat) {
        guard regularHeight >= 0, safeAreaHeight >= 0 else { return }
        self.barHeights.tabBarRegularHeight = regularHeight
        self.barHeights.tabBarSafeAreaHeight = safeAreaHeight
        self.postConfigurationChange()
    }

    public func applyBarHeights(_ configuration: STBarHeightsConfiguration) {
        self.barHeights = configuration
        self.postConfigurationChange()
    }

    public func configureScaleStrategy(_ strategy: STScaleStrategy) {
        self.scaleStrategy = strategy
        self.postConfigurationChange()
    }

    /// 仅用于测试:重置所有配置到初始值
    public func reset() {
        self.designSize = nil
        self.barHeights = STBarHeightsConfiguration()
        self.scaleStrategy = .default
        self.postConfigurationChange()
    }

    private func postConfigurationChange() {
        NotificationCenter.default.post(name: STDeviceAdapter.configurationDidChangeNotification, object: self)
    }

    // MARK: - Scaling

    public static var widthScale: CGFloat {
        guard let designSize = shared.designSize else { return 1.0 }
        let raw = screenWidth / designSize.width
        return clamped(raw, strategy: shared.scaleStrategy)
    }

    public static var heightScale: CGFloat {
        guard let designSize = shared.designSize else { return 1.0 }
        let raw = screenHeight / designSize.height
        return clamped(raw, strategy: shared.scaleStrategy)
    }

    public static func scaledValue(_ value: CGFloat) -> CGFloat {
        scaled(value, multiplier: widthScale)
    }

    public static func scaledHeightValue(_ value: CGFloat) -> CGFloat {
        scaled(value, multiplier: heightScale)
    }

    public static func scaledWidth(_ value: CGFloat) -> CGFloat {
        scaledValue(value)
    }

    public static func scaledHeight(_ value: CGFloat) -> CGFloat {
        scaledHeightValue(value)
    }

    /// 注意:字体缩放建议使用 `UIFont.st_preferredFont(ofSize:forTextStyle:)` 以联动 Dynamic Type。
    /// 本方法仅按设计稿宽度等比缩放,不响应系统字号设置。
    public static func scaledFontSize(_ value: CGFloat) -> CGFloat {
        scaledValue(value)
    }

    public static func scaledSpacing(_ value: CGFloat) -> CGFloat {
        scaledValue(value)
    }

    // MARK: - Screen Metrics (scene-based)

    /// 屏幕/窗口尺寸。
    /// 优先级:key window.bounds → active scene.screen.bounds → `UIScreen.main.bounds`(退化兜底)。
    /// 最后一档是 iOS 16+ 已弃用的 `UIScreen.main`,但 App 启动早期(AppDelegate.didFinishLaunching
    /// 期间、`makeKeyAndVisible` 之前)只有这条路径能返回非零尺寸。
    public static var screenBounds: CGRect {
        if let window = activeKeyWindow { return window.bounds }
        if let scene = activeWindowScene { return scene.screen.bounds }
        return fallbackMainScreenBounds
    }

    public static var screenWidth: CGFloat { screenBounds.width }
    public static var screenHeight: CGFloat { screenBounds.height }
    public static var screenSize: CGSize { screenBounds.size }

    public static var screenScale: CGFloat {
        if let scale = activeWindowScene?.screen.scale { return scale }
        if let scale = activeKeyWindow?.screen.scale { return scale }
        return fallbackMainScreenScale
    }

    // MARK: - Safe Area / Status Bar

    public static var safeAreaInsets: UIEdgeInsets {
        activeKeyWindow?.safeAreaInsets ?? .zero
    }

    public static var statusBarHeight: CGFloat {
        activeWindowScene?.statusBarManager?.statusBarFrame.height ?? 0
    }

    /// 是否为带 home indicator 的全面屏设备(刘海/灵动岛/iPad Pro with home indicator)。
    /// 判据:idiom==.phone 且底部安全区 > 0;对于 iPad,通常不需要"刘海"这个概念,返回 false。
    public static var isNotchScreen: Bool {
        guard UIDevice.current.userInterfaceIdiom == .phone else { return false }
        return safeAreaInsets.bottom > 0 || safeAreaInsets.top > 20
    }

    // MARK: - Bar Heights

    public static var navigationBarHeight: CGFloat {
        isNotchScreen
        ? shared.barHeights.navigationBarSafeAreaHeight
        : shared.barHeights.navigationBarRegularHeight
    }

    public static var navigationBarContainerHeight: CGFloat {
        shared.barHeights.navigationBarContainerHeight
    }

    public static var tabBarHeight: CGFloat {
        isNotchScreen
        ? shared.barHeights.tabBarSafeAreaHeight
        : shared.barHeights.tabBarRegularHeight
    }

    public static var bottomSafeAreaHeight: CGFloat { safeAreaInsets.bottom }

    public static var safeTabBarHeight: CGFloat { tabBarHeight + bottomSafeAreaHeight }

    public static var contentHeight: CGFloat {
        screenHeight - navigationBarHeight - statusBarHeight
    }

    public static var contentHeightWithTabBar: CGFloat {
        screenHeight - navigationBarHeight - statusBarHeight - tabBarHeight
    }

    // MARK: - Orientation (scene-based, reliable)

    public static var interfaceOrientation: UIInterfaceOrientation {
        activeWindowScene?.interfaceOrientation ?? .portrait
    }

    public static var isLandscape: Bool { interfaceOrientation.isLandscape }
    public static var isPortrait: Bool { interfaceOrientation.isPortrait }

    /// 已弃用:请改用 `interfaceOrientation`(返回 `UIInterfaceOrientation`)。
    /// 保留此兼容入口以减少外部调用方升级成本;内部不再使用 `UIDevice.current.orientation`
    /// (需要显式 beginGeneratingDeviceOrientationNotifications,且 faceUp/faceDown 时不反映界面方向)。
    @available(*, deprecated, renamed: "interfaceOrientation", message: "Use interfaceOrientation; UIDevice.current.orientation is unreliable.")
    public static var orientation: UIDeviceOrientation {
        switch interfaceOrientation {
        case .portrait:           return .portrait
        case .portraitUpsideDown: return .portraitUpsideDown
        case .landscapeLeft:      return .landscapeLeft
        case .landscapeRight:     return .landscapeRight
        case .unknown:            return .unknown
        @unknown default:         return .unknown
        }
    }

    // MARK: - Snapshot

    public var currentMetrics: STDeviceMetrics {
        STDeviceMetrics(
            screenBounds: STDeviceAdapter.screenBounds,
            screenScale: STDeviceAdapter.screenScale,
            safeAreaInsets: STDeviceAdapter.safeAreaInsets,
            interfaceOrientation: STDeviceAdapter.interfaceOrientation,
            statusBarHeight: STDeviceAdapter.statusBarHeight,
            isNotchScreen: STDeviceAdapter.isNotchScreen
        )
    }

    public static var currentMetrics: STDeviceMetrics { shared.currentMetrics }

    // MARK: - Private

    /// 选择 scene 的优先级:
    /// 1. foregroundActive 且包含 key window(最可信)
    /// 2. 任意 foregroundActive
    /// 3. foregroundInactive 且包含 key window
    /// 4. 任意 foregroundInactive
    /// 5. 第一个可用 UIWindowScene
    /// 避免 iPad 多窗口/外接屏时选到非当前 UI 的 scene。
    private static var activeWindowScene: UIWindowScene? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        if let s = scenes.first(where: { $0.activationState == .foregroundActive && $0.windows.contains(where: \.isKeyWindow) }) {
            return s
        }
        if let s = scenes.first(where: { $0.activationState == .foregroundActive }) {
            return s
        }
        if let s = scenes.first(where: { $0.activationState == .foregroundInactive && $0.windows.contains(where: \.isKeyWindow) }) {
            return s
        }
        if let s = scenes.first(where: { $0.activationState == .foregroundInactive }) {
            return s
        }
        return scenes.first
    }

    /// 优先返回 key window;退化到 scene 内任意可见 window。
    private static var activeKeyWindow: UIWindow? {
        guard let scene = activeWindowScene else { return nil }
        if let key = scene.windows.first(where: \.isKeyWindow) { return key }
        return scene.windows.first
    }

    /// `UIScreen.main` 的兜底访问。该 API 在 iOS 16+ 标记为 deprecated,但在 scene/window 尚未就绪的
    /// 冷启动阶段仍是唯一可用的屏幕尺寸来源。封装在此以集中管理弃用告警。
    @available(iOS, introduced: 13.0)
    private static var fallbackMainScreenBounds: CGRect {
        #if swift(>=5.9)
        if #available(iOS 16.0, *) {
            // 继续使用 UIScreen.main;Apple 并未提供无 scene 场景下的等价替代。
        }
        #endif
        return UIScreen.main.bounds
    }

    private static var fallbackMainScreenScale: CGFloat {
        return UIScreen.main.scale
    }

    private static func scaled(_ value: CGFloat, multiplier: CGFloat) -> CGFloat {
        let result = value * multiplier
        let scale = screenScale
        guard scale > 0 else { return result }
        return (result * scale).rounded(shared.scaleStrategy.rounding) / scale
    }

    private static func clamped(_ value: CGFloat, strategy: STScaleStrategy) -> CGFloat {
        var v = value
        if let min = strategy.minScale { v = Swift.max(v, min) }
        if let max = strategy.maxScale { v = Swift.min(v, max) }
        return v
    }
}
