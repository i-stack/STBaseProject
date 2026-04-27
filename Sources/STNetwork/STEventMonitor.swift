//
//  STEventMonitor.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2018/12/10.
//

import Foundation

public protocol STEventMonitor: AnyObject {

    var queue: DispatchQueue { get }

    func requestDidResume(_ request: STRequest)
    func requestDidSuspend(_ request: STRequest)
    func requestDidCancel(_ request: STRequest)
    func requestDidFinish(_ request: STRequest)
    func requestDidTransition(_ request: STRequest, from: STRequestState, to: STRequestState)

    func request(_ request: STRequest, didCreateURLRequest urlRequest: URLRequest)
    func request(_ request: STRequest, didAdaptURLRequest initial: URLRequest, to adapted: URLRequest)
    func request(_ request: STRequest, didReceiveHTTPResponse response: HTTPURLResponse)

    func request(_ request: STDataRequest, didReceiveData data: Data)
    func request(_ request: STUploadRequest, didSendBytes bytesSent: Int64, totalBytesSent: Int64, totalBytesExpected: Int64)
    func request(_ request: STDownloadRequest, didWriteData bytesWritten: Int64, totalWritten: Int64, totalExpected: Int64)
}

public extension STEventMonitor {
    var queue: DispatchQueue { .main }
    func requestDidResume(_ request: STRequest) {}
    func requestDidSuspend(_ request: STRequest) {}
    func requestDidCancel(_ request: STRequest) {}
    func requestDidFinish(_ request: STRequest) {}
    func requestDidTransition(_ request: STRequest, from: STRequestState, to: STRequestState) {}
    func request(_ request: STRequest, didCreateURLRequest urlRequest: URLRequest) {}
    func request(_ request: STRequest, didAdaptURLRequest initial: URLRequest, to adapted: URLRequest) {}
    func request(_ request: STRequest, didReceiveHTTPResponse response: HTTPURLResponse) {}
    func request(_ request: STDataRequest, didReceiveData data: Data) {}
    func request(_ request: STUploadRequest, didSendBytes bytesSent: Int64, totalBytesSent: Int64, totalBytesExpected: Int64) {}
    func request(_ request: STDownloadRequest, didWriteData bytesWritten: Int64, totalWritten: Int64, totalExpected: Int64) {}
}

// MARK: - Composite Monitor
public final class STCompositeEventMonitor: STEventMonitor {

    private let monitors: [STEventMonitor]

    public init(monitors: [STEventMonitor]) {
        self.monitors = monitors
    }

    private func notify(_ block: @escaping (STEventMonitor) -> Void) {
        for monitor in self.monitors {
            monitor.queue.async { block(monitor) }
        }
    }

    public func requestDidResume(_ request: STRequest) { self.notify { $0.requestDidResume(request) } }
    public func requestDidSuspend(_ request: STRequest) { self.notify { $0.requestDidSuspend(request) } }
    public func requestDidCancel(_ request: STRequest) { self.notify { $0.requestDidCancel(request) } }
    public func requestDidFinish(_ request: STRequest) { self.notify { $0.requestDidFinish(request) } }
    public func requestDidTransition(_ request: STRequest, from: STRequestState, to: STRequestState) { self.notify { $0.requestDidTransition(request, from: from, to: to) } }
    public func request(_ request: STRequest, didCreateURLRequest urlRequest: URLRequest) { self.notify { $0.request(request, didCreateURLRequest: urlRequest) } }
    public func request(_ request: STRequest, didAdaptURLRequest initial: URLRequest, to adapted: URLRequest) { self.notify { $0.request(request, didAdaptURLRequest: initial, to: adapted) } }
    public func request(_ request: STRequest, didReceiveHTTPResponse response: HTTPURLResponse) { self.notify { $0.request(request, didReceiveHTTPResponse: response) } }
    public func request(_ request: STDataRequest, didReceiveData data: Data) { self.notify { $0.request(request, didReceiveData: data) } }
    public func request(_ request: STUploadRequest, didSendBytes bytesSent: Int64, totalBytesSent: Int64, totalBytesExpected: Int64) { self.notify { $0.request(request, didSendBytes: bytesSent, totalBytesSent: totalBytesSent, totalBytesExpected: totalBytesExpected) } }
    public func request(_ request: STDownloadRequest, didWriteData bytesWritten: Int64, totalWritten: Int64, totalExpected: Int64) { self.notify { $0.request(request, didWriteData: bytesWritten, totalWritten: totalWritten, totalExpected: totalExpected) } }
}

// MARK: - Console Logger
public final class STConsoleEventMonitor: STEventMonitor {

    public static let `default` = STConsoleEventMonitor()

    private lazy var dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss.SSS"
        return f
    }()

    private func ts() -> String { self.dateFormatter.string(from: Date()) }

    public func request(_ request: STRequest, didCreateURLRequest urlRequest: URLRequest) {
        let method = urlRequest.httpMethod ?? "??"
        let url = urlRequest.url?.absoluteString ?? ""
        print("[\(self.ts())] [\(method)] --> \(url)")
        if let body = urlRequest.httpBody,
           let bodyStr = String(data: body, encoding: .utf8) {
            print("  Body: \(bodyStr.prefix(500))")
        }
    }

    public func request(_ request: STRequest, didAdaptURLRequest initial: URLRequest, to adapted: URLRequest) {
        if initial.allHTTPHeaderFields != adapted.allHTTPHeaderFields {
            print("[\(self.ts())] [ADAPT] Headers updated")
        }
    }

    public func request(_ request: STRequest, didReceiveHTTPResponse response: HTTPURLResponse) {
        let emoji = response.statusCode < 400 ? "✓" : "✗"
        let url = response.url?.absoluteString ?? ""
        print("[\(self.ts())] [\(emoji) \(response.statusCode)] <-- \(url)")
    }

    public func requestDidCancel(_ request: STRequest) {
        print("[\(self.ts())] [CANCEL] \(request.urlRequest?.url?.absoluteString ?? "")")
    }

    public func requestDidFinish(_ request: STRequest) {
        print("[\(self.ts())] [DONE]")
    }

    public func request(_ request: STUploadRequest, didSendBytes bytesSent: Int64, totalBytesSent: Int64, totalBytesExpected: Int64) {
        guard totalBytesExpected > 0 else { return }
        let pct = Int(Double(totalBytesSent) / Double(totalBytesExpected) * 100)
        print("[\(self.ts())] [UPLOAD] \(pct)%")
    }

    public func request(_ request: STDownloadRequest, didWriteData bytesWritten: Int64, totalWritten: Int64, totalExpected: Int64) {
        guard totalExpected > 0 else { return }
        let pct = Int(Double(totalWritten) / Double(totalExpected) * 100)
        print("[\(self.ts())] [DOWNLOAD] \(pct)%")
    }
}
