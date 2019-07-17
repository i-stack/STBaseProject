//
//  STCarouselViewController.swift
//  STBaseProject_Example
//
//  Created by stack on 2019/7/8.
//  Copyright © 2019 STBaseProject. All rights reserved.
//

import UIKit
import SnapKit

class STCarouselViewController: UIViewController {

    var stCarousel: STCarousel!
    var carousel: iCarousel!
    var items: [Int] = []
    var expendBtn: UIButton!
    var tableView: UITableView!
    var dataSources: Array<UIView> = Array<UIView>()
    var count: NSInteger = 0
    var btnClick: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        for i in 0 ... 99 {
            items.append(i)
        }
        //createTableView()
        addCardView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        carousel.isVertical = true
        carousel.type = .invertedTimeMachine
    }

    func addCardView() -> Void {
        carousel = iCarousel.init(frame: CGRect.init(x: 0, y: 0, width: self.view.bounds.size.width, height: 250))
        carousel.delegate = self
        carousel.dataSource = self
        carousel.backgroundColor = UIColor.purple
        self.view.addSubview(carousel)
        
        expendBtn = UIButton.init(type: UIButton.ButtonType.custom)
        expendBtn.frame = CGRect.init(x: 10, y: 10, width: 40, height: 40)
        expendBtn.setTitle("展开", for: UIControl.State.normal)
        expendBtn.setTitleColor(UIColor.black, for: UIControl.State.normal)
        expendBtn.addTarget(self, action: #selector(expendBtnClick), for: UIControl.Event.touchUpInside)
        carousel.addSubview(expendBtn)
        dataSources.append(carousel)
    }
    
    @objc func expendBtnClick() -> Void {
        btnClick = !btnClick
        if btnClick {
            tableView.isHidden = false
            tableView.reloadData()
        } else {
            tableView.isHidden = true
        }
        carousel.type = .invertedTimeMachine
    }
    
    func createTableView() -> Void {
        tableView = UITableView.init(frame: self.view.bounds, style: UITableView.Style.plain)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        tableView.register(STCarouselTableViewCell.self, forCellReuseIdentifier: "STCarouselTableViewCell")
        self.view.addSubview(tableView)
        
        addCardView()
    }
}

extension STCarouselViewController: STCarouselDataSource {
    func st_numberOfItemsIn(carousel: STCarousel) -> NSInteger {
        if btnClick {
            return 1
        }
        return items.count
    }
    
    func st_carouselViewForItem(in viewForItemAtIndex: STCarousel, at index: NSInteger) -> UIView {
        var label: UILabel
        var itemView: UIImageView
        
        if let view = view as? UIImageView {
            itemView = view
            label = itemView.viewWithTag(1) as! UILabel
        } else {
            itemView = UIImageView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
            itemView.backgroundColor = UIColor.purple
            label = UILabel(frame: itemView.bounds)
            label.backgroundColor = .clear
            label.textAlignment = .center
            label.font = label.font.withSize(50)
            label.tag = 1
            itemView.addSubview(label)
        }
        
        itemView.frame = CGRect.init(x: 40 + 40 * count, y: 20 * count, width: Int(self.view.bounds.size.width) - 40 * count, height: 188)
        label.frame = itemView.bounds
        view?.frame = itemView.frame
        count += 1
        label.text = "\(items[index])"
        
        return itemView
    }
    
    func st_cardItem(_ cardView: STCarousel, cellForItemAt Index: Int) -> STCardItem {
        var item: STCardItem!
        if let image = UIImage(named: "img_0" + "\(Index)") {
            item = STCardItem(image: image)
        } else {
            item = STCardItem(image: UIImage.getImageWithColor(color: UIColor.randomColor))
        }
        return item
    }

    func st_numberOfItems(in cardView: STCarousel) -> Int {
        return count
    }
}

extension STCarouselViewController: STCarouselDelegate {
    func st_carouselWillBeginScrollingAnimation(carousel: STCarousel) {
        
    }
    
    func st_carouselDidEndScrollingAnimation(carousel: STCarousel) {
        
    }
    
