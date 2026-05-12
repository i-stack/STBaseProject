import XCTest
import Combine
import STBaseProject
@testable import STBaseProjectExample

private struct MockUserDTO: Codable, Equatable {
    let id: Int
    let name: String
}

private final class MockRequestingViewModel: STBaseViewModel {
    struct CapturedRequest {
        let url: String
        let method: STHTTPMethod
        let parameters: [String: Any]?
        let encodingType: STParameterEncoder.EncodingType
    }

    var capturedRequest: CapturedRequest?
    var capturedURLRequest: URLRequest?
    var mockedResponse: STHTTPResponse?
    var responseSubjects: [PassthroughSubject<STHTTPResponse, Never>] = []
    var dispatchCancelCount = 0

    override func st_dispatchRequestPublisher(
        url: String,
        method: STHTTPMethod,
        parameters: [String: Any]?,
        encodingType: STParameterEncoder.EncodingType
    ) -> AnyPublisher<STHTTPResponse, Never> {
        self.capturedRequest = CapturedRequest(
            url: url,
            method: method,
            parameters: parameters,
            encodingType: encodingType
        )
        if !self.responseSubjects.isEmpty {
            let subject = self.responseSubjects.removeFirst()
            return subject
                .handleEvents(receiveCancel: { [weak self] in
                    self?.dispatchCancelCount += 1
                })
                .eraseToAnyPublisher()
        }
        guard let mockedResponse = self.mockedResponse else {
            return Empty<STHTTPResponse, Never>().eraseToAnyPublisher()
        }
        return Just(mockedResponse).eraseToAnyPublisher()
    }

    override func st_dispatchRequestPublisher(_ request: URLRequest) -> AnyPublisher<STHTTPResponse, Never> {
        self.capturedURLRequest = request
        guard let mockedResponse = self.mockedResponse else {
            return Empty<STHTTPResponse, Never>().eraseToAnyPublisher()
        }
        return Just(mockedResponse).eraseToAnyPublisher()
    }
}

final class STBaseViewModelNetworkTests: XCTestCase {
    private var cancellables: Set<AnyCancellable> = []

    override func tearDown() {
        self.cancellables.removeAll()
        super.tearDown()
    }

