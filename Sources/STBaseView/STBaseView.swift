//
//  STBaseView.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2018/3/14.
//

import UIKit
import Combine

/// 用于 objc_setAssociatedObject 的引用型 key，避免对可变 static var 取地址造成的未定义行为。
private final class STAssociationKey {}

@inline(__always)
private func st_keyPointer(_ key: STAssociationKey) -> UnsafeRawPointer {
    return UnsafeRawPointer(Unmanaged.passUnretained(key).toOpaque())
}

public enum STLayoutMode {
    case scroll     // UIScrollView（默认）
    case fixed      // 普通容器，不可滚动
    case table      // UITableView
    case collection // UICollectionView
}

public enum STScrollDirection {
    case vertical
    case horizontal
    case both
    case none
}

open class STBaseView: UIView {

    public private(set) var layoutMode: STLayoutMode = .scroll
    public private(set) var scrollDirection: STScrollDirection = .vertical
    
    /// scroll 模式使用的 UIScrollView。可通过 init(scrollView:) 在初始化时注入自定义实例。
    /// open 允许子类（含跨模块）override 此 getter（如将 collectionView 作为 scrollView 代理）。
    open private(set) lazy var scrollView: UIScrollView = STBaseView.makeDefaultScrollView()
    /// 标记 scrollView 是否由内部创建（用于判断是否允许 configureScrollBehavior 覆盖外观/滚动配置）。
    private var _isInternallyCreatedScrollView: Bool = true
    /// contentView 是内容容器，子视图应添加到此视图。
    /// 在 .scroll 模式下位于 scrollView 内部；在 .fixed 模式下直接贴合 self。
    public private(set) lazy var contentView: UIView = self.makeContentView()
    
    private var _tableView: UITableView?
    private var _collectionView: UICollectionView?
    /// 标记 _tableView 是否由 STBaseView 内部懒创建（true）还是外部注入（false），
    /// 用于 st_tableViewStyle 判断是否允许销毁重建。
    private var _isInternallyCreatedTableView: Bool = false
    public private(set) var tableViewStyle: UITableView.Style = .plain

    private var keyboardObserverTokens: [NSObjectProtocol] = []
    private var appearanceCancellable: AnyCancellable?
    /// 是否启用 scrollView 的键盘 contentInset 自动调整（默认 true）。
    public var enableScrollViewKeyboardAdjustment: Bool = true
    /// 是否启用外观模式管理（默认 true）
    /// 当 STBaseView 在 STBaseViewController 中使用时，建议设置为 false，由 STBaseViewController 统一管理外观
    public var enableAppearanceManagement: Bool = true {
        didSet {
            guard self.enableAppearanceManagement != oldValue else { return }
            if self.enableAppearanceManagement {
                self.setupAppearanceObservation()
            } else {
                self.appearanceCancellable = nil
            }
        }
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupBase()
    }

