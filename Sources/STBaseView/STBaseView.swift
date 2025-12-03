//
//  STBaseView.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2018/3/14.
//

import UIKit

public enum STLayoutMode {
    case auto       // Detect at init (default), but will prefer scroll if content may exceed
    case scroll     // Always use UIScrollView
    case fixed      // Simple container (no scrolling)
    case table      // UITableView based
    case collection // UICollectionView based
}

public enum STScrollDirection {
    case vertical
    case horizontal
    case both
    case none
}

open class STBaseView: UIView {

    public private(set) var isFromXIB: Bool = false
    public private(set) var layoutMode: STLayoutMode = .auto
    public private(set) var scrollDirection: STScrollDirection = .vertical

    // If true, STBaseView will automatically enable scroll when content is larger than bounds.
    // NOTE: This detection occurs once at `didMoveToWindow` time; avoid toggling frequently.
    public var autoDetectScroll: Bool = true
    
    /// 是否启用外观模式管理（默认 true）
    /// 当 STBaseView 在 STBaseViewController 中使用时，建议设置为 false，由 STBaseViewController 统一管理外观
    public var enableAppearanceManagement: Bool = true {
        didSet {
            if !enableAppearanceManagement && oldValue {
                // 如果从启用变为禁用，移除观察者
                if let observer = self.appearanceObserver {
                    NotificationCenter.default.removeObserver(observer)
                    self.appearanceObserver = nil
                }
            } else if enableAppearanceManagement && !oldValue {
                // 如果从禁用变为启用，设置观察者
                self.setupAppearanceObservation()
            }
        }
    }
    
