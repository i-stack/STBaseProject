//
//  STImageManager.swift
//  STBaseProject
//
//  Created by ST on 2025/1/13.
//

import UIKit
import AVFoundation
import Photos

// MARK: - 图片来源枚举
public enum STImageSource {
    case camera
    case photoLibrary
    case simulator
    case unknown
    
    public var description: String {
        switch self {
        case .camera:
            return "camera"
        case .photoLibrary:
            return "photo_library"
        case .simulator:
            return "simulator"
        case .unknown:
            return "unknown"
        }
    }
}

// MARK: - 统一图片管理器
/// 统一的图片管理器，整合相机、照片库和图片处理功能
public class STImageManager: NSObject {
    
    public static let shared = STImageManager()
    
    private var configuration: STImageManagerConfiguration = STImageManagerConfiguration()
    private var currentCompletion: STImageManagerCompletion?
    private var imagePickerController: UIImagePickerController?
    
    private override init() {
        super.init()
    }
    
    deinit {
        imagePickerController?.delegate = nil
        imagePickerController = nil
    }
    
    /// 更新配置
    public func updateConfiguration(_ config: STImageManagerConfiguration) {
        self.configuration = config
    }
    
    // MARK: - 主要 API
    
    /// 选择图片（相机或照片库）
    public func selectImage(from viewController: UIViewController,
                           source: STImageSource = .photoLibrary,
                           configuration: STImageManagerConfiguration? = nil,
                           completion: @escaping STImageManagerCompletion) {
        if let config = configuration {
            self.configuration = config
        }
        
        self.currentCompletion = completion
        
        switch source {
        case .camera:
            openCamera(from: viewController)
        case .photoLibrary:
            openPhotoLibrary(from: viewController)
        case .simulator:
            handleError(.deviceNotAvailable(.simulator))
        case .unknown:
            handleError(.unknown)
        }
    }
    
    /// 显示选择器（让用户选择相机或照片库）
    public func showImagePicker(from viewController: UIViewController,
                               configuration: STImageManagerConfiguration? = nil,
                               completion: @escaping STImageManagerCompletion) {
        if let config = configuration {
            self.configuration = config
        }
        
        self.currentCompletion = completion
        
        let alert = UIAlertController(title: "选择图片来源", message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "相机", style: .default) { _ in
            self.openCamera(from: viewController)
        })
        
        alert.addAction(UIAlertAction(title: "照片库", style: .default) { _ in
            self.openPhotoLibrary(from: viewController)
        })
        
        alert.addAction(UIAlertAction(title: "取消", style: .cancel) { _ in
            self.handleError(.userCancelled)
        })
        
        viewController.present(alert, animated: true)
    }
    
    // MARK: - 私有方法
    
    private func openCamera(from viewController: UIViewController) {
        checkCameraPermission { [weak self] result in
            switch result {
            case .success:
                self?.presentImagePicker(sourceType: .camera, from: viewController)
            case .failure(let error):
                self?.handleError(error)
            }
        }
    }
    
    private func openPhotoLibrary(from viewController: UIViewController) {
        checkPhotoLibraryPermission { [weak self] result in
            switch result {
            case .success:
                self?.presentImagePicker(sourceType: .photoLibrary, from: viewController)
            case .failure(let error):
                self?.handleError(error)
            }
        }
    }
    
    private func presentImagePicker(sourceType: UIImagePickerController.SourceType, from viewController: UIViewController) {
        imagePickerController = UIImagePickerController()
        imagePickerController?.sourceType = sourceType
        imagePickerController?.allowsEditing = configuration.allowsEditing
        imagePickerController?.delegate = self
        
        if sourceType == .camera {
            imagePickerController?.cameraDevice = configuration.cameraDevice
            imagePickerController?.showsCameraControls = configuration.showsCameraControls
        }
        
        viewController.present(imagePickerController!, animated: true)
    }
    
    private func checkCameraPermission(completion: @escaping (Result<Void, STImageManagerError>) -> Void) {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            completion(.failure(.deviceNotAvailable(.camera)))
            return
        }
        
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            completion(.success(()))
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        completion(.success(()))
                    } else {
                        completion(.failure(.permissionDenied(.camera)))
                    }
                }
            }
        case .denied, .restricted:
            completion(.failure(.permissionDenied(.camera)))
        @unknown default:
            completion(.failure(.unknown))
        }
    }
    
    private func checkPhotoLibraryPermission(completion: @escaping (Result<Void, STImageManagerError>) -> Void) {
        guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else {
            completion(.failure(.deviceNotAvailable(.photoLibrary)))
            return
        }
        
        let status = PHPhotoLibrary.authorizationStatus()
        switch status {
        case .authorized:
            completion(.success(()))
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { status in
                DispatchQueue.main.async {
                    if status == .authorized {
                        completion(.success(()))
                    } else {
                        completion(.failure(.permissionDenied(.photoLibrary)))
                    }
                }
            }
        case .denied, .restricted:
            completion(.failure(.permissionDenied(.photoLibrary)))
        @unknown default:
            completion(.failure(.unknown))
        }
    }
    
    private func handleError(_ error: STImageManagerError) {
        var model = STImageManagerModel()
        model.error = error
        currentCompletion?(model)
    }
}

