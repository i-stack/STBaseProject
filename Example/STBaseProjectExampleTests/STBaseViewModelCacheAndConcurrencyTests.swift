//
//  STBaseViewModelCacheAndConcurrencyTests.swift
//  STBaseProjectExampleTests
//

import Combine
import XCTest
@testable import STBaseProject

/// 自包含测试：不依赖其他测试文件中的 private 类型。
/// 覆盖：隐藏 loading 的并发计数守卫、新旧缓存命名空间契约、清理所有权判定（不触碰真实磁盘）、
/// 上传/下载完成后的 cancellables 精确回收。
final class STBaseViewModelCacheAndConcurrencyTests: XCTestCase {

    private var cancellables = Set<AnyCancellable>()

    // MARK: - 场景1：隐藏 loading 的并发计数守卫

    /// showLoading == false 的请求不应发送任何 loading 终态，避免干扰其他并发请求的计数。
    func testHiddenLoadingRequestDoesNotSendTerminalState() {
        let vm = TestViewModel()
        vm.requestConfig.showLoading = false
        var states: [STLoadingState] = []
        let cancellable = vm.loadingState.dropFirst().sink { states.append($0) }

        let expectation = self.expectation(description: "request-finished")
        var received: TestModel?
        vm.st_requestPublisher(url: "https://example.com", responseType: TestModel.self)
            .sink(receiveCompletion: { _ in expectation.fulfill() },
                  receiveValue: { received = $0 })
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 2)
        XCTAssertNotNil(received, "数据应正常返回")
        XCTAssertTrue(states.isEmpty, "隐藏 loading 的请求不应产生任何 loading 终态，实际: \(states)")
        cancellable.cancel()
    }

    /// showLoading == true 的请求应正常发送 .loading -> .loaded。
    func testVisibleLoadingRequestSendsTerminalState() {
        let vm = TestViewModel()
        vm.requestConfig.showLoading = true
        var states: [STLoadingState] = []
        let cancellable = vm.loadingState.dropFirst().sink { states.append($0) }

        let expectation = self.expectation(description: "request-finished")
        vm.st_requestPublisher(url: "https://example.com", responseType: TestModel.self)
            .sink(receiveCompletion: { _ in expectation.fulfill() },
                  receiveValue: { _ in })
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 2)
        XCTAssertTrue(states.contains(where: { if case .loading = $0 { return true }; return false }), "应发送 .loading")
        XCTAssertTrue(states.contains(where: { if case .loaded = $0 { return true }; return false }), "应发送 .loaded")
        cancellable.cancel()
    }

    // MARK: - 场景3：新旧缓存命名空间契约

    func testCacheNamespaceContract() {
        let vm = TestViewModel()
        let key = "https://example.com/api"

        guard let newURL = vm.st_diskCacheURL(forKey: key) else {
            XCTFail("新缓存路径不应为 nil"); return
        }
        let newBase = newURL.deletingPathExtension().lastPathComponent
        XCTAssertTrue(newBase.hasPrefix("stvm_"), "新文件名应带 stvm_ 前缀")
        let newHash = String(newBase.dropFirst("stvm_".count))
        XCTAssertEqual(newHash.count, 64, "哈希应为 64 个十六进制字符")
        XCTAssertTrue(newBase.range(of: "^stvm_[0-9a-f]{64}$", options: .regularExpression) != nil)

        guard let legacyURL = vm.st_legacyDiskCacheURL(forKey: key) else {
            XCTFail("旧缓存路径不应为 nil"); return
        }
        let legacyBase = legacyURL.deletingPathExtension().lastPathComponent
        XCTAssertFalse(legacyBase.hasPrefix("stvm_"), "旧文件名不应带前缀")
        XCTAssertTrue(legacyBase.range(of: "^[0-9a-f]{64}$", options: .regularExpression) != nil, "旧文件名应为纯 64 位哈希")
        XCTAssertNotEqual(newBase, legacyBase, "新旧路径应不同（迁移语义）")
    }

    // MARK: - 场景4：清理所有权判定（不触碰真实磁盘）

    func testIsOwnedCacheFileOwnership() {
        let vm = TestViewModel()

        // 本模块：新命名空间
        XCTAssertTrue(vm.st_isOwnedCacheFile(URL(fileURLWithPath: "/tmp/stvm_\(String(repeating: "a", count: 64)).cache")))

        // 无 stvm_ 前缀的一律不算本模块文件（包括纯 64 位哈希，防止误删其他 SHA-256 命名模块）
        XCTAssertFalse(vm.st_isOwnedCacheFile(URL(fileURLWithPath: "/tmp/\(String(repeating: "f", count: 64)).cache")))
        XCTAssertFalse(vm.st_isOwnedCacheFile(URL(fileURLWithPath: "/tmp/image.cache")))
        XCTAssertFalse(vm.st_isOwnedCacheFile(URL(fileURLWithPath: "/tmp/network.cache")))
        XCTAssertFalse(vm.st_isOwnedCacheFile(URL(fileURLWithPath: "/tmp/other.cache")))
        // 非 .cache 后缀
        XCTAssertFalse(vm.st_isOwnedCacheFile(URL(fileURLWithPath: "/tmp/stvm_abc.txt")))
    }

    // MARK: - 场景2：上传/下载完成后 token 精确回收（registry 计数）

    func testUploadCompletionReleasesToken() {
        let session = FakeHTTPSession()
        let vm = TestViewModel(session: session)
        vm.requestConfig.showLoading = false

        let done = self.expectation(description: "upload-completed")
        vm.st_upload(url: "https://example.com/upload", files: [], responseType: TestModel.self) { _ in
            done.fulfill()
        }
        XCTAssertGreaterThan(vm.st_registeredCancellableCount, 0, "上传后应注册 token")
        session.lastUploadRequest?.didComplete(with: STHTTPResponse(data: Data(), response: nil, error: nil))

        wait(for: [done], timeout: 2)
        XCTAssertEqual(vm.st_registeredCancellableCount, 0, "上传完成应从 registry 中移除 token")
    }

    func testDownloadCompletionReleasesToken() {
        let session = FakeHTTPSession()
        let vm = TestViewModel(session: session)
        vm.requestConfig.showLoading = false

        let done = self.expectation(description: "download-completed")
        vm.st_download(url: "https://example.com/file") { _, _ in
            done.fulfill()
        }
        session.lastDownloadRequest?.didComplete(with: .success(URL(fileURLWithPath: NSTemporaryDirectory())))

        wait(for: [done], timeout: 2)
        XCTAssertEqual(vm.st_registeredCancellableCount, 0, "下载完成应从 registry 中移除 token")
    }

    /// 上传失败（completion-only，无 value）也应移除 token。
    func testUploadFailureCompletionOnlyReleasesToken() {
        let session = FakeHTTPSession()
        let vm = TestViewModel(session: session)
        vm.requestConfig.showLoading = false

        let done = self.expectation(description: "upload-failed")
        vm.st_upload(url: "https://example.com/upload", files: [], responseType: TestModel.self) { _ in
            done.fulfill()
        }
        session.lastUploadRequest?.didComplete(with: STHTTPResponse(data: nil, response: nil, error: STHTTPError.timeout))

        wait(for: [done], timeout: 2)
        XCTAssertEqual(vm.st_registeredCancellableCount, 0, "上传失败（无 value）也应移除 token")
    }

    /// 多次连续上传后 registry 应回到基线，不随次数累积。
    func testMultipleUploadsDoNotAccumulateTokens() {
        let session = FakeHTTPSession()
        let vm = TestViewModel(session: session)
        vm.requestConfig.showLoading = false

        for i in 0..<3 {
            let done = self.expectation(description: "upload-\(i)")
            vm.st_upload(url: "https://example.com/upload/\(i)", files: [], responseType: TestModel.self) { _ in
                done.fulfill()
            }
            session.lastUploadRequest?.didComplete(with: STHTTPResponse(data: Data(), response: nil, error: nil))
            wait(for: [done], timeout: 2)
        }
        XCTAssertEqual(vm.st_registeredCancellableCount, 0, "多次连续上传不应累积 token")
    }
}

