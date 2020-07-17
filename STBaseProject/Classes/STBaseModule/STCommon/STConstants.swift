//
//  STConstants.swift
//  STBaseProject
//
//  Created by stack on 2017/10/14.
//  Copyright © 2017年 ST. All rights reserved.
//

import UIKit
import Foundation

public enum STScreenSize {
    case AMXScreenSizeCurrent
    case AMXScreenSize3p5Inch
    case AMXScreenSize4Inch
    case AMXScreenSize4p7Inch
    case AMXScreenSize5p5Inch
    case AMXScreenSize7p9Inch
    case AMXScreenSize9p7Inch
    case AMXScreenSize12p9Inch
}

/// 自定义 bar height
public struct STConstantBarHeightModel {
    var navNormalHeight: CGFloat = 64.0
    var navIsSafeHeight: CGFloat = 88.0
    var tabBarNormalHeight: CGFloat = 49.0
    var tabBarIsSafeHeight: CGFloat = 83.0
    public init() {}
}

public class STConstants: NSObject {
    
    private var benchmarkDesignSize = CGSize.zero
    public static let shared: STConstants = STConstants()
    private var barHeightModel: STConstantBarHeightModel = STConstantBarHeightModel()

    /// @param 设计图基准尺寸
    public func st_configBenchmarkDesign(size: CGSize) -> Void {
        self.benchmarkDesignSize = size
    }
    
    /// @param 自定义 bar 高度
    public func st_customNavHeight(model: STConstantBarHeightModel) -> Void {
        self.barHeightModel = model
    }
    
    private class func st_multiplier() -> CGFloat {
        let size = STConstants.shared.benchmarkDesignSize
        if size == .zero {
            return 1.0
        }
        let min = UIScreen.main.bounds.height < UIScreen.main.bounds.width ? UIScreen.main.bounds.height : UIScreen.main.bounds.width
        return min / size.width
    }
    
    /// @param 调用此方法前，需调用 st_configBenchmarkDesign 传入基准设计尺寸，配置一次
    public class func st_handleFloat(float: CGFloat) -> CGFloat {
        let multiplier = self.st_multiplier()
        return float * multiplier
    }
    
    public class func st_adaptIPhone5(a: CGFloat) -> CGFloat {
        if self.st_apph() < 667 {
            return a * 0.8
        } else {
            return a
        }
    }
    
    public class func st_adaptIPhonePlus(a: CGFloat) -> CGFloat {
        if self.st_apph() < 667 {
            return a * 0.8
        } else if self.st_apph() == 667 {
            return a * 0.9
        } else {
            return a
        }
    }
    
    public class func st_adaptSafeTop(a: CGFloat) -> CGFloat {
        if self.st_apph() == 812 || self.st_apph() == 896 {
            return a + 24
        }
        return a
    }
    
    public class func st_adaptSafeBottom(a: CGFloat) -> CGFloat {
        if self.st_apph() == 812 || self.st_apph() == 896 {
            return a + 34
        }
        return a
    }
    
    public class func st_adaptSTSafeBottom(a: CGFloat) -> CGFloat{
        guard #available(iOS 11.0, *) else {
            return a
        }
        let safeareInsets = UIApplication.shared.keyWindow?.safeAreaInsets
        if safeareInsets!.bottom > 0 {
            return a + 34
        } else {
            return a
        }
    }
    
    public class func st_appw() -> CGFloat {
        return UIScreen.main.bounds.size.width
    }
    
    public class func st_apph() -> CGFloat {
        return UIScreen.main.bounds.size.height
    }
    
    public class func st_isIPhone5() -> Bool {
        return self.st_apph() < 667
    }
    
    public class func st_isIPhone6() -> Bool {
        return self.st_apph() == 667
    }
    
    public class func st_isIPhonePlus() -> Bool {
        return self.st_apph() == 736
    }
    
    public class func st_isIPhoneX() -> Bool {
        return self.st_apph() == 812
    }
    
    public class func st_isIPhoneXR() -> Bool {
        return self.st_apph() == 896
    }
    
    public class func st_isIPhoneXMax() -> Bool {
        return self.st_isIPhoneXR()
    }
    
    public class func st_isIPhoneSafe() -> Bool {
        return self.st_apph() == 812 || self.st_apph() == 896
    }
    
    public class func st_navHeight() -> CGFloat {
        if self.st_isIPhoneSafe() {
            return STConstants.shared.barHeightModel.navIsSafeHeight
        }
        return STConstants.shared.barHeightModel.navNormalHeight
    }
    
    public class func st_tabBarHeight() -> CGFloat {
        if self.st_isIPhoneSafe() {
            return STConstants.shared.barHeightModel.tabBarIsSafeHeight
        }
        return STConstants.shared.barHeightModel.tabBarNormalHeight
    }
    
    public class func st_safeBarHeight() -> CGFloat {
        if self.st_isIPhoneSafe() {
            return 34
        }
        return 0
    }
}

public func STLog<T>(_ message: T, file: String = #file, funcName: String = #function, lineNum: Int = #line) {
    #if DEBUG
    let file = (file as NSString).lastPathComponent
    print("\(file):(\(lineNum))--\(message)")
    #endif
}
