//
//  STBaseView.swift
//  STBaseProject
//
//  Created by stack on 2018/3/14.
//

import UIKit

// MARK: - 布局模式枚举
public enum STLayoutMode {
    case auto           // 自动检测是否需要滚动
    case scroll         // 强制使用ScrollView
    case fixed          // 固定布局，不滚动
    case table          // 使用TableView布局
    case collection     // 使用CollectionView布局
}

// MARK: - 滚动方向
public enum STScrollDirection {
    case vertical       // 垂直滚动
    case horizontal     // 水平滚动
    case both           // 双向滚动
    case none           // 不滚动
}

open class STBaseView: UIView {
    
    private var layoutMode: STLayoutMode = .auto
    private var scrollDirection: STScrollDirection = .vertical
    private var autoLayoutEnabled: Bool = true
    private var tableViewStyle: UITableView.Style = .plain
    private var isFromXIB: Bool = false
    private var xibSubviews: [UIView] = []
    private var xibConstraints: [NSLayoutConstraint] = []
    
    deinit {
#if DEBUG
        print("🌈 -> \(self) 🌈 ----> 🌈 dealloc")
#endif
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupBaseView()
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        isFromXIB = true
        setupBaseView()
    }
    
    open override func awakeFromNib() {
        super.awakeFromNib()
        preserveXIBContent()
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.setupXIBLayout()
        }
    }
    
    private func preserveXIBContent() {
        xibSubviews = subviews.map { $0 }
        xibConstraints = constraints.map { $0 }
    }
    
    private func setupXIBLayout() {
        if layoutMode == .auto {
            layoutMode = .fixed
        }
        if layoutMode == .scroll {
            setupScrollViewLayout()
        }
    }
    
    
    private func setupBaseView() {
        backgroundColor = .white
        translatesAutoresizingMaskIntoConstraints = false
    }
    
    // MARK: - 布局配置
    /// 设置布局模式
    open func st_setLayoutMode(_ mode: STLayoutMode) {
        layoutMode = mode
        if isFromXIB {
            print("✅ XIB模式：布局模式设置为 \(mode)，保持原始布局")
        } else {
            updateLayout()
        }
    }
    
    /// 为XIB模式设置布局模式（推荐在viewDidLoad中调用）
    open func st_setLayoutModeForXIB(_ mode: STLayoutMode) {
        guard isFromXIB else {
            print("⚠️ 警告: 此方法仅适用于来自XIB的STBaseView")
            return
        }
        layoutMode = mode
        if mode == .scroll {
            setupScrollViewLayout()
        }
    }
    
    /// 设置滚动方向
    open func st_setScrollDirection(_ direction: STScrollDirection) {
        scrollDirection = direction
        updateLayout()
    }
    
    /// 启用/禁用自动布局
    open func st_setAutoLayoutEnabled(_ enabled: Bool) {
        autoLayoutEnabled = enabled
        updateLayout()
    }
    
    /// 设置TableView样式
    open func st_setTableViewStyle(_ style: UITableView.Style) {
        tableViewStyle = style
        if layoutMode == .table {
            updateLayout()
        }
    }
    
    // MARK: - 布局更新
    private func updateLayout() {
        if isFromXIB {
            print("✅ XIB模式：保持原始布局，不进行更新")
            return
        }
        clearExistingLayout()
        switch layoutMode {
        case .auto:
            setupAutoLayout()
        case .scroll:
            setupScrollViewLayout()
        case .fixed:
            setupFixedLayout()
        case .table:
            setupTableViewLayout()
        case .collection:
            setupCollectionViewLayout()
        }
    }
    
    private func clearExistingLayout() {
        subviews.forEach { $0.removeFromSuperview() }
        constraints.forEach { removeConstraint($0) }
    }
    
    // MARK: - 自动布局模式
    private func setupAutoLayout() {
        addSubview(contentView)
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: topAnchor),
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        setupContentSizeObserver()
    }
    
    // MARK: - ScrollView布局模式
    private func setupScrollViewLayout() {
        guard let scrollView = st_getScrollView() else { return }
        addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        let contentView = st_getContentView()
        scrollView.addSubview(contentView)
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
        if isFromXIB {
            for subview in xibSubviews {
                if subview.superview == self {
                    contentView.addSubview(subview)
                }
            }
            // 重新设置约束，将原来相对于STBaseView的约束改为相对于contentView
            updateXIBConstraintsForScrollView(contentView: contentView)
            // 设置contentView的最小高度，确保ScrollView可以滚动
            setupContentViewSizeForXIB(contentView: contentView)
        }
        configureScrollView()
    }
    
    private func updateXIBConstraintsForScrollView(contentView: UIView) {
        for constraint in xibConstraints {
            if let firstView = constraint.firstItem as? UIView,
               let secondView = constraint.secondItem as? UIView {
                if firstView == self || secondView == self {
                    constraint.isActive = false
                    let newConstraint: NSLayoutConstraint
                    if firstView == self {
                        newConstraint = NSLayoutConstraint(
                            item: contentView,
                            attribute: constraint.firstAttribute,
                            relatedBy: constraint.relation,
                            toItem: secondView,
                            attribute: constraint.secondAttribute,
                            multiplier: constraint.multiplier,
                            constant: constraint.constant
                        )
                    } else {
                        newConstraint = NSLayoutConstraint(
                            item: firstView,
                            attribute: constraint.firstAttribute,
                            relatedBy: constraint.relation,
                            toItem: contentView,
                            attribute: constraint.secondAttribute,
                            multiplier: constraint.multiplier,
                            constant: constraint.constant
                        )
                    }
                    newConstraint.isActive = true
                }
            }
        }
    }
    
    private func setupContentViewSizeForXIB(contentView: UIView) {
        var maxHeight: CGFloat = 0
        for subview in xibSubviews {
            let frame = subview.frame
            maxHeight = max(maxHeight, frame.maxY)
        }
        let minHeight = max(maxHeight, bounds.height)
        contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: minHeight).isActive = true
        print("📏 XIB ContentView尺寸设置: 最小高度 = \(minHeight)")
        print("📊 XIB子视图最大Y坐标: \(maxHeight)")
    }
    
    // MARK: - 固定布局模式
    private func setupFixedLayout() {
        let contentView = st_getContentView()
        addSubview(contentView)
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: topAnchor),
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    // MARK: - TableView布局模式
    private func setupTableViewLayout() {
        guard let tableView = st_getTableView() else { return }
        addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: topAnchor),
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    // MARK: - CollectionView布局模式
    private func setupCollectionViewLayout() {
        guard let collectionView = st_getCollectionView() else { return }
        addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    // MARK: - 内容大小观察
    private func setupContentSizeObserver() {
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.checkContentSize()
        }
    }
    
    private func checkContentSize() {
        guard autoLayoutEnabled else { return }
        let contentSize = calculateContentSize()
        if contentSize.height > bounds.height || contentSize.width > bounds.width {
            switchToScrollViewMode()
        }
    }
    
    private func calculateContentSize() -> CGSize {
        var maxX: CGFloat = 0
        var maxY: CGFloat = 0
        for subview in contentView.subviews {
            let frame = subview.frame
            maxX = max(maxX, frame.maxX)
            maxY = max(maxY, frame.maxY)
        }
        return CGSize(width: maxX, height: maxY)
    }
    
    private func switchToScrollViewMode() {
        let currentContent = contentView.subviews
        layoutMode = .scroll
        updateLayout()
        for subview in currentContent {
            contentView.addSubview(subview)
        }
    }
    
    // MARK: - ScrollView配置
    private func configureScrollView() {
        scrollView.bounces = true
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.alwaysBounceVertical = scrollDirection == .vertical || scrollDirection == .both
        scrollView.alwaysBounceHorizontal = scrollDirection == .horizontal || scrollDirection == .both
        scrollView.showsVerticalScrollIndicator = scrollDirection == .vertical || scrollDirection == .both
        scrollView.showsHorizontalScrollIndicator = scrollDirection == .horizontal || scrollDirection == .both
    }
    
    // MARK: - 公共方法
    
    /// 添加子视图到内容区域
    open func st_addSubviewToContent(_ subview: UIView) {
        if isFromXIB {
            if layoutMode == .scroll {
                let contentView = st_getContentView()
                contentView.addSubview(subview)
            } else {
                addSubview(subview)
            }
            return
        }
        switch layoutMode {
        case .auto, .scroll:
            contentView.addSubview(subview)
        case .fixed:
            addSubview(subview)
        case .table, .collection:
            print("⚠️ 警告: TableView/CollectionView模式不支持直接添加子视图")
        }
    }
    
    /// 安全地添加约束，确保约束引用的是同一个视图层次结构
    open func st_addConstraintSafely(_ constraint: NSLayoutConstraint) {
        if let firstView = constraint.firstItem as? UIView,
           let secondView = constraint.secondItem as? UIView {
            if firstView.isDescendant(of: self) && secondView.isDescendant(of: self) {
                NSLayoutConstraint.activate([constraint])
            } else {
                print("⚠️ 警告: 约束引用了不同视图层次结构中的视图，跳过此约束")
            }
        } else {
            NSLayoutConstraint.activate([constraint])
        }
    }
    
    /// 更新内容大小
    open func st_updateContentSize() {
        checkContentSize()
    }
    
    /// 获取当前布局模式
    open func st_getCurrentLayoutMode() -> STLayoutMode {
        return layoutMode
    }
    
    /// 获取ScrollView（如果存在）
    open func st_getScrollView() -> UIScrollView? {
        return layoutMode == .scroll ? scrollView : nil
    }
    
    /// 获取内容视图
    open func st_getContentView() -> UIView {
        return contentView
    }
    
    /// 获取TableView（如果存在）
    open func st_getTableView() -> UITableView? {
        guard layoutMode == .table else { return nil }
        return tableViewStyle == .grouped ? tableViewGrouped : tableViewPlain
    }
    
    /// 获取CollectionView（如果存在）
    open func st_getCollectionView() -> UICollectionView? {
        return layoutMode == .collection ? collectionView : nil
    }
    
    /// 检查是否来自XIB
    open func st_isFromXIB() -> Bool {
        return isFromXIB
    }
    
    /// 获取XIB中的子视图
    open func st_getXIBSubviews() -> [UIView] {
        return xibSubviews
    }
        
    /// 滚动视图
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.backgroundColor = .clear
        return scrollView
    }()
    
    /// 内容视图
    private lazy var contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        return view
    }()
    
    /// 分组样式TableView
    public lazy var tableViewGrouped: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.tableFooterView = UIView()
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 44
        return tableView
    }()
    
    /// 普通样式TableView
    public lazy var tableViewPlain: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.tableFooterView = UIView()
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 44
        return tableView
    }()
    
    /// CollectionView
    public lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        return collectionView
    }()
}

