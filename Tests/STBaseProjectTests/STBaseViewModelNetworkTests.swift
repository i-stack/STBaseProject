import XCTest
import Combine
@testable import STBaseProject

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
    var mockedResponse: STHTTPResponse?

    override func st_dispatchRequest(
        url: String,
        method: STHTTPMethod,
        parameters: [String: Any]?,
        encodingType: STParameterEncoder.EncodingType,
        completion: @escaping (STHTTPResponse) -> Void
    ) {
        self.capturedRequest = CapturedRequest(
            url: url,
            method: method,
            parameters: parameters,
            encodingType: encodingType
        )
        if let mockedResponse = self.mockedResponse {
            completion(mockedResponse)
        }
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

        let completionExpectation = expectation(description: "request completion called")
        var completionResult: Result<MockUserDTO, STBaseError>?
        viewModel.st_request(
            url: url.absoluteString,
            method: .get,
            parameters: ["id": 7],
            responseType: MockUserDTO.self
        ) { result in
            completionResult = result
            completionExpectation.fulfill()
        }

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

        guard case .success(let value) = completionResult else {
            return XCTFail("Expected success result")
        }
        XCTAssertEqual(value, responseBody)
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

        let completionExpectation = expectation(description: "request completion called")
        var completionResult: Result<MockUserDTO, STBaseError>?
        viewModel.st_request(
            url: "https://example.com/user",
            responseType: MockUserDTO.self
        ) { result in
            completionResult = result
            completionExpectation.fulfill()
        }

        wait(for: [completionExpectation, failedStateExpectation], timeout: 1.0)

        guard case .failure(let error) = completionResult else {
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

        let completionExpectation = expectation(description: "request completion called")
        var completionResult: Result<MockUserDTO, STBaseError>?
        viewModel.st_request(
            url: url.absoluteString,
            responseType: MockUserDTO.self
        ) { result in
            completionResult = result
            completionExpectation.fulfill()
        }

        wait(for: [completionExpectation], timeout: 1.0)

        guard case .failure(let error) = completionResult else {
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
        let completionExpectation = expectation(description: "post completion called")

        viewModel.st_post(
            url: "https://example.com/user",
            parameters: ["name": "Song"],
            responseType: MockUserDTO.self
        ) { _ in
            completionExpectation.fulfill()
        }

        wait(for: [completionExpectation], timeout: 1.0)
        XCTAssertEqual(viewModel.capturedRequest?.method, .post)
        XCTAssertEqual(viewModel.capturedRequest?.parameters?["name"] as? String, "Song")
    }

    func testPutMethodConvenienceForwardsPutRequestMethod() throws {
        let viewModel = MockRequestingViewModel()
        viewModel.mockedResponse = try self.makeSuccessHTTPResponse()
        let completionExpectation = expectation(description: "put completion called")

        viewModel.st_put(
            url: "https://example.com/user",
            parameters: ["name": "Updated"],
            responseType: MockUserDTO.self
        ) { _ in
            completionExpectation.fulfill()
        }

        wait(for: [completionExpectation], timeout: 1.0)
        XCTAssertEqual(viewModel.capturedRequest?.method, .put)
        XCTAssertEqual(viewModel.capturedRequest?.parameters?["name"] as? String, "Updated")
    }

    func testDeleteMethodConvenienceForwardsDeleteRequestMethod() throws {
        let viewModel = MockRequestingViewModel()
        viewModel.mockedResponse = try self.makeSuccessHTTPResponse()
        let completionExpectation = expectation(description: "delete completion called")

        viewModel.st_delete(
            url: "https://example.com/user",
            parameters: ["id": 7],
            responseType: MockUserDTO.self
        ) { _ in
            completionExpectation.fulfill()
        }

        wait(for: [completionExpectation], timeout: 1.0)
        XCTAssertEqual(viewModel.capturedRequest?.method, .delete)
        XCTAssertEqual(viewModel.capturedRequest?.parameters?["id"] as? Int, 7)
    }

    func testRequestForwardsExplicitPostPutDeleteMethods() throws {
        let viewModel = MockRequestingViewModel()
        viewModel.mockedResponse = try self.makeSuccessHTTPResponse()

        let postExpectation = expectation(description: "explicit post completion")
        viewModel.st_request(
            url: "https://example.com/user",
            method: .post,
            parameters: ["kind": "post"],
            responseType: MockUserDTO.self
        ) { _ in
            postExpectation.fulfill()
        }
        wait(for: [postExpectation], timeout: 1.0)
        XCTAssertEqual(viewModel.capturedRequest?.method, .post)

        let putExpectation = expectation(description: "explicit put completion")
        viewModel.st_request(
            url: "https://example.com/user",
            method: .put,
            parameters: ["kind": "put"],
            responseType: MockUserDTO.self
        ) { _ in
            putExpectation.fulfill()
        }
        wait(for: [putExpectation], timeout: 1.0)
        XCTAssertEqual(viewModel.capturedRequest?.method, .put)

        let deleteExpectation = expectation(description: "explicit delete completion")
        viewModel.st_request(
            url: "https://example.com/user",
            method: .delete,
            parameters: ["kind": "delete"],
            responseType: MockUserDTO.self
        ) { _ in
            deleteExpectation.fulfill()
        }
        wait(for: [deleteExpectation], timeout: 1.0)
        XCTAssertEqual(viewModel.capturedRequest?.method, .delete)
    }
}
