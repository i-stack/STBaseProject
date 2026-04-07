//
//  STLogOutput.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2019/03/16.
//

import Foundation

@inline(__always)
private func stDefaultLabel(from file: String) -> String {
    ((file as NSString).lastPathComponent as NSString).deletingPathExtension
}

/// 通用日志入口。
///
/// 默认行为：
/// - `DEBUG` 环境下会输出到控制台。
/// - 是否写入本地文件由 `STLogManager.Configuration.persistDefaultLogs` 控制。
///
/// 适用场景：
/// - 开发调试信息
/// - 普通状态流转记录
/// - 不一定需要长期保留的业务日志
///
/// 如果需要在 TestFlight / Release 中确保日志可导出，请在启动时开启：
/// ```swift
/// STLogManager.bootstrap(.init(
///     minimumLevel: .debug,
///     persistDefaultLogs: true
/// ))
/// ```
///
/// 如果需要同步上传到云端，可继续配置：
/// ```swift
/// let transport = STURLSessionLogCloudTransport(
///     endpoint: URL(string: "https://example.com/api/logs")!,
///     headers: ["Authorization": "Bearer <token>"]
/// )
///
/// STLogManager.bootstrap(.init(
///     minimumLevel: .debug,
///     persistDefaultLogs: true,
///     cloudTransport: transport,
///     cloudBatchSize: 20
/// ))
/// ```
///
/// - Parameters:
///   - message: 日志消息内容
///   - level: 日志级别，默认 `info`
///   - metadata: 结构化附加字段，例如 requestId、userId、page
///   - file: 调用文件，默认由编译器注入
///   - function: 调用函数，默认由编译器注入
///   - line: 调用行号，默认由编译器注入
public func STLog<T>(_ message: T, level: STLogLevel = .info, metadata: STLogger.Metadata = [:], file: String = #fileID, function: String = #function, line: Int = #line) {
    let logger = STLogManager.makeLogger(label: stDefaultLabel(from: file))
    logger.log(level: level, String(describing: message), metadata: metadata, persistent: STLogManager.configuration.persistDefaultLogs, file: file, function: function, line: line)
}

/// 强制写入本地持久化日志。
///
/// 默认行为：
/// - `DEBUG` 环境下会输出到控制台。
/// - 无论 `persistDefaultLogs` 是否开启，都会写入本地日志文件。
///
/// 适用场景：
/// - 网络失败、解析失败、支付失败等关键错误
/// - 崩溃前 breadcrumb
/// - TestFlight / Release 需要回溯的问题定位信息
/// - 需要同时本地落盘并参与云端上传的关键日志
///
/// - Parameters:
///   - message: 日志消息内容
///   - level: 日志级别，默认 `info`
///   - metadata: 结构化附加字段，例如 requestId、traceId、errorCode
///   - file: 调用文件，默认由编译器注入
///   - function: 调用函数，默认由编译器注入
///   - line: 调用行号，默认由编译器注入
public func STPersistentLog<T>(_ message: T, level: STLogLevel = .info, metadata: STLogger.Metadata = [:], file: String = #fileID, function: String = #function, line: Int = #line) {
    let logger = STLogManager.makeLogger(label: stDefaultLabel(from: file))
    logger.log(level: level, String(describing: message), metadata: metadata, persistent: true, file: file, function: function, line: line)
}
