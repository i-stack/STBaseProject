import Testing
import XCTest
@testable import STBaseProjectExample
import STBaseProject

@MainActor
struct STBaseViewControllerNavigationTests {

    // MARK: - Helpers

    /// 赋予确定尺寸并强制布局，避免读取到未布局的零 frame
    private func layout(_ vc: STBaseViewController) {
        vc.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        vc.view.layoutIfNeeded()
    }

    // MARK: - P1: 展示前配置 .none 必须真正折叠占位高度

    @Test func noneBeforeViewLoadCollapsesBarHeight() {
        let vc = STBaseViewController()
        // 视图尚未加载时配置 .none（此时高度约束尚未创建）
        vc.st_showNavBtnType(type: .none)
        vc.loadViewIfNeeded()
        self.layout(vc)

        #expect(vc.navigationBarView.isHidden == true)
        #expect(vc.navigationBarItemsView.isHidden == true)
        // 占位高度被折叠为 0，内容区顶部不应残留死区
        #expect(vc.navigationBarItemsView.frame.height == 0)
    }

    @Test func defaultKeepsBarHeight() {
        let vc = STBaseViewController()
        vc.loadViewIfNeeded()
        self.layout(vc)
        #expect(vc.navigationBarItemsView.frame.height == STDeviceAdapter.navigationBarContentHeight)
    }

    // MARK: - P2: 无障碍兜底文案（通过公开语言切换 API 驱动真实通知链路）

    @Test func imageOnlyFallsBackToChineseWhenChinese() {
        let vc = STBaseViewController()
        vc.loadViewIfNeeded()   // 触发 viewDidLoad，注册 stLanguageDidChange 观察者
        vc.st_setLeftBtn(image: UIImage())

        Bundle.st_setCustomLanguage("zh-Hans")
        #expect(vc.leftBtn.accessibilityLabel == "返回")

        Bundle.st_clearCustomLanguage()
    }

    @Test func imageOnlyFallsBackToEnglishWhenEnglish() {
        let vc = STBaseViewController()
        vc.loadViewIfNeeded()
        vc.st_setLeftBtn(image: UIImage())

        Bundle.st_setCustomLanguage("en")
        #expect(vc.leftBtn.accessibilityLabel == "Back")

        Bundle.st_clearCustomLanguage()
    }

    /// 语言切换后兜底文案应随之刷新（覆盖 stLanguageDidChange → st_updateLocalizedTexts 生产路径）
    @Test func accessibilityFallbackRefreshesOnLanguageChange() {
        let vc = STBaseViewController()
        vc.loadViewIfNeeded()
        vc.st_setLeftBtn(image: UIImage())
        vc.st_setRightBtn(image: UIImage())

        Bundle.st_setCustomLanguage("zh-Hans")
        #expect(vc.leftBtn.accessibilityLabel == "返回")
        #expect(vc.rightBtn.accessibilityLabel == "更多")

        Bundle.st_setCustomLanguage("en")
        #expect(vc.leftBtn.accessibilityLabel == "Back")
        #expect(vc.rightBtn.accessibilityLabel == "More")

        Bundle.st_clearCustomLanguage()
    }

    /// 顺序依赖修复验证：图片 + 文案同传时，读出的是文案而非兜底
    @Test func imageAndTitleUsesTitleNotFallback() {
        let vc = STBaseViewController()
        vc.loadViewIfNeeded()
        vc.st_setLeftBtn(image: UIImage(), title: "关闭")
        #expect(vc.leftBtn.accessibilityLabel == "关闭")
    }

    /// 调用方显式传入 accessibilityLabel 具有最高优先级
    @Test func explicitAccessibilityLabelWins() {
        let vc = STBaseViewController()
        vc.loadViewIfNeeded()
        vc.st_setLeftBtn(image: UIImage(), title: "关闭", accessibilityLabel: "关闭弹窗")
        #expect(vc.leftBtn.accessibilityLabel == "关闭弹窗")
    }
}
