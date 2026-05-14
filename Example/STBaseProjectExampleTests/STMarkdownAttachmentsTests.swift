import XCTest
import UIKit
@testable import STBaseProject

// MARK: - Test doubles

/// 最小 `STMarkdownRefreshableAttachment` 实现，用于隔离测试附件刷新协议与绑定逻辑。
private final class MockRefreshableAttachment: NSTextAttachment, STMarkdownRefreshableAttachment, @unchecked Sendable {
    private let registry = STMarkdownRefreshObserverRegistry()

    func addDisplayObserver(_ observer: @escaping () -> Void) -> STMarkdownRefreshObservation {
        self.registry.add(observer)
    }

    func notifyDisplayObservers() {
        self.registry.notify()
    }
}

// MARK: - STMarkdownRefreshObservation & STMarkdownRefreshObserverRegistry

final class STMarkdownRefreshAttachmentInfrastructureTests: XCTestCase {

    func testRefreshObservationInvalidateRunsHandlerOnce() {
        var calls = 0
        let obs = STMarkdownRefreshObservation { calls += 1 }
        obs.invalidate()
        obs.invalidate()
        XCTAssertEqual(calls, 1)
    }

    func testRefreshObservationDeinitInvalidatesHandler() {
        var calls = 0
        do {
            _ = STMarkdownRefreshObservation { calls += 1 }
        }
        XCTAssertEqual(calls, 1)
    }

    func testRefreshObserverRegistryMulticastAndInvalidateRemovesEntry() {
        let registry = STMarkdownRefreshObserverRegistry()
        var a = 0
        var b = 0
        let tokenA = registry.add { a += 1 }
        let tokenB = registry.add { b += 1 }
        registry.notify()
        XCTAssertEqual(a, 1)
        XCTAssertEqual(b, 1)
        tokenA.invalidate()
        registry.notify()
        XCTAssertEqual(a, 1)
        XCTAssertEqual(b, 2)
        tokenB.invalidate()
    }

    func testRefreshObserverRegistryNotifyInvokesAllCurrentObservers() {
        let registry = STMarkdownRefreshObserverRegistry()
        var sum = 0
        let token1 = registry.add { sum += 1 }
        let token2 = registry.add { sum += 2 }
        registry.notify()
        XCTAssertEqual(sum, 3)
        token1.invalidate()
        token2.invalidate()
    }
}

// MARK: - STMarkdownNumberBadgeAttachment

@MainActor
final class STMarkdownNumberBadgeAttachmentTests: XCTestCase {

    func testFixedDiameterBaseline() {
        XCTAssertEqual(STMarkdownNumberBadgeAttachment.fixedDiameter, 18, accuracy: 0.001)
    }

    func testInitUsesMinimumDiameterForSmallBodyFont() {
        let font = UIFont.st_systemFont(ofSize: 10, weight: .regular)
        let badge = STMarkdownNumberBadgeAttachment(
            numberText: "1",
            font: font,
            textColor: .white,
            backgroundColor: .systemBlue
        )
        guard let image = badge.image else {
            return XCTFail("expected image")
        }
        XCTAssertEqual(image.size.width, STMarkdownNumberBadgeAttachment.fixedDiameter, accuracy: 0.5)
        XCTAssertEqual(image.size.height, STMarkdownNumberBadgeAttachment.fixedDiameter, accuracy: 0.5)
        XCTAssertEqual(badge.bounds.width, image.size.width, accuracy: 0.001)
        XCTAssertEqual(badge.bounds.height, image.size.height, accuracy: 0.001)
    }

    func testInitScalesDiameterWithBodyFont() {
        let font = UIFont.st_systemFont(ofSize: 34, weight: .regular)
        let badge = STMarkdownNumberBadgeAttachment(
            numberText: "2",
            font: font,
            textColor: .label,
            backgroundColor: .systemGray3
        )
        guard let image = badge.image else {
            return XCTFail("expected image")
        }
        // 与 `STMarkdownNumberBadgeAttachment.init` 一致：`UIFont` 实际 `pointSize` 可能略大于请求值。
        let expected = max(
            STMarkdownNumberBadgeAttachment.fixedDiameter,
            ceil(font.pointSize / 17 * STMarkdownNumberBadgeAttachment.fixedDiameter)
        )
        XCTAssertEqual(image.size.width, expected, accuracy: 0.5)
        XCTAssertEqual(image.size.height, expected, accuracy: 0.5)
    }

    func testRenderBadgeImageDefaultDiameterMatchesFixedDiameter() {
        let img = STMarkdownNumberBadgeAttachment.renderBadgeImage(
            number: "9",
            textColor: .white,
            backgroundColor: .systemRed
        )
        XCTAssertEqual(img.size.width, STMarkdownNumberBadgeAttachment.fixedDiameter, accuracy: 0.5)
        XCTAssertEqual(img.size.height, STMarkdownNumberBadgeAttachment.fixedDiameter, accuracy: 0.5)
    }

    func testRenderBadgeImageAccessibilityLabel() {
        let img = STMarkdownNumberBadgeAttachment.renderBadgeImage(
            number: "42",
            textColor: .white,
            backgroundColor: .black,
            diameter: 20
        )
        XCTAssertEqual(img.accessibilityLabel, "引用 42")
    }

