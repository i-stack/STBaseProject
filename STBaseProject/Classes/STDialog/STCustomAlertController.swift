//
//  STCustomAlertController.swift
//  UrtyePbhk
//
//  Created by song on 2024/12/31.
//

import UIKit

enum STCustomAlertStyle: Int, @unchecked Sendable {
    case actionSheet = 0
    case alert = 1
}

enum STCustomAlertBtnClickType {
    case btnClick
    case leftBtnClick
    case rightBtnClick
}

struct STCustomAlertInfo {
    var title: String = ""
    var message: String = ""
    var style: STCustomAlertStyle = .alert
    var buttonTitles: [String] = []
    var buttonHandlers: [(Bool, String) -> Void] = []
}

class STCustomAlertController: UIViewController {
    
    private var isPresented: Bool = false
    private var newConstraint: NSLayoutConstraint!
    private var backgroundColor: UIColor = UIColor.white
    private var alertInfo: STCustomAlertInfo = STCustomAlertInfo()
    
    convenience init(style: STCustomAlertStyle) {
        self.init()
        self.alertInfo.style = style
    }
   
    convenience init(title: String, message: String, style: STCustomAlertStyle) {
        self.init()
        self.alertInfo.title = title
        self.alertInfo.message = message
        self.alertInfo.style = style
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.modalPresentationStyle = .overFullScreen
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.isPresented = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.isPresented = false
    }
    
    func currentVCIsPresented() -> Bool {
        return self.isPresented
    }
    
    func setup() {
        self.configCustomAlertView()
    }
    
    func setBackground(color: UIColor) {
        self.backgroundColor = color
    }
    
    func addAction(title: String, handler: @escaping((Bool, String) -> Void)) {
        if self.alertInfo.buttonTitles.count < 2 {
            self.alertInfo.buttonTitles.append(title)
        } else {
            self.alertInfo.buttonTitles[1] = title
        }
        self.alertInfo.buttonHandlers.append(handler)
    }
    
    func updateTitle(text: String) {
        self.titleLabel.text = text
    }
    
    func updateMessage(text: String) {
        self.messageLabel.text = text
    }
    
    func animateIn() {
        DispatchQueue.main.async {
            self.alertView.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
            self.alertView.alpha = 0
            UIView.animate(withDuration: 0.4, animations: {
               self.alertView.transform = CGAffineTransform.identity
               self.alertView.alpha = 1
            })
        }
    }
       
