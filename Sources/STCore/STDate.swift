//
//  STDate.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2019/10/10.
//

import UIKit
import Foundation

// MARK: - Date Extensions
public extension Date {
    
    /// 获取当前时间戳（毫秒）
    static var st_currentTimestamp: TimeInterval {
        return Date().timeIntervalSince1970 * 1000
    }
    
    /// 获取当前时间戳（秒）
    static var st_currentTimestampInSeconds: TimeInterval {
        return Date().timeIntervalSince1970
    }
    
    /// 转换为指定格式的字符串
    func st_toString(format: String = "yyyy-MM-dd HH:mm:ss") -> String {
        let formatter = STDateManager.shared.getFormatter(for: format)
        return formatter.string(from: self)
    }
    
    /// 转换为时间戳（毫秒）
    var st_timestamp: TimeInterval {
        return timeIntervalSince1970 * 1000
    }
    
    /// 转换为时间戳（秒）
    var st_timestampInSeconds: TimeInterval {
        return timeIntervalSince1970
    }
    
    /// 获取年份
    var st_year: Int {
        return Calendar.current.component(.year, from: self)
    }
    
    /// 获取月份
    var st_month: Int {
        return Calendar.current.component(.month, from: self)
    }
    
    /// 获取日期
    var st_day: Int {
        return Calendar.current.component(.day, from: self)
    }
    
    /// 获取小时
    var st_hour: Int {
        return Calendar.current.component(.hour, from: self)
    }
    
    /// 获取分钟
    var st_minute: Int {
        return Calendar.current.component(.minute, from: self)
    }
    
    /// 获取秒
    var st_second: Int {
        return Calendar.current.component(.second, from: self)
    }
    
    /// 获取星期几（1-7，1为周日）
    var st_weekday: Int {
        return Calendar.current.component(.weekday, from: self)
    }
    
    /// 获取星期几的名称
    var st_weekdayName: String {
        let formatter = STDateManager.shared.getWeekdayFormatter()
        return formatter.string(from: self)
    }
    
    /// 获取月份名称
    var st_monthName: String {
        let formatter = STDateManager.shared.getMonthFormatter()
        return formatter.string(from: self)
    }
    
    /// 是否是今天
    var st_isToday: Bool {
        return Calendar.current.isDateInToday(self)
    }
    
    /// 是否是昨天
    var st_isYesterday: Bool {
        return Calendar.current.isDateInYesterday(self)
    }
    
    /// 是否是明天
    var st_isTomorrow: Bool {
        return Calendar.current.isDateInTomorrow(self)
    }
    
    /// 是否是同一年
    func st_isSameYear(as date: Date) -> Bool {
        return Calendar.current.isDate(self, equalTo: date, toGranularity: .year)
    }
    
    /// 是否是同一月
    func st_isSameMonth(as date: Date) -> Bool {
        return Calendar.current.isDate(self, equalTo: date, toGranularity: .month)
    }
    
    /// 是否是同一天
    func st_isSameDay(as date: Date) -> Bool {
        return Calendar.current.isDate(self, equalTo: date, toGranularity: .day)
    }
    
    /// 添加年数
    func st_addingYears(_ years: Int) -> Date {
        return Calendar.current.date(byAdding: .year, value: years, to: self) ?? self
    }
    
    /// 添加月数
    func st_addingMonths(_ months: Int) -> Date {
        return Calendar.current.date(byAdding: .month, value: months, to: self) ?? self
    }
    
    /// 添加天数
    func st_addingDays(_ days: Int) -> Date {
        return Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }
    
    /// 添加小时
    func st_addingHours(_ hours: Int) -> Date {
        return Calendar.current.date(byAdding: .hour, value: hours, to: self) ?? self
    }
    
    /// 添加分钟
    func st_addingMinutes(_ minutes: Int) -> Date {
        return Calendar.current.date(byAdding: .minute, value: minutes, to: self) ?? self
    }
    
    /// 添加秒数
    func st_addingSeconds(_ seconds: Int) -> Date {
        return Calendar.current.date(byAdding: .second, value: seconds, to: self) ?? self
    }
    
