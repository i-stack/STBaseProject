//
//  UPAlertController.swift
//  STBaseProject
//
//  Created by song on 2022/12/31.
//

import UIKit

public enum STAlertStyle: Int, @unchecked Sendable {
    case actionSheet = 0
    case alert = 1
}

public enum STAlertBtnClickType {
    case btnClick
    case leftBtnClick
    case rightBtnClick
}

public struct STAlertInfo {
    var title: TextInfo = TextInfo()
    var message: TextInfo = TextInfo()
    var style: STAlertStyle = .alert
    var buttonActions: [Action] = []
    var buttonHandlers: [(Bool, String) -> Void] = []
        
    public struct TextInfo {
        var text: String = ""
        var textFont: UIFont?
        var textColor: UIColor?
    }
    
    public struct Action {
        var font: UIFont?
        var title: String = ""
        var titleColor: UIColor?
        var backgroundColor: UIColor?
        var customButton: STBtn? // If there is a value, use it first
    }
    
    public struct LineImageView {
        var hBackgroundColor: UIColor?
        var vBackgroundColor: UIColor?
    }
}

open class STAlertController: UIViewController {
    
    private var isPresented: Bool = false
    private var newConstraint: NSLayoutConstraint!
    private var backgroundColor: UIColor = UIColor.white
    private var alertInfo: STAlertInfo = STAlertInfo()
    
    convenience init(style: STAlertStyle) {
        self.init()
        self.alertInfo.style = style
    }
    
    convenience init(title: String, message: String, style: STAlertStyle) {
        self.init()
        self.alertInfo.style = style
        self.alertInfo.title.text = title
        self.alertInfo.message.text = message
    }
    
    convenience init(info: STAlertInfo) {
        self.init()
        self.alertInfo = info
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.modalPresentationStyle = .overFullScreen
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.isPresented = true
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.isPresented = false
    }
    
    public func getIsPresented() -> Bool {
        return self.isPresented
    }
    
    public func setup() {
        self.configCustomAlertView()
    }
    
    public func setBackground(color: UIColor) {
        self.backgroundColor = color
    }
    
    public func updateTitle(text: String) {
        self.titleLabel.text = text
    }
    
    public func updateMessage(text: String) {
        self.messageLabel.text = text
    }
    
    public func addAction(action: STAlertInfo.Action, handler: @escaping((Bool, String) -> Void)) {
        if self.alertInfo.style == .alert {
            if self.alertInfo.buttonActions.count < 2 {
                self.alertInfo.buttonActions.append(action)
            } else {
                self.alertInfo.buttonActions[1] = action
            }
        } else {
            self.alertInfo.buttonActions.append(action)
        }
        self.alertInfo.buttonHandlers.append(handler)
    }
    
    public func animateIn() {
        self.alertView.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
        self.alertView.alpha = 0

        UIView.animate(withDuration: 0.4, animations: {
           self.alertView.transform = CGAffineTransform.identity
           self.alertView.alpha = 1
        })
    }
       
