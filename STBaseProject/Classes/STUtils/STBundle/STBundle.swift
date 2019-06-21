//
//  STBundle.swift
//  STBaseProject
//
//  Created by song on 2018/11/14.
//  Copyright © 2018年 song. All rights reserved.
//

import UIKit
import Foundation

open class STBundle: Bundle {

    class open func st_mainBundle() -> Bundle {
        return Bundle.main
    }
    
    class open func st_scanResourceBundle() -> Bundle {
        let bundle: Bundle = Bundle.init(for: STScanView.self)
        let url: URL = bundle.url(forResource: "STScanResource", withExtension: "bundle") ?? URL.init(fileURLWithPath: "")
        return Bundle.init(url: url) ?? Bundle.main
    }
    
    class open func st_baseResourceBundle() -> Bundle {
        let bundle: Bundle = Bundle.init(for: STScanView.self)
        let url: URL = bundle.url(forResource: "STBaseResource", withExtension: "bundle") ?? URL.init(fileURLWithPath: "")
        return Bundle.init(url: url) ?? Bundle.main
    }
}