    public init(scrollView: UIScrollView) {
        super.init(frame: .zero)
        self.scrollView = scrollView
        self._isInternallyCreatedScrollView = false
        self.setupBase()
    }

    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setupBase()
    }

    deinit {
        self.removeKeyboardObservers()
    }

    private func setupBase() {
        self.translatesAutoresizingMaskIntoConstraints = false
        self.setupKeyboardObservers()
        if self.enableAppearanceManagement {
            self.setupAppearanceObservation()
        }
        self.installLayoutStructure()
    }

    /// 切换布局模式。
    /// - Parameters:
    ///   - layoutMode: 目标模式
    ///   - scrollDirection: 滚动方向，仅 .scroll 模式有效
    ///   - tableView: 自定义 UITableView，传 nil 则使用内部默认实例（仅 .table 模式生效）
    ///   - collectionView: 自定义 UICollectionView，传 nil 则使用内部默认实例（仅 .collection 模式生效）
    public func configure(layoutMode: STLayoutMode, scrollDirection: STScrollDirection = .vertical, tableView: UITableView? = nil, collectionView: UICollectionView? = nil) {
        if let tv = tableView {
            self._tableView = tv
            self._isInternallyCreatedTableView = false
        }
        if let cv = collectionView { self._collectionView = cv }
        self.layoutMode = layoutMode
        self.scrollDirection = scrollDirection
        self.installLayoutStructure()
    }

    /// Convenience: configure to scroll and return scrollView for further configuration
    public func configureAsScroll(_ direction: STScrollDirection = .vertical) -> UIScrollView {
        self.configure(layoutMode: .scroll, scrollDirection: direction)
        return self.scrollView
    }

    /// 返回内容所在的容器视图。
    /// - `.scroll` / `.fixed`：返回 contentView
    /// - `.table`：返回 tableView（用于 overlay 子视图，cells 仍走 delegate/dataSource）
    /// - `.collection`：返回 collectionView
    open func contentContainer() -> UIView {
        switch self.layoutMode {
        case .scroll, .fixed:
            return self.contentView
        case .table:
            return self.st_getTableView() ?? self
        case .collection:
            return self.collectionView
        }
    }

    /// Add child to content container. Use Auto Layout for constraints.
    public func st_addContentSubview(_ view: UIView) {
        let container = self.contentContainer()
        view.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(view)
    }

    /// Helper to set lastSubview bottom anchor to contentView bottom (important for scroll)
    public func st_setBottomConstraintForLastSubview(_ subview: UIView, offset: CGFloat = -20) {
        guard subview.superview == self.contentView else {
            assertionFailure("Last subview must be added to contentView")
            return
        }
        let constraint = subview.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: offset)
        constraint.priority = .required
        constraint.isActive = true
    }

    // MARK: - Accessors for table/collection
    /// 返回当前 tableView；仅在 .table 模式下有效，否则返回 nil。
    public func st_getTableView() -> UITableView? {
        guard self.layoutMode == .table else { return nil }
        return self.tableView
    }

    /// 返回当前 collectionView；仅在 .collection 模式下有效，否则返回 nil。
    public func st_getCollectionView() -> UICollectionView? {
        return self.layoutMode == .collection ? self.collectionView : nil
    }

    private func installLayoutStructure() {
        self.removeManagedContainers()
        switch self.layoutMode {
        case .scroll:
            self.installScrollStructure()
        case .fixed:
            self.installFixedStructure()
        case .table:
            self.installTableStructure()
        case .collection:
            self.installCollectionStructure()
        }
    }

    private func removeManagedContainers() {
        [self.scrollView as UIView, _tableView, _collectionView].compactMap { $0 }.forEach {
            if $0.superview == self { $0.removeFromSuperview() }
        }
        self.contentView.removeFromSuperview()
    }

    private func installScrollStructure() {
        self.installScrollViewConstraints()
        self.scrollView.addSubview(self.contentView)
        NSLayoutConstraint.activate([
            self.contentView.topAnchor.constraint(equalTo: self.scrollView.contentLayoutGuide.topAnchor),
            self.contentView.leadingAnchor.constraint(equalTo: self.scrollView.contentLayoutGuide.leadingAnchor),
            self.contentView.trailingAnchor.constraint(equalTo: self.scrollView.contentLayoutGuide.trailingAnchor),
            self.contentView.bottomAnchor.constraint(equalTo: self.scrollView.contentLayoutGuide.bottomAnchor),
            // Important: make contentView width equal to scrollView frame (for vertical scrolling)
            self.contentView.widthAnchor.constraint(equalTo: self.scrollView.frameLayoutGuide.widthAnchor)
        ])
        self.configureScrollBehavior()
    }

    /// 子类重写此方法，将 scrollView 添加到视图层级并设置位置约束。
    /// 默认实现：scrollView 四边贴合父视图。
    /// - 注意：此方法在 configure(layoutMode: .scroll) 调用链内同步执行，
    ///   重写时可安全访问已提前创建好的兄弟视图（如导航栏容器）。
    open func installScrollViewConstraints() {
        self.addSubview(self.scrollView)
        self.scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.scrollView.topAnchor.constraint(equalTo: topAnchor),
            self.scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            self.scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            self.scrollView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    private func installFixedStructure() {
        self.addSubview(self.contentView)
        self.contentView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.contentView.topAnchor.constraint(equalTo: topAnchor),
            self.contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            self.contentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            self.contentView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    private func installTableStructure() {
        let table = self.tableView
        self.addSubview(table)
        table.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            table.topAnchor.constraint(equalTo: topAnchor),
            table.leadingAnchor.constraint(equalTo: leadingAnchor),
            table.trailingAnchor.constraint(equalTo: trailingAnchor),
            table.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    private func installCollectionStructure() {
        self.addSubview(self.collectionView)
        self.collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.collectionView.topAnchor.constraint(equalTo: topAnchor),
            self.collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            self.collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            self.collectionView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    private func configureScrollBehavior() {
        // 注入的外部 scrollView 保留使用者原配置，仅对内部默认实例进行定制。
        guard self._isInternallyCreatedScrollView else { return }
        self.scrollView.alwaysBounceVertical = (self.scrollDirection == .vertical || self.scrollDirection == .both)
        self.scrollView.alwaysBounceHorizontal = (self.scrollDirection == .horizontal || self.scrollDirection == .both)
        self.scrollView.showsVerticalScrollIndicator = (self.scrollDirection == .vertical || self.scrollDirection == .both)
        self.scrollView.showsHorizontalScrollIndicator = (self.scrollDirection == .horizontal || self.scrollDirection == .both)
        self.scrollView.contentInsetAdjustmentBehavior = .automatic
    }

    // MARK: - Appearance
    private func setupAppearanceObservation() {
        guard self.enableAppearanceManagement else { return }
        self.applyOverrideStyle()
        let style = STAppearanceManager.shared.resolvedInterfaceStyle(for: self.traitCollection)
        self.st_appearanceDidChange(resolvedStyle: style == .unspecified ? .light : style)
        self.appearanceCancellable = STAppearanceManager.shared.appearanceModePublisher
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self = self, self.enableAppearanceManagement else { return }
                self.applyOverrideStyle()
            }
    }

    private func applyOverrideStyle() {
        switch STAppearanceManager.shared.currentMode {
        case .system: self.overrideUserInterfaceStyle = .unspecified
        case .light:  self.overrideUserInterfaceStyle = .light
        case .dark:   self.overrideUserInterfaceStyle = .dark
        }
    }

    /// 外部手动触发，适用于自定义属性变动后需要立即同步外观的场景
    public func st_forceAppearanceRefresh(animated: Bool = false) {
        self.applyOverrideStyle()
        let style = STAppearanceManager.shared.resolvedInterfaceStyle(for: self.traitCollection)
        let resolved: UIUserInterfaceStyle = style == .unspecified ? .light : style
        if animated {
            UIView.transition(with: self, duration: 0.25, options: [.transitionCrossDissolve, .allowUserInteraction]) {
                self.st_appearanceDidChange(resolvedStyle: resolved)
            }
        } else {
            self.st_appearanceDidChange(resolvedStyle: resolved)
        }
    }

    open override func safeAreaInsetsDidChange() {
        super.safeAreaInsetsDidChange()
        // tableView / collectionView 使用 contentInsetAdjustmentBehavior = .never，
        // 所以 safeArea 不会自动折进 adjustedContentInset，需要手动把底部 safeArea
        // 写入 contentInset.bottom，否则内容会压到 home indicator。
        // 同时若存在 STRefreshHeaderView / STLoadMoreFooterView，还要保留它们
        // 已注入的额外占位（refreshing / loading / noMore 状态下 +height）。
        switch self.layoutMode {
        case .table:
            if let tv = self._tableView {
                self.st_applyBaseSafeAreaInset(to: tv)
            }
        case .collection:
            if let cv = self._collectionView {
                self.st_applyBaseSafeAreaInset(to: cv)
            }
        default:
            break
        }
    }

    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        let previousStyle = previousTraitCollection?.userInterfaceStyle ?? .unspecified
        let currentStyle = self.traitCollection.userInterfaceStyle
        guard previousStyle != currentStyle else { return }
        let style = STAppearanceManager.shared.resolvedInterfaceStyle(for: self.traitCollection)
        self.st_appearanceDidChange(resolvedStyle: style == .unspecified ? .light : style)
    }
    
    /// 外观模式变化时的回调方法（可重写）
    /// SDK 只负责设置 overrideUserInterfaceStyle，具体的颜色设置由使用者在外界或重写此方法时处理
    /// - Parameter resolvedStyle: 解析后的外观样式（.light 或 .dark）
    /// 
    /// 默认实现为空，使用者可以：
    /// 1. 在外界通过属性（如 backgroundColor、contentView.backgroundColor）设置颜色
    /// 2. 重写此方法来自定义外观变化时的颜色设置逻辑
    open func st_appearanceDidChange(resolvedStyle: UIUserInterfaceStyle) {
        // 默认不自动设置颜色，保持使用者在外界设置的颜色
        // 使用者可以重写此方法来自定义处理逻辑
    }

    // MARK: - Keyboard handling
    private func setupKeyboardObservers() {
        let nc = NotificationCenter.default
        let willShow = nc.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { [weak self] note in
            self?.keyboardWillShow(note)
        }
        let willHide = nc.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { [weak self] note in
            self?.keyboardWillHide(note)
        }
        self.keyboardObserverTokens = [willShow, willHide]
    }

    private func removeKeyboardObservers() {
        let nc = NotificationCenter.default
        self.keyboardObserverTokens.forEach { nc.removeObserver($0) }
        self.keyboardObserverTokens.removeAll()
    }

    private func keyboardWillShow(_ note: Notification) {
        guard self.layoutMode == .scroll, self.enableScrollViewKeyboardAdjustment, let userInfo = note.userInfo else { return }
        let keyboardFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect) ?? .zero
        let converted = convert(keyboardFrame, from: nil)
        let insetBottom = max(0, bounds.maxY - converted.minY)
        var insets = self.scrollView.contentInset
        insets.bottom = insetBottom
        self.scrollView.contentInset = insets
        self.scrollView.scrollIndicatorInsets = insets
    }

    private func keyboardWillHide(_ note: Notification) {
        guard self.layoutMode == .scroll, self.enableScrollViewKeyboardAdjustment else { return }
        var insets = self.scrollView.contentInset
        insets.bottom = 0
        self.scrollView.contentInset = insets
        self.scrollView.scrollIndicatorInsets = insets
    }

    /// Convenience for debugging: ensure last subview has bottom constraint to contentView
    public func st_validateBottomConstraintLogging() {
        guard self.layoutMode == .scroll else { return }
        let children = self.contentView.subviews
        guard let last = children.last else { return }
        let superviewConstraints = last.superview?.constraints ?? []
        let candidates = last.constraints + self.contentView.constraints + superviewConstraints
        let found = candidates.contains { c in
            return (c.firstItem as? UIView) == last && (c.firstAttribute == .bottom) && (c.secondItem as? UIView) == self.contentView
        }
        if !found {
            STLog("⚠️ STBaseView: last subview doesn't have bottom constraint to contentView. Add st_setBottomConstraintForLastSubview(_:,offset:)")
        }
    }
    
    /// table 模式内部使用的 UITableView；外部通过 st_getTableView() 访问。
    private var tableView: UITableView {
        if _tableView == nil {
            _tableView = self.makeTableView(self.tableViewStyle)
            _isInternallyCreatedTableView = true
        }
        return _tableView!
    }

    /// collection 模式内部使用的 UICollectionView；外部通过 st_getCollectionView() 访问。
    private var collectionView: UICollectionView {
        if _collectionView == nil {
            _collectionView = self.makeCollectionView()
        }
        return _collectionView!
    }

    private static func makeDefaultScrollView() -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.backgroundColor = .clear
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.contentInsetAdjustmentBehavior = .automatic
        return scrollView
    }

    private func makeContentView() -> UIView {
        let contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.backgroundColor = .clear
        return contentView
    }

    private func makeTableView(_ style: UITableView.Style) -> UITableView {
        let tableView = UITableView(frame: .zero, style: style)
        tableView.backgroundColor = .clear
        tableView.estimatedRowHeight = 44
        tableView.separatorStyle = .none
        tableView.tableFooterView = UIView()
        tableView.allowsSelection = true
        tableView.delaysContentTouches = false
        tableView.keyboardDismissMode = .interactive
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.rowHeight = UITableView.automaticDimension
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }

    private func makeCollectionView() -> UICollectionView {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .clear
        collectionView.contentInsetAdjustmentBehavior = .never
        return collectionView
    }
}

