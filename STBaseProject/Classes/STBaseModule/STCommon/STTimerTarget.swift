//
//  STTimerTarget.swift
//  STBaseFramework
//
//  Created by stack on 2019/12/13.
//  Copyright © 2019 ST. All rights reserved.
//

import UIKit

public class STTimerTarget: NSObject {

    private weak var target: AnyObject?

    public init(aTarget: AnyObject) {
        super.init()
        self.target = aTarget
    }

    public override func forwardingTarget(for aSelector: Selector!) -> Any? {
        return self.target
    }
}