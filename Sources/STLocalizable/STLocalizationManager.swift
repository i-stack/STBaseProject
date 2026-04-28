//
//  STLocalizationManager.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2018/01/10.
//

import UIKit

// MARK: - 内部常量
private enum STLocalizationConstant {
    static let userDefaultsKey    = "App_Language_Switch_Key"
    static let notificationName   = "Language_Change_Notification"
}

// 作为 associated object 的唯一地址键
private var st_customBundleKey: UInt8 = 0

// MARK: - 支持的语言
public struct STSupportedLanguage {
    public let languageCode: String
    public let displayName: String
    public let locale: Locale

    public init(languageCode: String, displayName: String? = nil) {
        self.languageCode = languageCode
        self.locale       = Locale(identifier: languageCode)
        self.displayName  = displayName
            ?? self.locale.localizedString(forLanguageCode: languageCode)
            ?? languageCode
    }

    /// 扫描 main bundle 中所有 .lproj 目录，返回可用语言列表。
    /// 每次调用均含文件 I/O，调用方应在适当时机缓存结果。
    public static func getAvailableLanguages() -> [STSupportedLanguage] {
        guard let resourcePath = Bundle.main.resourcePath else { return [] }
        do {
            return try FileManager.default.contentsOfDirectory(atPath: resourcePath)
                .filter { $0.hasSuffix(".lproj") && $0 != "Base.lproj" }
                .map { STSupportedLanguage(languageCode: String($0.dropLast(6))) }
                .sorted { $0.displayName < $1.displayName }
        } catch {
            print("⚠️ STLocalizationManager: 无法读取语言列表: \(error)")
            return []
        }
    }
}

// MARK: - Bundle 方法替换（替代 ISA Swizzle）
//
// 使用 method_exchangeImplementations 替换 Bundle.localizedString(forKey:value:table:)，
// 使所有途径（包括 NSLocalizedString）在 Bundle.main 上自动走自定义语言包。
// 替换仅执行一次，由 static let 懒加载保证。
private extension Bundle {

    static let st_installSwizzle: Void = {
        guard
            let original = class_getInstanceMethod(Bundle.self, #selector(Bundle.localizedString(forKey:value:table:))),
            let patched   = class_getInstanceMethod(Bundle.self, #selector(Bundle.st_patched_localizedString(forKey:value:table:)))
        else { return }
        method_exchangeImplementations(original, patched)
    }()

    /// 替换后此 selector 的实现指向原始 localizedString；
    /// 在内部调用 self.st_patched_localizedString 即调用原始实现，不会递归。
    @objc func st_patched_localizedString(forKey key: String, value: String?, table tableName: String?) -> String {
        guard self === Bundle.main,
              let customBundle = objc_getAssociatedObject(Bundle.main, &st_customBundleKey) as? Bundle else {
            return self.st_patched_localizedString(forKey: key, value: value, table: tableName)
        }
        return customBundle.st_patched_localizedString(forKey: key, value: value, table: tableName)
    }
}

// MARK: - Bundle 语言管理
public extension Bundle {

    /// 当前生效的自定义语言包，nil 表示跟随系统。模块内可写，外部只读。
    internal static var customLanguageBundle: Bundle? {
        get { objc_getAssociatedObject(Bundle.main, &st_customBundleKey) as? Bundle }
        set { objc_setAssociatedObject(Bundle.main, &st_customBundleKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    /// 获取本地化字符串，优先使用自定义语言包
    static func st_localizedString(key: String, tableName: String = "Localizable") -> String {
        let bundle = customLanguageBundle ?? Bundle.main
        return bundle.localizedString(forKey: key, value: nil, table: tableName)
    }

    /// 切换到指定语言代码（如 "zh-Hans"、"en"）
    static func st_setCustomLanguage(_ languageCode: String) {
        guard let path = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            print("⚠️ STLocalizationManager: 未找到语言包 \(languageCode)")
            return
        }
        customLanguageBundle = bundle
        UserDefaults.standard.set(languageCode, forKey: STLocalizationConstant.userDefaultsKey)
        NotificationCenter.default.post(name: .stLanguageDidChange, object: languageCode)
    }

    /// 切换到指定语言对象
    static func st_setSupportedLanguage(_ language: STSupportedLanguage) {
        st_setCustomLanguage(language.languageCode)
    }

    /// 清除自定义语言，恢复跟随系统
    static func st_clearCustomLanguage() {
        customLanguageBundle = nil
        UserDefaults.standard.removeObject(forKey: STLocalizationConstant.userDefaultsKey)
        NotificationCenter.default.post(name: .stLanguageDidChange, object: nil)
    }

    /// 当前自定义语言代码，跟随系统时返回 nil
    static func st_getCurrentLanguage() -> String? {
        return UserDefaults.standard.string(forKey: STLocalizationConstant.userDefaultsKey)
    }

    /// 当前自定义语言对象，跟随系统时返回 nil
    static func st_getCurrentLanguageObject() -> STSupportedLanguage? {
        guard let code = st_getCurrentLanguage() else { return nil }
        return STSupportedLanguage(languageCode: code)
    }

    /// 系统首选语言代码
    static func st_getSystemLanguage() -> String {
        return Locale.preferredLanguages.first ?? "en"
    }

    /// 指定语言包是否存在于 main bundle
    static func st_isLanguageAvailable(_ languageCode: String) -> Bool {
        return Bundle.main.path(forResource: languageCode, ofType: "lproj") != nil
    }

    /// 所有可用语言列表（含 I/O，调用方应缓存）
    static func st_getAvailableLanguages() -> [STSupportedLanguage] {
        return STSupportedLanguage.getAvailableLanguages()
    }

    /// 在 application(_:didFinishLaunchingWithOptions:) 中调用一次，完成方法替换并还原上次语言设置
    static func st_configureLocalization() {
        _ = Bundle.st_installSwizzle

        if let savedCode = st_getCurrentLanguage(), st_isLanguageAvailable(savedCode) {
            st_setCustomLanguage(savedCode)
            return
        }

        let systemCode = st_getSystemLanguage()
        let available  = STSupportedLanguage.getAvailableLanguages()

        let matched = available.first {
            systemCode == $0.languageCode || systemCode.hasPrefix($0.languageCode + "-")
        }
        if let lang = matched ?? available.first {
            st_setCustomLanguage(lang.languageCode)
        }
    }
}

// MARK: - String 便捷本地化
public extension String {
    var localized: String {
        return Bundle.st_localizedString(key: self)
    }

    func localized(tableName: String) -> String {
        return Bundle.st_localizedString(key: self, tableName: tableName)
    }
}

// MARK: - 语言切换通知
public extension Notification.Name {
    static let stLanguageDidChange = Notification.Name(STLocalizationConstant.notificationName)
}
