//
//  STLogManager.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2018/10/10.
//

import Foundation

// MARK: - 日志管理器
public class STLogManager {
    
    private static let directoryName = "outputLog"
    private static let fileName = "log.txt"
    public static let queryNotificationName = "com.notification.queryLog"

    /// 获取日志输出路径（若不存在则自动创建）
    public class func logFilePath() -> String {
        let directory = "\(STFileSystem.cachesDirectoryPath)/\(directoryName)"
        let exists = STFileSystem.fileStatus(at: directory)
        if !exists.exists {
            _ = STFileSystem.createFileIfNeeded(in: directory, fileName: fileName)
        }
        return "\(directory)/\(fileName)"
    }
}