    /// 获取当月第一天
    var st_startOfMonth: Date {
        let components = Calendar.current.dateComponents([.year, .month], from: self)
        return Calendar.current.date(from: components) ?? self
    }
    
    /// 获取当月最后一天
    var st_endOfMonth: Date {
        let nextMonth = st_startOfMonth.st_addingMonths(1)
        return nextMonth.st_addingDays(-1)
    }
    
    /// 获取当天开始时间（00:00:00）
    var st_startOfDay: Date {
        return Calendar.current.startOfDay(for: self)
    }
    
    /// 获取当天结束时间（23:59:59）
    var st_endOfDay: Date {
        let startOfDay = self.st_startOfDay
        return startOfDay.st_addingDays(1).addingTimeInterval(-1)
    }
    
    /// 距离当前时间的相对描述
    var st_relativeString: String {
        let now = Date()
        let timeInterval = now.timeIntervalSince(self)
        
        if timeInterval < 60 {
            return "刚刚"
        } else if timeInterval < 3600 {
            let minutes = Int(timeInterval / 60)
            return "\(minutes)分钟前"
        } else if timeInterval < 86400 {
            let hours = Int(timeInterval / 3600)
            return "\(hours)小时前"
        } else if timeInterval < 2592000 {
            let days = Int(timeInterval / 86400)
            return "\(days)天前"
        } else if timeInterval < 31536000 {
            let months = Int(timeInterval / 2592000)
            return "\(months)个月前"
        } else {
            let years = Int(timeInterval / 31536000)
            return "\(years)年前"
        }
    }
    
    /// 智能时间显示（今天显示时间，昨天显示昨天，其他显示日期）
    var st_smartTimeString: String {
        if st_isToday {
            return st_toString(format: "HH:mm")
        } else if st_isYesterday {
            return "昨天 " + st_toString(format: "HH:mm")
        } else if st_isSameYear(as: Date()) {
            return st_toString(format: "MM-dd HH:mm")
        } else {
            return st_toString(format: "yyyy-MM-dd HH:mm")
        }
    }
    
    /// 获取两个日期之间的天数差
    func st_daysBetween(_ date: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: self.st_startOfDay, to: date.st_startOfDay)
        return components.day ?? 0
    }
    
    /// 生成指定范围内的日期数组
    static func st_datesBetween(start: Date, end: Date) -> [Date] {
        var dates: [Date] = []
        var currentDate = start.st_startOfDay
        let endDate = end.st_startOfDay
        
        while currentDate <= endDate {
            dates.append(currentDate)
            currentDate = currentDate.st_addingDays(1)
        }
        
        return dates
    }
}

// MARK: - STDateManager
public class STDateManager {
    public static let shared = STDateManager()
    
    private var formatters: [String: DateFormatter] = [:]
    private let queue = DispatchQueue(label: "com.stbase.datemanager", attributes: .concurrent)
    
    private init() {}
    
    /// 获取格式化器（缓存复用）
    func getFormatter(for format: String, timeZone: TimeZone? = nil, locale: Locale? = nil) -> DateFormatter {
        let key = "\(format)_\(timeZone?.identifier ?? "default")_\(locale?.identifier ?? "default")"
        
        return queue.sync {
            if let formatter = formatters[key] {
                return formatter
            }
            
            let formatter = DateFormatter()
            formatter.dateFormat = format
            formatter.timeZone = timeZone ?? TimeZone.current
            formatter.locale = locale ?? Locale.current
            
            queue.async(flags: .barrier) {
                self.formatters[key] = formatter
            }
            
            return formatter
        }
    }
    
    /// 获取星期几格式化器
    func getWeekdayFormatter() -> DateFormatter {
        return getFormatter(for: "EEEE")
    }
    
    /// 获取月份格式化器
    func getMonthFormatter() -> DateFormatter {
        return getFormatter(for: "MMMM")
    }
    
    /// 清除缓存的格式化器
    public func clearCache() {
        queue.async(flags: .barrier) {
            self.formatters.removeAll()
        }
    }
}

// MARK: - String Date Extensions
public extension String {
    
