# STMedia

一个功能丰富的 iOS 媒体处理 Swift 包，提供图片处理、扫码、截图等核心功能。

## 功能特性

- 📸 **图片处理**: 支持多种图片格式，提供压缩、裁剪、水印等功能
- 📱 **扫码功能**: 支持二维码和条形码扫描，提供可自定义的扫描界面
- 📷 **图片管理**: 相机拍照、相册选择、图片保存等完整流程
- 🖼️ **截图功能**: 应用截图检测和处理
- 🎨 **UI 扩展**: 丰富的 UIImage 和 UIView 扩展方法

## 系统要求

- iOS 13.0+
- Swift 5.0+
- Xcode 12.0+

## 安装方式

### Swift Package Manager

在 Xcode 中添加包依赖：

1. 打开 Xcode 项目
2. 选择 `File` → `Add Package Dependencies...`
3. 输入仓库地址：`https://github.com/i-stack/STProjectMedia.git`
4. 选择版本或分支
5. 点击 `Add Package`

### Package.swift

```swift
dependencies: [
    .package(url: "https://github.com/i-stack/STProjectMedia.git", branch: "main")
]
```

## 使用方法

### 1. 图片处理

#### 基础图片操作

```swift
import STMedia

// 检查图片是否为空
let isEmpty = UIImage.isEmpty(image)

// 图片压缩
let compressedImage = image.st_compressImage(quality: 0.8)

// 图片裁剪
let croppedImage = image.st_cropImage(to: CGRect(x: 0, y: 0, width: 100, height: 100))

// 图片缩放
let scaledImage = image.st_scaleImage(to: CGSize(width: 200, height: 200))

// 图片旋转
let rotatedImage = image.st_rotateImage(angle: 90)
```

#### 图片格式转换

```swift
// 获取图片格式
let format = image.st_imageFormat

// 转换为指定格式
let pngData = image.st_convertToPNG()
let jpegData = image.st_convertToJPEG(quality: 0.8)
```

#### 水印功能

```swift
// 添加文字水印
let watermarkedImage = image.st_addTextWatermark(
    text: "STMedia",
    position: .bottomRight,
    fontSize: 16,
    color: .white
)

// 添加图片水印
let logoImage = UIImage(named: "logo")
let finalImage = image.st_addImageWatermark(
    watermark: logoImage,
    position: .topLeft,
    alpha: 0.7
)
```

### 2. 图片管理

#### 相机拍照

```swift
import STMedia

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func takePhoto(_ sender: UIButton) {
        STImageManager.shared.takePhoto(from: .camera) { [weak self] result in
            switch result {
            case .success(let image):
                // 处理拍摄的图片
                self?.imageView.image = image
            case .failure(let error):
                print("拍照失败: \(error)")
            }
        }
    }
}
```

#### 相册选择

```swift
@IBAction func selectFromLibrary(_ sender: UIButton) {
    STImageManager.shared.selectImage(from: .photoLibrary) { [weak self] result in
        switch result {
        case .success(let image):
            // 处理选择的图片
            self?.imageView.image = image
        case .failure(let error):
            print("选择图片失败: \(error)")
        }
    }
}
```

#### 保存图片到相册

```swift
STImageManager.shared.saveImageToPhotoLibrary(image) { result in
    switch result {
    case .success:
        print("图片保存成功")
    case .failure(let error):
        print("保存失败: \(error)")
    }
}
```

### 3. 扫码功能

#### 基础扫码

```swift
import STMedia

class ViewController: UIViewController {
    
    @IBAction func startScan(_ sender: UIButton) {
        let scanManager = STScanManager()
        scanManager.scanType = .STScanTypeQrCode
        scanManager.presentVC = self
        
        scanManager.scanFinishBlock = { [weak self] result in
            print("扫描结果: \(result)")
            // 处理扫描结果
        }
        
        scanManager.startScan()
    }
}
```

#### 自定义扫码界面

```swift
// 创建自定义配置
var config = STScanViewConfiguration()
config.scanAreaMargin = 80.0
config.borderColor = .systemBlue
config.cornerColor = .systemRed
config.tipText = "请将二维码放入扫描框内"
config.tipTextColor = .white

// 创建扫码视图
let scanView = STScanView(frame: view.bounds, configuration: config)
view.addSubview(scanView)

// 开始扫描
scanView.startScanning()
```

#### 扫码结果处理

```swift
scanManager.scanFinishBlock = { [weak self] result in
    DispatchQueue.main.async {
        // 停止扫描
        scanManager.stopScan()
        
        // 处理不同类型的扫码结果
        if result.hasPrefix("http") {
            // 处理 URL
            self?.openURL(result)
        } else if result.hasPrefix("tel:") {
            // 处理电话号码
            self?.makePhoneCall(result)
        } else {
            // 显示普通文本
            self?.showAlert(message: result)
        }
    }
}
```

### 4. 截图功能

#### 监听截图事件

```swift
import STMedia

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 监听截图通知
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(userDidTakeScreenshot),
            name: UIApplication.userDidTakeScreenshotNotification,
            object: nil
        )
    }
    
    @objc func userDidTakeScreenshot() {
        print("用户截屏了！")
        
        // 获取截图
        if let screenshot = STScreenShot.st_imageWithScreenshot() {
            // 处理截图
            handleScreenshot(screenshot)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
```

#### 显示截图预览

```swift
@objc func userDidTakeScreenshot() {
    // 显示截图预览
    let screenshotView = STScreenShot.st_showScreenshotImage(rect: CGRect(x: 0, y: 0, width: 200, height: 200))
    view.addSubview(screenshotView)
    
    // 3秒后自动移除
    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
        screenshotView.removeFromSuperview()
    }
}
```

### 5. 权限处理

#### 相机权限

```swift
STImageManager.shared.requestCameraPermission { granted in
    if granted {
        print("相机权限已授权")
    } else {
        print("相机权限被拒绝")
        // 引导用户到设置页面
    }
}
```

#### 相册权限

```swift
STImageManager.shared.requestPhotoLibraryPermission { granted in
    if granted {
        print("相册权限已授权")
    } else {
        print("相册权限被拒绝")
    }
}
```

## 配置说明

### Info.plist 权限配置

在 `Info.plist` 中添加必要的权限描述：

```xml
<key>NSCameraUsageDescription</key>
<string>需要访问相机来拍照</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>需要访问相册来选择图片</string>

<key>NSPhotoLibraryAddUsageDescription</key>
<string>需要访问相册来保存图片</string>
```

## 依赖项

- `STProjectBase`: 基础工具库
- `UIKit`: iOS 用户界面框架
- `Photos`: 相册访问框架
- `AVFoundation`: 音视频处理框架

## 许可证

Copyright © 2018 ST. All rights reserved.

## 贡献

欢迎提交 Issue 和 Pull Request 来改进这个项目。

## 更新日志

### 1.0.0
- 初始版本发布
- 支持图片处理、扫码、截图等核心功能
- 提供完整的图片管理流程
