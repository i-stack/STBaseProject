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
    
    /// 可通过 init(scrollView:) 在初始化时注入自定义实例。
    private var _isInternallyCreatedScrollView: Bool = true
    public private(set) lazy var contentView: UIView = self.makeContentView()
    open private(set) lazy var scrollView: UIScrollView = STBaseView.makeDefaultScrollView()

    private var _tableView: UITableView?
    private var _collectionView: UICollectionView?
    /// 当前由 STBaseView 管理的 tableView 约束。
    /// 外部赋值时会自动停用旧约束并激活新约束。
    public var tableViewConstraints: [NSLayoutConstraint] = [] {
        didSet {
            NSLayoutConstraint.deactivate(oldValue)
            NSLayoutConstraint.activate(self.tableViewConstraints)
        }
    }
    /// 标记 _tableView 是否由 STBaseView 内部懒创建（true）还是外部注入（false），
    /// 用于 st_tableViewStyle 判断是否允许销毁重建。
    private var _isInternallyCreatedTableView: Bool = false
    public private(set) var tableViewStyle: UITableView.Style = .plain

    private var keyboardObserverTokens: [NSObjectProtocol] = []
    /// 键盘响应前的基准 inset，用于在键盘收起时还原调用方原有配置（safe area / 工具栏 / 分页 footer 等）。
    private var baseContentInset: UIEdgeInsets?
    private var baseVerticalIndicatorInsets: UIEdgeInsets?
    private var baseHorizontalIndicatorInsets: UIEdgeInsets?
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
        var constraints: [NSLayoutConstraint] = [
            self.contentView.topAnchor.constraint(equalTo: self.scrollView.contentLayoutGuide.topAnchor),
            self.contentView.leadingAnchor.constraint(equalTo: self.scrollView.contentLayoutGuide.leadingAnchor),
            self.contentView.trailingAnchor.constraint(equalTo: self.scrollView.contentLayoutGuide.trailingAnchor),
            self.contentView.bottomAnchor.constraint(equalTo: self.scrollView.contentLayoutGuide.bottomAnchor)
        ]
        // 约束语义随滚动方向变化：
        // - .vertical：宽度锁定为 frame 宽度，内容只能纵向撑高。
        // - .horizontal：高度锁定为 frame 高度，内容只能横向撑宽。
        // - .both：宽高都不锁定，由内容子视图的完整约束决定 contentSize。
        // - .none：同时锁定宽高，等价于固定容器（不可滚动）。
        switch self.scrollDirection {
        case .vertical:
            constraints.append(self.contentView.widthAnchor.constraint(equalTo: self.scrollView.frameLayoutGuide.widthAnchor))
        case .horizontal:
            constraints.append(self.contentView.heightAnchor.constraint(equalTo: self.scrollView.frameLayoutGuide.heightAnchor))
        case .both:
            break
        case .none:
            constraints.append(self.contentView.widthAnchor.constraint(equalTo: self.scrollView.frameLayoutGuide.widthAnchor))
            constraints.append(self.contentView.heightAnchor.constraint(equalTo: self.scrollView.frameLayoutGuide.heightAnchor))
        }
        NSLayoutConstraint.activate(constraints)
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
        self.tableViewConstraints = [
            table.topAnchor.constraint(equalTo: topAnchor),
            table.leadingAnchor.constraint(equalTo: leadingAnchor),
            table.trailingAnchor.constraint(equalTo: trailingAnchor),
            table.bottomAnchor.constraint(equalTo: bottomAnchor)
        ]
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
        guard self.enableAppearanceManagement else { return }
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
        let willChange = nc.addObserver(forName: UIResponder.keyboardWillChangeFrameNotification, object: nil, queue: .main) { [weak self] note in
            self?.keyboardWillChangeFrame(note)
        }
        self.keyboardObserverTokens = [willShow, willHide, willChange]
    }

    private func removeKeyboardObservers() {
        let nc = NotificationCenter.default
        self.keyboardObserverTokens.forEach { nc.removeObserver($0) }
        self.keyboardObserverTokens.removeAll()
    }

    private func keyboardWillShow(_ note: Notification) {
        self.adjustForKeyboard(using: note, appearing: true)
    }

    private func keyboardWillHide(_ note: Notification) {
        self.adjustForKeyboard(using: note, appearing: false)
    }

    private func keyboardWillChangeFrame(_ note: Notification) {
        // 旋转/分屏时键盘 frame 变化：键盘可见时按新 frame 重算增量；不可见时忽略。
        guard self.layoutMode == .scroll, self.enableScrollViewKeyboardAdjustment, note.userInfo != nil else { return }
        let keyboardFrame = (note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect) ?? .zero
        let converted = convert(keyboardFrame, from: nil)
        let insetBottom = max(0, bounds.maxY - converted.minY)
        guard insetBottom > 0 else { return }
        self.adjustForKeyboard(using: note, appearing: true)
    }

    /// 以"基准 inset + 键盘遮挡增量"的方式调整 contentInset / scrollIndicatorInsets，
    /// 隐藏时还原基准值并清空缓存，避免覆盖调用方原有的 bottom / 其他边 inset，
    /// 也避免后续键盘周期恢复陈旧基准。
    private func adjustForKeyboard(using note: Notification, appearing: Bool) {
        // 键盘禁用时，若此前已注入过键盘 inset（基准非空），仍要恢复到基准；否则直接退出。
        guard self.layoutMode == .scroll else { return }
        guard appearing || self.baseContentInset != nil else { return }
        guard let userInfo = note.userInfo, self.enableScrollViewKeyboardAdjustment else {
            if !appearing, let baseContent = self.baseContentInset {
                // 键盘调整被关闭，但仍需还原已注入的 inset。
                self.restoreBaseInsets()
            }
            return
        }

        // 首次响应键盘前保存基准 inset（一次键盘周期内捕获，隐藏后清空）。
        // 垂直/水平指示器的 inset 需分别保存完整 UIEdgeInsets，避免恢复时丢失调用方原有边距。
        if self.baseContentInset == nil {
            self.baseContentInset = self.scrollView.contentInset
        }
        if self.baseVerticalIndicatorInsets == nil {
            self.baseVerticalIndicatorInsets = self.scrollView.verticalScrollIndicatorInsets
        }
        if self.baseHorizontalIndicatorInsets == nil {
            self.baseHorizontalIndicatorInsets = self.scrollView.horizontalScrollIndicatorInsets
        }
        let baseContent = self.baseContentInset ?? self.scrollView.contentInset
        var verticalIndicator = self.baseVerticalIndicatorInsets ?? self.scrollView.verticalScrollIndicatorInsets
        var horizontalIndicator = self.baseHorizontalIndicatorInsets ?? self.scrollView.horizontalScrollIndicatorInsets

        let keyboardFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect) ?? .zero
        let converted = convert(keyboardFrame, from: nil)
        let overlay = appearing ? max(0, bounds.maxY - converted.minY) : 0
        // 增量 = 键盘遮挡高度 - 基准已有 bottom（避免与调用方原有 bottom inset 叠加）。
        let delta = max(0, overlay - baseContent.bottom)

        var contentInset = baseContent
        contentInset.bottom = baseContent.bottom + delta
        // 只修改各自指示器的 bottom，其余边保持调用方原配置。
        verticalIndicator.bottom += delta
        horizontalIndicator.bottom += delta

        let duration = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0
        let curveRaw = (userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber)?.uintValue ?? UInt(UIView.AnimationCurve.easeInOut.rawValue)
        let options = UIView.AnimationOptions(rawValue: curveRaw << 16)

        UIView.animate(withDuration: duration, delay: 0, options: options) {
            self.scrollView.contentInset = contentInset
            self.scrollView.verticalScrollIndicatorInsets = verticalIndicator
            self.scrollView.horizontalScrollIndicatorInsets = horizontalIndicator
            if !appearing {
                // 隐藏动画完成后清空基准缓存，下一次显示重新捕获当前 inset。
                self.baseContentInset = nil
                self.baseVerticalIndicatorInsets = nil
                self.baseHorizontalIndicatorInsets = nil
            }
        }
    }

    private func restoreBaseInsets() {
        let baseContent = self.baseContentInset ?? self.scrollView.contentInset
        let verticalIndicator = self.baseVerticalIndicatorInsets ?? self.scrollView.verticalScrollIndicatorInsets
        let horizontalIndicator = self.baseHorizontalIndicatorInsets ?? self.scrollView.horizontalScrollIndicatorInsets
        self.scrollView.contentInset = baseContent
        self.scrollView.verticalScrollIndicatorInsets = verticalIndicator
        self.scrollView.horizontalScrollIndicatorInsets = horizontalIndicator
        self.baseContentInset = nil
        self.baseVerticalIndicatorInsets = nil
        self.baseHorizontalIndicatorInsets = nil
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
    
    public func deactivateBaseTableViewEdgeConstraints() {
        guard self.st_getTableView() != nil else { return }
        self.tableViewConstraints.removeAll()
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
    /// 重建 tableView 会丢弃所有已在旧 table 上配置的状态：delegate / dataSource /
    /// cell 注册 / contentOffset / 以及已挂载的 pull-to-refresh / load-more 控件。
    /// 重建后调用方需要自行重新配置。推荐在创建 tableView 之前一次性确定 style。
    @discardableResult
    public func st_tableViewStyle(_ style: UITableView.Style) -> Self {
        guard self.tableViewStyle != style else { return self }
        self.tableViewStyle = style
        if self._tableView != nil, self._isInternallyCreatedTableView {
            #if DEBUG
            assertionFailure("STBaseView.st_tableViewStyle(_:) called after the internal tableView was created. All table configuration (delegate/dataSource/cell registration/pull-to-refresh/load-more) will be lost and must be re-applied.")
            #endif
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

        @discardableResult
        public func setSpacing(_ spacing: CGFloat) -> Self {
            self.spacing = spacing
            return self
        }

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
        if let oldBottom = self.st_lastSectionBottomConstraint {
            oldBottom.isActive = false
            self.st_lastSectionBottomConstraint = nil
        }

        // section.inset 仅作为 section 内部 stackView 的内边距（由 STSection 自身约束使用），
        // section 相对容器保持左右贴边。STSection.spacing 原本控制 stackView 内部 arranged subviews 的间距，
        // 因此不可兼作 section 对容器的外边距：首尾 section 直接贴容器，section 之间才使用 interSectionSpacing。
        if let last = container.subviews.dropLast().last {
            #if DEBUG
            assert(last is STSection, "STBaseView.st_addSection: contentContainer 中存在非 STSection 子视图（可能混用了 st_addContentSubview），链式约束将锚定到错误视图。请勿混用这两个 API。")
            #endif
            let interSpacing = interSectionSpacing ?? 0
            section.topAnchor.constraint(equalTo: last.bottomAnchor, constant: interSpacing).isActive = true
        } else {
            // 首个 section：顶部直接贴容器（无外边距）。
            section.topAnchor.constraint(equalTo: container.topAnchor).isActive = true
        }
        NSLayoutConstraint.activate([
            section.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            section.trailingAnchor.constraint(equalTo: container.trailingAnchor)
        ])

        // 在 .scroll 模式下，必须建立 section.bottom -> container.bottom 的约束才能算出 contentSize。
        // 在 .fixed 模式下也建立此约束以保证布局完整；在 table/collection 容器下不强制。
        // 末尾 section 直接贴容器底部（无外边距）。
        if self.layoutMode == .scroll || self.layoutMode == .fixed {
            let bottom = section.bottomAnchor.constraint(equalTo: container.bottomAnchor)
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
        self.gradientLayer.frame = self.bounds
    }

    public override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: self.height)
    }

    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
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
    ///   - action: 加载回调，完成后调用 `st_endLoadMore(paging:)`
    public func st_addLoadMore(content: STLoadMoreContent = .animation, action: @escaping () -> Void) {
        guard let sv = self.st_refreshScrollView() else { return }
        self.st_removeLoadMore()
        let footer = STLoadMoreFooterView(content: content)
        footer.attach(to: sv, action: action)
        objc_setAssociatedObject(self, st_keyPointer(STRefreshKeys.footer), footer, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    /// 结束加载动画。`.exhausted` 时显示"无更多数据"并锁定，不再自动触发。
    public func st_endLoadMore(paging: STPagingState = .hasMore) {
        (objc_getAssociatedObject(self, st_keyPointer(STRefreshKeys.footer)) as? STLoadMoreFooterView)?.endLoading(paging: paging)
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