    private func makeSuccessHTTPResponse(urlString: String = "https://example.com/user") throws -> STHTTPResponse {
        let responseBody = MockUserDTO(id: 7, name: "Song")
        let responseData = try JSONEncoder().encode(responseBody)
        let url = URL(string: urlString)!
        let urlResponse = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)
        return STHTTPResponse(data: responseData, response: urlResponse, error: nil)
    }

    func testRequestSuccessDecodesModelAndPublishesLoadedState() throws {
        let viewModel = MockRequestingViewModel()
        viewModel.requestConfig.showLoading = true

        let responseBody = MockUserDTO(id: 7, name: "Song")
        let responseData = try JSONEncoder().encode(responseBody)
        let url = URL(string: "https://example.com/user")!
        let urlResponse = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)
        viewModel.mockedResponse = STHTTPResponse(data: responseData, response: urlResponse, error: nil)

        var loadingStates: [STLoadingState] = []
        let stateExpectation = expectation(description: "loading state reaches loaded")
        viewModel.loadingState
            .sink { state in
                loadingStates.append(state)
                if case .loaded = state {
                    stateExpectation.fulfill()
                }
            }
            .store(in: &self.cancellables)

        let completionExpectation = expectation(description: "request publisher emits value")
        var receivedValue: MockUserDTO?
        viewModel.st_requestPublisher(
            url: url.absoluteString,
            method: .get,
            parameters: ["id": 7],
            responseType: MockUserDTO.self
        )
        .sink(
            receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    XCTFail("Expected success but got error: \(error)")
                }
            },
            receiveValue: { value in
                receivedValue = value
                completionExpectation.fulfill()
            }
        )
        .store(in: &self.cancellables)

        wait(for: [completionExpectation, stateExpectation], timeout: 1.0)

        XCTAssertEqual(viewModel.capturedRequest?.url, url.absoluteString)
        XCTAssertEqual(viewModel.capturedRequest?.method, .get)
        XCTAssertEqual(viewModel.capturedRequest?.parameters?["id"] as? Int, 7)
        XCTAssertEqual(viewModel.capturedRequest?.encodingType, .json)

        XCTAssertTrue(loadingStates.contains { state in
            if case .loading = state { return true }
            return false
        })
        XCTAssertTrue(loadingStates.contains { state in
            if case .loaded = state { return true }
            return false
        })

        guard let value = receivedValue else {
            return XCTFail("Expected success result")
        }
        XCTAssertEqual(value, responseBody)
    }

    func testRequestPublisherIsLazyUntilSubscribed() throws {
        let viewModel = MockRequestingViewModel()
        viewModel.mockedResponse = try self.makeSuccessHTTPResponse()

        let publisher = viewModel.st_requestPublisher(
            url: "https://example.com/lazy",
            responseType: MockUserDTO.self
        )
        XCTAssertNil(viewModel.capturedRequest)

        let completionExpectation = expectation(description: "lazy publisher emits after subscription")
        publisher
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { _ in completionExpectation.fulfill() }
            )
            .store(in: &self.cancellables)

        wait(for: [completionExpectation], timeout: 1.0)
        XCTAssertEqual(viewModel.capturedRequest?.url, "https://example.com/lazy")
    }

    func testRequestPublisherCancellationReturnsLoadingStateToIdleAndCancelsUpstream() {
        let viewModel = MockRequestingViewModel()
        viewModel.requestConfig.showLoading = true
        viewModel.responseSubjects = [PassthroughSubject<STHTTPResponse, Never>()]

        var states: [STLoadingState] = []
        viewModel.loadingState
            .sink { states.append($0) }
            .store(in: &self.cancellables)

        let token = viewModel.st_requestPublisher(
            url: "https://example.com/cancel",
            responseType: MockUserDTO.self
        )
        .sink(
            receiveCompletion: { _ in },
            receiveValue: { _ in XCTFail("Expected cancellation before response") }
        )

        XCTAssertEqual(viewModel.capturedRequest?.url, "https://example.com/cancel")
        token.cancel()

        XCTAssertEqual(viewModel.dispatchCancelCount, 1)
        XCTAssertTrue(states.contains { state in
            if case .loading = state { return true }
            return false
        })
        XCTAssertEqual(viewModel.loadingState.value, .idle)
    }

    func testConcurrentRequestsKeepLoadingUntilAllRequestsFinish() throws {
        let viewModel = MockRequestingViewModel()
        viewModel.requestConfig.showLoading = true
        let firstSubject = PassthroughSubject<STHTTPResponse, Never>()
        let secondSubject = PassthroughSubject<STHTTPResponse, Never>()
        viewModel.responseSubjects = [firstSubject, secondSubject]

        viewModel.st_requestPublisher(
            url: "https://example.com/first",
            responseType: MockUserDTO.self
        )
        .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
        .store(in: &self.cancellables)

        viewModel.st_requestPublisher(
            url: "https://example.com/second",
            responseType: MockUserDTO.self
        )
        .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
        .store(in: &self.cancellables)

        firstSubject.send(try self.makeSuccessHTTPResponse(urlString: "https://example.com/first"))
        firstSubject.send(completion: .finished)
        XCTAssertEqual(viewModel.loadingState.value, .loading)

        secondSubject.send(try self.makeSuccessHTTPResponse(urlString: "https://example.com/second"))
        secondSubject.send(completion: .finished)
        XCTAssertEqual(viewModel.loadingState.value, .loaded)
    }

    func testURLRequestOverloadPreservesOriginalRequest() throws {
        let viewModel = MockRequestingViewModel()
        viewModel.mockedResponse = try self.makeSuccessHTTPResponse()

        var request = URLRequest(url: URL(string: "https://example.com/raw")!)
        request.httpMethod = "POST"
        request.setValue("application/custom", forHTTPHeaderField: "Content-Type")
        request.setValue("signature-value", forHTTPHeaderField: "X-Signature")
        request.httpBody = Data("raw-body=1&not-json=true".utf8)
        request.timeoutInterval = 7
        request.cachePolicy = .reloadIgnoringLocalCacheData

        let completionExpectation = expectation(description: "URLRequest overload emits value")
        viewModel.st_request(request, responseType: MockUserDTO.self) { result in
            guard case .success = result else {
                return XCTFail("Expected URLRequest overload success")
            }
            completionExpectation.fulfill()
        }

        wait(for: [completionExpectation], timeout: 1.0)
        XCTAssertEqual(viewModel.capturedURLRequest?.url, request.url)
        XCTAssertEqual(viewModel.capturedURLRequest?.httpMethod, "POST")
        XCTAssertEqual(viewModel.capturedURLRequest?.value(forHTTPHeaderField: "Content-Type"), "application/custom")
        XCTAssertEqual(viewModel.capturedURLRequest?.value(forHTTPHeaderField: "X-Signature"), "signature-value")
        XCTAssertEqual(viewModel.capturedURLRequest?.httpBody, request.httpBody)
        XCTAssertEqual(viewModel.capturedURLRequest?.timeoutInterval, 7)
        XCTAssertEqual(viewModel.capturedURLRequest?.cachePolicy, .reloadIgnoringLocalCacheData)
    }

    func testRequestFailureMapsTimeoutErrorAndPublishesFailedState() {
        let viewModel = MockRequestingViewModel()
        viewModel.requestConfig.showLoading = true
        viewModel.mockedResponse = STHTTPResponse(data: nil, response: nil, error: STHTTPError.timeout)

        let failedStateExpectation = expectation(description: "loading state reaches failed")
        var receivedError: STBaseError?
        viewModel.loadingState
            .sink { state in
                if case .failed(let error) = state {
                    receivedError = error
                    failedStateExpectation.fulfill()
                }
            }
            .store(in: &self.cancellables)

        let completionExpectation = expectation(description: "request publisher emits failure")
        var completionError: STBaseError?
        viewModel.st_requestPublisher(
            url: "https://example.com/user",
            responseType: MockUserDTO.self
        )
        .sink(
            receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    completionError = error
                    completionExpectation.fulfill()
                }
            },
            receiveValue: { _ in
                XCTFail("Expected failure but received value")
            }
        )
        .store(in: &self.cancellables)

        wait(for: [completionExpectation, failedStateExpectation], timeout: 1.0)

        guard let error = completionError else {
            return XCTFail("Expected failure result")
        }
        if case .networkError(let message) = error {
            XCTAssertEqual(message, "请求超时")
        } else {
            XCTFail("Expected networkError")
        }

        if case .networkError(let message) = receivedError {
            XCTAssertEqual(message, "请求超时")
        } else {
            XCTFail("Expected failed loading state with networkError")
        }
    }

    func testRequestFailureWhenDecodeInvalidJSON() {
        let viewModel = MockRequestingViewModel()
        viewModel.requestConfig.showLoading = true

        let url = URL(string: "https://example.com/user")!
        let urlResponse = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)
        let invalidData = Data("{\"id\":\"not-int\"}".utf8)
        viewModel.mockedResponse = STHTTPResponse(data: invalidData, response: urlResponse, error: nil)

        let completionExpectation = expectation(description: "request publisher emits decode failure")
        var completionError: STBaseError?
        viewModel.st_requestPublisher(
            url: url.absoluteString,
            responseType: MockUserDTO.self
        )
        .sink(
            receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    completionError = error
                    completionExpectation.fulfill()
                }
            },
            receiveValue: { _ in
                XCTFail("Expected decode failure but received value")
            }
        )
        .store(in: &self.cancellables)

        wait(for: [completionExpectation], timeout: 1.0)

        guard let error = completionError else {
            return XCTFail("Expected decode failure")
        }
        if case .dataError(let message) = error {
            XCTAssertTrue(message.contains("JSON解析失败"))
        } else {
            XCTFail("Expected dataError")
        }
    }

    func testPostMethodConvenienceForwardsPostRequestMethod() throws {
        let viewModel = MockRequestingViewModel()
        viewModel.mockedResponse = try self.makeSuccessHTTPResponse()
        let completionExpectation = expectation(description: "post publisher emits value")
        viewModel.st_postPublisher(
            url: "https://example.com/user",
            parameters: ["name": "Song"],
            responseType: MockUserDTO.self
        )
        .sink(
            receiveCompletion: { _ in },
            receiveValue: { _ in completionExpectation.fulfill() }
        )
        .store(in: &self.cancellables)

        wait(for: [completionExpectation], timeout: 1.0)
        XCTAssertEqual(viewModel.capturedRequest?.method, .post)
        XCTAssertEqual(viewModel.capturedRequest?.parameters?["name"] as? String, "Song")
    }

    func testPutMethodConvenienceForwardsPutRequestMethod() throws {
        let viewModel = MockRequestingViewModel()
        viewModel.mockedResponse = try self.makeSuccessHTTPResponse()
        let completionExpectation = expectation(description: "put publisher emits value")
        viewModel.st_putPublisher(
            url: "https://example.com/user",
            parameters: ["name": "Updated"],
            responseType: MockUserDTO.self
        )
        .sink(
            receiveCompletion: { _ in },
            receiveValue: { _ in completionExpectation.fulfill() }
        )
        .store(in: &self.cancellables)

        wait(for: [completionExpectation], timeout: 1.0)
        XCTAssertEqual(viewModel.capturedRequest?.method, .put)
        XCTAssertEqual(viewModel.capturedRequest?.parameters?["name"] as? String, "Updated")
    }

    func testDeleteMethodConvenienceForwardsDeleteRequestMethod() throws {
        let viewModel = MockRequestingViewModel()
        viewModel.mockedResponse = try self.makeSuccessHTTPResponse()
        let completionExpectation = expectation(description: "delete publisher emits value")
        viewModel.st_deletePublisher(
            url: "https://example.com/user",
            parameters: ["id": 7],
            responseType: MockUserDTO.self
        )
        .sink(
            receiveCompletion: { _ in },
            receiveValue: { _ in completionExpectation.fulfill() }
        )
        .store(in: &self.cancellables)

        wait(for: [completionExpectation], timeout: 1.0)
        XCTAssertEqual(viewModel.capturedRequest?.method, .delete)
        XCTAssertEqual(viewModel.capturedRequest?.parameters?["id"] as? Int, 7)
    }

    func testRequestForwardsExplicitPostPutDeleteMethods() throws {
        let viewModel = MockRequestingViewModel()
        viewModel.mockedResponse = try self.makeSuccessHTTPResponse()

        let postExpectation = expectation(description: "explicit post publisher")
        viewModel.st_requestPublisher(
            url: "https://example.com/user",
            method: .post,
            parameters: ["kind": "post"],
            responseType: MockUserDTO.self
        )
        .sink(
            receiveCompletion: { _ in },
            receiveValue: { _ in postExpectation.fulfill() }
        )
        .store(in: &self.cancellables)
        wait(for: [postExpectation], timeout: 1.0)
        XCTAssertEqual(viewModel.capturedRequest?.method, .post)

        let putExpectation = expectation(description: "explicit put publisher")
        viewModel.st_requestPublisher(
            url: "https://example.com/user",
            method: .put,
            parameters: ["kind": "put"],
            responseType: MockUserDTO.self
        )
        .sink(
            receiveCompletion: { _ in },
            receiveValue: { _ in putExpectation.fulfill() }
        )
        .store(in: &self.cancellables)
        wait(for: [putExpectation], timeout: 1.0)
        XCTAssertEqual(viewModel.capturedRequest?.method, .put)

        let deleteExpectation = expectation(description: "explicit delete publisher")
        viewModel.st_requestPublisher(
            url: "https://example.com/user",
            method: .delete,
            parameters: ["kind": "delete"],
            responseType: MockUserDTO.self
        )
        .sink(
            receiveCompletion: { _ in },
            receiveValue: { _ in deleteExpectation.fulfill() }
        )
        .store(in: &self.cancellables)
        wait(for: [deleteExpectation], timeout: 1.0)
        XCTAssertEqual(viewModel.capturedRequest?.method, .delete)
    }

    func testLegacyCompletionRequestStillWorksWithPublisherBackedImplementation() throws {
        let viewModel = MockRequestingViewModel()
        viewModel.requestConfig.showLoading = true

        let responseBody = MockUserDTO(id: 99, name: "Legacy")
        let responseData = try JSONEncoder().encode(responseBody)
        let url = URL(string: "https://example.com/legacy")!
        let urlResponse = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)
        viewModel.mockedResponse = STHTTPResponse(data: responseData, response: urlResponse, error: nil)

        let completionExpectation = expectation(description: "legacy completion receives success")
        var completionResult: Result<MockUserDTO, STBaseError>?
        viewModel.st_request(
            url: url.absoluteString,
            method: .get,
            parameters: ["legacy": true],
            responseType: MockUserDTO.self
        ) { result in
            completionResult = result
            completionExpectation.fulfill()
        }

        wait(for: [completionExpectation], timeout: 1.0)
        XCTAssertEqual(viewModel.capturedRequest?.method, .get)
        XCTAssertEqual(viewModel.capturedRequest?.parameters?["legacy"] as? Bool, true)
        guard case .success(let value) = completionResult else {
            return XCTFail("Expected success result from legacy completion API")
        }
        XCTAssertEqual(value, responseBody)
    }

    func testLegacyCompletionRequestFailureStillMapsToSTBaseError() {
        let viewModel = MockRequestingViewModel()
        viewModel.mockedResponse = STHTTPResponse(data: nil, response: nil, error: STHTTPError.timeout)

        let completionExpectation = expectation(description: "legacy completion receives failure")
        var completionResult: Result<MockUserDTO, STBaseError>?
        viewModel.st_request(
            url: "https://example.com/legacy-error",
            responseType: MockUserDTO.self
        ) { result in
            completionResult = result
            completionExpectation.fulfill()
        }

        wait(for: [completionExpectation], timeout: 1.0)
        guard case .failure(let error) = completionResult else {
            return XCTFail("Expected failure result from legacy completion API")
        }
        if case .networkError(let message) = error {
            XCTAssertEqual(message, "请求超时")
        } else {
            XCTFail("Expected networkError for legacy completion API")
        }
    }
}
