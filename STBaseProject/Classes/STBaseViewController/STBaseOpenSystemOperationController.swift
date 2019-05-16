//
//  STBaseOpenSystemOperationController.swift
//  STBaseProject
//
//  Created by song on 2018/4/28.
//  Copyright © 2018 song. All rights reserved.
//

import UIKit
import Photos
import AVFoundation
import AssetsLibrary

enum STOpenSourceType {
    case photoLibrary
    case camera
    case unknown
}

enum STOpenSourceError: LocalizedError {
    
    case openSourceOK
    case openCameraError
    case openPhotoLibraryError
    case imagePickerControllerDidCancelError

    var errorDescription: String {
        switch self {
        case .openCameraError:
            return "open Camera Error"
        case .openPhotoLibraryError:
            return "open PhotoLibrary Error"
        case .imagePickerControllerDidCancelError:
            return "image pickerController did cancel"
        case .openSourceOK:
            return ""
        }
    }
}

typealias STImagePickerResult = (_ originalImage: UIImage, _ editedImage: UIImage, _ result: Bool, _ error: STOpenSourceError) -> Void

class STBaseOpenSystemOperationController: STBaseViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    var customImageSize: CGSize?
    var picker: UIImagePickerController!
    var imagePickerResult: STImagePickerResult?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.imagePickerViewController()
    }

    func imagePickerViewController() -> Void {
        guard self.picker != nil else {
            self.picker = UIImagePickerController()
            self.picker.delegate = self
            self.picker.allowsEditing = true
            return
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true) {
            DispatchQueue.main.async {
                if let complection = self.imagePickerResult {
                    complection(UIImage(), UIImage(), false, .imagePickerControllerDidCancelError)
                }
            }
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let originalImage: UIImage = info[UIImagePickerController.InfoKey.originalImage] as! UIImage
        let editedImage: UIImage = info[UIImagePickerController.InfoKey.editedImage] as! UIImage
        picker.dismiss(animated: true) {
            let newSize = self.customImageSize ?? CGSize.init(width: 200, height: 200)
            UIGraphicsBeginImageContext(newSize)
            editedImage.draw(in: CGRect.init(x: 0, y: 0, width: newSize.width, height: newSize.height))
            let newImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            DispatchQueue.main.async {
                if let complection = self.imagePickerResult {
                    complection(originalImage, newImage ?? editedImage, true, .openSourceOK)
                }
            }
        }
    }
}

extension STBaseOpenSystemOperationController {
    func openPhotoLibrary() -> Void {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.photoLibrary) == true {
            picker.sourceType = UIImagePickerController.SourceType.photoLibrary
            self.present(picker, animated: true) {}
        } else {
            DispatchQueue.main.async {
                if let complection = self.imagePickerResult {
                    complection(UIImage(), UIImage(), false, .openPhotoLibraryError)
                }
            }
        }
    }

    func openCamera() -> Void {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.camera) == true {
            picker.sourceType = UIImagePickerController.SourceType.camera
            self.present(picker, animated: true) {}
        } else {
            DispatchQueue.main.async {
                if let complection = self.imagePickerResult {
                    complection(UIImage(), UIImage(), false, .openPhotoLibraryError)
                }
            }
        }
    }

    func openSystemOperation(openSourceType: STOpenSourceType, complection: @escaping(STImagePickerResult)) -> Void {
        self.imagePickerResult = complection
        switch openSourceType {
        case .photoLibrary:
            self.openPhotoLibrary()
            break
        case .camera:
            self.openCamera()
            break
        default:
            break
        }
    }
    
    func isAvailablePhoto() -> Bool {
        let authorStatus: PHAuthorizationStatus = PHPhotoLibrary.authorizationStatus()
        if authorStatus == .denied {
            return false
        }
        return true
    }
    
    func isAvailableCamera() -> Bool {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.camera) == true {
            let mediaType = AVMediaType.video
            let authorizationStatus: AVAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: mediaType)
            if authorizationStatus == .restricted || authorizationStatus == .denied {
                self.authorizationFailed()
                return false
            }
            return true
        } else {
            // 相机硬件不可用【一般是模拟器】
            return false
        }
    }
}

extension STBaseOpenSystemOperationController {
    func authorizationFailed() -> Void {
        DispatchQueue.main.async {
            let tipMessage: String = "请到手机系统的\n【设置】->【隐私】->【相册】\n" + "开启相机的访问权限"
            self.showError(message: tipMessage, title: "相册读取权限未开启")
        }
    }
}

extension STBaseOpenSystemOperationController {
    func showError(message: String) -> Void {
        self.showError(message: message, title: "提示")
    }
    
    func showError(message: String, title: String) -> Void {
        let alert = UIAlertController.init(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        let action: UIAlertAction = UIAlertAction.init(title: "我知道了", style: UIAlertAction.Style.cancel) { (action) in}
        alert.addAction(action)
        self.present(alert, animated: true) {}
    }
    
    /// 延时操作器
    func performTaskWithTimeInterval(timeInterval: Double, complection: @escaping(Result<Bool, Error>) -> Void) {
        let delayTime = DispatchTime.now() + timeInterval
        DispatchQueue.main.asyncAfter(deadline: delayTime){
            complection(.success(true))
        }
    }
    
    func imageIsEmpty(image: UIImage) -> Bool {
        var cgImageIsEmpty: Bool = false
        if let _: CGImage = image.cgImage {
            cgImageIsEmpty = false
        } else {
            cgImageIsEmpty = true
        }
        
        var ciImageIsEmpty: Bool = false
        if let _: CIImage = image.ciImage {
            ciImageIsEmpty = false
        } else {
            ciImageIsEmpty = true
        }
        if cgImageIsEmpty == true, ciImageIsEmpty == true {
            return true
        }
        return false
    }
    
    func stringToDouble(string: String) -> Double {
        let formatter = NumberFormatter()
        formatter.locale = Locale.current
        formatter.decimalSeparator = "."
        if let result = formatter.number(from: string) {
            return result.doubleValue
        } else {
            formatter.decimalSeparator = ","
            if let result = formatter.number(from: string) {
                return result.doubleValue
            }
        }
        return 0
    }
}

