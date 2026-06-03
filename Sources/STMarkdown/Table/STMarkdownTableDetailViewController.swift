//
//  STMarkdownTableDetailViewController.swift
//  STBaseProject
//
//  Created by Codex on 2026/05/21.
//

import UIKit

public final class STMarkdownTableDetailViewController: UIViewController {

    public let tableViewModel: STMarkdownTableViewModel
    public let style: STMarkdownStyle
    public let collectionSize: CGSize?
    public var onCitationTap: ((String) -> Void)? {
        didSet {
            if self.isViewLoaded {
                self.tableView.onCitationTap = self.onCitationTap
            }
        }
    }

    private lazy var closeButton: UIButton = {
        let button = UIButton(type: .system)
        let imageConfig = UIImage.SymbolConfiguration(pointSize: 17, weight: .semibold)
        button.setImage(UIImage(systemName: "xmark", withConfiguration: imageConfig), for: .normal)
        button.tintColor = self.style.textColor
        button.addTarget(self, action: #selector(self.handleClose), for: .touchUpInside)
        return button
    }()

    private lazy var tableView: STMarkdownTableView = {
        let view = STMarkdownTableView(style: self.style)
        // 全屏页自带关闭按钮，关闭内置工具条，避免重复表头与“全屏中再全屏”。
        view.showsHeader = false
        view.tableData = self.tableViewModel
        return view
    }()

    public init(tableViewModel: STMarkdownTableViewModel, style: STMarkdownStyle, collectionSize: CGSize? = nil) {
        self.tableViewModel = tableViewModel
        self.style = style
        self.collectionSize = collectionSize
        super.init(nibName: nil, bundle: nil)
        self.modalPresentationStyle = .fullScreen
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard let collectionSize else { return }
        self.preferredContentSize = collectionSize
    }

    private func setupUI() {
        self.view.backgroundColor = self.style.tableBackgroundColor ?? UIColor.systemBackground
        let contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(contentView)
        self.closeButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(self.closeButton)
        self.tableView.translatesAutoresizingMaskIntoConstraints = false
        self.tableView.onCitationTap = self.onCitationTap
        contentView.addSubview(self.tableView)
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor),

            self.closeButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            self.closeButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            self.closeButton.widthAnchor.constraint(equalToConstant: 36),
            self.closeButton.heightAnchor.constraint(equalToConstant: 36),

            self.tableView.topAnchor.constraint(equalTo: self.closeButton.bottomAnchor, constant: 12),
            self.tableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            self.tableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            self.tableView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        ])
    }

    @objc private func handleClose() {
        self.dismiss(animated: true)
    }
}
