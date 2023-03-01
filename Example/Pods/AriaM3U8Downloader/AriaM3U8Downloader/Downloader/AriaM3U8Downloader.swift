//
//  AriaM3U8Downloader.swift
//  AriaM3U8Downloader
//
//  Created by 神崎H亚里亚 on 2019/11/28.
//  Copyright © 2019 moxcomic. All rights reserved.
//

import UIKit
import RxSwift
import RxDataSources
import Alamofire
import RxAlamofire
import NSObject_Rx

public class AriaM3U8Downloader: NSObject {
    fileprivate let queue : OperationQueue = {
        let que = OperationQueue()
        que.maxConcurrentOperationCount = 3
        return que
    }()
    
    fileprivate var tag: Int = 0
    
    /// M3U8 URL
    fileprivate var M3U8_URL: URL!
    /// 下载输出路径
    fileprivate var OUTPUT_PATH: URL!
    /// M3U8 下载模型
    fileprivate var M3U8_Entity: M3U8Entity!
    /// 正确的 URL 前缀
    fileprivate var TRUE_Prefix: URL!
    
    /// 最大同时下载数量
    @objc open var maxConcurrentOperationCount = 3 { didSet { queue.maxConcurrentOperationCount = maxConcurrentOperationCount } }
    
    /// App进入后台是否暂停下载, 进入前台时恢复下载
    /// 默认为 True , 如果需要请设置为 False 并自行实现后台下载
    @objc open var autoPauseWhenAppDidEnterBackground = true
    
    /// 当前下载状态
    /// isNotReadyToDownload -> 未完成准备下载
    /// isReadyToDownload -> 完成下载准备
    /// isStart -> 开始下载
    /// isPause -> 暂停下载
    /// isStop -> 停止下载
    /// isDownloading -> 下载中
    /// isComplete -> 下载完成
    @objc open fileprivate(set) var downloadStatus: AriaDownloadStatus = .isNotReadyToDownload
    
    /// 下载TS文件完成回调
    /// return -> String: TS文件名
    @objc open var downloadTSSuccessExeBlock: ((String) -> ())?
    /// 下载TS文件进度回调
    /// return -> Float: 当前Downloader下载总进度
    @objc open var downloadFileProgressExeBlock: ((Float) -> ())?
    /// 下载开始回调
    /// return -> Void
    @objc open var downloadStartExeBlock: (() -> ())?
    /// 下载暂停回调
    /// return -> Void
    @objc open var downloadPausedExeBlock: (() -> ())?
    /// 下载恢复回调
    /// return -> Void
    @objc open var downloadResumeExeBlock: (() -> ())?
    /// 下载停止回调
    /// return > Void
    @objc open var downloadStopExeBlock: (() -> ())?
    /// 下载TS文件失败回调
    /// return -> TS FileName
    @objc open var downloadTSFailureExeBlock: ((String) -> ())?
    /// 下载完成回调
    /// return -> Void
    @objc open var downloadCompleteExeBlock: (() -> ())?
    /// 下载状态回调
    /// return -> Int: 当前下载, Int: 文件总数
    @objc open var downloadM3U8StatusExeBlock: ((Int, Int) -> ())?
    
    /// App进入后台回调
    /// return -> Void
    @objc open var downloadDidEnterBackgroundExeBlock: (() -> ())?
    /// App进入前台回调
    /// return -> Void
    @objc open var downloadDidBecomeActiveExeBlock: (() -> ())?
}

