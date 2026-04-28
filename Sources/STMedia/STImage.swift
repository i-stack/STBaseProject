//
//  STImage.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2018/3/14.
//

import UIKit
import Photos

// MARK: - STImageError

public enum STImageError: LocalizedError {
    case invalidData
    case photoLibraryPermissionDenied

    public var errorDescription: String? {
        switch self {
        case .invalidData: return "Invalid image data"
        case .photoLibraryPermissionDenied: return "Photo library permission denied"
        }
    }
}

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

    public var mimeType: String { return "image/\(rawValue)" }
    public var fileExtension: String { return rawValue }
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

    static func isEmpty(_ image: UIImage) -> Bool {
        return image.cgImage == nil && image.ciImage == nil
    }

    func toBase64() -> String {
        let data = toData()
        return data.count > 0 ? data.base64EncodedString() : ""
    }

    func toData() -> Data {
        if let pngData = self.pngData(), pngData.count > 0 { return pngData }
        if let jpegData = self.jpegData(compressionQuality: 1.0), jpegData.count > 0 { return jpegData }
        return Data()
    }

    /// 从已有 Data 直接检测图片格式，避免重复编码
    static func format(from data: Data) -> STImageFormat {
        guard data.count > 0 else { return .undefined }
        var firstByte: UInt8 = 0
        data.copyBytes(to: &firstByte, count: 1)
        switch firstByte {
        case 0xFF: return .jpeg
        case 0x89: return .png
        case 0x47: return .gif
        case 0x49, 0x4D: return .tiff
        case 0x52:
            if data.count >= 12 {
                let header = data.prefix(12)
                if let s = String(data: header, encoding: .ascii), s.hasPrefix("RIFF") && s.contains("WEBP") {
                    return .webp
                }
            }
        case 0x00:
            if data.count >= 12 {
                let ftyp = data.dropFirst(4).prefix(8)
                if let s = String(data: ftyp, encoding: .ascii) {
                    if ["ftypheic", "ftypheix", "ftyphevc", "ftyphevx"].contains(s) { return .heic }
                    if ["ftypmif1", "ftypmsf1"].contains(s) { return .heif }
                }
            }
        default: break
        }
        return .undefined
    }

    func getFormat() -> STImageFormat {
        return UIImage.format(from: self.toData())
    }

    func getTypeString() -> String? {
        let fmt = getFormat()
        return fmt == .undefined ? nil : fmt.rawValue
    }

    // MARK: - 图片处理

    static func resizeImage(_ image: UIImage, to targetSize: CGSize) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }

    func getColor(at point: CGPoint) -> UIColor {
        guard CGRect(origin: .zero, size: self.size).contains(point) else { return .clear }
        let pointX = trunc(point.x)
        let pointY = trunc(point.y)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        var pixelData: [UInt8] = [0, 0, 0, 0]
        pixelData.withUnsafeMutableBytes { pointer in
            guard let context = CGContext(
                data: pointer.baseAddress,
                width: 1, height: 1,
                bitsPerComponent: 8,
                bytesPerRow: 4,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ), let cgImage = self.cgImage else { return }
            context.setBlendMode(.copy)
            context.translateBy(x: -pointX, y: pointY - self.size.height)
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height))
        }
        return UIColor(
            displayP3Red: CGFloat(pixelData[0]) / 255.0,
            green: CGFloat(pixelData[1]) / 255.0,
            blue: CGFloat(pixelData[2]) / 255.0,
            alpha: CGFloat(pixelData[3]) / 255.0
        )
    }

    static func compressToSize(_ image: UIImage, maxFileSize: Int) -> Data? {
        let maxBytes = maxFileSize * 1024
        var quality: CGFloat = 1.0
        guard var data = image.jpegData(compressionQuality: quality) else { return nil }
        guard data.count > maxBytes else { return data }
        while data.count > maxBytes && quality > 0.1 {
            quality -= 0.1
            if let compressed = image.jpegData(compressionQuality: quality) { data = compressed }
        }
        if data.count > maxBytes {
            let targetSize = calculateTargetSize(for: image, maxFileSize: maxBytes)
            if let resized = resizeImage(image, to: targetSize) {
                return compressToSize(resized, maxFileSize: maxFileSize)
            }
        }
        return data
    }

    private static func calculateTargetSize(for image: UIImage, maxFileSize: Int) -> CGSize {
        let original = image.size
        let originalBytes = image.jpegData(compressionQuality: 1.0)?.count ?? 1
        let scale = sqrt(Double(maxFileSize) / Double(originalBytes))
        return CGSize(width: original.width * CGFloat(scale), height: original.height * CGFloat(scale))
    }

    func crop(to rect: CGRect) -> UIImage? {
        guard let cgImage = self.cgImage?.cropping(to: rect) else { return nil }
        return UIImage(cgImage: cgImage)
    }

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

    func roundedCorners(radius: CGFloat) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            let path = UIBezierPath(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: radius)
            path.addClip()
            draw(in: CGRect(origin: .zero, size: size))
        }
    }

    func addBorder(width: CGFloat, color: UIColor) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            draw(in: CGRect(x: width, y: width, width: size.width - 2 * width, height: size.height - 2 * width))
        }
    }

    static func smartCompress(_ image: UIImage,
                              maxFileSize: Int,
                              quality: CGFloat = 0.8,
                              format: STImageFormat = .jpeg) -> Data? {
        let maxBytes = maxFileSize * 1024
        switch format {
        case .png:
            if let data = image.pngData(), data.count <= maxBytes { return data }
            return compressImageBySize(image, maxFileSize: maxBytes, format: .png)
        case .jpeg:
            var compressionQuality = quality
            guard var data = image.jpegData(compressionQuality: compressionQuality) else { return nil }
            if data.count <= maxBytes { return data }
            var minQuality: CGFloat = 0.1
            var maxQuality = compressionQuality
            while maxQuality - minQuality > 0.05 {
                let mid = (minQuality + maxQuality) / 2
                if let compressed = image.jpegData(compressionQuality: mid) {
                    if compressed.count <= maxBytes { data = compressed; minQuality = mid }
                    else { maxQuality = mid }
                }
            }
            if data.count > maxBytes {
                return compressImageBySize(image, maxFileSize: maxBytes, format: .jpeg)
            }
            return data
        default:
            return compressToSize(image, maxFileSize: maxFileSize)
        }
    }

    private static func compressImageBySize(_ image: UIImage, maxFileSize: Int, format: STImageFormat) -> Data? {
        let originalData = format == .png ? image.pngData() : image.jpegData(compressionQuality: 0.8)
        var scaleFactor: CGFloat = 1.0
        if let data = originalData, data.count > 0 {
            scaleFactor = min(sqrt(CGFloat(maxFileSize) / CGFloat(data.count)), 1.0)
        }
        for _ in 0..<5 {
            let newSize = CGSize(width: image.size.width * scaleFactor, height: image.size.height * scaleFactor)
            guard let resized = resizeImage(image, to: newSize) else { break }
            let compressed = format == .png ? resized.pngData() : resized.jpegData(compressionQuality: 0.8)
            if let data = compressed, data.count <= maxFileSize { return data }
            scaleFactor *= 0.8
        }
        return nil
    }

    func aspectFitScale(to targetSize: CGSize) -> UIImage? {
        let ratio = min(targetSize.width / size.width, targetSize.height / size.height)
        return UIImage.resizeImage(self, to: CGSize(width: size.width * ratio, height: size.height * ratio))
    }

    func aspectFillScale(to targetSize: CGSize) -> UIImage? {
        let ratio = max(targetSize.width / size.width, targetSize.height / size.height)
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        guard let scaled = UIImage.resizeImage(self, to: newSize) else { return nil }
        let xOffset = (newSize.width - targetSize.width) / 2
        let yOffset = (newSize.height - targetSize.height) / 2
        return scaled.crop(to: CGRect(x: xOffset, y: yOffset, width: targetSize.width, height: targetSize.height))
    }

    func addWatermark(_ watermarkImage: UIImage,
                      position: WatermarkPosition = .bottomRight,
                      margin: CGFloat = 10,
                      alpha: CGFloat = 0.7) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: size))
            let wSize = watermarkImage.size
            let origin: CGPoint
            switch position {
            case .topLeft: origin = CGPoint(x: margin, y: margin)
            case .topRight: origin = CGPoint(x: size.width - wSize.width - margin, y: margin)
            case .bottomLeft: origin = CGPoint(x: margin, y: size.height - wSize.height - margin)
            case .bottomRight: origin = CGPoint(x: size.width - wSize.width - margin, y: size.height - wSize.height - margin)
            case .center: origin = CGPoint(x: (size.width - wSize.width) / 2, y: (size.height - wSize.height) / 2)
            }
            watermarkImage.draw(in: CGRect(origin: origin, size: wSize), blendMode: .normal, alpha: alpha)
        }
    }

    func applyBlur(radius: CGFloat = 10) -> UIImage? {
        guard let cgImage = self.cgImage else { return nil }
        let context = CIContext()
        let ciImage = CIImage(cgImage: cgImage)
        guard let filter = CIFilter(name: "CIGaussianBlur") else { return nil }
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(radius, forKey: kCIInputRadiusKey)
        guard let output = filter.outputImage,
              let blurredCGImage = context.createCGImage(output, from: ciImage.extent) else { return nil }
        return UIImage(cgImage: blurredCGImage)
    }

    func adjustBrightness(_ brightness: Float) -> UIImage? {
        guard let cgImage = self.cgImage else { return nil }
        let context = CIContext()
        let ciImage = CIImage(cgImage: cgImage)
        guard let filter = CIFilter(name: "CIColorControls") else { return nil }
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(brightness, forKey: kCIInputBrightnessKey)
        guard let output = filter.outputImage,
              let adjustedCGImage = context.createCGImage(output, from: ciImage.extent) else { return nil }
        return UIImage(cgImage: adjustedCGImage)
    }

    // MARK: - 网络与相册

    static func load(from url: URL) async throws -> UIImage {
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let image = UIImage(data: data) else { throw STImageError.invalidData }
        return image
    }

    func saveToPhotoLibrary() async throws {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else {
            throw STImageError.photoLibraryPermissionDenied
        }
        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAsset(from: self)
        }
    }
}
