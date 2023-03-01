//
//  STMoushiVideoDownViewController.swift
//  STBaseProject_Example
//
//  Created by song on 2023/2/27.
//  Copyright © 2023 STBaseProject. All rights reserved.
//

import UIKit
import STBaseProject

class STMoushiVideoDownViewController: STBaseViewController {

    @IBOutlet weak var topConstraint: NSLayoutConstraint!
    @IBOutlet weak var tableView: UITableView!
    
    private let viewModel: STMoushiVideoDownViewModel = STMoushiVideoDownViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.titleLabel.text = "谋事视频下载"
        self.titleLabel.textColor = UIColor.black
        self.st_showNavBtnType(type: .showLeftBtn)
        self.leftBtn.setImage(UIImage.init(named: "left_arrow"), for: .normal)
        self.tableView.tableFooterView = UIView()
        self.topConstraint.constant = STScreenSizeConstants.st_navHeight()
        self.viewModel.loadData {[weak self] result in
            guard let strongSelf = self else { return }
            if result {
                strongSelf.tableView.reloadData()
            }
        }
    }
}

extension STMoushiVideoDownViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.cellDateSources().count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = ""
        var cell = tableView.dequeueReusableCell(withIdentifier: identifier)
        if (cell == nil) {
            cell = UITableViewCell.init(style: .default, reuseIdentifier: identifier)
            cell?.selectionStyle = .none
        }
        let model = self.viewModel.cellForRow(indexPath: indexPath)
        cell?.textLabel?.text = model.title
        return cell ?? UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let model = self.viewModel.cellForRow(indexPath: indexPath)
        let namespace = Bundle.main.infoDictionary!["CFBundleName"] as! String
        let classFromStr: AnyClass? = NSClassFromString(namespace + "." + model.className)
        let viewControllerClass = classFromStr as! UIViewController.Type
        let moushiVC = viewControllerClass.init(nibName: model.nibName, bundle: nil)
        self.navigationController?.pushViewController(moushiVC, animated: true)
    }
}
