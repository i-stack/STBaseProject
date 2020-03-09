//
//  STDateManager.swift
//  STBaseProject
//
//  Created by stack on 2019/12/10.
//  Copyright © 2019 ST. All rights reserved.
//

import UIKit
import Foundation

public extension String {
    
    /// @param 当前时间戳 yyyy-MM-dd HH:mm:ss
    func st_currentSystemTimestamp() -> String {
        return st_currentSystemTimestamp(dateFormat: "yyyy-MM-dd HH:mm:ss")
    }
    
    /// @param 当前时间戳
    func st_currentSystemTimestamp(dateFormat: String) -> String {
        let dateFormatter = self.formatter(dateFormat: dateFormat)
        let dateStr = dateFormatter.string(from: Date())
        return dateStr
    }
    
    /// @param 时间戳转时间 yyyy-MM-dd HH:mm:ss
    func st_timestampToStr() -> String {
        return st_timestampToStr(dateFormat: "yyyy-MM-dd HH:mm:ss")
    }
    
    /// @param 时间戳转时间
    func st_timestampToStr(dateFormat: String) -> String {
        if self.count < 1 {
            return ""
        }
        let timeStamp: TimeInterval = self.timeStampToSecond()
        let dateFormatter = self.formatter(dateFormat: dateFormat)
        let date = Date.init(timeIntervalSince1970: timeStamp)
        let timeStr = dateFormatter.string(from: date)
        return timeStr
    }
    
    /// @param 时间戳转Date
    func st_timestampToDate() -> Date {
        if self.count < 1 {
            return Date()
        }
        let timeStamp: TimeInterval = self.timeStampToSecond()
        let date = Date.init(timeIntervalSince1970: timeStamp)
        let zone = NSTimeZone.system
        let interval = zone.secondsFromGMT(for: date)
        let localeDate = date.addingTimeInterval(TimeInterval(interval))
        return localeDate
    }
    
    /// @param 时间字符串转时间戳
    func st_timeTotimestamp(dateFormat: String) -> String {
        if self.count < 1 {
            return ""
        }
        let dateFormatter: DateFormatter = self.formatter(dateFormat: dateFormat)
        var interval: TimeInterval = 0
        if let date = dateFormatter.date(from: self) {
            interval = date.timeIntervalSince1970
        }
        return String(interval)
    }
    
    /// @param 比较给定Date与当前时间的时间差，返回相差的秒数
    func st_timeDifference(date: Date) -> String {
        let localDate = Date()
        let difference = fabs(localDate.timeIntervalSince(date))
        return String(difference)
    }
    
    /// @param 返回几天前、几小时前、几分钟前等
    func st_timeStampToDay() -> String {
        let timeStamp = self.timeStampToSecond()
        let currentTime = Date().timeIntervalSince1970
        let reduceTime: TimeInterval = currentTime - timeStamp
        if reduceTime < 60 {
            return "刚刚"
        }
        let mins = reduceTime / 60.0
        if mins < 60 {
            return "\(mins)分钟前"
        }
        let hours = mins / 60
        if hours < 24 {
            return "\(hours)小时前"
        }
        let days = hours / 24.0
        if days < 30 {
            return "\(days)天前"
        }
        let month = days / 30.0
        if month < 12 {
            return "\(month)月前"
        }
        let year = month / 12.0
        return "\(year)年前"
    }
    
    /// @param 比较给定日期与当前日期 year {0: 相同，1: 大于当前日期， 2: 小于当前日期}
    func st_compareYearWithCurrentDate() -> Int {
        return compareWithCurrentDate(compontent: .year)
    }
    
    /// @param 比较给定日期与当前日期 month {0: 相同，1: 大于当前日期， 2: 小于当前日期}
    func st_compareMonthWithCurrentDate() -> Int {
        return compareWithCurrentDate(compontent: .month)
    }
    
    /// @param 比较给定日期与当前日期 day {0: 相同，1: 大于当前日期， 2: 小于当前日期}
    func st_compareDayWithCurrentDate() -> Int {
        return compareWithCurrentDate(compontent: .day)
    }
    
    /// @param 比较给定日期与当前日期 hour {0: 相同，1: 大于当前日期， 2: 小于当前日期}
    func st_compareHourWithCurrentDate() -> Int {
        return compareWithCurrentDate(compontent: .hour)
    }
    
    /// @param 比较给定日期与当前日期 minute {0: 相同，1: 大于当前日期， 2: 小于当前日期}
    func st_compareMinuteWithCurrentDate() -> Int {
        return compareWithCurrentDate(compontent: .minute)
    }
    
    /// @param 比较给定日期与当前日期 second {0: 相同，1: 大于当前日期， 2: 小于当前日期}
    func st_compareSecondWithCurrentDate() -> Int {
        return compareWithCurrentDate(compontent: .second)
    }
    
    /// @param 比较给定日期与当前日期 {0: 相同，1: 大于当前日期， 2: 小于当前日期}
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
        let stamp: Double = self.doubleValue
        var timeStamp: TimeInterval = TimeInterval(stamp)
        if self.count == 13 {
            timeStamp = TimeInterval(timeStamp / 1000)
        }
        return timeStamp
    }
    
    private func formatter() -> DateFormatter {
        return formatter(dateFormat: "yyyy-MM-dd HH:mm:ss")
    }
    
    private func formatter(dateFormat: String) -> DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = dateFormat
        dateFormatter.locale = Locale.current
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
}