extension STBaseView {
    /// 设置 layoutMode。注意：仅记录模式，需要调用 st_done() 或 configure(...) 才会真正安装结构。
    @discardableResult
    public func st_layoutMode(_ mode: STLayoutMode) -> Self {
        self.layoutMode = mode
        return self
    }

    /// 设置 table 模式的 style。
    /// - 如果尚未实例化内部默认 tableView，则仅记录 style 等待后续创建。
    /// - 如果当前正在 .table 模式且已存在内部默认实例，则销毁旧实例并用新 style 重建。
    /// - 若外部注入过自定义 tableView，此方法不会影响已注入实例。
    ///
    /// ⚠️ 重建 tableView 会丢弃所有已在旧 table 上配置的状态：delegate / dataSource /
    /// cell 注册 / contentOffset / 以及已挂载的 pull-to-refresh / load-more 控件。
    /// 重建后调用方需要自行重新配置。推荐在创建 tableView 之前一次性确定 style。
    @discardableResult
    public func st_tableViewStyle(_ style: UITableView.Style) -> Self {
        guard self.tableViewStyle != style else { return self }
        self.tableViewStyle = style
        // 若已经存在由内部创建的 tableView，则销毁重建以让新 style 生效
        if self._tableView != nil, self._isInternallyCreatedTableView {
            #if DEBUG
            assertionFailure("STBaseView.st_tableViewStyle(_:) called after the internal tableView was created. All table configuration (delegate/dataSource/cell registration/pull-to-refresh/load-more) will be lost and must be re-applied.")
            #endif
            // 先拆除挂在旧 table 上的刷新控件，避免 KVO token 继续持有旧 scrollView（泄漏），
            // 并清掉 self 上的 associated object，防止后续 st_beginRefreshing / st_endLoadMore
            // 作用到已脱离视图层级的旧实例上。
            self.st_removePullToRefresh()
            self.st_removeLoadMore()
            self._tableView?.removeFromSuperview()
            self._tableView = nil
            if self.layoutMode == .table {
                self.installLayoutStructure()
            }
        }
        return self
    }

