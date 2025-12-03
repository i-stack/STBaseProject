//
//  STLocalizationManager.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2018/01/10.
//

import Foundation
import UIKit

// MARK: - 本地化常量
private struct STLocalizationConstantKey {
    static var customBundleKey: UInt8 = 10
    static let appLanguageSwitchKey = "App_Language_Switch_Key"
    static let languageChangeNotification = "Language_Change_Notification"
}

// MARK: - 支持的语言结构
public struct STSupportedLanguage {
    public let languageCode: String
    public let displayName: String
    public let locale: Locale
    
    public init(languageCode: String, displayName: String? = nil) {
        self.languageCode = languageCode
        self.locale = Locale(identifier: languageCode)
        if let displayName = displayName {
            self.displayName = displayName
        } else {
            self.displayName = self.locale.localizedString(forLanguageCode: languageCode) ?? languageCode
        }
    }
    
    /// 获取项目中所有可用的语言
    public static func getAvailableLanguages() -> [STSupportedLanguage] {
        var availableLanguages: [STSupportedLanguage] = []
        if let bundlePath = Bundle.main.resourcePath {
            do {
                let contents = try FileManager.default.contentsOfDirectory(atPath: bundlePath)
                let lprojFolders = contents.filter { $0.hasSuffix(".lproj") }
                for folder in lprojFolders {
                    let languageCode = String(folder.dropLast(6)) // 移除 ".lproj" 后缀
                    if languageCode != "Base" {
                        let language = STSupportedLanguage(languageCode: languageCode)
                        availableLanguages.append(language)
                    }
                }
            } catch {
                print("⚠️ STLocalizationManager: 无法读取 Bundle 内容: \(error)")
            }
        }
        return availableLanguages.sorted { $0.displayName < $1.displayName }
    }
    
    /// 检查语言是否可用
    public static func isLanguageAvailable(_ languageCode: String) -> Bool {
        return getAvailableLanguages().contains { $0.languageCode == languageCode }
    }
    
    /// 根据语言代码获取语言对象
    public static func getLanguage(by languageCode: String) -> STSupportedLanguage? {
        return getAvailableLanguages().first { $0.languageCode == languageCode }
    }
}

// MARK: - 本地化管理器
/// 本地化管理器，负责应用的语言切换和本地化字符串管理
public class STLocalizationManager: Bundle, @unchecked Sendable {
    
    deinit {
        objc_removeAssociatedObjects(self)
    }
    
    public override func localizedString(forKey key: String, value: String?, table tableName: String?) -> String {
        if let bundle = objc_getAssociatedObject(self, &STLocalizationConstantKey.customBundleKey) as? Bundle {
            return bundle.localizedString(forKey: key, value: value, table: tableName)
        }
        return super.localizedString(forKey: key, value: value, table: tableName)
    }
}

// MARK: - 自定义语言包
public extension Bundle {
    
