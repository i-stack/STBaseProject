//
//  STConstants.swift
//  STBaseProject
//
//  Created by stack on 2019/03/16.
//

import UIKit
import Foundation

public class STBaseConfig: NSObject {
    
    public static let shared: STBaseConfig = STBaseConfig()
    
    public func defaultBaseConfig() {
        configBenchmarkDesign(size: nil)
        configCustomNavBar(normalHeight: nil, safeHeigh: nil)
//        configHUDParam(customView: nil)
    }
    
    public func configBenchmarkDesign(size: CGSize?) {
        if let newSize = size {
            STBaseConstants.shared.st_configBenchmarkDesign(size: CGSize.init(width: newSize.width, height: newSize.height))
        } else {
            STBaseConstants.shared.st_configBenchmarkDesign(size: CGSize.init(width: 375, height: 812))
        }
    }
    
    public func configCustomNavBar(normalHeight: CGFloat?, safeHeigh: CGFloat?) {
        var model = STConstantBarHeightModel.init()
        model.navNormalHeight = normalHeight ?? 76
        model.navIsSafeHeight = safeHeigh ?? 100
        STBaseConstants.shared.st_customNavHeight(model: model)
    }
    
//    public func configHUDParam(customView: UIView?) {
//        STHUD.sharedHUD.hudMode = .customView
//        if let newCustomView = customView {
//            STHUD.sharedHUD.customView = newCustomView
//        }
//        STHUD.sharedHUD.labelColor = UIColor.white
//        STHUD.sharedHUD.activityViewColor = UIColor.st_color(hexString: "#000000", alpha: 0.3)
//        STHUD.sharedHUD.labelFont = UIFont.st_systemFont(ofSize: 14, weight: .regular)
//    }
}
