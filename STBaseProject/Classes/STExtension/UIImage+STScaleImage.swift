//
//  UIImage+STScaleImage.swift
//  STBaseProject
//
//  Created by song on 2018/11/14.
//  Copyright © 2018年 song. All rights reserved.
//

import UIKit

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
    
    /**
     *  获取启动图
     */
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
