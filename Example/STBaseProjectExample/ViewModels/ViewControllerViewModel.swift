//
//  ViewControllerViewModel.swift
//  STBaseProject_Example
//
//  Created by 寒江孤影 on 2023/2/27.
//  Copyright © 2023 STBaseProject. All rights reserved.
//

import UIKit
import STBaseProject

class ViewControllerViewModel: NSObject {

    private var _name: String?
    var name: String? {
        get {
            STLog("getName: \(String(describing: self._name))")
            return self._name
        }
        set {
            self._name = newValue
            STLog("setName: \(String(describing: newValue))")
        }
    }
    var age: Int?
    
    override class func willChangeValue(forKey key: String) {
        super.willChangeValue(forKey: key)
        STLog("willChangeValue")
    }
}
