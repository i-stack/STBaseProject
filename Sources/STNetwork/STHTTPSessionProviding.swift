//
//  STHTTPSessionProviding.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2018/12/10.
//

import Foundation

public protocol STHTTPSessionProviding: AnyObject {

    @discardableResult
    func request(
        _ urlString: String,
        method: STHTTPMethod,
        parameters: [String: Any]?,
        encoding: STParameterEncoder.EncodingType,
        headers: STRequestHeaders?,
        interceptor: STInterceptor?,
        requestConfig: STRequestConfig?
    ) -> STDataRequest

    @discardableResult
    func upload(
        _ urlString: String,
        files: [STUploadFile],
        parameters: [String: Any]?,
        headers: STRequestHeaders?,
        interceptor: STInterceptor?,
        requestConfig: STRequestConfig?
    ) -> STUploadRequest

    @discardableResult
    func download(
        _ urlString: String,
        to destinationURL: URL,
        method: STHTTPMethod,
        parameters: [String: Any]?,
        encoding: STParameterEncoder.EncodingType,
        headers: STRequestHeaders?,
        dispatch: STDownloadDispatch
    ) -> STDownloadRequest

    func st_checkNetworkStatus() -> STNetworkReachabilityStatus
}

public protocol STHTTPURLRequestSessionProviding: STHTTPSessionProviding {

    @discardableResult
    func request(
        _ request: URLRequest,
        interceptor: STInterceptor?,
        requestConfig: STRequestConfig?
    ) -> STDataRequest
}

extension STHTTPSession: STHTTPSessionProviding {}
extension STHTTPSession: STHTTPURLRequestSessionProviding {}
