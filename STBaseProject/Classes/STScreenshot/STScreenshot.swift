//
//  STScreenShot.swift
//  STBaseProject
//
//  Created by song on 2018/5/6.
//  Copyright © 2019 song. All rights reserved.
//

import UIKit

open class STScreenShot: NSObject {
    
    class open func st_dataWithScreenshotInPNGFormat() -> Data {
        var imageSize: CGSize = CGSize.zero
        let orientation = UIApplication.shared.statusBarOrientation
        if orientation.isPortrait == true {
            imageSize = UIScreen.main.bounds.size
        } else {
            imageSize = CGSize.init(width: UIScreen.main.bounds.size.height, height: UIScreen.main.bounds.size.width)
        }
        UIGraphicsBeginImageContextWithOptions(imageSize, false, 0)
        let context: CGContext = UIGraphicsGetCurrentContext()!
        for window in UIApplication.shared.windows {
            context.saveGState()
            context.translateBy(x: window.center.x, y: window.center.y)
            context.concatenate(window.transform)
            context.translateBy(x: -window.bounds.size.width * window.layer.anchorPoint.x, y: -window.bounds.size.height * window.layer.anchorPoint.y)
            if orientation == UIInterfaceOrientation.landscapeLeft {
                context.rotate(by: .pi / 2)
                context.translateBy(x: 0, y: -imageSize.width)
            } else if orientation == UIInterfaceOrientation.landscapeRight {
                context.rotate(by: -(.pi / 2))
                context.translateBy(x: -imageSize.height, y: 0)
            } else if orientation == UIInterfaceOrientation.portraitUpsideDown {
                context.rotate(by: .pi)
                context.translateBy(x: -imageSize.width, y: -imageSize.height)
            }
            window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
            context.restoreGState()
        }
        let image: UIImage = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
        UIGraphicsEndImageContext()
        return image.pngData() ?? Data()
    }
    
    /**
     *  返回截取到的图片
     *
     *  @return UIImage *
     */
    class open func st_imageWithScreenshot() -> UIImage {
        let imageData = self.st_dataWithScreenshotInPNGFormat()
        return UIImage.init(data: imageData) ?? UIImage()
    }
    
    class open func st_showScreenshotImage() -> UIImageView {
        let image = self.st_imageWithScreenshot()
        let imgvPhoto: UIImageView = UIImageView.init(image: image)
        imgvPhoto.frame = CGRect.init(x: UIScreen.main.bounds.size.width / 2.0, y: UIScreen.main.bounds.size.height / 2.0, width: UIScreen.main.bounds.size.width / 2.0, height: UIScreen.main.bounds.size.height / 2.0)
        let layer: CALayer = imgvPhoto.layer
        layer.borderColor = UIColor.white.cgColor
        layer.borderWidth = 5.0
        imgvPhoto.layer.shadowColor = UIColor.black.cgColor
        imgvPhoto.layer.shadowOffset = CGSize.zero
        imgvPhoto.layer.shadowOpacity = 0.5
        imgvPhoto.layer.shadowRadius = 10.0
        
        imgvPhoto.layer.shadowColor = UIColor.black.cgColor
        imgvPhoto.layer.shadowOffset = CGSize.init(width: 4, height: 4)
        imgvPhoto.layer.shadowOpacity = 0.5
        imgvPhoto.layer.shadowRadius = 2.0
        return imgvPhoto
    }
}
