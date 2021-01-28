//
//  STTestViewController.swift
//  STBaseProject_Example
//
//  Created by song on 2021/1/28.
//  Copyright © 2021 STBaseProject. All rights reserved.
//

import UIKit
import STBaseProject

class STTestViewController: STBaseViewController {

    @IBOutlet weak var heightConstraint: NSLayoutConstraint!
    @IBOutlet weak var tpConstraint: NSLayoutConstraint!
    @IBOutlet weak var nameLabel: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("nameLabel top constraint \(self.tpConstraint.constant) -- height constraint \(self.heightConstraint.constant)")
        // Do any additional setup after loading the view.
    }


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
