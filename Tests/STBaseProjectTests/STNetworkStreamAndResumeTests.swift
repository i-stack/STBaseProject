import XCTest
@testable import STBaseProject

final class STNetworkStreamAndResumeTests: XCTestCase {

    func testStreamRequestParsesServerSentEventsAcrossChunks() {
        let request = STDataStreamRequest()
        let eventExpectation = expectation(description: "receive parsed SSE events")
        eventExpectation.expectedFulfillmentCount = 2

        var receivedEvents: [STServerSentEvent] = []
        request.onEvent(queue: .main) { event in
            receivedEvents.append(event)
            eventExpectation.fulfill()
        }

        let part1 = Data("id:1\nevent:update\ndata:hello\n\nid:2\ndata:wo".utf8)
        let part2 = Data("rld\n\n".utf8)
        request.didReceive(part1)
        request.didReceive(part2)

        wait(for: [eventExpectation], timeout: 1.0)
        XCTAssertTrue(request.hasReceivedFirstByte)
        XCTAssertEqual(receivedEvents.count, 2)
        XCTAssertEqual(receivedEvents[0].id, "1")
        XCTAssertEqual(receivedEvents[0].event, "update")
        XCTAssertEqual(receivedEvents[0].data, "hello")
        XCTAssertEqual(receivedEvents[1].id, "2")
        XCTAssertEqual(receivedEvents[1].event, nil)
        XCTAssertEqual(receivedEvents[1].data, "world")
    }

    func testStreamRequestOnCompleteReceivesTerminalError() {
        let request = STDataStreamRequest()
        let completionExpectation = expectation(description: "stream completion callback")
        let terminalError = STHTTPError.timeout

        var receivedError: Error?
        request.onComplete(queue: .main) { error in
            receivedError = error
            completionExpectation.fulfill()
        }

        request.didFinish(error: terminalError)
        wait(for: [completionExpectation], timeout: 1.0)

        guard let httpError = receivedError as? STHTTPError else {
            return XCTFail("Expected STHTTPError.timeout")
        }
        if case .timeout = httpError {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected timeout error")
        }
    }

    func testDownloadRequestStoresResumeDataSafely() {
        let request = STDownloadRequest()
        let resumeData = Data("resume-point".utf8)
        request.didReceiveResumeData(resumeData)

        XCTAssertEqual(request.resumeData, resumeData)
    }

    func testDownloadRequestCancelByProducingResumeDataReturnsStoredValueWithoutTask() {
        let request = STDownloadRequest()
        let expected = Data("existing-resume".utf8)
        request.didReceiveResumeData(expected)

        let expectation = expectation(description: "cancel callback receives stored resumeData")
        _ = request.cancel(byProducingResumeData: { data in
            XCTAssertEqual(data, expected)
            expectation.fulfill()
        })

        wait(for: [expectation], timeout: 1.0)
    }
}
