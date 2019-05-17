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

public typealias ScanFinishBlock = (_ result: String) -> Void

open class STScanViewController: STBaseOpenSystemOperationController {
    
    var delayQRAction: Bool = false
    var delayBarAction: Bool = false
    var scanFinishBlock: ScanFinishBlock?

    var scanRect: CGRect?
    var scanType: STScanType?
    var scanRectView: STScanView?
    
    var device: AVCaptureDevice?
    var session: AVCaptureSession?
    var input: AVCaptureDeviceInput?
    var output: AVCaptureMetadataOutput?
    var preview: AVCaptureVideoPreviewLayer?
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        self.st_showNavBtnType(type: .showBothBtn)
        self.st_scanDevice()
        self.st_drawScanView()
    }
    
    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let newSession = self.session {
            newSession.startRunning()
        }
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }
    
    override open func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        self.navigationController?.setNavigationBarHidden(true, animated: true)
        if let newSession = self.session {
            newSession.stopRunning()
        }
    }
    
    /**
     初始化二维码扫描控制器
     @param type 扫码类型
     */
    convenience public init(qrType type: STScanType, onFinish: @escaping(ScanFinishBlock)) {
        self.init()
        self.scanType = type
        self.scanFinishBlock = onFinish
    }

    public func st_scanFinishCallback(block: @escaping ScanFinishBlock) -> Void {
        self.scanFinishBlock = block
    }
    
    /**
     识别二维码
     @param image UIImage对象
     @param onFinish 识别结果回调
     */
    class open func st_recognizeQrCodeImage(image: UIImage, onFinish: @escaping(Result<String, Error>) -> Void) {
        if STScanViewController().st_stringToDouble(string: UIDevice.current.systemVersion) < 8.0 {
            STScanViewController().st_showError(message: "只支持iOS8.0以上系统")
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
    class open func st_createQRImageWithString(content: String, qrSize: CGSize, onFinish: @escaping(Result<UIImage, Error>) -> Void) {
        self.st_createQRImageWithString(content: content, qrSize: qrSize, qrColor: UIColor.black, bkColor: UIColor.white, onFinish: onFinish)
    }
    
    /**
     生成二维码【自定义颜色】
     @param  content 二维码内容字符串【数字、字符、链接等】
     @param  size 生成图片的大小
     @param  qrColor 二维码颜色
     @param  bkColor 背景色
     @return UIImage图片对象
     */
    class open func st_createQRImageWithString(content: String, qrSize: CGSize, qrColor: UIColor, bkColor: UIColor, onFinish: @escaping(Result<UIImage, Error>) -> Void) {
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
    class open func st_createBarCodeImageWithString(content: String, barSize: CGSize, onFinish: @escaping(Result<UIImage, Error>) -> Void) {
        self.st_createBarCodeImageWithString(content: content, barSize: barSize, barColor: UIColor.black, barBgColor: UIColor.white, onFinish: onFinish)
    }
    
    /**
     生成条形码【自定义颜色】
     @param content 条码内容【一般是数字】
     @param size 生成条码图片的大小
     @param qrColor 码颜色
     @param bkColor 背景颜色
     @return UIImage图片对象
     */
    class open func st_createBarCodeImageWithString(content: String, barSize: CGSize, barColor: UIColor, barBgColor: UIColor, onFinish: @escaping(Result<UIImage, Error>) -> Void) {
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
    class open func st_getHDImgWithCIImage(content: String, size: CGSize, waterImage: UIImage, waterImageSize: CGSize, onFinish: @escaping(Result<UIImage, Error>) -> Void) {
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
        
        if STScanViewController().st_imageIsEmpty(image: waterImage) == true {
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
    
    override open func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true) {}
        var image: UIImage? = info[UIImagePickerController.InfoKey.editedImage] as? UIImage
        if image == nil {
            image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage
        }
        STScanViewController.st_recognizeQrCodeImage(image: image ?? UIImage()) { [weak self] (result) in
            guard let strongSelf = self else {
                return
            }
            switch (result) {
            case .success(let str):
                strongSelf.st_renderUrlStr(url: str)
                break
            case .failure(_):
                break
            }
        }
    }
    
    override open func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}

extension STScanViewController: AVCaptureMetadataOutputObjectsDelegate {
    public func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if metadataObjects.count < 1 {
            return
        }
        if let newSession = self.session {
            newSession.stopRunning()
            let metadataObject: AVMetadataMachineReadableCodeObject = metadataObjects.first as! AVMetadataMachineReadableCodeObject
            self.st_renderUrlStr(url: metadataObject.stringValue ?? "")
        }
    }
}

extension STScanViewController {
    
    func st_renderUrlStr(url: String) -> Void {
        if let nav = self.navigationController {
            if let newScanFinish = self.scanFinishBlock {
                newScanFinish(url)
            }
            nav.popViewController(animated: true)
        }
    }
    
    // 打开相册
    open func st_openPhoto() -> Void {
        if self.st_isAvailablePhoto() == true {
            self.st_openPhotoLibrary()
        } else {
            self.st_authorizationFailed()
        }
    }
    
    open func st_openFlash(sender: UIButton) -> Void {
        sender.isSelected = !sender.isSelected
        if let newDevice = self.device, newDevice.hasTorch == true, newDevice.hasFlash == true, let newInput = self.input {
            let torch: AVCaptureDevice.TorchMode = newInput.device.torchMode
            try? newInput.device.lockForConfiguration()
            newInput.device.torchMode = torch
            newInput.device.unlockForConfiguration()
        }
    }
}

extension STScanViewController {
    
    func st_scanDevice() -> Void {
        if self.st_isAvailableCamera() == true {
            self.device = AVCaptureDevice.default(for: .video)
            self.input = try? AVCaptureDeviceInput.init(device: self.device!)
            self.output = AVCaptureMetadataOutput.init()
            self.output?.rectOfInterest = NSCoder.cgRect(for: self.st_scanRectWithScale(scale: 1)[0] as! String)
            self.output?.metadataObjectTypes = [AVMetadataObject.ObjectType.qr,
                                                AVMetadataObject.ObjectType.ean8,
                                                AVMetadataObject.ObjectType.ean13,
                                                AVMetadataObject.ObjectType.code128
                                                ]
            self.output?.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            self.session = AVCaptureSession()
            if let newSession = self.session {
                newSession.canSetSessionPreset(AVCaptureSession.Preset.inputPriority)
                if let newInput = self.input, newSession.canAddInput(newInput) == true {
                    newSession.addInput(newInput)
                }
                if let newOutput = self.output, newSession.canAddOutput(newOutput) == true {
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

    func st_drawScanView() -> Void {
        self.scanRectView = STScanView.init(frame: CGRect.init(x: 0, y: ST_NavHeight, width: self.view.bounds.size.width, height: self.view.bounds.size.height))
        self.scanRectView?.st_configScanType(scanType: self.scanType ?? STScanType.STScanTypeQrCode)
        self.view.addSubview(self.scanRectView!)
    }
    
    func st_scanRectWithScale(scale: CGFloat) -> NSArray {
        let windowSize = UIScreen.main.bounds.size
        let left = 60.0 / scale
        let scanSize = CGSize.init(width: self.view.frame.size.width - left * 2.0,
                                   height: (self.view.frame.size.width - left * 2.0) / scale)
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
