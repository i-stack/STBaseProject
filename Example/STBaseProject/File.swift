//
//  File.swift
//  STBaseProject_Example
//
//  Created by song on 2025/1/30.
//  Copyright © 2025 STBaseProject. All rights reserved.
//

import Foundation
//
//  STDateManager.swift
//  STBaseProject
//
//  Created by stack on 2019/10/10.
//

import UIKit
import Foundation

public extension String {
    
    /// Current timestamp
    ///
    /// - Returns: yyyy-MM-dd HH:mm:ss
    ///
    func st_currentSystemTimestamp() -> String {
        return st_currentSystemTimestamp(dateFormat: "yyyy-MM-dd HH:mm:ss")
    }
    
    /// Current timestamp
    ///
    /// - Parameter dateFormat:
    ///     - Customize time format, such as: yyyy-MM-dd HH:mm:ss
    ///
    /// - Returns: 2018-06-20 12:00:00
    ///
    func st_currentSystemTimestamp(dateFormat: String) -> String {
        let dateFormatter = String.formatter(dateFormat: dateFormat)
        let dateStr = dateFormatter.string(from: Date())
        return dateStr
    }
    
    /// timestamp to time
    ///
    /// Default time format: yyyy-MM-dd HH:mm:ss
    ///
    /// - Returns: 2018-06-20 12:00:00
    ///
    func st_timestampToStr() -> String {
        return st_timestampToStr(dateFormat: "yyyy-MM-dd HH:mm:ss")
    }
    
    func st_timestampToStr(dateFormat: String) -> String {
        if self.count < 1 {
            return ""
        }
        let timeStamp: TimeInterval = self.timeStampToSecond()
        let dateFormatter = String.formatter(dateFormat: dateFormat)
        let date = Date.init(timeIntervalSince1970: timeStamp)
        let timeStr = dateFormatter.string(from: date)
        return timeStr
    }
    
    /// timestamp to Date
    func st_timestampToDate() -> Date {
        if self.count < 1 {
            return Date()
        }
        let timeStamp: TimeInterval = self.timeStampToSecond()
        let date = Date.init(timeIntervalSince1970: timeStamp)
        return date
    }
    
    /// timestamp conversion from time string
    ///
    /// - Parameter dateFormat:
    ///     - Customize time format, such as: yyyy-MM-dd HH:mm:ss
    ///
    /// - Returns: TimeInterval millisecond
    ///
    func st_timeTotimestamp(dateFormat: String) -> TimeInterval {
        if self.count < 1 {
            return 0
        }
        let dateFormatter: DateFormatter = String.formatter(dateFormat: dateFormat)
        var interval: TimeInterval = 0
        if let date = dateFormatter.date(from: self) {
            interval = date.timeIntervalSince1970
        }
        return interval * 1000.0
    }
    
    /// Compare the time difference between the given Date and the current time, and return the difference in seconds.
    func st_timeDifference(date: Date) -> String {
        let localDate = Date()
        let difference = fabs(localDate.timeIntervalSince(date))
        return String(difference)
    }
    
    /// Compare the given date with the current date
    ///
    /// Compare the magnitude of `year`
    ///
    /// - Returns:
    ///     - 0: Same
    ///     - 1: Greater than the current date
    ///     - 2: Less than the current date
    ///
    func st_compareYearWithCurrentDate() -> Int {
        return compareWithCurrentDate(compontent: .year)
    }
    
    /// Compare the given date with the current date
    ///
    /// Compare the magnitude of `month`
    ///
    /// - Returns:
    ///     - 0: Same
    ///     - 1: Greater than the current date
    ///     - 2: Less than the current date
    ///
    func st_compareMonthWithCurrentDate() -> Int {
        return compareWithCurrentDate(compontent: .month)
    }
    
    /// Compare the given date with the current date
    ///
    /// Compare the magnitude of `day`
    ///
    /// - Returns:
    ///     - 0: Same
    ///     - 1: Greater than the current date
    ///     - 2: Less than the current date
    ///
    func st_compareDayWithCurrentDate() -> Int {
        return compareWithCurrentDate(compontent: .day)
    }
    
    /// Compare the given date with the current date
    ///
    /// Compare the magnitude of `hour`
    ///
    /// - Returns:
    ///     - 0: Same
    ///     - 1: Greater than the current date
    ///     - 2: Less than the current date
    ///
    func st_compareHourWithCurrentDate() -> Int {
        return compareWithCurrentDate(compontent: .hour)
    }
    
