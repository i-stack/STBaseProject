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
    var tempItems: [Int] = []

    var expendBtn: UIButton!
    var count: NSInteger = 0
    var btnClick: Bool = false
    
    var currentIndex: NSInteger = 0
    var collectionView: UICollectionView!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        for i in 0 ... 5 {
            items.append(i)
        }
        createCollectionView()
        addCardView()
    }

    func addCardView() -> Void {
        carousel = iCarousel.init(frame: CGRect.init(x: 0, y: 0, width: self.view.bounds.size.width, height: 230))
        carousel.delegate = self
        carousel.dataSource = self
        carousel.backgroundColor = UIColor.purple
        carousel.isVertical = true
        carousel.type = .invertedTimeMachine
        self.view.addSubview(carousel)
        
        expendBtn = UIButton.init(type: UIButton.ButtonType.custom)
        expendBtn.frame = CGRect.init(x: 10, y: 10, width: 40, height: 40)
        expendBtn.setTitle("展开", for: UIControl.State.normal)
        expendBtn.setTitleColor(UIColor.black, for: UIControl.State.normal)
        expendBtn.addTarget(self, action: #selector(expendBtnClick), for: UIControl.Event.touchUpInside)
        self.view.addSubview(expendBtn)
    }
    
    func createCollectionView() -> Void {
        tempItems.append(items[self.currentIndex])

        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout.init()
        layout.itemSize = CGSize.init(width: self.view.bounds.size.width - 50, height: 188)
        layout.minimumLineSpacing = 20
        
        collectionView = UICollectionView.init(frame: CGRect.init(x: 0, y: 0, width: self.view.bounds.size.width, height: self.view.bounds.size.height - 0), collectionViewLayout: layout)
        collectionView.bounces = false
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.isPagingEnabled = true
        collectionView.register(STCarouselCollectionViewCell.self, forCellWithReuseIdentifier: "STCarouselCollectionViewCell")
        self.view.addSubview(collectionView)
    }
    
    @objc func expendBtnClick() -> Void {
        btnClick = !btnClick
//        tempItems.removeAll()
        if btnClick {
            var expendItems: Array<Int> = items
            expendItems.remove(at: Int(self.currentIndex))
            carousel.isHidden = true
            collectionView.isHidden = false
            for index in 0...expendItems.count - 1 {
                tempItems.append(items[index])
                collectionView.insertItems(at: [IndexPath.init(row: items.count - 1, section: 0)])
            }
//            UIView.transition(with: self.contentView, duration: 1, options: UIView.AnimationOptions.curveEaseInOut, animations: {
//            }) { (done) in
//
//
//            }
//            scrollView.contentSize = CGSize.init(width: Int(self.view.bounds.size.width), height: 208 * items.count)
        } else {
            carousel.isHidden = false
            tempItems.append(items[self.currentIndex])
            collectionView.reloadData()
            collectionView.isHidden = true
//            for subView in contentView.subviews {
//                if !subView.isKind(of: iCarousel.self), !subView.isKind(of: UIButton.self) {
//                    subView.removeFromSuperview()
//                }
//            }
        }
//        carousel.removeFromSuperview()
        //addCardView()
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
            itemView = UIImageView(frame: CGRect(x: 50, y: 0, width: Int(self.view.bounds.size.width) - 50, height: 188))
            itemView.backgroundColor = UIColor.randomColor
            label = UILabel(frame: itemView.bounds)
            label.backgroundColor = .clear
            label.textAlignment = .center
            label.font = label.font.withSize(50)
            label.tag = 1
            itemView.addSubview(label)
        }
        if btnClick {
            label.text = "\(tempItems[index])"
        } else {
            label.text = "\(items[index])"
        }
        return itemView
    }
    
    func numberOfItems(in carousel: iCarousel) -> Int {
        if btnClick {
            return tempItems.count
        }
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
        self.currentIndex = carousel.currentItemIndex
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

extension STCarouselViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return tempItems.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: STCarouselCollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: "STCarouselCollectionViewCell", for: indexPath) as! STCarouselCollectionViewCell
        cell.backgroundColor = UIColor.randomColor
        return cell
    }
}