    /// 注入自定义 UITableView（需在 st_done() 前调用）
    @discardableResult
    public func st_tableView(_ tableView: UITableView) -> Self {
        self._tableView = tableView
        self._isInternallyCreatedTableView = false
        return self
    }

    /// 注入自定义 UICollectionView（需在 st_done() 前调用）
    @discardableResult
    public func st_collectionView(_ collectionView: UICollectionView) -> Self {
        self._collectionView = collectionView
        return self
    }

    /// 设置滚动方向。仅 .scroll 模式下 configureScrollBehavior 会应用；需要调用 st_done() 生效。
    @discardableResult
    public func st_scrollDirection(_ direction: STScrollDirection) -> Self {
        self.scrollDirection = direction
        return self
    }

    @discardableResult
    public func st_backgroundColor(_ color: UIColor) -> Self {
        self.backgroundColor = color
        return self
    }

    @discardableResult
    public func st_onContent(_ block: (UIView) -> Void) -> Self {
        block(self.contentContainer())
        return self
    }

    @discardableResult
    public func st_done() -> Self {
        self.installLayoutStructure()
        return self
    }
}

// MARK: - Section System
open class STSection: UIView {

    /// 直接赋值即可动态调整（通过 `didSet` 更新约束，不会产生约束泄漏）。
    public var inset: UIEdgeInsets {
        didSet { self.applyInsetToConstraints() }
    }
    /// 直接赋值即可动态调整。
    public var spacing: CGFloat {
        didSet { self.stackView.spacing = self.spacing }
    }
    private let stackView: UIStackView
    // 持有 stackView 的 4 条边约束引用，便于改 inset 时直接改 constant，避免约束泄漏
    private var topConstraint: NSLayoutConstraint!
    private var leadingConstraint: NSLayoutConstraint!
    private var trailingConstraint: NSLayoutConstraint!
    private var bottomConstraint: NSLayoutConstraint!

