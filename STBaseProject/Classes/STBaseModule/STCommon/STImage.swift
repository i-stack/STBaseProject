//
//  STImage.swift
//  STBaseFramework
//
//  Created by song on 2019/12/17.
//  Copyright © 2019 wlcy. All rights reserved.
//

import UIKit

public extension UIImage {
    static func st_imageIsEmpty(image: UIImage) -> Bool {
        var cgImageIsEmpty: Bool = false
        if let _: CGImage = image.cgImage {
            cgImageIsEmpty = false
        } else {
            cgImageIsEmpty = true
        }
        
        var ciImageIsEmpty: Bool = false
        if let _: CIImage = image.ciImage {
            ciImageIsEmpty = false
        } else {
            ciImageIsEmpty = true
        }
        if cgImageIsEmpty == true, ciImageIsEmpty == true {
            return true
        }
        return false
    }
}
