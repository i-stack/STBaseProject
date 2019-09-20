//
//  STCarouselViewController.swift
//  STBaseProject_Example
//
//  Created by stack on 2019/7/8.
//  Copyright © 2019 STBaseProject. All rights reserved.
//

import UIKit
import SnapKit
import STBaseProject

class STCarouselViewController: UIViewController {

    var carousel: iCarousel!
    var items: [Int] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        for i in 0 ... 10 {
            items.append(i)
        }
        addCardView()
    }

    func addCardView() -> Void {
        carousel = iCarousel.init(frame: CGRect.init(x: 0, y: 100, width: self.view.bounds.size.width, height: 230))
        carousel.delegate = self
        carousel.dataSource = self
        self.view.addSubview(carousel)
    }
}

extension STCarouselViewController: iCarouselDataSource, iCarouselDelegate {
    func carousel(_ carousel: iCarousel, viewForItemAt index: Int, reusing view: UIView?) -> UIView {
        var label: UILabel
        var itemView: UIImageView
        if let view = view as? UIImageView {
            itemView = view
            label = itemView.viewWithTag(1) as! UILabel
        } else {
            itemView = UIImageView(frame: CGRect(x: 40, y: 0, width: Int(self.view.bounds.size.width) - 40, height: 188))
            itemView.backgroundColor = UIColor.randomColor
            label = UILabel(frame: itemView.bounds)
            label.backgroundColor = .clear
            label.textAlignment = .center
            label.font = label.font.withSize(50)
            label.tag = 1
            itemView.addSubview(label)
        }
        label.text = "\(items[index])"
        return itemView
    }
    
    func numberOfItems(in carousel: iCarousel) -> Int {
        return items.count
    }

    func carousel(_ carousel: iCarousel, valueFor option: iCarouselOption, withDefault value: CGFloat) -> CGFloat {
        if (option == .spacing) {
            return value * 1.1
        } else if option == .wrap {
            return 1.0
        }
        return value
    }

    func carouselDidEndScrollingAnimation(_ carousel: iCarousel) {
        print("current index" + "\(carousel.currentItemIndex)")
    }
}

extension UIImage {
    /// 将颜色转换为图片
    static func getImageWithColor(color:UIColor)->UIImage{
        let rect = CGRect(x: 0, y: 0, width: 1, height: 1)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        context!.setFillColor(color.cgColor)
        context!.fill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
}

extension UIColor {
    //返回随机颜色
    class var randomColor: UIColor {
        get {
            let red = CGFloat(arc4random()%256)/255.0
            let green = CGFloat(arc4random()%256)/255.0
            let blue = CGFloat(arc4random()%256)/255.0
            return UIColor(red: red, green: green, blue: blue, alpha: 1.0)
        }
    }
}
