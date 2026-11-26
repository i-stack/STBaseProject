---
name: STBaseView 架构评审
description: STBaseView 的适用范围、容器切换风险与验证方法
type: project
---

# STBaseView 架构评审结果

### 评审结论

STBaseView 适合在页面初始化时选定布局模式，承载固定内容、表单或标准 UIKit 列表。运行期切换模式或替换容器时，调用方需要关注刷新控件归属、键盘边距恢复和旧容器清理。

### 核实后的架构边界

1. **模式切换。** `installLayoutStructure()` 同步拆装容器，未内置过渡动画。同一实例可以复用，但刷新控件仍绑定添加时的滚动容器。`configure(...)` 与 `st_layoutMode(_:)` 在离开 `.scroll` 前会检查是否存在未恢复的键盘 inset，有则立即调用 `restoreBaseInsets()` 还原，不依赖键盘隐藏通知之后是否还能在 `.scroll` 下触达。验证时分别检查切换前后的刷新回调归属，以及离开 `.scroll` 后三组 inset 是否已还原为基准值。
2. **替换容器。** `configure(...)`、`st_tableView(_:)`、`st_collectionView(_:)` 替换已安装的 table 或 collection 时，统一走 `replaceTableView(with:internallyCreated:)` / `replaceCollectionView(with:)`：仅当新实例与现有引用不同才替换，替换前会判断旧实例的 `superview` 是否为 `self`，是则先移除，再切换引用。验证时分别用不同的 A、B 实例连续配置 table 和 collection，检查 A 是否已脱离层级、B 是否是唯一已安装的列表容器。
3. **Table 样式。** `st_tableViewStyle(_:)` 在首次创建前记录样式。同样式调用直接返回，外部注入实例也不会因样式变更而重建。对已创建的内部默认实例改用不同样式时，Debug 会触发断言。Release 会丢弃旧实例，新实例需要重新配置 delegate、dataSource、cell 注册、滚动位置和刷新控件。分别验证首次配置、外部注入和内部实例创建后改样式三条路径。
4. **嵌套滚动与扩展。** `adjustForKeyboard` 仅调整 `.scroll` 的主滚动容器，`st_refreshScrollView()` 只选择当前模式的主容器，`.fixed` 不支持刷新和加载更多。键盘与刷新实现依赖 `UIScrollView` 的 inset、offset 等接口。嵌套或非标准容器需要调用方自行协调键盘、刷新目标和手势，是否发生手势冲突需在实际层级中验证。
5. **列表与数据职责。** `.scroll` 挂载调用方添加的子视图，不提供按可见区域创建或复用的机制。长列表优先选用 `.table` 或 `.collection`，由 UIKit 负责 cell 复用。STBaseView 提供容器和视图操作，列表数据源、diff 和业务状态同步由调用方负责，可按需要采用传统或 diffable data source，并由 ViewModel 或适配层管理复杂状态。

源码依据见 [STBaseView.swift](../Sources/STBaseView/STBaseView.swift)，重点对应 `installLayoutStructure()`、`configure(...)`、`replaceTableView(with:internallyCreated:)`、`replaceCollectionView(with:)`、`st_tableViewStyle(_:)`、`adjustForKeyboard`、`st_refreshScrollView()` 和 `st_addContentSubview(_:)`。

### 可能的架构演进

**Behavior 对象抽离（组合优于继承）。** `STBaseView.swift` 单个文件承载布局安装、外观管理、键盘适配、状态页、刷新/加载更多等五类职责，已超过 1000 行；其中键盘适配（`adjustForKeyboard` 及 `baseContentInset` 等私有状态）和刷新/加载更多（`st_addPullToRefresh`/`st_addLoadMore`）目前都直接实现在基类内部，无法脱离 `STBaseView` 单独测试或复用。可以考虑把这两部分拆分为独立的 Behavior 对象（例如 `STKeyboardAdjustmentBehavior`、`STRefreshBehavior`），通过组合方式注入 `STBaseView`，而不是让基类直接持有这些逻辑。收益是职责分离后可独立测试，也便于非 `STBaseView` 的场景复用同一套键盘/刷新逻辑；代价是需要把 `baseContentInset`、`baseVerticalIndicatorInsets` 等私有状态迁移到独立对象，涉及多处调用点改造。这是后续迭代方向，不在当前版本范围内。

### 验证范围

以上结论基于源码核对。STBaseProject 的 Debug 模拟器构建已通过（`STBaseProjectExample.xcodeproj` 的 `STBaseProject` scheme，iPhoneSimulator SDK，arm64 + x86_64），工程基线为 iOS 16、Swift tools 5.9、Swift 5 语言模式。容器替换、键盘与刷新状态切换、嵌套手势和列表性能尚未在真机/模拟器上手工跑过运行时验证。
