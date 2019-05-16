//
//  STScanViewController.swift
//  STBaseProject
//
//  Created by song on 2018/3/14.
//  Copyright © 2018 song. All rights reserved.
//

import UIKit
import Photos
import AVFoundation
import AssetsLibrary

typealias ScanFinishBlock = (_ result: String) -> Void

class STScanViewController: STBaseOpenSystemOperationController {
    
    var tipTitle: UILabel?  // 扫码区域下方提示文字
    var toolsView: UIView?  // 底部显示的功能项 -box
    var photoBtn: UIButton? // 相册按钮
    var flashBtn: UIButton? // 闪光灯按钮
    
    var appName: String?
    var delayQRAction: Bool = false
    var delayBarAction: Bool = false
    var scanFinishBlock: ScanFinishBlock?

    var scanRect: CGRect?
    var scanType: STScanType?
    var scanTypeQrBtn: UIButton?   // 修改扫码类型按钮
    var scanTypeBarBtn: UIButton?  // 修改扫码类型按钮
    var scanRectView: STScanView?
    
    var device: AVCaptureDevice?
    var session: AVCaptureSession?
    var input: AVCaptureDeviceInput?
    var output: AVCaptureMetadataOutput?
    var preview: AVCaptureVideoPreviewLayer?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.black
        self.appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
        self.scanDevice()
        self.drawTitle()
        self.drawScanView()
        self.initScanType()
        self.switchBarView(type: self.scanType ?? .STScanTypeQrCode)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let newSession = self.session {
            newSession.startRunning()
        }
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        self.navigationController?.setNavigationBarHidden(true, animated: true)
        if let newSession = self.session {
            newSession.stopRunning()
        }
    }
    
    func scanFinishCallback(block: @escaping ScanFinishBlock) -> Void {
        self.scanFinishBlock = block
    }

    /**
     初始化二维码扫描控制器
     @param type 扫码类型
     */
    func initWithQrType(type: STScanType, onFinish: @escaping(ScanFinishBlock)) -> Void {
        self.scanType = type
        self.scanFinishBlock = onFinish
    }
    
    /**
     识别二维码
     @param image UIImage对象
     @param onFinish 识别结果回调
     */
    class func recognizeQrCodeImage(image: UIImage, onFinish: @escaping(Result<String, Error>) -> Void) {
        
        if STScanViewController().stringToDouble(string: UIDevice.current.systemVersion) < 8.0 {
            STScanViewController().showError(message: "只支持iOS8.0以上系统")
            return
        }
        
        let context: CIContext = CIContext()
        let detector: CIDetector = CIDetector.init(ofType: CIDetectorTypeQRCode, context: context, options: [CIDetectorAccuracy : CIDetectorAccuracyHigh]) ?? CIDetector()
        
        let features: [CIFeature] = detector.features(in: CIImage.init(image: image) ?? CIImage.empty())
        if features.count >= 1 {
            let feature: CIQRCodeFeature = features[0] as! CIQRCodeFeature
            let scanResult = feature.messageString
            onFinish(.success(scanResult ?? ""))
        } else {
            onFinish(.failure(NSError.init(domain: "scan_error", code: 0, userInfo: [:])))
        }
    }
    
    /**
     生成二维码【白底黑色】
     @param  content  二维码内容字符串【数字、字符、链接等】
     @param  qrSize   生成图片的大小
     @return onFinish 图片对象回调
     */
    class func createQRImageWithString(content: String, qrSize: CGSize, onFinish: @escaping(Result<UIImage, Error>) -> Void) {
        self.createQRImageWithString(content: content, qrSize: qrSize, qrColor: UIColor.black, bkColor: UIColor.white, onFinish: onFinish)
    }
    
    /**
     生成二维码【自定义颜色】
     @param  content 二维码内容字符串【数字、字符、链接等】
     @param  size 生成图片的大小
     @param  qrColor 二维码颜色
     @param  bkColor 背景色
     @return UIImage图片对象
     */
    class func createQRImageWithString(content: String, qrSize: CGSize, qrColor: UIColor, bkColor: UIColor, onFinish: @escaping(Result<UIImage, Error>) -> Void) {
        if content.count < 1 {
            DispatchQueue.main.async {
                onFinish(.failure(NSError.init(domain: "content is nil!", code: 0, userInfo: [:])))
            }
            return
        }
        
        if qrSize == CGSize.zero {
            DispatchQueue.main.async {
                onFinish(.failure(NSError.init(domain: "qrSize is zero!", code: 0, userInfo: [:])))
            }
            return
        }
        
        let stringData = content.data(using: String.Encoding.utf8)
        let qrFilter: CIFilter = CIFilter.init(name: "CIQRCodeGenerator") ?? CIFilter()
        qrFilter.setValue(stringData, forKey: "inputMessage")
        qrFilter.setValue("H", forKey: "inputCorrectionLevel")
        let colorFilter: CIFilter = CIFilter.init(
            name: "CIFalseColor",
            parameters: ["inputImage": qrFilter.outputImage ?? CIImage.empty(),
                        "inputColor0": CIColor.init(cgColor: qrColor.cgColor),
                        "inputColor1": CIColor.init(cgColor: bkColor.cgColor)]) ?? CIFilter()
        let qrImage: CIImage = colorFilter.outputImage ?? CIImage.empty()
        let cgImage: CGImage = CIContext.init().createCGImage(qrImage, from: qrImage.extent)!
        
        UIGraphicsBeginImageContext(qrSize)
        let cgContext: CGContext = UIGraphicsGetCurrentContext()!
        cgContext.interpolationQuality = .none
        cgContext.scaleBy(x: 1.0, y: -1.0)
        cgContext.draw(cgImage, in: cgContext.boundingBoxOfClipPath)
        let codeImage: UIImage = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
        UIGraphicsEndImageContext()
        DispatchQueue.main.async {
            onFinish(.success(codeImage))
        }
    }

    /**
     生成条形码【白底黑色】
     @param content 条码内容【一般是数字】
     @param barSize 生成条码图片的大小
     @return UIImage图片对象
     */
    class func createBarCodeImageWithString(content: String, barSize: CGSize, onFinish: @escaping(Result<UIImage, Error>) -> Void) {
        self.createBarCodeImageWithString(content: content, barSize: barSize, barColor: UIColor.black, barBgColor: UIColor.white, onFinish: onFinish)
    }
    
    /**
     生成条形码【自定义颜色】
     @param content 条码内容【一般是数字】
     @param size 生成条码图片的大小
     @param qrColor 码颜色
     @param bkColor 背景颜色
     @return UIImage图片对象
     */
    class func createBarCodeImageWithString(content: String, barSize: CGSize, barColor: UIColor, barBgColor: UIColor, onFinish: @escaping(Result<UIImage, Error>) -> Void) {
        if content.count < 1 {
            DispatchQueue.main.async {
                onFinish(.failure(NSError.init(domain: "content is nil!", code: 0, userInfo: [:])))
            }
            return
        }
        
        if barSize == CGSize.zero {
            DispatchQueue.main.async {
                onFinish(.failure(NSError.init(domain: "barSize is zero!", code: 0, userInfo: [:])))
            }
            return
        }
        
        let stringData = content.data(using: String.Encoding.utf8)
        let qrFilter: CIFilter = CIFilter.init(name: "CICode128BarcodeGenerator") ?? CIFilter()
        qrFilter.setValue(stringData, forKey: "inputMessage")
        let colorFilter: CIFilter = CIFilter.init(
            name: "CIFalseColor",
            parameters: ["inputImage": qrFilter.outputImage ?? CIImage.empty(),
                         "inputColor0": CIColor.init(cgColor: barColor.cgColor),
                         "inputColor1": CIColor.init(cgColor: barBgColor.cgColor)]) ?? CIFilter()
        let qrImage: CIImage = colorFilter.outputImage ?? CIImage.empty()
        let cgImage: CGImage = CIContext.init().createCGImage(qrImage, from: qrImage.extent)!
        UIGraphicsBeginImageContext(barSize)
        let cgContext: CGContext = UIGraphicsGetCurrentContext()!
        cgContext.interpolationQuality = .none
        cgContext.scaleBy(x: 1.0, y: -1.0)
        cgContext.draw(cgImage, in: cgContext.boundingBoxOfClipPath)
        let codeImage: UIImage = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
        UIGraphicsEndImageContext()
        DispatchQueue.main.async {
            onFinish(.success(codeImage))
        }
    }
    
    /**
     调整二维码清晰度，添加水印图片
     @param content 模糊的二维码图片字符串
     @param size 二维码的宽高
     @param waterImg 水印图片
     @return 添加水印图片后，清晰的二维码图片
     */
    class func getHDImgWithCIImage(content: String, size: CGSize, waterImage: UIImage, waterImageSize: CGSize, onFinish: @escaping(Result<UIImage, Error>) -> Void) {
        if content.count < 1 {
            DispatchQueue.main.async {
                onFinish(.failure(NSError.init(domain: "content is nil!", code: 0, userInfo: [:])))
            }
            return
        }
        
        if size == CGSize.zero {
            DispatchQueue.main.async {
                onFinish(.failure(NSError.init(domain: "size is zero!", code: 0, userInfo: [:])))
            }
            return
        }
        
        if STScanViewController().imageIsEmpty(image: waterImage) == true {
            DispatchQueue.main.async {
                onFinish(.failure(NSError.init(domain: "waterImageSize is nil!", code: 0, userInfo: [:])))
            }
            return
        }
        
        if waterImageSize == CGSize.zero {
            DispatchQueue.main.async {
                onFinish(.failure(NSError.init(domain: "waterImageSize is zero!", code: 0, userInfo: [:])))
            }
            return
        }
        
        let stringData = content.data(using: String.Encoding.utf8)
        let qrFilter: CIFilter = CIFilter.init(name: "CIQRCodeGenerator") ?? CIFilter()
        qrFilter.setValue(stringData, forKey: "inputMessage")
        qrFilter.setValue("H", forKey: "inputCorrectionLevel")
        
        let img: CIImage = qrFilter.outputImage ?? CIImage.empty()
        let extent: CGRect = img.extent.integral
        let scale: CGFloat = min(size.width / extent.width, size.height / extent.height)
        let width: CGFloat = extent.width * scale
        let height: CGFloat = extent.height * scale;
        let cs: CGColorSpace = CGColorSpaceCreateDeviceGray()
        let bitmapRef: CGContext = CGContext(data: nil, width: Int(width), height: Int(height), bitsPerComponent: 8, bytesPerRow: 0, space: cs, bitmapInfo: CGImageAlphaInfo.none.rawValue)!
        let ciContext: CIContext = CIContext.init()
        let bitmapImage: CGImage = ciContext.createCGImage(img, from: extent)!
        bitmapRef.interpolationQuality = CGInterpolationQuality.none
        bitmapRef.scaleBy(x: scale, y: scale)
        bitmapRef.draw(bitmapImage, in: extent)
        let scaledImage: CGImage = bitmapRef.makeImage()!
        let outputImage: UIImage = UIImage.init(cgImage: scaledImage)
        UIGraphicsBeginImageContextWithOptions(outputImage.size, false, UIScreen.main.scale)
        outputImage.draw(in: CGRect.init(x: 0, y: 0, width: size.width, height: size.height))
    //把水印图片画到生成的二维码图片上，注意尺寸不要太大（根据上面生成二维码设置的纠错程度设置），否则有可能造成扫不出来
        let waterImgH: CGFloat = waterImageSize.height
        let waterImgW: CGFloat = waterImageSize.width
        waterImage.draw(in: CGRect.init(x: (size.width - waterImgW) / 2.0, y: (size.height - waterImgH) / 2.0, width: waterImgW, height: waterImgH))
        let newPic: UIImage = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
        UIGraphicsEndImageContext()
        DispatchQueue.main.async {
            onFinish(.success(newPic))
        }
    }
    
    override func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true) {}
        var image: UIImage? = info[UIImagePickerController.InfoKey.editedImage] as? UIImage
        if image == nil {
            image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage
        }
        STScanViewController.recognizeQrCodeImage(image: image ?? UIImage()) { [weak self] (result) in
            guard let strongSelf = self else {
                return
            }
            switch (result) {
            case .success(let str):
                strongSelf.renderUrlStr(url: str)
                break
            case .failure(_):
                break
            }
        }
    }
    
    override func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}

