# STContacts

一个简洁易用的iOS联系人管理Swift Package，基于Apple的Contacts框架封装，提供联系人权限管理和数据获取功能。

## 功能特性

- 🔐 联系人权限请求和管理
- 📱 获取设备所有联系人信息
- ✅ 权限状态检查
- 🎯 基于CNContact的完整联系人数据
- 📦 Swift Package Manager支持
- 🛡️ 错误处理和异常捕获

## 系统要求

- iOS 13.0+
- Swift 5.0+
- Xcode 12.0+

## 安装方式

### Swift Package Manager

在Xcode中，选择 `File` → `Add Package Dependencies...`，然后输入以下URL：

```
https://github.com/i-stack/STContacts.git
```

或者在 `Package.swift` 文件中添加依赖：

```swift
dependencies: [
    .package(url: "https://github.com/i-stack/STContacts.git", branch: "main")
]
```

### 手动集成

1. 下载源码到本地
2. 将 `Sources` 文件夹拖拽到你的项目中
3. 确保项目设置中包含了必要的框架依赖

## 使用方法

### 1. 导入框架

```swift
import STContacts
import Contacts
```

### 2. 权限管理

#### 检查联系人权限状态

```swift
let permissionStatus = STContactManager.shared.st_checkContactPermission()

switch permissionStatus {
case .authorized:
    print("已授权")
case .denied:
    print("已拒绝")
case .restricted:
    print("受限制")
case .notDetermined:
    print("未确定")
@unknown default:
    print("未知状态")
}
```

#### 请求联系人权限

```swift
STContactManager.shared.st_requestContactPermission { granted, contacts, error in
    DispatchQueue.main.async {
        if granted {
            print("权限获取成功，联系人数量：\(contacts.count)")
            // 处理联系人数据
        } else {
            print("权限被拒绝：\(error)")
        }
    }
}
```

### 3. 获取联系人数据

#### 直接获取联系人（需要先确保有权限）

```swift
STContactManager.shared.st_fetchContactInfo { success, contacts, error in
    DispatchQueue.main.async {
        if success {
            print("成功获取 \(contacts.count) 个联系人")
            
            for contact in contacts {
                print("姓名：\(contact.givenName) \(contact.familyName)")
                
                // 获取电话号码
                for phoneNumber in contact.phoneNumbers {
                    print("电话：\(phoneNumber.value.stringValue)")
                }
            }
        } else {
            print("获取联系人失败：\(error)")
        }
    }
}
```

### 4. 完整使用示例

```swift
import UIKit
import STContacts
import Contacts

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadContacts()
    }
    
    private func loadContacts() {
        // 先检查权限状态
        let status = STContactManager.shared.st_checkContactPermission()
        
        switch status {
        case .authorized:
            // 已授权，直接获取联系人
            fetchContacts()
            
        case .notDetermined:
            // 未确定，请求权限
            requestPermission()
            
        case .denied, .restricted:
            // 被拒绝或受限制，提示用户
            showPermissionAlert()
            
        @unknown default:
            break
        }
    }
    
    private func requestPermission() {
        STContactManager.shared.st_requestContactPermission { [weak self] granted, contacts, error in
            DispatchQueue.main.async {
                if granted {
                    self?.processContacts(contacts)
                } else {
                    print("权限被拒绝：\(error)")
                }
            }
        }
    }
    
    private func fetchContacts() {
        STContactManager.shared.st_fetchContactInfo { [weak self] success, contacts, error in
            DispatchQueue.main.async {
                if success {
                    self?.processContacts(contacts)
                } else {
                    print("获取联系人失败：\(error)")
                }
            }
        }
    }
    
    private func processContacts(_ contacts: [CNContact]) {
        print("成功获取 \(contacts.count) 个联系人")
        
        for contact in contacts {
            let fullName = "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces)
            print("联系人：\(fullName)")
            
            for phoneNumber in contact.phoneNumbers {
                print("  电话：\(phoneNumber.value.stringValue)")
            }
        }
    }
    
    private func showPermissionAlert() {
        let alert = UIAlertController(
            title: "需要联系人权限",
            message: "请在设置中允许访问联系人",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "设置", style: .default) { _ in
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
        })
        
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        present(alert, animated: true)
    }
}
```

## API 文档

### STContactManager

#### 属性

- `shared: STContactManager` - 单例实例

#### 方法

##### st_requestContactPermission(completion:)

请求联系人权限并获取联系人数据。

**参数：**
- `completion: (Bool, [CNContact], String) -> Void` - 完成回调
  - `Bool` - 是否授权成功
  - `[CNContact]` - 联系人列表
  - `String` - 错误信息

##### st_fetchContactInfo(completion:)

获取联系人信息（需要先确保有权限）。

**参数：**
- `completion: (Bool, [CNContact], String) -> Void` - 完成回调
  - `Bool` - 是否成功
  - `[CNContact]` - 联系人列表
  - `String` - 错误信息

##### st_checkContactPermission() -> CNAuthorizationStatus

检查联系人权限状态。

**返回值：**
- `CNAuthorizationStatus` - 权限状态枚举值

## 注意事项

1. **隐私权限**：使用前需要在 `Info.plist` 中添加联系人权限说明：
   ```xml
   <key>NSContactsUsageDescription</key>
   <string>此应用需要访问您的联系人以便提供更好的服务</string>
   ```

2. **线程安全**：所有回调都在后台线程执行，如需更新UI请切换到主线程。

3. **错误处理**：建议始终检查回调中的成功状态和错误信息。

4. **权限状态**：权限状态可能发生变化，建议在每次使用前检查权限状态。

## 依赖项

- `STProjectBase` - 基础项目框架依赖

## 许可证

请查看项目根目录的许可证文件。

## 贡献

欢迎提交 Issue 和 Pull Request 来改进这个项目。

## 更新日志

### v1.0.0
- 初始版本发布
- 支持联系人权限管理
- 支持联系人数据获取
- 提供完整的API接口
