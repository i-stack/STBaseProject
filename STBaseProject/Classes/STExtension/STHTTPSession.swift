//
//  STHTTPSession.swift
//  STBaseProject
//
//  Created by stack on 2018/12/10.
//

import UIKit

public struct STHTTPMethod {
    /// `CONNECT` method.
    public static let connect = STHTTPMethod(rawValue: "CONNECT")
    /// `DELETE` method.
    public static let delete = STHTTPMethod(rawValue: "DELETE")
    /// `GET` method.
    public static let get = STHTTPMethod(rawValue: "GET")
    /// `HEAD` method.
    public static let head = STHTTPMethod(rawValue: "HEAD")
    /// `OPTIONS` method.
    public static let options = STHTTPMethod(rawValue: "OPTIONS")
    /// `PATCH` method.
    public static let patch = STHTTPMethod(rawValue: "PATCH")
    /// `POST` method.
    public static let post = STHTTPMethod(rawValue: "POST")
    /// `PUT` method.
    public static let put = STHTTPMethod(rawValue: "PUT")
    /// `QUERY` method.
    public static let query = STHTTPMethod(rawValue: "QUERY")
    /// `TRACE` method.
    public static let trace = STHTTPMethod(rawValue: "TRACE")

    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

open class STHTTPSession: NSObject {

    open var timeout: TimeInterval = 6
    public static let `shared` = STHTTPSession()
    
    private func st_http(request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) {
        self.session.dataTask(with: request) { (data, response, error) in
            DispatchQueue.main.async {
                completionHandler(data, response, error)
            }
        }
    }
    
    private func st_encode(urlRequest: URLRequest, with parameters: Dictionary<String, Any>?) throws -> URLRequest {
        var request = urlRequest
        guard let url = request.url else {
            throw NSError.init(domain: "missingURL", code: 0, userInfo: [:])
        }
        if let para = parameters, !para.isEmpty {
            if let method = request.httpMethod, method == STHTTPMethod.get.rawValue {
                if var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) {
                    let percentEncodedQuery = (urlComponents.percentEncodedQuery.map { $0 + "&" } ?? "") + self.st_query(para)
                    urlComponents.percentEncodedQuery = percentEncodedQuery
                    request.url = urlComponents.url
                }
            } else {
                request.httpBody = self.st_query(para).data(using: .utf8, allowLossyConversion: false)
            }
        }
        return request
    }
    
    private func st_query(_ parameters: [String: Any]) -> String {
       var components: [(String, String)] = []
       for key in parameters.keys.sorted(by: <) {
           let value = parameters[key]!
           components += self.st_queryComponents(fromKey: key, value: value)
       }
       return components.map { "\($0)=\($1)" }.joined(separator: "&")
    }
    
    private func st_queryComponents(fromKey key: String, value: Any) -> [(String, String)] {
       var components: [(String, String)] = []
       if let dictionary = value as? [String: Any] {
            for (nestedKey, value) in dictionary {
                components += st_queryComponents(fromKey: "\(key)[\(nestedKey)]", value: value)
            }
       } else if let array = value as? [Any] {
            for value in array {
                components += st_queryComponents(fromKey: "\(key)[]", value: value)
            }
       } else if let value = value as? NSNumber {
            components.append((st_escape(key), st_escape("\(value)")))
       } else if let bool = value as? Bool {
            components.append((st_escape(key), st_escape(bool ? "1" : "0")))
       } else {
            components.append((st_escape(key), st_escape("\(value)")))
       }
       return components
    }
    
    private func st_escape(_ string: String) -> String {
        let generalDelimitersToEncode = ":#[]@" // does not include "?" or "/" due to RFC 3986 - Section 3.4
        let subDelimitersToEncode = "!$&'()*+,;="
        var allowedCharacterSet = CharacterSet.urlQueryAllowed
        allowedCharacterSet.remove(charactersIn: "\(generalDelimitersToEncode)\(subDelimitersToEncode)")
        var escaped = ""
        if #available(iOS 8.3, *) {
            escaped = string.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet) ?? string
        } else {
            let batchSize = 50
            var index = string.startIndex
            while index != string.endIndex {
                let startIndex = index
                let endIndex = string.index(index, offsetBy: batchSize, limitedBy: string.endIndex) ?? string.endIndex
                let range = startIndex..<endIndex
                let substring = string[range]
                escaped += substring.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet) ?? String(substring)
                index = endIndex
            }
        }
        return escaped
    }
    
    private func st_missUrl() -> Error {
        return NSError.init(domain: "missingURL", code: 0, userInfo: [:])
    }
    
    private func st_defatulContentType(request: URLRequest) -> URLRequest {
        var req = request
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        return req
    }
    
    lazy var session: URLSession = {
        let configuration: URLSessionConfiguration = URLSessionConfiguration.default
        let session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        return session
    } ()
}