// MARK: - Notification
extension AriaM3U8Downloader {
    fileprivate func registerNotifications() {
        NotificationCenter.default.rx.notification(custom: .DownloadTSSuccessNotification, tag: tag).takeUntil(self.rx.deallocated).subscribe() {
            #if DEBUG
            print("-- RECEIVE DOWNLOAD TS SUCCESS NOTIFICATION --")
            #endif
            self.downloadTSSuccessExeBlock?("\($0.element?.object ?? "")")
        }.disposed(by: rx.disposeBag)
        
        NotificationCenter.default.rx.notification(custom: .DownloadM3U8ProgressNotification, tag: tag).takeUntil(self.rx.deallocated).subscribe() {
            #if DEBUG
            print("-- RECEIVE DOWNLOAD PROGRESS NOTIFICATION --")
            #endif
            self.downloadFileProgressExeBlock?(Float("\($0.element?.object ?? 0.0)")!)
        }.disposed(by: rx.disposeBag)
        
        NotificationCenter.default.rx.notification(custom: .DownloadM3U8StartNotification, tag: tag).takeUntil(self.rx.deallocated).subscribe() {
            #if DEBUG
            print("-- RECEIVE DOWNLOAD START NOTIFICATION --")
            print($0)
            #endif
            self.downloadStartExeBlock?()
        }.disposed(by: rx.disposeBag)
        
        NotificationCenter.default.rx.notification(custom: .DownloadM3U8PausedNotification, tag: tag).takeUntil(self.rx.deallocated).subscribe() {
            #if DEBUG
            print("-- RECEIVE DOWNLOAD PAUSE NOTIFICATION --")
            print($0)
            #endif
            self.downloadPausedExeBlock?()
        }.disposed(by: rx.disposeBag)
        
        NotificationCenter.default.rx.notification(custom: .DownloadM3U8ResumeNotification, tag: tag).takeUntil(self.rx.deallocated).subscribe() {
            #if DEBUG
            print("-- RECEIVE DOWNLOAD RESUME NOTIFICATION --")
            print($0)
            #endif
            self.downloadResumeExeBlock?()
        }.disposed(by: rx.disposeBag)
        
        NotificationCenter.default.rx.notification(custom: .DownloadM3U8StopNotification, tag: tag).takeUntil(self.rx.deallocated).subscribe() {
            #if DEBUG
            print("-- RECEIVE DOWNLOAD STOP NOTIFICATION --")
            print($0)
            #endif
            self.downloadStopExeBlock?()
        }.disposed(by: rx.disposeBag)
        
        NotificationCenter.default.rx.notification(custom: .DownloadM3U8CompleteNotification, tag: tag).takeUntil(self.rx.deallocated).subscribe() {
            #if DEBUG
            print("-- RECEIVE DOWNLOAD COMPLETE NOTIFICATION --")
            print($0)
            #endif
            self.downloadCompleteExeBlock?()
        }.disposed(by: rx.disposeBag)
        
        NotificationCenter.default.rx.notification(custom: .DownloadTSFailureNotification, tag: tag).takeUntil(self.rx.deallocated).subscribe() {
            #if DEBUG
            print("-- RECEIVE DOWNLOAD FAILURE NOTIFICATION --")
            #endif
            self.downloadTSFailureExeBlock?("\($0.element?.object ?? "")")
        }.disposed(by: rx.disposeBag)
        
        NotificationCenter.default.rx.notification(custom: .DownloadM3U8StatusNotification, tag: tag).takeUntil(self.rx.deallocated).subscribe() {
            #if DEBUG
            print("-- RECEIVE DOWNLOAD STATUS NOTIFICATION --")
            #endif
            guard let obj = $0.element?.object as? [Int] else { return }
            if obj.count != 2 { return }
            self.downloadM3U8StatusExeBlock?(obj[0], obj[1])
        }.disposed(by: rx.disposeBag)
        
        NotificationCenter.default.rx.notification(UIApplication.didEnterBackgroundNotification).takeUntil(self.rx.deallocated).subscribe() {
            #if DEBUG
            print("-- RECEIVE APP ENTER BACKGROUND NOTIFICATION --")
            print($0)
            #endif
            if self.autoPauseWhenAppDidEnterBackground { self.pause() }
            self.downloadDidEnterBackgroundExeBlock?()
        }.disposed(by: rx.disposeBag)
        
        NotificationCenter.default.rx.notification(UIApplication.didBecomeActiveNotification).takeUntil(self.rx.deallocated).subscribe() {
            #if DEBUG
            print("-- RECEIVE APP BECOME ACTIVE NOTIFICATION --")
            print($0)
            #endif
            if self.autoPauseWhenAppDidEnterBackground { self.resume() }
            self.downloadDidBecomeActiveExeBlock?()
        }.disposed(by: rx.disposeBag)
    }
}

// MARK: - 创建播放文件
extension AriaM3U8Downloader {
    /// 创建临时M3U8文件,用于未下载完成时播放
    @objc
    public func createTempLocalM3U8File() {
        let opCount = self.queue.operations.count
        let dCount = self.M3U8_Entity.TSDATA.count - opCount
        createLocalM3U8File(withTSCount: dCount)
    }
    
