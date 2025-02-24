//
//  STCameraManager.swift
//  UrtyePbhk
//
//  Created by song on 2025/1/13.
//

import UIKit
import AVFoundation

public enum STCamerImageSource: Int {
    case photoLibrary = 1
    case camera = 2
}

public struct STCameraModel {
    var image: UIImage?
    var fileName: String?
    var mimeType: String?
    var imageData: Data?
    var serviceKey: String = "" // need setting, upload image service-key
    var imageSource: STCamerImageSource?
    var authorizationStatus: AVAuthorizationStatus?
}

public struct STCameraConfiguration {
    var compressImageMaxFileSize: CGFloat?
    var cameraDevice: UIImagePickerController.CameraDevice?
    var permissionTitle: String = "Camera permission has been disabled"
    var permissionMessage: String = "Please go to settings to enable camera permissions"
}

public class STCameraManager: NSObject {
    
    static let shared = STCameraManager()
    private var completion: ((STCameraModel) -> Void) = { _ in }
    private var imagePickerController: UIImagePickerController?
    private var cameraConfig: STCameraConfiguration = STCameraConfiguration()

    public func st_openCamera(isFront cameraDevice: Bool, from viewController: UIViewController, completion: @escaping (STCameraModel) -> Void) {
        self.completion = completion
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        var cameraModel = STCameraModel()
        cameraModel.authorizationStatus = status
        switch status {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                guard let strongSelf = self else { return }
                DispatchQueue.main.async {
                    if granted {
                        strongSelf.st_showCustomCamera(isFront: cameraDevice, viewController: viewController)
                    } else {
                        completion(cameraModel)
                    }
                }
            }
        case .authorized:
            self.st_showCustomCamera(isFront: cameraDevice, viewController: viewController)
        case .denied, .restricted:
            completion(cameraModel)
        default:
            break
        }
    }
    
    private func st_showCustomCamera(isFront cameraDevice: Bool, viewController: UIViewController) {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            self.imagePickerController = UIImagePickerController()
            imagePickerController?.sourceType = .camera
            if cameraDevice {
                imagePickerController?.cameraDevice = .front
                imagePickerController?.showsCameraControls = false
                let overlayView = UIView(frame: viewController.view.bounds)
                overlayView.backgroundColor = .clear
                
                let captureButton = UIButton(frame: CGRect(x: (viewController.view.bounds.width - 70) / 2, y: viewController.view.bounds.height - 100, width: 70, height: 70))
                captureButton.layer.cornerRadius = 35
                captureButton.backgroundColor = .red
                captureButton.addTarget(self, action: #selector(st_capturePhoto), for: .touchUpInside)
                
                overlayView.addSubview(captureButton)
                imagePickerController?.cameraOverlayView = overlayView
            }
            imagePickerController?.allowsEditing = true
            imagePickerController?.delegate = self
            if let presentedVC = viewController.presentedViewController {
                presentedVC.dismiss(animated: true) {
                    viewController.present(self.imagePickerController ?? UIImagePickerController(), animated: true, completion: nil)
                }
            } else {
                viewController.present(self.imagePickerController ?? UIImagePickerController(), animated: true)
            }
        } else {
            print("camera can not use")
        }
    }
    
    @objc private func st_capturePhoto() {
        self.imagePickerController?.takePicture()
    }
    
    public func st_updateCameraConfiguration(config: STCameraConfiguration) {
        self.cameraConfig = config
    }
}

extension STCameraManager: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        var model = STCameraModel()
        if picker.sourceType == .photoLibrary {
            model.imageSource = .photoLibrary
        } else if picker.sourceType == .camera {
            model.imageSource = .camera
        }
        if let image = info[.originalImage] as? UIImage {
            if let compressedImageData = UIImage.st_compressImageToSize(image, maxFileSize: 300) {
                print("Compressed image size: \(compressedImageData.count / 1024) KB")
                model.image = image
                model.imageData = compressedImageData
            } else {
                print("Failed to compress image.")
            }
            if model.mimeType == nil {
                if let type = image.st_getImageType() {
                    model.mimeType = "image/\(type)"
                }
            }
        }
        model.fileName = "photo_\(UUID().uuidString).jpg"
        self.completion(model)
        picker.dismiss(animated: true, completion: nil)
    }
    
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}

public extension STCameraManager {
    func st_uploadImage(cameraModel: STCameraModel, otherParams: [String: String], httpBody: Data, urlString: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1, userInfo: nil)))
            return
        }
        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        let httpBody = self.st_createFormDataBody(cameraModel: cameraModel, otherParams: otherParams, boundary: boundary)
        request.httpBody = httpBody
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let data = data, let result = String(data: data, encoding: .utf8) {
                completion(.success(result))
            } else {
                completion(.failure(NSError(domain: "Invalid response", code: -1, userInfo: nil)))
            }
        }
        task.resume()
    }
        
    func st_createFormDataBody(cameraModel: STCameraModel, otherParams: [String: String], boundary: String) -> Data {
        var body = Data()
        for (key, value) in otherParams {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"\(cameraModel.serviceKey)\"; filename=\"\(cameraModel.fileName ?? "temp.image")\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(cameraModel.mimeType ?? "image/jpeg")\r\n\r\n".data(using: .utf8)!)
        body.append(cameraModel.imageData ?? Data())
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        return body
    }
}
