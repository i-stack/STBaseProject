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

public enum STOpenSourceType {
    case photoLibrary
    case camera
    case unknown
}

public enum STOpenSourceError: LocalizedError {
    
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

public typealias STImagePickerResult = (_ originalImage: UIImage, _ editedImage: UIImage, _ result: Bool, _ error: STOpenSourceError) -> Void

open class STBaseOpenSystemOperationController: STBaseViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    open var customImageSize: CGSize?
    open var picker: UIImagePickerController!
    var imagePickerResult: STImagePickerResult?

    override open func viewDidLoad() {
        super.viewDidLoad()
        self.st_imagePickerViewController()
    }

    func st_imagePickerViewController() -> Void {
        guard self.picker != nil else {
            self.picker = UIImagePickerController()
            self.picker.delegate = self
            self.picker.allowsEditing = true
            return
        }
    }
    
    open func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true) {
            DispatchQueue.main.async {
                if let complection = self.imagePickerResult {
                    complection(UIImage(), UIImage(), false, .imagePickerControllerDidCancelError)
                }
            }
        }
    }
    
    open func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
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
    open func st_openPhotoLibrary() -> Void {
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

    open func st_openCamera() -> Void {
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

    open func st_openSystemOperation(openSourceType: STOpenSourceType, complection: @escaping(STImagePickerResult)) -> Void {
        self.imagePickerResult = complection
        switch openSourceType {
        case .photoLibrary:
            self.st_openPhotoLibrary()
            break
        case .camera:
            self.st_openCamera()
            break
        default:
            break
        }
    }
    
    open func st_isAvailablePhoto() -> Bool {
        let authorStatus: PHAuthorizationStatus = PHPhotoLibrary.authorizationStatus()
        if authorStatus == .denied {
            return false
        }
        return true
    }
    
    open func st_isAvailableCamera() -> Bool {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.camera) == true {
            let mediaType = AVMediaType.video
            let authorizationStatus: AVAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: mediaType)
            if authorizationStatus == .restricted || authorizationStatus == .denied {
                self.st_authorizationFailed()
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
    open func st_authorizationFailed() -> Void {
        DispatchQueue.main.async {
            let tipMessage: String = "请到手机系统的\n【设置】->【隐私】->【相册】\n" + "开启相机的访问权限"
            self.st_showError(message: tipMessage, title: "相册读取权限未开启")
        }
    }
}

