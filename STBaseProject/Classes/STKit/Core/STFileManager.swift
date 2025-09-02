//
//  STFileManager.swift
//  STBaseProject
//
//  Created by stack on 2018/10/10.
//

import UIKit
import Foundation

/// 文件管理器类，提供完整的文件操作功能
public class STFileManager: NSObject {
    
    // MARK: - 文件写入操作
    
    /// 写入内容到文件
    /// - Parameters:
    ///   - content: 要写入的内容
    ///   - filePath: 文件路径
    ///   - encoding: 编码格式，默认UTF8
    /// - Returns: 是否写入成功
    @discardableResult
    public static func st_writeToFile(content: String, filePath: String, encoding: String.Encoding = .utf8) -> Bool {
        let exist = st_fileExistAt(path: filePath)
        if exist.0 {
            if content.count > 0 {
                var originContent = st_readFromFile(filePath: filePath)
                if originContent.count < 1 {
                    originContent = content
                } else {
                    originContent = "\(originContent)\n\(content)"
                }
                if let data = originContent.data(using: encoding) {
                    do {
                        try data.write(to: URL(fileURLWithPath: filePath))
                        return true
                    } catch {
                        print("st_writeToFile Err: \(error.localizedDescription)")
                        return false
                    }
                }
            }
        }
        return false
    }
    
    /// 覆盖写入内容到文件
    /// - Parameters:
    ///   - content: 要写入的内容
    ///   - filePath: 文件路径
    ///   - encoding: 编码格式，默认UTF8
    /// - Returns: 是否写入成功
    @discardableResult
    public static func st_overwriteToFile(content: String, filePath: String, encoding: String.Encoding = .utf8) -> Bool {
        if let data = content.data(using: encoding) {
            do {
                try data.write(to: URL(fileURLWithPath: filePath))
                return true
            } catch {
                print("st_overwriteToFile Err: \(error.localizedDescription)")
                return false
            }
        }
        return false
    }
    
    /// 追加内容到文件末尾
    /// - Parameters:
    ///   - content: 要追加的内容
    ///   - filePath: 文件路径
    ///   - encoding: 编码格式，默认UTF8
    /// - Returns: 是否追加成功
    @discardableResult
    public static func st_appendToFile(content: String, filePath: String, encoding: String.Encoding = .utf8) -> Bool {
        let fileHandle = FileHandle(forWritingAtPath: filePath)
        if let handle = fileHandle {
            handle.seekToEndOfFile()
            if let data = content.data(using: encoding) {
                handle.write(data)
                handle.closeFile()
                return true
            }
            handle.closeFile()
        }
        return false
    }
    
    // MARK: - 文件读取操作
    
    /// 从文件读取内容
    /// - Parameters:
    ///   - filePath: 文件路径
    ///   - encoding: 编码格式，默认UTF8
    /// - Returns: 文件内容
    public static func st_readFromFile(filePath: String, encoding: String.Encoding = .utf8) -> String {
        var originContent = ""
        let exist = st_fileExistAt(path: filePath)
        if exist.0 {
            do {
                originContent = try String(contentsOfFile: filePath, encoding: encoding)
            } catch {
                print("st_readFromFile Err: \(error.localizedDescription)")
            }
        }
        return originContent
    }
    
    /// 从文件读取数据
    /// - Parameter filePath: 文件路径
    /// - Returns: 文件数据
    public static func st_readDataFromFile(filePath: String) -> Data? {
        let exist = st_fileExistAt(path: filePath)
        if exist.0 {
            do {
                return try Data(contentsOf: URL(fileURLWithPath: filePath))
            } catch {
                print("st_readDataFromFile Err: \(error.localizedDescription)")
            }
        }
        return nil
    }
    
    // MARK: - 路径获取
    
    /// 获取主目录路径
    /// - Returns: 主目录路径
    public static func st_getHomePath() -> String {
        return NSHomeDirectory()
    }

    /// 获取临时目录路径
    /// - Returns: 临时目录路径
    public static func st_getTmpPath() -> String {
        return NSTemporaryDirectory()
    }

