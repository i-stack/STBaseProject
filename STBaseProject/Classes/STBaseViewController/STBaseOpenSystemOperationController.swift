//
//  STBaseOpenSystemOperationController.swift
//  STBaseProject
//
//  Created by song on 2018/4/28.
//  Copyright © 2019 Tron. All rights reserved.
//

import UIKit

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
}
