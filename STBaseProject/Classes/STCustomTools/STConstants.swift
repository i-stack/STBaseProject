//
//  STConstants.swift
//  STBaseProject
//
//  Created by stack on 2019/03/16.
//

import UIKit
import Foundation

public class STConstants: NSObject {
    
    public static let shared: STConstants = STConstants()
    
    public class func st_outputLogPath() -> String {
        let outputPath = "\(STFileManager.getLibraryCachePath())/outputLog"
        let pathIsExist = STFileManager.fileExistAt(path: outputPath)
        if !pathIsExist.0 {
            let _ = STFileManager.create(filePath: outputPath, fileName: "log.txt")
        }
        return "\(outputPath)/log.txt"
    }
    
    public class func st_notificationQueryLogName() -> String {
        return "com.notification.queryLog"
    }
}

/// 在DEBUG模式下打印到控制台
public func STLog<T>(_ message: T, file: String = #file, funcName: String = #function, lineNum: Int = #line) {
    #if DEBUG
    let file = (file as NSString).lastPathComponent
    let content = "\n\("".st_currentSystemTimestamp()) \(file)\nfuncName: \(funcName)\nlineNum: (\(lineNum))\nmessage: \(message)"
    print(content)
    #endif
}

/// 在DEBUG模式下打印到控制台并保存日志
public func STLogP<T>(_ message: T, file: String = #file, funcName: String = #function, lineNum: Int = #line) {
    #if DEBUG
    let file = (file as NSString).lastPathComponent
    let content = "\n\("".st_currentSystemTimestamp()) \(file)\nfuncName: \(funcName)\nlineNum: (\(lineNum))\nmessage: \(message)"
    print(content)
    var allContent = ""
    let outputPath = STConstants.st_outputLogPath()
    let userDefault = UserDefaults.standard
    if let origintContent = userDefault.object(forKey: outputPath) as? String {
        allContent = "\(origintContent)\n\(content)"
    } else {
        allContent = content
    }
    userDefault.setValue(allContent, forKey: outputPath)
    userDefault.synchronize()
    NotificationCenter.default.post(name: NSNotification.Name(rawValue: STConstants.st_notificationQueryLogName()), object: content)
    #endif
}
