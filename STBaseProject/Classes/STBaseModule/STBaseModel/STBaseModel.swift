//
//  STBaseModel.swift
//  STBaseProject
//
//  Created by stack on 2018/3/14.
//  Copyright © 2018 ST. All rights reserved.
//

import UIKit

open class STBaseModel: NSObject {
    
    deinit {
        STBaseModel.debugPrint(content: "🌈 -> \(self) 🌈 ----> 🌈 dealloc")
    }
    
    open override func value(forUndefinedKey key: String) -> Any? {
        STBaseModel.debugPrint(content: "⚠️ ⚠️ Key = \(key) isValueForUndefinedKey ⚠️ ⚠️")
        return nil
    }

    open override class func setValue(_ value: Any?, forUndefinedKey key: String) {
        STBaseModel.debugPrint(content: "⚠️ ⚠️ Key = \(key) isUndefinedKey ⚠️ ⚠️")
    }

    open override func setValue(_ value: Any?, forUndefinedKey key: String) {
        STBaseModel.debugPrint(content: "⚠️ ⚠️ Key = \(key) isUndefinedKey ⚠️ ⚠️")
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
    
    private func unrecognizedSelectorSentToInstance() {
        STBaseModel.debugPrint(content: "unrecognized selector sent to Instance")
    }
    
    private class func unrecognizedSelectorSentToClass() {
        debugPrint(content: "unrecognized selector sent to class")
    }
    
    private class func debugPrint(content: String) {
#if DEBUG
        print(content)
#endif
    }
}
