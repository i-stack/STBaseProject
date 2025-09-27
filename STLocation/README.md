# STLocation

一个基于 CoreLocation 的 Swift Package Manager 位置管理库，提供简洁易用的位置获取、权限管理和地理编码功能。

## 功能特性

- 🎯 **单次定位**: 获取当前精确位置
- 🔄 **持续定位**: 实时位置更新
- 🔐 **权限管理**: 智能的位置权限请求和状态检查
- 📍 **地理编码**: 自动将坐标转换为地址信息
- ⚡ **缓存机制**: 智能位置缓存，提高性能
- 🛡️ **错误处理**: 完善的错误类型和处理机制
- 🎛️ **配置灵活**: 多种精度和超时配置选项
- 🔒 **线程安全**: 使用并发队列确保线程安全

## 系统要求

- iOS 13.0+
- Swift 5.9+
- Xcode 15.0+

## 安装方式

### Swift Package Manager

在你的 `Package.swift` 文件中添加依赖：

```swift
dependencies: [
    .package(url: "https://github.com/your-username/STLocation.git", from: "1.0.0")
]
```

或者在 Xcode 中：
1. 选择 `File` → `Add Package Dependencies`
2. 输入仓库 URL: `https://github.com/your-username/STLocation.git`
3. 选择版本并添加到你的项目

### 导入

```swift
import STLocation
```

## 权限配置

在 `Info.plist` 中添加位置权限说明：

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>此应用需要访问您的位置以提供基于位置的服务</string>

<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>此应用需要访问您的位置以提供基于位置的服务</string>
```

## 基本使用

### 1. 获取当前位置（单次定位）

```swift
STLocationManager.shared.st_getCurrentLocation { result in
    switch result {
    case .success(let locationInfo):
        print("位置信息: \(locationInfo.formattedAddress)")
        print("坐标: \(locationInfo.coordinateString)")
        print("经度: \(locationInfo.longitude)")
        print("纬度: \(locationInfo.latitude)")
    case .failure(let error):
        print("获取位置失败: \(error.localizedDescription)")
    }
}
```

### 2. 请求位置权限

```swift
// 请求使用期间的位置权限
STLocationManager.shared.st_requestWhenInUseAuthorization { status in
    switch status {
    case .authorizedWhenInUse, .authorizedAlways:
        print("位置权限已授权")
        // 现在可以获取位置
    case .denied, .restricted:
        print("位置权限被拒绝")
        // 引导用户到设置页面
    case .notDetermined:
        print("位置权限未确定")
    @unknown default:
        break
    }
}

// 请求始终的位置权限
STLocationManager.shared.st_requestAlwaysAuthorization { status in
    // 处理权限状态
}
```

### 3. 检查当前位置权限状态

```swift
STLocationManager.shared.st_checkLocationPermission { status in
    switch status {
    case .authorizedWhenInUse, .authorizedAlways:
        print("已有位置权限")
    case .denied, .restricted:
        print("位置权限被拒绝")
    case .notDetermined:
        print("位置权限未确定")
    @unknown default:
        break
    }
}
```

### 4. 使用自定义配置

```swift
// 高精度配置
let highAccuracyConfig = STLocationConfig.highAccuracy
STLocationManager.shared.st_getCurrentLocation(config: highAccuracyConfig) { result in
    // 处理结果
}

// 低精度配置（省电）
let lowAccuracyConfig = STLocationConfig.lowAccuracy
STLocationManager.shared.st_getCurrentLocation(config: lowAccuracyConfig) { result in
    // 处理结果
}

// 自定义配置
let customConfig = STLocationConfig(
    desiredAccuracy: kCLLocationAccuracyBest,
    distanceFilter: 5.0,
    timeout: 20.0,
    maximumAge: 180.0
)
STLocationManager.shared.st_getCurrentLocation(config: customConfig) { result in
    // 处理结果
}
```

### 5. 持续位置更新

```swift
// 开始持续位置更新
STLocationManager.shared.st_startUpdatingLocation { result in
    switch result {
    case .success(let locationInfo):
        print("位置更新: \(locationInfo.formattedAddress)")
    case .failure(let error):
        print("位置更新失败: \(error.localizedDescription)")
    }
}

