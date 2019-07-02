//
//  STImageContentType.swift
//  STBaseProject
//
//  Created by song on 2018/11/14.
//  Copyright © 2018年 song. All rights reserved.
//

import UIKit
import CoreServices
import MobileCoreServices

public enum STImageFormat {
    case STImageFormatUndefined
    case STImageFormatJPEG
    case STImageFormatPNG
    case STImageFormatGIF
    case STImageFormatTIFF
    case STImageFormatWebP
    case STImageFormatHEIC
    case STImageFormatHEIF
}

//MARK:- ImageFormat
extension NSData {
    
    public class func st_imageFormatForImageData(data: NSData) -> STImageFormat {
        if data.length < 1 {
            return .STImageFormatUndefined
        }
        // File signatures table: http://www.garykessler.net/library/file_sigs.html
        var c: UInt8 = 0
        data.getBytes(&c, length: 1)
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
            if data.length >= 12 {
                //RIFF....WEBP
                let testString: String = String.init(data: data.subdata(with: NSRange.init(location: 0, length: 12)), encoding: String.Encoding.ascii) ?? ""
                if testString.hasPrefix("RIFF") == true && testString.hasPrefix("WEBP") == true {
                    return .STImageFormatWebP
                }
            }
            break;
        case 0x00:
            if data.length >= 12 {
                let testString: String = String.init(data: data.subdata(with: NSRange.init(location: 4, length: 8)), encoding: String.Encoding.ascii) ?? ""
                
                //....ftypheic ....ftypheix ....ftyphevc ....ftyphevx
                if testString == "ftypheic" ||
                    testString == "ftypheix" ||
                    testString == "ftyphevc" ||
                    testString == "ftyphevx" {
                    return .STImageFormatHEIC
                }
                
                //....ftypmif1 ....ftypmsf1
                if testString == "ftypmif1" ||
                    testString == "ftypmsf1" {
                    return .STImageFormatHEIF
                }
            }
            break
        default:
            break
        }
        return .STImageFormatUndefined
    }

    public class func st_UTTypeFromImageFormat(format: STImageFormat) -> CFString {
        var type: CFString = kUTTypePNG
        switch format {
        case .STImageFormatJPEG:
            type = kUTTypeJPEG
            break
        case .STImageFormatPNG:
            type = kUTTypePNG
            break
        case .STImageFormatGIF:
            type = kUTTypeGIF
            break
        case .STImageFormatTIFF:
            type = kUTTypeTIFF
            break
        case .STImageFormatWebP:
            type = "public.webp" as CFString
            break
        case .STImageFormatHEIF:
            type = "public.heif" as CFString
            break
        case .STImageFormatHEIC:
            type = "public.heic" as CFString
            break
        default:
            break
        }
        return type
    }
    
    public class func st_imageFormatFromUTType(uttype: CFString) -> STImageFormat {
        
        var imageFormat: STImageFormat = .STImageFormatUndefined
        if CFStringCompare(uttype, kUTTypeJPEG, []) == CFComparisonResult.compareEqualTo {
            imageFormat = .STImageFormatJPEG
        } else if CFStringCompare(uttype, kUTTypePNG, []) == CFComparisonResult.compareEqualTo {
            imageFormat = .STImageFormatPNG
        } else if CFStringCompare(uttype, kUTTypeGIF, []) == CFComparisonResult.compareEqualTo {
            imageFormat = .STImageFormatGIF
        } else if CFStringCompare(uttype, kUTTypePNG, []) == CFComparisonResult.compareEqualTo {
            imageFormat = .STImageFormatPNG
        } else if CFStringCompare(uttype, kUTTypeTIFF, []) == CFComparisonResult.compareEqualTo {
            imageFormat = .STImageFormatTIFF
        } else if CFStringCompare(uttype, "public.webp" as CFString, []) == CFComparisonResult.compareEqualTo {
            imageFormat = .STImageFormatWebP
        } else if CFStringCompare(uttype, "public.heic" as CFString, []) == CFComparisonResult.compareEqualTo {
            imageFormat = .STImageFormatHEIC
        } else if CFStringCompare(uttype, "public.heif" as CFString, []) == CFComparisonResult.compareEqualTo {
            imageFormat = .STImageFormatHEIF
        }
        return imageFormat
    }
}
