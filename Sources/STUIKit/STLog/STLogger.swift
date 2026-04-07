//
//  STLogger.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2018/10/10.
//

import Foundation

public struct STLogger {
    public typealias Metadata = STLogRecord.Metadata

    public let label: String
    public var logLevel: STLogLevel
    public var metadata: Metadata

    public init(label: String, logLevel: STLogLevel? = nil, metadata: Metadata = [:]) {
        self.label = label
        self.logLevel = logLevel ?? STLogManager.configuration.minimumLevel
        self.metadata = metadata
    }

    public subscript(metadataKey key: String) -> String? {
        get { self.metadata[key] }
        set { self.metadata[key] = newValue }
    }

    public func log(level: STLogLevel, _ message: @autoclosure () -> Any, metadata extraMetadata: Metadata = [:], persistent: Bool = false, file: String = #fileID, function: String = #function, line: Int = #line) {
        guard level >= self.logLevel else { return }
        let mergedMetadata = self.metadata.merging(extraMetadata) { _, rhs in rhs }
        let record = STLogRecord(level: level, label: label, message: String(describing: message()), file: file, function: function, line: line, metadata: mergedMetadata, persistent: persistent)
        STLogManager.shared.log(record)
    }

    public func debug(_ message: @autoclosure () -> Any, metadata: Metadata = [:], persistent: Bool = false, file: String = #fileID, function: String = #function, line: Int = #line) {
        self.log(level: .debug, message(), metadata: metadata, persistent: persistent, file: file, function: function, line: line)
    }

    public func info(_ message: @autoclosure () -> Any, metadata: Metadata = [:], persistent: Bool = false, file: String = #fileID, function: String = #function, line: Int = #line) {
        self.log(level: .info, message(), metadata: metadata, persistent: persistent, file: file, function: function, line: line)
    }

    public func warning(_ message: @autoclosure () -> Any, metadata: Metadata = [:], persistent: Bool = false, file: String = #fileID, function: String = #function, line: Int = #line) {
        self.log(level: .warning, message(), metadata: metadata, persistent: persistent, file: file, function: function, line: line)
    }

    public func error(_ message: @autoclosure () -> Any, metadata: Metadata = [:], persistent: Bool = true, file: String = #fileID, function: String = #function, line: Int = #line) {
        self.log(level: .error, message(), metadata: metadata, persistent: persistent, file: file, function: function, line: line)
    }

    public func fatal(_ message: @autoclosure () -> Any, metadata: Metadata = [:], persistent: Bool = true, file: String = #fileID, function: String = #function, line: Int = #line) {
        self.log(level: .fatal, message(), metadata: metadata, persistent: persistent, file: file, function: function, line: line)
    }
}

extension STLogger {
    static let `default` = STLogger(label: "STBase")
}