//MARK: get request
public extension STHTTPSession {
    func st_httpGetRequest(url: String, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) {
       self.st_httpGetRequest(url: url, parameters: [:], completionHandler: completionHandler)
    }

    func st_httpGetRequest(url: String, parameters: Dictionary<String, Any>, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) {
       self.st_httpGetRequest(url: url, parameters: parameters, httpHeaderFields: [:], completionHandler: completionHandler)
    }
    
    func st_httpGetRequest(url: String?, parameters: Dictionary<String, Any>?, httpHeaderFields: Dictionary<String, String>?, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) {
       guard let urlStr = url, !urlStr.isEmpty else {
           DispatchQueue.main.async {
               completionHandler(Data(), URLResponse(), self.st_missUrl())
           }
           return
       }
       
       if let url = URL.init(string: urlStr) {
           var urlRequest = URLRequest(url: url)
           urlRequest.timeoutInterval = self.timeout
           urlRequest.httpMethod = STHTTPMethod.get.rawValue
           if let headers = httpHeaderFields {
               for (headerField, headerValue) in headers {
                   urlRequest.setValue(headerValue, forHTTPHeaderField: headerField)
               }
           } else {
               urlRequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
           }
           do {
               let reqeust = try self.st_encode(urlRequest: urlRequest, with: parameters)
               self.st_http(request: reqeust, completionHandler: completionHandler)
           } catch (let error) {
                DispatchQueue.main.async {
                     completionHandler(Data(), URLResponse(), error)
                }
           }
       } else {
            DispatchQueue.main.async {
                 completionHandler(Data(), URLResponse(), self.st_missUrl())
            }
       }
   }
}

//MARK: post request
public extension STHTTPSession {
    func st_httpPostRquest(url: String, httpBody: Data, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) {
        self.st_httpPostRquest(url: url, httpBody: httpBody, httpHeaderFields: [:], completionHandler: completionHandler)
    }
    
    func st_httpPostRquest(url: String, parameters: Dictionary<String, Any>, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) {
        self.st_httpPostRquest(url: url, parameters: parameters, httpHeaderFields: [:], completionHandler: completionHandler)
    }
    
    func st_httpPostRquest(url: String?, parameters: Dictionary<String, Any>?, httpHeaderFields: Dictionary<String, String>?, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) {
        guard let urlStr = url, !urlStr.isEmpty else {
            DispatchQueue.main.async {
                 completionHandler(Data(), URLResponse(), self.st_missUrl())
            }
            return
        }
        
        if let para = parameters {
            if let body = self.st_query(para).data(using: .utf8, allowLossyConversion: false) {
                return self.st_httpPostRquest(url: urlStr, httpBody: body, completionHandler: completionHandler)
            }
        }
        DispatchQueue.main.async {
             completionHandler(Data(), URLResponse(), self.st_missUrl())
        }
    }
    
    func st_httpPostRquest(url: String?, httpBody: Data, httpHeaderFields: Dictionary<String, String>?, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) {
        guard let urlStr = url, !urlStr.isEmpty else {
            DispatchQueue.main.async {
                 completionHandler(Data(), URLResponse(), self.st_missUrl())
            }
            return
        }
        
        if let url = URL.init(string: urlStr) {
            var urlRequest = URLRequest(url: url)
            urlRequest.httpBody = httpBody
            urlRequest.timeoutInterval = self.timeout
            urlRequest.httpMethod = STHTTPMethod.post.rawValue
            if let headers = httpHeaderFields {
                for (headerField, headerValue) in headers {
                    urlRequest.setValue(headerValue, forHTTPHeaderField: headerField)
                }
            } else {
                urlRequest.setValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
            }
            self.st_http(request: urlRequest, completionHandler: completionHandler)
        } else {
            DispatchQueue.main.async {
                 completionHandler(Data(), URLResponse(), self.st_missUrl())
            }
        }
    }
}

extension STHTTPSession: URLSessionTaskDelegate {
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        
    }
}
