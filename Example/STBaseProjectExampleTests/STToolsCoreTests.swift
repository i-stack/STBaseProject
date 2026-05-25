import XCTest
import STBaseProject
@testable import STBaseProjectExample

final class STToolsCoreTests: XCTestCase {

    func testDataHexAndBase64RoundTrip() {
        let data = Data("hello".utf8)
        XCTAssertEqual(data.hexEncodedString(), "68656c6c6f")
        XCTAssertEqual(Data.hexDecoded("68656c6c6f"), data)

        let base64URLSafe = data.base64URLSafeEncodedString()
        XCTAssertEqual(Data.base64URLSafeDecoded(base64URLSafe), data)
    }

    func testDataSlicesAndChunks() {
        let data = Data([1, 2, 3, 4, 5])
        XCTAssertEqual(data.slice(from: 1, length: 3), Data([2, 3, 4]))
        XCTAssertEqual(data.slice(from: -1, length: 2), Data([1, 2]))
        XCTAssertEqual(data.chunks(ofSize: 2), [Data([1, 2]), Data([3, 4]), Data([5])])
    }

    func testDataConstantTimeEquals() {
        let lhs = Data([1, 2, 3, 4])
        XCTAssertTrue(lhs.constantTimeEquals(to: Data([1, 2, 3, 4])))
        XCTAssertFalse(lhs.constantTimeEquals(to: Data([1, 2, 3, 5])))
        XCTAssertFalse(lhs.constantTimeEquals(to: Data([1, 2, 3])))
    }

    func testDictionaryTypedAccessAndMerge() {
        let dict: [String: Any] = ["name": "st", "count": "12", "flag": "yes", "ratio": 2]
        XCTAssertEqual(dict.stringValue(for: "name"), "st")
        XCTAssertEqual(dict.intValue(for: "count"), 12)
        XCTAssertEqual(dict.boolValue(for: "flag"), true)
        XCTAssertEqual(dict.doubleValue(for: "ratio"), 2.0)

        let merged = ["a": 1, "b": 2].mergingValues(with: ["b": 3, "c": 4])
        XCTAssertEqual(merged["a"], 1)
        XCTAssertEqual(merged["b"], 3)
        XCTAssertEqual(merged["c"], 4)
    }

    func testGeometryDistanceAndAngle() {
        let distance = STGeometry.distance(between: CGPoint(x: 0, y: 0), and: CGPoint(x: 3, y: 4))
        XCTAssertEqual(distance, 5, accuracy: 0.0001)

        let angle = STGeometry.angle(
            onCircleWithRadius: 10,
            center: CGPoint(x: 0, y: 0),
            start: CGPoint(x: 10, y: 0),
            end: CGPoint(x: 0, y: 10)
        )
        XCTAssertEqual(angle, 90, accuracy: 0.0001)

        let offsetCenterAngle = STGeometry.angle(
            onCircleWithRadius: 10,
            center: CGPoint(x: 5, y: 5),
            start: CGPoint(x: 15, y: 5),
            end: CGPoint(x: 5, y: 15)
        )
        XCTAssertEqual(offsetCenterAngle, 90, accuracy: 0.0001)
    }

    func testJSONValueConversionAndCodable() throws {
        let value = STJSONValue(["k": 1, "ok": true, "arr": ["x", 2]] as [String: Any])
        let object = value.object(or: [:])
        XCTAssertEqual(object["k"]?.intValue, 1)
        XCTAssertEqual(object["ok"]?.boolValue, true)
        XCTAssertEqual(object["arr"]?.arrayValue?.count, 2)

        let encoded = try JSONEncoder().encode(value)
        let decoded = try JSONDecoder().decode(STJSONValue.self, from: encoded)
        XCTAssertEqual(decoded.object(or: [:])["k"]?.int(or: 0), 1)
    }

    func testStringValidationAndMasking() {
        XCTAssertTrue(STStringValidator.isValidEmail("a@b.com"))
        XCTAssertTrue(STStringValidator.isValidPhoneNumber("13812345678"))
        XCTAssertFalse(STStringValidator.isValidPhoneNumber("23812345678"))
        XCTAssertEqual("13812345678".maskedPhoneNumber(start: 3, end: 7), "138****5678")
        XCTAssertEqual("hello world".snakeCased, "hello world")
    }

    func testDateFormattingAndSmartDate() throws {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let text = date.formatted("yyyy-MM-dd")
        XCTAssertFalse(text.isEmpty)
        XCTAssertEqual(text.date(using: "yyyy-MM-dd")?.formatted("yyyy-MM-dd"), text)

        XCTAssertNotNil("2024-10-01 12:30:00".smartDate)
        XCTAssertNotNil("2024-10-01T12:30:00Z".smartDate)
        let interval = try XCTUnwrap("1700000000".timestampDate?.timeIntervalSince1970)
        XCTAssertEqual(interval, 1_700_000_000, accuracy: 0.001)
    }

    func testFileSystemCreateReadWriteRemove() {
        let dir = URL(fileURLWithPath: STFileSystem.temporaryDirectoryPath)
            .appendingPathComponent("sttools-tests-\(UUID().uuidString)").path
        XCTAssertTrue(STFileSystem.createDirectoryIfNeeded(at: dir))

        let filePath = STFileSystem.createFileIfNeeded(in: dir, fileName: "a.txt")
        XCTAssertTrue(STFileSystem.overwriteFile(at: filePath, with: "line1"))
        XCTAssertTrue(STFileSystem.appendLine("line2", toFileAt: filePath))
        XCTAssertEqual(STFileSystem.readString(fromFileAt: filePath), "line1\nline2")
        XCTAssertTrue(STFileSystem.removeItem(at: dir))
    }

    func testThreadingHelpers() {
        let backgroundExpectation = XCTestExpectation(description: "background run")
        STThreading.runInBackground {
            backgroundExpectation.fulfill()
        }
        wait(for: [backgroundExpectation], timeout: 1.0)

        let mainExpectation = XCTestExpectation(description: "main run")
        STThreading.runOnMain {
            XCTAssertTrue(Thread.isMainThread)
            mainExpectation.fulfill()
        }
        wait(for: [mainExpectation], timeout: 1.0)
    }
}
