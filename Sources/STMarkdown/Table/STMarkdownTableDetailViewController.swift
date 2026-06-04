//
//  STMarkdownTableDetailViewController.swift
//  STBaseProject
//
//  Created by Codex on 2026/05/21.
//

import UIKit

/// 表格全屏详情页。
/// - 通过容器旋转 90° 模拟横屏（App 为竖屏锁定，避免改全局方向支持）。
/// - 顶栏：返回 / 复制 / 下载。
/// - 长按表格弹出浮层菜单：复制 / 复制为图片 / 保存到相册。
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

    /// 横屏内容容器（旋转 90°）。顶栏 + 表格都放在这里，使用横屏逻辑尺寸布局。
    private let rotationContainer = UIView()
    private let topBar = UIView()

    private lazy var backButton: UIButton = self.makeToolButton(systemName: "chevron.left", action: #selector(self.handleBack))
    private lazy var copyButton: UIButton = self.makeToolButton(systemName: "doc.on.doc", action: #selector(self.handleCopy))
    private lazy var downloadButton: UIButton = self.makeToolButton(systemName: "square.and.arrow.down", action: #selector(self.handleDownload))
    private var copyResetWorkItem: DispatchWorkItem?
    private weak var actionMenu: STMarkdownTableActionMenu?

    private lazy var tableView: STMarkdownTableView = {
        let view = STMarkdownTableView(style: self.style)
        view.showsHeader = false
        view.isFullScreenPresentation = true
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

    public override var prefersStatusBarHidden: Bool { true }

    public override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.layoutRotatedContent()
    }

    // MARK: - Setup

    private func setupUI() {
        self.view.backgroundColor = self.style.tableBackgroundColor ?? UIColor.systemBackground

        self.rotationContainer.backgroundColor = .clear
        self.view.addSubview(self.rotationContainer)

        self.topBar.backgroundColor = .clear
        self.rotationContainer.addSubview(self.topBar)

        let buttonStack = UIStackView(arrangedSubviews: [self.copyButton, self.downloadButton])
        buttonStack.axis = .horizontal
        buttonStack.spacing = 8
        buttonStack.alignment = .center
        buttonStack.translatesAutoresizingMaskIntoConstraints = false

        self.backButton.translatesAutoresizingMaskIntoConstraints = false
        self.topBar.addSubview(self.backButton)
        self.topBar.addSubview(buttonStack)

        self.tableView.onCitationTap = self.onCitationTap
        self.rotationContainer.addSubview(self.tableView)

        NSLayoutConstraint.activate([
            self.backButton.leadingAnchor.constraint(equalTo: self.topBar.leadingAnchor),
            self.backButton.centerYAnchor.constraint(equalTo: self.topBar.centerYAnchor),
            self.backButton.widthAnchor.constraint(equalToConstant: 40),
            self.backButton.heightAnchor.constraint(equalToConstant: 40),

            buttonStack.trailingAnchor.constraint(equalTo: self.topBar.trailingAnchor),
            buttonStack.centerYAnchor.constraint(equalTo: self.topBar.centerYAnchor),
            buttonStack.heightAnchor.constraint(equalToConstant: 40)
        ])

        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(self.handleLongPress(_:)))
        self.tableView.addGestureRecognizer(longPress)
    }

    /// 将 rotationContainer 旋转为横屏，并在其中以横屏逻辑尺寸布局顶栏 + 表格。
    private func layoutRotatedContent() {
        let bounds = self.view.bounds
        // 横屏逻辑尺寸：宽高互换
        let landscapeSize = CGSize(width: bounds.height, height: bounds.width)
        self.rotationContainer.bounds = CGRect(origin: .zero, size: landscapeSize)
        self.rotationContainer.center = CGPoint(x: bounds.midX, y: bounds.midY)
        self.rotationContainer.transform = CGAffineTransform(rotationAngle: .pi / 2)

        // 安全区重映射（顺时针旋转 90°）：容器左=设备上(刘海)、容器右=设备下(Home 指示器)
        let safe = self.view.safeAreaInsets
        let leftInset = max(safe.top, 16)
        let rightInset = max(safe.bottom, 16)
        let topInset: CGFloat = 12
        let bottomInset: CGFloat = 12
        let contentWidth = landscapeSize.width - leftInset - rightInset
        let topBarHeight: CGFloat = 44

        self.topBar.frame = CGRect(x: leftInset, y: topInset, width: contentWidth, height: topBarHeight)
        let tableY = self.topBar.frame.maxY + 8
        self.tableView.frame = CGRect(
            x: leftInset,
            y: tableY,
            width: contentWidth,
            height: landscapeSize.height - tableY - bottomInset
        )
    }

    private func makeToolButton(systemName: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        button.setImage(UIImage(systemName: systemName, withConfiguration: config), for: .normal)
        button.tintColor = self.style.textColor
        button.addTarget(self, action: action, for: .touchUpInside)
        button.widthAnchor.constraint(equalToConstant: 40).isActive = true
        return button
    }

    // MARK: - Top bar actions

    @objc private func handleBack() {
        self.dismiss(animated: true)
    }

    @objc private func handleCopy() {
        UIPasteboard.general.string = self.tableViewModel.plainText()
        self.flashCopyFeedback()
    }

    @objc private func handleDownload() {
        let text = self.tableViewModel.plainText()
        guard !text.isEmpty else { return }
        self.presentShareSheet(items: [text], sourceView: self.downloadButton)
    }

    private func flashCopyFeedback() {
        self.copyResetWorkItem?.cancel()
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        self.copyButton.setImage(UIImage(systemName: "checkmark", withConfiguration: config), for: .normal)
        let workItem = DispatchWorkItem { [weak self] in
            self?.copyButton.setImage(UIImage(systemName: "doc.on.doc", withConfiguration: config), for: .normal)
        }
        self.copyResetWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2, execute: workItem)
    }

    // MARK: - Long press menu

    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        self.actionMenu?.removeFromSuperview()
        let point = gesture.location(in: self.rotationContainer)
        let menu = STMarkdownTableActionMenu(style: self.style)
        menu.onSelect = { [weak self] action in
            self?.performMenuAction(action)
        }
        menu.present(in: self.rotationContainer, at: point)
        self.actionMenu = menu
    }

    private func performMenuAction(_ action: STMarkdownTableActionMenu.Action) {
        switch action {
        case .copyText:
            UIPasteboard.general.string = self.tableViewModel.plainText()
            self.flashCopyFeedback()
        case .copyImage:
            if let image = self.tableView.renderFullTableImage() {
                UIPasteboard.general.image = image
            }
        case .saveImage:
            if let image = self.tableView.renderFullTableImage() {
                self.presentShareSheet(items: [image], sourceView: self.tableView)
            }
        }
    }

    // MARK: - Share

    private func presentShareSheet(items: [Any], sourceView: UIView) {
        let activity = UIActivityViewController(activityItems: items, applicationActivities: nil)
        if let popover = activity.popoverPresentationController {
            popover.sourceView = sourceView
            popover.sourceRect = CGRect(x: sourceView.bounds.midX, y: sourceView.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        self.present(activity, animated: true)
    }
}