// MARK: - UIImagePickerControllerDelegate
extension STImageManager: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        var model = STImageManagerModel()
        
        // 设置图片来源
        model.source = picker.sourceType == .camera ? .camera : .photoLibrary
        
        // 获取图片
        let imageKey = configuration.allowsEditing ? UIImagePickerController.InfoKey.editedImage : UIImagePickerController.InfoKey.originalImage
        guard let originalImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else {
            handleError(.unknown)
            picker.dismiss(animated: true)
            return
        }
        
        model.originalImage = originalImage
        
        // 处理编辑后的图片
        if configuration.allowsEditing, let editedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            model.editedImage = editedImage
        } else {
            model.editedImage = originalImage
        }
        
        // 压缩图片
        if let compressedData = UIImage.smartCompress(model.editedImage!, maxFileSize: configuration.maxFileSize) {
            model.imageData = compressedData
            #if DEBUG
            print("压缩后图片大小: \(compressedData.count / 1024) KB")
            #endif
        } else {
            model.error = .compressionFailed
        }
        
        // 设置文件信息
        if let type = model.editedImage!.getTypeString() {
            model.mimeType = "image/\(type)"
            model.fileName = "photo_\(Date().timeIntervalSince1970).\(type)"
        } else {
            model.mimeType = "image/\(configuration.imageFormat)"
            model.fileName = "photo_\(Date().timeIntervalSince1970).\(configuration.imageFormat)"
        }
        
        currentCompletion?(model)
        picker.dismiss(animated: true)
    }
    
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        var model = STImageManagerModel()
        model.error = .userCancelled
        currentCompletion?(model)
        picker.dismiss(animated: true)
    }
}

// MARK: - 数据模型
public struct STImageManagerModel {
    public var originalImage: UIImage?
    public var editedImage: UIImage?
    public var imageData: Data?
    public var fileName: String?
    public var mimeType: String?
    public var source: STImageSource?
    public var error: STImageManagerError?
    
    public init() {}
}

public struct STImageManagerConfiguration {
    public var allowsEditing: Bool = true
    public var showsCameraControls: Bool = true
    public var cameraDevice: UIImagePickerController.CameraDevice = .rear
    public var maxFileSize: Int = 300 // KB
    public var imageFormat: String = "jpeg"
    public var compressionQuality: CGFloat = 0.8
    
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
            return "permission_denied_\(source == .camera ? "camera" : "photo")".localized
        case .deviceNotAvailable(let source):
            return "device_not_available_\(source.description)".localized
        case .userCancelled:
            return "user_cancelled".localized
        case .compressionFailed:
            return "compression_failed".localized
        case .unknown:
            return "unknown_error".localized
        }
    }
}

public typealias STImageManagerCompletion = (STImageManagerModel) -> Void

// MARK: - 上传能力
public extension STImageManager {
    /// 通过 STImageManagerModel 上传图片
    func uploadImage(model: STImageManagerModel,
                     toURL urlString: String,
                     fieldName: String = "image",
                     parameters: [String: String] = [:],
                     completion: @escaping (Result<String, Error>) -> Void) {
        guard let data = model.imageData,
              let fileName = model.fileName,
              let mimeType = model.mimeType else {
            completion(.failure(NSError(domain: "STImageManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "invalid image model"])));
            return
        }
        upload(data: data,
               fileName: fileName,
               mimeType: mimeType,
               fieldName: fieldName,
               toURL: urlString,
               parameters: parameters,
               completion: completion)
    }

    /// 直接通过 data 上传图片
    func upload(data: Data,
                fileName: String,
                mimeType: String,
                fieldName: String = "image",
                toURL urlString: String,
                parameters: [String: String] = [:],
                completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "STImageManager", code: -2, userInfo: [NSLocalizedDescriptionKey: "invalid url"])));
            return
        }

        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = createFormDataBody(data: data,
                                             fileName: fileName,
                                             mimeType: mimeType,
                                             fieldName: fieldName,
                                             parameters: parameters,
                                             boundary: boundary)

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                    return
                }
                if let data = data, let result = String(data: data, encoding: .utf8) {
                    completion(.success(result))
                } else {
                    completion(.failure(NSError(domain: "STImageManager", code: -3, userInfo: [NSLocalizedDescriptionKey: "invalid response"])));
                }
            }
        }
        task.resume()
    }

    private func createFormDataBody(data: Data,
                                    fileName: String,
                                    mimeType: String,
                                    fieldName: String,
                                    parameters: [String: String],
                                    boundary: String) -> Data {
        var body = Data()
        for (key, value) in parameters {
            body.st_appendString("--\(boundary)\r\n")
            body.st_appendString("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
            body.st_appendString("\(value)\r\n")
        }
        body.st_appendString("--\(boundary)\r\n")
        body.st_appendString("Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(fileName)\"\r\n")
        body.st_appendString("Content-Type: \(mimeType)\r\n\r\n")
        body.append(data)
        body.st_appendString("\r\n")
        body.st_appendString("--\(boundary)--\r\n")
        return body
    }
}

private extension Data {
    mutating func st_appendString(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
