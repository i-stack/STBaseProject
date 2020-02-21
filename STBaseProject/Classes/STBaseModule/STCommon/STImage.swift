//
//  STImage.swift
//  STBaseProject
//
//  Created by stack on 2019/12/17.
//  Copyright © 2019 ST. All rights reserved.
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
    
    func st_imageFormat() -> STImageFormat {
        let data = st_imageToData()
        let newData = NSData.init(data: data)
        if newData.length < 1 {
            return .STImageFormatUndefined
        }
        
        var c: UInt8?
        newData.getBytes(&c, length: 1)
        switch c {
        case 0xFF:
            return .STImageFormatJPEG
        case 0x89:
            return .STImageFormatPNG
        case 0x47:
            return .STImageFormatGIF
        case 0x49:
            return .STImageFormatTIFF
        case 0x4D:
            return .STImageFormatTIFF
        case 0x52:
            if newData.length >= 12 {
                //RIFF....WEBP
                if let testString = NSString.init(data: newData.subdata(with: NSRange.init(location: 0, length: 12)), encoding: String.Encoding.ascii.rawValue) {
                    if testString.hasPrefix("RIFF"), testString.hasPrefix("WEBP") {
                        return .STImageFormatWebP
                    }
                }
            }
            break;
        case 0x00:
            if newData.length >= 12 {
                if let testString = NSString.init(data: newData.subdata(with: NSRange.init(location: 4, length: 8)), encoding: String.Encoding.ascii.rawValue) {
                    //....ftypheic ....ftypheix ....ftyphevc ....ftyphevx
                    if testString.isEqual(to: "ftypheic") ||
                        testString.isEqual(to: "ftypheix") ||
                        testString.isEqual(to: "ftyphevc") ||
                        testString.isEqual(to: "ftyphevx") {
                        return .STImageFormatHEIC
                    }
                    
                    //....ftypmif1 ....ftypmsf1
                    if testString.isEqual(to: "ftypmif1") ||
                        testString.isEqual(to: "ftypmsf1") {
                        return .STImageFormatHEIF
                    }
                }
            }
            break
        case .none:
            break
        case .some(_):
            break
        }
        return .STImageFormatUndefined
    }
}