    public private(set) var tableViewStyle: UITableView.Style = .plain
    private(set) lazy var contentView: UIView = self.makeContentView()
    private(set) lazy var scrollView: UIScrollView = self.makeScrollView()
    private(set) lazy var tableViewPlain: UITableView = self.makeTableView(.plain)
    private(set) lazy var tableViewGrouped: UITableView = self.makeTableView(.grouped)
    private(set) lazy var collectionView: UICollectionView = self.makeCollectionView()
    private var keyboardObserverTokens: [NSObjectProtocol] = []
    private var appearanceObserver: NSObjectProtocol?

    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit(fromXIB: false)
    }

    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        self.isFromXIB = true
        self.commonInit(fromXIB: true)
    }

    deinit {
        self.removeKeyboardObservers()
        if let observer = self.appearanceObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        #if DEBUG
        print("STBaseView deinit: \(String(describing: type(of: self)))")
        #endif
    }

    private func commonInit(fromXIB: Bool) {
        self.translatesAutoresizingMaskIntoConstraints = false
        self.backgroundColor = .clear
        self.layoutMode = .auto
        self.scrollDirection = .vertical
        self.setupKeyboardObservers()
        if self.enableAppearanceManagement {
            self.setupAppearanceObservation()
        }
    }

    /// Must be called before adding subviews if you want a mode other than `.auto`.
    open func configure(layoutMode: STLayoutMode, scrollDirection: STScrollDirection = .vertical) {
        self.layoutMode = layoutMode
        self.scrollDirection = scrollDirection
        self.setupBaseAccordingToMode()
    }

    /// Convenience: configure to scroll and return scrollView for further configuration
    open func configureAsScroll(_ direction: STScrollDirection = .vertical) -> UIScrollView {
        self.configure(layoutMode: .scroll, scrollDirection: direction)
        return self.scrollView
    }

    /// Returns the effective content container into which children should be added.
    /// For `.fixed` and `.auto` when content fits, this is `self`'s contentView pinned to self.
    open func contentContainer() -> UIView {
        switch self.layoutMode {
        case .scroll:
            return self.contentView
        case .fixed, .auto:
            return self.contentView
        case .table, .collection:
            return self.contentView
        }
    }

    /// Add child to content container. Use Auto Layout for constraints.
    open func st_addContentSubview(_ view: UIView) {
        let container = self.contentContainer()
        view.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(view)
    }

    /// Helper to set lastSubview bottom anchor to contentView bottom (important for scroll)
    open func st_setBottomConstraintForLastSubview(_ subview: UIView, offset: CGFloat = -20) {
        guard subview.superview == self.contentView else {
            assertionFailure("Last subview must be added to contentView")
            return
        }
        let constraint = subview.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: offset)
        constraint.priority = .required
        constraint.isActive = true
    }

    // MARK: - Accessors for table/collection
    open func st_getTableView() -> UITableView? {
        if self.layoutMode == .table {
            if self.tableViewStyle == .plain {
                return self.tableViewPlain
            }
            if self.tableViewStyle == .grouped {
                return self.tableViewGrouped
            }
        }
        return nil
    }

    open func st_getCollectionView() -> UICollectionView? {
        return self.layoutMode == .collection ? self.collectionView : nil
    }

    private func setupBaseAccordingToMode() {
        // Remove previously added helper views (but do not remove children inside contentView)
        // We'll not destructively recreate children to avoid flashing or losing state.
        // Remove only framework-managed container views to re-add liked structure.
        self.removeManagedContainers()
        switch self.layoutMode {
        case .scroll:
            self.installScrollStructure()
        case .fixed:
            self.installFixedStructure()
        case .auto:
            // Default to scroll-enabled structure (recommended). If you prefer fixed by default, change here.
            self.installScrollStructure()
        case .table:
            self.installTableStructure()
        case .collection:
            self.installCollectionStructure()
        }
    }

    private func removeManagedContainers() {
        [scrollView, tableViewPlain, tableViewGrouped, collectionView].forEach { container in
            if container.superview == self { container.removeFromSuperview() }
        }
        if contentView.superview == self { contentView.removeFromSuperview() }
    }

    private func installScrollStructure() {
        self.addSubview(self.scrollView)
        self.scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.scrollView.topAnchor.constraint(equalTo: topAnchor),
            self.scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            self.scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            self.scrollView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        // Attach contentView to scrollView's contentLayoutGuide
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
        if let table = self.st_getTableView() {
            self.addSubview(table)
            table.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                table.topAnchor.constraint(equalTo: topAnchor),
                table.leadingAnchor.constraint(equalTo: leadingAnchor),
                table.trailingAnchor.constraint(equalTo: trailingAnchor),
                table.bottomAnchor.constraint(equalTo: bottomAnchor)
            ])
        }
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
        self.scrollView.alwaysBounceVertical = (self.scrollDirection == .vertical || self.scrollDirection == .both)
        self.scrollView.alwaysBounceHorizontal = (self.scrollDirection == .horizontal || self.scrollDirection == .both)
        self.scrollView.showsVerticalScrollIndicator = (self.scrollDirection == .vertical || self.scrollDirection == .both)
        self.scrollView.showsHorizontalScrollIndicator = (self.scrollDirection == .horizontal || self.scrollDirection == .both)

        // Default content inset adjustment. Let parent view controller adjust automatically.
        self.scrollView.contentInsetAdjustmentBehavior = .automatic
    }

    // MARK: - Appearance
    private func setupAppearanceObservation() {
        guard self.enableAppearanceManagement else { return }
        
        self.appearanceObserver = NotificationCenter.default.addObserver(
            forName: .stAppearanceDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let strongSelf = self, strongSelf.enableAppearanceManagement else { return }
            strongSelf.refreshAppearance(animated: true)
        }
        self.refreshAppearance()
    }

    private func refreshAppearance(animated: Bool = false) {
        let style = STAppearanceManager.shared.resolvedInterfaceStyle(for: self.traitCollection)
        if #available(iOS 13.0, *) {
            switch STAppearanceManager.shared.currentMode {
            case .system:
                self.overrideUserInterfaceStyle = .unspecified
            case .light:
                self.overrideUserInterfaceStyle = .light
            case .dark:
                self.overrideUserInterfaceStyle = .dark
            }
        }
        let resolvedStyle = style == .unspecified ? .light : style
        let action = { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.st_appearanceDidChange(resolvedStyle: resolvedStyle)
        }

        if animated {
            UIView.transition(with: self, duration: 0.25, options: [.transitionCrossDissolve, .allowUserInteraction], animations: action, completion: nil)
        } else {
            action()
        }
    }

    /// 外部可手动触发，保证在自定义属性变动后立即响应
    public func st_forceAppearanceRefresh(animated: Bool = false) {
        self.refreshAppearance(animated: animated)
    }

    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard self.enableAppearanceManagement else { return }
        guard #available(iOS 13.0, *) else { return }
        
        // 监听系统深浅模式切换
        // 只有当 STAppearanceManager 的模式为 .system（跟随系统）时，才响应系统切换
        guard STAppearanceManager.shared.currentMode == .system else { return }
        
        // 检查系统用户界面风格是否发生变化
        let previousStyle = previousTraitCollection?.userInterfaceStyle ?? .unspecified
        let currentStyle = self.traitCollection.userInterfaceStyle
        if previousStyle != currentStyle && previousStyle != .unspecified {
            // 系统深浅模式切换，自动更新外观
            self.refreshAppearance(animated: true)
        }
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

    // MARK: - Factory methods
    private func makeScrollView() -> UIScrollView {
        let s = UIScrollView()
        s.backgroundColor = .clear
        s.translatesAutoresizingMaskIntoConstraints = false
        s.contentInsetAdjustmentBehavior = .automatic
        return s
    }

    private func makeContentView() -> UIView {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .clear
        return v
    }

    private func makeTableView(_ style: UITableView.Style) -> UITableView {
        let t = UITableView(frame: .zero, style: style)
        t.translatesAutoresizingMaskIntoConstraints = false
        t.backgroundColor = .clear
        t.tableFooterView = UIView()
        t.rowHeight = UITableView.automaticDimension
        t.estimatedRowHeight = 44
        return t
    }

    private func makeCollectionView() -> UICollectionView {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        let c = UICollectionView(frame: .zero, collectionViewLayout: layout)
        c.translatesAutoresizingMaskIntoConstraints = false
        c.backgroundColor = .clear
        return c
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
        guard self.layoutMode == .scroll, let userInfo = note.userInfo else { return }
        let keyboardFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect) ?? .zero
        let converted = convert(keyboardFrame, from: nil)
        let insetBottom = max(0, bounds.maxY - converted.minY)
        var insets = self.scrollView.contentInset
        insets.bottom = insetBottom
        self.scrollView.contentInset = insets
        self.scrollView.scrollIndicatorInsets = insets
    }

    private func keyboardWillHide(_ note: Notification) {
        guard self.layoutMode == .scroll else { return }
        var insets = self.scrollView.contentInset
        insets.bottom = 0
        self.scrollView.contentInset = insets
        self.scrollView.scrollIndicatorInsets = insets
    }

    // MARK: - XIB Auto Migration Support (added)
    /// Migrate XIB subviews into contentView when layoutMode == .scroll
    /// This preserves XIB structure while enabling scroll mode.
    public func st_migrateXIBSubviewsIfNeeded() {
        guard self.isFromXIB else { return }
        guard self.layoutMode == .scroll else { return }
        let existing = subviews.filter { $0 !== self.scrollView && $0 !== self.contentView }
        existing.forEach { view in
            view.removeFromSuperview()
            self.contentView.addSubview(view)
            view.translatesAutoresizingMaskIntoConstraints = false
        }
        let toFix = constraints
        toFix.forEach { c in
            guard let first = c.firstItem as? UIView, let second = c.secondItem as? UIView else { return }
            if first == self || second == self {
                c.isActive = false
                let newConstraint = NSLayoutConstraint(
                    item: (first == self ? contentView : first),
                    attribute: c.firstAttribute,
                    relatedBy: c.relation,
                    toItem: (second == self ? contentView : second),
                    attribute: c.secondAttribute,
                    multiplier: c.multiplier,
                    constant: c.constant
                )
                newConstraint.priority = c.priority
                newConstraint.isActive = true
            }
        }
    }
    /// Convenience for debugging: ensure last subview has bottom constraint to contentView
    open func st_validateBottomConstraintLogging() {
        guard self.layoutMode == .scroll else { return }
        let children = self.contentView.subviews
        guard let last = children.last else { return }
        let found = (last.constraints + self.contentView.constraints + last.superview!.constraints).contains { c in
            return (c.firstItem as? UIView) == last && (c.firstAttribute == .bottom) && (c.secondItem as? UIView) == self.contentView
        }
        if !found {
            #if DEBUG
            print("⚠️ STBaseView: last subview doesn't have bottom constraint to contentView. Add st_setBottomConstraintForLastSubview(_:,offset:)")
            #endif
        }
    }
}