    func animateOut(completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.4, animations: {
            DispatchQueue.main.async {
                self.alertView.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
                self.alertView.alpha = 0
            }
        }, completion: { _ in
           completion?()
        })
    }
       
    func show(in parentVC: UIViewController) {
        if let presentedVC = parentVC.presentedViewController {
            presentedVC.dismiss(animated: false) { [weak self] in
                parentVC.present(self ?? UIViewController(), animated: true, completion: nil)
            }
        } else {
            parentVC.present(self, animated: true, completion: nil)
        }
    }

    func dismissAlert() {
        self.animateOut {
            self.dismiss(animated: true, completion: nil)
        }
    }

    func configCustomAlertView() {
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
        
        if self.alertInfo.title != "" && self.alertInfo.message != "" {
            self.titleLabel.text = self.alertInfo.title
            self.messageLabel.text = self.alertInfo.message
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
        } else if self.alertInfo.title != "" && self.alertInfo.message == "" {
            self.titleLabel.text = self.alertInfo.title
            self.alertView.addSubview(self.titleLabel)
            self.view.addConstraints([
                NSLayoutConstraint.init(item: self.titleLabel, attribute: .top, relatedBy: .equal, toItem: self.alertView, attribute: .top, multiplier: 1, constant: 20),
                NSLayoutConstraint.init(item: self.titleLabel, attribute: .left, relatedBy: .equal, toItem: self.alertView, attribute: .left, multiplier: 1, constant: 20),
                NSLayoutConstraint.init(item: self.titleLabel, attribute: .right, relatedBy: .equal, toItem: self.alertView, attribute: .right, multiplier: 1, constant: -20),
            ])
        } else if self.alertInfo.title == "" && self.alertInfo.message != "" {
            self.messageLabel.text = self.alertInfo.message
            self.alertView.addSubview(self.messageLabel)
            self.view.addConstraints([
                NSLayoutConstraint.init(item: self.messageLabel, attribute: .top, relatedBy: .equal, toItem: self.alertView, attribute: .top, multiplier: 1, constant: 20),
                NSLayoutConstraint.init(item: self.messageLabel, attribute: .left, relatedBy: .equal, toItem: self.alertView, attribute: .left, multiplier: 1, constant: 20),
                NSLayoutConstraint.init(item: self.messageLabel, attribute: .right, relatedBy: .equal, toItem: self.alertView, attribute: .right, multiplier: 1, constant: -20),
            ])
        }
        configBtn()
    }
    
    @objc func alertButtonClick(sender: STBtn) {
        if self.alertInfo.buttonHandlers.count == 1 {
            if let handler = self.alertInfo.buttonHandlers.first {
                handler(true, sender.titleLabel?.text ?? "")
            }
        } else {
            if sender.identifier as! STCustomAlertBtnClickType == STCustomAlertBtnClickType.leftBtnClick {
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
    
    private func configBtn() {
        if self.alertInfo.buttonTitles.count == 1 {
            self.alertView.addSubview(self.lineImageH)
            let btn = createBtn()
            btn.identifier = STCustomAlertBtnClickType.btnClick
            btn.setTitle(self.alertInfo.buttonTitles[0], for: .normal)
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
        } else {
            self.alertView.addSubview(self.lineImageH)
            self.alertView.addSubview(self.lineImageV)
            let leftBtn = createBtn()
            leftBtn.setTitleColor(UPApplicationColor.A50_000000(), for: .normal)
            leftBtn.setTitle(self.alertInfo.buttonTitles[0], for: .normal)
            leftBtn.identifier = STCustomAlertBtnClickType.leftBtnClick
            leftBtn.addTarget(self, action: #selector(alertButtonClick), for: .touchUpInside)
            self.alertView.addSubview(leftBtn)
            let rightBtn = createBtn()
            rightBtn.setTitle(self.alertInfo.buttonTitles[1], for: .normal)
            rightBtn.identifier = STCustomAlertBtnClickType.rightBtnClick
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
        if self.alertInfo.message != "" {
            self.newConstraint.constant = self.messageLabel.frame.maxY + 54
        } else if self.alertInfo.title != "" {
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
        label.textColor = UPApplicationColor.A333333()
        label.backgroundColor = UPApplicationColor.FFFFFF()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.st_systemFont(ofSize: 15, weight: .regular)
        return label
    }()
    
    private lazy var messageLabel: UILabel = {
        var label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        label.textColor = UPApplicationColor.A333333()
        label.backgroundColor = UPApplicationColor.FFFFFF()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.st_systemFont(ofSize: 15, weight: .regular)
        return label
    }()
    
    private func createBtn() -> STBtn {
        let btn = STBtn(type: .custom)
        btn.isUserInteractionEnabled = true
        btn.contentVerticalAlignment = .center
        btn.contentHorizontalAlignment = .center
        btn.titleLabel?.font = UIFont.st_systemFont(ofSize: 14, weight: .regular)
        btn.setTitleColor(UPApplicationColor.FD5904FF(), for: .normal)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }
    
    private lazy var lineImageH: UIImageView = {
        var imageView = UIImageView()
        imageView.backgroundColor = UPApplicationColor.A5_000000()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private lazy var lineImageV: UIImageView = {
        var imageView = UIImageView()
        imageView.backgroundColor = UPApplicationColor.A5_000000()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
}
