//
//  STLogFileWriter.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2018/10/10.
//

import Foundation

final class STLogFileWriter {

    static let shared = STLogFileWriter()
    private let queue = DispatchQueue(label: "com.stbaseproject.logWriter", qos: .utility)
    
    private init() {}
    
    func append(_ content: String) {
        queue.async {
            self.write(content: content)
        }
    }
    
    private func write(content: String) {
        let path = STLogManager.logFilePath()
        let directory = (path as NSString).deletingLastPathComponent
        let status = STFileSystem.fileStatus(at: directory)
        if !status.exists {
            _ = STFileSystem.createFileIfNeeded(in: directory, fileName: (path as NSString).lastPathComponent)
        }
        
        guard let data = (content.hasSuffix("\n\n") ? content : "\(content)\n\n").data(using: .utf8) else {
            return
        }
        
        do {
            if FileManager.default.fileExists(atPath: path) {
                let handle = try FileHandle(forWritingTo: URL(fileURLWithPath: path))
                defer { handle.closeFile() }
                handle.seekToEndOfFile()
                handle.write(data)
            } else {
                try data.write(to: URL(fileURLWithPath: path), options: .atomic)
            }
        } catch {
            try? data.write(to: URL(fileURLWithPath: path), options: .atomic)
        }
    }
}