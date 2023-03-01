//
//  M3U8Entity.swift
//  AriaM3U8Downloader
//
//  Created by 神崎H亚里亚 on 2019/11/28.
//  Copyright © 2019 moxcomic. All rights reserved.
//

import UIKit

class M3U8Entity: NSObject {
    var TRUE_Prefix: String!
    var M3U8_URL: String!
    var OUTPUT_PATH: String!
    var EXT_X_VERSION: Int = 0
    var EXT_X_PLAYLIST_TYPE: String!
    var EXT_X_TARGETDURATION: Int = 0
    var EXT_X_MEDIA_SEQUENCE: Int = 0
    var EXT_X_KEY: String!
    var EXT_X_IV: String!
    var METHOD: String!
    var INFDATA = [Float]()
    var TSDATA = [String]()
    var FAILURE_TSDATA = [String]()
    var currentDownloadTSIndex = 0
}