    /// 获取当前系统时间戳字符串
    ///
    /// - Returns: yyyy-MM-dd HH:mm:ss
    ///
    func st_currentSystemTimestamp() -> String {
        return st_currentSystemTimestamp(dateFormat: "yyyy-MM-dd HH:mm:ss")
    }
    
    /// 获取当前系统时间戳字符串
    ///
    /// - Parameter dateFormat: 自定义时间格式，如：yyyy-MM-dd HH:mm:ss
    /// - Returns: 格式化后的时间字符串，如：2018-06-20 12:00:00
    ///
    func st_currentSystemTimestamp(dateFormat: String) -> String {
        let formatter = STDateManager.shared.getFormatter(for: dateFormat)
        return formatter.string(from: Date())
    }
    
    /// 从字符串创建Date对象
    /// - Parameter format: 时间格式
    /// - Returns: Date对象，失败返回nil
    func st_toDate(format: String = "yyyy-MM-dd HH:mm:ss") -> Date? {
        let formatter = STDateManager.shared.getFormatter(for: format)
        return formatter.date(from: self)
    }
    
    /// 支持多种常见格式的日期转换
    var st_smartToDate: Date? {
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
            "ISO8601"
        ]
        
        // 特殊处理ISO8601格式
        if self.contains("T") && (self.contains("Z") || self.contains("+")) {
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
        
        // 尝试其他格式
        for format in formats {
            if let date = st_toDate(format: format) {
                return date
            }
        }
        
        return nil
    }
    
    /// 时间戳转换为时间字符串
    ///
    /// 默认时间格式: yyyy-MM-dd HH:mm:ss
    ///
    /// - Returns: 2018-06-20 12:00:00
    ///
    func st_timestampToStr() -> String {
        return st_timestampToStr(dateFormat: "yyyy-MM-dd HH:mm:ss")
    }
    
    /// 时间戳转换为时间字符串
    /// - Parameter dateFormat: 时间格式
    /// - Returns: 格式化后的时间字符串
    func st_timestampToStr(dateFormat: String) -> String {
        guard !self.isEmpty else { return "" }
        
        let timeStamp = self.st_normalizedTimestamp()
        let formatter = STDateManager.shared.getFormatter(for: dateFormat)
        let date = Date(timeIntervalSince1970: timeStamp)
        return formatter.string(from: date)
    }
    
    /// 时间戳转换为Date对象
    func st_timestampToDate() -> Date? {
        guard !self.isEmpty else { return nil }
        
        let timeStamp = self.st_normalizedTimestamp()
        return Date(timeIntervalSince1970: timeStamp)
    }
    
    /// 时间字符串转换为时间戳
    ///
    /// - Parameter dateFormat: 自定义时间格式，如：yyyy-MM-dd HH:mm:ss
    /// - Returns: 时间戳（毫秒）
    ///
    func st_timeTotimestamp(dateFormat: String) -> TimeInterval {
        guard !self.isEmpty else { return 0 }
        
        let formatter = STDateManager.shared.getFormatter(for: dateFormat)
        guard let date = formatter.date(from: self) else { return 0 }
        
        return date.timeIntervalSince1970 * 1000.0
    }
    
    /// 智能时间字符串转时间戳（支持多种格式）
    var st_smartTimestamp: TimeInterval {
        guard let date = st_smartToDate else { return 0 }
        return date.timeIntervalSince1970 * 1000.0
    }
    
    /// 标准化时间戳（处理秒和毫秒）
    private func st_normalizedTimestamp() -> TimeInterval {
        guard !self.isEmpty else { return 0 }
        
        var timeStamp = NSDecimalNumber(string: self).doubleValue
        let stamp = abs(Int64(timeStamp))
        
        // 如果是13位数字，说明是毫秒时间戳，需要转换为秒
        if String(stamp).count == 13 {
            timeStamp = timeStamp / 1000.0
        }
        
        return timeStamp
    }
    
    /// 比较给定日期与当前时间的时间差，返回秒数差值
    func st_timeDifference(date: Date) -> TimeInterval {
        let localDate = Date()
        return abs(localDate.timeIntervalSince(date))
    }
    
