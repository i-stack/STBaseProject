import XCTest
import UIKit
import STBaseProject

@MainActor
final class STBaseViewTests: XCTestCase {

    func testConfigureScrollDirectionReplacesDimensionConstraintsAndBounceBehavior() {
        let view = STBaseView(frame: CGRect(x: 0, y: 0, width: 300, height: 400))

        view.configure(layoutMode: .scroll, scrollDirection: .horizontal)
        XCTAssertTrue(view.scrollView.alwaysBounceHorizontal)
        XCTAssertFalse(view.scrollView.alwaysBounceVertical)
        XCTAssertTrue(view.scrollView.showsHorizontalScrollIndicator)
        XCTAssertFalse(view.scrollView.showsVerticalScrollIndicator)
        XCTAssertTrue(Self.hasActiveDimensionConstraint(in: view, attribute: .height))

        view.configure(layoutMode: .scroll, scrollDirection: .vertical)
        XCTAssertTrue(view.scrollView.alwaysBounceVertical)
        XCTAssertFalse(view.scrollView.alwaysBounceHorizontal)
        XCTAssertTrue(view.scrollView.showsVerticalScrollIndicator)
        XCTAssertFalse(view.scrollView.showsHorizontalScrollIndicator)
        XCTAssertTrue(Self.hasActiveDimensionConstraint(in: view, attribute: .width))
        XCTAssertFalse(Self.hasActiveDimensionConstraint(in: view, attribute: .height))
    }

    func testContentContainerFollowsLayoutMode() throws {
        let view = STBaseView(frame: CGRect(x: 0, y: 0, width: 300, height: 400))

        view.configure(layoutMode: .fixed)
        XCTAssertTrue(view.contentContainer() === view.contentView)

        view.configure(layoutMode: .table)
        let tableView = try XCTUnwrap(view.st_getTableView())
        XCTAssertTrue(view.contentContainer() === tableView)
        XCTAssertNil(view.st_getCollectionView())

        view.configure(layoutMode: .collection)
        let collectionView = try XCTUnwrap(view.st_getCollectionView())
        XCTAssertTrue(view.contentContainer() === collectionView)
        XCTAssertNil(view.st_getTableView())

        view.configure(layoutMode: .scroll)
        XCTAssertTrue(view.contentContainer() === view.contentView)
    }

    func testAddContentSubviewInstallsBottomConstraint() {
        let view = STBaseView(frame: CGRect(x: 0, y: 0, width: 300, height: 400))
        view.configure(layoutMode: .scroll)
        let child = UIView()
        view.st_addContentSubview(child)
        view.st_setBottomConstraintForLastSubview(child, offset: -12)

        let bottom = view.contentView.constraints.first {
            ($0.firstItem as? UIView) === child &&
            $0.firstAttribute == .bottom &&
            ($0.secondItem as? UIView) === view.contentView &&
            $0.constant == -12 &&
            $0.isActive
        }
        XCTAssertNotNil(bottom)
    }

    func testStatePagesAreMutuallyExclusiveAndCanBeHidden() {
        let view = STBaseView(frame: CGRect(x: 0, y: 0, width: 300, height: 400))

        view.st_showLoading("加载中")
        XCTAssertEqual(Self.labelTexts(in: view), ["加载中"])

        view.st_showEmpty("暂无数据")
        XCTAssertEqual(Self.labelTexts(in: view), ["暂无数据"])

        view.st_showError("出错了")
        XCTAssertEqual(Self.labelTexts(in: view), ["出错了"])

        view.st_showLoading()
        XCTAssertEqual(Self.labelTexts(in: view), [STStatePageDefaults.loadingText])

        view.st_hideAllStates()
        XCTAssertTrue(Self.labelTexts(in: view).isEmpty)
    }

