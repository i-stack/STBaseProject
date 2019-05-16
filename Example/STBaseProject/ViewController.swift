//
//  ViewController.swift
//  STBaseProject
//
//  Created by songMW on 05/16/2019.
//  Copyright (c) 2019 songMW. All rights reserved.
//

import UIKit
import STBaseProject

class ViewController: STBaseOpenSystemOperationController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.st_openPhotoLibrary()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

