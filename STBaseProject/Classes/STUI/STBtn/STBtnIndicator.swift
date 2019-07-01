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
    private var newBtnTitleLabel: UILabel?
    private var activityIndicator: UIActivityIndicatorView!
    
    open var st_space: CGFloat = 0.0
    open var st_newBtnTitle: String = ""
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
        if st_indicatorIsAnimating == true {
            return
        }
        st_indicatorIsAnimating = true
        
        if activityIndicator == nil {
            activityIndicator = createActivityIndicator()
        }
        
        if st_newBtnTitle.count > 0, newBtnTitleLabel == nil {
            newBtnTitleLabel = self.createNewBtnTitleLabel()
        }
        
        originalButtonText = self.titleLabel?.text
        self.setTitle("", for: .normal)
        newBtnTitleLabel?.text = st_newBtnTitle
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
            self.centerActivityIndicatorInButton()
            self.activityIndicator.startAnimating()
        }
    }
    
    private func hiddenSpinning() {
        DispatchQueue.main.async {
            self.newBtnTitleLabel?.text = ""
            self.setTitle(self.originalButtonText, for: .normal)

            self.isUserInteractionEnabled = true
            self.activityIndicator.stopAnimating()
            self.activityIndicator.removeFromSuperview()
            self.newBtnTitleLabel?.removeFromSuperview()
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
                                                toItem: self,
                                                attribute: .centerX,
                                                multiplier: 1,
                                                constant: -st_space * 2)
            ])
        
        guard let btnTitleLabel = newBtnTitleLabel, st_newBtnTitle.count > 0 else { return }
        if btnTitleLabel.superview == nil {
            self.addSubview(btnTitleLabel)
        }
        self.addConstraints([NSLayoutConstraint(item: btnTitleLabel,
                                                attribute: .centerY,
                                                relatedBy: .equal,
                                                toItem: self,
                                                attribute: .centerY,
                                                multiplier: 1,
                                                constant: 0),
                             NSLayoutConstraint(item: btnTitleLabel,
                                                attribute: .right,
                                                relatedBy: .equal,
                                                toItem: self,
                                                attribute: .right,
                                                multiplier: 1,
                                                constant: 0),
                             NSLayoutConstraint(item: btnTitleLabel,
                                                attribute: .left,
                                                relatedBy: .equal,
                                                toItem: activityIndicator,
                                                attribute: .right,
                                                multiplier: 1,
                                                constant: st_space < 10 ? 10 : st_space),
                             NSLayoutConstraint(item: btnTitleLabel,
                                                attribute: .height,
                                                relatedBy: .equal,
                                                toItem: nil,
                                                attribute: .notAnAttribute,
                                                multiplier: 1,
                                                constant: self.titleLabel?.frame.size.height ?? 25)
            ])
    }
}
