//
//  STNextViewController.swift
//  STBaseProject_Example
//
//  Created by song on 2021/1/7.
//  Copyright © 2021 STBaseProject. All rights reserved.
//

import UIKit
import SnapKit
import STBaseProject

class STNextViewController: STBaseViewController {

    var imagePickerManager: STImagePickerManager?

    deinit {
        STLog("STNextViewController dealloc")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.imagePickerManager = STImagePickerManager.init(presentViewController: self)
        self.st_showNavBtnType(type: .showLeftBtn)
        self.view.backgroundColor = UIColor.orange
    }
    

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        let alert = UIAlertController.init(title: nil, message: nil, preferredStyle: .actionSheet)
        let albumAction = UIAlertAction.init(title: "从手机相册中选择", style: .default) {[weak self] (action) in
            guard let strongSelf = self else { return }
            strongSelf.imagePickerManager?.st_openSystemOperation(openSourceType: .photoLibrary, complection: { (pickerModel) in
                if pickerModel.openSourceError == .openSourceOK {
                    if let editImage = pickerModel.editedImage {
                    }
                }
            })
        }
        alert.addAction(albumAction)
        let phoneAction = UIAlertAction.init(title: "拍照", style: .default) {[weak self] (action) in
            guard let strongSelf = self else { return }
            strongSelf.imagePickerManager?.st_openSystemOperation(openSourceType: .camera, complection: { (pickerModel) in
                if pickerModel.openSourceError == .openSourceOK {
                    if let editImage = pickerModel.editedImage {
                    }
                }
            })
        }
        alert.addAction(phoneAction)
        let cancelAction = UIAlertAction.init(title: "取消", style: .cancel) { (action) in}
        alert.addAction(cancelAction)
        self.present(alert, animated: true, completion: nil)
    }
}
