import XCTest
import UIKit
@testable import STBaseProject
@testable import STMedia

final class STToolsExtensionTests: XCTestCase {

    func testStringTrimmingWithEmptyNeedleReturnsOriginalString() {
        XCTAssertEqual("abc".trimmingPrefix(""), "abc")
        XCTAssertEqual("abc".trimmingSuffix(""), "abc")
        XCTAssertEqual("abc".trimming(both: ""), "abc")
    }

    func testStringHelpersHandleCommonBoundaries() {
        XCTAssertEqual("a/b/c".substring(after: "/", fromEnd: true), "c")
        XCTAssertEqual("a/b/c".substring(before: "/", fromEnd: true), "a/b")
        XCTAssertEqual("  a\n\tb  ".normalizedWhitespace, "a b")
        XCTAssertEqual("<a&b>".htmlEscaped, "&lt;a&amp;b&gt;")
        XCTAssertEqual("a b+c&d".strictURLQueryEncoded, "a%20b%2Bc%26d")
    }

    func testURLQueryHelpers() throws {
        let url = try XCTUnwrap(URL(string: "https://example.com/path?x=1&y&z=%E4%B8%AD"))
        XCTAssertEqual(url.queryComponents["x"], "1")
        XCTAssertEqual(url.queryComponents["y"], "")
        XCTAssertEqual(url.queryComponents["z"], "中")

        let appended = try XCTUnwrap(url.appendingQueryParameters(["x": "2", "q": "a b"]))
        XCTAssertEqual(appended.queryComponents["q"], "a b")

        let removed = try XCTUnwrap(appended.removingQueryParameters(named: ["x"]))
        XCTAssertNil(removed.queryComponents["x"])
        XCTAssertEqual(removed.queryComponents["q"], "a b")
    }

    func testCacheEvictsLeastRecentlyUsedItem() {
        let cache = STCache<String, Int>(itemLimit: 2)
        cache.setObject(1, forKey: "a")
        cache.setObject(2, forKey: "b")

        XCTAssertEqual(cache.object(forKey: "a"), 1)

        cache.setObject(3, forKey: "c")
        XCTAssertEqual(cache.object(forKey: "a"), 1)
        XCTAssertNil(cache.object(forKey: "b"))
        XCTAssertEqual(cache.object(forKey: "c"), 3)
    }

    func testCacheUpdatingExistingKeyDoesNotEvictOtherItems() {
        let cache = STCache<String, Int>(itemLimit: 2)
        cache.setObject(1, forKey: "a")
        cache.setObject(2, forKey: "b")
        cache.setObject(10, forKey: "a")

        XCTAssertEqual(cache.object(forKey: "a"), 10)
        XCTAssertEqual(cache.object(forKey: "b"), 2)
    }

    func testColorCSSStringAndSourceOverBlend() {
        let css = UIColor(red: 1, green: 0.5, blue: 0, alpha: 0.25).cssColorString
        XCTAssertEqual(css, "rgba(255, 128, 0, 0.25)")

        let base = UIColor(red: 0, green: 0, blue: 1, alpha: 1)
        let source = UIColor(red: 1, green: 0, blue: 0, alpha: 0.5)
        let blended = base.blending(with: source)
        XCTAssertEqual(blended?.cssColorString, "rgba(128, 0, 128, 1)")
    }

    func testImageSimilarityUsesWholeImage() {
        let red = UIImage.solidColor(.red, size: CGSize(width: 2, height: 2), scale: 1)
        let almostRed = red.withAdditionalDrawing { context in
            UIColor.blue.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        }

        XCTAssertEqual(red.similarity(to: red), 1)
        let similarity = red.similarity(to: almostRed)
        XCTAssertNotNil(similarity)
        XCTAssertGreaterThan(similarity ?? 0, 0)
        XCTAssertLessThan(similarity ?? 1, 1)
    }
}