    public func animateOut(completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.4, animations: {
           self.alertView.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
           self.alertView.alpha = 0
        }, completion: { _ in
           completion?()
        })
    }
       
    public func show(in parentVC: UIViewController) {
        if let presentedVC = parentVC.presentedViewController {
            presentedVC.dismiss(animated: false) { [weak self] in
                guard let strongSelf = self else { return }
                parentVC.present(strongSelf, animated: true, completion: nil)
            }
        } else {
            parentVC.present(self, animated: true, completion: nil)
        }
    }

    public func dismissAlert() {
        self.animateOut {
            self.dismiss(animated: true, completion: nil)
        }
    }

    private func configCustomAlertView() {
        self.view.addSubview(self.alertView)
        self.newConstraint = NSLayoutConstraint.init(item: self.alertView, attribute: .height, relatedBy: .greaterThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 180)
        if self.alertInfo.style == .alert {
            self.view.addConstraints([
                NSLayoutConstraint.init(item: self.alertView, attribute: .centerX, relatedBy: .equal, toItem: self.view, attribute: .centerX, multiplier: 1, constant: 0),
                NSLayoutConstraint.init(item: self.alertView, attribute: .centerY, relatedBy: .equal, toItem: self.view, attribute: .centerY, multiplier: 1, constant: 0),
                NSLayoutConstraint.init(item: self.alertView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 270),
                self.newConstraint
            ])
        } else {
            self.view.addConstraints([
                NSLayoutConstraint.init(item: self.alertView, attribute: .centerX, relatedBy: .equal, toItem: self.view, attribute: .centerX, multiplier: 1, constant: 0),
                NSLayoutConstraint.init(item: self.alertView, attribute: .bottom, relatedBy: .equal, toItem: self.view, attribute: .bottom, multiplier: 1, constant: 0),
                NSLayoutConstraint.init(item: self.alertView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 270),
                self.newConstraint
            ])
        }
        
        if self.alertInfo.title.text != "" && self.alertInfo.message.text != "" {
            self.titleLabel.text = self.alertInfo.title.text
            self.messageLabel.text = self.alertInfo.message.text
            self.alertView.addSubview(self.titleLabel)
            self.alertView.addSubview(self.messageLabel)
            self.view.addConstraints([
                NSLayoutConstraint.init(item: self.titleLabel, attribute: .top, relatedBy: .equal, toItem: self.alertView, attribute: .top, multiplier: 1, constant: 20),
                NSLayoutConstraint.init(item: self.titleLabel, attribute: .left, relatedBy: .equal, toItem: self.alertView, attribute: .left, multiplier: 1, constant: 20),
                NSLayoutConstraint.init(item: self.titleLabel, attribute: .right, relatedBy: .equal, toItem: self.alertView, attribute: .right, multiplier: 1, constant: -20),
            ])
            self.view.addConstraints([
                NSLayoutConstraint.init(item: self.messageLabel, attribute: .top, relatedBy: .equal, toItem: self.titleLabel, attribute: .bottom, multiplier: 1, constant: 10),
                NSLayoutConstraint.init(item: self.messageLabel, attribute: .left, relatedBy: .equal, toItem: self.titleLabel, attribute: .left, multiplier: 1, constant: 20),
                NSLayoutConstraint.init(item: self.messageLabel, attribute: .right, relatedBy: .equal, toItem: self.titleLabel, attribute: .right, multiplier: 1, constant: -20),
            ])
        } else if self.alertInfo.title.text != "" && self.alertInfo.message.text == "" {
            self.titleLabel.text = self.alertInfo.title.text
            self.alertView.addSubview(self.titleLabel)
            self.view.addConstraints([
                NSLayoutConstraint.init(item: self.titleLabel, attribute: .top, relatedBy: .equal, toItem: self.alertView, attribute: .top, multiplier: 1, constant: 20),
                NSLayoutConstraint.init(item: self.titleLabel, attribute: .left, relatedBy: .equal, toItem: self.alertView, attribute: .left, multiplier: 1, constant: 20),
                NSLayoutConstraint.init(item: self.titleLabel, attribute: .right, relatedBy: .equal, toItem: self.alertView, attribute: .right, multiplier: 1, constant: -20),
            ])
        } else if self.alertInfo.title.text == "" && self.alertInfo.message.text != "" {
            self.messageLabel.text = self.alertInfo.message.text
            self.alertView.addSubview(self.messageLabel)
            self.view.addConstraints([
                NSLayoutConstraint.init(item: self.messageLabel, attribute: .top, relatedBy: .equal, toItem: self.alertView, attribute: .top, multiplier: 1, constant: 20),
                NSLayoutConstraint.init(item: self.messageLabel, attribute: .left, relatedBy: .equal, toItem: self.alertView, attribute: .left, multiplier: 1, constant: 20),
                NSLayoutConstraint.init(item: self.messageLabel, attribute: .right, relatedBy: .equal, toItem: self.alertView, attribute: .right, multiplier: 1, constant: -20),
            ])
        }
        self.configAlertBtn()
    }
    
    @objc private func alertButtonClick(sender: STBtn) {
        if self.alertInfo.buttonHandlers.count == 1 {
            if let handler = self.alertInfo.buttonHandlers.first {
                handler(true, sender.titleLabel?.text ?? "")
            }
        } else {
            if sender.identifier as! STAlertBtnClickType == STAlertBtnClickType.leftBtnClick {
                if let handler = self.alertInfo.buttonHandlers.first {
                    handler(true, sender.titleLabel?.text ?? "")
                }
            } else {
                if let handler = self.alertInfo.buttonHandlers.last {
                    handler(true, sender.titleLabel?.text ?? "")
                }
            }
        }
    }
    
    private func configAlertBtn() {
        if self.alertInfo.buttonActions.count < 1 { return }
        if self.alertInfo.buttonActions.count == 1 {
            self.alertView.addSubview(self.lineImageH)
            let btn = self.createBtn(action: self.alertInfo.buttonActions[0])
            btn.identifier = STAlertBtnClickType.btnClick
            btn.addTarget(self, action: #selector(alertButtonClick), for: .touchUpInside)
            self.alertView.addSubview(btn)
            self.view.addConstraints([
                NSLayoutConstraint.init(item: self.lineImageH, attribute: .top, relatedBy: .equal, toItem: self.alertView, attribute: .bottom, multiplier: 1, constant: -44),
                NSLayoutConstraint.init(item: self.lineImageH, attribute: .left, relatedBy: .equal, toItem: self.alertView, attribute: .left, multiplier: 1, constant: 0),
                NSLayoutConstraint.init(item: self.lineImageH, attribute: .right, relatedBy: .equal, toItem: self.alertView, attribute: .right, multiplier: 1, constant: 0),
                NSLayoutConstraint.init(item: self.lineImageH, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 0.5)
            ])
            self.view.addConstraints([
                NSLayoutConstraint.init(item: btn, attribute: .top, relatedBy: .equal, toItem: self.lineImageH, attribute: .bottom, multiplier: 1, constant: 0),
                NSLayoutConstraint.init(item: btn, attribute: .left, relatedBy: .equal, toItem: self.alertView, attribute: .left, multiplier: 1, constant: 0),
                NSLayoutConstraint.init(item: btn, attribute: .right, relatedBy: .equal, toItem: self.alertView, attribute: .right, multiplier: 1, constant: 0),
                NSLayoutConstraint.init(item: btn, attribute: .bottom, relatedBy: .equal, toItem: self.alertView, attribute: .bottom, multiplier: 1, constant: 0),
            ])
        } else if self.alertInfo.buttonActions.count == 2 {
            self.alertView.addSubview(self.lineImageH)
            self.alertView.addSubview(self.lineImageV)
            
            let leftBtn = self.createBtn(action: self.alertInfo.buttonActions[0])
            leftBtn.identifier = STAlertBtnClickType.leftBtnClick
            leftBtn.addTarget(self, action: #selector(alertButtonClick), for: .touchUpInside)
            self.alertView.addSubview(leftBtn)
            
            let rightBtn = self.createBtn(action: self.alertInfo.buttonActions[1])
            rightBtn.identifier = STAlertBtnClickType.rightBtnClick
            rightBtn.addTarget(self, action: #selector(alertButtonClick), for: .touchUpInside)
            self.alertView.addSubview(rightBtn)
            self.view.addConstraints([
                NSLayoutConstraint.init(item: self.lineImageH, attribute: .top, relatedBy: .equal, toItem: self.alertView, attribute: .bottom, multiplier: 1, constant: -44),
                NSLayoutConstraint.init(item: self.lineImageH, attribute: .left, relatedBy: .equal, toItem: self.alertView, attribute: .left, multiplier: 1, constant: 0),
                NSLayoutConstraint.init(item: self.lineImageH, attribute: .right, relatedBy: .equal, toItem: self.alertView, attribute: .right, multiplier: 1, constant: 0),
                NSLayoutConstraint.init(item: self.lineImageH, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 0.5)
            ])
            self.view.addConstraints([
                NSLayoutConstraint.init(item: self.lineImageV, attribute: .top, relatedBy: .equal, toItem: self.lineImageH, attribute: .top, multiplier: 1, constant: 0),
                NSLayoutConstraint.init(item: self.lineImageV, attribute: .bottom, relatedBy: .equal, toItem: self.alertView, attribute: .bottom, multiplier: 1, constant: 0),
                NSLayoutConstraint.init(item: self.lineImageV, attribute: .centerX, relatedBy: .equal, toItem: self.alertView, attribute: .centerX, multiplier: 1, constant: 0),
                NSLayoutConstraint.init(item: self.lineImageV, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 0.5)
            ])
            self.view.addConstraints([
                NSLayoutConstraint.init(item: leftBtn, attribute: .top, relatedBy: .equal, toItem: self.lineImageH, attribute: .top, multiplier: 1, constant: 0),
                NSLayoutConstraint.init(item: leftBtn, attribute: .left, relatedBy: .equal, toItem: self.alertView, attribute: .left, multiplier: 1, constant: 0),
                NSLayoutConstraint.init(item: leftBtn, attribute: .right, relatedBy: .equal, toItem: self.lineImageV, attribute: .left, multiplier: 1, constant: 0),
                NSLayoutConstraint.init(item: leftBtn, attribute: .bottom, relatedBy: .equal, toItem: self.alertView, attribute: .bottom, multiplier: 1, constant: 0),
            ])
            self.view.addConstraints([
                NSLayoutConstraint.init(item: rightBtn, attribute: .top, relatedBy: .equal, toItem: self.lineImageH, attribute: .bottom, multiplier: 1, constant: 0),
                NSLayoutConstraint.init(item: rightBtn, attribute: .left, relatedBy: .equal, toItem: self.lineImageV, attribute: .right, multiplier: 1, constant: 0),
                NSLayoutConstraint.init(item: rightBtn, attribute: .right, relatedBy: .equal, toItem: self.alertView, attribute: .right, multiplier: 1, constant: 0),
                NSLayoutConstraint.init(item: rightBtn, attribute: .bottom, relatedBy: .equal, toItem: self.alertView, attribute: .bottom, multiplier: 1, constant: 0),
            ])
        }
        self.view.layoutIfNeeded()
        if self.alertInfo.message.text != "" {
            self.newConstraint.constant = self.messageLabel.frame.maxY + 54
        } else if self.alertInfo.title.text != "" {
            self.newConstraint.constant = self.titleLabel.frame.maxY + 54
        }
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
            self.animateIn()
        }
    }
    
    private lazy var alertView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 10
        view.isUserInteractionEnabled = true
        view.backgroundColor = self.backgroundColor
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var titleLabel: UILabel = {
        var label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        label.textColor = UIColor.black
        label.backgroundColor = UIColor.white
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.st_systemFont(ofSize: 15, weight: .medium)
        return label
    }()
    
    private lazy var messageLabel: UILabel = {
        var label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        label.textColor = UIColor.black
        label.backgroundColor = UIColor.black
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.st_systemFont(ofSize: 15, weight: .regular)
        return label
    }()
    
    private func createBtn(action: STAlertInfo.Action) -> STBtn {
        if let customButton = action.customButton {
            return customButton
        }
        let btn = STBtn(type: .custom)
        btn.isUserInteractionEnabled = true
        btn.contentVerticalAlignment = .center
        btn.contentHorizontalAlignment = .center
        btn.setTitle(action.title, for: .normal)
        if let font = action.font {
            btn.titleLabel?.font = font
        } else {
            btn.titleLabel?.font = UIFont.st_systemFont(ofSize: 14, weight: .regular)
        }
        if let titleColor = action.titleColor {
            btn.setTitleColor(titleColor, for: .normal)
        } else {
            btn.setTitleColor(UIColor.systemGray, for: .normal)
        }
        if let backgroundColor = action.backgroundColor {
            btn.backgroundColor = backgroundColor
        }
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }
    
    private lazy var lineImageH: UIImageView = {
        var imageView = UIImageView()
        imageView.backgroundColor = UIColor.st_color(hexString: "#000000", alpha: 0.05)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private lazy var lineImageV: UIImageView = {
        var imageView = UIImageView()
        imageView.backgroundColor = UIColor.st_color(hexString: "#000000", alpha: 0.05)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
}
