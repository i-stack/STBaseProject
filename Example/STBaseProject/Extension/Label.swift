//
//  Label.swift
//  STBaseProject_Example
//
//  Created by song on 2025/1/19.
//  Copyright © 2025 STBaseProject. All rights reserved.
//

import Foundation
import UIKit
import STBaseProject

extension UILabel {
    @IBInspectable open var localizedTitle: String {
        set {
            self.text = Bundle.st_localizedString(key: newValue)
        }
        get {
            return self.text ?? ""
        }
    }
}
