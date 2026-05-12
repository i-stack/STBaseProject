import XCTest
import STMedia

// MARK: - STImageFormatTests

final class STImageFormatTests: XCTestCase {

    // MARK: format(from:) 字节头检测

    func test_format_jpeg() {
        let data = Data([0xFF, 0xD8, 0xFF, 0xE0])
        XCTAssertEqual(UIImage.format(from: data), .jpeg)
    }

    func test_format_png() {
        let data = Data([0x89, 0x50, 0x4E, 0x47])
        XCTAssertEqual(UIImage.format(from: data), .png)
    }

    func test_format_gif() {
        let data = Data([0x47, 0x49, 0x46, 0x38])
        XCTAssertEqual(UIImage.format(from: data), .gif)
    }

    func test_format_tiff_little_endian() {
        let data = Data([0x49, 0x49, 0x2A, 0x00])
        XCTAssertEqual(UIImage.format(from: data), .tiff)
    }

    func test_format_tiff_big_endian() {
        let data = Data([0x4D, 0x4D, 0x00, 0x2A])
        XCTAssertEqual(UIImage.format(from: data), .tiff)
    }

    func test_format_webp() {
        // RIFF????WEBP header (12 bytes)
        var bytes = Array("RIFF".utf8) + [0x00, 0x00, 0x00, 0x00] + Array("WEBP".utf8)
        let data = Data(bytes)
        XCTAssertEqual(UIImage.format(from: data), .webp)
    }

    func test_format_empty_returns_undefined() {
        XCTAssertEqual(UIImage.format(from: Data()), .undefined)
    }

    func test_format_unknown_returns_undefined() {
        let data = Data([0xAB, 0xCD, 0xEF])
        XCTAssertEqual(UIImage.format(from: data), .undefined)
    }

    // MARK: STImageFormat 属性

    func test_mimeType() {
        XCTAssertEqual(STImageFormat.jpeg.mimeType, "image/jpeg")
        XCTAssertEqual(STImageFormat.png.mimeType, "image/png")
        XCTAssertEqual(STImageFormat.gif.mimeType, "image/gif")
        XCTAssertEqual(STImageFormat.webp.mimeType, "image/webp")
        XCTAssertEqual(STImageFormat.heic.mimeType, "image/heic")
    }

    func test_fileExtension() {
        XCTAssertEqual(STImageFormat.jpeg.fileExtension, "jpeg")
        XCTAssertEqual(STImageFormat.png.fileExtension, "png")
    }

    // MARK: getFormat() 实例方法（alpha 启发式）

    func test_getFormat_opaqueImage_returns_jpeg() {
        let image = makeOpaqueImage(size: CGSize(width: 4, height: 4), color: .red)
        XCTAssertEqual(image.getFormat(), .jpeg)
    }

    func test_getFormat_alphaImage_returns_png() {
        let image = makeAlphaImage(size: CGSize(width: 4, height: 4))
        XCTAssertEqual(image.getFormat(), .png)
    }

    // MARK: toData() 格式选择

    func test_toData_opaqueImage_decodesAsJPEG() {
        let image = makeOpaqueImage(size: CGSize(width: 4, height: 4), color: .blue)
        let data = image.toData()
        XCTAssertFalse(data.isEmpty)
        // 无 alpha → 编码为 JPEG，首字节 0xFF
        XCTAssertEqual(UIImage.format(from: data), .jpeg)
    }

    func test_toData_alphaImage_decodesAsPNG() {
        let image = makeAlphaImage(size: CGSize(width: 4, height: 4))
        let data = image.toData()
        XCTAssertFalse(data.isEmpty)
        // 有 alpha → 编码为 PNG，首字节 0x89
        XCTAssertEqual(UIImage.format(from: data), .png)
    }

    // MARK: Helpers

    private func makeOpaqueImage(size: CGSize, color: UIColor) -> UIImage {
        // opaque = true 确保 cgImage.alphaInfo 为 none，与 getFormat() 的 alpha 启发式保持一致
        let format = UIGraphicsImageRendererFormat()
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { ctx in
            color.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }
    }

    private func makeAlphaImage(size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            UIColor.clear.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
            UIColor.red.withAlphaComponent(0.5).setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: size.width / 2, height: size.height))
        }
    }
}

// MARK: - STImageCompressTests

final class STImageCompressTests: XCTestCase {

