//
//  STLogCloudTransport.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2018/10/10.
//

import Foundation

/// 云端日志上传协议。
///
/// 接入方式：
/// 1. 实现 `send(logs:completion:)`，将日志批量上传到你们自己的接口。
/// 2. 在应用启动时通过 `STLogManager.bootstrap(.init(cloudTransport: ...))` 注入。
/// 3. 也可以在登录完成、拿到鉴权信息后调用 `STLogManager.setCloudTransport(...)` 动态替换。
///
/// 示例：
/// ```swift
/// final class MyCloudTransport: STLogCloudTransport {
///     func send(logs: [STLogRecord], completion: @escaping (Result<Void, Error>) -> Void) {
///         // 调用你们自己的上传接口
///         completion(.success(()))
///     }
/// }
///
/// STLogManager.bootstrap(.init(
///     minimumLevel: .debug,
///     persistDefaultLogs: true,
///     cloudTransport: MyCloudTransport(),
///     cloudBatchSize: 20
/// ))
/// ```
///
/// 上传约定：
/// - 成功时调用 `completion(.success(()))`
/// - 失败时调用 `completion(.failure(error))`
/// - 失败批次会在内存中回填，等待下次继续发送
public protocol STLogCloudTransport: AnyObject {
    func send(logs: [STLogRecord], completion: @escaping (Result<Void, Error>) -> Void)
}
