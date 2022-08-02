//
//  ColorModel.swift
//  STBaseProject_Example
//
//  Created by qcraft on 2022/7/29.
//  Copyright © 2022 STBaseProject. All rights reserved.
//

import Foundation
import STBaseProject

struct ColorsInfo: Codable {
    var colors: Dictionary<String, ColorModel> = Dictionary<String, ColorModel>()
}

struct ColorModel: Codable {
    var light: String = ""
    var dark: String = ""
}
