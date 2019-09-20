//
//  STIndicatorBtn.swift
//  STBaseProject
//
//  Created by song on 2018/11/14.
//  Copyright © 2018年 song. All rights reserved.
//

import UIKit

enum STIndicatorType {
    case activity
    case custom
}

open class STIndicatorBtn: STBtn {
    
    private var timer: Timer?
    private var countDown: CGFloat = 0
    private var originalButtonText: String?
    private var customImageView: UIImageView!
    private var indicatorType: STIndicatorType = .activity
    private var activityIndicator: UIActivityIndicatorView!
    
    open var st_space: CGFloat = 0.0
    open var st_newBtnTitle: String = ""
    open var st_rotationAngle: CGFloat = .pi / 4.0
    public var st_indicatorIsAnimating: Bool = false
    open var st_activityIndicatorColor: UIColor = .white
    
    deinit {
        self.hiddenSpinning()
    }
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func st_indicatorStartAnimating(customImage: UIImage) -> Void {
        if st_indicatorIsAnimating == true {
            return
        }
        st_indicatorIsAnimating = true
        
        if customImageView == nil {
            customImageView = createCustomActivityIndicator(customImage: customImage)
        }
        
        originalButtonText = self.titleLabel?.text
        self.setTitle(st_newBtnTitle, for: .normal)
        indicatorType = .custom
        self.showSpinning()
    }
    
    public func st_indicatorStartAnimating() -> Void {
        if st_indicatorIsAnimating == true {
            return
        }
        st_indicatorIsAnimating = true
        
        if activityIndicator == nil {
            activityIndicator = createActivityIndicator()
        }
        
        originalButtonText = self.titleLabel?.text
        self.setTitle(st_newBtnTitle, for: .normal)
        self.showSpinning()
    }
    
    public func st_indicatorStopAnimating() -> Void {
        if st_indicatorIsAnimating == false {
            return
        }
        st_indicatorIsAnimating = false

        self.hiddenSpinning()
    }
    
    private func showSpinning() {
        DispatchQueue.main.async {
            self.isUserInteractionEnabled = false
            if self.indicatorType == .activity {
                self.centerActivityIndicatorInButton()
                self.activityIndicator.startAnimating()
            } else if self.indicatorType == .custom {
                self.centerCustomActivityIndicatorInButton()
                self.customIndicatorBeginAnimation()
            }
        }
    }
    
    private func hiddenSpinning() {
        DispatchQueue.main.async {
            self.setTitle(self.originalButtonText, for: .normal)
            self.isUserInteractionEnabled = true
            if self.indicatorType == .activity {
                self.activityIndicator.stopAnimating()
                self.activityIndicator.removeFromSuperview()
            } else if self.indicatorType == .custom {
                self.customIndicatorStopAnimation()
                self.customImageView.removeFromSuperview()
            }
        }
    }
    
    private func customIndicatorBeginAnimation() -> Void {
        if self.timer == nil {
            self.timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true, block: {[weak self] (state) in
                guard let strongSelf = self else { return }
                if strongSelf.indicatorType == .custom {
                    strongSelf.countDown += 1.0
                    strongSelf.customImageView.transform = CGAffineTransform(rotationAngle: strongSelf.st_rotationAngle * strongSelf.countDown)
                }
            })
        }
    }
    
    private func customIndicatorStopAnimation() -> Void {
        if let newTimer = self.timer, newTimer.isValid {
            newTimer.invalidate()
            self.countDown = 0
            self.customImageView.transform = CGAffineTransform.identity
        }
    }
    
    private func createActivityIndicator() -> UIActivityIndicatorView {
        let indicator = UIActivityIndicatorView()
        indicator.hidesWhenStopped = true
        indicator.color = st_activityIndicatorColor
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }
    
    private func createCustomActivityIndicator(customImage: UIImage) -> UIImageView {
        let imageView = UIImageView.init(image: customImage)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }
    
    private func createNewBtnTitleLabel() -> UILabel {
        let label = UILabel()
        label.font = self.titleLabel?.font
        label.backgroundColor = UIColor.clear
        label.isUserInteractionEnabled = true
        label.textColor = self.titleLabel?.textColor
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }
    
    private func centerActivityIndicatorInButton() {
        if activityIndicator.superview == nil {
            self.addSubview(self.activityIndicator)
        }
        self.addConstraints([NSLayoutConstraint(item: activityIndicator!,
                                                attribute: .centerY,
                                                relatedBy: .equal,
                                                toItem: self,
                                                attribute: .centerY,
                                                multiplier: 1,
                                                constant: 0),
                             NSLayoutConstraint(item: activityIndicator!,
                                                attribute: .right,
                                                relatedBy: .equal,
                                                toItem: self.titleLabel,
                                                attribute: .left,
                                                multiplier: 1,
                                                constant: -st_space)
            ])
    }
    
    private func centerCustomActivityIndicatorInButton() {
        if customImageView.superview == nil {
            self.addSubview(self.customImageView)
        }
        self.addConstraints([NSLayoutConstraint(item: customImageView!,
                                                attribute: .centerY,
                                                relatedBy: .equal,
                                                toItem: self,
                                                attribute: .centerY,
                                                multiplier: 1,
                                                constant: 0),
                             NSLayoutConstraint(item: customImageView!,
                                                attribute: .right,
                                                relatedBy: .equal,
                                                toItem: self.titleLabel,
                                                attribute: .left,
                                                multiplier: 1,
                                                constant: -st_space)
            ])
    }
    
    private func textWidth(text: String) -> CGFloat {
        let maxSize = CGSize.init(width: self.bounds.size.width, height: 0)
        let rect: CGRect = text.boundingRect(with: maxSize, options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: self.titleLabel?.font ?? UIFont.systemFont(ofSize: 14)] , context: nil)
        return  CGFloat(ceilf(Float(rect.size.width)))
    }
}