    /// 创建播放文件
    /// 文件名默认为 index.m3u8 不可修改
    /// - Parameter count: 需要添加的TS文件数量, -1 为全部添加
    @objc
    public func createLocalM3U8File(withTSCount count: Int = -1) {
        let totalCount = (count == -1 ? M3U8_Entity.TSDATA.count : count)
        
        let m3u8File = OUTPUT_PATH.appendingPathComponent("index.m3u8")
        
        var header =
        """
        #EXTM3U
        #EXT-X-VERSION:3
        #EXT-X-TARGETDURATION:60\n
        """
        if M3U8_Entity.EXT_X_KEY != nil { header.append("\n#EXT-X-KEY:METHOD=\(M3U8_Entity.METHOD!),URI=\"\(M3U8_Entity.EXT_X_KEY!)\"\(M3U8_Entity.EXT_X_IV == nil ? "" : ",IV=\(M3U8_Entity.EXT_X_IV!)")\n") }
        for i in 0..<totalCount {
            header.append("#EXTINF:\(M3U8_Entity.INFDATA[i]),\n\(M3U8_Entity.TSDATA[i])\n")
        }
        
        header.append("#EXT-X-ENDLIST")
        
        guard let data = header.data(using: .utf8) else { return }
        try? data.write(to: m3u8File)
    }
}

// MARK: - Open Func
extension AriaM3U8Downloader {
    /// 开始下载任务
    @objc
    public func start() {
        if M3U8_URL == nil {
            #if DEBUG
            print("M3U8 地址不正确,无法开始任务")
            #endif
            return
        }
        getClip().subscribe(onNext: { (entity) in
            NotificationCenter.post(customeNotification: .DownloadM3U8StartNotification, tag: self.tag)
            self.M3U8_Entity = entity
            if entity.EXT_X_KEY != nil { self.downloadKey() }
            self.downloadTS()
            self.downloadStatus = .isDownloading
        }, onError: { (error) in
            #if DEBUG
            print(error.localizedDescription)
            #endif
        }).disposed(by: rx.disposeBag)
    }
    
    /// 暂停下载任务
    @objc
    public func pause() {
        queue.isSuspended = true
        self.downloadStatus = .isPause
        NotificationCenter.post(customeNotification: .DownloadM3U8PausedNotification, tag: tag)
    }
    
    /// 恢复下载任务
    @objc
    public func resume() {
        if queue.operations.count > 0 { downloadStatus = .isDownloading }
        else { downloadStatus = .isComplete }
        queue.isSuspended = false
        NotificationCenter.post(customeNotification: .DownloadM3U8ResumeNotification, tag: tag)
    }
    
    /// 停止下载任务
    @objc
    public func stop() {
        downloadStatus = .isStop
        queue.cancelAllOperations()
        NotificationCenter.post(customeNotification: .DownloadM3U8StopNotification, tag: tag)
    }
}

