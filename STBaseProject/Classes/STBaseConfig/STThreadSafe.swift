//
//  STConstants.swift
//  STBaseProject
//
//  Created by stack on 2019/03/16.
//  Copyright © 2019年 ST. All rights reserved.
//

import Dispatch

public func dispatch_main_async_safe(callBack: @escaping () -> Void) {
    if Thread.isMainThread {
        callBack()
    } else {
        DispatchQueue.main.async { callBack() }
    }
}