extension STScanViewController: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if metadataObjects.count < 1 {
            return
        }
        if let newSession = self.session {
            newSession.stopRunning()
            let metadataObject: AVMetadataMachineReadableCodeObject = metadataObjects.first as! AVMetadataMachineReadableCodeObject
            self.renderUrlStr(url: metadataObject.stringValue ?? "")
        }
    }
}

extension STScanViewController {
    
    func renderUrlStr(url: String) -> Void {
        if let nav = self.navigationController {
            if let newScanFinish = self.scanFinishBlock {
                newScanFinish(url)
            }
            nav.popViewController(animated: true)
        }
    }
    
    // 打开相册
    func openPhoto() -> Void {
        if self.isAvailablePhoto() == true {
            self.openPhotoLibrary()
        } else {
            self.authorizationFailed()
        }
    }
    
    func openFlash(sender: UIButton) -> Void {
        sender.isSelected = !sender.isSelected
        if let newDevice = self.device, newDevice.hasTorch == true, newDevice.hasFlash == true, let newInput = self.input {
            let torch: AVCaptureDevice.TorchMode = newInput.device.torchMode
            try? newInput.device.lockForConfiguration()
            newInput.device.torchMode = torch
            newInput.device.unlockForConfiguration()
        }
    }
}

/// 修改扫码类型 【二维码  || 条形码】
extension STScanViewController {
    @objc func qrBtnClicked(sender: UIButton) -> Void {
        self.scanTypeBarBtn?.isSelected = false
        self.scanBtnCommon(sender: sender, type: .STScanTypeQrCode)
    }
    
