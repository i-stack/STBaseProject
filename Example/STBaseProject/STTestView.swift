//
//  STTestView.swift
//  STBaseProject_Example
//
//  Created by stack on 2020/1/14.
//  Copyright © 2020 STBaseProject. All rights reserved.
//

import UIKit
import SnapKit
import STBaseProject

class STTestView: STBaseView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.st_baseViewAddScrollView()
        
        let view = UIView()
        view.backgroundColor = UIColor.purple
        self.baseContentView?.addSubview(view)
        view.snp.makeConstraints { (make) in
            make.top.left.right.equalTo(0)
            make.height.equalTo(200)
        }
        
        let view1 = UIView()
        view1.backgroundColor = UIColor.purple
        self.baseContentView?.addSubview(view1)
        view1.snp.makeConstraints { (make) in
            make.top.equalTo(view.snp.bottom).offset(20)
            make.left.right.height.equalTo(view)
        }
        
        let view2 = UIView()
        view2.backgroundColor = UIColor.purple
        self.baseContentView?.addSubview(view2)
        view2.snp.makeConstraints { (make) in
            make.top.equalTo(view1.snp.bottom).offset(20)
            make.left.right.height.equalTo(view)
        }
        
        let view3 = UIView()
        view3.backgroundColor = UIColor.purple
        self.baseContentView?.addSubview(view3)
        view3.snp.makeConstraints { (make) in
            make.top.equalTo(view2.snp.bottom).offset(20)
            make.left.right.height.equalTo(view)
        }
        
        let view4 = UIView()
        view4.backgroundColor = UIColor.purple
        self.baseContentView?.addSubview(view4)
        view4.snp.makeConstraints { (make) in
            make.top.equalTo(view3.snp.bottom).offset(20)
            make.left.right.height.equalTo(view)
        }
        self.baseScrollView?.snp.makeConstraints({ (make) in
            make.edges.equalTo(self)
        })
        self.baseContentView?.snp.makeConstraints({ (make) in
            make.edges.equalTo(self.baseScrollView!)
            make.width.equalTo(self.baseScrollView!)
            make.bottom.equalTo(view4.snp.bottom).offset(20)
        })
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