// 停止位置更新
STLocationManager.shared.st_stopUpdatingLocation()
```

### 6. 获取最后已知位置

```swift
if let lastLocation = STLocationManager.shared.st_getLastKnownLocation() {
    print("最后位置: \(lastLocation.formattedAddress)")
    print("时间: \(lastLocation.timestamp)")
}
```

### 7. 清除位置缓存

```swift
STLocationManager.shared.st_clearLocationCache()
```

## 配置选项

### STLocationConfig

| 属性 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `desiredAccuracy` | `CLLocationAccuracy` | `kCLLocationAccuracyNearestTenMeters` | 期望的定位精度 |
| `distanceFilter` | `CLLocationDistance` | `10.0` | 位置更新的最小距离（米） |
| `timeout` | `TimeInterval` | `30.0` | 获取位置的超时时间（秒） |
| `maximumAge` | `TimeInterval` | `300.0` | 位置缓存的最大有效期（秒） |

### 预设配置

```swift
// 默认配置
STLocationConfig.default

// 高精度配置
STLocationConfig.highAccuracy

// 低精度配置（省电）
STLocationConfig.lowAccuracy
```

## 数据结构

### STLocationInfo

位置信息结构体，包含以下属性：

```swift
public struct STLocationInfo {
    public let name: String?                    // 地点名称
    public let country: String?                 // 国家
    public let latitude: Double                 // 纬度
    public let longitude: Double                // 经度
    public let locality: String?                // 城市
    public let subLocality: String?             // 区域
    public let thoroughfare: String?            // 街道
    public let subThoroughfare: String?         // 门牌号
    public let isoCountryCode: String?          // 国家代码
    public let administrativeArea: String?      // 省份/州
    public let postalCode: String?              // 邮编
    public let timestamp: Date                  // 时间戳
    
    // 计算属性
    public var formattedAddress: String         // 格式化地址
    public var coordinateString: String         // 坐标字符串
}
```

### STLocationError

错误类型枚举：

```swift
public enum STLocationError: Error {
    case authorizationDenied        // 权限被拒绝
    case authorizationRestricted    // 权限受限
    case locationServicesDisabled   // 位置服务已禁用
    case timeout                    // 获取位置超时
    case networkError              // 网络错误
    case geocodingFailed           // 地理编码失败
    case unknown(Error)            // 未知错误
}
```

## 完整使用示例

```swift
import STLocation

class LocationViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLocation()
    }
    
    private func setupLocation() {
        // 1. 检查权限状态
        STLocationManager.shared.st_checkLocationPermission { [weak self] status in
            switch status {
            case .authorizedWhenInUse, .authorizedAlways:
                self?.getCurrentLocation()
            case .notDetermined:
                self?.requestLocationPermission()
            case .denied, .restricted:
                self?.showPermissionAlert()
            @unknown default:
                break
            }
        }
    }
    
    private func requestLocationPermission() {
        STLocationManager.shared.st_requestWhenInUseAuthorization { [weak self] status in
            if status == .authorizedWhenInUse {
                self?.getCurrentLocation()
            }
        }
    }
    
    private func getCurrentLocation() {
        // 使用高精度配置
        STLocationManager.shared.st_getCurrentLocation(config: .highAccuracy) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let locationInfo):
                    self?.updateUI(with: locationInfo)
                case .failure(let error):
                    self?.showError(error)
                }
            }
        }
    }
    
    private func updateUI(with locationInfo: STLocationInfo) {
        // 更新界面显示位置信息
        print("地址: \(locationInfo.formattedAddress)")
        print("坐标: \(locationInfo.coordinateString)")
    }
    
    private func showError(_ error: STLocationError) {
        let alert = UIAlertController(title: "位置获取失败", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
    
    private func showPermissionAlert() {
        let alert = UIAlertController(title: "需要位置权限", message: "请在设置中开启位置权限", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "去设置", style: .default) { _ in
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
        })
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        present(alert, animated: true)
    }
}
```

## 注意事项

1. **权限处理**: 确保在 Info.plist 中添加相应的权限说明
2. **线程安全**: 所有回调都在主线程执行，但内部使用并发队列保证线程安全
3. **电池优化**: 使用低精度配置可以节省电池电量
4. **缓存机制**: 库会自动缓存位置信息，避免频繁请求
5. **超时处理**: 设置合适的超时时间，避免长时间等待

## 许可证

MIT License

## 贡献

欢迎提交 Issue 和 Pull Request！

## 更新日志

### 1.0.0
- 初始版本发布
- 支持单次定位和持续定位
- 完善的权限管理
- 地理编码功能
- 位置缓存机制