    @objc func barBtnClicked(sender: UIButton) -> Void {
        self.scanTypeQrBtn?.isSelected = false
        self.scanRectView?.stopAnimating()
        self.scanBtnCommon(sender: sender, type: .STScanTypeBarCode)
    }
    
    func scanBtnCommon(sender: UIButton, type: STScanType) -> Void {
        if sender.isSelected == true {
            return
        }
        if self.delayQRAction == true {
            return
        }
        sender.isSelected = true
        self.changeScanCodeType(type: type)
        self.switchBarView(type: type)
        self.delayQRAction = true
        self.performTaskWithTimeInterval(timeInterval: 3.0) { (result) in
            self.delayQRAction = false
        }
    }
    
    /// 修改扫码类型 【二维码  || 条形码】
    func changeScanCodeType(type: STScanType) -> Void {
        if let newSession = self.session {
            newSession.stopRunning()
            var scanSize = NSCoder.cgRect(for: self.scanRectWithScale(scale: 1)[1] as! String)
            if type == .STScanTypeBarCode {
                self.output?.metadataObjectTypes = [AVMetadataObject.ObjectType.ean13,
                                                    AVMetadataObject.ObjectType.ean8,
                                                    AVMetadataObject.ObjectType.code128]
                self.navigationController?.title = "条形码"
                self.scanRect = NSCoder.cgRect(for: self.scanRectWithScale(scale: 3)[0] as! String)
                scanSize = NSCoder.cgRect(for: self.scanRectWithScale(scale: 3)[1] as! String)
                self.tipTitle?.text = "将取景框对准条码,即可自动扫描"
            } else {
                self.output?.metadataObjectTypes = [AVMetadataObject.ObjectType.qr]
                self.navigationController?.title = "二维码"
                self.scanRect = NSCoder.cgRect(for: self.scanRectWithScale(scale: 1)[0] as! String)
                scanSize = NSCoder.cgRect(for: self.scanRectWithScale(scale: 1)[1] as! String)
                self.tipTitle?.text = "将取景框对准二维码,即可自动扫描"
            }
            
            //设置扫描聚焦区域
            DispatchQueue.main.async {
                self.output?.rectOfInterest = self.scanRect ?? CGRect.zero
                self.scanRectView?.configScanType(scanType: type)
                self.session?.startRunning()
            }
            UIView.animate(withDuration: 0.3, animations: {
                self.tipTitle?.center = CGPoint.init(x: self.view.center.x, y: self.view.center.y + scanSize.height / 2 + 25)
            })
        }
    }
    
