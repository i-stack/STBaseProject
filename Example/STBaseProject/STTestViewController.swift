//
//  STTestViewController.swift
//  STBaseProject
//
//  Created for comprehensive testing of STBaseView and STBaseViewController.
//

import UIKit
import STBaseProject

class STTestViewController: STBaseViewController {

    // MARK: - Test Modes
    private enum TestMode: String, CaseIterable {
        case scrollVertical = "Scroll 垂直"
        case scrollHorizontal = "Scroll 水平"
        case scrollBoth = "Scroll 双向"
        case fixed = "Fixed 固定"
        case table = "Table 表格"
        case collection = "Collection 集合"
        case section = "Section 分段"
        case stateLoading = "状态页-加载"
        case stateEmpty = "状态页-空"
        case keyboard = "键盘处理"
        case fluentAPI = "链式 API"
    }

    private var currentMode: TestMode = .scrollVertical
    private var dataSource: [String] = (0..<30).map { "数据项 \($0)" }
    override func viewDidLoad() {
        self.navBarBackgroundColor = UIColor.systemIndigo.withAlphaComponent(0.2)
        self.navBarTitleFont = UIFont.systemFont(ofSize: 18, weight: .semibold)
        self.navBarTitleColor = .systemPurple
        self.buttonTitleColor = .systemOrange
        self.statusBarStyle = .lightContent

        super.viewDidLoad()

        self.configureNavigationBarElements()
        self.configureGestureForHeightToggle()
        self.applyTestMode(.scrollVertical)
    }

    private func configureNavigationBarElements() {
        self.st_setTitle("STBaseView 全面测试")
            .st_setNavigationBarColor(UIColor.systemTeal.withAlphaComponent(0.15))
            .st_setNavigationBarHeight(104)

        if #available(iOS 13.0, *) {
            self.st_setLeftBtn(image: UIImage(systemName: "chevron.left"), title: "返回")
            self.st_setRightBtn(image: UIImage(systemName: "list.bullet"), title: "测试菜单")
        } else {
            self.st_setLeftBtn(title: "返回")
            self.st_setRightBtn(title: "测试菜单")
        }

        self.leftBtn.contentEdgeInsets = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
        self.leftBtn.titleEdgeInsets = UIEdgeInsets(top: 0, left: 6, bottom: 0, right: -6)
        self.rightBtn.contentEdgeInsets = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
        self.rightBtn.titleEdgeInsets = UIEdgeInsets(top: 0, left: 6, bottom: 0, right: -6)

