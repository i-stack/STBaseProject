//
//  STLogOutput.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2019/03/16.
//

import Foundation

public func STLog<T>(
    _ message: T,
    level: STLogLevel = .info,
    file: String = #file,
    function: String = #function,
    line: Int = #line
) {
#if DEBUG
    let fileName = (file as NSString).lastPathComponent
    let formattedMessage = "\(level.rawValue): \(message)"
    let content = """

\(Date.currentString()) \(fileName)
funcName: \(function)
lineNum: (\(line))
level: \(level.rawValue)
message: \(formattedMessage)
"""
    print(content)
#endif
}

public func STPersistentLog<T>(
    _ message: T,
    level: STLogLevel = .info,
    file: String = #file,
    function: String = #function,
    line: Int = #line
) {
#if DEBUG
    let fileName = (file as NSString).lastPathComponent
    let formattedMessage = "\(level.rawValue): \(message)"
    let content = """

\(Date.currentString()) \(fileName)
funcName: \(function)
lineNum: (\(line))
level: \(level.rawValue)
message: \(formattedMessage)
"""
    print(content)
    STLogFileWriter.shared.append(content)
    NotificationCenter.default.post(
        name: NSNotification.Name(rawValue: STLogManager.queryNotificationName),
        object: content
    )
#endif
}
