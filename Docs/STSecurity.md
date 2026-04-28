# STSecurity 模块说明

本文档聚焦 `Sources/STSecurity` 目录，说明该目录下安全能力的职责边界、核心类型、接入方式与风险注意项。

---

## 模块定位

`STSecurity` 是 `STBaseProject` 的安全能力聚合模块，主要提供：

- 数据加解密与签名能力（多算法支持）
- Keychain 敏感信息安全存取能力
- 安全策略统一配置与持久化能力
- 运行时安全检测（代理、调试、Hook、越狱、模拟器、Pinning 配置完整性）
- 可选的定时反调试监控能力

该模块的设计目标是：让业务层只关注“何时启用什么安全策略”，不直接处理底层安全 API 细节。

---

## 目录结构与职责

### `STSecurityConfig.swift`

安全配置中枢，负责“读取配置 -> 应用配置 -> 安全检测 -> 风险回调”完整链路。

核心职责：

- 持有并管理 `STSSLPinningConfig`、`STEncryptionConfig`、`STAntiDebugConfig`
- 将配置持久化到 Keychain，并支持进程重启后恢复
- 将 SSL Pinning 配置应用到 `STHTTPSession`
- 将加密算法配置同步到 `STCryptoService`
- 根据反调试配置启动/停止 `STAntiDebugMonitor`
- 统一输出 `STSecurityCheckResult`

### `STSecurityModels.swift`

安全模块的模型与错误定义，包括：

- `STCryptoAlgorithm`：算法枚举（`AES-256-GCM`、`AES-256-CBC`、`ChaCha20-Poly1305`）
- `STEncryptionConfig`：加密配置模型
- `STAntiDebugConfig`：反调试配置模型
- `STSecurityIssue` / `STSecuritySeverity`：安全问题与严重级别
- `STSecurityCheckResult`：检测结果聚合
- `STCryptoError`：统一加密错误

### `STCryptoService.swift`

统一加密服务，封装 CryptoKit / CommonCrypto 细节。

核心能力：

- 对称加密/解密：`AES-256-GCM`、`AES-256-CBC`、`ChaCha20-Poly1305`
- 签名与验签：基于 `HMAC-SHA256`
- 批量加解密
- 异步加解密（回调在主线程）
- 统一密钥派生与随机密钥生成

### `STEncrypt.swift`

偏工具层的加密扩展，提供字符串/二进制常用安全能力：

- Hash：MD5/SHA1/SHA256/SHA384/SHA512
- HMAC：SHA256/SHA512
- AES-256-GCM 字符串与数据扩展
- PBKDF2 密钥派生
- 安全随机字符串/Token 生成
- 常量时间字符串比较

适合业务快速调用基础安全工具；复杂流程建议优先走 `STCryptoService`。

### `STKeychainHelper.swift`

Keychain 统一封装，提供多类型读写和访问控制策略：

- 字符串、二进制、Bool、Int、Double 读写
- 批量写入/批量删除
- 项目存在性、数量、键集合查询
- 生物识别能力检测与读写（Face ID / Touch ID）
- 访问控制（`whenUnlocked`、`biometricCurrentSet`、`devicePasscode` 等）
- 同步策略（本地 / iCloud 同步）

### `STAntiDebugMonitor.swift`

定时安全巡检执行器（可选启用），按配置周期触发检测：

- 在主线程启动和停止 Timer，避免线程竞态
- 周期执行 `STSecurityConfig.shared.st_performSecurityCheck()`
- 将发现的问题通过 `onSecurityIssue` 回调抛给上层

---

## 核心工作流

### 1) 配置加载与应用

`STSecurityConfig.shared` 初始化时会从 Keychain 恢复配置，并调用 `st_applySecurityConfiguration()`：

- SSL Pinning 配置写入 `STHTTPSession.shared`
- 加密算法配置写入 `STCryptoService.shared`
- 根据反调试开关启动/关闭 `STAntiDebugMonitor`

### 2) 安全检测

`st_performSecurityCheck()` 会按当前配置检测：

- 系统代理环境
- 调试器附加状态
- Hook 框架路径
- 越狱/模拟器状态（依赖 `STDeviceInfo`）
- SSL Pinning 配置完整性

### 3) 风险上报

当 `STAntiDebugMonitor` 运行时，检测到风险会通过 `onSecurityIssue` 逐条回调给业务层，便于做日志记录、降级、拦截或告警。

---

## 推荐接入方式

### 启动阶段统一应用

```swift
import STBaseProject

func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
) -> Bool {
    STSecurityConfig.shared.st_applySecurityConfiguration()
    return true
}
```

### 配置安全策略

```swift
import STBaseProject

let encryption = STEncryptionConfig(
    enabled: true,
    algorithm: .aes256GCM,
    keyRotationInterval: 86_400,
    enableRequestSigning: true,
    enableResponseSigning: true
)
try STSecurityConfig.shared.st_saveEncryptionConfig(encryption)
```

### 注册安全事件回调

```swift
import STBaseProject

STSecurityConfig.shared.onSecurityIssue = { issue in
    print("Security issue: \(issue.rawValue), severity: \(issue.severity.rawValue)")
}
```

---

## 适用场景

- 登录态 Token、设备密钥等敏感信息安全存储
- 接口请求签名、防篡改校验
- 高安全业务（支付、账户、风控）运行环境风险检测
- 企业内网或监管场景下的证书绑定策略强化

---

## 风险与注意事项

- 不要在业务代码中重复实现加密或 Keychain 底层逻辑，避免策略分叉。
- `STEncryptionConfig` 和 `STAntiDebugConfig` 字段目前为模块内部可读，业务若需读取详情，建议通过 `STSecurityConfig` Getter 方法访问。
- 开启反调试/反篡改后，建议同步制定“误报处理策略”（如灰度开关、告警分级、兜底降级）。
- 算法切换前需确认历史密文兼容策略，避免旧数据不可解密。
- 安全策略放宽应通过配置开关控制，并明确默认值与回滚路径。

---

## 对外能力清单（按职责）

- 配置与应用：`STSecurityConfig`
- 加密与签名：`STCryptoService`、`STEncrypt`
- 安全存储：`STKeychainHelper`
- 反调试监控：`STAntiDebugMonitor`
- 模型与错误：`STSecurityModels`

如需网络层安全配置细节（证书绑定策略、会话联动），可结合查看 `Docs/STHTTPSession.md`。
