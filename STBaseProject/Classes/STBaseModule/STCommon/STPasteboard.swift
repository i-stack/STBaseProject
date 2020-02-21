//
//  STPasteboard.swift
//  STBaseProject
//
//  Created by stack on 2017/10/24.
//  Copyright © 2018年 song. All rights reserved.
//

import Foundation

public class STPasteboard: NSObject {
    
    public class func st_pasteboardWithString(pasteboardString: String) -> Void {
        let pasteboard = UIPasteboard.general
        pasteboard.string = pasteboardString
    }
}