    func switchBarView(type: STScanType) -> Void {
        if type == .STScanTypeBarCode {
            
        }
    }
}

extension STScanViewController {
    func scanDevice() -> Void {
        if self.isAvailableCamera() == true {
            self.device = AVCaptureDevice.default(for: .video)
            self.input = try? AVCaptureDeviceInput.init(device: self.device!)
            self.output = AVCaptureMetadataOutput.init()
            self.output?.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            self.session = AVCaptureSession()
            if let newSession = self.session {
                newSession.canSetSessionPreset(AVCaptureSession.Preset.inputPriority)
                if let newInput = self.input, newSession.canAddInput(newInput) == true {
                    newSession.addInput(newInput)
                }
                
                if let newOutput = self.output,  newSession.canAddOutput(newOutput) == true {
                    newSession.addOutput(newOutput)
                    newOutput.metadataObjectTypes = [AVMetadataObject.ObjectType.qr]
                    newOutput.rectOfInterest = self.scanRect ?? CGRect.zero
                }
                
                self.preview = AVCaptureVideoPreviewLayer.init(session: newSession)
                if let newPreview = self.preview {
                    newPreview.videoGravity = .resizeAspectFill
                    newPreview.frame = UIScreen.main.bounds
                    self.view.layer.insertSublayer(newPreview, at: 0)
                }
            }
        }
    }
    
