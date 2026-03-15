//
//  STDate.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2019/10/10.
//

import Foundation

private final class STDateFormatterCache {
    static let shared = STDateFormatterCache()

    private var formatters: [String: DateFormatter] = [:]
    private let queue = DispatchQueue(label: "com.stbase.dateformattercache", attributes: .concurrent)

    private init() {}

    func formatter(for format: String, timeZone: TimeZone? = nil, locale: Locale? = nil) -> DateFormatter {
        let key = "\(format)_\(timeZone?.identifier ?? "default")_\(locale?.identifier ?? "default")"
        return queue.sync {
            if let formatter = formatters[key] {
                return formatter
            }

            let formatter = DateFormatter()
            formatter.dateFormat = format
            formatter.timeZone = timeZone ?? .current
            formatter.locale = locale ?? .current

            queue.async(flags: .barrier) {
                self.formatters[key] = formatter
            }
            return formatter
        }
    }
}

public extension Date {
    static var currentTimestampMilliseconds: TimeInterval {
        Date().timeIntervalSince1970 * 1000
    }

    static var currentTimestampSeconds: TimeInterval {
        Date().timeIntervalSince1970
    }

    static func currentString(format: String = "yyyy-MM-dd HH:mm:ss") -> String {
        Date().formatted(format)
    }

    func formatted(_ format: String = "yyyy-MM-dd HH:mm:ss") -> String {
        STDateFormatterCache.shared.formatter(for: format).string(from: self)
    }

    var timestampMilliseconds: TimeInterval {
        timeIntervalSince1970 * 1000
    }

    var timestampSeconds: TimeInterval {
        timeIntervalSince1970
    }

    var year: Int { Calendar.current.component(.year, from: self) }
    var month: Int { Calendar.current.component(.month, from: self) }
    var day: Int { Calendar.current.component(.day, from: self) }
    var hour: Int { Calendar.current.component(.hour, from: self) }
    var minute: Int { Calendar.current.component(.minute, from: self) }
    var second: Int { Calendar.current.component(.second, from: self) }
    var weekday: Int { Calendar.current.component(.weekday, from: self) }
    var weekdayName: String { STDateFormatterCache.shared.formatter(for: "EEEE").string(from: self) }
    var monthName: String { STDateFormatterCache.shared.formatter(for: "MMMM").string(from: self) }
    var isToday: Bool { Calendar.current.isDateInToday(self) }
    var isYesterday: Bool { Calendar.current.isDateInYesterday(self) }
    var isTomorrow: Bool { Calendar.current.isDateInTomorrow(self) }

    func isSameYear(as date: Date) -> Bool {
        Calendar.current.isDate(self, equalTo: date, toGranularity: .year)
    }

    func isSameMonth(as date: Date) -> Bool {
        Calendar.current.isDate(self, equalTo: date, toGranularity: .month)
    }

    func isSameDay(as date: Date) -> Bool {
        Calendar.current.isDate(self, equalTo: date, toGranularity: .day)
    }

    func adding(years: Int) -> Date {
        Calendar.current.date(byAdding: .year, value: years, to: self) ?? self
    }

    func adding(months: Int) -> Date {
        Calendar.current.date(byAdding: .month, value: months, to: self) ?? self
    }

    func adding(days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }

    func adding(hours: Int) -> Date {
        Calendar.current.date(byAdding: .hour, value: hours, to: self) ?? self
    }

    func adding(minutes: Int) -> Date {
        Calendar.current.date(byAdding: .minute, value: minutes, to: self) ?? self
    }

    func adding(seconds: Int) -> Date {
        Calendar.current.date(byAdding: .second, value: seconds, to: self) ?? self
    }

    var startOfMonth: Date {
        let components = Calendar.current.dateComponents([.year, .month], from: self)
        return Calendar.current.date(from: components) ?? self
    }

    var endOfMonth: Date {
        startOfMonth.adding(months: 1).adding(days: -1)
    }

    var dayStart: Date {
        Calendar.current.startOfDay(for: self)
    }

    var dayEnd: Date {
        dayStart.adding(days: 1).addingTimeInterval(-1)
    }

