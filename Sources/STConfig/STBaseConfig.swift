//
//  STBaseConfig.swift
//  STBaseProject
//
//  Created by stack on 2019/03/16.
//

import UIKit
import Foundation

/// 基础配置管理类
public class STBaseConfig: NSObject {
    
    public static let shared: STBaseConfig = STBaseConfig()
    
    private override init() {
        super.init()
    }
    
    // MARK: - 默认配置
    /// 设置默认基础配置
    /// 使用 iPhone X 的设计基准尺寸 (375x812)
    /// 使用默认导航栏高度
    public func st_setDefaultConfig() {
        st_configBenchmarkDesign(size: CGSize(width: 375, height: 812))
        st_configCustomNavBar(normalHeight: 64, safeHeight: 88)
    }
    
    // MARK: - 设计基准配置
    /// 配置设计基准尺寸
    /// - Parameter size: 设计图的基准尺寸，通常为设计稿的尺寸
    /// - Note: 建议使用 iPhone X 的尺寸 (375x812) 作为基准
    public func st_configBenchmarkDesign(size: CGSize) {
        guard size.width > 0 && size.height > 0 else {
            print("⚠️ STBaseConfig: 设计基准尺寸无效，使用默认尺寸")
            STDeviceAdapter.shared.st_configBenchmarkDesign(size: CGSize(width: 375, height: 812))
            return
        }
        STDeviceAdapter.shared.st_configBenchmarkDesign(size: size)
        print("✅ STBaseConfig: 设计基准尺寸已设置为 \(size)")
    }
    
    // MARK: - 便捷配置方法
    /// 配置自定义导航栏高度（便捷方法）
    /// - Parameters:
    ///   - normalHeight: 普通设备导航栏高度（默认64）
    ///   - safeHeight: 刘海屏设备导航栏高度（默认88）
    public func st_configCustomNavBar(normalHeight: CGFloat, safeHeight: CGFloat) {
        STDeviceAdapter.shared.st_customNavHeight(normalHeight: normalHeight, safeHeight: safeHeight)
    }
    
    /// 配置自定义 TabBar 高度（便捷方法）
    /// - Parameters:
    ///   - normalHeight: 普通设备 TabBar 高度（默认49）
    ///   - safeHeight: 刘海屏设备 TabBar 高度（默认83）
    public func st_configCustomTabBar(normalHeight: CGFloat, safeHeight: CGFloat) {
        STDeviceAdapter.shared.st_customTabBarHeight(normalHeight: normalHeight, safeHeight: safeHeight)
    }
    
    // MARK: - 高级配置方法
    /// 配置完整的界面尺寸（推荐使用）
    /// - Parameters:
    ///   - designSize: 设计基准尺寸
    ///   - navNormalHeight: 普通设备导航栏高度
    ///   - navSafeHeight: 刘海屏设备导航栏高度
    ///   - tabBarNormalHeight: 普通设备 TabBar 高度
    ///   - tabBarSafeHeight: 刘海屏设备 TabBar 高度
    public func st_configCompleteUI(
        designSize: CGSize,
        navNormalHeight: CGFloat = 64,
        navSafeHeight: CGFloat = 88,
        tabBarNormalHeight: CGFloat = 49,
        tabBarSafeHeight: CGFloat = 83
    ) {
        st_configBenchmarkDesign(size: designSize)
        st_configCustomNavBar(normalHeight: navNormalHeight, safeHeight: navSafeHeight)
        st_configCustomTabBar(normalHeight: tabBarNormalHeight, safeHeight: tabBarSafeHeight)
    }
    
    /// 使用完整的高度模型配置（高级用法）
    /// - Parameter model: 完整的高度模型
    public func st_configWithModel(_ model: STConstantBarHeightModel) {
        STDeviceAdapter.shared.st_customBarHeightModel(model)
    }
    
    /// 快速配置 iPhone X 设计基准（最常用）
    public func st_configForIPhoneX() {
        st_configCompleteUI(
            designSize: CGSize(width: 375, height: 812),
            navNormalHeight: 64,
            navSafeHeight: 88,
            tabBarNormalHeight: 49,
            tabBarSafeHeight: 83
        )
    }
    
    /// 快速配置 iPhone 14 Pro 设计基准
    public func st_configForIPhone14Pro() {
        st_configCompleteUI(
            designSize: CGSize(width: 393, height: 852),
            navNormalHeight: 64,
            navSafeHeight: 88,
            tabBarNormalHeight: 49,
            tabBarSafeHeight: 83
        )
    }
    
    // MARK: - 生命周期监控
    /// 启用应用生命周期监控（可选）
    /// - Parameters:
    ///   - timeoutInterval: 后台超时时间，默认沿用 STAppLifecycleManager 的设定
    ///   - onBackgroundTimeout: 超时回调，参数为后台停留秒数
    ///   - onDidEnterBackground: 进入后台回调
    ///   - onWillEnterForeground: 进入前台回调
    public func st_enableAppLifecycleMonitoring(
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
