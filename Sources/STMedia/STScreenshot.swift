//
//  STScreenShot.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2018/3/14.
//

import UIKit

open class STScreenShot: NSObject {

    private class func captureData() -> Data {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            return Data()
        }
        let orientation = windowScene.interfaceOrientation
        let screenBounds = UIScreen.main.bounds
        let imageSize: CGSize
        if orientation.isPortrait {
            imageSize = screenBounds.size
        } else {
            imageSize = CGSize(width: screenBounds.height, height: screenBounds.width)
        }
        let windows = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
        let renderer = UIGraphicsImageRenderer(size: imageSize)
        let image = renderer.image { ctx in
            for window in windows {
                ctx.cgContext.saveGState()
                ctx.cgContext.translateBy(x: window.center.x, y: window.center.y)
                ctx.cgContext.concatenate(window.transform)
                ctx.cgContext.translateBy(
                    x: -window.bounds.size.width * window.layer.anchorPoint.x,
                    y: -window.bounds.size.height * window.layer.anchorPoint.y
                )
                if orientation == .landscapeLeft {
                    ctx.cgContext.rotate(by: .pi / 2)
                    ctx.cgContext.translateBy(x: 0, y: -imageSize.width)
                } else if orientation == .landscapeRight {
                    ctx.cgContext.rotate(by: -(.pi / 2))
                    ctx.cgContext.translateBy(x: -imageSize.height, y: 0)
                } else if orientation == .portraitUpsideDown {
                    ctx.cgContext.rotate(by: .pi)
                    ctx.cgContext.translateBy(x: -imageSize.width, y: -imageSize.height)
                }
                window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
                ctx.cgContext.restoreGState()
            }
        }
        return image.pngData() ?? Data()
    }

    class open func st_imageWithScreenshot() -> UIImage {
        let data = self.captureData()
        return UIImage(data: data) ?? UIImage()
    }

    class open func st_showScreenshotImage(rect: CGRect?) -> UIImageView {
        let image = self.st_imageWithScreenshot()
        let imageView = UIImageView(image: image)
        if let rect, rect != .zero {
            imageView.frame = rect
        } else {
            let bounds = UIScreen.main.bounds
            let side = min(bounds.width, bounds.height) / 2.0
            imageView.frame = CGRect(
                x: bounds.width / 2.0,
                y: bounds.height / 2.0,
                width: side,
                height: side
            )
        }
        let borderWidth: CGFloat = 5.0
        let shadowRadius: CGFloat = 2.0
        imageView.layer.borderWidth = borderWidth
        imageView.layer.shadowRadius = shadowRadius
        imageView.layer.shadowOpacity = 0.5
        imageView.layer.borderColor = UIColor.white.cgColor
        imageView.layer.shadowColor = UIColor.black.cgColor
        imageView.layer.shadowOffset = CGSize(width: 4, height: 4)
        return imageView
    }
}
