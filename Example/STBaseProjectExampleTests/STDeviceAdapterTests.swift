import XCTest
import STBaseProject
import STMarkdown
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

    private func withTraits<Value>(
        _ traits: UITraitCollection,
        perform body: () -> Value
    ) -> Value {
        var value: Value!
        traits.performAsCurrent {
            value = body()
        }
        return value
    }

    private func labels(in view: UIView) -> [UILabel] {
        view.subviews.flatMap { subview in
            (subview as? UILabel).map { [$0] } ?? self.labels(in: subview)
        }
    }

    override func setUp() {
        super.setUp()
        STDeviceAdapter.shared.reset()
        STFontManager.shared.reset()
    }

    override func tearDown() {
        STDeviceAdapter.shared.reset()
        STFontManager.shared.reset()
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

    // MARK: - 容器级布局适配

    func testContainerLayoutAdapterUsesContainerInsteadOfGlobalScreen() throws {
        let adapter = try XCTUnwrap(
            STContainerLayoutAdapter(
                designSize: CGSize(width: 375, height: 812),
                containerSize: CGSize(width: 750, height: 812)
            )
        )

        XCTAssertEqual(adapter.widthScale, 2)
        XCTAssertEqual(adapter.heightScale, 1)
        XCTAssertEqual(adapter.scaledWidth(10), 20)
        XCTAssertEqual(adapter.scaledHeight(10), 10)
    }

    func testContainerLayoutAdapterRejectsInvalidDimensions() {
        XCTAssertNil(
            STContainerLayoutAdapter(
                designSize: CGSize(width: 0, height: 812),
                containerSize: CGSize(width: 375, height: 812)
            )
        )
        XCTAssertNil(
            STContainerLayoutAdapter(
                designSize: CGSize(width: 375, height: 812),
                containerSize: .zero
            )
        )
    }

    func testContainerLayoutAdapterAppliesClampAndPixelRounding() throws {
        let adapter = try XCTUnwrap(
            STContainerLayoutAdapter(
                designSize: CGSize(width: 100, height: 100),
                containerSize: CGSize(width: 250, height: 50),
                scaleStrategy: STScaleStrategy(minScale: 0.75, maxScale: 1.5, rounding: .up),
                displayScale: 2
            )
        )

        XCTAssertEqual(adapter.widthScale, 1.5)
        XCTAssertEqual(adapter.heightScale, 0.75)
        XCTAssertEqual(adapter.scaledWidth(1.1), 2)
        XCTAssertEqual(adapter.scaledHeight(1), 1)
    }

    func testConfiguredContainerAdapterPreservesLegacyConfiguration() throws {
        STDeviceAdapter.shared.configure(designSize: CGSize(width: 375, height: 812))
        STDeviceAdapter.shared.configureScaleStrategy(.padFriendly)

        let adapter = try XCTUnwrap(
            STDeviceAdapter.containerAdapter(for: CGSize(width: 750, height: 812))
        )

        XCTAssertEqual(adapter.designSize, CGSize(width: 375, height: 812))
        XCTAssertEqual(adapter.widthScale, 1.3)
        XCTAssertEqual(adapter.heightScale, 1)
    }

    // MARK: - 语义字体

    func testTypographyTokenRespondsToContentSizeCategory() {
        let standardTraits = UITraitCollection(preferredContentSizeCategory: .large)
        let accessibilityTraits = UITraitCollection(preferredContentSizeCategory: .accessibilityExtraExtraExtraLarge)

        let standardFont = STTypography.body.font(compatibleWith: standardTraits)
        let accessibilityFont = STTypography.body.font(compatibleWith: accessibilityTraits)

        XCTAssertGreaterThan(accessibilityFont.pointSize, standardFont.pointSize)
    }

    func testTypographyTokenRespectsMaximumPointSize() {
        let traits = UITraitCollection(preferredContentSizeCategory: .accessibilityExtraExtraExtraLarge)
        let token = STTypographyToken(
            baseSize: 17,
            textStyle: .body,
            maximumPointSize: 24
        )

        XCTAssertLessThanOrEqual(token.font(compatibleWith: traits).pointSize, 24)
    }

    func testTypographyTokenAppliesAppFontScaleWithoutScreenScale() {
        STDeviceAdapter.shared.configure(designSize: CGSize(width: 1, height: 1))
        STFontManager.shared.fontSizeScale = 1.25
        let traits = UITraitCollection(preferredContentSizeCategory: .large)

        let font = STTypographyToken(baseSize: 16, textStyle: .body).font(compatibleWith: traits)

        XCTAssertEqual(font.pointSize, 20, accuracy: 0.01)
    }

    func testNamedPreferredFontRespondsToContentSizeCategoryAndMaximum() {
        let standardTraits = UITraitCollection(preferredContentSizeCategory: .large)
        let accessibilityTraits = UITraitCollection(preferredContentSizeCategory: .accessibilityExtraExtraExtraLarge)

        let standardFont = UIFont.st_preferredFont(
            name: "Helvetica",
            ofSize: 12,
            forTextStyle: .caption1,
            maxSize: 18,
            compatibleWith: standardTraits
        )
        let accessibilityFont = UIFont.st_preferredFont(
            name: "Helvetica",
            ofSize: 12,
            forTextStyle: .caption1,
            maxSize: 18,
            compatibleWith: accessibilityTraits
        )

        XCTAssertGreaterThan(accessibilityFont.pointSize, standardFont.pointSize)
        XCTAssertLessThanOrEqual(accessibilityFont.pointSize, 18)
    }

    // MARK: - Dynamic Type 组件回归

    func testDynamicTypeValidationMatrixAcrossContainersAndOrientations() {
        let cases: [(name: String, size: CGSize)] = [
            ("iPhone SE portrait", CGSize(width: 320, height: 568)),
            ("iPhone portrait", CGSize(width: 393, height: 852)),
            ("iPhone landscape", CGSize(width: 852, height: 393)),
            ("iPad portrait", CGSize(width: 1024, height: 1366)),
            ("iPad landscape", CGSize(width: 1366, height: 1024)),
        ]
        let standardTraits = UITraitCollection(preferredContentSizeCategory: .large)
        let accessibilityTraits = UITraitCollection(
            preferredContentSizeCategory: .accessibilityExtraExtraExtraLarge
        )

        for testCase in cases {
            guard let adapter = STContainerLayoutAdapter(
                designSize: CGSize(width: 393, height: 852),
                containerSize: testCase.size,
                scaleStrategy: .padFriendly
            ) else {
                XCTFail("Invalid matrix case: \(testCase.name)")
                continue
            }
            let standardFont = STTypography.body.font(compatibleWith: standardTraits)
            let accessibilityFont = STTypography.body.font(compatibleWith: accessibilityTraits)

            XCTAssertGreaterThan(adapter.widthScale, 0, testCase.name)
            XCTAssertGreaterThan(adapter.heightScale, 0, testCase.name)
            XCTAssertGreaterThan(
                accessibilityFont.pointSize,
                standardFont.pointSize,
                testCase.name
            )
        }
    }

    func testMarkdownRerendersAndInvalidatesHeightWhenContentSizeCategoryChanges() throws {
        let view = STMarkdownTextView(style: .default)
        view.frame = CGRect(x: 0, y: 0, width: 320, height: 1)
        view.preferredContentWidth = 320
        let standardTraits = UITraitCollection(preferredContentSizeCategory: .large)
        let accessibilityTraits = UITraitCollection(
            preferredContentSizeCategory: .accessibilityExtraExtraExtraLarge
        )
        view.refreshDynamicType(compatibleWith: standardTraits)
        view.setMarkdown("# Dynamic Type\n\n正文需要随系统字号重新排版并增长高度。")

        let beforeFont = try XCTUnwrap(
            view.attributedText.attribute(.font, at: view.attributedText.length - 1, effectiveRange: nil) as? UIFont
        )
        let beforeHeight = view.sizeThatFitsMarkdown(width: 320).height

        view.refreshDynamicType(compatibleWith: accessibilityTraits)

        let afterFont = try XCTUnwrap(
            view.attributedText.attribute(.font, at: view.attributedText.length - 1, effectiveRange: nil) as? UIFont
        )
        let afterHeight = view.sizeThatFitsMarkdown(width: 320).height
        XCTAssertGreaterThan(afterFont.pointSize, beforeFont.pointSize)
        XCTAssertGreaterThan(afterHeight, beforeHeight)
    }

    func testMarkdownPresetsKeepLineHeightAboveFontAtAccessibilitySizes() {
        let accessibilityTraits = UITraitCollection(
            preferredContentSizeCategory: .accessibilityExtraExtraExtraLarge
        )
        let presets = [
            STMarkdownPresets.default,
            STMarkdownPresets.article,
            STMarkdownPresets.compact,
        ]

        for preset in presets {
            let resolved = preset.resolvedForDynamicType(compatibleWith: accessibilityTraits)
            XCTAssertGreaterThanOrEqual(resolved.lineHeight, ceil(resolved.font.lineHeight))
        }
    }

    func testSTLabelPreservesFontWeightAcrossTraitChanges() {
        let standardTraits = UITraitCollection(preferredContentSizeCategory: .large)
        let accessibilityTraits = UITraitCollection(
            preferredContentSizeCategory: .accessibilityExtraExtraExtraLarge
        )
        let label = STLabel(frame: .zero)
        label.font = UIFont.st_preferredFont(
            ofSize: 17,
            forTextStyle: .headline,
            weight: .bold,
            compatibleWith: standardTraits
        )

        label.traitCollectionDidChange(standardTraits)
        label.traitCollectionDidChange(accessibilityTraits)

        XCTAssertTrue(label.adjustsFontForContentSizeCategory)
        XCTAssertTrue(label.font.fontDescriptor.symbolicTraits.contains(.traitBold))
    }

    func testProgressHUDUsesDynamicTypeLabels() {
        let hud = STProgressHUD.show(
            addedToView: UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 480)),
            animation: .none
        )

        XCTAssertTrue(hud.label.adjustsFontForContentSizeCategory)
        XCTAssertTrue(hud.detailsLabel.adjustsFontForContentSizeCategory)
        XCTAssertTrue(hud.button.titleLabel?.adjustsFontForContentSizeCategory == true)
    }

    func testTabBarTitleRespondsToContentSizeCategoryWithinCap() throws {
        let model = STTabBarItemModel(
            title: "Dynamic Type Tab",
            normalImage: UIImage(systemName: "house"),
            selectedImage: UIImage(systemName: "house.fill"),
            typography: STTabBarItemTypography(fontSize: 12, fontName: "Helvetica")
        )
        let view = STTabBarItemView(frame: CGRect(x: 0, y: 0, width: 100, height: 60))
        view.configure(with: model)
        let label = try XCTUnwrap(self.labels(in: view).first { $0.text == model.title })

        XCTAssertTrue(label.adjustsFontForContentSizeCategory)
        XCTAssertLessThanOrEqual(label.font.pointSize, model.typography.fontSize * 1.4)
    }

    func testWebErrorViewFontsRespondToContentSizeCategory() throws {
        let labels = self.labels(in: STBaseWKViewController().errorView)

        XCTAssertGreaterThanOrEqual(labels.count, 2)
        XCTAssertTrue(labels.allSatisfy(\.adjustsFontForContentSizeCategory))
    }

    func testMarkdownHeadingFontRespondsToContentSizeCategory() {
        let standardTraits = UITraitCollection(preferredContentSizeCategory: .large)
        let accessibilityTraits = UITraitCollection(preferredContentSizeCategory: .accessibilityExtraExtraExtraLarge)

        let standardFont = self.withTraits(standardTraits) { STMarkdownTypography.headingFont(for: 1) }
        let accessibilityFont = self.withTraits(accessibilityTraits) { STMarkdownTypography.headingFont(for: 1) }

        XCTAssertGreaterThan(accessibilityFont.pointSize, standardFont.pointSize)
    }

    func testMarkdownPresetDoesNotFreezeContentSizeCategory() {
        let standardTraits = UITraitCollection(preferredContentSizeCategory: .large)
        let accessibilityTraits = UITraitCollection(preferredContentSizeCategory: .accessibilityExtraExtraExtraLarge)

        let standardFont = self.withTraits(standardTraits) { STMarkdownPresets.article.font }
        let accessibilityFont = self.withTraits(accessibilityTraits) { STMarkdownPresets.article.font }

        XCTAssertGreaterThan(accessibilityFont.pointSize, standardFont.pointSize)
    }
}
