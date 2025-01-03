//
//  STBtn.swift
//  STBaseProject
//
//  Created by stack on 2019/10/14.
//
import UIKit

extension UIView {
    func st_setCustomCorners(topLeft: CGFloat,
                          topRight: CGFloat,
                          bottomLeft: CGFloat,
                          bottomRight: CGFloat) {
        let path = UIBezierPath(
            roundedRect: self.bounds,
            byRoundingCorners: [.topLeft, .topRight, .bottomLeft, .bottomRight],
            cornerRadii: CGSize(width: topLeft, height: topRight)
        )
        let maskLayer = CAShapeLayer()
        maskLayer.frame = self.bounds
        maskLayer.path = path.cgPath
        self.layer.mask = maskLayer
    }
}
