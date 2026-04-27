import XCTest
@testable import STBaseProject

final class STHTTPDebugLogTests: XCTestCase {

    func testCURLDescriptionForGetRequestOmitsExplicitGetMethod() {
        var request = URLRequest(url: URL(string: "https://example.com/path?a=1")!)
        request.httpMethod = "GET"

        let curl = request.st_cURLDescription()

        XCTAssertTrue(curl.contains("$ curl -v"))
        XCTAssertTrue(curl.contains("\"https://example.com/path?a=1\""))
        XCTAssertFalse(curl.contains("-X GET"))
    }

    func testCURLDescriptionRedactsConfiguredHeaders() {
        var request = URLRequest(url: URL(string: "https://example.com/api")!)
        request.httpMethod = "POST"
        request.setValue("Bearer abc123", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let curl = request.st_cURLDescription(redactedHeaders: ["authorization"])

        XCTAssertTrue(curl.contains("-X POST"))
        XCTAssertTrue(curl.contains("Authorization: ***"))
        XCTAssertTrue(curl.contains("Content-Type: application/json"))
        XCTAssertFalse(curl.contains("Bearer abc123"))
    }

    func testCURLDescriptionTruncatesLargeBody() {
        var request = URLRequest(url: URL(string: "https://example.com/upload")!)
        request.httpMethod = "POST"
        request.httpBody = Data("abcdefghijklmnopqrstuvwxyz".utf8)

        let curl = request.st_cURLDescription(maxBodyLength: 10)

        XCTAssertTrue(curl.contains("-d \"abcdefghij...<truncated 16 bytes>\""))
    }

    func testCURLDescriptionUsesBinaryFlagForNonUTF8Body() {
        var request = URLRequest(url: URL(string: "https://example.com/binary")!)
        request.httpMethod = "PUT"
        request.httpBody = Data([0xFF, 0xD8, 0x00, 0x10, 0xAA])

        let curl = request.st_cURLDescription()

        XCTAssertTrue(curl.contains("--data-binary <5 bytes>"))
        XCTAssertFalse(curl.contains("-d \""))
    }
}