    static var customLanguageBundle: Bundle? {
        get {
            return objc_getAssociatedObject(Bundle.main, &STLocalizationConstantKey.customBundleKey) as? Bundle
        }
        set {
            objc_setAssociatedObject(Bundle.main, &STLocalizationConstantKey.customBundleKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    /// 获取本地化字符串
    /// - Parameters:
    ///   - key: 字符串键
    ///   - tableName: 字符串表名，默认为 "Localizable"
    /// - Returns: 本地化字符串
    static func st_localizedString(key: String, tableName: String = "Localizable") -> String {
        let bundle = customLanguageBundle ?? Bundle.main
        return bundle.localizedString(forKey: key, value: nil, table: tableName)
    }
    
    /// 设置自定义语言
    /// - Parameter language: 语言代码，如 "zh-Hans"、"en" 等
    static func st_setCustomLanguage(_ language: String) {
        guard !language.isEmpty else {
            customLanguageBundle = nil
            UserDefaults.standard.removeObject(forKey: STLocalizationConstantKey.appLanguageSwitchKey)
            UserDefaults.standard.synchronize()
            NotificationCenter.default.post(name: NSNotification.Name(STLocalizationConstantKey.languageChangeNotification), object: nil)
            return
        }
        
        if let path = Bundle.main.path(forResource: language, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            customLanguageBundle = bundle
            UserDefaults.standard.set(language, forKey: STLocalizationConstantKey.appLanguageSwitchKey)
            UserDefaults.standard.synchronize()
            NotificationCenter.default.post(name: NSNotification.Name(STLocalizationConstantKey.languageChangeNotification), object: nil)
        } else {
            print("⚠️ STLocalizationManager: 未找到语言包 \(language)")
            customLanguageBundle = nil
            UserDefaults.standard.removeObject(forKey: STLocalizationConstantKey.appLanguageSwitchKey)
            UserDefaults.standard.synchronize()
        }
    }
    
    /// 设置支持的语言
    /// - Parameter language: 支持的语言对象
    static func st_setSupportedLanguage(_ language: STSupportedLanguage) {
        st_setCustomLanguage(language.languageCode)
    }
    
    /// 获取当前自定义语言
    /// - Returns: 当前语言代码，如果跟随系统则返回 nil
    static func st_getCurrentLanguage() -> String? {
        if let language = UserDefaults.standard.string(forKey: STLocalizationConstantKey.appLanguageSwitchKey), !language.isEmpty {
            return language
        }
        return nil
    }
    
    /// 获取当前语言对象
    /// - Returns: 当前语言对象，如果跟随系统则返回 nil
    static func st_getCurrentLanguageObject() -> STSupportedLanguage? {
        guard let languageCode = st_getCurrentLanguage() else { return nil }
        return STSupportedLanguage.getLanguage(by: languageCode)
    }
    
    /// 恢复系统语言
    static func st_restoreSystemLanguage() {
        st_setCustomLanguage("")
    }
    
    /// 获取系统语言
    /// - Returns: 系统语言代码
    static func st_getSystemLanguage() -> String {
        return NSLocale.preferredLanguages.first ?? "en"
    }
    
    /// 获取应用支持的语言
    /// - Returns: 应用支持的语言代码
    static func st_getAppSupportedLanguage() -> String {
        if let languages = UserDefaults.standard.value(forKey: "AppleLanguages") as? [String], !languages.isEmpty {
            return languages.first ?? "en"
        }
        return "en"
    }
    
    /// 配置语言管理器
    static func st_configureLocalization() {
        object_setClass(Bundle.main, STLocalizationManager.self)
        
        // 检查是否有保存的语言设置
        if let savedLanguage = st_getCurrentLanguage() {
            st_setCustomLanguage(savedLanguage)
        } else {
            // 如果没有保存的设置，使用系统语言或默认语言
            let systemLanguage = st_getSystemLanguage()
            let availableLanguages = STSupportedLanguage.getAvailableLanguages()
            
            // 查找系统语言是否在支持的语言列表中
            if let supportedLanguage = availableLanguages.first(where: { $0.languageCode == systemLanguage }) {
                st_setCustomLanguage(supportedLanguage.languageCode)
            } else if let firstLanguage = availableLanguages.first {
                // 如果系统语言不支持，使用第一个可用的语言
                st_setCustomLanguage(firstLanguage.languageCode)
            } else {
                // 如果没有任何语言包，使用英语作为默认
                st_setCustomLanguage("en")
            }
        }
    }
    
    /// 检查语言包是否存在
    /// - Parameter language: 语言代码
    /// - Returns: 是否存在对应的语言包
    static func st_isLanguageAvailable(_ language: String) -> Bool {
        return Bundle.main.path(forResource: language, ofType: "lproj") != nil
    }
    
    /// 获取所有可用的语言代码
    /// - Returns: 可用的语言代码数组
    static func st_getAvailableLanguageCodes() -> [String] {
        return STSupportedLanguage.getAvailableLanguages().map { $0.languageCode }
    }
    
    /// 获取所有可用的语言对象
    /// - Returns: 可用的语言对象数组
    static func st_getAvailableLanguages() -> [STSupportedLanguage] {
        return STSupportedLanguage.getAvailableLanguages()
    }
}

// MARK: - 本地化字符串
public extension String {
    
    var localized: String {
        return Bundle.st_localizedString(key: self)
    }
    
    /// 本地化字符串（指定表名）
    /// - Parameter tableName: 字符串表名
    /// - Returns: 本地化字符串
    func localized(tableName: String) -> String {
        return Bundle.st_localizedString(key: self, tableName: tableName)
    }
}

// MARK: - 语言切换通知
public extension Notification.Name {
    static let stLanguageDidChange = Notification.Name(STLocalizationConstantKey.languageChangeNotification)
}
