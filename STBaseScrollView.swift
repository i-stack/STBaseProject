//
//  STBaseScrollView.swift
//  STBaseProject
//
//  Created by song on 2025/1/31.
//

import UIKit

open class STBaseScrollView: UIScrollView {
    open override func touchesShouldCancel(in view: UIView) -> Bool {
        if view.isKind(of: UIButton.self) {
            return true
        }
        return super.touchesShouldCancel(in: view)
    }
}
