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

open class STBaseView: UIView, UIScrollViewDelegate {

    private var isFromXIB: Bool = false
    private var xibSubviews: [UIView] = []
    private var xibConstraints: [NSLayoutConstraint] = []
    
    private var autoLayoutEnabled: Bool = true
    private var layoutMode: STLayoutMode = .auto
    private var tableViewStyle: UITableView.Style = .plain
    private var scrollDirection: STScrollDirection = .vertical

    deinit {
#if DEBUG
        print("🌈 -> \(self) 🌈 ----> 🌈 dealloc")
#endif
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupBaseView()
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        self.isFromXIB = true
        self.setupBaseView()
    }
    
    open override func awakeFromNib() {
        super.awakeFromNib()
        self.preserveXIBContent()
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.setupXIBLayout()
        }
    }
    
    private func preserveXIBContent() {
        self.xibSubviews = subviews.map { $0 }
        self.xibConstraints = constraints.map { $0 }
    }
    
    private func setupXIBLayout() {
        if self.layoutMode == .auto {
            self.layoutMode = .fixed
        }
        if self.layoutMode == .scroll {
            self.setupScrollViewLayout()
        }
    }
    
    private func setupBaseView() {
        self.backgroundColor = .white
        self.translatesAutoresizingMaskIntoConstraints = false
        self.setupDefaultAutoScroll()
    }
    
    /// 默认自动滚动配置（子类可重写来自定义或禁用）
    /// 
    /// ⚠️ 重要提醒：
    /// 1. 使用自动滚动时，请确保为最后一个子视图设置底部约束
    /// 2. 将子视图添加到 contentView 而不是直接添加到 STBaseView
    /// 3. 示例：make.bottom.equalTo(-20) // 设置底部约束
    @objc open func setupDefaultAutoScroll() {
        // 默认启用自动布局检测
        self.st_setAutoLayoutEnabled(true)
        // 默认使用自动模式，会根据内容高度自动决定是否滚动
        self.st_setLayoutMode(.auto)
        // 默认垂直滚动
        self.st_setScrollDirection(.vertical)
    }
    
    /// 设置布局模式
    open func st_setLayoutMode(_ mode: STLayoutMode) {
        self.layoutMode = mode
        if !isFromXIB {
            self.updateLayout()
        }
    }
    
    /// 为XIB模式设置布局模式（推荐在viewDidLoad中调用）
    open func st_setLayoutModeForXIB(_ mode: STLayoutMode) {
        guard self.isFromXIB else {
            print("⚠️ 警告: 此方法仅适用于来自XIB的STBaseView")
            return
        }
        self.layoutMode = mode
        if mode == .scroll {
            self.setupScrollViewLayout()
        }
    }
    
    /// 设置滚动方向
    open func st_setScrollDirection(_ direction: STScrollDirection) {
        self.scrollDirection = direction
        self.updateLayout()
    }
    
    /// 启用/禁用自动布局
    open func st_setAutoLayoutEnabled(_ enabled: Bool) {
        self.autoLayoutEnabled = enabled
        self.updateLayout()
    }
    
    /// 设置TableView样式
    open func st_setTableViewStyle(_ style: UITableView.Style) {
        self.tableViewStyle = style
        if self.layoutMode == .table {
            self.updateLayout()
        }
    }
    
    // MARK: - 布局更新
    private func updateLayout() {
        if self.isFromXIB {
            print("✅ XIB模式：保持原始布局，不进行更新")
            return
        }
        self.clearExistingLayout()
        switch self.layoutMode {
        case .auto:
            self.setupAutoLayout()
        case .scroll:
            self.setupScrollViewLayout()
        case .fixed:
            self.setupFixedLayout()
        case .table:
            self.setupTableViewLayout()
        case .collection:
            self.setupCollectionViewLayout()
        }
    }
    
    private func clearExistingLayout() {
        self.subviews.forEach { $0.removeFromSuperview() }
        self.constraints.forEach { removeConstraint($0) }
    }
    
    // MARK: - 自动布局模式
    private func setupAutoLayout() {
        self.addSubview(self.contentView)
        NSLayoutConstraint.activate([
            self.contentView.topAnchor.constraint(equalTo: topAnchor),
            self.contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            self.contentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            self.contentView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        self.setupContentSizeObserver()
    }
    
    // MARK: - ScrollView布局模式
    private func setupScrollViewLayout() {
        guard let scrollView = self.st_getScrollView() else { return }
        self.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        let contentView = self.st_getContentView()
        scrollView.addSubview(contentView)
        
        let topConstraint = contentView.topAnchor.constraint(equalTo: scrollView.topAnchor)
        let leadingConstraint = contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor)
        let trailingConstraint = contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor)
        let bottomConstraint = contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor)
        let widthConstraint = contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        
        topConstraint.priority = UILayoutPriority(1000)
        leadingConstraint.priority = UILayoutPriority(1000)
        trailingConstraint.priority = UILayoutPriority(1000)
        widthConstraint.priority = UILayoutPriority(1000)
        
        NSLayoutConstraint.activate([
            topConstraint,
            leadingConstraint,
            trailingConstraint,
            bottomConstraint,
            widthConstraint
        ])
        if self.isFromXIB {
            for subview in self.xibSubviews {
                if subview.superview == self {
                    self.contentView.addSubview(subview)
                }
            }
            // 重新设置约束，将原来相对于STBaseView的约束改为相对于contentView
            self.updateXIBConstraintsForScrollView(contentView: contentView)
            // 设置contentView的最小高度，确保ScrollView可以滚动
            self.setupContentViewSizeForXIB(contentView: contentView)
        }
        self.configureScrollView()
    }
    
    private func updateXIBConstraintsForScrollView(contentView: UIView) {
        for constraint in self.xibConstraints {
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
        for subview in self.xibSubviews {
            let frame = subview.frame
            maxHeight = max(maxHeight, frame.maxY)
        }
        let minHeight = max(maxHeight, bounds.height)
        contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: minHeight).isActive = true
    }
    
    // MARK: - 固定布局模式
    private func setupFixedLayout() {
        let contentView = self.st_getContentView()
        self.addSubview(contentView)
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: topAnchor),
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    // MARK: - TableView布局模式
    private func setupTableViewLayout() {
        guard let tableView = self.st_getTableView() else { return }
        self.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: topAnchor),
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    // MARK: - CollectionView布局模式
    private func setupCollectionViewLayout() {
        guard let collectionView = self.st_getCollectionView() else { return }
        self.addSubview(collectionView)
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
        guard self.autoLayoutEnabled else { return }
        let contentSize = self.calculateContentSize()
        
        #if DEBUG
        self.validateBottomConstraints()
        #endif
        
        if contentSize.height > bounds.height || contentSize.width > bounds.width {
            self.switchToScrollViewMode()
        }
    }
    
    private func calculateContentSize() -> CGSize {
        var maxX: CGFloat = 0
        var maxY: CGFloat = 0
        for subview in self.contentView.subviews {
            let frame = subview.frame
            maxX = max(maxX, frame.maxX)
            maxY = max(maxY, frame.maxY)
        }
        return CGSize(width: maxX, height: maxY)
    }
    
    private func switchToScrollViewMode() {
        let currentContent = self.contentView.subviews
        self.layoutMode = .scroll
        self.updateLayout()
        for subview in currentContent {
            self.contentView.addSubview(subview)
        }
    }
    
    // MARK: - ScrollView配置
    private func configureScrollView() {
        self.scrollView.bounces = true
        self.scrollView.alwaysBounceVertical = self.scrollDirection == .vertical || self.scrollDirection == .both
        self.scrollView.alwaysBounceHorizontal = self.scrollDirection == .horizontal || self.scrollDirection == .both
        self.scrollView.showsVerticalScrollIndicator = self.scrollDirection == .vertical || self.scrollDirection == .both
        self.scrollView.showsHorizontalScrollIndicator = self.scrollDirection == .horizontal || self.scrollDirection == .both
        
        if self.isFromXIB {
            self.scrollView.contentInsetAdjustmentBehavior = .never
            self.scrollView.automaticallyAdjustsScrollIndicatorInsets = false
        } else {
            self.scrollView.contentInsetAdjustmentBehavior = .automatic
        }
    }
        
    /// 添加子视图到内容区域
    /// 
    /// ⚠️ 重要提醒：
    /// 1. 添加子视图后，请确保设置正确的约束
    /// 2. 最后一个子视图必须设置底部约束：make.bottom.equalTo(-20)
    /// 3. 使用 st_validateConstraints() 检查约束设置
    open func st_addSubviewToContent(_ subview: UIView) {
        if self.isFromXIB {
            if self.layoutMode == .scroll {
                let contentView = self.st_getContentView()
                self.contentView.addSubview(subview)
            } else {
                self.addSubview(subview)
            }
            return
        }
        switch self.layoutMode {
        case .auto, .scroll:
            self.contentView.addSubview(subview)
            #if DEBUG
            // 延迟检查，给约束设置一些时间
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.validateBottomConstraints()
            }
            #endif
        case .fixed:
            self.addSubview(subview)
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
        self.checkContentSize()
    }
    
    /// 获取当前布局模式
    open func st_getCurrentLayoutMode() -> STLayoutMode {
        return self.layoutMode
    }
    
    /// 获取ScrollView（如果存在）
    open func st_getScrollView() -> UIScrollView? {
        return self.layoutMode == .scroll ? self.scrollView : nil
    }
    
    /// 获取内容视图
    open func st_getContentView() -> UIView {
        return self.contentView
    }
    
    /// 获取TableView（如果存在）
    open func st_getTableView() -> UITableView? {
        guard self.layoutMode == .table else { return nil }
        return self.tableViewStyle == .grouped ? self.tableViewGrouped : self.tableViewPlain
    }
    
    /// 获取CollectionView（如果存在）
    open func st_getCollectionView() -> UICollectionView? {
        return self.layoutMode == .collection ? self.collectionView : nil
    }
    
    /// 检查是否来自XIB
    open func st_isFromXIB() -> Bool {
        return self.isFromXIB
    }
    
    /// 获取XIB中的子视图
    open func st_getXIBSubviews() -> [UIView] {
        return self.xibSubviews
    }
    
    /// 验证底部约束设置（仅在DEBUG模式下调用）
    private func validateBottomConstraints() {
        guard self.layoutMode == .auto || self.layoutMode == .scroll else { return }
        
        let contentView = self.st_getContentView()
        let subviews = contentView.subviews
        
        if subviews.isEmpty {
            print("⚠️ STBaseView 提醒：contentView 中没有子视图，请使用 st_getContentView() 添加子视图")
            return
        }
        
        // 检查是否有底部约束
        var hasBottomConstraint = false
        for subview in subviews {
            for constraint in subview.constraints {
                if constraint.firstAttribute == .bottom || constraint.secondAttribute == .bottom {
                    hasBottomConstraint = true
                    break
                }
            }
            if hasBottomConstraint { break }
        }
        
        // 检查 contentView 的约束
        for constraint in contentView.constraints {
            if constraint.firstAttribute == .bottom || constraint.secondAttribute == .bottom {
                hasBottomConstraint = true
                break
            }
        }
        
        if !hasBottomConstraint {
            print("""
            ⚠️ STBaseView 重要提醒：
            📍 您可能忘记设置底部约束！
            📍 这会导致自动滚动检测失效
            📍 请为最后一个子视图添加底部约束：
               make.bottom.equalTo(-20)
            📍 或者使用 st_validateConstraints() 方法检查约束设置
            """)
        }
    }
    
    /// 手动验证约束设置（公开方法，供开发者调用）
    open func st_validateConstraints() {
        #if DEBUG
        self.validateBottomConstraints()
        #else
        print("⚠️ 约束验证仅在DEBUG模式下可用")
        #endif
    }
    
    /// 便捷方法：为最后一个子视图设置底部约束
    /// 
    /// 使用示例：
    /// ```swift
    /// let contentView = baseView.st_getContentView()
    /// contentView.addSubview(myView)
    /// baseView.st_setBottomConstraint(for: myView, offset: -20)
    /// ```
    open func st_setBottomConstraint(for subview: UIView, offset: CGFloat = -20) {
        guard subview.superview == self.st_getContentView() else {
            print("⚠️ 警告：子视图必须添加到 contentView 中")
            return
        }
        subview.translatesAutoresizingMaskIntoConstraints = false
        let bottomConstraint = NSLayoutConstraint(
            item: subview,
            attribute: .bottom,
            relatedBy: .equal,
            toItem: self.st_getContentView(),
            attribute: .bottom,
            multiplier: 1.0,
            constant: offset
        )
        self.st_getContentView().addConstraint(bottomConstraint)
        #if DEBUG
        print("✅ 已为 \(String(describing: type(of: subview))) 设置底部约束，偏移量：\(offset)")
        #endif
    }
    
    /// 滚动视图
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.delegate = self
        scrollView.backgroundColor = .clear
        scrollView.alwaysBounceVertical = false
        scrollView.contentInset = .zero
        scrollView.scrollIndicatorInsets = .zero
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.translatesAutoresizingMaskIntoConstraints = false
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

