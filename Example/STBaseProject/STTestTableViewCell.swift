//
//  STTestTableViewCell.swift
//  STBaseProject_Example
//
//  Created by song on 2021/7/17.
//  Copyright © 2021 STBaseProject. All rights reserved.
//

import UIKit

class STTestTableViewCell: UITableViewCell {

    @IBOutlet weak var progressView: UIProgressView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
