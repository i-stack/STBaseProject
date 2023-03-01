//
//  STLocalBusinessOperatorViewModel.swift
//  STBaseProject_Example
//
//  Created by song on 2023/2/27.
//  Copyright © 2023 STBaseProject. All rights reserved.
//

import UIKit
import Alamofire
import mobileffmpeg

// 本地商家运营师
class STLocalBusinessOperatorViewModel: NSObject {
    
    private var courseId: NSInteger = -1
    private var pageNo: NSInteger = 1
    private var pageSize: NSInteger = 20
    private let semaphore = DispatchSemaphore(value: 1)
    private let bookSemaphore = DispatchSemaphore(value: 1)
    private let bookSerialGroup = DispatchGroup()

    func numberOfSections() -> NSInteger {
        if let model = self.curriculumChaptersDataSources["\(self.courseId)"] {
            return model.data.list.count
        }
        return 0
    }
    
    func numberOfRowsInSection(section: Int) -> Int {
        if let model = self.curriculumChaptersDataSources["\(self.courseId)"] {
            if model.data.list.count > section {
                let chapterModel = model.data.list[section]
                return chapterModel.chaperInfo?.data.count ?? 0
            }
        }
        return 0
    }
    
    func titleForHeaderInSection(section: Int) -> String {
        if let model = self.curriculumChaptersDataSources["\(self.courseId)"] {
            if model.data.list.count > section {
                let chapterModel = model.data.list[section]
                return chapterModel.chapterName
            }
        }
        return ""
    }
    
    func cellForRowAt(indexPath: IndexPath) -> String {
        if let model = self.curriculumChaptersDataSources["\(self.courseId)"] {
            if model.data.list.count > indexPath.section {
                let chapterModel = model.data.list[indexPath.section]
                if chapterModel.chaperInfo?.data.count ?? 0 > indexPath.row {
                    let cellModel = chapterModel.chaperInfo?.data[indexPath.row]
                    return cellModel?.charterName ?? ""
                }
            }
        }
        return ""
    }
    
    func videoUrl(indexPath: IndexPath) -> String {
        if let model = self.curriculumChaptersDataSources["\(self.courseId)"] {
            if model.data.list.count > indexPath.section {
                let chapterModel = model.data.list[indexPath.section]
                if chapterModel.chaperInfo?.data.count ?? 0 > indexPath.row {
                    let cellModel = chapterModel.chaperInfo?.data[indexPath.row]
                    if let bookModel = cellModel?.bookModel {
                        return bookModel.data.bookChapterMtsModeList.first?.videoUrl ?? ""
                    }
                }
            }
        }
        return ""
    }

    func requestCurrentUserCurriculum(success: @escaping(Bool) -> Void, failed: @escaping(NSError) -> Void) {
        do {
            let request = try STURLRequest.request(url: self.curriculumUrl, method: .get)
            AF.request(request).responseDecodable(of: STCurriculumModel.self) {[weak self] response in
                guard let strongSelf = self else { return }
                if let model = response.value {
                    for dateModel in model.data {
                        if dateModel.bookName.contains("本地商家运营师") {
                            strongSelf.courseId = dateModel.id
                            break
                        }
                    }
                    if strongSelf.courseId != -1 {
                        strongSelf.requestCurriculumChapters(id: strongSelf.courseId, success: success, failed: failed)
                    } else {
                        let error = NSError.init(domain: "未获取到课程id", code: -100)
                        DispatchQueue.main.async {
                            failed(error)
                        }
                    }
                } else {
                    let error = NSError.init(domain: "请求失败", code: -100)
                    DispatchQueue.main.async {
                        failed(error)
                    }
                }
            }
        } catch (let error) {
            DispatchQueue.main.async {
                failed(error as NSError)
            }
        }
    }
    
    private func requestCurriculumChapters(id: Int, success: @escaping(Bool) -> Void, failed: @escaping(NSError) -> Void) {
        do {
            let request = try STURLRequest.request(url: self.chaptersUrl(id: id, pageNo: self.pageNo, pageSize: self.pageSize), method: .get)
            AF.request(request).responseDecodable(of: STCurriculumChaptersModel.self) {[weak self] response in
                guard let strongSelf = self else { return }
                if let model = response.value {
                    strongSelf.curriculumChaptersDataSources["\(id)"] = model
                    
                    let group = DispatchGroup()
                    DispatchQueue.global().async(group: group) {
                        for chapterModel in model.data.list {
                            strongSelf.requestCurriculumChapter(id: id, chapterId: chapterModel.chapterId) { result in
                                strongSelf.semaphore.signal()
                            } failed: { error in
                                strongSelf.semaphore.signal()
                            }
                            strongSelf.semaphore.wait()
                        }
                    }
                    group.notify(queue: DispatchQueue.main) {
                        success(true)
                    }
                } else {
                    let error = NSError.init(domain: "请求失败", code: -100)
                    DispatchQueue.main.async {
                        failed(error)
                    }
                }
            }
        } catch (let error) {
            DispatchQueue.main.async {
                failed(error as NSError)
            }
        }
    }
    