    /// Compare the given date with the current date
    ///
    /// Compare the magnitude of `minute`
    ///
    /// - Returns:
    ///     - 0: Same
    ///     - 1: Greater than the current date
    ///     - 2: Less than the current date
    ///
    func st_compareMinuteWithCurrentDate() -> Int {
        return compareWithCurrentDate(compontent: .minute)
    }
    
    /// Compare the given date with the current date
    ///
    /// Compare the magnitude of `second`
    ///
    /// - Returns:
    ///     - 0: Same
    ///     - 1: Greater than the current date
    ///     - 2: Less than the current date
    ///
    func st_compareSecondWithCurrentDate() -> Int {
        return compareWithCurrentDate(compontent: .second)
    }
    
    /// Compare the given date with the current date
    ///
    /// Compare the magnitude of `Date`
    ///
    /// - Returns:
    ///     - 0: Same
    ///     - 1: Greater than the current date
    ///     - 2: Less than the current date
    ///
    func st_compareWithCurrentDate() -> Int {
        var compareResult = 0
        let currentDate = Date()
        let originDate = self.st_timestampToDate()
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: currentDate)
        let originYear = calendar.component(.year, from: originDate)
        if currentYear == originYear {
            let currentMonth = calendar.component(.month, from: currentDate)
            let originMonth = calendar.component(.month, from: originDate)
            if currentMonth == originMonth {
                let currentDay = calendar.component(.day, from: currentDate)
                let originDay = calendar.component(.day, from: originDate)
                if currentDay == originDay {
                    let currentHour = calendar.component(.hour, from: currentDate)
                    let originHour = calendar.component(.hour, from: originDate)
                    if currentHour == originHour {
                        let currentMinute = calendar.component(.minute, from: currentDate)
                        let originMinute = calendar.component(.minute, from: originDate)
                        if currentMinute == originMinute {
                            let currentSecond = calendar.component(.second, from: currentDate)
                            let originSecond = calendar.component(.second, from: originDate)
                            if currentSecond == originSecond {
                                compareResult = 0
                            } else if currentSecond < originSecond {
                                compareResult = 1
                            } else {
                                compareResult = 2
                            }
                        } else if currentMinute < originMinute {
                            compareResult = 1
                        } else {
                            compareResult = 2
                        }
                    } else if currentHour < originHour {
                        compareResult = 1
                    } else {
                        compareResult = 2
                    }
                } else if currentDay < originDay {
                    compareResult = 1
                } else {
                    compareResult = 2
                }
            } else if currentMonth < originMonth {
                compareResult = 1
            } else {
                compareResult = 2
            }
        } else if currentYear < originYear {
            compareResult = 1
        } else {
            compareResult = 2
        }
        return compareResult
    }
    
    private func timeStampToSecond() -> TimeInterval {
        if self.count < 1 {
            return 0
        }
        var timeStamp: TimeInterval = NSDecimalNumber.init(string: self).doubleValue
        let stamp = abs(Int64(timeStamp))
        if String(stamp).count == 13 {
            timeStamp = timeStamp / 1000.0
        }
        return timeStamp
    }
    
    private func formatter() -> DateFormatter {
        return String.formatter(dateFormat: "yyyy-MM-dd HH:mm:ss")
    }
    
    static func formatter(dateFormat: String) -> DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = dateFormat
        dateFormatter.locale = Locale.current
        dateFormatter.timeZone = TimeZone.current
        return dateFormatter
    }
    
    private func compareWithCurrentDate(compontent: Calendar.Component) -> Int {
        var compareResult = 0
        let currentDate = Date()
        let originDate = self.st_timestampToDate()
        let calendar = Calendar.current
        let current = calendar.component(compontent, from: currentDate)
        let origin = calendar.component(compontent, from: originDate)
        if current == origin {
            compareResult = 0
        } else if current < origin {
            compareResult = 1
        } else {
            compareResult = 2
        }
        return compareResult
    }
    
    static func st_year(date: Date) -> Int {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)
        return year
    }
    
    static func st_month(date: Date) -> Int {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: date)
        return month
    }
    
    static func st_day(date: Date) -> Int {
        let calendar = Calendar.current
        let day = calendar.component(.day, from: date)
        return day
    }
    
    static func st_hour(date: Date) -> Int {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        return hour
    }
    
    static func st_minute(date: Date) -> Int {
        let calendar = Calendar.current
        let minute = calendar.component(.minute, from: date)
        return minute
    }
    
    static func st_second(date: Date) -> Int {
        let calendar = Calendar.current
        let second = calendar.component(.second, from: date)
        return second
    }
    
    static func st_nanosecond(date: Date) -> Int {
        let calendar = Calendar.current
        let nanosecond = calendar.component(.nanosecond, from: date)
        return nanosecond
    }
}
