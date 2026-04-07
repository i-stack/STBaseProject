//
//  STLogRecord.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2018/10/10.
//

import Foundation

public struct STLogRecord: Codable, Identifiable, Sendable {
    public typealias Metadata = [String: String]

    public let id: String
    public let timestamp: Date
    public let level: STLogLevel
    public let label: String
    public let message: String
    public let file: String
    public let function: String
    public let line: Int
    public let metadata: Metadata
    public let thread: String
    public let persistent: Bool

    public init(
        id: String = UUID().uuidString,
        timestamp: Date = Date(),
        level: STLogLevel,
        label: String,
        message: String,
        file: String,
        function: String,
        line: Int,
        metadata: Metadata = [:],
        thread: String = STLogRecord.threadDescription(),
        persistent: Bool
    ) {
        self.id = id
        self.timestamp = timestamp
        self.level = level
        self.label = label
        self.message = message
        self.file = file
        self.function = function
        self.line = line
        self.metadata = metadata
        self.thread = thread
        self.persistent = persistent
    }

    public var fileName: String {
        (file as NSString).lastPathComponent
    }

    public var searchableText: String {
        let values = self.metadata.sorted { $0.key < $1.key }.map { "\($0.key)=\($0.value)" }.joined(separator: " ")
        return [self.label, self.message, self.fileName, self.function, self.thread, values].joined(separator: " ").lowercased()
    }

    public func formatted(multiline: Bool = true) -> String {
        let metadataText = self.metadata
            .sorted { $0.key < $1.key }
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: ", ")

        let lines = [
            "\(self.timestamp.formatted("yyyy-MM-dd HH:mm:ss.SSS")) \(fileName)",
            "label: \(self.label)",
            "funcName: \(self.function)",
            "lineNum: (\(self.line))",
            "thread: \(self.thread)",
            "level: \(self.level.rawValue)",
            metadataText.isEmpty ? nil : "metadata: \(metadataText)",
            "message: \(self.message)"
        ].compactMap { $0 }

        return multiline ? lines.joined(separator: "\n") : lines.joined(separator: " | ")
    }

    func jsonLine(using encoder: JSONEncoder) -> String? {
        guard let data = try? encoder.encode(self),
              var line = String(data: data, encoding: .utf8) else {
            return nil
        }
        if !line.hasSuffix("\n") {
            line.append("\n")
        }
        return line
    }

    static func decode(from line: String, using decoder: JSONDecoder) -> STLogRecord? {
        guard let data = line.data(using: .utf8) else { return nil }
        return try? decoder.decode(STLogRecord.self, from: data)
    }

    public static func threadDescription() -> String {
        if Thread.isMainThread {
            return "main"
        }
        if let name = Thread.current.name, !name.isEmpty {
            return name
        }
        return "\(Unmanaged.passUnretained(Thread.current).toOpaque())"
    }
}
