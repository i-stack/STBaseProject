//
//  STImage.swift
//  STBaseProject
//
//  Created by stack on 2018/10/17.
//  Copyright © 2018 ST. All rights reserved.
//

import UIKit
import Photos

// MARK: - 图片格式枚举
public enum STImageFormat: String, CaseIterable {
    case png = "png"
    case gif = "gif"
    case jpeg = "jpeg"
    case tiff = "tiff"
    case webp = "webp"
    case heic = "heic"
    case heif = "heif"
    case undefined = "undefined"
    
    public var mimeType: String {
        return "image/\(rawValue)"
    }
    
    public var fileExtension: String {
        return rawValue
    }
}

// MARK: - 水印位置枚举
public enum WatermarkPosition {
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight
    case center
}

// MARK: - UIImage 扩展
public extension UIImage {
    
    // MARK: - 基础功能
    /// 检查图片是否为空
    static func isEmpty(_ image: UIImage) -> Bool {
        let cgImageIsEmpty = image.cgImage == nil
        let ciImageIsEmpty = image.ciImage == nil
        return cgImageIsEmpty && ciImageIsEmpty
    }
    
    /// 转换为 Base64 字符串
    func toBase64() -> String {
        let imageData = toData()
        return imageData.count > 0 ? imageData.base64EncodedString() : ""
    }
    
    /// 转换为 Data
    func toData() -> Data {
        if let pngData = self.pngData(), pngData.count > 0 {
            return pngData
        } else if let jpegData = self.jpegData(compressionQuality: 1.0), jpegData.count > 0 {
            return jpegData
        }
        return Data()
    }
    
    /// 获取图片格式
    func getFormat() -> STImageFormat {
        let data = self.toData()
        guard data.count > 0 else { return .undefined }
        
        var firstByte: UInt8 = 0
        data.copyBytes(to: &firstByte, count: 1)
        
        switch firstByte {
        case 0xFF:
            return .jpeg
        case 0x89:
            return .png
        case 0x47:
            return .gif
        case 0x49, 0x4D:
            return .tiff
        case 0x52:
            if data.count >= 12 {
                let headerData = data.prefix(12)
                if let headerString = String(data: headerData, encoding: .ascii),
                   headerString.hasPrefix("RIFF") && headerString.contains("WEBP") {
                    return .webp
                }
            }
        case 0x00:
            if data.count >= 12 {
                let ftypData = data.dropFirst(4).prefix(8)
                if let ftypString = String(data: ftypData, encoding: .ascii) {
                    let heicTypes = ["ftypheic", "ftypheix", "ftyphevc", "ftyphevx"]
                    let heifTypes = ["ftypmif1", "ftypmsf1"]
                    
                    if heicTypes.contains(ftypString) {
                        return .heic
                    } else if heifTypes.contains(ftypString) {
                        return .heif
                    }
                }
            }
        default:
            break
        }
        
        return .undefined
    }
    
    /// 获取图片类型字符串
    func getTypeString() -> String? {
        let format = getFormat()
        return format == .undefined ? nil : format.rawValue
    }
    
    // MARK: - 图片处理
    func imageResized(to size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        self.draw(in: CGRect(origin: .zero, size: size))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resizedImage
    }
    
