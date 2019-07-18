//
//  STCarouselTableViewCell.swift
//  STBaseProject_Example
//
//  Created by stack on 2019/7/16.
//  Copyright © 2019 STBaseProject. All rights reserved.
//

import UIKit

class STCarouselTableViewCell: UITableViewCell {
    
    var showContentView: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
//        self.showContentView = UIView.init()
//        self.showContentView.backgroundColor = UIColor.white
//        self.addSubview(self.showContentView)
//        self.showContentView.snp.makeConstraints { (make) in
//            make.top.left.bottom.right.equalToSuperview()
//        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func rightInAnimation(withDuration duration: Double = 0.5, withDelay delay : Double = 0.08, forIndex index : Int) {
        self.transform = CGAffineTransform(translationX: self.bounds.width, y: 0)
        UIView.animate(withDuration: duration,delay: delay * Double(index),animations: {
            self.transform = CGAffineTransform(translationX: 0, y: 0)
        })
    }
}
