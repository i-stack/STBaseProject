//
//  STScanManager.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2018/3/14.
//

import UIKit
import Photos
import AVFoundation

public enum STScanType {
    case qrCode
    case barCode
    case all
}

public typealias STScanFinishBlock = (_ result: String) -> Void

public enum STScanError: LocalizedError {
    case invalidContent
    case invalidSize
    case recognitionFailed
    case noQRCodeFound
    case cameraNotAvailable
    case cameraPermissionDenied

    public var errorDescription: String? {
        switch self {
        case .invalidContent: return "Content is empty"
        case .invalidSize: return "Size is zero"
        case .recognitionFailed: return "Failed to process image"
        case .noQRCodeFound: return "No QR code found in image"
        case .cameraNotAvailable: return "Camera is not available"
        case .cameraPermissionDenied: return "Camera permission denied"
        }
    }
}

public class STScanManager: NSObject {

    public var scanRect: CGRect?
    public var scanRectView: STScanView?

    private weak var presentVC: UIViewController?
    private var scanFinishBlock: STScanFinishBlock?
    private var scanType: STScanType = .qrCode

    private var device: AVCaptureDevice?
    private var session: AVCaptureSession?
    private var input: AVCaptureDeviceInput?
    private var output: AVCaptureMetadataOutput?
    private var preview: AVCaptureVideoPreviewLayer?

    public init(presentViewController: UIViewController) {
        super.init()
        self.presentVC = presentViewController
    }

    public init(qrType type: STScanType, presentViewController: UIViewController, onFinish: @escaping STScanFinishBlock) {
        super.init()
        self.presentVC = presentViewController
        self.scanType = type
        self.scanFinishBlock = onFinish
        self.configScanManager()
    }

    deinit {
        self.session?.stopRunning()
        self.session = nil
    }

    // MARK: - Public instance API

    public func st_scanFinishCallback(block: @escaping STScanFinishBlock) {
        self.scanFinishBlock = block
    }

    public func st_beginScan() {
        self.session?.startRunning()
    }

    public func st_stopScan() {
        guard let session = self.session, session.isRunning else { return }
        session.stopRunning()
    }

    public func detailSelectPhoto(image: UIImage) {
        Task { [weak self] in
            guard let self else { return }
            do {
                let result = try await STScanManager.recognizeQRCode(in: image)
                self.st_renderUrlStr(url: result)
            } catch {
                self.st_renderUrlStr(url: "")
            }
        }
    }

    // MARK: - Static async API