    private func requestCurriculumChapter(id: NSInteger, chapterId: NSInteger, success: @escaping(Bool) -> Void, failed: @escaping(NSError) -> Void) {
        do {
            let request = try STURLRequest.request(url: self.chapterUrl(chapterId: chapterId, id: id), method: .get)
            AF.request(request).responseDecodable(of: STCurriculumSingleChaperModel.self) {[weak self] response in
                guard let strongSelf = self else { return }
                if let model = response.value {
                    if let dictModel = strongSelf.curriculumChaptersDataSources["\(id)"] {
                        var tempDictModel = dictModel
                        for (i,dataModel) in dictModel.data.list.enumerated() {
                            var tempDataModel = dataModel
                            if dataModel.chapterId == chapterId {
                                tempDataModel.chaperInfo = model
                                tempDictModel.data.list[i] = tempDataModel
                                strongSelf.curriculumChaptersDataSources["\(id)"] = tempDictModel
                                break
                            }
                        }
                        
                        DispatchQueue.global().async(group: strongSelf.bookSerialGroup) {
                            for bookModel in model.data {
                                strongSelf.requestCurriculumChapterInfo(id: id, chapterId: bookModel.charterId) { result in
                                    strongSelf.bookSemaphore.signal()
                                } failed: { error in
                                    strongSelf.bookSemaphore.signal()
                                }
                                strongSelf.bookSemaphore.wait()
                            }
                        }
                        strongSelf.bookSerialGroup.notify(queue: DispatchQueue.main) {
                            success(true)
                        }
//                        for bookModel in model.data {
//                            DispatchQueue.global().async {
//                                strongSelf.requestCurriculumChapterInfo(id: id, chapterId: bookModel.charterId) { result in
//                                    strongSelf.bookSemaphore.signal()
//                                } failed: { error in
//                                    strongSelf.bookSemaphore.signal()
//                                }
//                                strongSelf.bookSemaphore.wait()
//                            }
//                        }
//
//                        DispatchQueue.main.async {
//                            success(true)
//                        }
                    } else {
                        let error = NSError.init(domain: "课程ID不存在", code: -100)
                        DispatchQueue.main.async {
                            strongSelf.semaphore.signal()
                            failed(error)
                        }
                    }
                } else {
                    let error = NSError.init(domain: "请求失败", code: -100)
                    DispatchQueue.main.async {
                        strongSelf.semaphore.signal()
                        failed(error)
                    }
                }
            }
        } catch (let error) {
            DispatchQueue.main.async {
                self.semaphore.signal()
                failed(error as NSError)
            }
        }
    }
    
    private func requestCurriculumChapterInfo(id: NSInteger, chapterId: NSInteger, success: @escaping(Bool) -> Void, failed: @escaping(NSError) -> Void) {
        do {
            let request = try STURLRequest.request(url: self.chapterInfoUrl(chapterId: chapterId, id: id), method: .get)
            AF.request(request).responseDecodable(of: STBookModel.self) {[weak self] response in
                guard let strongSelf = self else { return }
                if let model = response.value {
                    if let dictModel = strongSelf.curriculumChaptersDataSources["\(id)"] {
                        var isFinished = false
                        var tempDictModel = dictModel
                        for (k, dataModel) in dictModel.data.list.enumerated() {
                            var tempDataModel = dataModel
                            if let chapterList = dataModel.chaperInfo?.data {
                                for (i, chapterModel) in chapterList.enumerated() {
                                    if chapterModel.charterId == chapterId {
                                        isFinished = true
                                        var tempChapterModel = chapterModel
                                        tempChapterModel.bookModel = model
                                        tempDataModel.chaperInfo?.data[i] = tempChapterModel
                                        tempDictModel.data.list[k] = tempDataModel
                                        strongSelf.curriculumChaptersDataSources["\(id)"] = tempDictModel
                                        
//                                        print(model.data.bookChapterMtsModeList.last?.videoUrl ?? "")
                                        break
                                    }
                                }
                            }
                        }
                        DispatchQueue.main.async {
                            success(isFinished)
                        }
                    } else {
                        let error = NSError.init(domain: "课程ID不存在", code: -100)
                        DispatchQueue.main.async {
                            failed(error)
                        }
                    }
                } else {
                    let error = NSError.init(domain: "请求失败", code: -100)
                    DispatchQueue.main.async {
                        failed(error)
                    }
                }
            }
        } catch (let error) {
            DispatchQueue.main.async {
                failed(error as NSError)
            }
        }
    }
    
