//
//  STDeviceAdapter.swift
//  STBaseProject
//
//  Created by stack on 2019/03/16.
//

import UIKit
import Foundation

// MARK: - 导航栏高度模型
/// 自定义导航栏和 TabBar 高度模型
public struct STConstantBarHeightModel {
    public var navNormalHeight: CGFloat = 64.0
    public var navIsSafeHeight: CGFloat = 88.0
    public var tabBarNormalHeight: CGFloat = 49.0
    public var tabBarIsSafeHeight: CGFloat = 83.0
    
    public init() {}
    
    public init(
        navNormalHeight: CGFloat = 64.0,
        navIsSafeHeight: CGFloat = 88.0,
        tabBarNormalHeight: CGFloat = 49.0,
        tabBarIsSafeHeight: CGFloat = 83.0
    ) {
        self.navNormalHeight = navNormalHeight
        self.navIsSafeHeight = navIsSafeHeight
        self.tabBarNormalHeight = tabBarNormalHeight
        self.tabBarIsSafeHeight = tabBarIsSafeHeight
    }
}

// MARK: - 设备类型枚举
public enum STDeviceType {
    case iPhone
    case iPad
    case mac
    case unknown
}

// MARK: - 设备适配管理类
/// 设备适配管理类
/// 负责设备判断、尺寸计算、比例缩放、界面适配等功能
public class STDeviceAdapter: NSObject {
    
    public static let shared: STDeviceAdapter = STDeviceAdapter()
    private var benchmarkDesignSize = CGSize.zero
    private var barHeightModel: STConstantBarHeightModel = STConstantBarHeightModel()
    
    private override init() {
        super.init()
    }
    
    // MARK: - 设计基准配置
    /// 配置设计基准尺寸
    /// - Parameter size: 设计图的基准尺寸
    public func st_configBenchmarkDesign(size: CGSize) {
        self.benchmarkDesignSize = size
    }
    
    /// 获取当前设计基准尺寸
    public func st_getBenchmarkDesignSize() -> CGSize {
        return benchmarkDesignSize
    }
    
    // MARK: - 导航栏配置
    /// 配置自定义导航栏高度
    /// - Parameter model: 导航栏高度模型
    public func st_customNavHeight(model: STConstantBarHeightModel) {
        self.barHeightModel = model
    }
    
    /// 配置自定义 TabBar 高度
    /// - Parameter model: TabBar 高度模型
    public func st_customTabBarHeight(model: STConstantBarHeightModel) {
        self.barHeightModel.tabBarNormalHeight = model.tabBarNormalHeight
        self.barHeightModel.tabBarIsSafeHeight = model.tabBarIsSafeHeight
    }
    
    // MARK: - 比例计算
    /// 获取当前屏幕与设计基准的比例
    /// - Returns: 比例值，基于屏幕宽度计算
    public class func st_multiplier() -> CGFloat {
        let size = STDeviceAdapter.shared.benchmarkDesignSize
        if size == .zero {
            return 1.0
        }
        let screenWidth = UIScreen.main.bounds.width
        return screenWidth / size.width
    }
    
    /// 获取高度比例
    /// - Returns: 基于屏幕高度的比例值
    public class func st_heightMultiplier() -> CGFloat {
        let size = STDeviceAdapter.shared.benchmarkDesignSize
        if size == .zero {
            return 1.0
        }
        let screenHeight = UIScreen.main.bounds.height
        return screenHeight / size.height
    }
    
    /// 根据设计稿尺寸计算实际尺寸
    /// - Parameter float: 设计稿上的尺寸值
    /// - Returns: 适配后的实际尺寸
    public class func st_handleFloat(float: CGFloat) -> CGFloat {
        let multiplier = self.st_multiplier()
        let result = float * multiplier
        let scale = UIScreen.main.scale
        return (result * scale).rounded(.up) / scale
    }
    
    /// 根据设计稿尺寸计算实际尺寸（基于高度）
    /// - Parameter float: 设计稿上的尺寸值
    /// - Returns: 适配后的实际尺寸
    public class func st_handleHeightFloat(float: CGFloat) -> CGFloat {
        let multiplier = self.st_heightMultiplier()
        let result = float * multiplier
        let scale = UIScreen.main.scale
        return (result * scale).rounded(.up) / scale
    }
    
    // MARK: - 屏幕尺寸
    /// 获取屏幕宽度
    public class func st_appw() -> CGFloat {
        return UIScreen.main.bounds.size.width
    }
    