    public static func recognizeQRCode(in image: UIImage) async throws -> String {
        guard let ciImage = CIImage(image: image) else { throw STScanError.recognitionFailed }
        let context = CIContext()
        let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: context, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])
        let features = detector?.features(in: ciImage) ?? []
        guard let feature = features.first as? CIQRCodeFeature,
              let result = feature.messageString else {
            throw STScanError.noQRCodeFound
        }
        return result
    }

    public static func generateQRCode(
        content: String,
        size: CGSize,
        color: UIColor = .black,
        background: UIColor = .white
    ) async throws -> UIImage {
        guard !content.isEmpty else { throw STScanError.invalidContent }
        guard size != .zero else { throw STScanError.invalidSize }
        return try _generateQRImage(content: content, size: size, color: color, background: background)
    }

    public static func generateQRCode(
        content: String,
        size: CGSize,
        watermark: UIImage,
        watermarkSize: CGSize
    ) async throws -> UIImage {
        guard !content.isEmpty else { throw STScanError.invalidContent }
        guard size != .zero, watermarkSize != .zero else { throw STScanError.invalidSize }
        return try _generateQRImageWithWatermark(content: content, size: size, watermark: watermark, watermarkSize: watermarkSize)
    }

    public static func generateBarCode(
        content: String,
        size: CGSize,
        color: UIColor = .black,
        background: UIColor = .white
    ) async throws -> UIImage {
        guard !content.isEmpty else { throw STScanError.invalidContent }
        guard size != .zero else { throw STScanError.invalidSize }
        return try _generateBarCodeImage(content: content, size: size, color: color, background: background)
    }

    // MARK: - Private image helpers

    private static func _generateQRImage(
        content: String,
        size: CGSize,
        color: UIColor,
        background: UIColor
    ) throws -> UIImage {
        guard let data = content.data(using: .utf8) else { throw STScanError.invalidContent }
        guard let qrFilter = CIFilter(name: "CIQRCodeGenerator") else { throw STScanError.recognitionFailed }
        qrFilter.setValue(data, forKey: "inputMessage")
        qrFilter.setValue("H", forKey: "inputCorrectionLevel")
        guard let colorFilter = CIFilter(name: "CIFalseColor", parameters: [
            "inputImage": qrFilter.outputImage ?? CIImage.empty(),
            "inputColor0": CIColor(cgColor: color.cgColor),
            "inputColor1": CIColor(cgColor: background.cgColor)
        ]) else { throw STScanError.recognitionFailed }
        let ciImage = colorFilter.outputImage ?? CIImage.empty()
        guard let cgImage = CIContext().createCGImage(ciImage, from: ciImage.extent) else {
            throw STScanError.recognitionFailed
        }
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            ctx.cgContext.interpolationQuality = .none
            UIImage(cgImage: cgImage).draw(in: CGRect(origin: .zero, size: size))
        }
    }

    private static func _generateBarCodeImage(
        content: String,
        size: CGSize,
        color: UIColor,
        background: UIColor
    ) throws -> UIImage {
        guard let data = content.data(using: .utf8) else { throw STScanError.invalidContent }
        guard let barFilter = CIFilter(name: "CICode128BarcodeGenerator") else { throw STScanError.recognitionFailed }
        barFilter.setValue(data, forKey: "inputMessage")
        guard let colorFilter = CIFilter(name: "CIFalseColor", parameters: [
            "inputImage": barFilter.outputImage ?? CIImage.empty(),
            "inputColor0": CIColor(cgColor: color.cgColor),
            "inputColor1": CIColor(cgColor: background.cgColor)
        ]) else { throw STScanError.recognitionFailed }
        let ciImage = colorFilter.outputImage ?? CIImage.empty()
        guard let cgImage = CIContext().createCGImage(ciImage, from: ciImage.extent) else {
            throw STScanError.recognitionFailed
        }
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            ctx.cgContext.interpolationQuality = .none
            UIImage(cgImage: cgImage).draw(in: CGRect(origin: .zero, size: size))
        }
    }

    private static func _generateQRImageWithWatermark(
        content: String,
        size: CGSize,
        watermark: UIImage,
        watermarkSize: CGSize
    ) throws -> UIImage {
        guard let data = content.data(using: .utf8) else { throw STScanError.invalidContent }
        guard let qrFilter = CIFilter(name: "CIQRCodeGenerator") else { throw STScanError.recognitionFailed }
        qrFilter.setValue(data, forKey: "inputMessage")
        qrFilter.setValue("H", forKey: "inputCorrectionLevel")
        let ciImage = qrFilter.outputImage ?? CIImage.empty()
        let extent = ciImage.extent.integral
        let scale = min(size.width / extent.width, size.height / extent.height)
        let scaledWidth = extent.width * scale
        let scaledHeight = extent.height * scale
        let cs = CGColorSpaceCreateDeviceGray()
        guard let bitmapCtx = CGContext(
            data: nil,
            width: Int(scaledWidth), height: Int(scaledHeight),
            bitsPerComponent: 8, bytesPerRow: 0,
            space: cs,
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else { throw STScanError.recognitionFailed }
        guard let baseCGImage = CIContext().createCGImage(ciImage, from: extent) else {
            throw STScanError.recognitionFailed
        }
        bitmapCtx.interpolationQuality = .none
        bitmapCtx.scaleBy(x: scale, y: scale)
        bitmapCtx.draw(baseCGImage, in: extent)
        guard let scaledCGImage = bitmapCtx.makeImage() else { throw STScanError.recognitionFailed }
        let baseImage = UIImage(cgImage: scaledCGImage)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            baseImage.draw(in: CGRect(origin: .zero, size: size))
            let origin = CGPoint(
                x: (size.width - watermarkSize.width) / 2.0,
                y: (size.height - watermarkSize.height) / 2.0
            )
            watermark.draw(in: CGRect(origin: origin, size: watermarkSize))
        }
    }

    // MARK: - Private setup

    private func configScanManager() {
        self.st_scanDevice()
        self.st_drawScanView()
    }

    private func st_scanDevice() {
        self.checkCameraPermission { [weak self] granted in
            guard let self, granted else { return }
            guard let device = AVCaptureDevice.default(for: .video) else { return }
            self.device = device
            guard let input = try? AVCaptureDeviceInput(device: device) else { return }
            self.input = input
            let output = AVCaptureMetadataOutput()
            self.output = output
            output.setMetadataObjectsDelegate(self, queue: .main)
            let session = AVCaptureSession()
            self.session = session
            if session.canAddInput(input) { session.addInput(input) }
            if session.canAddOutput(output) {
                session.addOutput(output)
                output.metadataObjectTypes = self.metadataObjectTypes(for: self.scanType)
                output.rectOfInterest = self.st_scanRectWithScale(scale: 1).rectOfInterest
            }
            let preview = AVCaptureVideoPreviewLayer(session: session)
            self.preview = preview
            preview.videoGravity = .resizeAspectFill
            preview.frame = UIScreen.main.bounds
            self.presentVC?.view.layer.insertSublayer(preview, at: 0)
        }
    }

    private func metadataObjectTypes(for type: STScanType) -> [AVMetadataObject.ObjectType] {
        switch type {
        case .qrCode: return [.qr]
        case .barCode: return [.code128, .code39, .ean13, .ean8, .upce, .pdf417]
        case .all: return [.qr, .code128, .code39, .ean13, .ean8, .upce, .pdf417]
        }
    }

    private func checkCameraPermission(completion: @escaping (Bool) -> Void) {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            completion(false)
            return
        }
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            completion(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async { completion(granted) }
            }
        case .denied, .restricted:
            completion(false)
        @unknown default:
            completion(false)
        }
    }

    private func st_drawScanView() {
        let width = self.presentVC?.view.bounds.size.width ?? UIScreen.main.bounds.width
        let height = self.presentVC?.view.bounds.size.height ?? UIScreen.main.bounds.height
        let view = STScanView(frame: CGRect(x: 0, y: 0, width: width, height: height))
        view.st_configScanType(scanType: self.scanType)
        self.scanRectView = view
        self.presentVC?.view.addSubview(view)
    }

    private func st_scanRectWithScale(scale: CGFloat) -> (rectOfInterest: CGRect, scanSize: CGSize) {
        let windowSize = UIScreen.main.bounds.size
        let left = 60.0 / scale
        let scanWidth = (self.presentVC?.view.frame.size.width ?? windowSize.width) - left * 2.0
        let scanSize = CGSize(width: scanWidth, height: scanWidth / scale)
        let scanX = (windowSize.width - scanSize.width) / 2.0
        let scanY = (windowSize.height - scanSize.height) / 2.0
        // AVFoundation rectOfInterest: normalized coords, axes swapped vs portrait screen
        let rectOfInterest = CGRect(
            x: scanY / windowSize.height,
            y: scanX / windowSize.width,
            width: scanSize.height / windowSize.height,
            height: scanSize.width / windowSize.width
        )
        return (rectOfInterest, scanSize)
    }

    private func st_renderUrlStr(url: String) {
        self.scanFinishBlock?(url)
    }
}

extension STScanManager: AVCaptureMetadataOutputObjectsDelegate {
    public func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject else { return }
        self.st_stopScan()
        self.st_renderUrlStr(url: metadataObject.stringValue ?? "")
    }
}