    func downloadVideo(urlString: String, title: String, complection: @escaping(Progress) -> Void) {
//        let destination = DownloadRequest.suggestedDownloadDestination(for: .documentDirectory)
        let destination: DownloadRequest.Destination = { (url, response) in
            let docmentURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            var newName = urlString
            if let lastComponent = urlString.split(separator: ".").last {
                newName = title.appending(".\(lastComponent)")
            }
            let fileRUL = docmentURL?.appendingPathComponent(newName)//拼接处完整的路径
            return (fileRUL!, [.removePreviousFile,.createIntermediateDirectories])
        }
        AF.download(urlString, to: destination).downloadProgress { progress in
//                complection(progress.)
        }.validate().responseData { response in
            print(response.fileURL ?? "")
        }
    }
    
    func printChaterName() {
        let model = self.getCurriculumChaptersDataSources()["\(self.courseId)"]
        if let list = model?.data.list {
            for listModel in list {
                print("课程章节名：", listModel.chapterName)
                if let chaperInfo = listModel.chaperInfo {
                    for chaperInfoModel in chaperInfo.data {
                        print(chaperInfoModel.charterName)
                        
                        if let bookData = chaperInfoModel.bookModel?.data {
                            for bookInfo in bookData.bookChapterMtsModeList {
                                if bookInfo.videoUrl.hasSuffix(".mp4") {
                                    downloadVideo(urlString: bookInfo.videoUrl, title: bookInfo.name) { progress in

                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    func downloadResources() {
        let jsonString = Bundle.main.path(forResource: "resources", ofType: ".json")
        let data = try! Data(contentsOf: URL(fileURLWithPath: jsonString!))
        let resourcesModel = try! JSONDecoder().decode(STResourcesModel.self, from: data)
        for model in resourcesModel.data.list {
            let destination: DownloadRequest.Destination = { (url, response) in
                let docmentURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
                var newName = model.ossUrl
                if let lastComponent = "\(response.url?.lastPathComponent ?? "")".split(separator: ".").last {
                    newName = model.title.appending(".\(lastComponent)")
                }
                let fileRUL = docmentURL?.appendingPathComponent(newName)//拼接处完整的路径
                return (fileRUL!, [.removePreviousFile,.createIntermediateDirectories])
            }
            
            AF.download(model.ossUrl, to: destination).downloadProgress { progress in
//                complection(progress.)
            }.validate().responseData { response in
                print(response.fileURL ?? "")
            }
        }
    }
    
    func getCurriculumDataSources() -> [STCurriculumModel] {
        return self.curriculumDataSources
    }
    
    private lazy var curriculumDataSources: [STCurriculumModel] = {
        let dataSources: [STCurriculumModel] = [STCurriculumModel]()
        return dataSources
    }()
    
    func getCurriculumChaptersDataSources() -> [String: STCurriculumChaptersModel] {
        return self.curriculumChaptersDataSources
    }
    
    private lazy var curriculumChaptersDataSources: [String: STCurriculumChaptersModel]  = {
        let dataSources: [String: STCurriculumChaptersModel] = [String: STCurriculumChaptersModel]()
        return dataSources
    }()
    
    private lazy var domain: String = {
        return "https://app-api.moushikeji.com"
    }()
    
    // 当前用户已开通课程
    private lazy var curriculumUrl: String = {
        return "\(self.domain)/query/user/curriculum"
    }()
    
    // 请求开通课程所有章节
    private func chaptersUrl(id: NSInteger, pageNo: NSInteger, pageSize: NSInteger) -> String {
        return "\(self.domain)/chapters/page?id=\(id)&pageNo=\(pageNo)&pageSize=\(pageSize)"
    }
    
    // 单个章节下课程小节
    private func chapterUrl(chapterId: NSInteger, id: NSInteger) -> String {
        return "\(self.domain)/\(chapterId)/chapters/list?id=\(id)"
    }
    
    // 单个小节信息
    private func chapterInfoUrl(chapterId: NSInteger, id: NSInteger) -> String {
        return "\(self.domain)/\(id)/book/info?chapterId=\(chapterId)"
    }
}