        public init(inset: UIEdgeInsets = .zero, spacing: CGFloat = 0) {
            self.inset = inset
            self.spacing = spacing
            self.stackView = UIStackView()
            super.init(frame: .zero)
            self.translatesAutoresizingMaskIntoConstraints = false
            self.setupStackView()
        }

        required public init?(coder: NSCoder) {
            self.inset = .zero
            self.spacing = 0
            self.stackView = UIStackView()
            super.init(coder: coder)
            self.translatesAutoresizingMaskIntoConstraints = false
            self.setupStackView()
        }

        private func setupStackView() {
            self.stackView.axis = .vertical
            self.stackView.spacing = self.spacing
            self.stackView.alignment = .fill
            self.stackView.distribution = .fill
            self.stackView.translatesAutoresizingMaskIntoConstraints = false
            self.addSubview(self.stackView)
            self.topConstraint = self.stackView.topAnchor.constraint(equalTo: self.topAnchor, constant: self.inset.top)
            self.leadingConstraint = self.stackView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: self.inset.left)
            self.trailingConstraint = self.stackView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -self.inset.right)
            self.bottomConstraint = self.stackView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -self.inset.bottom)
            NSLayoutConstraint.activate([self.topConstraint, self.leadingConstraint, self.trailingConstraint, self.bottomConstraint])
        }

        /// Add multiple views (arranged) to this section (chainable)
        @discardableResult
        public func addViews(_ views: [UIView]) -> Self {
            for v in views {
                v.translatesAutoresizingMaskIntoConstraints = false
                self.stackView.addArrangedSubview(v)
            }
            return self
        }

        /// Add a single view
        @discardableResult
        public func addView(_ view: UIView) -> Self {
            view.translatesAutoresizingMaskIntoConstraints = false
            self.stackView.addArrangedSubview(view)
            return self
        }

        /// Clear all arranged subviews
        @discardableResult
        public func clear() -> Self {
            let snapshot = self.stackView.arrangedSubviews
            for v in snapshot {
                self.stackView.removeArrangedSubview(v)
                v.removeFromSuperview()
            }
            return self
        }

        /// Update spacing (chainable) — equivalent to directly assigning `self.spacing`.
        @discardableResult
        public func setSpacing(_ spacing: CGFloat) -> Self {
            self.spacing = spacing
            return self
        }

        /// Update inset (chainable) — equivalent to directly assigning `self.inset`.
        /// The setter tunes the 4 retained constraints, so there's no constraint leak.
        @discardableResult
        public func setInset(_ inset: UIEdgeInsets) -> Self {
            self.inset = inset
            return self
        }

        private func applyInsetToConstraints() {
            self.topConstraint?.constant = self.inset.top
            self.leadingConstraint?.constant = self.inset.left
            self.trailingConstraint?.constant = -self.inset.right
            self.bottomConstraint?.constant = -self.inset.bottom
        }
}

