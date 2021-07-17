//
//  STTestViewController.swift
//  STBaseProject_Example
//
//  Created by song on 2021/1/28.
//  Copyright © 2021 STBaseProject. All rights reserved.
//

import UIKit
import STBaseProject

class STTestViewController: STBaseViewController {
    
    var executeTimer: Timer?
    var timeCount: Float = 1.0
    @IBOutlet weak var tableView: UITableView!
    
    deinit {
        print("STTestViewController dealloc")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.st_showNavBtnType(type: .showLeftBtn)
        tableView.register(UINib.init(nibName: "STTestTableViewCell", bundle: nil), forCellReuseIdentifier: "STTestTableViewCell")
    }
    
    private func beginExecute(row: Int) {
        if executeTimer == nil {
            executeTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: {[weak self] timer in
                guard let strongSelf = self else { return }
                if let cell = strongSelf.tableView.cellForRow(at: IndexPath.init(row: row, section: 0)) as? STTestTableViewCell {
                    cell.progressView.setProgress(strongSelf.timeCount * 0.1, animated: true)
                }
                strongSelf.timeCount += 1
//                if strongSelf.timeCount >= 10.0 {
//                    strongSelf.endExecute()
//                }
            })
        }
    }
    
    private func endExecute() {
        if executeTimer?.isValid ?? false {
            executeTimer?.invalidate()
            executeTimer = nil
            timeCount = 1.0
        }
    }
}

extension STTestViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "STTestTableViewCell", for: indexPath)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.beginExecute(row: indexPath.row)
    }
}
