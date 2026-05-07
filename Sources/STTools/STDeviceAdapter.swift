//
//  STDeviceAdapter.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2019/03/16.
//

import UIKit

public struct STBarHeightsConfiguration: Sendable, Equatable {

    /// 导航栏内部 items 容器(navigationBarItemsView,承载 title / leftBtn / rightBtn)的高度。
    /// 设计图上通常 44(iOS 标准)或 50。整个导航栏总高随设备状态栏动态计算为 statusBar + 此值。
    public var navigationBarContentHeight: CGFloat = 44.0
    /// TabBar 内容高度(不含底部安全区)。iOS 标准值 49。
    public var tabBarContentHeight: CGFloat = 49.0

    public init() {}
}

public struct STScaleStrategy: Sendable, Equatable {

    public var minScale: CGFloat?
    public var maxScale: CGFloat?
    public var rounding: FloatingPointRoundingRule

    public init(minScale: CGFloat? = nil, maxScale: CGFloat? = nil, rounding: FloatingPointRoundingRule = .up) {
        self.minScale = minScale
        self.maxScale = maxScale
        self.rounding = rounding
    }

    public static let `default` = STScaleStrategy()
    public static let padFriendly = STScaleStrategy(maxScale: 1.3)
}

public struct STDeviceMetrics: Sendable, Equatable {
    public let screenBounds: CGRect
    public let screenScale: CGFloat
    public let safeAreaInsets: UIEdgeInsets
    public let interfaceOrientation: UIInterfaceOrientation
    public let statusBarHeight: CGFloat
    public let isNotchScreen: Bool
}

public protocol STDeviceAdapting: AnyObject {
    var designSize: CGSize? { get }
    var barHeights: STBarHeightsConfiguration { get }
    var scaleStrategy: STScaleStrategy { get }
    var currentMetrics: STDeviceMetrics { get }
}

public final class STDeviceAdapter: STDeviceAdapting {

    public static let shared = STDeviceAdapter()
    private let configurationLock = NSLock()
    private var storedDesignSize: CGSize?
    private var storedBarHeights = STBarHeightsConfiguration()
    private var storedScaleStrategy: STScaleStrategy = .default

    public var designSize: CGSize? {
        self.withConfigurationLock { self.storedDesignSize }
    }

    public var barHeights: STBarHeightsConfiguration {
        self.withConfigurationLock { self.storedBarHeights }
    }

    public var scaleStrategy: STScaleStrategy {
        self.withConfigurationLock { self.storedScaleStrategy }
    }

    private init() {}

    public func configure(designSize: CGSize?) {
        self.configurationLock.lock()
        defer { self.configurationLock.unlock() }
        guard let size = designSize, size.width > 0, size.height > 0 else {
            self.storedDesignSize = nil
            return
        }
        self.storedDesignSize = designSize
    }

    public func configureNavigationBar(contentHeight: CGFloat) {
        guard contentHeight >= 0 else { return }
        self.configurationLock.lock()
        defer { self.configurationLock.unlock() }
        self.storedBarHeights.navigationBarContentHeight = contentHeight
    }

    public func configureTabBar(contentHeight: CGFloat) {
        guard contentHeight >= 0 else { return }
        self.configurationLock.lock()
        defer { self.configurationLock.unlock() }
        self.storedBarHeights.tabBarContentHeight = contentHeight
    }

    public func applyBarHeights(_ configuration: STBarHeightsConfiguration) {
        self.configurationLock.lock()
        defer { self.configurationLock.unlock() }
        self.storedBarHeights = configuration
    }

    public func configureScaleStrategy(_ strategy: STScaleStrategy) {
        self.configurationLock.lock()
        defer { self.configurationLock.unlock() }
        self.storedScaleStrategy = strategy
    }

    /// 重置所有配置到初始值
    public func reset() {
        self.configurationLock.lock()
        defer { self.configurationLock.unlock() }
        self.storedDesignSize = nil
        self.storedBarHeights = STBarHeightsConfiguration()
        self.storedScaleStrategy = .default
    }

    public static var widthScale: CGFloat {
        let snapshot = self.shared.configurationSnapshot()
        guard let designSize = snapshot.designSize else { return 1.0 }
        let raw = self.screenWidth / designSize.width
        return clamped(raw, strategy: snapshot.scaleStrategy)
    }

    public static var heightScale: CGFloat {
        let snapshot = self.shared.configurationSnapshot()
        guard let designSize = snapshot.designSize else { return 1.0 }
        let raw = self.screenHeight / designSize.height
        return clamped(raw, strategy: snapshot.scaleStrategy)
    }

    public static func scaledWidth(_ value: CGFloat) -> CGFloat {
        scaled(value, multiplier: self.widthScale)
    }

    public static func scaledHeight(_ value: CGFloat) -> CGFloat {
        scaled(value, multiplier: self.heightScale)
    }

    /// 字体缩放建议使用 `UIFont.st_preferredFont(ofSize:forTextStyle:)` 以联动 Dynamic Type。
    /// 本方法仅按设计稿宽度等比缩放,不响应系统字号设置。
    public static func scaledFontSize(_ value: CGFloat) -> CGFloat {
        scaledWidth(value)
    }

    public static func scaledSpacing(_ value: CGFloat) -> CGFloat {
        scaledWidth(value)
    }

    /// 屏幕/窗口尺寸。
    /// 优先级:key window.bounds → active scene.screen.bounds → `UIScreen.main.bounds`(退化兜底)。
    /// 最后一档是 iOS 16+ 已弃用的 `UIScreen.main`,但 App 启动早期(AppDelegate.didFinishLaunching
    /// 期间、`makeKeyAndVisible` 之前)只有这条路径能返回非零尺寸。
    public static var screenBounds: CGRect {
        assertMainThread()
        if let window = self.activeKeyWindow { return window.bounds }
        if let scene = self.activeWindowScene { return scene.screen.bounds }
        return self.fallbackMainScreenBounds
    }

