//
//  STImagePickerManager.swift
//  STBaseProject
//
//  Created by stack on 2018/4/28.
//  Copyright © 2018 ST. All rights reserved.
//

import UIKit
import Photos
import AVFoundation
import AssetsLibrary

public enum STOpenSourceType {
    case camera
    case simulator
    case photoLibrary
    case unknown
}

public enum STOpenSourceError: LocalizedError {
    
    case unknown
    case openSourceOK
    case openCameraError
    case unsupportSimulator
    case openPhotoLibraryError
    case authorizationCameraFailed
    case authorizationPhotoLibraryFailed
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
        case .authorizationCameraFailed:
            return "相机读取权限未开启，请到手机系统【设置】->【隐私】->【相机】开启相机的访问权限"
        case .authorizationPhotoLibraryFailed:
            return "相册读取权限未开启，请到手机系统【设置】->【隐私】->【相册】开启相册的访问权限"
        case .unknown:
            return "未知错误"
        case .unsupportSimulator:
            return "不支持模拟器"
        }
    }
}

public typealias STImagePickerResult = (_ originalImage: UIImage, _ editedImage: UIImage, _ result: Bool, _ error: STOpenSourceError) -> Void

open class STImagePickerManager: NSObject {

    open var customImageSize: CGSize?
    open var picker: UIImagePickerController!
    weak var presentVC: UIViewController?
    public var imagePickerResult: STImagePickerResult?

    deinit {
        self.presentVC = nil
        self.picker.delegate = nil
        self.imagePickerResult = nil
        STLog("STOpenSystemOperationController dealloc")
    }
    
    public override init() {
        super.init()
    }
    
    public init(presentViewController: UIViewController) {
        super.init()
        self.presentVC = presentViewController
        self.st_imagePickerViewController()
    }

    private func st_imagePickerViewController() -> Void {
        guard self.picker != nil else {
            self.picker = UIImagePickerController()
            self.picker.delegate = self.presentVC as? UIImagePickerControllerDelegate & UINavigationControllerDelegate
            self.picker.allowsEditing = true
            return
        }
    }

    private func st_openPhotoLibrary(presentImagePickerDone: @escaping(Bool) -> Void) {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.photoLibrary) == true {
            picker.sourceType = UIImagePickerController.SourceType.photoLibrary
            self.presentVC?.present(picker, animated: true) {
                presentImagePickerDone(true)
            }
        } else {
            DispatchQueue.main.async {
                if let complection = self.imagePickerResult {
                    complection(UIImage(), UIImage(), false, .openPhotoLibraryError)
                }
            }
        }
    }

    private func st_openCamera(presentImagePickerDone: @escaping(Bool) -> Void) {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.camera) == true {
            picker.sourceType = UIImagePickerController.SourceType.camera
            self.presentVC?.present(picker, animated: true) {
                presentImagePickerDone(true)
            }
        } else {
            DispatchQueue.main.async {
                if let complection = self.imagePickerResult {
                    complection(UIImage(), UIImage(), false, .openPhotoLibraryError)
                }
            }
        }
    }

    open func st_openSystemOperation(openSourceType: STOpenSourceType, complection: @escaping(STImagePickerResult), presentImagePickerDone: @escaping(Bool) -> Void) {
        self.imagePickerResult = complection
        switch openSourceType {
        case .photoLibrary:
            if self.st_isAvailablePhoto() {
                self.st_openPhotoLibrary(presentImagePickerDone: presentImagePickerDone)
            }
            break
        case .camera:
            if self.st_isAvailableCamera() {
                self.st_openCamera(presentImagePickerDone: presentImagePickerDone)
            }
            break
        default:
            break
        }
    }
    
    public func st_isAvailablePhoto() -> Bool {
        let authorStatus: PHAuthorizationStatus = PHPhotoLibrary.authorizationStatus()
        if authorStatus == .denied {
            self.st_authorizationFailed(openSourceType: .photoLibrary)
            return false
        }
        return true
    }
    
    public func st_isAvailableCamera() -> Bool {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.camera) == true {
            let mediaType = AVMediaType.video
            let authorizationStatus: AVAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: mediaType)
            if authorizationStatus == .restricted || authorizationStatus == .denied {
                self.st_authorizationFailed(openSourceType: .camera)
                return false
            }
            return true
        } else {
            self.st_authorizationFailed(openSourceType: .simulator)
            return false
        }
    }
    
    private func st_authorizationFailed(openSourceType: STOpenSourceType) -> Void {
        if let complection = self.imagePickerResult {
            var openSourceError: STOpenSourceError = .unknown
            switch openSourceType {
            case .camera:
                openSourceError = .authorizationCameraFailed
                break
            case .photoLibrary:
                openSourceError = .authorizationPhotoLibraryFailed
                break
            case .simulator:
                openSourceError = .unsupportSimulator
                break
            default:
                break
            }
            DispatchQueue.main.async {
                complection(UIImage(), UIImage(), false, openSourceError)
            }
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