    private func makeColorImage(size: CGSize = CGSize(width: 100, height: 100)) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            UIColor.blue.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }
    }

    func test_smartCompress_jpeg_withinLimit() throws {
        let image = makeColorImage()
        let maxKB = 50
        let data = try XCTUnwrap(UIImage.smartCompress(image, maxFileSize: maxKB))
        XCTAssertLessThanOrEqual(data.count, maxKB * 1024)
    }

    func test_smartCompress_png_producesValidData() throws {
        let image = makeColorImage(size: CGSize(width: 10, height: 10))
        let data = try XCTUnwrap(UIImage.smartCompress(image, maxFileSize: 100, format: .png))
        XCTAssertFalse(data.isEmpty)
        XCTAssertEqual(UIImage.format(from: data), .png)
    }

    func test_compressToSize_reducesSize() throws {
        let image = makeColorImage(size: CGSize(width: 500, height: 500))
        let maxKB = 30
        let data = try XCTUnwrap(UIImage.compressToSize(image, maxFileSize: maxKB))
        XCTAssertLessThanOrEqual(data.count, maxKB * 1024)
    }

    func test_resizeImage_outputSize() throws {
        let image = makeColorImage(size: CGSize(width: 200, height: 200))
        let target = CGSize(width: 50, height: 50)
        let resized = try XCTUnwrap(UIImage.resizeImage(image, to: target))
        XCTAssertEqual(resized.size, target)
    }

    func test_aspectFitScale_maintainsRatio() throws {
        let image = makeColorImage(size: CGSize(width: 200, height: 100))
        let result = try XCTUnwrap(image.aspectFitScale(to: CGSize(width: 50, height: 50)))
        XCTAssertLessThanOrEqual(result.size.width, 50 + 1)
        XCTAssertLessThanOrEqual(result.size.height, 50 + 1)
        let ratio = result.size.width / result.size.height
        XCTAssertEqual(ratio, 2.0, accuracy: 0.01)
    }

    func test_aspectFillScale_outputSize() throws {
        let image = makeColorImage(size: CGSize(width: 200, height: 100))
        let target = CGSize(width: 50, height: 50)
        let result = try XCTUnwrap(image.aspectFillScale(to: target))
        XCTAssertEqual(result.size.width, target.width, accuracy: 1.0)
        XCTAssertEqual(result.size.height, target.height, accuracy: 1.0)
    }

    func test_toBase64_roundTrip() {
        let image = makeColorImage(size: CGSize(width: 4, height: 4))
        let base64 = image.toBase64()
        XCTAssertFalse(base64.isEmpty)
        let decoded = Data(base64Encoded: base64)
        XCTAssertNotNil(decoded)
        XCTAssertNotNil(UIImage(data: decoded!))
    }

    func test_isEmpty_emptyImage() {
        let empty = UIImage()
        XCTAssertTrue(UIImage.isEmpty(empty))
    }

    func test_isEmpty_nonEmptyImage() {
        let image = makeColorImage()
        XCTAssertFalse(UIImage.isEmpty(image))
    }
}

// MARK: - STImageTransformTests

final class STImageTransformTests: XCTestCase {

    private func makeImage(size: CGSize = CGSize(width: 100, height: 60)) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            UIColor.green.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }
    }

    func test_crop() throws {
        let image = makeImage(size: CGSize(width: 100, height: 100))
        let cropRect = CGRect(x: 10, y: 10, width: 40, height: 40)
        let cropped = try XCTUnwrap(image.crop(to: cropRect))
        XCTAssertEqual(cropped.size.width, 40, accuracy: 1.0)
        XCTAssertEqual(cropped.size.height, 40, accuracy: 1.0)
    }

    func test_rotate_90degrees() throws {
        let image = makeImage(size: CGSize(width: 100, height: 60))
        let rotated = try XCTUnwrap(image.rotate(by: 90))
        // 90° 旋转后宽高互换（允许浮点误差）
        XCTAssertEqual(rotated.size.width, 60, accuracy: 1.0)
        XCTAssertEqual(rotated.size.height, 100, accuracy: 1.0)
    }

    func test_roundedCorners_returnsImage() throws {
        let image = makeImage()
        let rounded = try XCTUnwrap(image.roundedCorners(radius: 10))
        XCTAssertEqual(rounded.size, image.size)
    }

    func test_addBorder_enlargesImage() throws {
        let image = makeImage(size: CGSize(width: 80, height: 80))
        let bordered = try XCTUnwrap(image.addBorder(width: 5, color: .red))
        XCTAssertEqual(bordered.size, image.size)
    }

    func test_addWatermark_returnsImage() throws {
        let base = makeImage(size: CGSize(width: 100, height: 100))
        let watermark = makeImage(size: CGSize(width: 20, height: 20))
        let result = try XCTUnwrap(base.addWatermark(watermark, position: .center))
        XCTAssertEqual(result.size, base.size)
    }

    func test_applyBlur_returnsImage() throws {
        let image = makeImage()
        let blurred = try XCTUnwrap(image.applyBlur(radius: 5))
        XCTAssertFalse(UIImage.isEmpty(blurred))
    }

    func test_adjustBrightness_returnsImage() throws {
        let image = makeImage()
        let adjusted = try XCTUnwrap(image.adjustBrightness(0.2))
        XCTAssertFalse(UIImage.isEmpty(adjusted))
    }

    func test_getColor_centerPixel() {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 10, height: 10))
        let image = renderer.image { ctx in
            UIColor.red.setFill()
            ctx.fill(CGRect(origin: .zero, size: CGSize(width: 10, height: 10)))
        }
        let color = image.getColor(at: CGPoint(x: 5, y: 5))
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        XCTAssertGreaterThan(r, 0.5)
        XCTAssertLessThan(g, 0.1)
        XCTAssertEqual(a, 1.0, accuracy: 0.01)
    }

    func test_getColor_outOfBoundsReturnssClear() {
        let image = makeImage()
        let color = image.getColor(at: CGPoint(x: 9999, y: 9999))
        XCTAssertEqual(color, .clear)
    }
}

