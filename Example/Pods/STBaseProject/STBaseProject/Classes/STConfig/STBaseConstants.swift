//
//  STBaseConstants.swift
//  STBaseProject
//
//  Created by stack on 2019/03/16.
//

import UIKit
import Foundation

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
        let minScreenSize = min(UIScreen.main.bounds.width, UIScreen.main.bounds.height)
        return minScreenSize / size.width
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
    
    /// Is it a notch screen
    ///
    /// If the height is greater than 736, it is a notch screen
    ///
    public class func st_isNotchScreen() -> Bool {
        return self.st_apph() > 736
    }
    
    /// nav height
    public class func st_navHeight() -> CGFloat {
        if self.st_isNotchScreen() {
            return STBaseConstants.shared.barHeightModel.navIsSafeHeight
        }
        return STBaseConstants.shared.barHeightModel.navNormalHeight
    }
    
    /// tabBar height
    public class func st_tabBarHeight() -> CGFloat {
        if self.st_isNotchScreen() {
            return STBaseConstants.shared.barHeightModel.tabBarIsSafeHeight
        }
        return STBaseConstants.shared.barHeightModel.tabBarNormalHeight
    }
    
    public class func st_safeBarHeight() -> CGFloat {
        if self.st_isNotchScreen() {
            return 34
        }
        return 0
    }
}