    /// 获取文档目录路径
    /// - Returns: 文档目录路径
    public static func st_getDocumentsPath() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        return paths.first ?? ""
    }

    /// 获取库目录路径
    /// - Returns: 库目录路径
    public static func st_getLibraryPath() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true)
        return paths.first ?? ""
    }

    /// 获取缓存目录路径
    /// - Returns: 缓存目录路径
    public static func st_getLibraryCachePath() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)
        return paths.first ?? ""
    }
    
    /// 获取应用支持目录路径
    /// - Returns: 应用支持目录路径
    public static func st_getApplicationSupportPath() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true)
        return paths.first ?? ""
    }

    // MARK: - 文件状态检查
    
    /// 检查文件是否存在
    /// - Parameter path: 文件路径
    /// - Returns: (是否存在, 是否为目录)
    public static func st_fileExistAt(path: String) -> (Bool, Bool) {
        let fileManager = FileManager.default
        var isDirectory: ObjCBool = false
        let exist = fileManager.fileExists(atPath: path, isDirectory: &isDirectory)
        return (exist, isDirectory.boolValue)
    }
    
    /// 获取文件属性
    /// - Parameter path: 文件路径
    /// - Returns: 文件属性字典
    public static func st_getFileAttributes(path: String) -> [FileAttributeKey: Any]? {
        let fileManager = FileManager.default
        do {
            return try fileManager.attributesOfItem(atPath: path)
        } catch {
            print("st_getFileAttributes Err: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// 获取文件大小
    /// - Parameter path: 文件路径
    /// - Returns: 文件大小（字节）
    public static func st_getFileSize(path: String) -> Int64 {
        if let attributes = st_getFileAttributes(path: path),
           let fileSize = attributes[.size] as? Int64 {
            return fileSize
        }
        return 0
    }
    
    /// 获取文件创建时间
    /// - Parameter path: 文件路径
    /// - Returns: 创建时间
    public static func st_getFileCreationDate(path: String) -> Date? {
        if let attributes = st_getFileAttributes(path: path),
           let creationDate = attributes[.creationDate] as? Date {
            return creationDate
        }
        return nil
    }
    
    /// 获取文件修改时间
    /// - Parameter path: 文件路径
    /// - Returns: 修改时间
    public static func st_getFileModificationDate(path: String) -> Date? {
        if let attributes = st_getFileAttributes(path: path),
           let modificationDate = attributes[.modificationDate] as? Date {
            return modificationDate
        }
        return nil
    }

    // MARK: - 目录操作
    
    /// 创建目录
    /// - Parameter path: 目录路径
    /// - Returns: 是否创建成功
    @discardableResult
    public static func st_createDirectory(path: String) -> Bool {
        let fileManager = FileManager.default
        var isDirectory: ObjCBool = false
        let exist = fileManager.fileExists(atPath: path, isDirectory: &isDirectory)
        if !exist {
            do {
                try fileManager.createDirectory(at: URL(fileURLWithPath: path), withIntermediateDirectories: true, attributes: nil)
                return true
            } catch {
                print("st_createDirectory Err : \(error.localizedDescription)")
                return false
            }
        }
        return true
    }
    
    /// 创建文件
    /// - Parameters:
    ///   - filePath: 文件路径
    ///   - fileName: 文件名
    /// - Returns: 完整文件路径
    public static func st_create(filePath: String, fileName: String) -> String {
        st_createDirectory(path: filePath)
        let path = URL(fileURLWithPath: filePath).appendingPathComponent(fileName)
        let fileManager = FileManager.default
        let exist = st_fileExistAt(path: path.path)
        if !exist.0 {
            fileManager.createFile(atPath: path.path, contents: nil, attributes: nil)
        }
        return path.path
    }
    
    /// 创建临时文件
    /// - Parameter fileName: 文件名
    /// - Returns: 临时文件路径
    public static func st_createTempFile(fileName: String) -> String {
        let tempDir = st_getTmpPath()
        let tempPath = URL(fileURLWithPath: tempDir).appendingPathComponent(fileName)
        let fileManager = FileManager.default
        fileManager.createFile(atPath: tempPath.path, contents: nil, attributes: nil)
        return tempPath.path
    }

    // MARK: - 文件操作
    
    /// 复制文件
    /// - Parameters:
    ///   - atPath: 源文件路径
    ///   - toPath: 目标文件路径
    /// - Returns: 是否复制成功
    @discardableResult
    public static func st_copyItem(atPath: String, toPath: String) -> Bool {
        let fileManager = FileManager.default
        do {
            try fileManager.copyItem(atPath: atPath, toPath: toPath)
            return true
        } catch {
            print("st_copyItem Err : \(error.localizedDescription)")
            return false
        }
    }

    /// 移动文件
    /// - Parameters:
    ///   - atPath: 源文件路径
    ///   - toPath: 目标文件路径
    /// - Returns: 是否移动成功
    @discardableResult
    public static func st_moveItem(atPath: String, toPath: String) -> Bool {
        let fileManager = FileManager.default
        do {
            try fileManager.moveItem(atPath: atPath, toPath: toPath)
            return true
        } catch {
            print("st_moveItem Err : \(error.localizedDescription)")
            return false
        }
    }

    /// 删除文件
    /// - Parameter atPath: 文件路径
    /// - Returns: 是否删除成功
    @discardableResult
    public static func st_removeItem(atPath: String) -> Bool {
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: atPath) {
            do {
                try fileManager.removeItem(atPath: atPath)
                return true
            } catch {
                print("st_removeItem Err : \(error.localizedDescription)")
                return false
            }
        }
        return false
    }
    
    /// 清空目录内容
    /// - Parameter path: 目录路径
    /// - Returns: 是否清空成功
    @discardableResult
    public static func st_clearDirectory(path: String) -> Bool {
        let fileManager = FileManager.default
        do {
            let contents = try fileManager.contentsOfDirectory(atPath: path)
            for item in contents {
                let itemPath = URL(fileURLWithPath: path).appendingPathComponent(item).path
                try fileManager.removeItem(atPath: itemPath)
            }
            return true
        } catch {
            print("st_clearDirectory Err : \(error.localizedDescription)")
            return false
        }
    }

    /// 获取目录内容
    /// - Parameter atPath: 目录路径
    /// - Returns: 目录内容数组
    public static func st_getContentsOfDirectory(atPath: String) -> [String] {
        var contentArr: [String] = []
        let fileManager = FileManager.default
        do {
            contentArr = try fileManager.contentsOfDirectory(atPath: atPath)
        } catch {
            print("st_getContentsOfDirectory Err : \(error.localizedDescription)")
        }
        return contentArr
    }
    
    /// 获取目录内容（包含完整路径）
    /// - Parameter atPath: 目录路径
    /// - Returns: 完整路径数组
    public static func st_getFullPathsOfDirectory(atPath: String) -> [String] {
        let contents = st_getContentsOfDirectory(atPath: atPath)
        return contents.map { URL(fileURLWithPath: atPath).appendingPathComponent($0).path }
    }
    
    /// 获取目录大小
    /// - Parameter path: 目录路径
    /// - Returns: 目录大小（字节）
    public static func st_getDirectorySize(path: String) -> Int64 {
        var totalSize: Int64 = 0
        let fileManager = FileManager.default
        
        guard let enumerator = fileManager.enumerator(atPath: path) else { return 0 }
        
        while let fileName = enumerator.nextObject() as? String {
            let filePath = URL(fileURLWithPath: path).appendingPathComponent(fileName).path
            totalSize += st_getFileSize(path: filePath)
        }
        
        return totalSize
    }
    
    // MARK: - 文件类型检查
    
    /// 检查是否为图片文件
    /// - Parameter path: 文件路径
    /// - Returns: 是否为图片
    public static func st_isImageFile(path: String) -> Bool {
        let imageExtensions = ["jpg", "jpeg", "png", "gif", "bmp", "tiff", "webp"]
        let fileExtension = URL(fileURLWithPath: path).pathExtension.lowercased()
        return imageExtensions.contains(fileExtension)
    }
    
    /// 检查是否为视频文件
    /// - Parameter path: 文件路径
    /// - Returns: 是否为视频
    public static func st_isVideoFile(path: String) -> Bool {
        let videoExtensions = ["mp4", "mov", "avi", "mkv", "wmv", "flv", "webm", "m4v"]
        let fileExtension = URL(fileURLWithPath: path).pathExtension.lowercased()
        return videoExtensions.contains(fileExtension)
    }
    
    /// 检查是否为音频文件
    /// - Parameter path: 文件路径
    /// - Returns: 是否为音频
    public static func st_isAudioFile(path: String) -> Bool {
        let audioExtensions = ["mp3", "wav", "aac", "m4a", "flac", "ogg", "wma"]
        let fileExtension = URL(fileURLWithPath: path).pathExtension.lowercased()
        return audioExtensions.contains(fileExtension)
    }
    
    /// 检查是否为文档文件
    /// - Parameter path: 文件路径
    /// - Returns: 是否为文档
    public static func st_isDocumentFile(path: String) -> Bool {
        let documentExtensions = ["pdf", "doc", "docx", "txt", "rtf", "pages"]
        let fileExtension = URL(fileURLWithPath: path).pathExtension.lowercased()
        return documentExtensions.contains(fileExtension)
    }
    
    // MARK: - 日志相关
    
    /// 写入日志到文件
    public class func st_logWriteToFile() -> Void {
        let userDefault = UserDefaults.standard
        if let origintContent = userDefault.object(forKey: STFileManager.st_outputLogPath()) as? String {
            let path = STFileManager.st_create(filePath: "\(STFileManager.st_getLibraryCachePath())/outputLog", fileName: "log.txt")
            STFileManager.st_writeToFile(content: origintContent, filePath: path)
        }
    }
    
    /// 获取日志输出路径
    public class func st_outputLogPath() -> String {
        let outputPath = "\(STFileManager.st_getLibraryCachePath())/outputLog"
        let pathIsExist = STFileManager.st_fileExistAt(path: outputPath)
        if !pathIsExist.0 {
            let _ = STFileManager.st_create(filePath: outputPath, fileName: "log.txt")
        }
        return "\(outputPath)/log.txt"
    }
    
    // MARK: - 文件URL操作
    
    /// 从URL读取文件内容
    /// - Parameters:
    ///   - url: 文件URL
    ///   - encoding: 编码格式
    /// - Returns: 文件内容
    public static func st_readFromURL(url: URL, encoding: String.Encoding = .utf8) -> String? {
        do {
            return try String(contentsOf: url, encoding: encoding)
        } catch {
            print("st_readFromURL Err: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// 写入内容到URL
    /// - Parameters:
    ///   - content: 内容
    ///   - url: 目标URL
    ///   - encoding: 编码格式
    /// - Returns: 是否成功
    @discardableResult
    public static func st_writeToURL(content: String, url: URL, encoding: String.Encoding = .utf8) -> Bool {
        do {
            try content.write(to: url, atomically: true, encoding: encoding)
            return true
        } catch {
            print("st_writeToURL Err: \(error.localizedDescription)")
            return false
        }
    }
    
    // MARK: - 文件监控
    
    /// 监控文件变化
    /// - Parameters:
    ///   - path: 文件路径
    ///   - handler: 变化回调
    /// - Returns: 文件描述符
    public static func st_monitorFile(path: String, handler: @escaping (String) -> Void) -> DispatchSourceFileSystemObject? {
        let fileDescriptor = open(path, O_EVTONLY)
        if fileDescriptor == -1 { return nil }
        
        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: .write,
            queue: DispatchQueue.global()
        )
        
        source.setEventHandler {
            handler(path)
        }
        
        source.setCancelHandler {
            close(fileDescriptor)
        }
        
        source.resume()
        return source
    }
}

// MARK: - 日志函数

/// 调试日志输出
public func STLog<T>(_ message: T, file: String = #file, funcName: String = #function, lineNum: Int = #line) {
    #if DEBUG
    let file = (file as NSString).lastPathComponent
    let content = "\n\("".st_currentSystemTimestamp()) \(file)\nfuncName: \(funcName)\nlineNum: (\(lineNum))\nmessage: \(message)"
    print(content)
    #endif
}

/// 持久化日志输出
public func STLogP<T>(_ message: T, file: String = #file, funcName: String = #function, lineNum: Int = #line) {
    #if DEBUG
    let file = (file as NSString).lastPathComponent
    let content = "\n\("".st_currentSystemTimestamp()) \(file)\nfuncName: \(funcName)\nlineNum: (\(lineNum))\nmessage: \(message)"
    print(content)
    var allContent = ""
    let outputPath = STLogView.st_outputLogPath()
    let userDefault = UserDefaults.standard
    if let origintContent = userDefault.object(forKey: outputPath) as? String {
        allContent = "\(origintContent)\n\(content)"
    } else {
        allContent = content
    }
    userDefault.setValue(allContent, forKey: outputPath)
    userDefault.synchronize()
    NotificationCenter.default.post(name: NSNotification.Name(rawValue: STLogView.st_notificationQueryLogName()), object: content)
    #endif
}
