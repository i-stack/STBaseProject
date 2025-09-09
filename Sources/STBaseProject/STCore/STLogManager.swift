//
//  STLogManager.swift
//  STBaseProject
//
//  Created by stack on 2024/01/01.
//

import Foundation

// MARK: - 日志管理器
public class STLogManager {
    
    /// 获取日志输出路径
    public class func st_outputLogPath() -> String {
        return "STLogView_outputLogPath"
    }
    
    /// 获取日志查询通知名称
    public class func st_notificationQueryLogName() -> String {
        return "STLogView_notificationQueryLogName"
    }
}