// MARK: - 便捷扩展
extension STBaseView {
    
    public func st_setupTableView(delegate: UITableViewDelegate, dataSource: UITableViewDataSource) {
        if tableViewStyle == .grouped {
            tableViewGrouped.delegate = delegate
            tableViewGrouped.dataSource = dataSource
        } else {
            tableViewPlain.delegate = delegate
            tableViewPlain.dataSource = dataSource
        }
    }
    
    public func st_setupCollectionView(delegate: UICollectionViewDelegate, dataSource: UICollectionViewDataSource) {
        collectionView.delegate = delegate
        collectionView.dataSource = dataSource
    }
    
    public func st_registerTableViewCell<T: UITableViewCell>(_ cellClass: T.Type, identifier: String? = nil) {
        let cellId = identifier ?? String(describing: cellClass)
        if tableViewStyle == .grouped {
            tableViewGrouped.register(cellClass, forCellReuseIdentifier: cellId)
        } else {
            tableViewPlain.register(cellClass, forCellReuseIdentifier: cellId)
        }
    }
    
    public func st_registerCollectionViewCell<T: UICollectionViewCell>(_ cellClass: T.Type, identifier: String? = nil) {
        let cellId = identifier ?? String(describing: cellClass)
        collectionView.register(cellClass, forCellWithReuseIdentifier: cellId)
    }
}
