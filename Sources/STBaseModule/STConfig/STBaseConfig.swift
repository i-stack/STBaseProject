//
//  STBaseConfig.swift
//  STBaseProject
//
//  Created by stack on 2019/03/16.
//

import UIKit
import Foundation

/// 基础配置管理类
/// 负责管理设计基准尺寸和自定义导航栏配置
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
    
    // MARK: - 导航栏配置
    /// 配置自定义导航栏高度
    /// - Parameters:
    ///   - normalHeight: 普通设备导航栏高度（默认64）
    ///   - safeHeight: 刘海屏设备导航栏高度（默认88）
    public func st_configCustomNavBar(normalHeight: CGFloat, safeHeight: CGFloat) {
        guard normalHeight > 0 && safeHeight > 0 else {
            print("⚠️ STBaseConfig: 导航栏高度无效，使用默认高度")
            var model = STConstantBarHeightModel()
            model.navNormalHeight = 64
            model.navIsSafeHeight = 88
            STDeviceAdapter.shared.st_customNavHeight(model: model)
            return
        }
        
        var model = STConstantBarHeightModel()
        model.navNormalHeight = normalHeight
        model.navIsSafeHeight = safeHeight
        STDeviceAdapter.shared.st_customNavHeight(model: model)
        print("✅ STBaseConfig: 导航栏高度已配置 - 普通: \(normalHeight), 刘海屏: \(safeHeight)")
    }
    
    // MARK: - TabBar 配置
    /// 配置自定义 TabBar 高度
    /// - Parameters:
    ///   - normalHeight: 普通设备 TabBar 高度（默认49）
    ///   - safeHeight: 刘海屏设备 TabBar 高度（默认83）
    public func st_configCustomTabBar(normalHeight: CGFloat, safeHeight: CGFloat) {
        guard normalHeight > 0 && safeHeight > 0 else {
            print("⚠️ STBaseConfig: TabBar 高度无效，使用默认高度")
            var model = STConstantBarHeightModel()
            model.tabBarNormalHeight = 49
            model.tabBarIsSafeHeight = 83
            STDeviceAdapter.shared.st_customTabBarHeight(model: model)
            return
        }
        
        var model = STConstantBarHeightModel()
        model.tabBarNormalHeight = normalHeight
        model.tabBarIsSafeHeight = safeHeight
        STDeviceAdapter.shared.st_customTabBarHeight(model: model)
        print("✅ STBaseConfig: TabBar 高度已配置 - 普通: \(normalHeight), 刘海屏: \(safeHeight)")
    }
    
    // MARK: - 完整配置
    /// 配置完整的界面尺寸
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
}
