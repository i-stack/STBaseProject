//
//  STLocalBusinessOperatorModel.swift
//  STBaseProject_Example
//
//  Created by song on 2023/2/27.
//  Copyright © 2023 STBaseProject. All rights reserved.
//

import UIKit

struct STCurriculumModel : Codable {
    var code: Int = 0
    var message: String = ""
    var data: [STCurriculumDataModel] = [STCurriculumDataModel]()
}

struct STCurriculumDataModel : Codable {
    var id: Int = 0
    var isLive: Int = 0
    var bookId: Int = 0
    var bookCount: Int = 0
    var isClickNew: Int = 0
    var plannedSpeed: Int = 0
    var bookChapterId: Int = 0
    var bookChapterName: String = ""
    var coverImg: String = ""
    var bookName: String = ""
}

// 课程下章节
struct STCurriculumChaptersModel: Codable {
    var code: Int = 0
    var message: String = ""
    var data: STCurriculumChaptersDataModel = STCurriculumChaptersDataModel()
}

struct STCurriculumChaptersDataModel: Codable {
    var list: [STCurriculumChapersList] = [STCurriculumChapersList]()
}

struct STCurriculumChapersList: Codable {
    var chapterId: Int = 0
    var chapterName: String = ""
    var chaperInfo: STCurriculumSingleChaperModel?
}

// 章节下小节
struct STCurriculumSingleChaperModel: Codable {
    var code: Int = 0
    var message: String = ""
    var data: [STCurriculumSingleChaperList] = [STCurriculumSingleChaperList]()
}

struct STCurriculumSingleChaperList: Codable {
    var sort: Int = 0
    var charterId: Int = 0
    var charterName: String = ""
    var timeCount: String = ""
    var bookModel: STBookModel?
}

// 小节具体信息
struct STBookModel: Codable {
    var code: Int = 0
    var message: String = ""
    var data: STBookDataModel = STBookDataModel()
}

struct STBookDataModel: Codable {
    var id: Int = 0
    var bookId: Int = 0
    var bookCount: Int = 0
    var plannedSpeed: Int = 0
    var merchantIdCount: Int = 0
    var coverImg: String = ""
    var bookName: String = ""
    var chapterName: String = ""
    var bookChapterMtsModeList: [STBookChapterMtsMode] = [STBookChapterMtsMode]()
}

struct STBookChapterMtsMode: Codable {
    var id: Int = 0
    var chapterId: Int = 0
    var name: String = ""
    var name2: String = ""
    var videoSize: String = ""
    var videoUrl: String = ""
}

struct STResourcesModel: Codable {
    var code: Int = 0
    var message: String = ""
    var data: STResuoucesDataModel = STResuoucesDataModel()
}

struct STResuoucesDataModel: Codable {
    var list: [STResuoucesDataListModel] = [STResuoucesDataListModel]()
}

struct STResuoucesDataListModel: Codable {
    var title: String = ""
    var ossUrl: String = ""
}