    public static var screenWidth: CGFloat { self.screenBounds.width }
    public static var screenHeight: CGFloat { self.screenBounds.height }
    public static var screenSize: CGSize { self.screenBounds.size }

    public static var screenScale: CGFloat {
        assertMainThread()
        if let scale = self.activeWindowScene?.screen.scale { return scale }
        if let scale = self.activeKeyWindow?.screen.scale { return scale }
        return self.fallbackMainScreenScale
    }

    public static var safeAreaInsets: UIEdgeInsets {
        assertMainThread()
        return self.activeKeyWindow?.safeAreaInsets ?? .zero
    }

    public static var statusBarHeight: CGFloat {
        assertMainThread()
        return self.activeWindowScene?.statusBarManager?.statusBarFrame.height ?? 0
    }

    /// 是否为带 home indicator 的全面屏设备(刘海/灵动岛/iPad Pro with home indicator)。
    /// 判据:idiom==.phone 且底部安全区 > 0;对于 iPad,通常不需要"刘海"这个概念,返回 false。
    public static var isNotchScreen: Bool {
        assertMainThread()
        guard UIDevice.current.userInterfaceIdiom == .phone else { return false }
        return self.safeAreaInsets.bottom > 0 || self.safeAreaInsets.top > 20
    }

    /// 导航栏内部 items 容器(navigationBarItemsView)高度,由配置固定。
    public static var navigationBarContentHeight: CGFloat {
        self.shared.barHeights.navigationBarContentHeight
    }

    /// 整个导航栏总高(从 view.top 到 navigationBarView.bottom) = 顶部安全区高度 + items 高度。
    /// 与 STBaseViewController 的真实布局口径一致(items 顶部锚定 safeAreaLayoutGuide.top)。
    /// 随设备动态变化(SE 64 / 刘海 88 / 灵动岛 ≈98);statusBarHidden、通话热点等状态下也能与实际渲染保持一致。
    public static var navigationBarHeight: CGFloat {
        self.safeAreaInsets.top + self.navigationBarContentHeight
    }

    /// TabBar 自身高度(不含底部安全区)。
    public static var tabBarHeight: CGFloat {
        self.shared.barHeights.tabBarContentHeight
    }

    public static var bottomSafeAreaHeight: CGFloat { 
        self.safeAreaInsets.bottom 
    }

    /// TabBar + 底部安全区,用于贴齐屏幕底部的完整占位高度。
    public static var safeTabBarHeight: CGFloat { 
        self.tabBarHeight + self.bottomSafeAreaHeight 
    }

    public static var contentHeight: CGFloat {
        self.screenHeight - self.navigationBarHeight
    }

    public static var contentHeightWithTabBar: CGFloat {
        self.screenHeight - self.navigationBarHeight - self.safeTabBarHeight
    }

    public static var interfaceOrientation: UIInterfaceOrientation {
        self.activeWindowScene?.interfaceOrientation ?? .portrait
    }

    public static var isLandscape: Bool { self.interfaceOrientation.isLandscape }
    public static var isPortrait: Bool { self.interfaceOrientation.isPortrait }

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

    public static var currentMetrics: STDeviceMetrics { self.shared.currentMetrics }

    private func withConfigurationLock<T>(_ body: () -> T) -> T {
        self.configurationLock.lock()
        defer { self.configurationLock.unlock() }
        return body()
    }

    private func configurationSnapshot() -> (designSize: CGSize?, barHeights: STBarHeightsConfiguration, scaleStrategy: STScaleStrategy) {
        self.withConfigurationLock {
            (
                designSize: self.storedDesignSize,
                barHeights: self.storedBarHeights,
                scaleStrategy: self.storedScaleStrategy
            )
        }
    }

    /// UIKit 访问入口必须在主线程。DEBUG 构建强校验,Release 构建不引入成本。
    /// UIApplication.connectedScenes / UIWindow.safeAreaInsets / UIScreen.main 等 API
    /// 文档均要求主线程,后台调用可能读到脏状态或触发不可预期行为。
    @inline(__always)
    private static func assertMainThread(_ function: StaticString = #function) {
        #if DEBUG
        dispatchPrecondition(condition: .onQueue(.main))
        #endif
    }

    /// 选择 scene 的优先级:
    /// 1. foregroundActive 且包含 key window(最可信)
    /// 2. 任意 foregroundActive
    /// 3. foregroundInactive 且包含 key window
    /// 4. 任意 foregroundInactive
    /// 5. 第一个可用 UIWindowScene
    /// 避免 iPad 多窗口/外接屏时选到非当前 UI 的 scene。
    private static var activeWindowScene: UIWindowScene? {
        assertMainThread()
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
        assertMainThread()
        guard let scene = self.activeWindowScene else { return nil }
        if let key = scene.windows.first(where: \.isKeyWindow) { return key }
        return scene.windows.first
    }

    /// `UIScreen.main` 的兜底访问。该 API 在 iOS 16+ 标记为 deprecated,但在 scene/window 尚未就绪的
    /// 冷启动阶段仍是唯一可用的屏幕尺寸来源。封装在此以集中管理弃用告警。
    @available(iOS, introduced: 13.0)
    private static var fallbackMainScreenBounds: CGRect {
        assertMainThread()
        #if swift(>=5.9)
        if #available(iOS 16.0, *) {
            // 继续使用 UIScreen.main;Apple 并未提供无 scene 场景下的等价替代。
        }
        #endif
        return UIScreen.main.bounds
    }

    private static var fallbackMainScreenScale: CGFloat {
        assertMainThread()
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
