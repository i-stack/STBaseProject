//
//  STSwiftConstants.swift
//  STBaseProject
//
//  Created by song on 2018/11/14.
//  Copyright © 2018年 song. All rights reserved.
//

import UIKit
import Foundation

let ST_One_PX: CGFloat = 1

let ST_NavHeight: CGFloat = ST_IsIPhoneSafe ? 88 : 64
let ST_SafeBottom: CGFloat = ST_IsIPhoneSafe ? 34 : 0
let ST_TabBarHeight: CGFloat = ST_IsIPhoneSafe ? 83 : 49

let ST_APPW  = UIScreen.main.bounds.size.width
let ST_APPH  = UIScreen.main.bounds.size.height
let ST_IsIPhone5: Bool = UIScreen.main.bounds.size.height < 667
let ST_IsIPhone6: Bool = UIScreen.main.bounds.size.height == 667
let ST_IsIPhoneX: Bool = UIScreen.main.bounds.size.height == 812
let ST_IsIPhoneXR: Bool = UIScreen.main.bounds.size.height == 896
let ST_IsIPhonePlus: Bool = UIScreen.main.bounds.size.height == 736
let ST_IsIPhoneXMax: Bool = UIScreen.main.bounds.size.height == 896
let ST_IsIPhoneSafe: Bool = UIScreen.main.bounds.size.height == 812 || UIScreen.main.bounds.size.height == 896

let PingFang_SC_Thin: String = "PingFangSC-Thin"
let PingFang_SC_Bold: String = "PingFang-SC-Bold"
let PingFang_SC_Light: String = "PingFangSC-Light"
let PingFang_SC_Medium: String = "PingFangSC-Medium"
let PingFang_SC_Regular: String = "PingFangSC-Regular"
let PingFang_SC_Semibold: String = "PingFangSC-Semibold"
let PingFang_SC_Ultralight: String = "PingFangSC-Ultralight"

struct STNotificationName {
    let st_app_language = "com.STBaseProject.current_language" // app语言
    let st_system_language = "com.STBaseProject.STBaseProject.appLanguage" // 系统语言
    let st_languageDidChangeNotification = "com.STBaseProject.app_languageDidChangeNotification"
    let st_networkStatusChangeNotification = "com.STBaseProject.networkStatusChangeNotification"
}

class STUIConstants: NSObject {
    class func handleFloat(float: CGFloat) -> CGFloat {
        if ST_IsIPhone5 {
            return float * 0.8
        } else if ST_IsIPhonePlus {
            return float * 1.07
        } else if ST_IsIPhoneX {
            return float * 1.07
        } else if ST_IsIPhoneXR || ST_IsIPhoneXMax {
            return float * 1.08
        } else {
            return float
        }
    }
    
    class func adaptIPhone5(a: CGFloat) -> CGFloat {
        if UIScreen.main.bounds.size.height < 667 {
            return a * 0.8
        } else {
            return a
        }
    }
    
    class func adaptIPhonePlus(a: CGFloat) -> CGFloat {
        if UIScreen.main.bounds.size.height < 667 {
            return a * 0.8
        } else if UIScreen.main.bounds.size.height == 667 {
            return a * 0.9
        } else {
            return a
        }
    }
    
    class func adaptSafeTop(a: CGFloat) -> CGFloat {
        if  UIScreen.main.bounds.size.height == 812 || UIScreen.main.bounds.size.height == 896 {
            return a + 24
        }
        return a
    }
    
    class func adaptSafeBottom(a: CGFloat) -> CGFloat {
        if  UIScreen.main.bounds.size.height == 812 || UIScreen.main.bounds.size.height == 896 {
            return a + 34
        }
        return a
    }
}
