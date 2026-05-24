//
//  STMarkdownMalformedTableNormalizer.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2019/03/16.
//

import Foundation

public enum STMarkdownMalformedTableNormalizer: Sendable {

    /// 按开关对输入做表格规整；`enabled == false` 时原样返回。
    public static func normalize(_ markdown: String, enabled: Bool) -> String {
        guard enabled, markdown.isEmpty == false else { return markdown }
        return self.normalize(markdown)
    }

    public static func normalize(_ markdown: String) -> String {
        let lines = markdown.components(separatedBy: .newlines)
        guard lines.count > 2 else { return markdown }

        var normalized: [String] = []
        var index = 0
        var activeFenceMarker: Character?

        while index < lines.count {
            let line = lines[index]

            if let fenceMarker = self.codeFenceMarker(in: line) {
                if activeFenceMarker == nil {
                    activeFenceMarker = fenceMarker
                } else if activeFenceMarker == fenceMarker {
                    activeFenceMarker = nil
                }
                normalized.append(line)
                index += 1
                continue
            }

            if activeFenceMarker != nil {
                normalized.append(line)
                index += 1
                continue
            }

            if index + 1 < lines.count,
               self.isLikelyTableRow(lines[index]),
               self.isTableSeparatorRow(lines[index + 1]) {
                normalized.append(lines[index])
                normalized.append(lines[index + 1])
                index += 2

                while index < lines.count {
                    let currentLine = lines[index]
                    let trimmed = currentLine.trimmingCharacters(in: .whitespaces)

                    if self.isStandalonePipeLine(trimmed) {
                        index += 1
                        continue
                    }

                    if trimmed.isEmpty {
                        if let nextNonEmpty = self.nextNonEmptyLineIndex(in: lines, from: index + 1),
                           self.isLikelyTableRow(lines[nextNonEmpty]) {
                            // 仅吞掉「表内误插空行」：若空行后是「表头 + 分隔行」起点，说明是新 GFM 表，保留空行以免与上一张表粘成一块。
                            let nextLineStartsNewGFMTable = nextNonEmpty + 1 < lines.count
                                && self.isTableSeparatorRow(lines[nextNonEmpty + 1])
                            if !nextLineStartsNewGFMTable {
                                index += 1
                                continue
                            }
                        }
                        normalized.append(currentLine)
                        index += 1
                        break
                    }

                    if self.isLikelyTableRow(currentLine) {
                        normalized.append(currentLine)
                        index += 1
                        continue
                    }

                    normalized.append(currentLine)
                    index += 1
                    break
                }
                continue
            }

            normalized.append(line)
            index += 1
        }

        return normalized.joined(separator: "\n")
    }

    // MARK: - Line predicates

    private static func codeFenceMarker(in line: String) -> Character? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard let first = trimmed.first, first == "`" || first == "~" else { return nil }
        let fenceCount = trimmed.prefix { $0 == first }.count
        return fenceCount >= 3 ? first : nil
    }

    private static func isLikelyTableRow(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard trimmed.isEmpty == false, trimmed.contains("|") else { return false }

        let cells = trimmed
            .split(separator: "|", omittingEmptySubsequences: false)
            .map { $0.trimmingCharacters(in: .whitespaces) }
        let nonEmptyCellCount = cells.filter { $0.isEmpty == false }.count
        return nonEmptyCellCount >= 2
    }

    private static func isTableSeparatorRow(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard trimmed.contains("|") else { return false }

        let cells = trimmed
            .split(separator: "|", omittingEmptySubsequences: false)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { $0.isEmpty == false }

        guard cells.count >= 2 else { return false }
        return cells.allSatisfy { self.isTableSeparatorCell($0) }
    }

    private static func isTableSeparatorCell(_ cell: String) -> Bool {
        let stripped = cell.trimmingCharacters(in: CharacterSet(charactersIn: ":"))
        guard stripped.count >= 3 else { return false }
        return stripped.allSatisfy { $0 == "-" }
    }

    private static func isStandalonePipeLine(_ trimmedLine: String) -> Bool {
        guard trimmedLine.isEmpty == false, trimmedLine.contains("|") else { return false }
        return trimmedLine.allSatisfy { $0 == "|" || $0.isWhitespace }
    }

    private static func nextNonEmptyLineIndex(in lines: [String], from start: Int) -> Int? {
        guard start < lines.count else { return nil }
        for idx in start..<lines.count {
            if lines[idx].trimmingCharacters(in: .whitespaces).isEmpty == false {
                return idx
            }
        }
        return nil
    }
}
