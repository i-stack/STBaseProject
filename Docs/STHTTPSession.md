# STHTTPSession 使用文档

`STHTTPSession` 是 `STBaseProject` 内置的网络层，基于 `URLSession`，参考 Alamofire 的 API 形态封装。支持链式调用、`async/await`、拦截器（adapter + retrier）、事件监听、SSL Pinning、断点续传、流式响应（SSE / chunked）、cURL 日志等。

---

## 目录

- [架构总览](#架构总览)
- [快速上手](#快速上手)
- [Session 配置](#session-配置)
- [请求配置 STRequestConfig](#请求配置-strequestconfig)
- [请求头 STRequestHeaders](#请求头-strequestheaders)
- [数据请求](#数据请求)
- [文件上传](#文件上传)
- [文件下载（含断点续传）](#文件下载含断点续传)
- [流式响应（SSE / NDJSON）](#流式响应sse--ndjson)
- [拦截器（Interceptor）](#拦截器interceptor)
- [事件监听 STEventMonitor](#事件监听-steventmonitor)
- [接口日志 / cURL 输出](#接口日志--curl-输出)
- [SSL Pinning](#ssl-pinning)
- [错误类型 STHTTPError](#错误类型-sthttperror)
- [常见配方](#常见配方)

---

## 架构总览

```
┌───────────────────────────────────────────────────────────────┐
│                       STHTTPSession                           │
│  - URLSession + URLSessionDelegate（pinning / 进度 / 完成）   │
│  - 拦截器（Adapter + Retrier）                                │
│  - 事件监听（STEventMonitor）                                 │
│  - 请求登记表（taskID → STRequest / TaskContext）             │
└───────────────────────────────────────────────────────────────┘
            │ 创建并返回
            ▼
   ┌──────────────────────────────────────────────────────┐
   │  STRequest（基类，状态机：initialized/resumed/...）   │
   │   ├── STDataRequest        响应链式 / async          │
   │   ├── STUploadRequest      multipart + 进度          │
   │   ├── STDownloadRequest    断点续传 + 进度           │
   │   └── STDataStreamRequest  SSE / chunked / Async流   │
   └──────────────────────────────────────────────────────┘
```

请求与 Session 是独立对象：你拿到的 `STDataRequest` 等可以单独 `cancel()` / `suspend()` / `resume()`，挂多份回调，或转成 `async` 序列消费。

---

## 快速上手

```swift
// 1. 链式调用
STHTTPSession.shared.request("https://api.example.com/users")
    .responseDecodable(of: [User].self) { result in
        switch result {
        case .success(let users): print(users)
        case .failure(let error): print(error)
        }
    }

// 2. async/await
let users = try await STHTTPSession.shared
    .request("https://api.example.com/users")
    .serializingDecodable([User].self)
```

---

## Session 配置

`STHTTPSession` 提供单例 `shared`，也可以自建。所有参数都有默认值：

```swift
let session = STHTTPSession(
    configuration: .default,
    defaultRequestConfig: STRequestConfig(timeoutInterval: 15, retryCount: 2),
    defaultRequestHeaders: {
        var h = STRequestHeaders()
        h.st_setUserAgent("MyApp/1.0")
        return h
    }(),
    interceptor: nil,                               // 全局拦截器
    eventMonitors: [STConsoleEventMonitor.default], // 事件监听
    sslPinningConfig: STSSLPinningConfig(enabled: false)
)
```

| 参数 | 作用 |
|---|---|
| `configuration` | 透传给 `URLSession` 的 `URLSessionConfiguration` |
| `defaultRequestConfig` | 没有显式传 `requestConfig` 时使用 |
| `defaultRequestHeaders` | 没有显式传 `headers` 时使用 |
| `interceptor` | 全局 adapter + retrier；可被请求级别 interceptor 覆盖 |
| `eventMonitors` | 多个监听器，自动并发派发 |
| `sslPinningConfig` | 启用后会接管 server trust 评估 |

> 单元测试场景建议每个测试用例用一个新 `STHTTPSession` 实例，避免共享 `.shared` 的拦截器状态。

---

## 请求配置 STRequestConfig

```swift
public struct STRequestConfig {
    var retryCount: Int = 0           // 重试次数（兜底，未传 interceptor 时生效）
    var retryDelay: TimeInterval = 1  // 兜底重试间隔
    var allowsCellularAccess: Bool = true
    var httpShouldHandleCookies: Bool = true
    var httpShouldUsePipelining: Bool = true
    var timeoutInterval: TimeInterval = 30
    var cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy
    var networkServiceType: URLRequest.NetworkServiceType = .default
    var showLoading: Bool = true      // 给 STBaseViewModel 用
    var showError: Bool = true        // 给 STBaseViewModel 用
    var enableEncryption: Bool = false
    var encryptionKey: String?
    var enableRequestSigning: Bool = false
    var signingSecret: String?
}
```

可单独传给某次请求覆盖默认：

```swift
let cfg = STRequestConfig(retryCount: 3, timeoutInterval: 10)
session.request("...", requestConfig: cfg).response { _ in }
```

---

## 请求头 STRequestHeaders

```swift
var headers = STRequestHeaders()
headers.st_setHeader("zh-CN", forKey: "Accept-Language")
headers.st_setContentType("application/json")
headers.st_setAuthorization("eyJhbGc...", type: .bearer)
// type 可选：.bearer / .basic / .custom("Token") / .tokenOnly
```

---

## 数据请求

```swift
let req: STDataRequest = STHTTPSession.shared.request(
    "https://api.example.com/v1/items",
    method: .post,
    parameters: ["name": "x", "qty": 3],
    encoding: .json,                  // .url / .json / .formData / .multipart
    headers: nil,                     // 不传则用 defaultRequestHeaders
    interceptor: nil,                 // 请求级别拦截器
    requestConfig: nil                // 请求级别配置
)

// 多种序列化
req.responseData    { result in /* Result<Data,  Error> */ }
req.responseString  { result in /* Result<String,Error> */ }
req.responseDecodable(of: ItemDTO.self) { result in /* Result<Item, Error> */ }

// async
let items = try await req.serializingDecodable([Item].self)

// 取消
req.cancel()
```

支持 `queue:` 参数指定回调线程，默认 `.main`。

---

## 文件上传

```swift
let file = STUploadFile(
    data: imageData,
    name: "avatar",                 // 服务器字段名
    fileName: "avatar.jpg",
    mimeType: "image/jpeg"
)
STHTTPSession.shared.upload(
    "https://api.example.com/upload",
    files: [file],
    parameters: ["uid": "123"]
)
.uploadProgress { p in
    print("\(Int(p.progress * 100))%")
}
.responseDecodable(of: UploadResp.self) { result in
    print(result)
}
```

---

## 文件下载（含断点续传）

```swift
let dst = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    .appendingPathComponent("big.zip")

// 1) 启动下载
let req = STHTTPSession.shared.download("https://.../big.zip", to: dst)
    .downloadProgress { p in print("\(p.fractionCompleted)") }
    .response { result in print(result) }

// 2) 用户暂停 — 拿 resumeData 持久化
req.cancel(byProducingResumeData: { data in
    UserDefaults.standard.set(data, forKey: "pause.bigzip")
})

// 3) 稍后恢复
let saved = UserDefaults.standard.data(forKey: "pause.bigzip")
STHTTPSession.shared.download("https://.../big.zip", to: dst, resumeData: saved)
    .response { result in print(result) }
```

**自动续传**：如果设置了 `requestConfig.retryCount > 0` 或全局拦截器允许重试，下载失败时 `URLSession` 携带的 `NSURLSessionDownloadTaskResumeData` 会自动写入 `STDownloadRequest.resumeData`，下一次重试自动用 `downloadTask(withResumeData:)` 续传。

下载选项：
```swift
let opts = STDownloadOptions(
    createIntermediateDirectories: true,  // 不存在时自动创建父目录
    removePreviousFile: true              // 目标已存在时先删除
)
session.download("...", to: dst, options: opts)
```

---

## 流式响应（SSE / NDJSON）

`stream(...)` 返回 `STDataStreamRequest`，**不缓冲**整段响应，逐 chunk 透传给上层。

```swift
// A) chunk 回调（适合 NDJSON / 自定义协议）
STHTTPSession.shared.stream("https://api.example.com/ndjson")
    .onData { chunk in /* 自行按 \n 切行 */ }
    .onComplete { error in /* nil 表示正常结束 */ }

// B) SSE 事件回调（自动按 \n\n 分帧 + id/event/data/retry 解析）
var headers = STRequestHeaders()
headers.st_setAccept("text/event-stream")
STHTTPSession.shared.stream("https://api.example.com/sse", headers: headers)
    .onEvent { ev in print("\(ev.event ?? ""): \(ev.data)") }
    .onComplete { _ in }

// C) async — 字节流
for try await chunk in STHTTPSession.shared.stream("https://...").bytes() {
    // ...
}

// D) async — SSE 事件流
for try await ev in STHTTPSession.shared.stream("https://.../sse").events() {
    print(ev.data)
}
```

**重试约束**：流式请求一旦收到首字节就不会再被自动重试（已经吐出去的 chunk 无法回滚）。首字节之前的失败仍走拦截器正常重试。

`STServerSentEvent`：`id` / `event` / `data`（多行 data 用 `\n` 拼接）/ `retry`，`:` 注释行会被忽略，`\r\n` 与 `\n` 行尾都支持。

---

## 拦截器（Interceptor）

`STInterceptor = STRequestAdapter + STRequestRetrier`，可同时承担请求改写（鉴权头）和失败重试（指数退避 / token 刷新）。

### Adapter — 请求改写

```swift
struct UserAgentAdapter: STRequestAdapter {
    func adapt(_ urlRequest: URLRequest, for session: STHTTPSession) async throws -> URLRequest {
        var r = urlRequest
        r.setValue("MyApp/1.0", forHTTPHeaderField: "User-Agent")
        return r
    }
}
```

### Retry Policy — 指数退避

```swift
let policy = STRetryPolicy(
    retryLimit: 2,
    exponentialBackoffBase: 2,
    exponentialBackoffScale: 0.5,
    retryableHTTPMethods: [.get, .head, .put, .delete, .options, .trace],
    retryableHTTPStatusCodes: [408, 500, 502, 503, 504]
)
```

### 鉴权刷新（401 → 刷 token → 重试）

`STAuthInterceptor` 会处理并发 401 风暴：第一个失败请求触发 token 刷新，其它请求挂起等同一份新 token。

```swift
let auth = STAuthInterceptor(
    headerKey: "Authorization",
    headerPrefix: "Bearer",
    tokenProvider: { try await TokenStore.current() },
    tokenRefresher: { try await TokenStore.refresh() }
)
let session = STHTTPSession(interceptor: auth)
```

> `interceptor` 既可挂在 `STHTTPSession` 上做全局，也可挂在 `request(_:interceptor:)` 上做单次覆盖。

### 自定义合成

```swift
final class MyInterceptor: STInterceptor {
    func adapt(_ urlRequest: URLRequest, for session: STHTTPSession) async throws -> URLRequest {
        var r = urlRequest
        r.setValue("X", forHTTPHeaderField: "X-Trace-Id")
        return r
    }
    func retry(_ request: STRequest, for session: STHTTPSession, dueTo error: Error) async -> STRetryResult {
        // .retry / .retryWithDelay(N) / .doNotRetry / .doNotRetryWithError(e)
        return .doNotRetry
    }
}
```

---

## 事件监听 STEventMonitor

事件监听是只读的旁路通道，适合做埋点 / 控制台日志 / 网络面板。

```swift
public protocol STEventMonitor: AnyObject {
    func requestDidResume(_ request: STRequest)
    func requestDidSuspend(_ request: STRequest)
    func requestDidCancel(_ request: STRequest)
    func requestDidFinish(_ request: STRequest)
    func requestDidTransition(_ request: STRequest, from: STRequestState, to: STRequestState)
    func request(_ request: STRequest, didCreateURLRequest urlRequest: URLRequest)
    func request(_ request: STRequest, didAdaptURLRequest initial: URLRequest, to adapted: URLRequest)
    func request(_ request: STRequest, didReceiveHTTPResponse response: HTTPURLResponse)
    func request(_ request: STDataRequest, didReceiveData data: Data)
    func request(_ request: STUploadRequest, didSendBytes ...)
    func request(_ request: STDownloadRequest, didWriteData ...)
}
```

内置 `STConsoleEventMonitor.default`（控制台简易日志）和 `STCompositeEventMonitor`（聚合多个监听器，每个监听器在自己的 `queue` 上派发）。

---

## 接口日志 / cURL 输出

`STHTTPSession` 内置基于 `STPersistentLog` 的 cURL 输出。每次请求 / 完成会落盘一条结构化日志。

```swift
// 启用（建议在 App 启动时设置）
STHTTPSession.shared.logging = .default     // verbosity = .body
// 关闭（默认）
STHTTPSession.shared.logging = .off
```

### `STHTTPLogConfig`

| 字段 | 默认 | 说明 |
|---|---|---|
| `verbosity` | `.off` | `.off / .basic / .headers / .body`（逐级递增） |
| `maxBodyLength` | 4096 | 单条日志中 body 最大字节，超出截断 |
| `redactedHeaders` | `[]` | 脱敏字段名（值替换为 `***`），**默认空 — 可直接复制 cURL 到终端复现** |
| `logResponseBodyOnSuccess` | `false` | 成功响应是否打印 body（默认仅失败打 body） |

### 日志级别

- 请求阶段（cURL 行）：`STLogLevel.debug`
- 完成阶段：成功 `.info`，失败 `.error`
- `STPersistentLog` 在 DEBUG 下会同时输出到控制台，并始终落盘

### 输出示例（`.body`）

请求：
```
$ curl -v \
    -X POST \
    -H "Authorization: Bearer eyJhbGc..." \
    -H "Content-Type: application/json" \
    -d "{\"id\":42}" \
    "https://api.example.com/v1/items"
```

成功完成：
```
← [200] POST https://api.example.com/v1/items
```

失败（自动 `.error`、自动截断 body）：
```
← [500] POST https://api.example.com/v1/items
  error: Server error: 500
  body: {"code":"INTERNAL","trace":"abc..."}
```

### 仅手动取 cURL

```swift
let curl = req.urlRequest!.st_cURLDescription(redactedHeaders: ["Authorization"])
```

> **响应体落盘建议**：默认 `logResponseBodyOnSuccess = false`，避免 PII / 容量问题。失败响应自动截断后落盘，定位足够。线上需要的话可在灰度环境单独打开。

---

## SSL Pinning

```swift
let config = STSSLPinningConfig(
    enabled: true,
    certificates: [certData1, certData2],  // 多张证书构成 trust chain
    publicKeyHashes: [],                    // 暂未启用
    validateHost: true,                     // 校验 host 名称
    allowInvalidCertificates: false         // 调试时可设 true
)
let session = STHTTPSession(sslPinningConfig: config)
```

校验顺序：

1. `enabled = false` → 走系统默认。
2. `allowInvalidCertificates = true` → 直接信任。
3. 启用 host 校验 + `SecTrustEvaluateWithError`。
4. 比对 server trust 链中的证书 DER 是否在 `certificates` 集合内（任一命中即放行，否则取消挑战）。

> iOS 15+ 用 `SecTrustCopyCertificateChain`，旧系统回退到 `SecTrustGetCertificateAtIndex`。

---

## 错误类型 STHTTPError

```swift
enum STHTTPError: Error {
    case invalidURL
    case noData
    case decodingError
    case networkError(Error)   // 包装系统错误
    case serverError(Int)      // statusCode >= 400
    case timeout               // NSURLErrorTimedOut
    case cancelled             // NSURLErrorCancelled
}
```

`STHTTPSession` 内部统一把 `URLSession` 的 `NSError` 归一化成 `STHTTPError`，再交给 retrier / response 链路。

---

## 常见配方

### 全局开启埋点 + 仅在 DEBUG 打 cURL

```swift
let monitors: [STEventMonitor] = [MyAnalyticsMonitor()]
let session = STHTTPSession(eventMonitors: monitors)
#if DEBUG
session.logging = .default
#endif
```

### 给某次请求单独打开重试

```swift
let cfg = STRequestConfig(retryCount: 3, retryDelay: 1)
session.request("...", requestConfig: cfg).response { _ in }
```

### 给某次请求单独换鉴权

```swift
let perRequestAuth = STAuthInterceptor(
    tokenProvider: { try await OtherTokenStore.current() },
    tokenRefresher: { try await OtherTokenStore.refresh() }
)
session.request("...", interceptor: perRequestAuth).response { _ in }
```

### Combine / RxSwift

直接在 `response { ... }` 里 forward 到 subject 即可；本库不强绑定响应式框架。
