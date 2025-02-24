//
//  STImage.swift
//  STBaseProject
//
//  Created by stack on 2018/10/17.
//  Copyright © 2018 ST. All rights reserved.
//

import UIKit

public enum STImageFormat {
    case  STImageFormatPNG
    case  STImageFormatGIF
    case  STImageFormatJPEG
    case  STImageFormatTIFF
    case  STImageFormatWebP
    case  STImageFormatHEIC
    case  STImageFormatHEIF
    case  STImageFormatUndefined
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
    
    func st_getImageFormat() -> STImageFormat {
        let data = self.st_imageToData()
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
    
    func st_getImageType() -> String? {
        let format = self.st_getImageFormat()
        switch format {
        case .STImageFormatPNG:
            return "png"
        case .STImageFormatGIF:
            return "gif"
        case .STImageFormatJPEG:
            return "jpeg"
        case .STImageFormatTIFF:
            return "tiff"
        case .STImageFormatWebP:
            return "webp"
        case .STImageFormatHEIC:
            return "heic"
        case .STImageFormatHEIF:
            return "heif"
        case .STImageFormatUndefined:
            return nil
        }
    }
    
    /// 获取图片某一点的颜色
    func st_getPointColor(point: CGPoint) -> UIColor {
        guard CGRect(origin: CGPoint(x: 0, y: 0), size: self.size).contains(point) else {
            return UIColor.clear
        }
        let pointX = trunc(point.x);
        let pointY = trunc(point.y);

        let width = self.size.width;
        let height = self.size.height;
        let colorSpace = CGColorSpaceCreateDeviceRGB();
        var pixelData: [UInt8] = [0, 0, 0, 0]

        pixelData.withUnsafeMutableBytes { pointer in
            if let context = CGContext(data: pointer.baseAddress, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue), let cgImage = self.cgImage {
                context.setBlendMode(.copy)
                context.translateBy(x: -pointX, y: pointY - height)
                context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
            }
        }

        let red = CGFloat(pixelData[0]) / CGFloat(255.0)
        let green = CGFloat(pixelData[1]) / CGFloat(255.0)
        let blue = CGFloat(pixelData[2]) / CGFloat(255.0)
        let alpha = CGFloat(pixelData[3]) / CGFloat(255.0)

        if #available(iOS 10.0, *) {
            return UIColor(displayP3Red: red, green: green, blue: blue, alpha: alpha)
        } else {
            return UIColor(red: red, green: green, blue: blue, alpha: alpha)
        }
    }
}

public extension UIImage {
    static func st_compressImageToSize(_ image: UIImage, maxFileSize: Int) -> Data? {
        let maxFileSizeBytes = maxFileSize * 1024
        var compressionQuality: CGFloat = 1.0
        let imageData = image.jpegData(compressionQuality: compressionQuality)
        guard var data = imageData, data.count > maxFileSizeBytes else {
            return imageData
        }
        while data.count > maxFileSizeBytes && compressionQuality > 0.1 {
            compressionQuality -= 0.1
            if let compressedData = image.jpegData(compressionQuality: compressionQuality) {
                data = compressedData
            }
        }
        if data.count > maxFileSizeBytes {
            let targetSize = self.st_calculateTargetSize(for: image, maxFileSize: maxFileSizeBytes)
            if let resizedImage = self.st_resizeImage(image, targetSize: targetSize) {
                return self.st_compressImageToSize(resizedImage, maxFileSize: maxFileSize)
            }
        }
        return data
    }
    
    static func st_resizeImage(_ image: UIImage, targetSize: CGSize) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }

    static func st_calculateTargetSize(for image: UIImage, maxFileSize: Int) -> CGSize {
        let originalSize = CGSize(width: image.size.width, height: image.size.height)
        let scaleFactor = sqrt(Double(maxFileSize) / Double(image.jpegData(compressionQuality: 1.0)?.count ?? 1))
        return CGSize(width: originalSize.width * CGFloat(scaleFactor),
                      height: originalSize.height * CGFloat(scaleFactor))
    }
}

public extension UIImage {
    static func st_getLaunchImage() -> UIImage {
        let viewSize = UIScreen.main.bounds.size
        var launchImage = ""
        if let imageDict = Bundle.main.infoDictionary?["UILaunchImages"] as? Array<Dictionary<String, String>> {
            for dict in imageDict {
                if let value = dict["UILaunchImageSize"] {
                    let imageSize = NSCoder.cgSize(for: value)
                    if imageSize.equalTo(viewSize) {
                        launchImage = dict["UILaunchImageName"] ?? ""
                    }
                }
            }
        }
        return UIImage.init(named: launchImage) ?? UIImage()
    }
}