// MARK: - 下载
extension AriaM3U8Downloader {
    fileprivate func downloadKey() {
        let semaphore = DispatchSemaphore(value: 0)
        queue.addOperation {
            let url = self.M3U8_Entity.EXT_X_KEY.hasPrefix("http") ? self.M3U8_Entity.EXT_X_KEY! : (self.TRUE_Prefix.appendingPathComponent(self.M3U8_Entity.EXT_X_KEY.hasPrefix("/") ? self.M3U8_Entity.EXT_X_KEY : "/\(self.M3U8_Entity.EXT_X_KEY!)")).path
            AriaBackgroundManager.shared.manager.download(url) { (url, response) -> (destinationURL: URL, options: DownloadRequest.DownloadOptions) in
                guard let output = self.OUTPUT_PATH else { return (FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0], []) }
                let fileURL = output.appendingPathComponent(response.suggestedFilename!)
                return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
            }.downloadProgress { (progress) in
                
            }.responseData { (response) in
                switch response.result {
                case .success(_):
                    #if DEBUG
                    print("\(self.M3U8_URL.absoluteString):\nKEY ->\(url): ->\n下载完成")
                    #endif
                case .failure(_):
                    #if DEBUG
                    print("\(self.M3U8_URL.absoluteString):\nKEY ->\(url): ->\n下载失败")
                    #endif
                    NotificationCenter.post(customeNotification: .DownloadTSFailureNotification, tag: self.tag, object: "key.key")
                }
                semaphore.signal()
            }
            semaphore.wait()
        }
    }
    
    fileprivate func downloadTS() {
        for ts in M3U8_Entity.TSDATA {
            let lastName = ts.components(separatedBy: "/").last!
            let fv = OUTPUT_PATH.appendingPathComponent(OUTPUT_PATH.path.hasSuffix("/") ? lastName : "/\(lastName)")
            if FileManager.default.fileExists(atPath: fv.path) {
                #if DEBUG
                print("\(ts): 文件已存在,跳过下载")
                NotificationCenter.post(customeNotification: .DownloadTSSuccessNotification, tag: tag, object: ts)
                #endif
                continue
            }
            let semaphore = DispatchSemaphore(value: 0)
            queue.addOperation {
                let url = self.TRUE_Prefix.appendingPathComponent(ts.hasPrefix("/") ? ts : "/\(ts)")
                AriaBackgroundManager.shared.manager.download(url) { (url, response) -> (destinationURL: URL, options: DownloadRequest.DownloadOptions) in
                    guard let output = self.OUTPUT_PATH else { return (FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0], []) }
                    let fileURL = output.appendingPathComponent(response.suggestedFilename!)
                    return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
                }.downloadProgress(closure: { (progress) in

                }).responseData { (response) in
                    switch response.result {
                    case .success(_):
                        #if DEBUG
                        print("\(self.M3U8_URL.absoluteString):\nTS ->\(url): ->\n下载完成")
                        #endif
                        NotificationCenter.post(customeNotification: .DownloadTSSuccessNotification, tag: self.tag, object: ts)
                    case .failure(_):
                        #if DEBUG
                        print("\(self.M3U8_URL.absoluteString):\nTS ->\(url): ->\n下载失败")
                        #endif
                        self.M3U8_Entity.FAILURE_TSDATA.append(ts)
                        NotificationCenter.post(customeNotification: .DownloadTSFailureNotification, tag: self.tag, object: ts)
                    }
                    #if DEBUG
                    print("queque count:\(self.queue.operations.count)")
                    #endif
                    if self.downloadStatus != .isStop {
                        let opCount = self.queue.operations.count
                        let dCount = self.M3U8_Entity.TSDATA.count - opCount
                        NotificationCenter.post(customeNotification: .DownloadM3U8ProgressNotification, tag: self.tag, object: Float(Float(dCount) / Float(self.M3U8_Entity.TSDATA.count)))
                    }
                    semaphore.signal()
                }
                semaphore.wait()
                if self.downloadStatus != .isStop {
                    let opCount = self.queue.operations.count
                    let dCount = self.M3U8_Entity.TSDATA.count - opCount
                    NotificationCenter.post(customeNotification: .DownloadM3U8StatusNotification, tag: self.tag, object: [dCount, self.M3U8_Entity.TSDATA.count])
                }
            }
        }
        DispatchQueue.global().async {
            self.queue.waitUntilAllOperationsAreFinished()
            if self.downloadStatus != .isStop {
                NotificationCenter.post(customeNotification: .DownloadM3U8StatusNotification, tag: self.tag, object: [self.M3U8_Entity.TSDATA.count, self.M3U8_Entity.TSDATA.count])
                if self.queue.operations.count == 0 {
                    self.createLocalM3U8File()
                    self.downloadStatus = .isComplete
                    NotificationCenter.post(customeNotification: .DownloadM3U8ProgressNotification, tag: self.tag, object: 1.0)
                    NotificationCenter.post(customeNotification: .DownloadM3U8CompleteNotification, tag: self.tag)
                }
            }
        }
    }
}