    func testAddSectionMaintainsChainAndAppliesInsetChanges() {
        let view = STBaseView(frame: CGRect(x: 0, y: 0, width: 300, height: 400))
        view.configure(layoutMode: .scroll)
        let first = STSection(inset: UIEdgeInsets(top: 1, left: 2, bottom: 3, right: 4), spacing: 5)
        let second = STSection()

        view.st_addSection(first)
        view.st_addSection(second, interSectionSpacing: 12)

        XCTAssertTrue(first.superview === view.contentView)
        XCTAssertTrue(second.superview === view.contentView)
        let topConstraint = Self.constraint(
            in: [view.contentView],
            first: second,
            firstAttribute: .top,
            second: first,
            secondAttribute: .bottom
        )
        XCTAssertEqual(topConstraint?.constant, 12)
        XCTAssertEqual(topConstraint?.isActive, true)

        first.inset = UIEdgeInsets(top: 10, left: 20, bottom: 30, right: 40)
        first.spacing = 16
        XCTAssertEqual(first.constraints.first { $0.firstAttribute == .top }?.constant, 10)
        XCTAssertEqual(first.constraints.first { $0.firstAttribute == .leading }?.constant, 20)
        XCTAssertEqual(first.constraints.first { $0.firstAttribute == .trailing }?.constant, -40)
        XCTAssertEqual(first.constraints.first { $0.firstAttribute == .bottom }?.constant, -30)
        XCTAssertEqual((first.subviews.first as? UIStackView)?.spacing, 16)
    }

    func testGradientNavigationBarUpdatesIntrinsicHeightAndColors() {
        let bar = STGradientNavigationBar()
        XCTAssertEqual(bar.intrinsicContentSize.height, 88)

        bar.height = 100
        bar.startColor = .red
        bar.endColor = .blue
        XCTAssertEqual(bar.intrinsicContentSize.height, 100)

        let layer = bar.layer.sublayers?.compactMap { $0 as? CAGradientLayer }.first
        let colors = layer?.colors as? [CGColor]
        XCTAssertEqual(colors?.count, 2)
        if let colors, colors.count == 2 {
            XCTAssertEqual(UIColor(cgColor: colors[0]), .red)
            XCTAssertEqual(UIColor(cgColor: colors[1]), .blue)
        }
    }

