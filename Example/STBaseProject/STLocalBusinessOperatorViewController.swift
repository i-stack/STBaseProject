//
//  STLocalBusinessOperatorViewController.swift
//  STBaseProject_Example
//
//  Created by song on 2023/2/27.
//  Copyright © 2023 STBaseProject. All rights reserved.
//

import STBaseProject

class STLocalBusinessOperatorViewController: STBaseViewController {

    @IBOutlet weak var topConstraint: NSLayoutConstraint!
    @IBOutlet weak var tableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.titleLabel.text = "本地商家运营师"
        self.titleLabel.textColor = UIColor.black
        self.st_showNavBtnType(type: .showLeftBtn)
        self.leftBtn.setImage(UIImage.init(named: "left_arrow"), for: .normal)
        self.tableView.tableFooterView = UIView()
        self.topConstraint.constant = STScreenSizeConstants.st_navHeight()
        self.viewModel.requestCurrentUserCurriculum {[weak self] result in
            guard let strongSelf = self else { return }
            strongSelf.tableView.reloadData()
            strongSelf.viewModel.printChaterName()
        } failed: { error in
            
        }
        self.viewModel.downloadResources()
        print(STFileManager.getDocumentsPath())
    }

    private lazy var viewModel: STLocalBusinessOperatorViewModel = {
        let vm = STLocalBusinessOperatorViewModel()
        return vm
    }()
}

extension STLocalBusinessOperatorViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.viewModel.numberOfSections()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.numberOfRowsInSection(section: section)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = ""
        var cell = tableView.dequeueReusableCell(withIdentifier: identifier)
        if (cell == nil) {
            cell = UITableViewCell.init(style: .default, reuseIdentifier: identifier)
            cell?.selectionStyle = .none
            cell?.textLabel?.font = UIFont.st_systemFont(ofSize: 14)
            cell?.textLabel?.textColor = UIColor.lightGray
        }
        cell?.textLabel?.text = self.viewModel.cellForRowAt(indexPath: indexPath)
        return cell ?? UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 44.0
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = UIColor.clear
        let lable = UILabel()
        lable.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        lable.text = self.viewModel.titleForHeaderInSection(section: section)
        lable.lineBreakMode = .byTruncatingTail
        view.addSubview(lable)
        lable.snp.makeConstraints { make in
            make.left.equalTo(10)
            make.centerY.equalToSuperview()
            make.top.right.equalToSuperview()
        }
        return view
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let videoUrl = self.viewModel.videoUrl(indexPath: indexPath)
        self.viewModel.downloadVideo(url: videoUrl) { progress in
            
        }
    }
}

extension STLocalBusinessOperatorViewController {
    func downloadVideo(url: String) {
        
    }
}
