//
//  STImage.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2018/3/14.
//

import UIKit
import Photos

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

public enum WatermarkPosition {
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight
    case center
}

extension UIImage {

    private static let sharedCIContext = CIContext()

    public static func isEmpty(_ image: UIImage) -> Bool {
        return image.cgImage == nil && image.ciImage == nil
    }

    public func toData() -> Data {
        guard let cgImage = self.cgImage else {
            return self.pngData() ?? Data()
        }
        let alpha = cgImage.alphaInfo
        let hasAlpha = alpha != .none && alpha != .noneSkipFirst && alpha != .noneSkipLast
        if hasAlpha {
            if let png = self.pngData(), !png.isEmpty { return png }
            return self.jpegData(compressionQuality: 1.0) ?? Data()
        } else {
            if let jpeg = self.jpegData(compressionQuality: 1.0), !jpeg.isEmpty { return jpeg }
            return self.pngData() ?? Data()
        }
    }

    public func toBase64() -> String {
        let data = toData()
        return !data.isEmpty ? data.base64EncodedString() : ""
    }

    public static func format(from data: Data) -> STImageFormat {
        guard !data.isEmpty else { return .undefined }
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

    /// 启发式判断图片格式：有 alpha 通道 → PNG，无 alpha → JPEG
    /// UIImage 在内存中是格式无关的解码位图，此方法为近似估计，需要原始 Data 时请用 UIImage.format(from:)
    public func getFormat() -> STImageFormat {
        guard let cgImage = self.cgImage else { return .undefined }
        let alpha = cgImage.alphaInfo
        let hasAlpha = alpha != .none && alpha != .noneSkipFirst && alpha != .noneSkipLast
        return hasAlpha ? .png : .jpeg
    }

    public func getTypeString() -> String? {
        let fmt = getFormat()
        return fmt == .undefined ? nil : fmt.rawValue
    }

    public static func resizeImage(_ image: UIImage, to targetSize: CGSize) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }

