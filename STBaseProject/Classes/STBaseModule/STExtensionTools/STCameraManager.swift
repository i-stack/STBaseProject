//
//  STCameraManager.swift
//  STBaseProject
//
//  Created by song on 2025/1/13.
//

import UIKit
import AVFoundation

// MARK: - 枚举和错误类型
public enum STCameraImageSource: Int, CaseIterable {
    case photoLibrary = 1
    case camera = 2
    
    public var description: String {
        switch self {
        case .photoLibrary: return "photo_library".localized
        case .camera: return "camera".localized
        }
    }
}

public enum STCameraError: LocalizedError {
    case permissionDenied(STCameraImageSource)
    case deviceNotAvailable
    case compressionFailed
    case uploadFailed(Error)
    case invalidURL
    case unknown
    
    public var errorDescription: String? {
        switch self {
        case .permissionDenied(let source):
            return "permission_denied_\(source == .camera ? "camera" : "photo")".localized
        case .deviceNotAvailable:
            return "device_not_available".localized
        case .compressionFailed:
            return "compression_failed".localized
        case .uploadFailed(let error):
            return "upload_failed".localized + ": \(error.localizedDescription)"
        case .invalidURL:
            return "invalid_url".localized
        case .unknown:
            return "unknown_error".localized
        }
    }
}

// MARK: - 数据模型
public struct STCameraModel {
    public var image: UIImage?
    public var fileName: String?
    public var mimeType: String?
    public var imageData: Data?
    public var serviceKey: String = ""
    public var imageSource: STCameraImageSource?
    public var authorizationStatus: AVAuthorizationStatus?
    public var error: STCameraError?
    
    public init() {}
}

public struct STCameraConfiguration {
    public var compressImageMaxFileSize: Int = 300 // KB
    public var cameraDevice: UIImagePickerController.CameraDevice = .rear
    public var allowsEditing: Bool = true
    public var showsCameraControls: Bool = true
    public var compressionQuality: CGFloat = 0.8
    public var imageFormat: String = "jpeg"
    
    // 本地化支持
    public var permissionTitle: String = "camera_permission_title".localized
    public var permissionMessage: String = "camera_permission_message".localized
    public var settingsButtonTitle: String = "settings".localized
    public var cancelButtonTitle: String = "cancel".localized
    
    public init() {}
}

// MARK: - 相机管理器
public class STCameraManager: NSObject {
    
    public static let shared = STCameraManager()
    private var completion: ((STCameraModel) -> Void) = { _ in }
    private var imagePickerController: UIImagePickerController?
    private var configuration: STCameraConfiguration = STCameraConfiguration()
    
    private override init() {
        super.init()
    }
    
    deinit {
        imagePickerController?.delegate = nil
        imagePickerController = nil
    }
    
    /// 更新配置
    public func updateConfiguration(_ config: STCameraConfiguration) {
        self.configuration = config
    }
    
    /// 打开相机
    public func openCamera(from viewController: UIViewController, 
                          configuration: STCameraConfiguration? = nil,
                          completion: @escaping (STCameraModel) -> Void) {
        if let config = configuration {
            self.configuration = config
        }
        
        self.completion = completion
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.presentCamera(from: viewController)
                    } else {
                        self?.handlePermissionDenied(.camera)
                    }
                }
            }
        case .authorized:
            presentCamera(from: viewController)
        case .denied, .restricted:
            handlePermissionDenied(.camera)
        @unknown default:
            handleError(.unknown)
        }
    }
    
    /// 打开照片库
    public func openPhotoLibrary(from viewController: UIViewController,
                                configuration: STCameraConfiguration? = nil,
                                completion: @escaping (STCameraModel) -> Void) {
        if let config = configuration {
            self.configuration = config
        }
        
        self.completion = completion
        presentPhotoLibrary(from: viewController)
    }
    
    // MARK: - 私有方法
    private func presentCamera(from viewController: UIViewController) {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            handleError(.deviceNotAvailable)
            return
        }
        
        setupImagePickerController(sourceType: .camera)
        presentImagePicker(from: viewController)
    }
    
    private func presentPhotoLibrary(from viewController: UIViewController) {
        guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else {
            handleError(.deviceNotAvailable)
            return
        }
        
        setupImagePickerController(sourceType: .photoLibrary)
        presentImagePicker(from: viewController)
    }
    
    private func setupImagePickerController(sourceType: UIImagePickerController.SourceType) {
        imagePickerController = UIImagePickerController()
        imagePickerController?.sourceType = sourceType
        imagePickerController?.allowsEditing = configuration.allowsEditing
        imagePickerController?.delegate = self
        
        if sourceType == .camera {
            imagePickerController?.cameraDevice = configuration.cameraDevice
            imagePickerController?.showsCameraControls = configuration.showsCameraControls
        }
    }
    
    private func presentImagePicker(from viewController: UIViewController) {
        guard let picker = imagePickerController else { return }
        
        if let presentedVC = viewController.presentedViewController {
            presentedVC.dismiss(animated: false) {
                viewController.present(picker, animated: true)
            }
        } else {
            viewController.present(picker, animated: true)
        }
    }
    
    private func handlePermissionDenied(_ source: STCameraImageSource) {
        var model = STCameraModel()
        model.error = .permissionDenied(source)
        completion(model)
    }
    
    private func handleError(_ error: STCameraError) {
        var model = STCameraModel()
        model.error = error
        completion(model)
    }
}

