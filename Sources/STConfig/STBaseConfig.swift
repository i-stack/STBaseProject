//
//  STBaseConfig.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2019/03/16.
//

import UIKit

public final class STBaseConfig {

    public static let shared: STBaseConfig = STBaseConfig()

    private init() {}

    /// 设置默认基础配置
    /// - 设计基准尺寸：iPhone X (375x812)
    /// - 导航栏内容:iOS 标准 44
    /// - TabBar 内容:iOS 标准 49
    public func applyDefaultConfiguration() {
        self.configureInterface(designSize: CGSize(width: 375, height: 812))
    }

    /// 配置设计基准尺寸
    /// - Parameter size: 设计图的基准尺寸，通常为设计稿的尺寸
    /// - Note: 传入非法尺寸（宽高<=0）会被忽略。
    public func configureDesignSize(_ size: CGSize) {
        guard size.width > 0, size.height > 0 else {
            STLog("⚠️ STBaseConfig: 设计基准尺寸无效 (\(size))，已忽略")
            return
        }
        STDeviceAdapter.shared.configure(designSize: size)
    }

    /// 配置自定义导航栏高度。传 `nil` 则使用 iOS 标准默认值。
    /// - Parameters:
    ///   - contentHeight: 导航栏内容高度(不含状态栏),iOS 标准为 44
    ///   - containerHeight: STBaseViewController 自定义容器高度,iOS 标准为 44
    public func configureNavigationBar(contentHeight: CGFloat? = nil, containerHeight: CGFloat? = nil) {
        if let contentHeight = contentHeight, contentHeight < 0 {
            STLog("⚠️ STBaseConfig: 导航栏 contentHeight 无效，忽略")
            return
        }
        if let containerHeight = containerHeight, containerHeight < 0 {
            STLog("⚠️ STBaseConfig: 导航栏 containerHeight 无效，忽略")
            return
        }
        STDeviceAdapter.shared.configureNavigationBar(contentHeight: contentHeight, containerHeight: containerHeight)
    }

    /// 配置自定义 TabBar 高度(不含底部安全区)。iOS 标准为 49。
    public func configureTabBar(contentHeight: CGFloat) {
        guard contentHeight >= 0 else {
            STLog("⚠️ STBaseConfig: TabBar contentHeight 无效，忽略")
            return
        }
        STDeviceAdapter.shared.configureTabBar(contentHeight: contentHeight)
    }

    /// 配置完整的界面尺寸。各 bar 高度传 `nil` 表示使用 iOS 标准默认值。
    public func configureInterface(
        designSize: CGSize,
        navigationBarContentHeight: CGFloat? = nil,
        navigationBarContainerHeight: CGFloat? = nil,
        tabBarContentHeight: CGFloat? = nil
    ) {
        self.configureDesignSize(designSize)
        self.configureNavigationBar(
            contentHeight: navigationBarContentHeight,
            containerHeight: navigationBarContainerHeight
        )
        if let tabBarContentHeight = tabBarContentHeight {
            self.configureTabBar(contentHeight: tabBarContentHeight)
        }
    }

    /// 使用完整的高度模型配置
    public func applyBarHeights(_ configuration: STBarHeightsConfiguration) {
        STDeviceAdapter.shared.applyBarHeights(configuration)
    }

    /// 配置缩放策略（可限制 iPad 等大屏设备的过度放大）
    public func configureScaleStrategy(_ strategy: STScaleStrategy) {
        STDeviceAdapter.shared.configureScaleStrategy(strategy)
    }

    /// 配置字体族
    public func configureFontFamily(_ config: STFontFamilyConfig) {
        STFontManager.shared.configure(fontFamily: config)
    }

    /// 快速配置 iPhone X 设计基准
    public func configureForIPhoneX() {
        self.configureInterface(designSize: CGSize(width: 375, height: 812))
    }

    /// 快速配置 iPhone 14 Pro 设计基准
    public func configureForIPhone14Pro() {
        self.configureInterface(designSize: CGSize(width: 393, height: 852))
    }

    /// 启用应用生命周期监控
    public func enableAppLifecycleMonitoring(
        timeoutInterval: TimeInterval? = nil,
        onBackgroundTimeout: ((TimeInterval) -> Void)? = nil,
        onDidEnterBackground: (() -> Void)? = nil,
        onWillEnterForeground: (() -> Void)? = nil
    ) {
        let manager = STAppLifecycleManager.shared
        if let timeoutInterval = timeoutInterval {
            manager.backgroundTimeoutInterval = timeoutInterval
        }
        manager.onBackgroundTimeout = onBackgroundTimeout
        manager.onDidEnterBackground = onDidEnterBackground
        manager.onWillEnterForeground = onWillEnterForeground
        manager.restoreBackgroundTimestampIfNeeded()
        manager.start()
    }
}