// MARK: - 测试辅助类型（文件内私有，自包含）

private struct TestModel: Codable {
    let name: String
    let age: Int
}

private final class TestViewModel: STBaseViewModel {
    init(session: STHTTPSessionProviding? = nil) {
        super.init()
        if let session = session {
            self.httpSession = session
        }
    }

    /// 用可控响应替换底层请求，避免真实网络。
    override func st_dispatchRequestPublisher(url: String, method: STHTTPMethod, parameters: [String: Any]?, encodingType: STParameterEncoder.EncodingType) -> AnyPublisher<STHTTPResponse, Never> {
        let data = try? JSONEncoder().encode(TestModel(name: "x", age: 1))
        return Just(STHTTPResponse(data: data, response: nil, error: nil)).eraseToAnyPublisher()
    }
}

private final class FakeHTTPSession: STHTTPSessionProviding {
    var lastUploadRequest: STUploadRequest?
    var lastDownloadRequest: STDownloadRequest?

    func request(_ urlString: String, method: STHTTPMethod, parameters: [String: Any]?, encoding: STParameterEncoder.EncodingType, headers: STRequestHeaders?, interceptor: STInterceptor?, requestConfig: STRequestConfig?) -> STDataRequest {
        fatalError("未在该测试中使用")
    }

    func upload(_ urlString: String, files: [STUploadFile], parameters: [String: Any]?, headers: STRequestHeaders?, interceptor: STInterceptor?, requestConfig: STRequestConfig?) -> STUploadRequest {
        let req = STUploadRequest(maxRetryCount: 0, retryDelay: 0)
        lastUploadRequest = req
        return req
    }

    func download(_ urlString: String, to destinationURL: URL, method: STHTTPMethod, parameters: [String: Any]?, encoding: STParameterEncoder.EncodingType, headers: STRequestHeaders?, dispatch: STDownloadDispatch) -> STDownloadRequest {
        let req = STDownloadRequest(destination: destinationURL, maxRetryCount: 0, retryDelay: 0)
        lastDownloadRequest = req
        return req
    }

    func st_checkNetworkStatus() -> STNetworkReachabilityStatus {
        return .unknown
    }
}
