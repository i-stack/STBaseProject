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
        self.configBenchmarkDesign(size: nil)
        self.configCustomNavBar(normalHeight: nil, safeHeigh: nil)
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
}