    var relativeDescription: String {
        let interval = Date().timeIntervalSince(self)
        switch interval {
        case ..<60:
            return "刚刚"
        case ..<3600:
            return "\(Int(interval / 60))分钟前"
        case ..<86400:
            return "\(Int(interval / 3600))小时前"
        case ..<2592000:
            return "\(Int(interval / 86400))天前"
        case ..<31536000:
            return "\(Int(interval / 2592000))个月前"
        default:
            return "\(Int(interval / 31536000))年前"
        }
    }

    var smartDisplayString: String {
        if isToday {
            return formatted("HH:mm")
        } else if isYesterday {
            return "昨天 " + formatted("HH:mm")
        } else if isSameYear(as: Date()) {
            return formatted("MM-dd HH:mm")
        } else {
            return formatted("yyyy-MM-dd HH:mm")
        }
    }

    func dayCount(until date: Date) -> Int {
        Calendar.current.dateComponents([.day], from: dayStart, to: date.dayStart).day ?? 0
    }

    static func dates(from start: Date, to end: Date) -> [Date] {
        var dates: [Date] = []
        var current = start.dayStart
        let end = end.dayStart
        while current <= end {
            dates.append(current)
            current = current.adding(days: 1)
        }
        return dates
    }
}

public extension String {
    func date(using format: String = "yyyy-MM-dd HH:mm:ss") -> Date? {
        STDateFormatterCache.shared.formatter(for: format).date(from: self)
    }

    var smartDate: Date? {
        let formats = [
            "yyyy-MM-dd HH:mm:ss",
            "yyyy-MM-dd HH:mm",
            "yyyy-MM-dd",
            "yyyy/MM/dd HH:mm:ss",
            "yyyy/MM/dd HH:mm",
            "yyyy/MM/dd",
            "MM/dd/yyyy HH:mm:ss",
            "MM/dd/yyyy HH:mm",
            "MM/dd/yyyy",
            "dd/MM/yyyy HH:mm:ss",
            "dd/MM/yyyy HH:mm",
            "dd/MM/yyyy",
            "yyyy年MM月dd日 HH:mm:ss",
            "yyyy年MM月dd日 HH:mm",
            "yyyy年MM月dd日",
        ]

        if contains("T") && (contains("Z") || contains("+")) {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatter.date(from: self) {
                return date
            }
            formatter.formatOptions = [.withInternetDateTime]
            if let date = formatter.date(from: self) {
                return date
            }
        }

        for format in formats {
            if let date = date(using: format) {
                return date
            }
        }
        return nil
    }

    func formattedDateStringFromTimestamp(format: String = "yyyy-MM-dd HH:mm:ss") -> String {
        guard let date = timestampDate else { return "" }
        return date.formatted(format)
    }

    var timestampDate: Date? {
        guard !isEmpty else { return nil }
        return Date(timeIntervalSince1970: normalizedTimestamp)
    }

    func timestampMilliseconds(using format: String) -> TimeInterval {
        guard let date = date(using: format) else { return 0 }
        return date.timestampMilliseconds
    }

    var smartTimestampMilliseconds: TimeInterval {
        smartDate?.timestampMilliseconds ?? 0
    }

    func timeIntervalSince(_ date: Date) -> TimeInterval {
        abs(Date().timeIntervalSince(date))
    }

    func comparisonWithCurrentTimestamp() -> Int {
        guard let targetDate = timestampDate else { return 2 }
        switch Date().compare(targetDate) {
        case .orderedSame:
            return 0
        case .orderedAscending:
            return 1
        case .orderedDescending:
            return 2
        }
    }

    func comparisonWithCurrentTimestamp(component: Calendar.Component) -> Int {
        guard let targetDate = timestampDate else { return 2 }
        let calendar = Calendar.current
        let currentValue = calendar.component(component, from: Date())
        let targetValue = calendar.component(component, from: targetDate)
        if currentValue == targetValue {
            return 0
        } else if currentValue < targetValue {
            return 1
        } else {
            return 2
        }
    }
}

private extension String {
    var normalizedTimestamp: TimeInterval {
        guard !isEmpty else { return 0 }
        var timestamp = NSDecimalNumber(string: self).doubleValue
        let absoluteTimestamp = abs(Int64(timestamp))
        if String(absoluteTimestamp).count == 13 {
            timestamp /= 1000
        }
        return timestamp
    }
}