// MARK: - UIImagePickerControllerDelegate
extension STCameraManager: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        var model = STCameraModel()
        
        // 设置图片来源
        model.imageSource = picker.sourceType == .camera ? .camera : .photoLibrary
        
        // 获取图片
        let imageKey = configuration.allowsEditing ? UIImagePickerController.InfoKey.editedImage : UIImagePickerController.InfoKey.originalImage
        guard let image = info[imageKey] as? UIImage ?? info[UIImagePickerController.InfoKey.originalImage] as? UIImage else {
            handleError(.unknown)
            picker.dismiss(animated: true)
            return
        }
        
        model.image = image
        
        // 压缩图片
        if let compressedData = UIImage.smartCompress(image, maxFileSize: configuration.compressImageMaxFileSize) {
            model.imageData = compressedData
            #if DEBUG
            print("压缩后图片大小: \(compressedData.count / 1024) KB")
            #endif
        } else {
            model.error = .compressionFailed
        }
        
        // 设置文件信息
        if let type = image.getTypeString() {
            model.mimeType = "image/\(type)"
            model.fileName = "photo_\(Date().timeIntervalSince1970).\(type)"
        } else {
            model.mimeType = "image/\(configuration.imageFormat)"
            model.fileName = "photo_\(Date().timeIntervalSince1970).\(configuration.imageFormat)"
        }
        
        completion(model)
        picker.dismiss(animated: true)
    }
    
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}

// MARK: - 上传功能
public extension STCameraManager {
    /// 上传图片
    func uploadImage(model: STCameraModel, 
                    toURL urlString: String,
                    parameters: [String: String] = [:],
                    completion: @escaping (Result<String, STCameraError>) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(.failure(.invalidURL))
            return
        }
        
        guard let imageData = model.imageData else {
            completion(.failure(.unknown))
            return
        }
        
        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = createFormDataBody(model: model, parameters: parameters, boundary: boundary)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(.uploadFailed(error)))
                    return
                }
                
                if let data = data, let result = String(data: data, encoding: .utf8) {
                    completion(.success(result))
                } else {
                    completion(.failure(.unknown))
                }
            }
        }
        task.resume()
    }
    
    /// 创建表单数据
    private func createFormDataBody(model: STCameraModel, parameters: [String: String], boundary: String) -> Data {
        var body = Data()
        
        // 添加其他参数
        for (key, value) in parameters {
            body.appendString("--\(boundary)\r\n")
            body.appendString("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
            body.appendString("\(value)\r\n")
        }
        
        // 添加图片数据
        body.appendString("--\(boundary)\r\n")
        let fieldName = model.serviceKey.isEmpty ? "image" : model.serviceKey
        let fileName = model.fileName ?? "image.jpg"
        body.appendString("Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(fileName)\"\r\n")
        body.appendString("Content-Type: \(model.mimeType ?? "image/jpeg")\r\n\r\n")
        body.append(model.imageData ?? Data())
        body.appendString("\r\n")
        body.appendString("--\(boundary)--\r\n")
        
        return body
    }
}

// MARK: - Data Extension
private extension Data {
    mutating func appendString(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
