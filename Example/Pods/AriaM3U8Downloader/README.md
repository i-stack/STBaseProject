# AriaM3U8Downloader
A Swift M3U8 Downloader
# Requirements
- iOS 11.0
- Swift 5.0
# Installation
```
pod 'AriaM3U8Downloader', :git => 'https://github.com/moxcomic/AriaM3U8Downloader.git'

// 如果需要播放请添加这个Pod
// 或者自己解决本地播放问题
pod 'AriaM3U8Downloader/LocalServer', :git => 'https://github.com/moxcomic/AriaM3U8Downloader.git'
```
# Usage
## Swift
```
import AriaM3U8Downloader

let downloader = AriaM3U8Downloader(withURLString: "https://xxx.m3u8", outputPath: "存放路径")
downloader.start()
```
## 回调方法 & 设置项
- downloadTSSuccessExeBlock
    - 下载每个TS文件完成的回调, 返回TS文件名
- downloadFileProgressExeBlock
    - 下载进度回调, 返回Float
- downloadStartExeBlock
    - 下载开始回调
- downloadPausedExeBlock
    - 下载暂停回调
- downloadResumeExeBlock
    - 下载恢复回调
- downloadStopExeBlock
    - 下载停止回调
- downloadTSFailureExeBlock
    - 下载TS文件失败回调, 返回TS文件名
- downloadCompleteExeBlock
    - 所有TS文件下载完成, 并且已创建index.m3u8文件
- downloadM3U8StatusExeBlock
    - 下载状态回调, 返回 Int: 当前下载, Int: 文件总数
- downloadDidEnterBackgroundExeBlock
    - App进入后台回调
- downloadDidBecomeActiveExeBlock
    - App进入前台回调
- downloadStatus
    - isNotReadyToDownload -> 未完成下载准备
    - isReadyToDownload -> 完成下载准备
    - isStart -> 开始下载
    - isPause -> 暂停下载
    - isStop -> 停止下载
    - isDownloading -> 下载中
    - isComplete -> 下载完成
- maxConcurrentOperationCount
    - 同时最大下载TS文件数量, Int 默认为 3
- autoPauseWhenAppDidEnterBackground
    - App进入后台是否暂停下载, 默认为 True, 如果需要请设置为 False 并自行实现后台下载
# OC
```
具体未测试, 理论支持
```