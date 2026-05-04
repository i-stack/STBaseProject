//
//  STImageManager.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2018/3/14.
//

import UIKit
import Photos
import PhotosUI
import AVFoundation

public enum STImageSource {
    case camera
    case photoLibrary
    case simulator
    case unknown

    public var description: String {
        switch self {
        case .camera: return "camera"
        case .photoLibrary: return "photo_library"
        case .simulator: return "simulator"
        case .unknown: return "unknown"
        }
    }
}

public struct STImageManagerModel {
    public let image: UIImage
    public let imageData: Data
    public let fileName: String
    public let mimeType: String
    public let source: STImageSource

    public init(image: UIImage, imageData: Data, fileName: String, mimeType: String, source: STImageSource) {
        self.image = image
        self.imageData = imageData
        self.fileName = fileName
        self.mimeType = mimeType
        self.source = source
    }
}

public struct STImageManagerConfiguration: Sendable {
    public var allowsEditing: Bool = true
    public var showsCameraControls: Bool = true
    public var cameraDevice: UIImagePickerController.CameraDevice = .rear
    public var maxFileSize: Int = 300
    public var imageFormat: String = "jpeg"
    public var compressionQuality: CGFloat = 0.8
    public var pickerTitle: String = "选择图片来源"
    public var cameraButtonTitle: String = "相机"
    public var photoLibraryButtonTitle: String = "照片库"
    public var cancelButtonTitle: String = "取消"

    public init() {}
}

public enum STImageManagerError: LocalizedError {
    case permissionDenied(STImageSource)
    case deviceNotAvailable(STImageSource)
    case userCancelled
    case compressionFailed
    case unknown

    public var errorDescription: String? {
        switch self {
        case .permissionDenied(let source):
            return "Permission denied for \(source.description)"
        case .deviceNotAvailable(let source):
            return "Device not available: \(source.description)"
        case .userCancelled:
            return "User cancelled"
        case .compressionFailed:
            return "Image compression failed"
        case .unknown:
            return "Unknown error occurred"
        }
    }
}

@MainActor
public class STImageManager: NSObject {

    public static let shared = STImageManager()

    private var configuration: STImageManagerConfiguration = STImageManagerConfiguration()
    private var pickerContinuation: CheckedContinuation<STImageManagerModel, Error>?
    private var cameraContinuation: CheckedContinuation<STImageManagerModel, Error>?
    private var imagePickerController: UIImagePickerController?

    private override init() {
        super.init()
    }

    deinit {
        self.imagePickerController = nil
    }

    public func updateConfiguration(_ config: STImageManagerConfiguration) {
        self.configuration = config
    }

    // MARK: - Public async API

    public func selectImage(
        from viewController: UIViewController,
        source: STImageSource = .photoLibrary,
        configuration: STImageManagerConfiguration? = nil
    ) async throws -> STImageManagerModel {
        if let config = configuration { self.configuration = config }
        switch source {
        case .camera:
            return try await self.selectFromCamera(from: viewController)
        case .photoLibrary:
            return try await self.selectFromPhotoLibrary(from: viewController)
        case .simulator:
            throw STImageManagerError.deviceNotAvailable(.simulator)
        case .unknown:
            throw STImageManagerError.unknown
        }
    }