    /// 获取屏幕高度
    public class func st_apph() -> CGFloat {
        return UIScreen.main.bounds.size.height
    }
    
    /// 获取屏幕尺寸
    public class func st_screenSize() -> CGSize {
        return UIScreen.main.bounds.size
    }
    
    // MARK: - 设备判断
    /// 判断是否为刘海屏设备
    public class func st_isNotchScreen() -> Bool {
        if #available(iOS 11.0, *) {
            let window = UIApplication.shared.windows.first { $0.isKeyWindow }
            return window?.safeAreaInsets.top ?? 0 > 20
        }
        return self.st_apph() > 736
    }
    
    /// 判断是否为 iPad
    public class func st_isIPad() -> Bool {
        return UIDevice.current.userInterfaceIdiom == .pad
    }
    
    /// 获取设备类型
    public class func st_deviceType() -> STDeviceType {
        if st_isIPad() {
            return .iPad
        } else if st_isNotchScreen() {
            return .iPhone
        } else {
            return .unknown
        }
    }
    
    // MARK: - 导航栏高度
    /// 获取导航栏高度
    public class func st_navHeight() -> CGFloat {
        if self.st_isNotchScreen() {
            return STDeviceAdapter.shared.barHeightModel.navIsSafeHeight
        }
        return STDeviceAdapter.shared.barHeightModel.navNormalHeight
    }
    
    /// 获取 TabBar 高度
    public class func st_tabBarHeight() -> CGFloat {
        if self.st_isNotchScreen() {
            return STDeviceAdapter.shared.barHeightModel.tabBarIsSafeHeight
        }
        return STDeviceAdapter.shared.barHeightModel.tabBarNormalHeight
    }
    
    /// 获取安全区域高度
    public class func st_safeBarHeight() -> CGFloat {
        if #available(iOS 11.0, *) {
            let window = UIApplication.shared.windows.first { $0.isKeyWindow }
            return window?.safeAreaInsets.bottom ?? 0
        }
        return self.st_isNotchScreen() ? 34 : 0
    }
    
    /// 获取状态栏高度
    public class func st_statusBarHeight() -> CGFloat {
        if #available(iOS 13.0, *) {
            let window = UIApplication.shared.windows.first { $0.isKeyWindow }
            return window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0
        } else {
            return UIApplication.shared.statusBarFrame.height
        }
    }
    
    // MARK: - 实用方法
    /// 获取可用内容区域高度（屏幕高度 - 导航栏 - 状态栏）
    public class func st_contentHeight() -> CGFloat {
        return st_apph() - st_navHeight() - st_statusBarHeight()
    }
    
    /// 获取可用内容区域高度（屏幕高度 - 导航栏 - 状态栏 - TabBar）
    public class func st_contentHeightWithTabBar() -> CGFloat {
        return st_apph() - st_navHeight() - st_statusBarHeight() - st_tabBarHeight()
    }
    
    /// 判断是否为横屏
    public class func st_isLandscape() -> Bool {
        return UIDevice.current.orientation.isLandscape
    }
    
    /// 判断是否为竖屏
    public class func st_isPortrait() -> Bool {
        return UIDevice.current.orientation.isPortrait
    }
    
    /// 获取当前方向
    public class func st_orientation() -> UIDeviceOrientation {
        return UIDevice.current.orientation
    }
    
    // MARK: - 尺寸适配
    /// 根据设计稿尺寸适配宽度
    /// - Parameter width: 设计稿宽度
    /// - Returns: 适配后的宽度
    public class func st_adaptWidth(_ width: CGFloat) -> CGFloat {
        return st_handleFloat(float: width)
    }
    
    /// 根据设计稿尺寸适配高度
    /// - Parameter height: 设计稿高度
    /// - Returns: 适配后的高度
    public class func st_adaptHeight(_ height: CGFloat) -> CGFloat {
        return st_handleHeightFloat(float: height)
    }
    
    /// 根据设计稿尺寸适配字体大小
    /// - Parameter fontSize: 设计稿字体大小
    /// - Returns: 适配后的字体大小
    public class func st_adaptFontSize(_ fontSize: CGFloat) -> CGFloat {
        return st_handleFloat(float: fontSize)
    }
    
    /// 根据设计稿尺寸适配间距
    /// - Parameter spacing: 设计稿间距
    /// - Returns: 适配后的间距
    public class func st_adaptSpacing(_ spacing: CGFloat) -> CGFloat {
        return st_handleFloat(float: spacing)
    }
}