    /// 获取图片某一点的颜色
    func getColor(at point: CGPoint) -> UIColor {
        guard CGRect(origin: .zero, size: self.size).contains(point) else {
            return UIColor.clear
        }
        
        let pointX = trunc(point.x)
        let pointY = trunc(point.y)
        let width = self.size.width
        let height = self.size.height
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        var pixelData: [UInt8] = [0, 0, 0, 0]
        
        pixelData.withUnsafeMutableBytes { pointer in
            if let context = CGContext(data: pointer.baseAddress,
                                     width: 1, height: 1,
                                     bitsPerComponent: 8,
                                     bytesPerRow: 4,
                                     space: colorSpace,
                                     bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue),
               let cgImage = self.cgImage {
                context.setBlendMode(.copy)
                context.translateBy(x: -pointX, y: pointY - height)
                context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
            }
        }
        
        let red = CGFloat(pixelData[0]) / 255.0
        let green = CGFloat(pixelData[1]) / 255.0
        let blue = CGFloat(pixelData[2]) / 255.0
        let alpha = CGFloat(pixelData[3]) / 255.0
        
        if #available(iOS 10.0, *) {
            return UIColor(displayP3Red: red, green: green, blue: blue, alpha: alpha)
        } else {
            return UIColor(red: red, green: green, blue: blue, alpha: alpha)
        }
    }
    
    /// 压缩图片到指定大小
    static func compressToSize(_ image: UIImage, maxFileSize: Int) -> Data? {
        let maxFileSizeBytes = maxFileSize * 1024
        var compressionQuality: CGFloat = 1.0
        
        guard var data = image.jpegData(compressionQuality: compressionQuality),
              data.count > maxFileSizeBytes else {
            return image.jpegData(compressionQuality: compressionQuality)
        }
        
        // 逐步降低压缩质量
        while data.count > maxFileSizeBytes && compressionQuality > 0.1 {
            compressionQuality -= 0.1
            if let compressedData = image.jpegData(compressionQuality: compressionQuality) {
                data = compressedData
            }
        }
        
        // 如果压缩质量无法达到目标，则调整尺寸
        if data.count > maxFileSizeBytes {
            let targetSize = calculateTargetSize(for: image, maxFileSize: maxFileSizeBytes)
            if let resizedImage = resizeImage(image, to: targetSize) {
                return compressToSize(resizedImage, maxFileSize: maxFileSize)
            }
        }
        
        return data
    }
    
    /// 调整图片尺寸
    static func resizeImage(_ image: UIImage, to targetSize: CGSize) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
    
    /// 计算目标尺寸
    private static func calculateTargetSize(for image: UIImage, maxFileSize: Int) -> CGSize {
        let originalSize = image.size
        let originalData = image.jpegData(compressionQuality: 1.0)
        let originalSizeBytes = originalData?.count ?? 1
        
        let scaleFactor = sqrt(Double(maxFileSize) / Double(originalSizeBytes))
        return CGSize(width: originalSize.width * CGFloat(scaleFactor),
                     height: originalSize.height * CGFloat(scaleFactor))
    }
    
    /// 裁剪图片
    func crop(to rect: CGRect) -> UIImage? {
        guard let cgImage = self.cgImage?.cropping(to: rect) else { return nil }
        return UIImage(cgImage: cgImage)
    }
    
    /// 旋转图片
    func rotate(by angle: CGFloat) -> UIImage? {
        let radians = angle * .pi / 180
        let rotatedSize = CGRect(origin: .zero, size: size)
            .applying(CGAffineTransform(rotationAngle: radians))
            .size
        
        let renderer = UIGraphicsImageRenderer(size: rotatedSize)
        return renderer.image { context in
            context.cgContext.translateBy(x: rotatedSize.width / 2, y: rotatedSize.height / 2)
            context.cgContext.rotate(by: radians)
            draw(in: CGRect(x: -size.width / 2, y: -size.height / 2, width: size.width, height: size.height))
        }
    }
    
    /// 添加圆角
    func roundedCorners(radius: CGFloat) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            let rect = CGRect(origin: .zero, size: size)
            let path = UIBezierPath(roundedRect: rect, cornerRadius: radius)
            path.addClip()
            draw(in: rect)
        }
    }
    
    /// 添加边框
    func addBorder(width: CGFloat, color: UIColor) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            let rect = CGRect(origin: .zero, size: size)
            color.setFill()
            context.fill(rect)
            draw(in: CGRect(x: width, y: width, width: size.width - 2 * width, height: size.height - 2 * width))
        }
    }
    
    /// 智能压缩 - 改进的压缩算法
    static func smartCompress(_ image: UIImage, 
                             maxFileSize: Int, 
                             quality: CGFloat = 0.8,
                             format: STImageFormat = .jpeg) -> Data? {
        let maxFileSizeBytes = maxFileSize * 1024
        
        // 根据格式选择压缩方式
        switch format {
        case .png:
            if let pngData = image.pngData(), pngData.count <= maxFileSizeBytes {
                return pngData
            }
            // PNG 无法调整质量，直接调整尺寸
            return compressImageBySize(image, maxFileSize: maxFileSizeBytes, format: .png)
            
        case .jpeg:
            var compressionQuality = quality
            guard var data = image.jpegData(compressionQuality: compressionQuality) else { return nil }
            
            if data.count <= maxFileSizeBytes {
                return data
            }
            
            // 二分法查找最佳压缩质量
            var minQuality: CGFloat = 0.1
            var maxQuality = compressionQuality
            
            while maxQuality - minQuality > 0.05 {
                let midQuality = (minQuality + maxQuality) / 2
                if let compressedData = image.jpegData(compressionQuality: midQuality) {
                    if compressedData.count <= maxFileSizeBytes {
                        data = compressedData
                        minQuality = midQuality
                    } else {
                        maxQuality = midQuality
                    }
                }
            }
            
            // 如果质量压缩无法满足要求，调整尺寸
            if data.count > maxFileSizeBytes {
                return compressImageBySize(image, maxFileSize: maxFileSizeBytes, format: .jpeg)
            }
            
            return data
            
        default:
            return compressToSize(image, maxFileSize: maxFileSize)
        }
    }
    
    /// 按尺寸压缩图片
    private static func compressImageBySize(_ image: UIImage, 
                                           maxFileSize: Int, 
                                           format: STImageFormat) -> Data? {
        var scaleFactor: CGFloat = 1.0
        let maxSizeBytes = maxFileSize
        
        // 计算初始缩放比例
        let originalData = format == .png ? image.pngData() : image.jpegData(compressionQuality: 0.8)
        if let data = originalData, data.count > 0 {
            scaleFactor = sqrt(CGFloat(maxSizeBytes) / CGFloat(data.count))
            scaleFactor = min(scaleFactor, 1.0) // 不放大图片
        }
        
        // 逐步调整尺寸直到满足要求
        var attempts = 0
        let maxAttempts = 5
        
        while attempts < maxAttempts {
            let newSize = CGSize(width: image.size.width * scaleFactor,
                               height: image.size.height * scaleFactor)
            
            guard let resizedImage = resizeImage(image, to: newSize) else { break }
            
            let compressedData = format == .png ? 
                resizedImage.pngData() : 
                resizedImage.jpegData(compressionQuality: 0.8)
            
            if let data = compressedData, data.count <= maxSizeBytes {
                return data
            }
            
            scaleFactor *= 0.8 // 减少20%的尺寸
            attempts += 1
        }
        
        return nil
    }
    
    /// 保持宽高比的缩放
    func aspectFitScale(to targetSize: CGSize) -> UIImage? {
        let widthRatio = targetSize.width / size.width
        let heightRatio = targetSize.height / size.height
        let ratio = min(widthRatio, heightRatio)
        
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        return UIImage.resizeImage(self, to: newSize)
    }
    
    /// 保持宽高比的填充
    func aspectFillScale(to targetSize: CGSize) -> UIImage? {
        let widthRatio = targetSize.width / size.width
        let heightRatio = targetSize.height / size.height
        let ratio = max(widthRatio, heightRatio)
        
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        guard let scaledImage = UIImage.resizeImage(self, to: newSize) else { return nil }
        
        // 裁剪到目标尺寸
        let xOffset = (newSize.width - targetSize.width) / 2
        let yOffset = (newSize.height - targetSize.height) / 2
        let cropRect = CGRect(x: xOffset, y: yOffset, width: targetSize.width, height: targetSize.height)
        
        return scaledImage.crop(to: cropRect)
    }
    
    /// 水印处理
    func addWatermark(_ watermarkImage: UIImage, 
                     position: WatermarkPosition = .bottomRight,
                     margin: CGFloat = 10,
                     alpha: CGFloat = 0.7) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            // 绘制原图
            draw(in: CGRect(origin: .zero, size: size))
            
            // 计算水印位置
            let watermarkSize = watermarkImage.size
            var watermarkOrigin: CGPoint
            
            switch position {
            case .topLeft:
                watermarkOrigin = CGPoint(x: margin, y: margin)
            case .topRight:
                watermarkOrigin = CGPoint(x: size.width - watermarkSize.width - margin, y: margin)
            case .bottomLeft:
                watermarkOrigin = CGPoint(x: margin, y: size.height - watermarkSize.height - margin)
            case .bottomRight:
                watermarkOrigin = CGPoint(x: size.width - watermarkSize.width - margin, 
                                        y: size.height - watermarkSize.height - margin)
            case .center:
                watermarkOrigin = CGPoint(x: (size.width - watermarkSize.width) / 2,
                                        y: (size.height - watermarkSize.height) / 2)
            }
            
            // 绘制水印
            watermarkImage.draw(in: CGRect(origin: watermarkOrigin, size: watermarkSize),
                              blendMode: .normal, alpha: alpha)
        }
    }
    
    /// 模糊效果
    func applyBlur(radius: CGFloat = 10) -> UIImage? {
        guard let cgImage = cgImage else { return nil }
        
        let context = CIContext()
        let ciImage = CIImage(cgImage: cgImage)
        
        guard let filter = CIFilter(name: "CIGaussianBlur") else { return nil }
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(radius, forKey: kCIInputRadiusKey)
        
        guard let outputImage = filter.outputImage,
              let blurredCGImage = context.createCGImage(outputImage, from: ciImage.extent) else {
            return nil
        }
        
        return UIImage(cgImage: blurredCGImage)
    }
    
    /// 色调调整
    func adjustBrightness(_ brightness: Float) -> UIImage? {
        guard let cgImage = cgImage else { return nil }
        
        let context = CIContext()
        let ciImage = CIImage(cgImage: cgImage)
        
        guard let filter = CIFilter(name: "CIColorControls") else { return nil }
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(brightness, forKey: kCIInputBrightnessKey)
        
        guard let outputImage = filter.outputImage,
              let adjustedCGImage = context.createCGImage(outputImage, from: ciImage.extent) else {
            return nil
        }
        
        return UIImage(cgImage: adjustedCGImage)
    }
    
    // MARK: - 系统功能
    /// 获取启动图片
    static func getLaunchImage() -> UIImage {
        let viewSize = UIScreen.main.bounds.size
        var launchImageName = ""
        
        if let imageDict = Bundle.main.infoDictionary?["UILaunchImages"] as? [[String: String]] {
            for dict in imageDict {
                if let sizeString = dict["UILaunchImageSize"] {
                    let imageSize = NSCoder.cgSize(for: sizeString)
                    if imageSize.equalTo(viewSize) {
                        launchImageName = dict["UILaunchImageName"] ?? ""
                        break
                    }
                }
            }
        }
        
        return UIImage(named: launchImageName) ?? UIImage()
    }
    
    /// 从 URL 加载图片
    static func loadFromURL(_ url: URL, completion: @escaping (UIImage?) -> Void) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let data = data, let image = UIImage(data: data) {
                    completion(image)
                } else {
                    completion(nil)
                }
            }
        }.resume()
    }
    
    /// 保存图片到相册
    func saveToPhotoLibrary(completion: @escaping (Bool, Error?) -> Void) {
        PHPhotoLibrary.requestAuthorization { status in
            switch status {
            case .authorized:
                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAsset(from: self)
                }) { success, error in
                    DispatchQueue.main.async {
                        completion(success, error)
                    }
                }
            case .denied, .restricted:
                DispatchQueue.main.async {
                    completion(false, NSError(domain: "PhotoLibrary", code: 1, userInfo: [NSLocalizedDescriptionKey: "相册权限被拒绝"]))
                }
            case .notDetermined:
                DispatchQueue.main.async {
                    completion(false, NSError(domain: "PhotoLibrary", code: 2, userInfo: [NSLocalizedDescriptionKey: "相册权限未确定"]))
                }
            @unknown default:
                DispatchQueue.main.async {
                    completion(false, NSError(domain: "PhotoLibrary", code: 3, userInfo: [NSLocalizedDescriptionKey: "未知错误"]))
                }
            }
        }
    }
}
