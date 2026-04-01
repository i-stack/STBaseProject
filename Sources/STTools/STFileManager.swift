//
//  STFileManager.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2018/10/10.
//

import Darwin
import Foundation

public enum STFileSystem {
    public static var homeDirectoryPath: String {
        NSHomeDirectory()
    }

    public static var temporaryDirectoryPath: String {
        NSTemporaryDirectory()
    }

    public static var documentsDirectoryPath: String {
        NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first ?? ""
    }

    public static var libraryDirectoryPath: String {
        NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).first ?? ""
    }

    public static var cachesDirectoryPath: String {
        NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first ?? ""
    }

    public static var applicationSupportDirectoryPath: String {
        NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true).first ?? ""
    }

    public static func appendLine(_ content: String, toFileAt path: String, encoding: String.Encoding = .utf8) -> Bool {
        guard fileStatus(at: path).exists else { return false }
        let existingContent = readString(fromFileAt: path, encoding: encoding)
        let updatedContent = existingContent.isEmpty ? content : "\(existingContent)\n\(content)"
        return overwriteFile(at: path, with: updatedContent, encoding: encoding)
    }

    @discardableResult
    public static func overwriteFile(at path: String, with content: String, encoding: String.Encoding = .utf8) -> Bool {
        guard let data = content.data(using: encoding) else { return false }
        do {
            try data.write(to: URL(fileURLWithPath: path))
            return true
        } catch {
            return false
        }
    }

    @discardableResult
    public static func appendContent(_ content: String, toFileAt path: String, encoding: String.Encoding = .utf8) -> Bool {
        guard let fileHandle = FileHandle(forWritingAtPath: path), let data = content.data(using: encoding) else {
            return false
        }
        fileHandle.seekToEndOfFile()
        fileHandle.write(data)
        fileHandle.closeFile()
        return true
    }

    public static func readString(fromFileAt path: String, encoding: String.Encoding = .utf8) -> String {
        guard fileStatus(at: path).exists else { return "" }
        return (try? String(contentsOfFile: path, encoding: encoding)) ?? ""
    }

    public static func readData(fromFileAt path: String) -> Data? {
        guard fileStatus(at: path).exists else { return nil }
        return try? Data(contentsOf: URL(fileURLWithPath: path))
    }

    public static func fileStatus(at path: String) -> (exists: Bool, isDirectory: Bool) {
        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory)
        return (exists, isDirectory.boolValue)
    }

    public static func attributes(ofItemAt path: String) -> [FileAttributeKey: Any]? {
        try? FileManager.default.attributesOfItem(atPath: path)
    }

    public static func fileSize(atPath path: String) -> Int64 {
        (attributes(ofItemAt: path)?[.size] as? Int64) ?? 0
    }

    public static func creationDate(atPath path: String) -> Date? {
        attributes(ofItemAt: path)?[.creationDate] as? Date
    }

    public static func modificationDate(atPath path: String) -> Date? {
        attributes(ofItemAt: path)?[.modificationDate] as? Date
    }

    @discardableResult
    public static func createDirectoryIfNeeded(at path: String) -> Bool {
        let status = fileStatus(at: path)
        guard !status.exists else { return true }
        do {
            try FileManager.default.createDirectory(at: URL(fileURLWithPath: path), withIntermediateDirectories: true)
            return true
        } catch {
            return false
        }
    }

    @discardableResult
    public static func createFileIfNeeded(in directoryPath: String, fileName: String) -> String {
        createDirectoryIfNeeded(at: directoryPath)
        let path = URL(fileURLWithPath: directoryPath).appendingPathComponent(fileName).path
        if !fileStatus(at: path).exists {
            FileManager.default.createFile(atPath: path, contents: nil)
        }
        return path
    }

    @discardableResult
    public static func createTemporaryFile(named fileName: String) -> String {
        let path = URL(fileURLWithPath: temporaryDirectoryPath).appendingPathComponent(fileName).path
        FileManager.default.createFile(atPath: path, contents: nil)
        return path
    }

    @discardableResult
    public static func copyItem(at sourcePath: String, to destinationPath: String) -> Bool {
        do {
            try FileManager.default.copyItem(atPath: sourcePath, toPath: destinationPath)
            return true
        } catch {
            return false
        }
    }

    @discardableResult
    public static func moveItem(at sourcePath: String, to destinationPath: String) -> Bool {
        do {
            try FileManager.default.moveItem(atPath: sourcePath, toPath: destinationPath)
            return true
        } catch {
            return false
        }
    }

    @discardableResult
    public static func removeItem(at path: String) -> Bool {
        guard FileManager.default.fileExists(atPath: path) else { return false }
        do {
            try FileManager.default.removeItem(atPath: path)
            return true
        } catch {
            return false
        }
    }

    @discardableResult
    public static func clearDirectory(at path: String) -> Bool {
        do {
            let contents = try FileManager.default.contentsOfDirectory(atPath: path)
            for item in contents {
                let itemPath = URL(fileURLWithPath: path).appendingPathComponent(item).path
                try FileManager.default.removeItem(atPath: itemPath)
            }
            return true
        } catch {
            return false
        }
    }

    public static func contentsOfDirectory(at path: String) -> [String] {
        (try? FileManager.default.contentsOfDirectory(atPath: path)) ?? []
    }

    public static func fullPathsOfDirectory(at path: String) -> [String] {
        contentsOfDirectory(at: path).map { URL(fileURLWithPath: path).appendingPathComponent($0).path }
    }

    public static func directorySize(at path: String) -> Int64 {
        var totalSize: Int64 = 0
        guard let enumerator = FileManager.default.enumerator(atPath: path) else { return 0 }
        while let fileName = enumerator.nextObject() as? String {
            let filePath = URL(fileURLWithPath: path).appendingPathComponent(fileName).path
            totalSize += fileSize(atPath: filePath)
        }
        return totalSize
    }

    public static func isImageFile(at path: String) -> Bool {
        ["jpg", "jpeg", "png", "gif", "bmp", "tiff", "webp"].contains(URL(fileURLWithPath: path).pathExtension.lowercased())
    }

    public static func isVideoFile(at path: String) -> Bool {
        ["mp4", "mov", "avi", "mkv", "wmv", "flv", "webm", "m4v"].contains(URL(fileURLWithPath: path).pathExtension.lowercased())
    }

    public static func isAudioFile(at path: String) -> Bool {
        ["mp3", "wav", "aac", "m4a", "flac", "ogg", "wma"].contains(URL(fileURLWithPath: path).pathExtension.lowercased())
    }

    public static func isDocumentFile(at path: String) -> Bool {
        ["pdf", "doc", "docx", "txt", "rtf", "pages"].contains(URL(fileURLWithPath: path).pathExtension.lowercased())
    }

    public static func readString(from url: URL, encoding: String.Encoding = .utf8) -> String? {
        try? String(contentsOf: url, encoding: encoding)
    }

    @discardableResult
    public static func write(_ content: String, to url: URL, encoding: String.Encoding = .utf8) -> Bool {
        do {
            try content.write(to: url, atomically: true, encoding: encoding)
            return true
        } catch {
            return false
        }
    }

    public static func monitorFile(at path: String, handler: @escaping (String) -> Void) -> DispatchSourceFileSystemObject? {
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