extension STBaseView {

    /// 用于跟踪每个 section 与 container.bottom 之间"末尾"约束，便于添加新 section 时拆除并复用为 inter-section 约束。
    private static let sectionBottomConstraintKey = STAssociationKey()

    private var st_lastSectionBottomConstraint: NSLayoutConstraint? {
        get { objc_getAssociatedObject(self, st_keyPointer(Self.sectionBottomConstraintKey)) as? NSLayoutConstraint }
        set { objc_setAssociatedObject(self, st_keyPointer(Self.sectionBottomConstraintKey), newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    /// 将一个 section 添加到 contentContainer。会自动维护链尾的 bottom 约束，
    /// 在 .scroll 模式下保证 contentView 高度可被正确计算。
    /// - Parameter interSectionSpacing: 与上一个 section 的间距（默认使用 section.spacing 的语义已被废弃，建议显式指定）。
    public func st_addSection(_ section: STSection, interSectionSpacing: CGFloat? = nil) {
        let container = self.contentContainer()
        container.addSubview(section)
        section.translatesAutoresizingMaskIntoConstraints = false

        // 移除旧的"末尾 -> container.bottom"约束（若存在）
        if let oldBottom = self.st_lastSectionBottomConstraint {
            oldBottom.isActive = false
            self.st_lastSectionBottomConstraint = nil
        }

        let topSpacing = interSectionSpacing ?? section.spacing
        if let last = container.subviews.dropLast().last {
            section.topAnchor.constraint(equalTo: last.bottomAnchor, constant: topSpacing).isActive = true
        } else {
            section.topAnchor.constraint(equalTo: container.topAnchor, constant: section.inset.top).isActive = true
        }
        NSLayoutConstraint.activate([
            section.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: section.inset.left),
            section.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -section.inset.right)
        ])

        // 在 .scroll 模式下，必须建立 section.bottom -> container.bottom 的约束才能算出 contentSize。
        // 在 .fixed 模式下也建立此约束以保证布局完整；在 table/collection 容器下不强制。
        if self.layoutMode == .scroll || self.layoutMode == .fixed {
            let bottom = section.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -section.inset.bottom)
            bottom.priority = .defaultHigh
            bottom.isActive = true
            self.st_lastSectionBottomConstraint = bottom
        }

        self.setNeedsLayout()
    }
}

// MARK: - State Pages (loading / empty / error)
/// 状态视图默认文案配置。使用者可在 App 启动时修改以支持国际化或自定义文本。
public enum STStatePageDefaults {
    public static var loadingText: String = "Loading…"
    public static var emptyText: String = "No Data"
    public static var errorText: String = "Error"
}