    /// 比较给定的时间戳字符串日期与当前日期的年份
    ///
    /// - Returns:
    ///     - 0: 相同
    ///     - 1: 大于当前日期
    ///     - 2: 小于当前日期
    ///
    func st_compareYearWithCurrentDate() -> Int {
        return st_compareWithCurrentDate(component: .year)
    }
    
    /// 比较给定的时间戳字符串日期与当前日期的月份
    ///
    /// - Returns:
    ///     - 0: 相同
    ///     - 1: 大于当前日期
    ///     - 2: 小于当前日期
    ///
    func st_compareMonthWithCurrentDate() -> Int {
        return st_compareWithCurrentDate(component: .month)
    }
    
    /// 比较给定的时间戳字符串日期与当前日期的日期
    ///
    /// - Returns:
    ///     - 0: 相同
    ///     - 1: 大于当前日期
    ///     - 2: 小于当前日期
    ///
    func st_compareDayWithCurrentDate() -> Int {
        return st_compareWithCurrentDate(component: .day)
    }
    
    /// 比较给定的时间戳字符串日期与当前日期的小时
    ///
    /// - Returns:
    ///     - 0: 相同
    ///     - 1: 大于当前日期
    ///     - 2: 小于当前日期
    ///
    func st_compareHourWithCurrentDate() -> Int {
        return st_compareWithCurrentDate(component: .hour)
    }
    
    /// 比较给定的时间戳字符串日期与当前日期的分钟
    ///
    /// - Returns:
    ///     - 0: 相同
    ///     - 1: 大于当前日期
    ///     - 2: 小于当前日期
    ///
    func st_compareMinuteWithCurrentDate() -> Int {
        return st_compareWithCurrentDate(component: .minute)
    }
    
    /// 比较给定的时间戳字符串日期与当前日期的秒数
    ///
    /// - Returns:
    ///     - 0: 相同
    ///     - 1: 大于当前日期
    ///     - 2: 小于当前日期
    ///
    func st_compareSecondWithCurrentDate() -> Int {
        return st_compareWithCurrentDate(component: .second)
    }
    
    /// 比较时间戳字符串对应的日期与当前日期
    ///
    /// - Returns:
    ///     - 0: 相同
    ///     - 1: 大于当前日期
    ///     - 2: 小于当前日期
    ///
    func st_compareWithCurrentDate() -> Int {
        guard let originDate = self.st_timestampToDate() else { return 2 }
        
        let currentDate = Date()
        let result = currentDate.compare(originDate)
        
        switch result {
        case .orderedSame:
            return 0
        case .orderedAscending:
            return 1
        case .orderedDescending:
            return 2
        }
    }
    
    /// 私有方法：比较指定组件
    private func st_compareWithCurrentDate(component: Calendar.Component) -> Int {
        guard let originDate = self.st_timestampToDate() else { return 2 }
        
        let currentDate = Date()
        let calendar = Calendar.current
        let current = calendar.component(component, from: currentDate)
        let origin = calendar.component(component, from: originDate)
        
        if current == origin {
            return 0
        } else if current < origin {
            return 1
        } else {
            return 2
        }
    }
    
    /// 获取指定日期的年份（静态方法，兼容性保留）
    static func st_year(date: Date) -> Int {
        return date.st_year
    }
    
    /// 获取指定日期的月份（静态方法，兼容性保留）
    static func st_month(date: Date) -> Int {
        return date.st_month
    }
    
    /// 获取指定日期的日期（静态方法，兼容性保留）
    static func st_day(date: Date) -> Int {
        return date.st_day
    }
    
    /// 获取指定日期的小时（静态方法，兼容性保留）
    static func st_hour(date: Date) -> Int {
        return date.st_hour
    }
    
    /// 获取指定日期的分钟（静态方法，兼容性保留）
    static func st_minute(date: Date) -> Int {
        return date.st_minute
    }
    
    /// 获取指定日期的秒数（静态方法，兼容性保留）
    static func st_second(date: Date) -> Int {
        return date.st_second
    }
    
    /// 获取指定日期的纳秒（静态方法，兼容性保留）
    static func st_nanosecond(date: Date) -> Int {
        return Calendar.current.component(.nanosecond, from: date)
    }
}
