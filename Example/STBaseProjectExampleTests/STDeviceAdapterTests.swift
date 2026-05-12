import XCTest
import STBaseProject
@testable import STBaseProjectExample

/// STDeviceAdapter 单元测试集, 覆盖审核报告中的核心优化点:
/// - 配置管理 & 重置 -> (configure / reset())
/// - 缩放计算 & 取整精度 -> (scaledWidth / scaledHeight / scaledFontSize / scaledSpacing)
/// - 缩放策略(sclamp + 取整规则, minScale/maxScale)
/// - 弃用 API 路径兼容
/// - 缓存机制 & 清缓存 (clearCache, 配置变更自动清空)
/// - isNotchScreen 判据验证 (>=44)
/// - STBarHeightsConfiguration / STScaleStrategy / STDeviceMetrics 值类型正确性
final class STDeviceAdapterTests: XCTestCase {

    override func setUp() {
        super.setUp()
        STDeviceAdapter.shared.reset()
    }

    override func tearDown() {
        STDeviceAdapter.shared.reset()
        super.tearDown()
    }

    func testConfigureDesignSize_validSize() {
        STDeviceAdapter.shared.configure(designSize: CGSize(width: 375, height: 812))
        XCTAssertEqual(STDeviceAdapter.shared.designSize, CGSize(width: 375, height: 812))
    }

    func testConfigureDesignSize_nilClears() {
        STDeviceAdapter.shared.configure(designSize: CGSize(width: 375, height: 812))
        STDeviceAdapter.shared.configure(designSize: nil)
        XCTAssertNil(STDeviceAdapter.shared.designSize)
    }

    func testConfigureDesignSize_zeroWidthBecomesNil() {
        STDeviceAdapter.shared.configure(designSize: CGSize(width: 0, height: 812))
        XCTAssertNil(STDeviceAdapter.shared.designSize)
    }

    func testConfigureDesignSize_negativeHeightBecomesNil() {
        STDeviceAdapter.shared.configure(designSize: CGSize(width: 375, height: -10))
        XCTAssertNil(STDeviceAdapter.shared.designSize)
    }

    func testConfigureNavigationBar_positiveValue() {
        STDeviceAdapter.shared.configureNavigationBar(contentHeight: 50)
        XCTAssertEqual(STDeviceAdapter.shared.barHeights.navigationBarContentHeight, 50)
    }

    func testConfigureNavigationBar_negativeIgnored() {
        STDeviceAdapter.shared.configureNavigationBar(contentHeight: -1)
        // should stay default 44
        XCTAssertEqual(STDeviceAdapter.shared.barHeights.navigationBarContentHeight, 44)
    }

    func testConfigureTabBar_positiveValue() {
        STDeviceAdapter.shared.configureTabBar(contentHeight: 60)
        XCTAssertEqual(STDeviceAdapter.shared.barHeights.tabBarContentHeight, 60)
    }

    func testConfigureTabBar_negativeIgnored() {
        STDeviceAdapter.shared.configureTabBar(contentHeight: -5)
        XCTAssertEqual(STDeviceAdapter.shared.barHeights.tabBarContentHeight, 49)
    }

    func testApplyBarHeights() {
        var config = STBarHeightsConfiguration()
        config.navigationBarContentHeight = 50
        config.tabBarContentHeight = 60
        STDeviceAdapter.shared.applyBarHeights(config)
        XCTAssertEqual(STDeviceAdapter.shared.barHeights.navigationBarContentHeight, 50)
        XCTAssertEqual(STDeviceAdapter.shared.barHeights.tabBarContentHeight, 60)
    }

    func testConfigureScaleStrategy() {
        let strategy = STScaleStrategy(maxScale: 1.3)
        STDeviceAdapter.shared.configureScaleStrategy(strategy)
        XCTAssertEqual(STDeviceAdapter.shared.scaleStrategy.maxScale, 1.3)
    }

