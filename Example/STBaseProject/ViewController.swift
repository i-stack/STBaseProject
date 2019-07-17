//
//  ViewController.swift
//  STBaseProject
//
//  Created by songMW on 05/16/2017.
//  Copyright (c) 2019 songMW. All rights reserved.
//

import UIKit
import STBaseProject

class ViewController: STBaseOpenSystemOperationController {
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.st_showNavBtnType(type: .none)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let carouselVC = STCarouselViewController()
        self.navigationController?.pushViewController(carouselVC, animated: true)
    }
}

