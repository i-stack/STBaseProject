//
//  STImage.swift
//  STBaseFramework
//
//  Created by song on 2019/12/17.
//  Copyright © 2019 wlcy. All rights reserved.
//

import UIKit

public enum STImageFormat {
    case  STImageFormatUndefined
    case  STImageFormatJPEG
    case  STImageFormatPNG
    case  STImageFormatGIF
    case  STImageFormatTIFF
    case  STImageFormatWebP
    case  STImageFormatHEIC
    case  STImageFormatHEIF
}

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
    
    func st_imageToBase64() -> String {
        var content = ""
        let imageData = st_imageToData()
        if imageData.count > 0 {
            content = imageData.base64EncodedString()
        }
        return content
    }
    
    func st_imageToData() -> Data {
        var imageData = Data()
        if let pngData: Data = self.pngData(), pngData.count > 0 {
            imageData = pngData
        } else if let jpegData: Data = self.jpegData(compressionQuality: 1.0), jpegData.count > 0 {
            imageData = jpegData
        }
        return imageData
    }
}
