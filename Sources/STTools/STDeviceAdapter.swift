//
//  STDeviceAdapter.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2019/03/16.
//

import UIKit
import Foundation

public struct STBarHeightsConfiguration {
    public var navigationBarRegularHeight: CGFloat = 64.0
    public var navigationBarSafeAreaHeight: CGFloat = 88.0
    public var tabBarRegularHeight: CGFloat = 49.0
    public var tabBarSafeAreaHeight: CGFloat = 83.0

    public init() {}

    public init(
        navigationBarRegularHeight: CGFloat = 64.0,
        navigationBarSafeAreaHeight: CGFloat = 88.0,
        tabBarRegularHeight: CGFloat = 49.0,
        tabBarSafeAreaHeight: CGFloat = 83.0
    ) {
        self.navigationBarRegularHeight = navigationBarRegularHeight
        self.navigationBarSafeAreaHeight = navigationBarSafeAreaHeight
        self.tabBarRegularHeight = tabBarRegularHeight
        self.tabBarSafeAreaHeight = tabBarSafeAreaHeight
    }
}

public final class STDeviceAdapter {
    
    public static let shared = STDeviceAdapter()
    public private(set) var designSize = CGSize.zero
    public private(set) var barHeights = STBarHeightsConfiguration()

    private init() {}

    public func configure(designSize: CGSize) {
        self.designSize = designSize
    }

    public func configureNavigationBar(regularHeight: CGFloat, safeAreaHeight: CGFloat) {
        self.barHeights.navigationBarRegularHeight = regularHeight
        self.barHeights.navigationBarSafeAreaHeight = safeAreaHeight
    }

    public func configureTabBar(regularHeight: CGFloat, safeAreaHeight: CGFloat) {
        self.barHeights.tabBarRegularHeight = regularHeight
        self.barHeights.tabBarSafeAreaHeight = safeAreaHeight
    }

    public func applyBarHeights(_ configuration: STBarHeightsConfiguration) {
        self.barHeights = configuration
    }

    public static var widthScale: CGFloat {
        let designSize = shared.designSize
        guard designSize != .zero else { return 1.0 }
        return screenWidth / designSize.width
    }

    public static var heightScale: CGFloat {
        let designSize = shared.designSize
        guard designSize != .zero else { return 1.0 }
        return screenHeight / designSize.height
    }

    public static func scaledValue(_ value: CGFloat) -> CGFloat {
        self.scaled(value, multiplier: widthScale)
    }

    public static func scaledHeightValue(_ value: CGFloat) -> CGFloat {
        self.scaled(value, multiplier: heightScale)
    }

    public static func scaledWidth(_ value: CGFloat) -> CGFloat {
        self.scaledValue(value)
    }

    public static func scaledHeight(_ value: CGFloat) -> CGFloat {
        self.scaledHeightValue(value)
    }

    public static func scaledFontSize(_ value: CGFloat) -> CGFloat {
        self.scaledValue(value)
    }

    public static func scaledSpacing(_ value: CGFloat) -> CGFloat {
        self.scaledValue(value)
    }

    public static var screenWidth: CGFloat {
        UIScreen.main.bounds.width
    }

    public static var screenHeight: CGFloat {
        UIScreen.main.bounds.height
    }

    public static var screenSize: CGSize {
        UIScreen.main.bounds.size
    }

    public static var safeAreaInsets: UIEdgeInsets {
        self.currentKeyWindow?.safeAreaInsets ?? .zero
    }

    public static var isNotchScreen: Bool {
        UIDevice.current.userInterfaceIdiom == .phone && safeAreaInsets.top > 20
    }

    public static var navigationBarHeight: CGFloat {
        self.isNotchScreen
        ? self.shared.barHeights.navigationBarSafeAreaHeight
        : self.shared.barHeights.navigationBarRegularHeight
    }

    public static var tabBarHeight: CGFloat {
        self.isNotchScreen
        ? self.shared.barHeights.tabBarSafeAreaHeight
        : self.shared.barHeights.tabBarRegularHeight
    }

    public static var bottomSafeAreaHeight: CGFloat {
        self.safeAreaInsets.bottom
    }

    public static var safeTabBarHeight: CGFloat {
        self.tabBarHeight + self.bottomSafeAreaHeight
    }

    public static var statusBarHeight: CGFloat {
        self.currentKeyWindow?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0
    }

    public static var contentHeight: CGFloat {
        self.screenHeight - self.navigationBarHeight - self.statusBarHeight
    }

    public static var contentHeightWithTabBar: CGFloat {
        self.screenHeight - self.navigationBarHeight - self.statusBarHeight - self.tabBarHeight
    }

    public static var isLandscape: Bool {
        UIDevice.current.orientation.isLandscape
    }

    public static var isPortrait: Bool {
        UIDevice.current.orientation.isPortrait
    }

    public static var orientation: UIDeviceOrientation {
        UIDevice.current.orientation
    }

    private static var currentKeyWindow: UIWindow? {
        if #available(iOS 13.0, *) {
            return UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap(\.windows)
                .first(where: \.isKeyWindow)
        } else {
            return UIApplication.shared.keyWindow
        }
    }

    private static func scaled(_ value: CGFloat, multiplier: CGFloat) -> CGFloat {
        let result = value * multiplier
        let scale = UIScreen.main.scale
        return (result * scale).rounded(.up) / scale
    }
}