extension STBaseView {
    @discardableResult
    public func st_layoutMode(_ mode: STLayoutMode) -> Self {
        self.layoutMode = mode
        return self
    }
    
    @discardableResult
    public func st_tableView(_ style: UITableView.Style) -> Self {
        self.tableViewStyle = style
        return self
    }

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
        self.setupBaseAccordingToMode()
        return self
    }
}

// MARK: - Section System
open class STSection: UIView {
    
    public var inset: UIEdgeInsets
        public var spacing: CGFloat
        private let stackView: UIStackView

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
            NSLayoutConstraint.activate([
                self.stackView.topAnchor.constraint(equalTo: self.topAnchor, constant: self.inset.top),
                self.stackView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: self.inset.left),
                self.stackView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -self.inset.right),
                self.stackView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -self.inset.bottom)
            ])
        }

        /// Add multiple views (arranged) to this section (chainable)
        @discardableResult
        open func addViews(_ views: [UIView]) -> Self {
            for v in views {
                v.translatesAutoresizingMaskIntoConstraints = false
                self.stackView.addArrangedSubview(v)
            }
            return self
        }

        /// Add a single view
        @discardableResult
        open func addView(_ view: UIView) -> Self {
            view.translatesAutoresizingMaskIntoConstraints = false
            self.stackView.addArrangedSubview(view)
            return self
        }

        /// Clear all arranged subviews
        @discardableResult
        open func clear() -> Self {
            for v in self.stackView.arrangedSubviews {
                self.stackView.removeArrangedSubview(v)
                v.removeFromSuperview()
            }
            return self
        }

        /// Update spacing (dynamically)
        @discardableResult
        open func setSpacing(_ spacing: CGFloat) -> Self {
            self.spacing = spacing
            self.stackView.spacing = spacing
            return self
        }

        /// Update inset (dynamically) — updates constraints by removing and readding
        @discardableResult
        open func setInset(_ inset: UIEdgeInsets) -> Self {
            self.inset = inset
            NSLayoutConstraint.deactivate(self.constraints.filter { constraint in
                return constraint.firstItem as? UIView == self.stackView || constraint.secondItem as? UIView == self.stackView
            })
            NSLayoutConstraint.activate([
                self.stackView.topAnchor.constraint(equalTo: self.topAnchor, constant: self.inset.top),
                self.stackView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: self.inset.left),
                self.stackView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -self.inset.right),
                self.stackView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -self.inset.bottom)
            ])
            return self
        }
}