    public func showImagePicker(
        from viewController: UIViewController,
        configuration: STImageManagerConfiguration? = nil
    ) async throws -> STImageManagerModel {
        if let config = configuration { self.configuration = config }
        let source: STImageSource = try await withCheckedThrowingContinuation { continuation in
            let alert = UIAlertController(title: self.configuration.pickerTitle, message: nil, preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: self.configuration.cameraButtonTitle, style: .default) { _ in
                continuation.resume(returning: .camera)
            })
            alert.addAction(UIAlertAction(title: self.configuration.photoLibraryButtonTitle, style: .default) { _ in
                continuation.resume(returning: .photoLibrary)
            })
            alert.addAction(UIAlertAction(title: self.configuration.cancelButtonTitle, style: .cancel) { _ in
                continuation.resume(throwing: STImageManagerError.userCancelled)
            })
            viewController.present(alert, animated: true)
        }
        return try await self.selectImage(from: viewController, source: source)
    }

    // MARK: - Private photo library

    private func selectFromPhotoLibrary(from viewController: UIViewController) async throws -> STImageManagerModel {
        // 取消之前未完成的请求，避免旧 continuation 永远挂起
        self.resolvePendingPickerContinuation(with: .userCancelled)
        return try await withCheckedThrowingContinuation { continuation in
            self.pickerContinuation = continuation
            var config = PHPickerConfiguration(photoLibrary: .shared())
            config.filter = .images
            config.selectionLimit = 1
            let picker = PHPickerViewController(configuration: config)
            picker.delegate = self
            viewController.present(picker, animated: true)
        }
    }

    // MARK: - Private camera

    private func selectFromCamera(from viewController: UIViewController) async throws -> STImageManagerModel {
        try await self.checkCameraPermission()
        // 取消之前未完成的请求，避免旧 continuation 永远挂起
        self.resolvePendingCameraContinuation(with: .userCancelled)
        return try await withCheckedThrowingContinuation { continuation in
            self.cameraContinuation = continuation
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.allowsEditing = self.configuration.allowsEditing
            picker.cameraDevice = self.configuration.cameraDevice
            picker.showsCameraControls = self.configuration.showsCameraControls
            picker.delegate = self
            self.imagePickerController = picker
            viewController.present(picker, animated: true)
        }
    }

    private func checkCameraPermission() async throws {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            throw STImageManagerError.deviceNotAvailable(.camera)
        }
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            return
        case .notDetermined:
            let granted: Bool = await withCheckedContinuation { continuation in
                AVCaptureDevice.requestAccess(for: .video) { continuation.resume(returning: $0) }
            }
            if !granted { throw STImageManagerError.permissionDenied(.camera) }
        case .denied, .restricted:
            throw STImageManagerError.permissionDenied(.camera)
        @unknown default:
            throw STImageManagerError.unknown
        }
    }

    // MARK: - Continuation 安全清理

    private func resolvePendingPickerContinuation(with error: STImageManagerError) {
        guard let pending = self.pickerContinuation else { return }
        self.pickerContinuation = nil
        pending.resume(throwing: error)
    }

    private func resolvePendingCameraContinuation(with error: STImageManagerError) {
        guard let pending = self.cameraContinuation else { return }
        self.cameraContinuation = nil
        pending.resume(throwing: error)
    }

    // MARK: - Model 构建（nonisolated 以便在 Task.detached 中调用）

    public nonisolated static func buildModel(
        from image: UIImage,
        source: STImageSource,
        config: STImageManagerConfiguration
    ) throws -> STImageManagerModel {
        guard let compressedData = UIImage.smartCompress(image, maxFileSize: config.maxFileSize) else {
            throw STImageManagerError.compressionFailed
        }
        let format = image.getTypeString() ?? config.imageFormat
        let timestamp = Date().timeIntervalSince1970
        return STImageManagerModel(
            image: image,
            imageData: compressedData,
            fileName: "photo_\(timestamp).\(format)",
            mimeType: "image/\(format)",
            source: source
        )
    }
}

// MARK: - PHPickerViewControllerDelegate

extension STImageManager: PHPickerViewControllerDelegate {
    public func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let result = results.first else {
            self.resolvePendingPickerContinuation(with: .userCancelled)
            return
        }
        guard result.itemProvider.canLoadObject(ofClass: UIImage.self) else {
            self.resolvePendingPickerContinuation(with: .unknown)
            return
        }
        let continuation = self.pickerContinuation
        self.pickerContinuation = nil
        let config = self.configuration
        result.itemProvider.loadObject(ofClass: UIImage.self) { object, error in
            if let error {
                continuation?.resume(throwing: error)
                return
            }
            guard let image = object as? UIImage else {
                continuation?.resume(throwing: STImageManagerError.unknown)
                return
            }
            Task.detached(priority: .userInitiated) {
                do {
                    let model = try STImageManager.buildModel(from: image, source: .photoLibrary, config: config)
                    continuation?.resume(returning: model)
                } catch {
                    continuation?.resume(throwing: error)
                }
            }
        }
    }
}

// MARK: - UIImagePickerControllerDelegate

extension STImageManager: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true)
        let imageKey: UIImagePickerController.InfoKey = self.configuration.allowsEditing ? .editedImage : .originalImage
        guard let image = info[imageKey] as? UIImage else {
            self.resolvePendingCameraContinuation(with: .unknown)
            return
        }
        let continuation = self.cameraContinuation
        self.cameraContinuation = nil
        let config = self.configuration
        Task.detached(priority: .userInitiated) {
            do {
                let model = try STImageManager.buildModel(from: image, source: .camera, config: config)
                continuation?.resume(returning: model)
            } catch {
                continuation?.resume(throwing: error)
            }
        }
    }

    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
        self.resolvePendingCameraContinuation(with: .userCancelled)
    }
}