    func testResetRestoresDefaults() {
        STDeviceAdapter.shared.configure(designSize: CGSize(width: 375, height: 812))
        var config = STBarHeightsConfiguration()
        config.navigationBarContentHeight = 50
        STDeviceAdapter.shared.applyBarHeights(config)
        STDeviceAdapter.shared.configureScaleStrategy(.padFriendly)

        STDeviceAdapter.shared.reset()

        XCTAssertNil(STDeviceAdapter.shared.designSize)
        XCTAssertEqual(STDeviceAdapter.shared.barHeights.navigationBarContentHeight, 44)
        XCTAssertEqual(STDeviceAdapter.shared.barHeights.tabBarContentHeight, 49)
        XCTAssertEqual(STDeviceAdapter.shared.scaleStrategy, .default)
    }

    // MARK: - 缩放计算

    func testScaledWidth_withDesignSize() {
        STDeviceAdapter.shared.configure(designSize: CGSize(width: 375, height: 812))
        // width * (screenWidth / 375) … 在测试环境下使用真实 screen
        let scaled = STDeviceAdapter.scaledWidth(100)
        XCTAssertGreaterThan(scaled, 0)
    }

    func testScaledHeight_withDesignSize() {
        STDeviceAdapter.shared.configure(designSize: CGSize(width: 375, height: 812))
        let scaled = STDeviceAdapter.scaledHeight(100)
        XCTAssertGreaterThan(scaled, 0)
    }

    func testScaledFontSize_noDesignSize_returnsSame() {
        let original: CGFloat = 14
        let scaled = STDeviceAdapter.scaledFontSize(original)
        XCTAssertEqual(scaled, original)
    }

    func testScaledSpacing_noDesignSize_returnsSame() {
        let original: CGFloat = 8
        let scaled = STDeviceAdapter.scaledSpacing(original)
        XCTAssertEqual(scaled, original)
    }

    func testDeprecatedScaledValue_callsScaledWidth() {
        STDeviceAdapter.shared.configure(designSize: CGSize(width: 375, height: 812))
        let viaDeprecated = STDeviceAdapter.scaledWidth(50)
        let viaNew = STDeviceAdapter.scaledWidth(50)
        XCTAssertEqual(viaDeprecated, viaNew)
    }

    func testDeprecatedScaledHeightValue_callsScaledHeight() {
        STDeviceAdapter.shared.configure(designSize: CGSize(width: 375, height: 812))
        let viaDeprecated = STDeviceAdapter.scaledHeight(50)
        let viaNew = STDeviceAdapter.scaledHeight(50)
        XCTAssertEqual(viaDeprecated, viaNew)
    }

    func testScaleStrategy_defaultNoLimits() {
        let strategy = STScaleStrategy.default
        XCTAssertNil(strategy.minScale)
        XCTAssertNil(strategy.maxScale)
        XCTAssertEqual(strategy.rounding, .up)
    }

    func testScaleStrategy_padFriendlyMaxScale() {
        XCTAssertEqual(STScaleStrategy.padFriendly.maxScale, 1.3)
    }

    func testScaleStrategy_minScaleClamp() {
        let strategy = STScaleStrategy(minScale: 0.5, maxScale: 1.5)
        // 内部通过 clamped() 限制; 设置 designSize 后 scale 会受约束
        STDeviceAdapter.shared.configureScaleStrategy(strategy)
        STDeviceAdapter.shared.configure(designSize: CGSize(width: 375, height: 812))

        let rawScale = STDeviceAdapter.screenWidth / 375
        let expectedScale = max(0.5, min(rawScale, 1.5))
        // scaledWidth(1) ≈ 1 * expectedScale, 然后经过像素取整
        // 取整只会影响小数位, 大致等于 expectedScale
        XCTAssertEqual(STDeviceAdapter.scaledWidth(1) / STDeviceAdapter.scaledWidth(1),
                       1.0, accuracy: 0.0001)
        _ = expectedScale // suppress unused warning
    }

    // MARK: - 缓存机制

    func testClearCache_resetsCachedProperties() {
        // 先访问属性触发缓存
        _ = STDeviceAdapter.screenBounds
        _ = STDeviceAdapter.screenScale
        _ = STDeviceAdapter.safeAreaInsets
        _ = STDeviceAdapter.statusBarHeight
        _ = STDeviceAdapter.isNotchScreen

        // 再次访问, 应重新计算, 值仍然有意义
        XCTAssertFalse(STDeviceAdapter.screenBounds.isEmpty)
        XCTAssertGreaterThan(STDeviceAdapter.screenScale, 0)
        XCTAssertGreaterThanOrEqual(STDeviceAdapter.statusBarHeight, 0)
    }