extension STBaseView {
    public func st_addSection(_ section: STSection) {
        let container = self.contentContainer()
        container.addSubview(section)
        section.translatesAutoresizingMaskIntoConstraints = false
        if let last = container.subviews.dropLast().last {
            section.topAnchor.constraint(equalTo: last.bottomAnchor, constant: section.spacing).isActive = true
        } else {
            section.topAnchor.constraint(equalTo: container.topAnchor, constant: section.inset.top).isActive = true
        }
        NSLayoutConstraint.activate([
            section.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: section.inset.left),
            section.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -section.inset.right)
        ])
        self.setNeedsLayout()
    }
}

// MARK: - State Pages (loading / empty / error)
extension STBaseView {
    
    private struct StateKeys {
        static var loading = "st_loadingView"
        static var empty = "st_emptyView"
        static var error = "st_errorView"
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

    public func st_showLoading() {
        self.st_hideAllStates()
        let v = self.st_makeStateView("Loading…")
        self.addSubview(v)
        NSLayoutConstraint.activate([
            v.topAnchor.constraint(equalTo: self.topAnchor),
            v.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            v.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            v.trailingAnchor.constraint(equalTo: self.trailingAnchor)
        ])
        objc_setAssociatedObject(self, &StateKeys.loading, v, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    public func st_showEmpty(_ text: String = "No Data") {
        self.st_hideAllStates()
        let v = self.st_makeStateView(text)
        self.addSubview(v)
        NSLayoutConstraint.activate([
            v.topAnchor.constraint(equalTo: self.topAnchor),
            v.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            v.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            v.trailingAnchor.constraint(equalTo: self.trailingAnchor)
        ])
        objc_setAssociatedObject(self, &StateKeys.empty, v, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

//    public func st_showError(_ text: String = "Load Failed") {
//        self.st_hideAllStates()
//        let v = self.st_makeStateView(text)
//        self.addSubview(v)
//        NSLayoutConstraint.activate([
//            v.topAnchor.constraint(equalTo: self.topAnchor),
//            v.bottomAnchor.constraint(equalTo: self.bottomAnchor),
//            v.leadingAnchor.constraint(equalTo: self.leadingAnchor),
//            v.trailingAnchor.constraint(equalTo: self.trailingAnchor)
//        ])
//        objc_setAssociatedObject(self, &StateKeys.error, v, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
//    }

    public func st_hideAllStates() {
        self.st_removeStateView(with: &StateKeys.loading)
        self.st_removeStateView(with: &StateKeys.empty)
        self.st_removeStateView(with: &StateKeys.error)
    }

    private func st_removeStateView(with key: UnsafeRawPointer) {
        if let v = objc_getAssociatedObject(self, key) as? UIView {
            v.removeFromSuperview()
            objc_setAssociatedObject(self, key, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

// MARK: - Dynamic Gradient Navigation Bar Support
open class STGradientNavigationBar: UIView {
    
    public var startColor: UIColor = .clear { didSet { self.setNeedsLayout() } }
    public var endColor: UIColor = .black { didSet { self.setNeedsLayout() } }
    public var height: CGFloat = 88 { didSet { self.invalidateIntrinsicContentSize() } }

    private let gradientLayer = CAGradientLayer()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.layer.addSublayer(self.gradientLayer)
    }
    required public init?(coder: NSCoder) { super.init(coder: coder) }

    public override func layoutSubviews() {
        super.layoutSubviews()
        self.gradientLayer.frame = self.bounds
        self.gradientLayer.colors = [self.startColor.cgColor, self.endColor.cgColor]
        self.gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        self.gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
    }

    public override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: self.height)
    }
}
