//
//  STScaleImage.swift
//  STBaseProject
//
//  Created by song on 2018/11/14.
//  Copyright © 2018年 song. All rights reserved.
//

import UIKit
import Photos

extension UIImage {
    /**
     *  @brief 图片缩放
     *  @prama showImageSize == UIImageView.bounds
     *  called in background thread, and update image in main thread.
     *
     *  DispatchQueue.init(label: "").async {
     *      let image = UIImage.st_scaleImageWithSize(showImageSize: CGSize)
     *      DispatchQueue.main.async {
     *          UIImageView.image = image
     *      }
     *  }
     *
     *  return scale image
     */
    public func st_scaleImageWithSize(showImageSize: CGSize) -> UIImage {
        if __CGSizeEqualToSize(showImageSize, self.size) {
            return self
        }
        UIGraphicsBeginImageContextWithOptions(showImageSize, true, UIScreen.main.scale)
        self.draw(in: CGRect.init(x: 0, y: 0, width: showImageSize.width, height: showImageSize.height))
        let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext() ?? self
        UIGraphicsEndImageContext()
        return newImage
    }
    
    /**
     *  @brief 图片设置为圆形
     *  called in background thread, and update image in main thread.
     *
     *  DispatchQueue.init(label: "").async {
     *      let image = UIImage.st_imageWithCircle()
     *      DispatchQueue.main.async {
     *          UIImageView.image = image
     *      }
     *  }
     *
     *  return circle image
     */
    public func st_imageWithCircle() -> UIImage {
        if __CGSizeEqualToSize(CGSize.zero, self.size) {
            return self
        }
        UIGraphicsBeginImageContextWithOptions(self.size, false, 0)
        let path = UIBezierPath.init(ovalIn: CGRect.init(x: 0, y: 0, width: self.size.width, height: self.size.height))
        path.addClip()
        self.draw(at: CGPoint.zero)
        let image = UIGraphicsGetImageFromCurrentImageContext() ?? self
        UIGraphicsEndImageContext()
        return image
    }
    
    /**  获取启动图 */
    public func st_launchImage() -> UIImage {
        var lauchImage: UIImage = UIImage()
        var viewOrientation: String = ""
        let viewSize = UIScreen.main.bounds.size
        let orientation: UIInterfaceOrientation = UIApplication.shared.statusBarOrientation
        if  orientation == .landscapeLeft ||
            orientation == .landscapeRight {
            viewOrientation = "Landscape"
        } else {
            viewOrientation = "Portrait"
        }
        let imagesDictionary: NSArray = Bundle.main.infoDictionary?["UILaunchImages"] as! NSArray
        for dict in imagesDictionary {
            let resultDict: NSDictionary = dict as! NSDictionary
            let imageSize = NSCoder.cgSize(for: resultDict.value(forKey: "UILaunchImageSize") as! String)
            if imageSize.equalTo(viewSize), viewOrientation == resultDict.value(forKey: "UILaunchImageOrientation") as! String {
                lauchImage = UIImage.init(named: resultDict.value(forKey: "UILaunchImageName") as! String) ?? UIImage()
            }
        }
        return lauchImage
    }
}

//MARK:- save image to album
extension UIImage {
    public func st_imageExist() -> Bool {
        let cgref: CGImage? = self.cgImage
        let cim: CIImage? = self.ciImage
        if let _ = cgref, let _ = cim {
            return true
        }
        return false
    }
    
    public func st_saveImageToAlbum(image: UIImage, resultHandler: @escaping (Result<Data, Error>) -> Void) {
        if image.st_imageExist() {
            var imageIds: Array<String> = Array<String>()
            PHPhotoLibrary.shared().performChanges({
                let req: PHAssetChangeRequest = PHAssetChangeRequest.creationRequestForAsset(from: image)
                imageIds.append(req.placeholderForCreatedAsset?.localIdentifier ?? "")
            }) { (sucess, error) in
                if sucess {
                    var imageAsset: PHAsset?
                    let result: PHFetchResult = PHAsset.fetchAssets(withLocalIdentifiers: imageIds, options: PHFetchOptions.init())
                    result.enumerateObjects({ (obj, idx, stop) in
                        imageAsset = obj
                        stop.pointee = true
                    })
                    if let newImageAsset = imageAsset {
                        PHImageManager.default().requestImageData(for: newImageAsset, options: PHImageRequestOptions.init(), resultHandler: { (imageData, dataUTI, orientation, info) in
                            DispatchQueue.main.async {
                                resultHandler(.success(imageData ?? Data()))
                            }
                        })
                    } else {
                        DispatchQueue.main.async {
                            resultHandler(.failure(NSError.init(domain: "saveImageToAlbum Error", code: 0, userInfo: ["message" : "image is nil"])))
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        resultHandler(.failure(error!))
                    }
                }
            }
        } else {
            DispatchQueue.main.async {
                resultHandler(.failure(NSError.init(domain: "saveImageToAlbum Error", code: 0, userInfo: ["message" : "image is nil"])))
            }
        }
    }
}