    func testRefreshHeaderBeginAndEndRefreshingRestoresInset() {
        let scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: 300, height: 400))
        let header = STRefreshHeaderView(content: .animation)
        var actionCount = 0
        header.attach(to: scrollView) { actionCount += 1 }
        let baseTop = scrollView.contentInset.top

        Self.performWithoutAnimations {
            header.beginRefreshing()
        }
        XCTAssertEqual(actionCount, 1)
        XCTAssertEqual(header.injectedInsetTop, 60)
        XCTAssertEqual(scrollView.contentInset.top, baseTop + 60, accuracy: 0.001)

        Self.performWithoutAnimations {
            header.endRefreshing()
        }
        RunLoop.main.run(until: Date().addingTimeInterval(0.01))
        XCTAssertEqual(header.injectedInsetTop, 0)
        XCTAssertEqual(scrollView.contentInset.top, baseTop, accuracy: 0.001)
    }

    func testLoadMoreFooterExhaustedAndResetStates() {
        let scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: 300, height: 400))
        let footer = STLoadMoreFooterView(content: .text(loading: "加载中", noMore: "没有更多"))
        footer.attach(to: scrollView) { }
        let baseBottom = scrollView.contentInset.bottom
        XCTAssertEqual(footer.injectedInsetBottom, 0)

        footer.endLoading(paging: .exhausted)
        XCTAssertEqual(footer.injectedInsetBottom, 44)
        XCTAssertEqual(scrollView.contentInset.bottom, baseBottom + 44, accuracy: 0.001)
        XCTAssertTrue(Self.labelTexts(in: footer).contains("没有更多"))

        footer.resetToIdle()
        XCTAssertEqual(footer.injectedInsetBottom, 0)
        XCTAssertEqual(scrollView.contentInset.bottom, baseBottom, accuracy: 0.001)
        XCTAssertTrue(Self.labelTexts(in: footer).contains("加载中"))
    }

    func testBaseViewRefreshFacadeUsesCurrentScrollView() {
        let view = STBaseView(frame: CGRect(x: 0, y: 0, width: 300, height: 400))
        view.configure(layoutMode: .scroll)
        var actionCount = 0
        view.st_addPullToRefresh(content: .animation) { actionCount += 1 }

        Self.performWithoutAnimations {
            view.st_beginRefreshing()
        }
        XCTAssertEqual(actionCount, 1)
        XCTAssertEqual(view.scrollView.contentInset.top, 60, accuracy: 0.001)

        Self.performWithoutAnimations {
            view.st_endRefreshing()
        }
        XCTAssertEqual(view.scrollView.contentInset.top, 0, accuracy: 0.001)

        view.st_removePullToRefresh()
        view.st_beginRefreshing()
        XCTAssertEqual(actionCount, 1)
    }

    func testKeyboardAdjustmentUpdatesRestoresAndDisablesInsets() {
        let view = STBaseView(frame: CGRect(x: 0, y: 0, width: 300, height: 400))
        view.configure(layoutMode: .scroll)
        let keyboardFrame = CGRect(x: 0, y: 300, width: 300, height: 100)

        Self.performWithoutAnimations {
            Self.postKeyboardNotification(UIResponder.keyboardWillShowNotification, frame: keyboardFrame)
            XCTAssertEqual(view.scrollView.contentInset.bottom, 100, accuracy: 0.001)

            Self.postKeyboardNotification(UIResponder.keyboardWillHideNotification, frame: keyboardFrame)
            XCTAssertEqual(view.scrollView.contentInset.bottom, 0, accuracy: 0.001)

            view.enableScrollViewKeyboardAdjustment = false
            Self.postKeyboardNotification(UIResponder.keyboardWillShowNotification, frame: keyboardFrame)
            XCTAssertEqual(view.scrollView.contentInset.bottom, 0, accuracy: 0.001)
        }
    }

    func testLeavingScrollModeRestoresKeyboardInset() {
        let view = STBaseView(frame: CGRect(x: 0, y: 0, width: 300, height: 400))
        view.configure(layoutMode: .scroll)
        let keyboardFrame = CGRect(x: 0, y: 300, width: 300, height: 100)

        Self.performWithoutAnimations {
            Self.postKeyboardNotification(UIResponder.keyboardWillShowNotification, frame: keyboardFrame)
        }
        XCTAssertEqual(view.scrollView.contentInset.bottom, 100, accuracy: 0.001)

        view.configure(layoutMode: .fixed)
        XCTAssertEqual(view.scrollView.contentInset.bottom, 0, accuracy: 0.001)
    }

    // MARK: - Helpers

    private static func hasActiveDimensionConstraint(in view: STBaseView, attribute: NSLayoutConstraint.Attribute) -> Bool {
        (view.scrollView.constraints + view.contentView.constraints).contains { constraint in
            constraint.firstAttribute == attribute &&
            constraint.isActive &&
            (constraint.firstItem as? UIView) === view.contentView
        }
    }

    private static func performWithoutAnimations(_ block: () -> Void) {
        let wasEnabled = UIView.areAnimationsEnabled
        UIView.setAnimationsEnabled(false)
        defer { UIView.setAnimationsEnabled(wasEnabled) }
        block()
    }

    private static func postKeyboardNotification(_ name: Notification.Name, frame: CGRect) {
        NotificationCenter.default.post(
            name: name,
            object: nil,
            userInfo: [
                UIResponder.keyboardFrameEndUserInfoKey: NSValue(cgRect: frame),
                UIResponder.keyboardAnimationDurationUserInfoKey: NSNumber(value: 0),
                UIResponder.keyboardAnimationCurveUserInfoKey: NSNumber(value: UIView.AnimationCurve.easeInOut.rawValue)
            ]
        )
        RunLoop.main.run(until: Date().addingTimeInterval(0.01))
    }

    private static func labelTexts(in view: UIView) -> [String] {
        view.subviews.flatMap { subview -> [String] in
            if let label = subview as? UILabel {
                return [label.text ?? ""]
            }
            return labelTexts(in: subview)
        }
    }

    private static func constraint(
        in containers: [UIView],
        first: UIView,
        firstAttribute: NSLayoutConstraint.Attribute,
        second: UIView,
        secondAttribute: NSLayoutConstraint.Attribute
    ) -> NSLayoutConstraint? {
        containers.flatMap { $0.constraints }.first { constraint in
            (constraint.firstItem as? UIView) === first &&
            constraint.firstAttribute == firstAttribute &&
            (constraint.secondItem as? UIView) === second &&
            constraint.secondAttribute == secondAttribute
        }
    }
}