extension STBaseView {
    
    public func st_setupTableView(delegate: UITableViewDelegate, dataSource: UITableViewDataSource) {
        if self.tableViewStyle == .grouped {
            self.tableViewGrouped.delegate = delegate
            self.tableViewGrouped.dataSource = dataSource
        } else {
            self.tableViewPlain.delegate = delegate
            self.tableViewPlain.dataSource = dataSource
        }
    }
    
    public func st_setupCollectionView(delegate: UICollectionViewDelegate, dataSource: UICollectionViewDataSource) {
        self.collectionView.delegate = delegate
        self.collectionView.dataSource = dataSource
    }
    
    public func st_registerTableViewCell<T: UITableViewCell>(_ cellClass: T.Type, identifier: String? = nil) {
        let cellId = identifier ?? String(describing: cellClass)
        if self.tableViewStyle == .grouped {
            self.tableViewGrouped.register(cellClass, forCellReuseIdentifier: cellId)
        } else {
            self.tableViewPlain.register(cellClass, forCellReuseIdentifier: cellId)
        }
    }
    
    public func st_registerCollectionViewCell<T: UICollectionViewCell>(_ cellClass: T.Type, identifier: String? = nil) {
        let cellId = identifier ?? String(describing: cellClass)
        self.collectionView.register(cellClass, forCellWithReuseIdentifier: cellId)
    }
}

// MARK: - UIScrollViewDelegate
extension STBaseView {
    
    @objc open func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // 防止滚动到顶部时出现空白
        if scrollView.contentOffset.y < 0 {
            scrollView.contentOffset = CGPoint(x: scrollView.contentOffset.x, y: 0)
        }
    }
    
    @objc open func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        // 子类可以重写此方法
    }
    
    @objc open func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        // 子类可以重写此方法
    }
    
    @objc open func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        // 子类可以重写此方法
    }
    
    @objc open func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        // 子类可以重写此方法
    }
    
    @objc open func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        // 子类可以重写此方法
    }
    
    @objc open func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        // 子类可以重写此方法
    }
    
    @objc open func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        // 子类可以重写此方法
        return true
    }
    
    @objc open func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
        // 子类可以重写此方法
    }
    
    @objc open func scrollViewDidChangeAdjustedContentInset(_ scrollView: UIScrollView) {
        // 子类可以重写此方法
    }
}
