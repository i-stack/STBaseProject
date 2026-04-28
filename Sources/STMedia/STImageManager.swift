//
//  STImageManager.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2018/3/14.
//

import UIKit
import AVFoundation
import Photos
import PhotosUI

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

public struct STImageManagerConfiguration {
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
            return try await selectFromCamera(from: viewController)
        case .photoLibrary:
            return try await selectFromPhotoLibrary(from: viewController)
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
        return try await selectImage(from: viewController, source: source)
    }

    // MARK: - Private photo library

    private func selectFromPhotoLibrary(from viewController: UIViewController) async throws -> STImageManagerModel {
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
        try await checkCameraPermission()
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

    // MARK: - Private model builder

    private func buildModel(from image: UIImage, source: STImageSource) throws -> STImageManagerModel {
        let config = self.configuration
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
            self.pickerContinuation?.resume(throwing: STImageManagerError.userCancelled)
            self.pickerContinuation = nil
            return
        }
        guard result.itemProvider.canLoadObject(ofClass: UIImage.self) else {
            self.pickerContinuation?.resume(throwing: STImageManagerError.unknown)
            self.pickerContinuation = nil
            return
        }
        let continuation = self.pickerContinuation
        self.pickerContinuation = nil
        let maxFileSize = self.configuration.maxFileSize
        let imageFormat = self.configuration.imageFormat
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
                guard let compressedData = UIImage.smartCompress(image, maxFileSize: maxFileSize) else {
                    continuation?.resume(throwing: STImageManagerError.compressionFailed)
                    return
                }
                let format = image.getTypeString() ?? imageFormat
                let timestamp = Date().timeIntervalSince1970
                let model = STImageManagerModel(
                    image: image,
                    imageData: compressedData,
                    fileName: "photo_\(timestamp).\(format)",
                    mimeType: "image/\(format)",
                    source: .photoLibrary
                )
                continuation?.resume(returning: model)
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
            self.cameraContinuation?.resume(throwing: STImageManagerError.unknown)
            self.cameraContinuation = nil
            return
        }
        let continuation = self.cameraContinuation
        self.cameraContinuation = nil
        let maxFileSize = self.configuration.maxFileSize
        let imageFormat = self.configuration.imageFormat
        Task.detached(priority: .userInitiated) {
            guard let compressedData = UIImage.smartCompress(image, maxFileSize: maxFileSize) else {
                continuation?.resume(throwing: STImageManagerError.compressionFailed)
                return
            }
            let format = image.getTypeString() ?? imageFormat
            let timestamp = Date().timeIntervalSince1970
            let model = STImageManagerModel(
                image: image,
                imageData: compressedData,
                fileName: "photo_\(timestamp).\(format)",
                mimeType: "image/\(format)",
                source: .camera
            )
            continuation?.resume(returning: model)
        }
    }

    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
        self.cameraContinuation?.resume(throwing: STImageManagerError.userCancelled)
        self.cameraContinuation = nil
    }
}
