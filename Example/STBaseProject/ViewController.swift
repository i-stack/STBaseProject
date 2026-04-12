//  STBaseViewController_Usage_Template.swift
//  Example usage combining STBaseViewController + STBaseView


import UIKit
import STBaseProject

class ViewController: STBaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.st_setTitle("Home")
        self.st_setLeftBtn(image: UIImage(systemName: "chevron.left"), title: "返回")
        self.st_enableGradientNavigationBar(startColor: .clear, endColor: UIColor.black.withAlphaComponent(0.2))
    }
}
