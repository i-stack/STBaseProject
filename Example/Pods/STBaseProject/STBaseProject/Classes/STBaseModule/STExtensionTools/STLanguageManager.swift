//
//  STLanguageManager.swift
//  STBaseProject
//
//  Created by stack on 2018/01/10.
//

import Foundation

struct STLanguageConstantKey {
    static var customBundleKey: UInt8 = 10
    let appLanguageSwitchKey = "App_Language_Switch_Key"
}

public class STLanguageManager: Bundle, @unchecked Sendable {
    
    deinit {
        objc_removeAssociatedObjects(self)
    }
    
    public override func localizedString(forKey key: String, value: String?, table tableName: String?) -> String {
        if let bundle = objc_getAssociatedObject(self, &STLanguageConstantKey.customBundleKey) as? Bundle {
            return bundle.localizedString(forKey: key, value: value, table: tableName)
        }
        return super.localizedString(forKey: key, value: value, table: tableName)
    }
}

public extension Bundle {
    static var customLanguageBundle: Bundle? {
        get {
            return objc_getAssociatedObject(Bundle.main, &STLanguageConstantKey.customBundleKey) as? Bundle
        }
        set {
            objc_setAssociatedObject(Bundle.main, &STLanguageConstantKey.customBundleKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    static func st_localizedString(key: String, tableName: String = "Localizable") -> String {
        let bundle = customLanguageBundle ?? Bundle.main
        return bundle.localizedString(forKey: key, value: nil, table: tableName)
    }
    
    /// setting language
    ///
    /// - Parameter language: `Base.lproj`, pass in `Base`
    ///
    /// `zh-Hans.lproj` pass in `zh-Hans`, provided that the language package has been added to the project in advance.
    ///
    static func st_setCusLanguage(language: String) -> Void {
        guard !language.isEmpty else {
            customLanguageBundle = nil
            UserDefaults.standard.removeObject(forKey: STLanguageConstantKey().appLanguageSwitchKey)
            UserDefaults.standard.synchronize()
            return
        }
        
        if let path = Bundle.main.path(forResource: language, ofType: "lproj") {
            if let bundle = Bundle.init(path: path) {
                customLanguageBundle = bundle
                UserDefaults.standard.set(language, forKey: STLanguageConstantKey().appLanguageSwitchKey)
            }
        } else {
            customLanguageBundle = nil
            UserDefaults.standard.removeObject(forKey: STLanguageConstantKey().appLanguageSwitchKey)
        }
        UserDefaults.standard.synchronize()
    }
    
    /// Get the current custom language; if the system language is followed, the output is `nil`.
    static func st_getCustomLanguage() -> String {
        if let language = UserDefaults.standard.string(forKey: STLanguageConstantKey().appLanguageSwitchKey), !language.isEmpty {
            return language
        }
        return self.st_appSupportLanguage()
    }

    /// Follow the system language for recovery.
    static func st_restoreSystemLanguage() -> Void {
        self.st_setCusLanguage(language: "")
    }
    
    static func st_systemLanguage() -> String {
        return NSLocale.preferredLanguages.first ?? "en"
    }
    
     static func st_appSupportLanguage() -> String {
         if let languages = UserDefaults.standard.value(forKey: "AppleLanguages") as? [String], !languages.isEmpty {
             return languages.first ?? "en"
        }
        return "en"
    }
    
    static func st_configLanguage() -> Void {
        object_setClass(Bundle.main, STLanguageManager.self)
        let customLanguage = st_getCustomLanguage()
        if customLanguage.isEmpty {
            st_setCusLanguage(language: "en")
        } else {
            st_setCusLanguage(language: customLanguage)
        }
    }
}
