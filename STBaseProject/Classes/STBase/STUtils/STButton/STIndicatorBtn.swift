//
//  STIndicatorBtn.swift
//  STBaseProject
//
//  Created by song on 2018/11/14.
//  Copyright © 2018年 song. All rights reserved.
//

import UIKit

open class STIndicatorBtn: STBtn {
    
    private var originalButtonText: String?
    private var newBtnTitleLabel: UILabel!
    private var activityIndicator: UIActivityIndicatorView!
    
    public var st_space: CGFloat = 10.0
    public var st_newButtonText: String = "loading..."
    public var st_indicatorIsAnimating: Bool = false

    @IBInspectable
    let activityIndicatorColor: UIColor = .gray
    
    deinit {
        self.hiddenSpinning()
    }
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func st_indicatorStartAnimating() -> Void {
        if (activityIndicator == nil) {
            activityIndicator = createActivityIndicator()
        }
        
        if newBtnTitleLabel == nil, st_newButtonText.count > 0 {
            newBtnTitleLabel = self.createNewBtnTitleLabel()
        }
        
        if st_indicatorIsAnimating == true {
            return
        }
        
        originalButtonText = self.titleLabel?.text
        self.setTitle("", for: .normal)
        newBtnTitleLabel.text = st_newButtonText
        st_indicatorIsAnimating = true
        self.showSpinning()
    }
    
    public func st_indicatorStopAnimating() -> Void {
        if st_indicatorIsAnimating == false {
            return
        }
        st_indicatorIsAnimating = false
        self.setTitle(originalButtonText, for: .normal)
        newBtnTitleLabel.text = ""
        self.hiddenSpinning()
    }

    private func showSpinning() {
        DispatchQueue.main.async {
            self.addSubview(self.activityIndicator)
            self.centerActivityIndicatorInButton()
            self.activityIndicator.startAnimating()
            self.isUserInteractionEnabled = false
        }
    }
    
    private func hiddenSpinning() {
        DispatchQueue.main.async {
            self.activityIndicator.stopAnimating()
            self.activityIndicator.removeFromSuperview()
            self.isUserInteractionEnabled = true
        }
    }
    
    private func createActivityIndicator() -> UIActivityIndicatorView {
        let indicator = UIActivityIndicatorView()
        indicator.hidesWhenStopped = true
        indicator.color = activityIndicatorColor
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }
    
    private func createNewBtnTitleLabel() -> UILabel {
        let label = UILabel()
        label.backgroundColor = UIColor.clear
        label.font = self.titleLabel?.font
        label.textColor = self.titleLabel?.textColor
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }
    
    private func centerActivityIndicatorInButton() {
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
                                                toItem: self,
                                                attribute: .centerX,
                                                multiplier: 1,
                                                constant: -st_space * 2)
            ])
        
        if st_newButtonText.count > 0 {
            self.addSubview(newBtnTitleLabel)
            self.addConstraints([NSLayoutConstraint(item: newBtnTitleLabel!,
                                                    attribute: .centerY,
                                                    relatedBy: .equal,
                                                    toItem: self,
                                                    attribute: .centerY,
                                                    multiplier: 1,
                                                    constant: 0),
                                 NSLayoutConstraint(item: newBtnTitleLabel!,
                                                    attribute: .right,
                                                    relatedBy: .equal,
                                                    toItem: self,
                                                    attribute: .right,
                                                    multiplier: 1,
                                                    constant: 0),
                                 NSLayoutConstraint(item: newBtnTitleLabel!,
                                                    attribute: .left,
                                                    relatedBy: .equal,
                                                    toItem: activityIndicator,
                                                    attribute: .right,
                                                    multiplier: 1,
                                                    constant: st_space),
                                 NSLayoutConstraint(item: newBtnTitleLabel!,
                                                    attribute: .height,
                                                    relatedBy: .equal,
                                                    toItem: nil,
                                                    attribute: .notAnAttribute,
                                                    multiplier: 1,
                                                    constant: self.titleLabel?.frame.size.height ?? 25)
                ])
        }
    }
}
