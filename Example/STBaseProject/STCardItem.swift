//
//  STCardItem.swift
//  STBaseProject_Example
//
//  Created by stack on 2019/7/9.
//  Copyright © 2019 STBaseProject. All rights reserved.
//

import UIKit

public enum STCardItemIdentifier {
    case one, two, three, none
}

open class STCardItem: UIView {
    
    private var image: UIImage = UIImage()
    private var imageView: UIImageView = UIImageView()
    
    open var originCenter: CGPoint = CGPoint.zero
    open var cartItemIdentifier: STCardItemIdentifier = .none

    public override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    public init(image: UIImage) {
        self.image = image
        super.init(frame: CGRect.zero)
        initView()
    }
    
    public func initView() {
        imageView = UIImageView()
        imageView.image = image
        self.addSubview(imageView)
    }
    
    override open func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = bounds
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