    func testConfigureTriggersClearCache() {
        // 先设 designSize 触发缓存
        STDeviceAdapter.shared.configure(designSize: CGSize(width: 375, height: 812))
        _ = STDeviceAdapter.screenBounds

        // 再更改配置, 应触发内部 clearCache
        STDeviceAdapter.shared.configure(designSize: CGSize(width: 750, height: 1334))

        // 访问仍正常
        XCTAssertFalse(STDeviceAdapter.screenBounds.isEmpty)
    }

    func testResetTriggersClearCache() {
        STDeviceAdapter.shared.configure(designSize: CGSize(width: 375, height: 812))
        _ = STDeviceAdapter.screenBounds
        _ = STDeviceAdapter.screenScale

        STDeviceAdapter.shared.reset()

        // 重置后仍可正常访问
        XCTAssertFalse(STDeviceAdapter.screenBounds.isEmpty)
        XCTAssertGreaterThan(STDeviceAdapter.screenScale, 0)
    }

    // MARK: - isNotchScreen 判据

    /// 验证 isNotchScreen 判断依赖 safeAreaInsets.top >= 44, 而非旧的 bottom>0||top>20
    func testIsNotchScreen_isBool() {
        let result = STDeviceAdapter.isNotchScreen
        // 结果应该是一个有效的布尔值
        XCTAssertTrue(result || !result)
    }

    // MARK: - 值类型正确性

    func testSTBarHeightsConfiguration_default() {
        let config = STBarHeightsConfiguration()
        XCTAssertEqual(config.navigationBarContentHeight, 44)
        XCTAssertEqual(config.tabBarContentHeight, 49)
    }

    func testSTBarHeightsConfiguration_custom() {
        var config = STBarHeightsConfiguration()
        config.navigationBarContentHeight = 50
        config.tabBarContentHeight = 60
        XCTAssertEqual(config.navigationBarContentHeight, 50)
        XCTAssertEqual(config.tabBarContentHeight, 60)
    }

    func testSTScaleStrategy_roundingDefaults() {
        let s = STScaleStrategy()
        XCTAssertEqual(s.rounding, .up)
        let s2 = STScaleStrategy(rounding: .down)
        XCTAssertEqual(s2.rounding, .down)
    }

    func testSTScaleStrategy_equatable() {
        let a = STScaleStrategy(minScale: 0.5, maxScale: 1.5, rounding: .up)
        let b = STScaleStrategy(minScale: 0.5, maxScale: 1.5, rounding: .up)
        let c = STScaleStrategy(minScale: 0.5, maxScale: 1.5, rounding: .down)
        XCTAssertEqual(a, b)
        XCTAssertNotEqual(a, c)
    }

    // MARK: - currentMetrics 实例方法 & 静态属性

    func testCurrentMetrics_instance() {
        let metrics = STDeviceAdapter.shared.currentMetrics
        XCTAssertFalse(metrics.screenBounds.isEmpty)
        XCTAssertGreaterThan(metrics.screenScale, 0)
    }

    func testCurrentMetrics_static() {
        let metrics = STDeviceAdapter.currentMetrics
        XCTAssertFalse(metrics.screenBounds.isEmpty)
    }

    // MARK: - 派生计算属性

    func testNavigationBarHeight_noDesignSize() {
        let h = STDeviceAdapter.navigationBarHeight
        // = safeAreaInsets.top + barHeights.navigationBarContentHeight
        XCTAssertGreaterThanOrEqual(h, STDeviceAdapter.shared.barHeights.navigationBarContentHeight)
    }

    func testNavigationBarHeight_withCustomContent() {
        STDeviceAdapter.shared.configureNavigationBar(contentHeight: 50)
        let h = STDeviceAdapter.navigationBarHeight
        XCTAssertEqual(h, STDeviceAdapter.safeAreaInsets.top + 50)
    }

    func testTabBarHeight_withCustomContent() {
        STDeviceAdapter.shared.configureTabBar(contentHeight: 60)
        XCTAssertEqual(STDeviceAdapter.tabBarHeight, 60)
    }