    func st_carouselDidEndDecelerating(carousel: STCarousel) {
        
    }
    
    func st_carousel(carousel: STCarousel, valueFor option: STCarouselOption, default value: CGFloat) -> CGFloat {
        var result: CGFloat = 0.0
        switch option {
        case .STCarouselOptionWrap:
            result = 1.0
            break
        case .STCarouselOptionSpacing:
            result = value * 1.05
            break
        case .STCarouselOptionFadeMax:
            result = value
            break
        default:
            result = value
            break
        }
        return result
    }
    
    func st_didClick(cardView: STCarousel, with index: Int) {
        print("click index: \(index)")
    }

    func st_remove(cardView: STCarousel, item: STCardItem, with index: Int) {
        print("remove: \(index)")
    }

    func st_revoke(cardView: STCarousel, item: STCardItem, with index: Int) {

    }
}

extension STCarouselViewController: iCarouselDataSource, iCarouselDelegate {
    func carousel(_ carousel: iCarousel, viewForItemAt index: Int, reusing view: UIView?) -> UIView {
        var label: UILabel
        var itemView: UIImageView
        
        if (count >= 3) {
            count = 2;
        }
        //reuse view if available, otherwise create a new view
        if let view = view as? UIImageView {
            itemView = view
            //get a reference to the label in the recycled view
            label = itemView.viewWithTag(1) as! UILabel
        } else {
            //don't do anything specific to the index within
            //this `if ... else` statement because the view will be
            //recycled and used with other index values later
            itemView = UIImageView(frame: CGRect(x: 40, y: 0, width: Int(self.view.bounds.size.width) - 40 * count - 40, height: 188))
//            itemView.image = UIImage(named: "page.png")
            //itemView.contentMode = .center
            itemView.backgroundColor = UIColor.gray
            label = UILabel(frame: itemView.bounds)
            label.backgroundColor = .clear
            label.textAlignment = .center
            label.font = label.font.withSize(50)
            label.tag = 1
            itemView.addSubview(label)
        }
        
//        itemView.frame = CGRect.init(x: 40 + 40 * count, y: 20 * count, width: Int(self.view.bounds.size.width) - 40 * count - 40, height: 188)
//        label.frame = itemView.bounds
//        count += 1
        
        //set item label
        //remember to always set any properties of your carousel item
        //views outside of the `if (view == nil) {...}` check otherwise
        //you'll get weird issues with carousel item content appearing
        //in the wrong place in the carousel
        label.text = "\(items[index])"
        dataSources.append(itemView)
        return itemView
    }
    
    func numberOfItems(in carousel: iCarousel) -> Int {
        return items.count
    }
    
    func carousel(_ carousel: iCarousel, itemTransformForOffset offset: CGFloat, baseTransform transform: CATransform3D) -> CATransform3D {
        let newTransform = CATransform3DRotate(transform, 0.0, 0.0, CGFloat(Double.pi / 8.0), 0.0);
        return CATransform3DTranslate(newTransform, 0.0, 0.0, offset * self.carousel.itemWidth)
    }
    
    func carousel(_ carousel: iCarousel, valueFor option: iCarouselOption, withDefault value: CGFloat) -> CGFloat {
        if (option == .spacing) {
            return value * 1.1
        } else if option == .wrap {
            return 1.0
        }
        return value
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

extension STCarouselViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if btnClick {
            return dataSources.count
        }
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: STCarouselTableViewCell = tableView.dequeueReusableCell(withIdentifier: "STCarouselTableViewCell") as! STCarouselTableViewCell
        for view in cell.showContentView.subviews {
            view.removeFromSuperview()
        }
        if indexPath.row < dataSources.count {
            let view = dataSources[indexPath.row]
            view.frame = CGRect.init(x: 0, y: 0, width: self.view.bounds.size.width, height: 250)
            cell.showContentView.addSubview(view)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 250.0
//        if indexPath.row == 0 {
//            return 250.0
//        }
//        return 188.0
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.transform = CGAffineTransform(translationX: 0, y: -80);
        UIView.animate(withDuration: 0.5) {
            cell.transform = CGAffineTransform.identity;
        }
    }
}
