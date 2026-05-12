import XCTest
import Combine
import STBaseProject
@testable import STBaseProjectExample

final class STNetworkStreamAndResumeTests: XCTestCase {
    private var cancellables: Set<AnyCancellable> = []

    override func tearDown() {
        self.cancellables.removeAll()
        super.tearDown()
    }

    func testStreamRequestParsesServerSentEventsAcrossChunks() {
        let request = STDataStreamRequest()
        let eventExpectation = expectation(description: "receive parsed SSE events")
        eventExpectation.expectedFulfillmentCount = 2

        var receivedEvents: [STServerSentEvent] = []
        request.eventPublisher
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { event in
                    receivedEvents.append(event)
                    eventExpectation.fulfill()
                }
            )
            .store(in: &self.cancellables)

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
        let completionExpectation = expectation(description: "stream completion receives terminal error")
        let terminalError = STHTTPError.timeout

        var receivedError: Error?
        request.eventPublisher
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        receivedError = error
                    }
                    completionExpectation.fulfill()
                },
                receiveValue: { _ in }
            )
            .store(in: &self.cancellables)

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

    func testStreamRequestDataPublisherEmitsChunksInOrder() {
        let request = STDataStreamRequest()
        let chunkExpectation = expectation(description: "receive two data chunks in order")
        chunkExpectation.expectedFulfillmentCount = 2

        var receivedChunks: [Data] = []
        request.dataPublisher
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { chunk in
                    receivedChunks.append(chunk)
                    chunkExpectation.fulfill()
                }
            )
            .store(in: &self.cancellables)

        let chunk1 = Data("first".utf8)
        let chunk2 = Data("second".utf8)
        request.didReceive(chunk1)
        request.didReceive(chunk2)

        wait(for: [chunkExpectation], timeout: 1.0)
        XCTAssertEqual(receivedChunks, [chunk1, chunk2])
    }

    func testStreamRequestParsesMultiLineSSEDataField() {
        let request = STDataStreamRequest()
        let eventExpectation = expectation(description: "receive one multiline SSE event")

        var receivedEvent: STServerSentEvent?
        request.eventPublisher
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { event in
                    receivedEvent = event
                    eventExpectation.fulfill()
                }
            )
            .store(in: &self.cancellables)

        request.didReceive(Data("id:42\nevent:note\ndata:line1\ndata:line2\n\n".utf8))

        wait(for: [eventExpectation], timeout: 1.0)
        XCTAssertEqual(receivedEvent?.id, "42")
        XCTAssertEqual(receivedEvent?.event, "note")
        XCTAssertEqual(receivedEvent?.data, "line1\nline2")
    }

    func testStreamRequestParsesRetryField() {
        let request = STDataStreamRequest()
        let eventExpectation = expectation(description: "receive one SSE event with retry")

        var receivedEvent: STServerSentEvent?
        request.eventPublisher
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { event in
                    receivedEvent = event
                    eventExpectation.fulfill()
                }
            )
            .store(in: &self.cancellables)

        request.didReceive(Data("id:7\nevent:reconnect\ndata:payload\nretry:1500\n\n".utf8))

        wait(for: [eventExpectation], timeout: 1.0)
        XCTAssertEqual(receivedEvent?.id, "7")
        XCTAssertEqual(receivedEvent?.event, "reconnect")
        XCTAssertEqual(receivedEvent?.data, "payload")
        XCTAssertEqual(receivedEvent?.retry, 1500)
    }

    func testStreamRequestIgnoresCommentAndUnknownFields() {
        let request = STDataStreamRequest()
        let eventExpectation = expectation(description: "receive one SSE event ignoring comment and unknown fields")

        var receivedEvent: STServerSentEvent?
        request.eventPublisher
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { event in
                    receivedEvent = event
                    eventExpectation.fulfill()
                }
            )
            .store(in: &self.cancellables)

        request.didReceive(
            Data(":this is comment\nfoo:bar\nid:11\nevent:update\ndata:ok\n\n".utf8)
        )

        wait(for: [eventExpectation], timeout: 1.0)
        XCTAssertEqual(receivedEvent?.id, "11")
        XCTAssertEqual(receivedEvent?.event, "update")
        XCTAssertEqual(receivedEvent?.data, "ok")
        XCTAssertNil(receivedEvent?.retry)
    }

    func testStreamRequestEventsAsyncSequenceYieldsThenFinishes() async throws {
        let request = STDataStreamRequest()
        let consumedExpectation = expectation(description: "consume two events then finish")

        var consumedEvents: [STServerSentEvent] = []
        let readerTask = Task {
            do {
                for try await event in request.events() {
                    consumedEvents.append(event)
                }
                consumedExpectation.fulfill()
            } catch {
                XCTFail("Expected finished stream without error, got \(error)")
            }
        }

        request.didReceive(Data("id:1\ndata:a\n\n".utf8))
        request.didReceive(Data("id:2\ndata:b\n\n".utf8))
        request.didFinish(error: nil)

        await fulfillment(of: [consumedExpectation], timeout: 1.0)
        readerTask.cancel()

        XCTAssertEqual(consumedEvents.count, 2)
        XCTAssertEqual(consumedEvents[0].id, "1")
        XCTAssertEqual(consumedEvents[0].data, "a")
        XCTAssertEqual(consumedEvents[1].id, "2")
        XCTAssertEqual(consumedEvents[1].data, "b")
    }

    func testStreamRequestEventsAsyncSequenceThrowsTerminalError() async throws {
        let request = STDataStreamRequest()
        let terminalError = STHTTPError.timeout
        let completionExpectation = expectation(description: "events async sequence throws terminal error")

        var receivedError: Error?
        let readerTask = Task {
            do {
                for try await _ in request.events() {}
                XCTFail("Expected async sequence to throw terminal error")
            } catch {
                receivedError = error
                completionExpectation.fulfill()
            }
        }

        request.didFinish(error: terminalError)
        await fulfillment(of: [completionExpectation], timeout: 1.0)
        readerTask.cancel()

        guard let httpError = receivedError as? STHTTPError else {
            return XCTFail("Expected STHTTPError.timeout")
        }
        if case .timeout = httpError {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected timeout error")
        }
    }

    func testStreamRequestBytesAsyncSequenceThrowsTerminalError() async throws {
        let request = STDataStreamRequest()
        let terminalError = STHTTPError.cancelled
        let completionExpectation = expectation(description: "bytes async sequence throws terminal error")

        var receivedError: Error?
        let readerTask = Task {
            do {
                for try await _ in request.bytes() {}
                XCTFail("Expected async sequence to throw terminal error")
            } catch {
                receivedError = error
                completionExpectation.fulfill()
            }
        }

        request.didFinish(error: terminalError)
        await fulfillment(of: [completionExpectation], timeout: 1.0)
        readerTask.cancel()

        guard let httpError = receivedError as? STHTTPError else {
            return XCTFail("Expected STHTTPError.cancelled")
        }
        if case .cancelled = httpError {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected cancelled error")
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
