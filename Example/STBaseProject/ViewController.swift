//
//  ViewController.swift
//  STBaseProject
//
//  Created by i-stack on 05/16/2017.
//  Copyright (c) 2019 songMW. All rights reserved.
//

import UIKit
//import SnapKit
import STBaseProject
//import SDWebImage

class ViewController: STBaseViewController {
        
    @IBOutlet weak var topConstraint: NSLayoutConstraint!
    @IBOutlet weak var tableView: UITableView!
    
    var viewModel: ViewControllerViewModel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.titleLabel.text = "ViewController"
        self.titleLabel.textColor = UIColor.black
        self.st_showNavBtnType(type: .onlyShowTitle)
        self.tableView.tableFooterView = UIView()
        self.topConstraint.constant = STScreenSizeConstants.st_navHeight()
        self.viewModel?.loadData {[weak self] result in
            guard let strongSelf = self else { return }
            if result {
                strongSelf.tableView.reloadData()
            }
        }
    }
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel?.cellDateSources().count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = ""
        var cell = tableView.dequeueReusableCell(withIdentifier: identifier)
        if (cell == nil) {
            cell = UITableViewCell.init(style: .default, reuseIdentifier: identifier)
            cell?.selectionStyle = .none
        }
        let model = self.viewModel?.cellForRow(indexPath: indexPath)
        cell?.textLabel?.text = model?.title
        return cell ?? UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let model = self.viewModel?.cellForRow(indexPath: indexPath) {
            let namespace = Bundle.main.infoDictionary!["CFBundleName"] as! String
            let classFromStr: AnyClass? = NSClassFromString(namespace + "." + model.className)
            let viewControllerClass = classFromStr as! UIViewController.Type
            let moushiVC = viewControllerClass.init(nibName: model.nibName, bundle: nil)
            self.navigationController?.pushViewController(moushiVC, animated: true)
        }
    }
}

extension ViewController {
    @objc func testRandomString() {
        var dict: Dictionary<String, String> = Dictionary<String, String>()
        for i in 0..<1000 {
            dict["key\(i)"] = "\(i)"
        }

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted)
            let outputPath = "\(STFileManager.getLibraryCachePath())/jsonData"
            let pathIsExist = STFileManager.fileExistAt(path: outputPath)
            if pathIsExist.0 {
                let path = STFileManager.create(filePath: outputPath, fileName: "json.json")
                print(outputPath)
                try jsonData.write(to: URL.init(fileURLWithPath: path), options: .atomic)
            } else {
                print(outputPath + "not exist")
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func testBtn() {
        let btn = STBtn()
        btn.backgroundColor = UIColor.orange
        btn.frame = CGRect.init(x: 10, y: 300, width: 380, height: 100)
        btn.setTitle("test001", for: .normal)
        btn.setTitleColor(UIColor.red, for: .normal)
        btn.setImage(UIImage.init(named: "Image"), for: .normal)
        btn.st_layoutButtonWithEdgeInsets(style: .bottom, imageTitleSpace: 10)
        btn.addTarget(self, action: #selector(btnClick(sender:)), for: .touchUpInside)
        self.view.addSubview(btn)
    }
    
    @objc func btnClick(sender: STBtn) {
        sender.st_layoutButtonWithEdgeInsets(style: .reset, imageTitleSpace: 0)
    }
}

extension ViewController {
    
    struct JsonModel: Codable {
        var posts: [PostModel] = [PostModel]()
    }
    
    struct PostModel: Codable {
        var permalink: String = ""
    }
    
    func parseJson() {
        if let jsonString = Bundle.main.path(forResource: "content", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: jsonString))
                let jsonModel = try JSONDecoder().decode(JsonModel.self, from: data)
                for post in jsonModel.posts {
                    print(post.permalink)
                }
            } catch {
                
            }
        }
    }
}
