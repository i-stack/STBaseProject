//
//  STBaseModel.swift
//  STBaseProject
//
//  Created by song on 2018/3/14.
//  Copyright © 2018 song. All rights reserved.
//

import UIKit

open class STBaseModel: NSObject {
    
    deinit {
        print("🌈 -> \(self) 🌈 ----> 🌈 dealloc")
    }
    
    open override func value(forUndefinedKey key: String) -> Any? {
        return nil
    }
    
    open override class func setValue(_ value: Any?, forUndefinedKey key: String) {
        
    }
    
    open override func setValue(_ value: Any?, forUndefinedKey key: String) {
        
    }
}