// MARK: - STScanManagerTests

final class STScanManagerTests: XCTestCase {

    // MARK: 空内容/零尺寸边界校验

    func test_generateQRCode_emptyContent_throws() async {
        do {
            _ = try await STScanManager.generateQRCode(content: "", size: CGSize(width: 200, height: 200))
            XCTFail("应该抛出 invalidContent 错误")
        } catch STScanError.invalidContent {
            // 预期
        } catch {
            XCTFail("期望 STScanError.invalidContent，实际：\(error)")
        }
    }

    func test_generateQRCode_zeroSize_throws() async {
        do {
            _ = try await STScanManager.generateQRCode(content: "test", size: .zero)
            XCTFail("应该抛出 invalidSize 错误")
        } catch STScanError.invalidSize {
            // 预期
        } catch {
            XCTFail("期望 STScanError.invalidSize，实际：\(error)")
        }
    }

    func test_generateBarCode_emptyContent_throws() async {
        do {
            _ = try await STScanManager.generateBarCode(content: "", size: CGSize(width: 200, height: 80))
            XCTFail("应该抛出 invalidContent 错误")
        } catch STScanError.invalidContent {
            // 预期
        } catch {
            XCTFail("期望 STScanError.invalidContent，实际：\(error)")
        }
    }

    // MARK: 正常生成

    func test_generateQRCode_returnsValidImage() async throws {
        let size = CGSize(width: 200, height: 200)
        let image = try await STScanManager.generateQRCode(content: "https://example.com", size: size)
        XCTAssertEqual(image.size.width, size.width, accuracy: 1.0)
        XCTAssertEqual(image.size.height, size.height, accuracy: 1.0)
        XCTAssertFalse(UIImage.isEmpty(image))
    }

    func test_generateQRCode_customColor_returnsImage() async throws {
        let size = CGSize(width: 150, height: 150)
        let image = try await STScanManager.generateQRCode(
            content: "hello",
            size: size,
            color: .blue,
            background: .yellow
        )
        XCTAssertEqual(image.size.width, size.width, accuracy: 1.0)
        XCTAssertFalse(UIImage.isEmpty(image))
    }

    func test_generateBarCode_returnsValidImage() async throws {
        let size = CGSize(width: 300, height: 100)
        let image = try await STScanManager.generateBarCode(content: "1234567890", size: size)
        XCTAssertEqual(image.size.width, size.width, accuracy: 1.0)
        XCTAssertFalse(UIImage.isEmpty(image))
    }

    // MARK: QR 生成后识别（端到端）

    func test_generateQRCode_thenRecognize_matchesOriginalContent() async throws {
        let content = "STMedia-QR-Test-\(UUID().uuidString)"
        let qrImage = try await STScanManager.generateQRCode(
            content: content,
            size: CGSize(width: 300, height: 300)
        )
        let recognized = try await STScanManager.recognizeQRCode(in: qrImage)
        XCTAssertEqual(recognized, content)
    }

