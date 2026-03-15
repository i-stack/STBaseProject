//
//  STBaseConfig.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2019/03/16.
//

import UIKit
import Foundation

public class STBaseConfig: NSObject {
    
    public static let shared: STBaseConfig = STBaseConfig()
    
    private override init() {
        super.init()
    }
    
    /// 设置默认基础配置
    /// 使用 iPhone X 的设计基准尺寸 (375x812)
    /// 使用默认导航栏高度
    public func applyDefaultConfiguration() {
        self.configureDesignSize(CGSize(width: 375, height: 812))
        self.configureNavigationBar(regularHeight: 64, safeAreaHeight: 88)
    }
    
    /// 配置设计基准尺寸
    /// - Parameter size: 设计图的基准尺寸，通常为设计稿的尺寸
    /// - Note: 建议使用 iPhone X 的尺寸 (375x812) 作为基准
    public func configureDesignSize(_ size: CGSize) {
        guard size.width > 0 && size.height > 0 else {
            STLog("⚠️ STBaseConfig: 设计基准尺寸无效，使用默认尺寸")
            STDeviceAdapter.shared.configure(designSize: CGSize(width: 375, height: 812))
            return
        }
        STDeviceAdapter.shared.configure(designSize: size)
        STLog("✅ STBaseConfig: 设计基准尺寸已设置为 \(size)")
    }
    
    /// 配置自定义导航栏高度
    /// - Parameters:
    ///   - normalHeight: 普通设备导航栏高度（默认64）
    ///   - safeHeight: 刘海屏设备导航栏高度（默认88）
    public func configureNavigationBar(regularHeight: CGFloat, safeAreaHeight: CGFloat) {
        STDeviceAdapter.shared.configureNavigationBar(regularHeight: regularHeight, safeAreaHeight: safeAreaHeight)
    }
    
    /// 配置自定义 TabBar 高度
    /// - Parameters:
    ///   - normalHeight: 普通设备 TabBar 高度（默认49）
    ///   - safeHeight: 刘海屏设备 TabBar 高度（默认83）
    public func configureTabBar(regularHeight: CGFloat, safeAreaHeight: CGFloat) {
        STDeviceAdapter.shared.configureTabBar(regularHeight: regularHeight, safeAreaHeight: safeAreaHeight)
    }
    
    /// 配置完整的界面尺寸
    /// - Parameters:
    ///   - designSize: 设计基准尺寸
    ///   - navNormalHeight: 普通设备导航栏高度
    ///   - navSafeHeight: 刘海屏设备导航栏高度
    ///   - tabBarNormalHeight: 普通设备 TabBar 高度
    ///   - tabBarSafeHeight: 刘海屏设备 TabBar 高度
    public func configureInterface(
        designSize: CGSize,
        navigationBarRegularHeight: CGFloat = 64,
        navigationBarSafeAreaHeight: CGFloat = 88,
        tabBarRegularHeight: CGFloat = 49,
        tabBarSafeAreaHeight: CGFloat = 83
    ) {
        self.configureDesignSize(designSize)
        self.configureNavigationBar(regularHeight: navigationBarRegularHeight, safeAreaHeight: navigationBarSafeAreaHeight)
        self.configureTabBar(regularHeight: tabBarRegularHeight, safeAreaHeight: tabBarSafeAreaHeight)
    }
    
    /// 使用完整的高度模型配置
    /// - Parameter model: 完整的高度模型
    public func applyBarHeights(_ configuration: STBarHeightsConfiguration) {
        STDeviceAdapter.shared.applyBarHeights(configuration)
    }
    
    /// 快速配置 iPhone X 设计基准
    public func configureForIPhoneX() {
        self.configureInterface(
            designSize: CGSize(width: 375, height: 812),
            navigationBarRegularHeight: 64,
            navigationBarSafeAreaHeight: 88,
            tabBarRegularHeight: 49,
            tabBarSafeAreaHeight: 83
        )
    }
    
    /// 快速配置 iPhone 14 Pro 设计基准
    public func configureForIPhone14Pro() {
        self.configureInterface(
            designSize: CGSize(width: 393, height: 852),
            navigationBarRegularHeight: 64,
            navigationBarSafeAreaHeight: 88,
            tabBarRegularHeight: 49,
            tabBarSafeAreaHeight: 83
        )
    }
    
    /// 启用应用生命周期监控
    /// - Parameters:
    ///   - timeoutInterval: 后台超时时间，默认沿用 STAppLifecycleManager 的设定
    ///   - onBackgroundTimeout: 超时回调，参数为后台停留秒数
    ///   - onDidEnterBackground: 进入后台回调
    ///   - onWillEnterForeground: 进入前台回调
    public func enableAppLifecycleMonitoring(
        timeoutInterval: TimeInterval = STAppLifecycleManager.shared.backgroundTimeoutInterval,
        onBackgroundTimeout: ((TimeInterval) -> Void)? = nil,
        onDidEnterBackground: (() -> Void)? = nil,
        onWillEnterForeground: (() -> Void)? = nil
    ) {
        let manager = STAppLifecycleManager.shared
        manager.backgroundTimeoutInterval = timeoutInterval
        manager.onBackgroundTimeout = onBackgroundTimeout
        manager.onDidEnterBackground = onDidEnterBackground
        manager.onWillEnterForeground = onWillEnterForeground
        manager.st_restoreBackgroundTimestampIfNeeded()
    }
}