// MARK: - 获取切片
extension AriaM3U8Downloader {
    fileprivate func getClip() -> Observable<M3U8Entity> {
        return Observable.create { (obs) -> Disposable in
            requestString(.get, self.M3U8_URL).subscribe(onNext: { (response, str) in
                let splitRS = str.components(separatedBy: "\n")
                // 双层, 再次进行拆包
                if str.contains("#EXT-X-STREAM-INF") {
                    let m3u8 = splitRS.filter { $0.hasSuffix(".m3u8") }
                    if m3u8.count == 0 { obs.onError(baseError("\(self.M3U8_URL.absoluteString): -> \n获取 M3U8 切片失败 -> SECOND CLIP NOT FOUND")) }
                    else {
                        self.getSecondClip(m3u8[0]).subscribe(onNext: { (entity) in
                            obs.onNext(entity)
                            obs.onCompleted()
                        }, onError: { (error) in
                            obs.onError(error)
                        }).disposed(by: self.rx.disposeBag)
                    }
                } else {
                    self.analysisClips(splitRS: splitRS).subscribe(onNext: { (entity) in
                        self.getTruePrefix(clip: entity.TSDATA[0]).subscribe(onNext: { (_) in
                            obs.onNext(entity)
                            obs.onCompleted()
                        }, onError: { (error) in
                            obs.onError(error)
                        }).disposed(by: self.rx.disposeBag)
                    }, onError: { (error) in
                        obs.onError(error)
                    }).disposed(by: self.rx.disposeBag)
                }
            }, onError: { (error) in
                obs.onError(baseError("\(self.M3U8_URL.absoluteString): -> \n获取 M3U8 切片失败 -> 1"))
            }).disposed(by: self.rx.disposeBag)
            return Disposables.create()
        }
    }
    
    fileprivate func getSecondClip(_ secondM3U8: String) -> Observable<M3U8Entity> {
        return Observable.create { (obs) -> Disposable in
            self.getTruePrefix(clip: secondM3U8).subscribe(onNext: { (sec) in
                let url = self.TRUE_Prefix.appendingPathComponent(secondM3U8.hasPrefix("/") ? secondM3U8 : "/\(secondM3U8)")
                requestString(.get, url).subscribe(onNext: { (response, str) in
                    let splitRS = str.components(separatedBy: "\n")
                    self.analysisClips(splitRS: splitRS).subscribe(onNext: { (entity) in
                        if sec.hasSuffix(".m3u8") {
                            self.getTruePrefix(clip: entity.TSDATA[0], url: URL(string: sec)!).subscribe(onNext: { (_) in
                                obs.onNext(entity)
                                obs.onCompleted()
                            }, onError: { (error) in
                                obs.onError(baseError("\(self.M3U8_URL.absoluteString): -> \n获取 URL 切片失败 -> TRUE PREFIX NOT FOUND -> 2"))
                            }).disposed(by: self.rx.disposeBag)
                        }
                    }, onError: { (error) in
                        obs.onError(error)
                    }).disposed(by: self.rx.disposeBag)
                }, onError: { (error) in
                    obs.onError(baseError("\(self.M3U8_URL.absoluteString): -> \n获取 M3U8 切片失败 -> 2"))
                }).disposed(by: self.rx.disposeBag)
            }, onError: { (error) in
                obs.onError(error)
            }).disposed(by: self.rx.disposeBag)
            return Disposables.create()
        }
    }
    