    public func getColor(at point: CGPoint) -> UIColor {
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

    public static func compressToSize(_ image: UIImage, maxFileSize: Int) -> Data? {
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

    public func crop(to rect: CGRect) -> UIImage? {
        guard let cgImage = self.cgImage?.cropping(to: rect) else { return nil }
        return UIImage(cgImage: cgImage)
    }

    public func rotate(by angle: CGFloat) -> UIImage? {
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

    public func roundedCorners(radius: CGFloat) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            let path = UIBezierPath(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: radius)
            path.addClip()
            draw(in: CGRect(origin: .zero, size: size))
        }
    }

    public func addBorder(width: CGFloat, color: UIColor) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            draw(in: CGRect(x: width, y: width, width: size.width - 2 * width, height: size.height - 2 * width))
        }
    }

    public static func smartCompress(_ image: UIImage,
                                     maxFileSize: Int,
                                     quality: CGFloat = 0.8,
                                     format: STImageFormat = .jpeg) -> Data? {
        let maxBytes = maxFileSize * 1024
        switch format {
        case .png:
            if let data = image.pngData(), data.count <= maxBytes { return data }
            return compressImageBySize(image, maxFileSize: maxBytes, format: .png)
        case .jpeg:
            guard var data = image.jpegData(compressionQuality: quality) else { return nil }
            if data.count <= maxBytes { return data }
            var minQuality: CGFloat = 0.1
            var maxQuality = quality
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
        if let data = originalData, !data.isEmpty {
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

    public func aspectFitScale(to targetSize: CGSize) -> UIImage? {
        let ratio = min(targetSize.width / size.width, targetSize.height / size.height)
        return UIImage.resizeImage(self, to: CGSize(width: size.width * ratio, height: size.height * ratio))
    }

    public func aspectFillScale(to targetSize: CGSize) -> UIImage? {
        let ratio = max(targetSize.width / size.width, targetSize.height / size.height)
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        guard let scaled = UIImage.resizeImage(self, to: newSize) else { return nil }
        let xOffset = (newSize.width - targetSize.width) / 2
        let yOffset = (newSize.height - targetSize.height) / 2
        return scaled.crop(to: CGRect(x: xOffset, y: yOffset, width: targetSize.width, height: targetSize.height))
    }

    public func addWatermark(_ watermarkImage: UIImage,
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

    public func applyBlur(radius: CGFloat = 10) -> UIImage? {
        guard let cgImage = self.cgImage else { return nil }
        let ciImage = CIImage(cgImage: cgImage)
        guard let filter = CIFilter(name: "CIGaussianBlur") else { return nil }
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(radius, forKey: kCIInputRadiusKey)
        guard let output = filter.outputImage,
              let blurredCGImage = UIImage.sharedCIContext.createCGImage(output, from: ciImage.extent) else { return nil }
        return UIImage(cgImage: blurredCGImage)
    }

    public func adjustBrightness(_ brightness: Float) -> UIImage? {
        guard let cgImage = self.cgImage else { return nil }
        let ciImage = CIImage(cgImage: cgImage)
        guard let filter = CIFilter(name: "CIColorControls") else { return nil }
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(brightness, forKey: kCIInputBrightnessKey)
        guard let output = filter.outputImage,
              let adjustedCGImage = UIImage.sharedCIContext.createCGImage(output, from: ciImage.extent) else { return nil }
        return UIImage(cgImage: adjustedCGImage)
    }

    // MARK: - 网络与相册

    public static func load(from url: URL) async throws -> UIImage {
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let image = UIImage(data: data) else { throw STImageError.invalidData }
        return image
    }

    public func saveToPhotoLibrary() async throws {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else {
            throw STImageError.photoLibraryPermissionDenied
        }
        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAsset(from: self)
        }
    }

    // MARK: - Factory

    /// 使用纯色生成指定尺寸的图片
    /// - Parameters:
    ///   - color: 填充颜色
    ///   - size: 图片尺寸
    ///   - scale: 渲染倍率，默认使用主屏幕倍率
    public static func solidColor(_ color: UIColor, size: CGSize, scale: CGFloat = UIScreen.main.scale) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { ctx in
            color.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }
    }

    /// 使用纯色生成可拉伸的单像素图，常用于给 UIButton/UINavigationBar 设置背景
    public static func stretchableSolidColor(_ color: UIColor) -> UIImage {
        solidColor(color, size: CGSize(width: 1, height: 1), scale: 1.0)
            .resizableImage(withCapInsets: .zero, resizingMode: .stretch)
    }

    /// 使用绘制闭包生成图像（背景透明，使用主屏幕倍率）
    public static func draw(size: CGSize, actions: (UIGraphicsImageRendererContext) -> Void) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image(actions: actions)
    }

    /// 用指定颜色填充非透明像素，保持原图的 alpha 通道；
    /// 与 `tinted(with:)` 的区别：该方法完全覆盖颜色而非混合
    public func masked(with color: UIColor) -> UIImage {
        let rect = CGRect(origin: .zero, size: size)
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { ctx in
            draw(in: rect)
            ctx.cgContext.setFillColor(color.cgColor)
            ctx.cgContext.setBlendMode(.sourceAtop)
            ctx.cgContext.fill(rect)
        }
    }

    /// 以 `sourceAtop` 方式叠加颜色，生成着色图
    public func tinted(with color: UIColor) -> UIImage {
        let rect = CGRect(origin: .zero, size: size)
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { _ in
            draw(in: rect)
            color.setFill()
            UIRectFillUsingBlendMode(rect, .sourceAtop)
        }
    }

    /// 按指定名称加载资源图，并使用目标颜色着色（等价于 FCUtilities 的 `fc_maskedImageNamed:color:`）
    public static func masked(named name: String, color: UIColor) -> UIImage? {
        UIImage(named: name)?.masked(with: color)
    }

    /// 将图像转换为去饱和（灰度）版本
    public func desaturated() -> UIImage {
        let rect = CGRect(origin: .zero, size: size)
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { ctx in
            draw(in: rect)
            ctx.cgContext.setFillColor(UIColor.black.cgColor)
            ctx.cgContext.setBlendMode(.saturation)
            ctx.cgContext.fill(rect)
        }
    }

    /// 在图像外围填充指定颜色的内边距
    /// - Parameters:
    ///   - color: 填充颜色
    ///   - insets: 边距（会自动取绝对值）
    public func padded(with color: UIColor, insets: UIEdgeInsets) -> UIImage {
        let top = abs(insets.top)
        let bottom = abs(insets.bottom)
        let left = abs(insets.left)
        let right = abs(insets.right)
        let newSize = CGSize(
            width: size.width + left + right,
            height: size.height + top + bottom
        )
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        return renderer.image { ctx in
            let entireRect = CGRect(origin: .zero, size: newSize)
            color.setFill()
            ctx.fill(entireRect)
            draw(in: entireRect.inset(by: UIEdgeInsets(top: top, left: left, bottom: bottom, right: right)))
        }
    }

    /// 在当前图像上追加额外的绘制操作
    public func withAdditionalDrawing(_ actions: (UIGraphicsImageRendererContext) -> Void) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { ctx in
            draw(in: CGRect(origin: .zero, size: size))
            actions(ctx)
        }
    }

    /// 以 iOS 风格的连续曲率圆角裁剪图像
    /// - Parameter cornerRadius: 圆角半径
    public func roundedImage(cornerRadius: CGFloat) -> UIImage {
        let rect = CGRect(origin: .zero, size: size)
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { _ in
            UIBezierPath(
                roundedRect: rect,
                byRoundingCorners: .allCorners,
                cornerRadii: CGSize(width: cornerRadius, height: cornerRadius)
            ).addClip()
            draw(in: rect)
        }
    }

    /// 以连续曲率圆角裁剪图像并绘制指定颜色/宽度的边框
    public func roundedImage(cornerRadius: CGFloat, borderColor: UIColor, borderWidth: CGFloat) -> UIImage {
        let halfBorder = borderWidth / 2.0
        let outputRect = CGRect(origin: .zero, size: size)
        let imageRect = outputRect.insetBy(dx: borderWidth, dy: borderWidth)
        let borderRect = outputRect.insetBy(dx: halfBorder, dy: halfBorder)
        let imageCornerRadius = max(0, cornerRadius - borderWidth)

        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { ctx in
            ctx.cgContext.saveGState()
            UIBezierPath(
                roundedRect: imageRect,
                byRoundingCorners: .allCorners,
                cornerRadii: CGSize(width: imageCornerRadius, height: imageCornerRadius)
            ).addClip()
            draw(in: imageRect)
            ctx.cgContext.restoreGState()

            let path = UIBezierPath(
                roundedRect: borderRect,
                byRoundingCorners: .allCorners,
                cornerRadii: CGSize(width: cornerRadius, height: cornerRadius)
            )
            path.lineWidth = borderWidth
            borderColor.setStroke()
            path.stroke()
        }
    }

    // MARK: - Pixel Enumeration / Similarity

    /// 遍历每个像素，回调 (x, y, r, g, b, a)
    public func enumeratePixels(_ body: (_ x: Int, _ y: Int, _ r: UInt8, _ g: UInt8, _ b: UInt8, _ a: UInt8) -> Void) {
        guard let cgImage else { return }
        let width = cgImage.width
        let height = cgImage.height
        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) else { return }

        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        var rawData = [UInt8](repeating: 0, count: height * bytesPerRow)

        guard let context = CGContext(
            data: &rawData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
        ) else { return }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        for y in 0..<height {
            for x in 0..<width {
                let offset = (y * bytesPerRow) + x * bytesPerPixel
                body(x, y, rawData[offset], rawData[offset + 1], rawData[offset + 2], rawData[offset + 3])
            }
        }
    }

    /// 与相同尺寸的另一张图比较相似度：1.0 完全相同，0.0 完全不同
    /// - Parameter other: 相同尺寸的另一张图像
    /// - Returns: 相似度或 nil（尺寸或数据不兼容）
    public func similarity(to other: UIImage) -> Float? {
        guard let a = cgImage, let b = other.cgImage else { return nil }
        let width = a.width
        let height = a.height
        guard b.width == width, b.height == height else { return nil }
        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) else { return nil }

        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        var dataA = [UInt8](repeating: 0, count: height * bytesPerRow)
        var dataB = [UInt8](repeating: 0, count: height * bytesPerRow)

        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
        guard let ctxA = CGContext(
            data: &dataA, width: width, height: height, bitsPerComponent: 8,
            bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo
        ), let ctxB = CGContext(
            data: &dataB, width: width, height: height, bitsPerComponent: 8,
            bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo
        ) else { return nil }

        ctxA.draw(a, in: CGRect(x: 0, y: 0, width: width, height: height))
        ctxB.draw(b, in: CGRect(x: 0, y: 0, width: width, height: height))

        var totalDifference: Float = 0
        for y in 0..<height {
            for x in 0..<width {
                let offset = (y * bytesPerRow) + x * bytesPerPixel
                let dr = Int(dataA[offset]) - Int(dataB[offset])
                let dg = Int(dataA[offset + 1]) - Int(dataB[offset + 1])
                let db = Int(dataA[offset + 2]) - Int(dataB[offset + 2])
                let da = Int(dataA[offset + 3]) - Int(dataB[offset + 3])
                let diffSquared = dr * dr + dg * dg + db * db + da * da
                totalDifference += Swift.min(1.0, Float(diffSquared) / Float(4 * 255 * 255))
            }
        }

        return 1.0 - (totalDifference / Float(width * height))
    }

    /// 从 Data 解码为 UIImage，可选缩放到最大边长
    /// - Parameters:
    ///   - data: 图片数据
    ///   - maxOutputDimension: 最大输出尺寸（>0 时启用缩略），0 表示原尺寸
    public static func decoded(from data: Data, maxOutputDimension: Int = 0) -> UIImage? {
        guard !data.isEmpty else { return nil }
        let options: [CFString: Any] = [kCGImageSourceShouldCache: false]
        guard let source = CGImageSourceCreateWithData(data as CFData, options as CFDictionary) else {
            return nil
        }

        let cgImage: CGImage?
        if maxOutputDimension > 0 {
            let thumbOptions: [CFString: Any] = [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceShouldCacheImmediately: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: maxOutputDimension
            ]
            cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, thumbOptions as CFDictionary)
        } else {
            let decodeOptions: [CFString: Any] = [kCGImageSourceShouldCacheImmediately: true]
            cgImage = CGImageSourceCreateImageAtIndex(source, 0, decodeOptions as CFDictionary)
        }
        return cgImage.map { UIImage(cgImage: $0) }
    }
}
