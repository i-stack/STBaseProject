//
//  UIImage+STScaleImage.swift
//  STBaseProject
//
//  Created by song on 2018/11/14.
//  Copyright © 2018年 song. All rights reserved.
//

import UIKit
import Foundation

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
}