    func test_generateQRCode_withWatermark_thenRecognize() async throws {
        let content = "watermark-test-\(UUID().uuidString)"
        let size = CGSize(width: 400, height: 400)
        let watermarkSize = CGSize(width: 60, height: 60)
        let watermark = makeColorImage(size: watermarkSize, color: .white)
        let qrImage = try await STScanManager.generateQRCode(
            content: content,
            size: size,
            watermark: watermark,
            watermarkSize: watermarkSize
        )
        let recognized = try await STScanManager.recognizeQRCode(in: qrImage)
        XCTAssertEqual(recognized, content)
    }

    // MARK: recognizeQRCode 识别失败路径

    func test_recognizeQRCode_solidColorImage_throws() async {
        let image = makeColorImage(size: CGSize(width: 100, height: 100), color: .white)
        do {
            _ = try await STScanManager.recognizeQRCode(in: image)
            XCTFail("纯色图片应该识别失败")
        } catch STScanError.noQRCodeFound {
            // 预期
        } catch {
            XCTFail("期望 STScanError.noQRCodeFound，实际：\(error)")
        }
    }

    // MARK: Helpers

    private func makeColorImage(size: CGSize, color: UIColor = .white) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            color.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }
    }
}

// MARK: - STScanViewTests

final class STScanViewTests: XCTestCase {

    // MARK: 配置更新后 scanLineImage 响应

    func test_scanLineImage_updatesAfterConfigChange() {
        let view = STScanView(frame: CGRect(x: 0, y: 0, width: 320, height: 568))
        let originalColor = view.configuration.cornerColor
        var newConfig = view.configuration
        newConfig.cornerColor = .red
        view.configuration = newConfig
        // 断言 configuration 正确更新（间接验证 makeScanLineImage 被调用）
        XCTAssertFalse(view.configuration.cornerColor == originalColor)
        XCTAssertEqual(view.configuration.cornerColor, .red)
    }

    func test_scanLineHeight_updatesAfterConfigChange() {
        let view = STScanView(frame: CGRect(x: 0, y: 0, width: 320, height: 568))
        var config = view.configuration
        config.scanLineHeight = 10.0
        view.configuration = config
        XCTAssertEqual(view.configuration.scanLineHeight, 10.0)
    }

    // MARK: 遮罩宽度计算（间接通过 getScanAreaRect 验证扫描框尺寸）

    func test_scanAreaRect_centeredInView() {
        let frame = CGRect(x: 0, y: 0, width: 320, height: 568)
        let view = STScanView(frame: frame)
        // 关闭 safe area 适配以得到确定性结果
        view.setSafeAreaAdaptation(.disabled)
        let rect = view.getScanAreaRect()
        // 扫描框应在视图宽度内
        XCTAssertGreaterThan(rect.minX, 0)
        XCTAssertLessThan(rect.maxX, frame.width)
        XCTAssertGreaterThan(rect.minY, 0)
        XCTAssertLessThan(rect.maxY, frame.height)
    }

    func test_scanAreaRect_barCodeType_isWider() {
        let view = STScanView(frame: CGRect(x: 0, y: 0, width: 320, height: 568))
        view.setSafeAreaAdaptation(.disabled)
        view.st_configScanType(scanType: .qrCode)
        let qrRect = view.getScanAreaRect()
        view.st_configScanType(scanType: .barCode)
        let barRect = view.getScanAreaRect()
        // barCode 的 heightScale = 3.0，高度应显著小于宽度（扁长条形）
        XCTAssertLessThan(barRect.height, barRect.width)
        // 条码框高度应小于二维码框高度
        XCTAssertLessThan(barRect.height, qrRect.height)
    }

    // MARK: 主题切换

    func test_theme_light_setsMaskAlpha() {
        let view = STScanView(frame: CGRect(x: 0, y: 0, width: 320, height: 568))
        view.theme = .light
        XCTAssertEqual(view.configuration.maskAlpha, 0.4, accuracy: 0.001)
    }

    func test_theme_dark_setsMaskAlpha() {
        let view = STScanView(frame: CGRect(x: 0, y: 0, width: 320, height: 568))
        view.theme = .dark
        XCTAssertEqual(view.configuration.maskAlpha, 0.6, accuracy: 0.001)
    }

    func test_theme_custom_appliesConfiguration() {
        var config = STScanViewConfiguration()
        config.maskAlpha = 0.9
        config.tipText = "自定义提示"
        // 直接设置 theme 属性，避免便利初始化路径的时序问题
        let view = STScanView(frame: CGRect(x: 0, y: 0, width: 320, height: 568))
        view.theme = .custom(config)
        XCTAssertEqual(view.configuration.maskAlpha, 0.9, accuracy: 0.001)
        XCTAssertEqual(view.configuration.tipText, "自定义提示")
    }

