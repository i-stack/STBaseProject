//
//  STLogManager.swift
//  STBaseProject
//
//  Created by stack on 2018/10/10.
//

import Foundation

// MARK: - 日志管理器
public class STLogManager {
    
    private static let directoryName = "outputLog"
    private static let fileName = "log.txt"
    private static let notificationName = "com.notification.queryLog"
    
    /// 获取日志输出路径（若不存在则自动创建）
    public class func st_outputLogPath() -> String {
        let directory = "\(STFileManager.st_getLibraryCachePath())/\(directoryName)"
        let exists = STFileManager.st_fileExistAt(path: directory)
        if !exists.0 {
            _ = STFileManager.st_create(filePath: directory, fileName: fileName)
        }
        return "\(directory)/\(fileName)"
    }
    
    /// 获取日志查询通知名称
    public class func st_notificationQueryLogName() -> String {
        return notificationName
    }
}
