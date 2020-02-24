//
//  STDeviceInfo.swift
//  STBaseProject
//
//  Created by stack on 2019/12/10.
//  Copyright © 2019 ST. All rights reserved.
//

import UIKit

public struct STDeviceInfo {
    
    /// @param uuid
    public static func uuid() -> String {
        return UIDevice.current.identifierForVendor?.uuidString ?? ""
    }
}
