//
//  STMarkdownTableDetailViewController.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2026/05/21.
//

import UIKit

open class STMarkdownTableDetailViewController: UIViewController {
    
    public var onDismiss: (() -> Void)?
    public var onCitationTap: ((String) -> Void)? {
        didSet {
            if self.isViewLoaded {
                self.tableView.onCitationTap = self.onCitationTap
            }
        }
    }
    public var onPortraitTransitionCompleted: (() -> Void)?
    public var actionMenuItems: [STMarkdownTableActionMenuItem]
    public let style: STMarkdownStyle
    public let collectionSize: CGSize?
    public let tableViewModel: STMarkdownTableViewModel
    
    private var copyResetWorkItem: DispatchWorkItem?
    private var isRestoringPortraitForDismissal = false
    private weak var actionMenu: STMarkdownTableActionMenu?

    override public var shouldAutorotate: Bool {
        return true
    }

    override public var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return [.portrait, .landscapeRight]
    }

    override public var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return self.isRestoringPortraitForDismissal ? .portrait : .landscapeRight
    }
    
    public init(
        tableViewModel: STMarkdownTableViewModel,
        style: STMarkdownStyle,
        collectionSize: CGSize? = nil,
        actionMenuItems: [STMarkdownTableActionMenuItem] = STMarkdownTableActionMenuItem.defaultItems
    ) {
        self.tableViewModel = tableViewModel
        self.style = style
        self.collectionSize = collectionSize
        self.actionMenuItems = actionMenuItems
        super.init(nibName: nil, bundle: nil)
        self.modalPresentationStyle = .fullScreen
        STOrientationManager.shared.requestInterfaceOrientations(.landscapeRight)
    }

    @available(*, unavailable)
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        STOrientationManager.shared.requestInterfaceOrientations(.landscapeRight, in: self.view.window?.windowScene)
    }

    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        guard self.isBeingDismissed || self.navigationController?.isBeingDismissed == true else { return }
        STOrientationManager.shared.restoreDefaultInterfaceOrientations(in: self.view.window?.windowScene)
    }

    open override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        guard self.isRestoringPortraitForDismissal else { return }
        coordinator.animate(alongsideTransition: nil) { [weak self] _ in
            self?.onPortraitTransitionCompleted?()
        }
    }

    open func setupUI() {
        self.view.backgroundColor = self.style.tableBackgroundColor ?? UIColor.systemBackground

        self.rotationContainer.translatesAutoresizingMaskIntoConstraints = false
        self.rotationContainer.backgroundColor = .clear
        self.view.addSubview(self.rotationContainer)

        self.topBar.translatesAutoresizingMaskIntoConstraints = false
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
        self.tableView.translatesAutoresizingMaskIntoConstraints = false
        self.rotationContainer.addSubview(self.tableView)

        let safeArea = self.rotationContainer.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            self.rotationContainer.topAnchor.constraint(equalTo: self.view.topAnchor),
            self.rotationContainer.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.rotationContainer.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            self.rotationContainer.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),

            self.topBar.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: 12),
            self.topBar.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 16),
            self.topBar.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -16),
            self.topBar.heightAnchor.constraint(equalToConstant: 44),

            self.backButton.leadingAnchor.constraint(equalTo: self.topBar.leadingAnchor),
            self.backButton.centerYAnchor.constraint(equalTo: self.topBar.centerYAnchor),
            self.backButton.widthAnchor.constraint(equalToConstant: 40),
            self.backButton.heightAnchor.constraint(equalToConstant: 40),

            buttonStack.trailingAnchor.constraint(equalTo: self.topBar.trailingAnchor),
            buttonStack.centerYAnchor.constraint(equalTo: self.topBar.centerYAnchor),
            buttonStack.heightAnchor.constraint(equalToConstant: 40),

            self.tableView.topAnchor.constraint(equalTo: self.topBar.bottomAnchor, constant: 8),
            self.tableView.leadingAnchor.constraint(equalTo: self.topBar.leadingAnchor),
            self.tableView.trailingAnchor.constraint(equalTo: self.topBar.trailingAnchor),
            self.tableView.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor, constant: -12)
        ])

        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(self.handleLongPress(_:)))
        self.tableView.addGestureRecognizer(longPress)
        
        self.backButton.contentHorizontalAlignment = .left
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

    @objc private func handleBack() {
        self.isRestoringPortraitForDismissal = true
        self.setNeedsUpdateOfSupportedInterfaceOrientations()
        if let onDismiss {
            onDismiss()
            return
        }
        STOrientationManager.shared.restoreDefaultInterfaceOrientations(in: self.view.window?.windowScene)
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

    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        self.actionMenu?.removeFromSuperview()
        let point = gesture.location(in: self.rotationContainer)
        let menu = STMarkdownTableActionMenu(style: self.style, items: self.actionMenuItems)
        menu.onSelect = { [weak self] action in
            self?.performMenuAction(action)
        }
        menu.present(in: self.rotationContainer, at: point)
        self.actionMenu = menu
    }

    private func performMenuAction(_ action: STMarkdownTableAction) {
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

    private func presentShareSheet(items: [Any], sourceView: UIView) {
        let activity = UIActivityViewController(activityItems: items, applicationActivities: nil)
        if let popover = activity.popoverPresentationController {
            popover.sourceView = sourceView
            popover.sourceRect = CGRect(x: sourceView.bounds.midX, y: sourceView.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        self.present(activity, animated: true)
    }
    
    /// 横屏内容容器。顶栏 + 表格都放在这里，跟随系统横屏 bounds 布局。
    public lazy var rotationContainer: UIView = {
        let view = UIView()
        return view
    }()
    
    public lazy var topBar: UIView = {
        let view = UIView()
        return view
    }()
    
    public lazy var backButton: UIButton = {
        return self.makeToolButton(systemName: "chevron.left", action: #selector(self.handleBack))
    }()
    
    public lazy var copyButton: UIButton = {
        return self.makeToolButton(systemName: "doc.on.doc", action: #selector(self.handleCopy))
    }()
    
    public lazy var downloadButton: UIButton = {
        return self.makeToolButton(systemName: "square.and.arrow.down", action: #selector(self.handleDownload))
    }()
    
    public lazy var tableView: STMarkdownTableView = {
        let view = STMarkdownTableView(style: self.style)
        view.showsHeader = false
        view.isFullScreenPresentation = true
        view.tableData = self.tableViewModel
        return view
    }()
}
