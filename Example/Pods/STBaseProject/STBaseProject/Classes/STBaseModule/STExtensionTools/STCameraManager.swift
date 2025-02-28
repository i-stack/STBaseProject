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

public class STCameraManager: NSObject {
    
    static let shared = STCameraManager()
    private var completion: ((STCameraModel) -> Void) = { _ in }
    private var imagePickerController: UIImagePickerController?

    public func st_openCamera(isFront cameraDevice: Bool, from viewController: UIViewController, overlayView: UIView?, completion: @escaping (STCameraModel) -> Void) {
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
                        strongSelf.st_showCustomCamera(isFront: cameraDevice, viewController: viewController, overlayView: overlayView)
                    } else {
                        completion(cameraModel)
                    }
                }
            }
        case .authorized:
            self.st_showCustomCamera(isFront: cameraDevice, viewController: viewController, overlayView: overlayView)
        case .denied, .restricted:
            DispatchQueue.main.async {
                completion(cameraModel)
            }
        default:
            break
        }
    }
    
    private func st_showCustomCamera(isFront cameraDevice: Bool, viewController: UIViewController, overlayView: UIView?) {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            self.imagePickerController = UIImagePickerController()
            self.imagePickerController?.sourceType = .camera
            self.imagePickerController?.allowsEditing = false
            self.imagePickerController?.delegate = self
            if let ov = overlayView {
                self.imagePickerController?.cameraOverlayView = ov
            } else {
                let ov = UIView(frame: CGRect.init(x: 0, y: 0, width: viewController.view.frame.size.width, height: viewController.view.frame.size.height - 200))
                ov.backgroundColor = .clear
                self.imagePickerController?.cameraOverlayView = ov
            }
            if cameraDevice {
                self.imagePickerController?.cameraDevice = .front
            }
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
    
    public func hiddenCameraOriginBtn(_ fromView: UIView) {
        for v in fromView.subviews {
            if v.description.contains("CAMFlipButton") {
                v.isHidden = true
                break
            }
            self.hiddenCameraOriginBtn(v)
        }
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
            model.image = image
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