    func drawTitle() -> Void {
        guard self.tipTitle != nil else {
            self.tipTitle = UILabel()
            self.tipTitle?.bounds = CGRect.init(x: 0, y: 0, width: 300, height: 50)
            self.tipTitle?.center = CGPoint.init(x: self.view.frame.size.width / 2.0,
                                                 y: self.view.center.y + self.view.frame.size.width / 2.0 - 35.0)
            self.tipTitle?.font = UIFont.systemFont(ofSize: 13)
            self.tipTitle?.textAlignment = .center
            self.tipTitle?.numberOfLines = 0
            self.tipTitle?.textColor = UIColor.white
            self.tipTitle?.layer.zPosition = 1
            self.view.addSubview(self.tipTitle!)
            self.view.bringSubviewToFront(self.tipTitle!)
            return
        }
    }
    
    func drawScanView() -> Void {
        self.scanRectView = STScanView.init(frame: self.view.frame)
        self.scanRectView?.configScanType(scanType: self.scanType ?? STScanType.STScanTypeQrCode)
        self.view.addSubview(self.scanRectView!)
    }
    
    func initScanType() -> Void {
        if self.scanType == .STScanTypeAll {
            self.scanRect = NSCoder.cgRect(for: self.scanRectWithScale(scale: 1)[0] as! String)
            self.output?.rectOfInterest = self.scanRect ?? CGRect.zero
            self.drawBottomItems()
        } else if self.scanType == .STScanTypeQrCode {
            self.output?.metadataObjectTypes = [AVMetadataObject.ObjectType.qr]
            self.navigationController?.title = "扫一扫"
            self.scanRect = NSCoder.cgRect(for: self.scanRectWithScale(scale: 1)[0] as! String)
            self.output?.rectOfInterest = self.scanRect ?? CGRect.zero
            
            self.tipTitle?.center = CGPoint.init(x: self.view.center.x, y: self.view.center.y + NSCoder.cgRect(for: self.scanRectWithScale(scale: 1)[1] as! String).height / 2 + 25)
        } else if self.scanType == .STScanTypeBarCode {
            self.output?.metadataObjectTypes = [AVMetadataObject.ObjectType.ean13,
                                                AVMetadataObject.ObjectType.ean8,
                                                AVMetadataObject.ObjectType.code128]
            self.navigationController?.title = "条形码"
            self.scanRect = NSCoder.cgRect(for: self.scanRectWithScale(scale: 3)[0] as! String)
            self.output?.rectOfInterest = self.scanRect ?? CGRect.zero
            self.scanRectView?.configScanType(scanType: .STScanTypeBarCode)
            self.tipTitle?.text = "将取景框对准条码,即可自动扫描"
            self.tipTitle?.center = CGPoint.init(x: self.view.center.x, y: self.view.center.y + NSCoder.cgRect(for: self.scanRectWithScale(scale: 3)[1] as! String).height / 2 + 25)
        }
    }
    
    func bundlePathURL() -> URL {
        let path: String = Bundle.main.path(forResource: "STScanResource", ofType: "bundle") ?? ""
        return URL.init(fileURLWithPath: path)
    }
    
