---
name: STBaseView 架构评审
description: STBaseView 的适用范围、容器切换风险与验证方法
type: project
---

# STBaseView 架构评审结果

### 评审结论

STBaseView 适合在页面初始化时选定布局模式，承载固定内容、表单或标准 UIKit 列表。运行期切换模式或替换容器时，调用方需要关注刷新控件归属、键盘边距恢复和旧容器清理。

### 核实后的架构边界

1. **模式切换。** `installLayoutStructure()` 同步拆装容器，未内置过渡动画。同一实例可以复用，但刷新控件仍绑定添加时的滚动容器。`configure(...)` 与 `st_layoutMode(_:)` 在离开 `.scroll` 前都会调用 `keyboardBehavior.restoreIfNeeded()`，由 `STKeyboardAdjustmentBehavior` 内部判断是否存在未恢复的键盘 inset 并强制还原，不依赖键盘隐藏通知之后是否还能在 `.scroll` 下触达。验证时分别检查切换前后的刷新回调归属，以及离开 `.scroll` 后三组 inset 是否已还原为基准值。
2. **替换容器。** `configure(...)`、`st_tableView(_:)`、`st_collectionView(_:)` 替换已安装的 table 或 collection 时，统一走 `replaceTableView(with:internallyCreated:)` / `replaceCollectionView(with:)`：仅当新实例与现有引用不同才替换；替换时先把引用切到新实例，再用局部变量持有的旧实例判断其 `superview` 是否为 `self`，是则移除。验证时分别用不同的 A、B 实例连续配置 table 和 collection，检查 A 是否已脱离层级、B 是否是唯一已安装的列表容器。
3. **Table 样式。** `st_tableViewStyle(_:)` 在首次创建前记录样式。同样式调用直接返回，外部注入实例也不会因样式变更而重建。对已创建的内部默认实例改用不同样式时，Debug 会触发断言。Release 会丢弃旧实例，新实例需要重新配置 delegate、dataSource、cell 注册、滚动位置和刷新控件。分别验证首次配置、外部注入和内部实例创建后改样式三条路径。
4. **嵌套滚动与扩展。** `STKeyboardAdjustmentBehavior` 只调整注入的 `scrollView`，且仅在宿主 `isActive()`（对应 `.scroll`）为真时生效；`st_refreshScrollView()` 只选择当前模式的主容器，`.fixed` 不支持刷新和加载更多。键盘与刷新实现依赖 `UIScrollView` 的 inset、offset 等接口。嵌套或非标准容器需要调用方自行协调键盘、刷新目标和手势，是否发生手势冲突需在实际层级中验证。
5. **列表与数据职责。** `.scroll` 挂载调用方添加的子视图，不提供按可见区域创建或复用的机制。长列表优先选用 `.table` 或 `.collection`，由 UIKit 负责 cell 复用。STBaseView 提供容器和视图操作，列表数据源、diff 和业务状态同步由调用方负责，可按需要采用传统或 diffable data source，并由 ViewModel 或适配层管理复杂状态。

源码依据见 [STBaseView.swift](../Sources/STBaseView/STBaseView.swift)，重点对应 `installLayoutStructure()`、`configure(...)`、`replaceTableView(with:internallyCreated:)`、`replaceCollectionView(with:)`、`st_tableViewStyle(_:)`、`st_refreshScrollView()` 和 `st_addContentSubview(_:)`；键盘适配见 [STKeyboardAdjustmentBehavior.swift](../Sources/STBaseView/STKeyboardAdjustmentBehavior.swift)，刷新/加载更多控件生命周期见 [STRefreshBehavior.swift](../Sources/STBaseView/STRefreshBehavior.swift)。

### 组合式拆分（Behavior 对象）

键盘适配和刷新/加载更多已经从 `STBaseView` 内部拆分为两个独立对象，通过组合方式持有：

- `STKeyboardAdjustmentBehavior`（`keyboardBehavior`）：封装键盘观察者的注册/移除、基准 inset 的捕获与还原。`STBaseView` 注入 `hostView`（`self`）、`scrollViewProvider`（`{ [weak self] in self?.scrollView }`）和 `isActive` 闭包（`{ layoutMode == .scroll }`），不再直接持有 `baseContentInset` 等私有状态。`scrollView` 用 provider 闭包而非直接持有实例，因为 `STBaseView.scrollView` 是 `open` 的，子类可以重写该 getter 在不同时机返回不同实例，每次键盘事件都要取当前值。`enableScrollViewKeyboardAdjustment` 保持原有公开签名，内部转发到 `keyboardBehavior.isEnabled`。
- `STRefreshBehavior`（`refreshBehavior`）：封装下拉刷新 `STRefreshHeaderView` / 上拉加载更多 `STLoadMoreFooterView` 的持有与转发，替代原来基于 `objc_setAssociatedObject` 的关联对象存储。`st_addPullToRefresh`/`st_removePullToRefresh`/`st_addLoadMore`/`st_removeLoadMore` 等公开方法签名不变，内部直接转发。

两个对象都是 internal（不对外暴露新的公开类型），键盘适配和刷新/加载更多逻辑不再直接写在 `STBaseView.swift` 内部。

### 验证范围

以上结论基于源码核对，Behavior 对象拆分前后均用相同命令重新编译确认过 `BUILD SUCCEEDED`。STBaseProject 的 Debug 模拟器构建已通过（`STBaseProjectExample.xcodeproj` 的 `STBaseProject` scheme，iPhoneSimulator SDK，arm64 + x86_64），工程基线为 iOS 16、Swift tools 5.9、Swift 5 语言模式。容器替换、键盘与刷新状态切换、嵌套手势和列表性能尚未在真机/模拟器上手工跑过运行时验证。