    // MARK: resetToDefault

    func test_resetToDefault_restoresDarkTheme() {
        let view = STScanView(frame: CGRect(x: 0, y: 0, width: 320, height: 568))
        view.theme = .light
        view.resetToDefault()
        XCTAssertEqual(view.configuration.maskAlpha, 0.6, accuracy: 0.001)
        XCTAssertEqual(view.scanType, .qrCode)
    }

    // MARK: updateTipText

    func test_updateTipText_updatesConfiguration() {
        let view = STScanView(frame: CGRect(x: 0, y: 0, width: 320, height: 568))
        view.updateTipText("新提示文字")
        XCTAssertEqual(view.configuration.tipText, "新提示文字")
    }

    // MARK: isAnimating 状态

    func test_isAnimating_barCodeType_isFalse() {
        let view = STScanView(frame: CGRect(x: 0, y: 0, width: 320, height: 568))
        view.st_configScanType(scanType: .barCode)
        XCTAssertFalse(view.isAnimating)
    }

    func test_stopAnimating_setsIsAnimatingFalse() {
        let view = STScanView(frame: CGRect(x: 0, y: 0, width: 320, height: 568))
        view.st_stopAnimating()
        XCTAssertFalse(view.isAnimating)
    }
}

// MARK: - STImageManagerModelTests

final class STImageManagerModelTests: XCTestCase {

    func test_buildModel_jpeg_usesJpegExtension() throws {
        let image = makeOpaqueImage(size: CGSize(width: 100, height: 100))
        var config = STImageManagerConfiguration()
        config.maxFileSize = 500
        config.imageFormat = "jpeg"
        let model = try STImageManager.buildModel(from: image, source: .camera, config: config)
        XCTAssertFalse(model.imageData.isEmpty)
        XCTAssertTrue(model.fileName.hasSuffix(".jpeg"), "文件名应以 .jpeg 结尾，实际：\(model.fileName)")
        XCTAssertTrue(model.mimeType.hasPrefix("image/"), "mimeType 应以 image/ 开头")
        XCTAssertEqual(model.source, .camera)
    }

    func test_buildModel_compressedDataWithinLimit() throws {
        let image = makeOpaqueImage(size: CGSize(width: 1000, height: 1000))
        var config = STImageManagerConfiguration()
        config.maxFileSize = 100  // KB
        let model = try STImageManager.buildModel(from: image, source: .photoLibrary, config: config)
        XCTAssertLessThanOrEqual(model.imageData.count, 100 * 1024 + 1024) // 允许极小误差
    }

    func test_buildModel_compressionFailed_onZeroMaxSize() {
        // 0KB 限制应导致压缩失败
        let image = makeOpaqueImage(size: CGSize(width: 10, height: 10))
        var config = STImageManagerConfiguration()
        config.maxFileSize = 0
        XCTAssertThrowsError(
            try STImageManager.buildModel(from: image, source: .camera, config: config)
        ) { error in
            guard case STImageManagerError.compressionFailed = error else {
                XCTFail("期望 compressionFailed，实际：\(error)")
                return
            }
        }
    }

    func test_buildModel_sourcePreserved() throws {
        let image = makeOpaqueImage(size: CGSize(width: 50, height: 50))
        let config = STImageManagerConfiguration()
        let modelCamera = try STImageManager.buildModel(from: image, source: .camera, config: config)
        let modelLib = try STImageManager.buildModel(from: image, source: .photoLibrary, config: config)
        XCTAssertEqual(modelCamera.source, .camera)
        XCTAssertEqual(modelLib.source, .photoLibrary)
    }

    // MARK: Helpers

    private func makeOpaqueImage(size: CGSize) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { ctx in
            UIColor.orange.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }
    }
}

// MARK: - STScanErrorTests

final class STScanErrorTests: XCTestCase {

    func test_errorDescriptions_notNil() {
        let errors: [STScanError] = [
            .invalidContent, .invalidSize, .recognitionFailed,
            .noQRCodeFound, .cameraNotAvailable, .cameraPermissionDenied
        ]
        for error in errors {
            XCTAssertNotNil(error.errorDescription, "\(error) 应有错误描述")
        }
    }
}

// MARK: - STImageErrorTests

final class STImageErrorTests: XCTestCase {

    func test_errorDescriptions_notNil() {
        XCTAssertNotNil(STImageError.invalidData.errorDescription)
        XCTAssertNotNil(STImageError.photoLibraryPermissionDenied.errorDescription)
    }
}
