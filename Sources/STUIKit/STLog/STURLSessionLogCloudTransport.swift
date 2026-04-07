//
//  STURLSessionLogCloudTransport.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2018/3/14.
//

import Foundation

public final class STURLSessionLogCloudTransport: STLogCloudTransport {
    public typealias RequestBuilder = (_ logs: [STLogRecord]) throws -> URLRequest

    private let session: URLSession
    private let requestBuilder: RequestBuilder

    public init(session: URLSession = .shared, requestBuilder: @escaping RequestBuilder) {
        self.session = session
        self.requestBuilder = requestBuilder
    }

    public convenience init(endpoint: URL, method: String = "POST", headers: [String: String] = [:], session: URLSession = .shared) {
        self.init(session: session) { logs in
            var request = URLRequest(url: endpoint)
            request.httpMethod = method
            request.timeoutInterval = 15
            headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
            if request.value(forHTTPHeaderField: "Content-Type") == nil {
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            }
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            request.httpBody = try encoder.encode(logs)
            return request
        }
    }

    public func send(logs: [STLogRecord], completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            let request = try self.requestBuilder(logs)
            self.session.dataTask(with: request) { _, response, error in
                if let error {
                    completion(.failure(error))
                    return
                }

                if let httpResponse = response as? HTTPURLResponse,
                   !(200...299).contains(httpResponse.statusCode) {
                    completion(.failure(NSError(
                        domain: "com.stbase.log.cloud",
                        code: httpResponse.statusCode,
                        userInfo: [NSLocalizedDescriptionKey: "Cloud log upload failed with status code \(httpResponse.statusCode)"]
                    )))
                    return
                }

                completion(.success(()))
            }.resume()
        } catch {
            completion(.failure(error))
        }
    }
}
