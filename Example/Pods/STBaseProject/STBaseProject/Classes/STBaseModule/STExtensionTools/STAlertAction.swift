//
//  STAlertAction.swift
//  STBaseProject
//
//  Created by song on 2019/7/1.
//

import UIKit

public extension UIAlertAction {
    
    /// property list
    static var propertyNames: [String] {
        var outCount: UInt32 = 0
        guard let ivars = class_copyIvarList(self, &outCount) else {
            return []
        }
        var result = [String]()
        let count = Int(outCount)
        for i in 0..<count {
            let ivar = ivars[Int(i)]
            if let key = ivar_getName(ivar) {
                let name = String(cString: key)
                result.append(name)
            }
        }
        return result
    }
    
    /// Check if a certain attribute exists.
    func isPropertyExisted(_ propertyName: String) -> Bool {
        for name in UIAlertAction.propertyNames {
            if name == propertyName {
                return true
            }
        }
        return false
    }
    
    /// Set text color
    func setTextColor(_ color: UIColor) {
        let key = "_titleTextColor"
        guard isPropertyExisted(key) else {
            return
        }
        self.setValue(color, forKey: key)
    }
}