    func drawBottomItems() -> Void {
        
        if (self.toolsView != nil) {
            return
        }
        self.toolsView = UIView.init(frame: CGRect.init(x: 0,
                                                        y: self.view.frame.maxY - 64.0,
                                                        width: self.view.frame.width,
                                                        height: 64))
        self.toolsView?.backgroundColor = UIColor.init(red: 0.212,
                                                       green: 0.208,
                                                       blue: 0.231,
                                                       alpha: 1.00)
        
        let size = CGSize.init(width: UIScreen.main.bounds.size.width / 2.0,
                               height: 64.0)
        self.scanTypeQrBtn = UIButton.init(type: UIButton.ButtonType.custom)
        self.scanTypeQrBtn?.frame = CGRect.init(x: 0,
                                                y: 0,
                                                width: size.width,
                                                height: size.height)
        self.scanTypeQrBtn?.setTitle("", for: UIControl.State.normal)
        self.scanTypeQrBtn?.setTitleColor(UIColor.white, for: UIControl.State.normal)
        self.scanTypeQrBtn?.setTitleColor(UIColor.init(red: 0.165,
                                                       green: 0.663,
                                                       blue: 0.886,
                                                       alpha: 1.00),
                                          for: UIControl.State.selected)
        
        let qrPath: String = self.bundlePathURL().appendingPathComponent("scan_qr_select").absoluteString
        let qrImage: UIImage = UIImage.init(contentsOfFile: qrPath) ?? UIImage()
        self.scanTypeQrBtn?.setImage(qrImage, for: UIControl.State.normal)
        self.scanTypeQrBtn?.isSelected = true
        self.scanTypeQrBtn?.imageEdgeInsets = UIEdgeInsets.init(top: 0,
                                                                left: 0,
                                                                bottom: 0,
                                                                right: 15)
        self.scanTypeQrBtn?.titleEdgeInsets = UIEdgeInsets.init(top: 0,
                                                                left: 0,
                                                                bottom: 0,
                                                                right: 0)
        self.scanTypeQrBtn?.addTarget(self,
                                      action: #selector(qrBtnClicked(sender:)),
                                      for: UIControl.Event.touchUpInside)
        
        self.scanTypeBarBtn = UIButton.init(type: UIButton.ButtonType.custom)
        self.scanTypeBarBtn?.frame = CGRect.init(x: size.width,
                                                 y: 0,
                                                 width: size.width,
                                                 height: size.height)
        self.scanTypeBarBtn?.setTitle("", for: UIControl.State.normal)
        self.scanTypeBarBtn?.setTitleColor(UIColor.white, for: UIControl.State.normal)
        self.scanTypeBarBtn?.setTitleColor(UIColor.init(red: 0.165,
                                                        green: 0.663,
                                                        blue: 0.886,
                                                        alpha: 1.00),
                                           for: UIControl.State.selected)
        
        let barPath: String = self.bundlePathURL().appendingPathComponent("scan_bar_normal").absoluteString
        let barImage: UIImage = UIImage.init(contentsOfFile: barPath) ?? UIImage()
        self.scanTypeBarBtn?.setImage(barImage, for: UIControl.State.normal)
        self.scanTypeBarBtn?.isSelected = false
        self.scanTypeBarBtn?.imageEdgeInsets = UIEdgeInsets.init(top: 0,
                                                                 left: 0,
                                                                 bottom: 0,
                                                                 right: 15)
        self.scanTypeBarBtn?.titleEdgeInsets = UIEdgeInsets.init(top: 0,
                                                                 left: 0,
                                                                 bottom: 0,
                                                                 right: 0)
        self.scanTypeBarBtn?.addTarget(self,
                                       action: #selector(barBtnClicked(sender:)),
                                       for: UIControl.Event.touchUpInside)
        self.toolsView?.addSubview(self.scanTypeQrBtn!)
        self.toolsView?.addSubview(self.scanTypeBarBtn!)
        self.view.addSubview(self.toolsView!)
    }
    
    func scanRectWithScale(scale: CGFloat) -> NSArray {
        let windowSize = UIScreen.main.bounds.size
        let Left = 60.0 / scale
        let scanSize = CGSize.init(width: self.view.frame.size.width - Left * 2.0,
                                   height: (self.view.frame.size.width - Left * 2.0) / scale)
        var scanRect = CGRect.init(x: (windowSize.width - scanSize.width) / 2.0,
                                   y: (windowSize.height - scanSize.height) / 2.0,
                                   width: scanSize.width,
                                   height: scanSize.height)
        scanRect = CGRect.init(x: scanRect.origin.y / windowSize.height,
                               y: scanRect.origin.x / windowSize.width,
                               width: scanRect.size.height / windowSize.height,
                               height: scanRect.size.width / windowSize.width)
        return [NSCoder.string(for: scanRect), NSCoder.string(for: scanSize)]
    }
}