extension STBaseView {

    private enum StateKeys {
        static let loading = STAssociationKey()
        static let empty = STAssociationKey()
        static let error = STAssociationKey()
    }

    private func st_makeStateView(_ text: String) -> UIView {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        let label = UILabel()
        label.text = text
        label.textColor = .gray
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        v.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: v.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: v.centerYAnchor)
        ])
        return v
    }

    private func st_installStateView(_ v: UIView, key: STAssociationKey) {
        self.addSubview(v)
        NSLayoutConstraint.activate([
            v.topAnchor.constraint(equalTo: self.topAnchor),
            v.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            v.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            v.trailingAnchor.constraint(equalTo: self.trailingAnchor)
        ])
        objc_setAssociatedObject(self, st_keyPointer(key), v, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    public func st_showLoading(_ text: String? = nil) {
        self.st_hideAllStates()
        let v = self.st_makeStateView(text ?? STStatePageDefaults.loadingText)
        self.st_installStateView(v, key: StateKeys.loading)
    }

    public func st_showEmpty(_ text: String? = nil) {
        self.st_hideAllStates()
        let v = self.st_makeStateView(text ?? STStatePageDefaults.emptyText)
        self.st_installStateView(v, key: StateKeys.empty)
    }

    /// 显示错误状态视图。
    public func st_showError(_ text: String? = nil) {
        self.st_hideAllStates()
        let v = self.st_makeStateView(text ?? STStatePageDefaults.errorText)
        self.st_installStateView(v, key: StateKeys.error)
    }

    public func st_hideAllStates() {
        self.st_removeStateView(with: StateKeys.loading)
        self.st_removeStateView(with: StateKeys.empty)
        self.st_removeStateView(with: StateKeys.error)
    }

    private func st_removeStateView(with key: STAssociationKey) {
        let ptr = st_keyPointer(key)
        if let v = objc_getAssociatedObject(self, ptr) as? UIView {
            v.removeFromSuperview()
            objc_setAssociatedObject(self, ptr, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

// MARK: - Dynamic Gradient Navigation Bar Support
open class STGradientNavigationBar: UIView {

    public var startColor: UIColor = .clear { didSet { self.updateGradientColors() } }
    public var endColor: UIColor = .black { didSet { self.updateGradientColors() } }
    public var height: CGFloat = 88 { didSet { self.invalidateIntrinsicContentSize() } }

    private let gradientLayer = CAGradientLayer()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupGradient()
    }
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setupGradient()
    }

    private func setupGradient() {
        self.gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        self.gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
        self.updateGradientColors()
        self.layer.addSublayer(self.gradientLayer)
    }

    private func updateGradientColors() {
        self.gradientLayer.colors = [self.startColor.cgColor, self.endColor.cgColor]
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        // frame 更新仍需每次布局同步；颜色/起止点已在属性变化/初始化时设置。
        self.gradientLayer.frame = self.bounds
    }

    public override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: self.height)
    }

    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        // 动态色适配：当 trait 变化导致 UIColor -> cgColor 对应分辨率变化时需重算
        if self.traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            self.updateGradientColors()
        }
    }
}

// MARK: - Refresh & Load More

private enum STRefreshKeys {
    static let header = STAssociationKey()
    static let footer = STAssociationKey()
}

extension STBaseView {

    private func st_refreshScrollView() -> UIScrollView? {
        switch self.layoutMode {
        case .scroll:     return self.scrollView
        case .table:      return self.st_getTableView()
        case .collection: return self.st_getCollectionView()
        case .fixed:
            #if DEBUG
            assertionFailure("STBaseView: st_addPullToRefresh / st_addLoadMore 不支持 .fixed 模式")
            #endif
            return nil
        }
    }

    /// safeArea 变化时通知刷新控件重新校准基准 inset。
    fileprivate func st_notifyRefreshControlsSafeAreaChanged() {
        if let header = objc_getAssociatedObject(self, st_keyPointer(STRefreshKeys.header)) as? STRefreshHeaderView {
            header.safeAreaInsetsDidChangeFromHost()
        }
        if let footer = objc_getAssociatedObject(self, st_keyPointer(STRefreshKeys.footer)) as? STLoadMoreFooterView {
            footer.safeAreaInsetsDidChangeFromHost()
        }
    }