        self.st_enableGradientNavigationBar(startColor: UIColor.systemPurple.withAlphaComponent(0.6),
                                            endColor: UIColor.systemBlue.withAlphaComponent(0.6))
    }

    // MARK: - Test Mode Application
    private func applyTestMode(_ mode: TestMode) {
        self.currentMode = mode
        self.removeExistingContent()
        self.baseView.st_hideAllStates()

        switch mode {
        case .scrollVertical:
            self.testScrollMode(.vertical)
        case .scrollHorizontal:
            self.testScrollMode(.horizontal)
        case .scrollBoth:
            self.testScrollMode(.both)
        case .fixed:
            self.testFixedMode()
        case .table:
            self.testTableMode()
        case .collection:
            self.testCollectionMode()
        case .section:
            self.testSectionSystem()
        case .stateLoading:
            self.testStateLoading()
        case .stateEmpty:
            self.testStateEmpty()
        case .keyboard:
            self.testKeyboardHandling()
        case .fluentAPI:
            self.testFluentAPI()
        }
    }

    // MARK: - Test Implementations

    private func testScrollMode(_ direction: STScrollDirection) {
        let scrollView = self.baseView.configureAsScroll(direction)
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.backgroundColor = .systemBackground
        self.st_linkScrollAlpha(scrollView)

        let container = self.baseView.contentContainer()
        let contentView = self.createScrollContentView(direction: direction)
        container.addSubview(contentView)

        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: container.topAnchor, constant: self.navBarHeight + 20),
            contentView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -20)
        ])

        // 测试 st_setBottomConstraintForLastSubview
        self.baseView.st_setBottomConstraintForLastSubview(contentView, offset: -20)

        // 验证底部约束
        self.baseView.st_validateBottomConstraintLogging()
    }

    private func createScrollContentView(direction: STScrollDirection) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = .secondarySystemBackground

        let stack = UIStackView()
        stack.axis = direction == .horizontal ? .horizontal : .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(stack)

        let titleLabel = UILabel()
        titleLabel.numberOfLines = 0
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        titleLabel.text = "Scroll 模式测试 - \(direction == .vertical ? "垂直" : direction == .horizontal ? "水平" : "双向")"
        stack.addArrangedSubview(titleLabel)

        for i in 0..<15 {
            let label = UILabel()
            label.numberOfLines = 0
            label.font = UIFont.systemFont(ofSize: 14)
            label.textColor = .secondaryLabel
            if direction == .horizontal {
                label.text = "横向内容 \(i + 1)"
                label.widthAnchor.constraint(equalToConstant: 200).isActive = true
            } else {
                label.text = "纵向内容 \(i + 1)：测试 st_addContentSubview 和 contentContainer API。滚动观察导航栏透明度变化。"
            }
            stack.addArrangedSubview(label)
        }

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -20)
        ])

        if direction == .horizontal {
            container.widthAnchor.constraint(greaterThanOrEqualToConstant: 3000).isActive = true
        }

        return container
    }

    private func testFixedMode() {
        self.baseView.configure(layoutMode: .fixed)
        let container = self.baseView.contentContainer()

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 20
        stack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(stack)

        let titleLabel = UILabel()
        titleLabel.numberOfLines = 0
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        titleLabel.text = "Fixed 模式测试"
        stack.addArrangedSubview(titleLabel)

        let descLabel = UILabel()
        descLabel.numberOfLines = 0
        descLabel.font = UIFont.systemFont(ofSize: 14)
        descLabel.text = "Fixed 模式使用固定容器，不支持滚动。适合内容固定且不超出屏幕的场景。"
        stack.addArrangedSubview(descLabel)

        for i in 0..<5 {
            let view = UIView()
            view.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.2)
            view.translatesAutoresizingMaskIntoConstraints = false
            view.heightAnchor.constraint(equalToConstant: 60).isActive = true
            stack.addArrangedSubview(view)

            let label = UILabel()
            label.text = "固定内容块 \(i + 1)"
            label.textAlignment = .center
            label.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(label)
            NSLayoutConstraint.activate([
                label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
            ])
        }

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: self.navBarHeight + 20),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20)
        ])
    }

    private func testTableMode() {
        self.baseView.configure(layoutMode: .table)
        guard let tableView = self.baseView.st_getTableView() else { return }
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = .systemBackground
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        tableView.tableFooterView = UIView()
        tableView.reloadData()

        self.st_linkScrollAlpha(tableView)
    }

    private func testCollectionMode() {
        self.baseView.configure(layoutMode: .collection)
        guard let collectionView = self.baseView.st_getCollectionView() else { return }
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = .systemBackground
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        collectionView.reloadData()

        self.st_linkScrollAlpha(collectionView)
    }

    private func testSectionSystem() {
        let scrollView = self.baseView.configureAsScroll(.vertical)
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.backgroundColor = .systemBackground
        self.st_linkScrollAlpha(scrollView)

        // 测试 STSection
        let section1 = STSection(inset: UIEdgeInsets(top: 16, left: 20, bottom: 16, right: 20), spacing: 12)
        let title1 = UILabel()
        title1.text = "Section 1 - 标题区域"
        title1.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        section1.addView(title1)

        for i in 0..<3 {
            let label = UILabel()
            label.text = "Section 1 内容项 \(i + 1)"
            label.font = UIFont.systemFont(ofSize: 14)
            section1.addView(label)
        }

        let section2 = STSection(inset: UIEdgeInsets(top: 16, left: 20, bottom: 16, right: 20), spacing: 8)
        let title2 = UILabel()
        title2.text = "Section 2 - 动态间距"
        title2.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        section2.addView(title2)

        let views = (0..<4).map { i -> UILabel in
            let label = UILabel()
            label.text = "Section 2 内容 \(i + 1)"
            label.font = UIFont.systemFont(ofSize: 14)
            return label
        }
        section2.addViews(views)

        // 测试动态修改
        section2.setSpacing(16)
        section2.setInset(UIEdgeInsets(top: 20, left: 24, bottom: 20, right: 24))

        self.baseView.st_addSection(section1)
        self.baseView.st_addSection(section2)

        // 添加最后一个 section 用于测试底部约束
        let section3 = STSection(inset: UIEdgeInsets(top: 16, left: 20, bottom: 16, right: 20), spacing: 12)
        let title3 = UILabel()
        title3.text = "Section 3 - 底部区域"
        title3.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        section3.addView(title3)
        self.baseView.st_addSection(section3)
        
        // 设置最后一个 section 的底部约束
        let container = self.baseView.contentContainer()
        if let lastSection = container.subviews.last {
            self.baseView.st_setBottomConstraintForLastSubview(lastSection, offset: -20)
        }
    }

    private func testStateLoading() {
        self.baseView.st_showLoading()
    }

    private func testStateEmpty() {
        self.baseView.st_showEmpty("暂无数据，请稍后再试")
    }

    private func testKeyboardHandling() {
        let scrollView = self.baseView.configureAsScroll(.vertical)
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.backgroundColor = .systemBackground
        self.st_linkScrollAlpha(scrollView)

        let container = self.baseView.contentContainer()
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 20
        stack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(stack)

        let titleLabel = UILabel()
        titleLabel.text = "键盘处理测试"
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        stack.addArrangedSubview(titleLabel)

        let descLabel = UILabel()
        descLabel.numberOfLines = 0
        descLabel.text = "点击下方输入框，键盘弹出时 STBaseView 会自动调整 contentInset。"
        stack.addArrangedSubview(descLabel)

        for i in 0..<3 {
            let textField = UITextField()
            textField.placeholder = "输入框 \(i + 1)"
            textField.borderStyle = .roundedRect
            textField.translatesAutoresizingMaskIntoConstraints = false
            textField.heightAnchor.constraint(equalToConstant: 44).isActive = true
            stack.addArrangedSubview(textField)
        }

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: self.navBarHeight + 20),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -20)
        ])
    }

    private func testFluentAPI() {
        self.baseView
            .st_layoutMode(.scroll)
            .st_scrollDirection(.vertical)
            .st_backgroundColor(.systemBackground)
        
        let scrollView = self.baseView.configureAsScroll(.vertical)
        scrollView.contentInsetAdjustmentBehavior = .never
        self.st_linkScrollAlpha(scrollView)

        // 测试 st_onContent
        self.baseView.st_onContent { container in
            let label = UILabel()
            label.numberOfLines = 0
            label.text = """
            链式 API 测试：
            - st_layoutMode(.scroll)
            - st_scrollDirection(.vertical)
            - st_backgroundColor(.systemBackground)
            - st_onContent { container in ... }
            """
            label.font = UIFont.systemFont(ofSize: 16)
            label.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(label)

            NSLayoutConstraint.activate([
                label.topAnchor.constraint(equalTo: container.topAnchor, constant: self.navBarHeight + 20),
                label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
                label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20)
            ])
        }
    }

    // MARK: - Helper Methods

    private func removeExistingContent() {
        let container = self.baseView.contentContainer()
        container.subviews.forEach { $0.removeFromSuperview() }
    }

    private func configureGestureForHeightToggle() {
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(self.onDoubleTap))
        doubleTap.numberOfTapsRequired = 2
        self.view.addGestureRecognizer(doubleTap)
    }

    @objc private func onDoubleTap() {
        let heightToggle = !(self.navBarHeight > 100)
        let newHeight: CGFloat = heightToggle ? 120 : 88
        self.st_setNavigationBarHeight(newHeight)
    }

    // MARK: - Button Actions

    override func onLeftBtnTap() {
        super.onLeftBtnTap()
    }

    override func onRightBtnTap() {
        let sheet = UIAlertController(title: "选择测试模式", message: "测试 STBaseView 各项功能", preferredStyle: .actionSheet)
        
        for mode in TestMode.allCases {
            let isSelected = mode == self.currentMode
            let title = isSelected ? "✓ \(mode.rawValue)" : mode.rawValue
            sheet.addAction(UIAlertAction(title: title, style: .default, handler: { [weak self] _ in
                self?.applyTestMode(mode)
            }))
        }
        
        sheet.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
        
        if let pop = sheet.popoverPresentationController {
            pop.sourceView = self.rightBtn
            pop.sourceRect = self.rightBtn.bounds
        }
        
        self.present(sheet, animated: true, completion: nil)
    }
}

// MARK: - UITableViewDataSource & Delegate
extension STTestViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dataSource.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let reuseId = "st_table_cell"
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseId) ??
            UITableViewCell(style: .subtitle, reuseIdentifier: reuseId)
        cell.textLabel?.text = self.dataSource[indexPath.row]
        cell.detailTextLabel?.text = "STBaseView table 模式 - 滚动联动导航栏透明度"
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - UICollectionViewDataSource & Delegate
extension STTestViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.dataSource.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
        cell.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.2)
        cell.layer.cornerRadius = 8

        // 移除旧的 label
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }

        let label = UILabel()
        label.text = self.dataSource[indexPath.item]
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 14)
        label.translatesAutoresizingMaskIntoConstraints = false
        cell.contentView.addSubview(label)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: cell.contentView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor)
        ])

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.bounds.width - 60) / 2
        return CGSize(width: width, height: 80)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 20
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 20
    }
}
