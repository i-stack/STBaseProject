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

    var carousel: iCarousel!
    var items: [Int] = []
    var expendBtn: UIButton!
    var count: NSInteger = 0
    var btnClick: Bool = false
    
    var blueView: UIView!
    var orangeView: UIView!
    var blackView: UIView!
    var contentView: UIView!
    var scrollView: UIScrollView!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        for i in 0 ... 5 {
            items.append(i)
        }
        addCardView()
        
//        contentView = self.createView()
//        scrollView = UIScrollView.init(frame: self.view.bounds)
//        self.view.addSubview(scrollView)
//        scrollView.addSubview(contentView)
//
//        blueView = self.createView()
//        blueView.tag = 100
//        blueView.backgroundColor = UIColor.blue
////        self.view.insertSubview(blueView, at: 0)
//
//        orangeView = self.createView()
//        orangeView.tag = 200
//        orangeView.backgroundColor = UIColor.orange
////        self.view.insertSubview(orangeView, at: 0)
//
//        blackView = self.createView()
//        blackView.tag = 300
//        blackView.backgroundColor = UIColor.black
////        self.view.insertSubview(blackView, at: 0)
//
////        self.view.addSubview(blackView)
////        self.view.addSubview(orangeView)
////        self.view.addSubview(blueView)
//
//        var transform: CATransform3D = CATransform3DMakeTranslation(20, 20, -30)
//        orangeView.layer.transform = transform
//
//        transform = CATransform3DIdentity
//        transform.m41 = 40
//        transform.m42 = 40
//        transform.m43 = -30
//        blackView.layer.transform = transform
    }
    
    func createView() -> UIView {
        let view: UIView = UIView.init(frame: CGRect.init(x: 100, y: 100, width: 200, height: 100))
        let pan: UIPanGestureRecognizer = UIPanGestureRecognizer.init(target: self, action: #selector(panGes(pan:)))
        view.addGestureRecognizer(pan)
        view.isUserInteractionEnabled = true
        return view
    }
    
    @objc func panGes(pan: UIPanGestureRecognizer) -> Void {
        
        let offset = pan.location(in: self.view)
        let view: UIView = pan.view ?? UIView()
        let velocity = pan.velocity(in: self.view)
        if pan.state == .began {
            
        } else if pan.state == .changed {
            if view.tag == 100 {
                var transform: CATransform3D = CATransform3DMakeTranslation(20, 20 - offset.y, -30)
                blueView.layer.transform = transform
                
                var originX = 20.0 - offset.y
                if originX < 0 {
                    originX = 0
                }
                transform = CATransform3DMakeTranslation(originX, 20 - offset.y, -30)
                orangeView.layer.transform = transform
                
                originX = 40 - offset.y
                if originX < 20 {
                    originX = 20
                }
                transform = CATransform3DMakeTranslation(originX, 20 - offset.y, -30)
                blackView.layer.transform = transform
                
            } else if view.tag == 200 {
                
            } else if view.tag == 300 {
                
            }
        } else if pan.state == .ended {
            
        }
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
    }
    
    @objc func expendBtnClick() -> Void {
        btnClick = !btnClick
//        if btnClick {
//        } else {
//        }

//        carousel.type = .invertedTimeMachine
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
    
    func carousel(_ carousel: iCarousel, itemTransformForOffset offset: CGFloat, baseTransform transform: CATransform3D) -> CATransform3D {
//        let newTransform = CATransform3DRotate(transform, 0.0, 0.0, CGFloat(Double.pi / 8.0), 0.0);
        return CATransform3DTranslate(transform, 0.0, 0.0, 0.0)
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
            return items.count
        }
        return 0
    }
    
//    func numberOfSections(in tableView: UITableView) -> Int {
//        if btnClick {
//            return items.count
//        }
//        return 1
//    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: STCarouselTableViewCell = tableView.dequeueReusableCell(withIdentifier: "STCarouselTableViewCell") as! STCarouselTableViewCell
//        for view in cell.showContentView.subviews {
//            view.removeFromSuperview()
//        }
        cell.textLabel?.text = "\(items[indexPath.row])"
        cell.textLabel?.textColor = UIColor.black
//        if indexPath.row < dataSources.count {
//            let view = dataSources[indexPath.row]
//            view.frame = CGRect.init(x: 0, y: 0, width: self.view.bounds.size.width, height: 250)
//            cell.showContentView.addSubview(view)
//        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 188.0
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let newCell: STCarouselTableViewCell = cell as! STCarouselTableViewCell
        newCell.rightInAnimation(forIndex: indexPath.row)
        cell.layer.transform = CATransform3DMakeTranslation(20, -20, 0)//CGAffineTransform(translationX: 0, y: -80);
        UIView.animate(withDuration: 0.5) {
            cell.transform = CGAffineTransform.identity;
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 250.0
        if section == 0 {
            return 250.0
        }
        return CGFloat.leastNormalMagnitude
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return carousel
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 100.0
//        if !btnClick {
//            return 100.0
//        }
//        if section == items.count - 1 {
//            return 100.0
//        }
//        return CGFloat.leastNormalMagnitude
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footerView: UIView = UIView()
        footerView.backgroundColor = UIColor.orange

//        if section == items.count - 1, btnClick {
//            footerView.backgroundColor = UIColor.orange
//        } else if !btnClick {
//            footerView.backgroundColor = UIColor.orange
//        } else {
//            footerView.backgroundColor = UIColor.white
//        }
        return footerView
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let sectionFooterHeight: CGFloat = 100
        if scrollView.contentOffset.y <= sectionFooterHeight, scrollView.contentOffset.y >= 0 {
            scrollView.contentInset = UIEdgeInsets.init(top: -scrollView.contentOffset.y, left: 0.0, bottom: 0.0, right: 0.0)
        } else if scrollView.contentOffset.y >= sectionFooterHeight {
            scrollView.contentInset = UIEdgeInsets.init(top: -sectionFooterHeight, left: 0.0, bottom: 0.0, right: 0.0)
        }
    }
}