    /// 把底部 safeArea 写入 contentInset.bottom（同时叠加刷新控件已注入的增量），
    /// 并把 scroll indicator 底部也对齐 safeArea；最后通知刷新控件以新基准重校准。
    /// 仅用于 .table / .collection 模式，因为这两种内部创建的 scrollView 使用
    /// contentInsetAdjustmentBehavior = .never，不会自动把 safeArea 折进来。
    fileprivate func st_applyBaseSafeAreaInset(to sv: UIScrollView) {
        let baseBottom = self.safeAreaInsets.bottom
        let footerExtra = (objc_getAssociatedObject(self, st_keyPointer(STRefreshKeys.footer)) as? STLoadMoreFooterView)?.injectedInsetBottom ?? 0
        sv.contentInset.bottom = baseBottom + footerExtra
        sv.verticalScrollIndicatorInsets.bottom = baseBottom
        self.st_notifyRefreshControlsSafeAreaChanged()
    }

    // MARK: Pull-to-Refresh

    /// 添加下拉刷新。必须在 configure(layoutMode: .table/.collection) 之后调用。
    /// - Parameters:
    ///   - content: 显示内容（`.animation` 仅 spinner / `.text` 文字 / `.imageAndText` 图片+文字）
    ///   - action: 刷新回调，完成后调用 `st_endRefreshing()`
    public func st_addPullToRefresh(content: STRefreshContent = .animation, action: @escaping () -> Void) {
        guard let sv = self.st_refreshScrollView() else { return }
        self.st_removePullToRefresh()
        let header = STRefreshHeaderView(content: content)
        header.attach(to: sv, action: action)
        objc_setAssociatedObject(self, st_keyPointer(STRefreshKeys.header), header, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    /// 结束刷新动画，恢复 contentInset。
    public func st_endRefreshing() {
        (objc_getAssociatedObject(self, st_keyPointer(STRefreshKeys.header)) as? STRefreshHeaderView)?.endRefreshing()
    }

    /// 程序化触发下拉刷新（如首次进入页面自动加载）。
    public func st_beginRefreshing() {
        (objc_getAssociatedObject(self, st_keyPointer(STRefreshKeys.header)) as? STRefreshHeaderView)?.beginRefreshing()
    }

    /// 移除下拉刷新控件。
    public func st_removePullToRefresh() {
        let ptr = st_keyPointer(STRefreshKeys.header)
        if let header = objc_getAssociatedObject(self, ptr) as? STRefreshHeaderView {
            header.removeFromSuperview()
            objc_setAssociatedObject(self, ptr, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    // MARK: Load More

    /// 添加上拉加载更多。必须在 configure(layoutMode: .table/.collection) 之后调用。
    /// - Parameters:
    ///   - content: 显示内容（`.animation` 仅 spinner / `.text` 文字 / `.imageAndText` 图片+文字）
    ///   - action: 加载回调，完成后调用 `st_endLoadMore(hasMore:)`
    public func st_addLoadMore(content: STLoadMoreContent = .animation, action: @escaping () -> Void) {
        guard let sv = self.st_refreshScrollView() else { return }
        self.st_removeLoadMore()
        let footer = STLoadMoreFooterView(content: content)
        footer.attach(to: sv, action: action)
        objc_setAssociatedObject(self, st_keyPointer(STRefreshKeys.footer), footer, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    /// 结束加载动画。`hasMore = false` 时显示"无更多数据"并锁定，不再自动触发。
    public func st_endLoadMore(hasMore: Bool = true) {
        (objc_getAssociatedObject(self, st_keyPointer(STRefreshKeys.footer)) as? STLoadMoreFooterView)?.endLoading(hasMore: hasMore)
    }

    /// 重置加载更多为初始 idle 状态（换页或重新请求时调用）。
    public func st_resetLoadMore() {
        (objc_getAssociatedObject(self, st_keyPointer(STRefreshKeys.footer)) as? STLoadMoreFooterView)?.resetToIdle()
    }

    /// 移除上拉加载更多控件。
    public func st_removeLoadMore() {
        let ptr = st_keyPointer(STRefreshKeys.footer)
        if let footer = objc_getAssociatedObject(self, ptr) as? STLoadMoreFooterView {
            footer.removeFromSuperview()
            objc_setAssociatedObject(self, ptr, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}
