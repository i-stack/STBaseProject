//
//  STDataTests.swift
//  STBaseProjectTests
//
//  Created by 寒江孤影 on 2019/03/16.
//

import XCTest
@testable import STBaseProject

final class STDataTests: XCTestCase {

    func testUnifiedDataStringAndEncodingAliasesMatchLegacyAPI() {
        let data = Data("Hello".utf8)

        XCTAssertEqual(data.string(using: .utf8), data.toString())
        XCTAssertEqual(data.utf8String, "Hello")
        XCTAssertEqual(data.utf8String(or: "fallback"), data.toStringUTF8(defaultValue: "fallback"))
        XCTAssertEqual(data.hexEncodedString(), data.toHexString())
        XCTAssertEqual(data.base64URLSafeEncodedString(), data.toBase64URLSafeString())
    }

    func testUnifiedStringEncodingAliasesMatchLegacyAPI() {
        let text = "Hello+/="

        XCTAssertEqual(text.encodedData(using: .utf8), text.st_toData())
        XCTAssertEqual(text.base64Encoded(), text.st_toBase64())
        XCTAssertEqual(text.base64URLSafeEncoded(), text.st_toBase64URLSafe())
        XCTAssertEqual(text.hexEncoded(), text.st_toHex())
    }

    func testBase64URLSafeRoundTripRemovesUnsafeCharacters() {
        let original = Data([0xfb, 0xff, 0xef])

        let encoded = original.toBase64URLSafeString()
        let decoded = Data.fromBase64URLSafeString(encoded)

        XCTAssertEqual(encoded, "-__v")
        XCTAssertFalse(encoded.contains("+"))
        XCTAssertFalse(encoded.contains("/"))
        XCTAssertFalse(encoded.contains("="))
        XCTAssertFalse(encoded.contains("\r"))
        XCTAssertFalse(encoded.contains("\n"))
        XCTAssertEqual(decoded, original)
    }

    func testHexParsingAcceptsPrefixAndWhitespace() {
        let data = Data.fromHexString("  0x48 65 6c\n6c\t6f  ")

        XCTAssertEqual(data?.toString(), "Hello")
    }

    func testSubdataWithNonPositiveLengthReturnsEmptyData() {
        let data = Data([0x01, 0x02, 0x03])

        XCTAssertEqual(data.subdata(from: 1, length: 0), Data())
        XCTAssertEqual(data.subdata(from: 1, length: -1), Data())
    }

    func testChunkedReturnsEmptyArrayForEmptyData() {
        XCTAssertEqual(Data().chunked(into: 8), [])
    }

    func testRandomDataZeroLengthReturnsEmptyData() {
        XCTAssertTrue(STDataUtils.randomData(length: 0).isEmpty)
    }

    func testMergePreservesOrder() {
        let merged = STDataUtils.merge([
            Data([0x01, 0x02]),
            Data(),
            Data([0x03, 0x04]),
        ])

        XCTAssertEqual(merged, Data([0x01, 0x02, 0x03, 0x04]))
    }

    func testConstantTimeEqualsSupportsEmptyPayload() {
        XCTAssertTrue(STDataUtils.constantTimeEquals(Data(), Data()))
        XCTAssertFalse(STDataUtils.constantTimeEquals(Data(), Data([0x01])))
        XCTAssertTrue(Data().constantTimeEquals(to: Data()))
    }

    func testUnifiedSlicingAndChunkingAliasesMatchLegacyAPI() {
        let data = Data([0, 1, 2, 3, 4, 5])

        XCTAssertEqual(data.slice(from: 2, length: 3), data.subdata(from: 2, length: 3))
        XCTAssertEqual(data.chunks(ofSize: 2), data.chunked(into: 2))
    }

    #if canImport(Compression)
    func testCompressionRoundTripDoesNotDependOnExactExpectedSize() {
        let original = Data((0..<8192).map { index in
            UInt8(truncatingIfNeeded: (index &* 31) ^ (index >> 3))
        })

        let compressed = original.compressed()
        let decompressedWithoutHint = compressed?.decompressed()
        let decompressedWithSmallHint = compressed?.decompressed(expectedSize: 16)

        XCTAssertNotNil(compressed)
        XCTAssertEqual(decompressedWithoutHint, original)
        XCTAssertEqual(decompressedWithSmallHint, original)
    }
    #endif
}
