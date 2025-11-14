//  STBaseViewController_Usage_Template.swift
//  Example usage combining STBaseViewController + STBaseView
//  Provides 3 page templates:
//  1. HomePage (sections + scroll)
//  2. FormPage (inputs + keyboard handling)
//  3. EmptyStatePage (loading/empty/error)

import UIKit
import STBaseProject

// MARK: - 1. Home Page Example (Sections + Scroll)
class ViewController: STBaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.st_setTitle("Home")
        self.st_setLeftBtn(image: UIImage(systemName: "chevron.left"), title: "返回")
        self.st_enableGradientNavigationBar(startColor: .clear, endColor: UIColor.black.withAlphaComponent(0.2))

        self.buildUI()
    }

    private func buildUI() {
        // Section 1
        let section1 = STSection(inset: .init(top: 20, left: 16, bottom: 0, right: 16), spacing: 12)

        let title = UILabel()
        title.text = "Welcome"
        title.font = .boldSystemFont(ofSize: 28)

        let desc = UILabel()
        desc.text = "This is a home page built with STBaseView + Sections system."
        desc.numberOfLines = 0

        section1.addViews([title, desc])

        // Section 2: buttons row
        let section2 = STSection(inset: .init(top: 30, left: 16, bottom: 0, right: 16), spacing: 16)

        let btn1 = UIButton(type: .system)
        btn1.setTitle("Go Profile", for: .normal)
        btn1.heightAnchor.constraint(equalToConstant: 48).isActive = true

        let btn2 = UIButton(type: .system)
        btn2.setTitle("Load Data", for: .normal)
        btn2.heightAnchor.constraint(equalToConstant: 48).isActive = true
        btn2.addTarget(self, action: #selector(self.loadData), for: .touchUpInside)

        section2.addViews([btn1, btn2])

        // Add sections into baseView
        self.baseView
            .st_addSection(section1)
//            .st_addSection(section2)
        
        self.baseView.st_addSection(section2)
    }

    @objc private func loadData() {
        self.baseView.st_showLoading()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.baseView.st_showEmpty("No items available")
        }
    }
    
    override func onLeftBtnTap() {
        
    }
}


// MARK: - 2. Form Page Example (Input + Keyboard Handling)
class FormPageController: STBaseViewController {

    private let nameField: UITextField = {
        let field = UITextField()
        field.placeholder = "Enter your name"
        field.borderStyle = .roundedRect
        return field
    }()

    private let emailField: UITextField = {
        let field = UITextField()
        field.placeholder = "Enter your email"
        field.borderStyle = .roundedRect
        return field
    }()

    private let submitButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Submit", for: .normal)
        btn.heightAnchor.constraint(equalToConstant: 48).isActive = true
        return btn
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.st_setTitle("Form")
        self.st_setLeftBtn(image: UIImage(systemName: "xmark"), title: "返回")
        
        self.buildFormUI()
    }

    private func buildFormUI() {
        let section = STSection(inset: .init(top: 30, left: 16, bottom: 0, right: 16), spacing: 20)
        section.addViews([self.nameField, self.emailField, self.submitButton])
        self.baseView.st_addSection(section)

        self.submitButton.addTarget(self, action: #selector(self.submit), for: .touchUpInside)
    }

    @objc private func submit() {
        self.baseView.st_showLoading()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            self.baseView.st_showError("Submission failed. Try again later.")
        }
    }
}


// MARK: - 3. Empty/Loading/Error Page Example
class EmptyStateController: STBaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.st_setTitle("State Demo")
        self.st_setLeftBtn(image: UIImage(systemName: "chevron.left"))

        self.buildButtons()
    }

    private func buildButtons() {
        let section = STSection(inset: .init(top: 40, left: 16, bottom: 0, right: 16), spacing: 20)

        let btnLoading = self.makeButton(title: "Show Loading", action: #selector(self.showLoading))
        let btnEmpty = self.makeButton(title: "Show Empty", action: #selector(self.showEmpty))
        let btnError = self.makeButton(title: "Show Error", action: #selector(self.showErrorState))

        section.addViews([btnLoading, btnEmpty, btnError])
        self.baseView.st_addSection(section)
    }

    private func makeButton(title: String, action: Selector) -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle(title, for: .normal)
        btn.heightAnchor.constraint(equalToConstant: 48).isActive = true
        btn.addTarget(self, action: action, for: .touchUpInside)
        return btn
    }

    // Actions
    @objc private func showLoading() { self.baseView.st_showLoading() }
    @objc private func showEmpty() { self.baseView.st_showEmpty("Nothing here.") }
    @objc private func showErrorState() { self.baseView.st_showError("Something went wrong.") }
}