    fileprivate func analysisClips(splitRS: [String]) -> Observable<M3U8Entity> {
        return Observable.create { (obs) -> Disposable in
            let entity = M3U8Entity()
            entity.M3U8_URL = self.M3U8_URL.absoluteString
            if self.TRUE_Prefix != nil { entity.TRUE_Prefix = self.TRUE_Prefix.absoluteString }
            entity.OUTPUT_PATH = self.OUTPUT_PATH.absoluteString
            for m in splitRS {
                if m.hasPrefix("#EXT-X-VERSION:") {
                    if let value = Int(m.replacingOccurrences(of: "#EXT-X-VERSION:", with: "")) { entity.EXT_X_VERSION = value }
                }
                
                if m.hasPrefix("#EXT-X-TARGETDURATION:") {
                    if let value = Int(m.replacingOccurrences(of: "#EXT-X-TARGETDURATION:", with: "")) { entity.EXT_X_TARGETDURATION = value }
                }
                
                if m.hasPrefix("#EXT-X-MEDIA-SEQUENCE:") {
                    if let value = Int(m.replacingOccurrences(of: "#EXT-X-MEDIA-SEQUENCE:", with: "")) { entity.EXT_X_MEDIA_SEQUENCE = value }
                }
                
                if m.hasPrefix("#EXT-X-PLAYLIST-TYPE:") {
                    entity.EXT_X_PLAYLIST_TYPE = m.replacingOccurrences(of: "#EXT-X-PLAYLIST-TYPE:", with: "")
                }
                
                if m.hasPrefix("#EXT-X-KEY:") {
                    let value = m.replacingOccurrences(of: "#EXT-X-KEY:", with: "")
                    var split = value.components(separatedBy: ",")
                    let method = split[0].components(separatedBy: "=")[1]
                    split.remove(at: 0)
                    let uri = split.joined(separator: "").components(separatedBy: "URI=\"")[1].components(separatedBy: "\"IV=")
                    entity.METHOD = method
                    entity.EXT_X_KEY = uri[0].hasPrefix("http") ? uri[0] : uri[0].components(separatedBy: "/").last!
                    if uri.count > 1 { entity.EXT_X_IV = uri[1] }
//                    for s in split {
//                        let ss = s.components(separatedBy: "=")
//                        if ss.count > 1 {
//                            switch ss[0] {
//                            case "METHOD": entity.METHOD = ss[1]
//                            case "URI":
//                                let uri = ss[1].replacingOccurrences(of: "\"", with: "")
//                                entity.EXT_X_KEY = uri.components(separatedBy: "/").last!
//                            default: continue
//                            }
//                        }
//                    }
                }
                
                if m.hasPrefix("#EXTINF:") {
                    if let value = Float(m.replacingOccurrences(of: "#EXTINF:", with: "").replacingOccurrences(of: ",", with: "")) { entity.INFDATA.append(value) }
                }
                
                if m.hasSuffix(".ts") { entity.TSDATA.append(m.components(separatedBy: "/").last!) }
            }
            
            if entity.TSDATA.count > 0 {
                obs.onNext(entity)
                obs.onCompleted()
            } else { obs.onError(baseError("获取M3U8内容失败")) }
            return Disposables.create()
        }
    }
    
    fileprivate func getTruePrefix(clip: String, url: URL? = nil) -> Observable<String> {
        return Observable.create { (obs) -> Disposable in
            if let urlClips = self.getURLClips(url: url) {
                for clipURL in urlClips {
                    let maybeRightURL = clipURL.appending(clip.hasPrefix("/") ? clip : "/\(clip)")
                    if let _ = try? Data(contentsOf: URL(string: maybeRightURL)!) {
                        #if DEBUG
                        print("correct downloadUrl = \(maybeRightURL)")
                        #endif
                        self.TRUE_Prefix = URL(string: clipURL)!
                        obs.onNext(maybeRightURL)
                        obs.onCompleted()
                    } else {
                        #if DEBUG
                        print("current download url is not correct.:\(maybeRightURL)")
                        #endif
                    }
                }
            } else { obs.onError(baseError("\(self.M3U8_URL.absoluteString): -> \n获取 URL 切片失败 -> TRUE PREFIX NOT FOUND -> 1")) }
            return Disposables.create()
        }
    }
    
    fileprivate func getURLClips(url: URL? = nil) -> [String]? {
        if M3U8_URL == nil {
            #if DEBUG
            print("无法获取URL切片")
            #endif
            return nil
        }
        let target = url ?? M3U8_URL
        let scheme = target!.scheme!
        let port = target!.port ?? -1
        let host = target!.host!
        let path = target!.path.components(separatedBy: "/").filter { !$0.isEmpty && !$0.hasSuffix(".m3u8") }
        var urlClips = [String]()
        urlClips.append("\(scheme)://\(host)\(port == -1 ? "" : ":\(port)")")
        for i in 0..<path.count {
            let p = path[0...i].joined(separator: "/")
            urlClips.append("\(scheme)://\(host)\(port == -1 ? "" : ":\(port)")/\(p)")
        }
        return urlClips
    }
}

// MARK: - Init
extension AriaM3U8Downloader {
    @objc
    public convenience init(withURLString urlString: String, outputPath: String, tag: Int = 0) {
        self.init()
        guard let m3u8 = URL(string: urlString) else {
            #if DEBUG
            print("M3U8 URL 地址不正确,请确认是否含有特殊字符")
            #endif
            return
        }
        let output = URL(fileURLWithPath: outputPath)
        M3U8_URL = m3u8
        OUTPUT_PATH = output
        self.tag = tag
        registerNotifications()
        downloadStatus = .isReadyToDownload
    }
}
