//
//  STBaseConstants.swift
//  STBaseProject
//
//  Created by stack on 2019/03/16.
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

// custom bar height
public struct STConstantBarHeightModel {
    public var navNormalHeight: CGFloat = 64.0
    public var navIsSafeHeight: CGFloat = 88.0
    public var tabBarNormalHeight: CGFloat = 49.0
    public var tabBarIsSafeHeight: CGFloat = 83.0
    public init() {}
}

public class STBaseConstants: NSObject {
    
    private var benchmarkDesignSize = CGSize.zero
    public static let shared: STBaseConstants = STBaseConstants()
    private var barHeightModel: STConstantBarHeightModel = STConstantBarHeightModel()
    
    private override init() {
        super.init()
    }

    /// Design drawing baseline dimensions
    ///
    /// Configure once
    ///
    /// - Parameter size: Basic size
    ///
    public func st_configBenchmarkDesign(size: CGSize) -> Void {
        self.benchmarkDesignSize = size
    }
    
    /// custom bar height
    ///
    /// - Parameter model: `STConstantBarHeightModel`
    ///
    public func st_customNavHeight(model: STConstantBarHeightModel) -> Void {
        self.barHeightModel = model
    }
    
    public class func st_multiplier() -> CGFloat {
        let size = STBaseConstants.shared.benchmarkDesignSize
        if size == .zero {
            return 1.0
        }
        let min = UIScreen.main.bounds.height < UIScreen.main.bounds.width ? UIScreen.main.bounds.height : UIScreen.main.bounds.width
        return min / size.width
    }
    
    /// Current screen ratio to the standard design size
    ///
    /// Before calling this method, `st_configBenchmarkDesign` should be called with the standard design size to configure once
    ///
    /// - Parameter float: The marked value on the design drawing
    ///
    public class func st_handleFloat(float: CGFloat) -> CGFloat {
        let multiplier = self.st_multiplier()
        let result = float * multiplier
        let scale = UIScreen.main.scale
        return (result * scale).rounded(.up) / scale
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
    
    /// 3.5inch
    ///
    /// Device name: 3GS、4、4S
    ///
    /// width x height: 320 x 480 @2x
    ///
    public class func st_isIPhone480() -> Bool {
        return self.st_apph() == 480
    }
    
    /// 4.0inch
    ///
    /// Device name: 5、5S、5C、SE
    ///
    /// width x height:320 x 568 @2x
    ///
    public class func st_isIPhone568() -> Bool {
        return self.st_apph() == 568
    }
    
    /// 4.7inch
    ///
    /// Device name: 6、6s、7、8
    ///
    /// width x height: 375 x 667 @2x
    ///
    public class func st_isIPhone667() -> Bool {
        return self.st_apph() == 667
    }
    
    /// 5.4inch
    ///
    /// Device name: 12 mini
    ///
    /// width x height: 360 x 780 @3x
    ///
    public class func st_isIPhone12Mini() -> Bool {
        return self.st_apph() == 780
    }
    
    /// 5.5inch
    ///
    /// Device name: 6Plus、6sPlus、7Plus、8Plus
    ///
    /// width x height: 414 x 736 @3x
    ///
    public class func st_isIPhonePlus() -> Bool {
        return self.st_apph() == 736
    }
    
    /// 5.8inch
    ///
    /// Device name: X、XS、11 Pro
    ///
    /// width x height: 375 x 812 @3x
    ///
    public class func st_isIPhone812() -> Bool {
        return self.st_apph() == 812
    }
    
    /// 6.1inch
    ///
    /// Device name: 12 Pro
    ///
    /// width x height:390 x 844 @3x
    ///
    public class func st_isIPhone844() -> Bool {
        return self.st_apph() == 844
    }
    
    /// 6.1inch
    ///
    /// Device name: 11、XR
    ///
    /// width x height:414 x 896 @2x
    ///
    public class func st_isIPhone896() -> Bool {
        return self.st_apph() == 896
    }
    
    /// 6.5inch
    ///
    /// Device name: 11 Pro Max
    ///
    /// width x height:414 x 896 @3x
    ///
    public class func st_isIPhone11ProMax() -> Bool {
        return self.st_apph() == 896
    }
    
    /// 6.7inch
    ///
    /// Device name: 12 Pro Max
    ///
    /// width x height: 428 x 926
    ///
    public class func st_isIPhone926() -> Bool {
        return self.st_apph() == 926
    }
    
    /// Is it a notch screen
    ///
    /// If the height is greater than 736, it is a notch screen
    ///
    public class func st_isIPhoneSafe() -> Bool {
        return self.st_apph() > 736
    }
    
    /// nav height
    public class func st_navHeight() -> CGFloat {
        if self.st_isIPhoneSafe() {
            return STBaseConstants.shared.barHeightModel.navIsSafeHeight
        }
        return STBaseConstants.shared.barHeightModel.navNormalHeight
    }
    
    /// tabBar height
    public class func st_tabBarHeight() -> CGFloat {
        if self.st_isIPhoneSafe() {
            return STBaseConstants.shared.barHeightModel.tabBarIsSafeHeight
        }
        return STBaseConstants.shared.barHeightModel.tabBarNormalHeight
    }
    
    public class func st_safeBarHeight() -> CGFloat {
        if self.st_isIPhoneSafe() {
            return 34
        }
        return 0
    }
}
