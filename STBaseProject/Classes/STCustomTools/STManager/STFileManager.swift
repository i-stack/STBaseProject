//
//  STFileManager.swift
//  STBaseProject
//
//  Created by stack on 2018/10/10.
//

import UIKit

public class STFileManager: NSObject {
    
    public static func writeToFile(content: String, filePath: String) {
        let exist = self.fileExistAt(path: filePath)
        if exist.0 {
            if content.count > 0 {
                var originContent = self.readFromFile(filePath: filePath)
                if originContent.count < 1 {
                    originContent = content
                } else {
                    originContent = "\(originContent)\n\(content)"
                }
                if let data = originContent.data(using: .utf8) {
                    do {
                        try data.write(to: URL.init(fileURLWithPath: filePath))
                    } catch {
                        print("writeToFile Err: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    public static func readFromFile(filePath: String) -> String {
        var originContent = ""
        let exist = self.fileExistAt(path: filePath)
        if exist.0 {
            do {
                originContent = try String.init(contentsOfFile: filePath)
            } catch {
                print("readFromFile Err: \(error.localizedDescription)")
            }
        }
        return originContent
    }
    
    public static func getHomePath() -> String {
        return NSHomeDirectory()
    }

    public static func getTmpPath() -> String {
        return NSTemporaryDirectory()
    }

    public static func getDocumentsPath() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }

    public static func getLibraryPath() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }

    public static func getLibraryCachePath() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }

    public static func fileExistAt(path: String) -> (Bool, Bool) {
        let fileManager = FileManager.default
        var isDirectory: ObjCBool = false
        let exist = fileManager.fileExists(atPath: path, isDirectory: &isDirectory)
        return (exist, isDirectory.boolValue)
    }

    public static func createDirectory(path: String) -> Void {
        let fileManager = FileManager.default
        var isDirectory: ObjCBool = false
        let exist = fileManager.fileExists(atPath: path, isDirectory: &isDirectory)
        if !exist {
            do {
                try fileManager.createDirectory(at: URL.init(fileURLWithPath: path), withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("createDirectory Err : \(error.localizedDescription)")
            }
        }
    }
    
    public static func create(filePath: String, fileName: String) -> String {
        self.createDirectory(path: filePath)
        if let pathURL = URL(string: filePath) {
            let path = pathURL.appendingPathComponent(fileName)
            let fileManager = FileManager.default
            let exist = self.fileExistAt(path: path.absoluteString)
            if !exist.0 {
                fileManager.createFile(atPath: path.absoluteString, contents: nil, attributes: nil)
            }
            return path.absoluteString
        }
        return ""
    }

    public static func copyItem(atPath: String, toPath: String) {
        let fileManager = FileManager.default
        do {
            try fileManager.copyItem(atPath: atPath, toPath: toPath)
        } catch {
            print("copyItem Err : \(error.localizedDescription)")
        }
    }

    public static func moveItem(atPath: String, toPath: String) {
        let fileManager = FileManager.default
        do {
            try fileManager.moveItem(atPath: atPath, toPath: toPath)
        } catch {
            print("moveItem Err : \(error.localizedDescription)")
        }
    }

    public static func removeItem(atPath: String) {
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: atPath) {
            do {
                try fileManager.removeItem(atPath: atPath)
            } catch {
                print("removeItem Err : \(error.localizedDescription)")
            }
        }
    }

    public static func getContentsOfDirectory(atPath: String) -> Array<String> {
        var contentArr: [String] = [String]()
        let fileManager = FileManager.default
        do {
            contentArr = try fileManager.contentsOfDirectory(atPath: atPath)
        } catch {
            print("getContentsOfDirectory Err : \(error.localizedDescription)")
        }
        return contentArr
    }
    
    public class func st_logWriteToFile() -> Void {
        let userDefault = UserDefaults.standard
        if let origintContent = userDefault.object(forKey: STFileManager.st_outputLogPath()) as? String {
            let path = STFileManager.create(filePath: "\(STFileManager.getLibraryCachePath())/outputLog", fileName: "log.txt")
            STFileManager.writeToFile(content: origintContent, filePath: path)
        }
    }
    
    public class func st_outputLogPath() -> String {
        let outputPath = "\(STFileManager.getLibraryCachePath())/outputLog"
        let pathIsExist = STFileManager.fileExistAt(path: outputPath)
        if !pathIsExist.0 {
            let _ = STFileManager.create(filePath: outputPath, fileName: "log.txt")
        }
        return "\(outputPath)/log.txt"
    }
}

public func STLog<T>(_ message: T, file: String = #file, funcName: String = #function, lineNum: Int = #line) {
    #if DEBUG
    let file = (file as NSString).lastPathComponent
    let content = "\n\("".st_currentSystemTimestamp()) \(file)\nfuncName: \(funcName)\nlineNum: (\(lineNum))\nmessage: \(message)"
    print(content)
    #endif
}

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
