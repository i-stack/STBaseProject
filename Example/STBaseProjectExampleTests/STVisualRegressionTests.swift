import XCTest
import STBaseProject
import STMarkdown
@testable import STBaseProjectExample

@MainActor
final class STVisualRegressionTests: XCTestCase {
    private let canvasSize = CGSize(width: 393, height: 852)

    func testAdaptiveComponentVisualEvidence() {
        let categories: [(name: String, value: UIContentSizeCategory)] = [
            ("standard", .large),
            ("accessibility", .accessibilityExtraExtraExtraLarge),
        ]

        for category in categories {
            let traits = UITraitCollection(preferredContentSizeCategory: category.value)
            traits.performAsCurrent {
                self.capture(
                    name: "HUD-\(category.name)",
                    view: self.makeHUDCanvas()
                )
                self.capture(
                    name: "TabBar-\(category.name)",
                    view: self.makeTabBarCanvas()
                )
                self.capture(
                    name: "WebError-\(category.name)",
                    view: self.makeWebErrorCanvas()
                )
                self.capture(
                    name: "Markdown-\(category.name)",
                    view: self.makeMarkdownCanvas(compatibleWith: traits)
                )
            }
        }
    }
}

private extension STVisualRegressionTests {
    func makeCanvas() -> UIView {
        let view = UIView(frame: CGRect(origin: .zero, size: self.canvasSize))
        view.backgroundColor = .systemBackground
        return view
    }

    func makeHUDCanvas() -> UIView {
        let canvas = self.makeCanvas()
        let hud = STProgressHUD.show(addedToView: canvas, animation: .none)
        hud.label.text = "正在同步数据"
        hud.detailsLabel.text = "Dynamic Type visual validation"
        hud.mode = .indeterminate
        canvas.layoutIfNeeded()
        return canvas
    }

    func makeTabBarCanvas() -> UIView {
        let canvas = self.makeCanvas()
        let tabBar = STCustomTabBar(frame: CGRect(x: 20, y: 740, width: 353, height: 72))
        tabBar.configure(
            items: [
                STTabBarItemModel(
                    title: "首页",
                    normalImage: UIImage(systemName: "house"),
                    selectedImage: UIImage(systemName: "house.fill")
                ),
                STTabBarItemModel(
                    title: "消息",
                    normalImage: UIImage(systemName: "message"),
                    selectedImage: UIImage(systemName: "message.fill"),
                    badge: STTabBarItemBadge(count: 8)
                ),
                STTabBarItemModel(
                    title: "我的",
                    normalImage: UIImage(systemName: "person"),
                    selectedImage: UIImage(systemName: "person.fill")
                ),
            ],
            config: STTabBarConfig()
        )
        canvas.addSubview(tabBar)
        canvas.layoutIfNeeded()
        return canvas
    }

    func makeWebErrorCanvas() -> UIView {
        let canvas = self.makeCanvas()
        let errorView = STBaseWKViewController().errorView
        errorView.isHidden = false
        errorView.frame = canvas.bounds.insetBy(dx: 24, dy: 120)
        canvas.addSubview(errorView)
        canvas.layoutIfNeeded()
        return canvas
    }

    func makeMarkdownCanvas(compatibleWith traits: UITraitCollection) -> UIView {
        let canvas = self.makeCanvas()
        let markdownView = STMarkdownTextView(
            style: STMarkdownPresets.article,
            advancedRenderers: STMarkdownPresets.makeDefaultAdvancedRenderers()
        )
        markdownView.frame = canvas.bounds.insetBy(dx: 20, dy: 48)
        markdownView.preferredContentWidth = markdownView.bounds.width
        markdownView.refreshDynamicType(compatibleWith: traits)
        markdownView.setMarkdown(
            """
            # Adaptive Typography

            正文会跟随系统字号重新排版，同时保留 **字重**、链接和列表语义。

            - HUD 与 TabBar
            - WebView 错误页
            - Markdown 富文本

            | Component | Status |
            | --- | --- |
            | Dynamic Type | Enabled |
            """
        )
        canvas.addSubview(markdownView)
        canvas.layoutIfNeeded()
        return canvas
    }

    func capture(name: String, view: UIView) {
        view.setNeedsLayout()
        view.layoutIfNeeded()
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let image = UIGraphicsImageRenderer(bounds: view.bounds, format: format).image { context in
            view.layer.render(in: context.cgContext)
        }

        XCTAssertEqual(image.size, self.canvasSize, name)
        XCTAssertNotNil(image.pngData(), name)
        let attachment = XCTAttachment(image: image)
        attachment.name = name
        attachment.lifetime = .keepAlways
        self.add(attachment)
    }
}