    func testInitImageAccessibilityLabel() {
        let font = UIFont.st_systemFont(ofSize: 17, weight: .regular)
        let badge = STMarkdownNumberBadgeAttachment(
            numberText: "7",
            font: font,
            textColor: .white,
            backgroundColor: .systemGreen
        )
        XCTAssertEqual(badge.image?.accessibilityLabel, "引用 7")
    }

    func testRenderBadgeImageCacheReturnsSameInstanceForIdenticalParameters() {
        let a = STMarkdownNumberBadgeAttachment.renderBadgeImage(
            number: "3",
            textColor: .white,
            backgroundColor: .systemOrange,
            diameter: 22
        )
        let b = STMarkdownNumberBadgeAttachment.renderBadgeImage(
            number: "3",
            textColor: .white,
            backgroundColor: .systemOrange,
            diameter: 22
        )
        XCTAssertTrue(a === b)
    }

    func testLegacyTypealiasCompilesAndBehavesLikeConcreteType() {
        let font = UIFont.st_systemFont(ofSize: 17, weight: .regular)
        let viaAlias: STMarkdownCircleNumberAttachment = STMarkdownCircleNumberAttachment(
            numberText: "1",
            font: font,
            textColor: .white,
            backgroundColor: .systemBlue
        )
        XCTAssertNotNil(viaAlias.image)
    }
}

// MARK: - STMarkdownAttachmentRefreshSupport

@MainActor
final class STMarkdownAttachmentRefreshSupportTests: XCTestCase {

    func testBindRefreshHandlersEmptyStringReturnsNoTokens() {
        let empty = NSAttributedString()
        let tokens = STMarkdownAttachmentRefreshSupport.bindRefreshHandlers(in: empty) { _ in }
        XCTAssertTrue(tokens.isEmpty)
    }

    func testBindRefreshHandlersSkipsNonRefreshableAttachments() {
        let plain = NSTextAttachment()
        let attr = NSMutableAttributedString(string: " ")
        attr.addAttribute(.attachment, value: plain, range: NSRange(location: 0, length: 1))
        var refreshCalls = 0
        let tokens = STMarkdownAttachmentRefreshSupport.bindRefreshHandlers(in: attr) { _ in
            refreshCalls += 1
        }
        XCTAssertTrue(tokens.isEmpty)
        XCTAssertEqual(refreshCalls, 0)
    }

    func testBindRefreshHandlersInvokesRefreshOnMainWhenObserverFiresOnMainThread() {
        let expectation = expectation(description: "refresh")
        let attachment = MockRefreshableAttachment()
        let attr = NSMutableAttributedString(string: " ")
        attr.addAttribute(.attachment, value: attachment, range: NSRange(location: 0, length: 1))
        let tokens = STMarkdownAttachmentRefreshSupport.bindRefreshHandlers(in: attr) { att in
            XCTAssertTrue(Thread.isMainThread)
            XCTAssertTrue(att === attachment)
            expectation.fulfill()
        }
        attachment.notifyDisplayObservers()
        waitForExpectations(timeout: 2)
        tokens.forEach { $0.invalidate() }
    }

    func testBindRefreshHandlersDispatchesToMainWhenObserverFiresOffMainThread() {
        let expectation = expectation(description: "refresh off main")
        let attachment = MockRefreshableAttachment()
        let attr = NSMutableAttributedString(string: " ")
        attr.addAttribute(.attachment, value: attachment, range: NSRange(location: 0, length: 1))
        let tokens = STMarkdownAttachmentRefreshSupport.bindRefreshHandlers(in: attr) { att in
            XCTAssertTrue(Thread.isMainThread)
            XCTAssertTrue(att === attachment)
            expectation.fulfill()
        }
        DispatchQueue.global(qos: .userInitiated).async {
            attachment.notifyDisplayObservers()
        }
        waitForExpectations(timeout: 3)
        tokens.forEach { $0.invalidate() }
    }

    func testBindRefreshHandlersRegistersOneTokenPerRefreshableAttachment() {
        let a = MockRefreshableAttachment()
        let b = MockRefreshableAttachment()
        let attr = NSMutableAttributedString(string: "  ")
        attr.addAttribute(.attachment, value: a, range: NSRange(location: 0, length: 1))
        attr.addAttribute(.attachment, value: b, range: NSRange(location: 1, length: 1))
        var count = 0
        let tokens = STMarkdownAttachmentRefreshSupport.bindRefreshHandlers(in: attr) { _ in
            count += 1
        }
        XCTAssertEqual(tokens.count, 2)
        a.notifyDisplayObservers()
        b.notifyDisplayObservers()
        XCTAssertEqual(count, 2)
    }

    func testInvalidateObservationStopsFurtherRefreshCallbacks() {
        let attachment = MockRefreshableAttachment()
        let attr = NSMutableAttributedString(string: " ")
        attr.addAttribute(.attachment, value: attachment, range: NSRange(location: 0, length: 1))
        var calls = 0
        let tokens = STMarkdownAttachmentRefreshSupport.bindRefreshHandlers(in: attr) { _ in
            calls += 1
        }
        XCTAssertEqual(tokens.count, 1)
        attachment.notifyDisplayObservers()
        XCTAssertEqual(calls, 1)
        tokens[0].invalidate()
        attachment.notifyDisplayObservers()
        XCTAssertEqual(calls, 1)
    }
}
