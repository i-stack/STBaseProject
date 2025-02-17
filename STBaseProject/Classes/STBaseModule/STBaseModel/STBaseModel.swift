//
//  STBaseModel.swift
//  STBaseProject
//
//  Created by stack on 2018/3/14.
//

import UIKit

open class STBaseModel: NSObject {
    
    deinit {
        STBaseModel.st_debugPrint(content: "🌈 -> \(self) 🌈 ----> 🌈 dealloc")
    }
    
    open override func value(forUndefinedKey key: String) -> Any? {
        STBaseModel.st_debugPrint(content: "⚠️ ⚠️ Key = \(key) isValueForUndefinedKey ⚠️ ⚠️")
        return nil
    }

    open override class func setValue(_ value: Any?, forUndefinedKey key: String) {
        STBaseModel.st_debugPrint(content: "⚠️ ⚠️ Key = \(key) isUndefinedKey ⚠️ ⚠️")
    }

    open override func setValue(_ value: Any?, forUndefinedKey key: String) {
        STBaseModel.st_debugPrint(content: "⚠️ ⚠️ Key = \(key) isUndefinedKey ⚠️ ⚠️")
    }
    
    open override class func resolveInstanceMethod(_ sel: Selector!) -> Bool {
        if let aMethod = class_getInstanceMethod(self, NSSelectorFromString("unrecognizedSelectorSentToInstance")) {
            class_addMethod(self, sel, method_getImplementation(aMethod), method_getTypeEncoding(aMethod))
            return true
        }
        return super.resolveInstanceMethod(sel)
    }
    
    open override class func resolveClassMethod(_ sel: Selector!) -> Bool {
        if let aMethod = class_getClassMethod(self, NSSelectorFromString("unrecognizedSelectorSentToClass")) {
            class_addMethod(self, sel, method_getImplementation(aMethod), method_getTypeEncoding(aMethod))
            return true
        }
        return super.resolveInstanceMethod(sel)
    }
    
    private func st_unrecognizedSelectorSentToInstance() {
        STBaseModel.st_debugPrint(content: "unrecognized selector sent to Instance")
    }
    
    private class func st_unrecognizedSelectorSentToClass() {
        STBaseModel.st_debugPrint(content: "unrecognized selector sent to class")
    }
    
    private class func st_debugPrint(content: String) {
#if DEBUG
        print(content)
#endif
    }
}
