//
//  STInterceptor.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2018/12/10.
//

import Foundation

public protocol STRequestAdapter {
    func adapt(_ urlRequest: URLRequest, for session: STHTTPSession) async throws -> URLRequest
}

public protocol STRequestRetrier {
    func retry(_ request: STRequest, for session: STHTTPSession, dueTo error: Error) async -> STRetryResult
}

public protocol STInterceptor: STRequestAdapter, STRequestRetrier {}

public struct STRetryPolicy: STRequestRetrier {

    public let retryLimit: Int
    public let exponentialBackoffBase: Double
    public let exponentialBackoffScale: Double
    public let retryableHTTPMethods: Set<STHTTPMethod>
    public let retryableHTTPStatusCodes: Set<Int>

    public static let `default` = STRetryPolicy()

    public init(
        retryLimit: Int = 2,
        exponentialBackoffBase: Double = 2,
        exponentialBackoffScale: Double = 0.5,
        retryableHTTPMethods: Set<STHTTPMethod> = [.get, .head, .put, .delete, .options, .trace],
        retryableHTTPStatusCodes: Set<Int> = [408, 500, 502, 503, 504]
    ) {
        self.retryLimit = retryLimit
        self.exponentialBackoffBase = exponentialBackoffBase
        self.exponentialBackoffScale = exponentialBackoffScale
        self.retryableHTTPMethods = retryableHTTPMethods
        self.retryableHTTPStatusCodes = retryableHTTPStatusCodes
    }

    public func retry(
        _ request: STRequest,
        for session: STHTTPSession,
        dueTo error: Error
    ) async -> STRetryResult {
        guard request.retryCount < self.retryLimit else { return .doNotRetry }

        if let httpError = error as? STHTTPError, case .serverError(let code) = httpError {
            guard self.retryableHTTPStatusCodes.contains(code) else { return .doNotRetry }
        }

        let delay = pow(self.exponentialBackoffBase, Double(request.retryCount)) * self.exponentialBackoffScale
        return .retryWithDelay(delay)
    }
}

public final class STAuthInterceptor: STInterceptor {

    public typealias TokenProvider = () async throws -> String
    public typealias TokenRefresher = () async throws -> String

    private let tokenProvider: TokenProvider
    private let tokenRefresher: TokenRefresher
    private let headerKey: String
    private let headerPrefix: String

    private let refreshLock = NSLock()
    private var isRefreshing = false
    private var pendingRetries: [(STRetryResult) -> Void] = []

    public init(
        headerKey: String = "Authorization",
        headerPrefix: String = "Bearer",
        tokenProvider: @escaping TokenProvider,
        tokenRefresher: @escaping TokenRefresher
    ) {
        self.headerKey = headerKey
        self.headerPrefix = headerPrefix
        self.tokenProvider = tokenProvider
        self.tokenRefresher = tokenRefresher
    }

    public func adapt(_ urlRequest: URLRequest, for session: STHTTPSession) async throws -> URLRequest {
        var request = urlRequest
        let token = try await self.tokenProvider()
        request.setValue("\(self.headerPrefix) \(token)", forHTTPHeaderField: self.headerKey)
        return request
    }

    public func retry(
        _ request: STRequest,
        for session: STHTTPSession,
        dueTo error: Error
    ) async -> STRetryResult {
        guard let httpError = error as? STHTTPError,
              case .serverError(let code) = httpError,
              code == 401 else {
            return .doNotRetry
        }

        return await withCheckedContinuation { continuation in
            self.refreshLock.lock()
            if self.isRefreshing {
                self.pendingRetries.append { continuation.resume(returning: $0) }
                self.refreshLock.unlock()
                return
            }
            self.isRefreshing = true
            self.refreshLock.unlock()

            Task {
                do {
                    _ = try await self.tokenRefresher()
                    self.resolvePending(result: .retry)
                    continuation.resume(returning: .retry)
                } catch {
                    self.resolvePending(result: .doNotRetryWithError(error))
                    continuation.resume(returning: .doNotRetryWithError(error))
                }
            }
        }
    }

    private func resolvePending(result: STRetryResult) {
        self.refreshLock.lock()
        let pending = self.pendingRetries
        self.pendingRetries.removeAll()
        self.isRefreshing = false
        self.refreshLock.unlock()
        pending.forEach { $0(result) }
    }
}