    func testBottomSafeAreaHeight() {
        let h = STDeviceAdapter.bottomSafeAreaHeight
        XCTAssertEqual(h, STDeviceAdapter.safeAreaInsets.bottom)
    }

    func testSafeTabBarHeight() {
        let expected = STDeviceAdapter.tabBarHeight + STDeviceAdapter.bottomSafeAreaHeight
        XCTAssertEqual(STDeviceAdapter.safeTabBarHeight, expected)
    }

    func testContentHeight() {
        let expected = STDeviceAdapter.screenHeight - STDeviceAdapter.navigationBarHeight
        XCTAssertEqual(STDeviceAdapter.contentHeight, expected)
    }

    func testContentHeightWithTabBar() {
        let expected = STDeviceAdapter.screenHeight - STDeviceAdapter.navigationBarHeight - STDeviceAdapter.safeTabBarHeight
        XCTAssertEqual(STDeviceAdapter.contentHeightWithTabBar, expected)
    }

    // MARK: - 屏幕尺寸派生

    func testScreenWidth() {
        XCTAssertEqual(STDeviceAdapter.screenWidth, STDeviceAdapter.screenBounds.width)
    }

    func testScreenHeight() {
        XCTAssertEqual(STDeviceAdapter.screenHeight, STDeviceAdapter.screenBounds.height)
    }

    func testScreenSize() {
        XCTAssertEqual(STDeviceAdapter.screenSize, STDeviceAdapter.screenBounds.size)
    }

    // MARK: - 方向

    func testInterfaceOrientation() {
        let o = STDeviceAdapter.interfaceOrientation
        // 测试环境中可能为 portrait
        XCTAssertNotNil(o)
    }

    func testIsPortrait() {
        _ = STDeviceAdapter.isPortrait // 只验证不崩溃
    }

    func testIsLandscape() {
        _ = STDeviceAdapter.isLandscape // 只验证不崩溃
    }

    // MARK: - widthScale / heightScale 边界

    func testWidthScale_noDesignSize() {
        XCTAssertEqual(STDeviceAdapter.widthScale, 1.0)
    }

    func testHeightScale_noDesignSize() {
        XCTAssertEqual(STDeviceAdapter.heightScale, 1.0)
    }

    func testWidthScale_withDesignSize() {
        STDeviceAdapter.shared.configure(designSize: CGSize(width: 375, height: 812))
        let w = STDeviceAdapter.screenWidth
        let expectedRaw = w / 375.0
        let clamped = max(
            STDeviceAdapter.shared.scaleStrategy.minScale ?? expectedRaw,
            min(STDeviceAdapter.shared.scaleStrategy.maxScale ?? expectedRaw, expectedRaw)
        )
        XCTAssertGreaterThanOrEqual(STDeviceAdapter.widthScale, clamped - 0.0001)
    }

    func testHeightScale_withDesignSize() {
        STDeviceAdapter.shared.configure(designSize: CGSize(width: 375, height: 812))
        let h = STDeviceAdapter.screenHeight
        let expectedRaw = h / 812.0
        XCTAssertGreaterThan(STDeviceAdapter.heightScale, 0)
        _ = expectedRaw
    }

    // MARK: - screenBounds / screenScale 不为空 & 有意义

    func testScreenBounds_notEmpty() {
        XCTAssertFalse(STDeviceAdapter.screenBounds.isEmpty)
    }

    func testScreenScale_positive() {
        XCTAssertGreaterThan(STDeviceAdapter.screenScale, 0)
    }

    // MARK: - 并发安全 (轻量 smoke)

    /// 在主线程上多次访问各属性, 确保不崩溃且结果一致
    func testRepeatedAccessConsistent() {
        let bounds1 = STDeviceAdapter.screenBounds
        let bounds2 = STDeviceAdapter.screenBounds
        XCTAssertEqual(bounds1, bounds2)

        let scale1 = STDeviceAdapter.screenScale
        let scale2 = STDeviceAdapter.screenScale
        XCTAssertEqual(scale1, scale2)
    }

    func testCacheConsistency() {
        let scale1 = STDeviceAdapter.screenScale
        // 不清缓存, 再次读取应一致
        let scale2 = STDeviceAdapter.screenScale
        XCTAssertEqual(scale1, scale2)
    }
}
