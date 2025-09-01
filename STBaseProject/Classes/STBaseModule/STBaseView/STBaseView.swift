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
    
    // MARK: - 属性
    private var st_layoutMode: STLayoutMode = .auto
    private var st_scrollDirection: STScrollDirection = .vertical
    private var st_autoLayoutEnabled: Bool = true
    private var st_tableViewStyle: UITableView.Style = .plain
    
    // MARK: - 生命周期
    deinit {
#if DEBUG
        print("🌈 -> \(self) 🌈 ----> 🌈 dealloc")
#endif
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        st_setupBaseView()
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        st_setupBaseView()
    }
    
    // MARK: - 基础设置
    private func st_setupBaseView() {
        backgroundColor = .white
        translatesAutoresizingMaskIntoConstraints = false
    }
    
    // MARK: - 布局配置
    /// 设置布局模式
    open func st_setLayoutMode(_ mode: STLayoutMode) {
        st_layoutMode = mode
        st_updateLayout()
    }
    
    /// 设置滚动方向
    open func st_setScrollDirection(_ direction: STScrollDirection) {
        st_scrollDirection = direction
        st_updateLayout()
    }
    
    /// 启用/禁用自动布局
    open func st_setAutoLayoutEnabled(_ enabled: Bool) {
        st_autoLayoutEnabled = enabled
        st_updateLayout()
    }
    
    /// 设置TableView样式
    open func st_setTableViewStyle(_ style: UITableView.Style) {
        st_tableViewStyle = style
        if st_layoutMode == .table {
            st_updateLayout()
        }
    }
    
    // MARK: - 布局更新
    private func st_updateLayout() {
        st_clearExistingLayout()
        
        switch st_layoutMode {
        case .auto:
            st_setupAutoLayout()
        case .scroll:
            st_setupScrollViewLayout()
        case .fixed:
            st_setupFixedLayout()
        case .table:
            st_setupTableViewLayout()
        case .collection:
            st_setupCollectionViewLayout()
        }
    }
    
    private func st_clearExistingLayout() {
        subviews.forEach { $0.removeFromSuperview() }
        constraints.forEach { removeConstraint($0) }
    }
    
    // MARK: - 自动布局模式
    private func st_setupAutoLayout() {
        addSubview(st_contentView)
        
        NSLayoutConstraint.activate([
            st_contentView.topAnchor.constraint(equalTo: topAnchor),
            st_contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            st_contentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            st_contentView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        st_setupContentSizeObserver()
    }
    
    // MARK: - ScrollView布局模式
    private func st_setupScrollViewLayout() {
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
        
        st_configureScrollView()
    }
    
    // MARK: - 固定布局模式
    private func st_setupFixedLayout() {
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
    private func st_setupTableViewLayout() {
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
    private func st_setupCollectionViewLayout() {
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
    private func st_setupContentSizeObserver() {
        DispatchQueue.main.async { [weak self] in
            self?.st_checkContentSize()
        }
    }
    
    private func st_checkContentSize() {
        guard st_autoLayoutEnabled else { return }
        
        let contentSize = st_calculateContentSize()
        
        if contentSize.height > bounds.height || contentSize.width > bounds.width {
            st_switchToScrollViewMode()
        }
    }
    
    private func st_calculateContentSize() -> CGSize {
        var maxX: CGFloat = 0
        var maxY: CGFloat = 0
        
        for subview in st_contentView.subviews {
            let frame = subview.frame
            maxX = max(maxX, frame.maxX)
            maxY = max(maxY, frame.maxY)
        }
        
        return CGSize(width: maxX, height: maxY)
    }
    
    private func st_switchToScrollViewMode() {
        let currentContent = st_contentView.subviews
        
        st_layoutMode = .scroll
        st_updateLayout()
        
        for subview in currentContent {
            st_contentView.addSubview(subview)
        }
    }
    
    // MARK: - ScrollView配置
    private func st_configureScrollView() {
        st_scrollView.showsVerticalScrollIndicator = st_scrollDirection == .vertical || st_scrollDirection == .both
        st_scrollView.showsHorizontalScrollIndicator = st_scrollDirection == .horizontal || st_scrollDirection == .both
        st_scrollView.contentInsetAdjustmentBehavior = .never
        st_scrollView.bounces = true
        st_scrollView.alwaysBounceVertical = st_scrollDirection == .vertical || st_scrollDirection == .both
        st_scrollView.alwaysBounceHorizontal = st_scrollDirection == .horizontal || st_scrollDirection == .both
    }
    
    // MARK: - 公共方法
    
    /// 添加子视图到内容区域
    open func st_addSubviewToContent(_ subview: UIView) {
        switch st_layoutMode {
        case .auto, .scroll:
            st_contentView.addSubview(subview)
        case .fixed:
            addSubview(subview)
        case .table, .collection:
            print("⚠️ 警告: TableView/CollectionView模式不支持直接添加子视图")
        }
    }
    
    /// 更新内容大小
    open func st_updateContentSize() {
        st_checkContentSize()
    }
    
    /// 获取当前布局模式
    open func st_getCurrentLayoutMode() -> STLayoutMode {
        return st_layoutMode
    }
    
    /// 获取ScrollView（如果存在）
    open func st_getScrollView() -> UIScrollView? {
        return st_layoutMode == .scroll ? st_scrollView : nil
    }
    
    /// 获取内容视图
    open func st_getContentView() -> UIView {
        return st_contentView
    }
    
    /// 获取TableView（如果存在）
    open func st_getTableView() -> UITableView? {
        guard st_layoutMode == .table else { return nil }
        return st_tableViewStyle == .grouped ? st_tableViewGrouped : st_tableViewPlain
    }
    
    /// 获取CollectionView（如果存在）
    open func st_getCollectionView() -> UICollectionView? {
        return st_layoutMode == .collection ? st_collectionView : nil
    }
    
    // MARK: - 懒加载属性
    
    /// 滚动视图
    private lazy var st_scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.backgroundColor = .clear
        return scrollView
    }()
    
    /// 内容视图
    private lazy var st_contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        return view
    }()
    
    /// 分组样式TableView
    public lazy var st_tableViewGrouped: UITableView = {
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
    public lazy var st_tableViewPlain: UITableView = {
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
    public lazy var st_collectionView: UICollectionView = {
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
    
    /// 快速设置TableView代理
    public func st_setupTableView(delegate: UITableViewDelegate, dataSource: UITableViewDataSource) {
        if st_tableViewStyle == .grouped {
            st_tableViewGrouped.delegate = delegate
            st_tableViewGrouped.dataSource = dataSource
        } else {
            st_tableViewPlain.delegate = delegate
            st_tableViewPlain.dataSource = dataSource
        }
    }
    
    /// 快速设置CollectionView代理
    public func st_setupCollectionView(delegate: UICollectionViewDelegate, dataSource: UICollectionViewDataSource) {
        st_collectionView.delegate = delegate
        st_collectionView.dataSource = dataSource
    }
    
    /// 注册TableView Cell
    public func st_registerTableViewCell<T: UITableViewCell>(_ cellClass: T.Type, identifier: String? = nil) {
        let cellId = identifier ?? String(describing: cellClass)
        if st_tableViewStyle == .grouped {
            st_tableViewGrouped.register(cellClass, forCellReuseIdentifier: cellId)
        } else {
            st_tableViewPlain.register(cellClass, forCellReuseIdentifier: cellId)
        }
    }
    
    /// 注册CollectionView Cell
    public func st_registerCollectionViewCell<T: UICollectionViewCell>(_ cellClass: T.Type, identifier: String? = nil) {
        let cellId = identifier ?? String(describing: cellClass)
        st_collectionView.register(cellClass, forCellWithReuseIdentifier: cellId)
    }
}
