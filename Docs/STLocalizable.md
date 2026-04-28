# STLocalizable 功能说明

本文档聚焦 `Sources/STLocalizable` 目录，按功能拆解本地化模块的职责、调用关系和接入方式，便于在业务中稳定使用语言切换能力。

---

## 目录结构

- `STLocalizableProtocol.swift`：定义可本地化视图协议
- `STLocalizationManager.swift`：语言包选择、持久化、字符串读取、通知分发、启动恢复
- `STViewControllerLocalization.swift`：`STBaseViewController` 层面的本地化刷新整合

---

## 功能一：可本地化视图协议

### 目标

统一约束“哪些视图支持运行时语言切换刷新”，避免业务层通过类型判断逐个手动刷新。

### 关键点

- 协议：`STLocalizable`
- 方法：`st_updateLocalizedText()`
- 设计方式：由 `STLabel`、`STBtn`、`STTextField` 等封装控件显式实现

### 使用方式

1. 组件实现 `STLocalizable`。
2. 在 `st_updateLocalizedText()` 内部重新根据 key 拉取文案并更新 UI。
3. 语言切换后由控制器递归遍历视图树触发刷新。

---

## 功能二：语言管理与字符串读取

对应文件：`STLocalizationManager.swift`

### 2.1 可用语言建模与发现

- 结构体：`STSupportedLanguage`
- 字段：`languageCode`、`displayName`、`locale`
- 能力：`getAvailableLanguages()` 扫描 `Bundle.main` 下的 `.lproj`（排除 `Base.lproj`）并排序返回
- 注意：该方法包含文件 I/O，调用方应缓存结果，避免高频扫描

### 2.2 本地化读取入口

- `Bundle.st_localizedString(key:tableName:)`：优先使用当前自定义语言包，否则回退到 `Bundle.main`
- `String.localized` / `String.localized(tableName:)`：字符串快捷调用

### 2.3 运行时语言切换

- `Bundle.st_setCustomLanguage(_:)`：切换语言代码（例如 `zh-Hans`、`en`）
- `Bundle.st_setSupportedLanguage(_:)`：用 `STSupportedLanguage` 对象切换
- `Bundle.st_clearCustomLanguage()`：清除自定义语言并恢复“跟随系统”
- `Bundle.st_getCurrentLanguage()` / `st_getCurrentLanguageObject()`：获取当前自定义语言
- `Bundle.st_getSystemLanguage()`：读取系统首选语言
- `Bundle.st_isLanguageAvailable(_:)`：校验目标语言包是否存在

### 2.4 语言切换通知

- 通知名：`Notification.Name.stLanguageDidChange`
- 触发时机：
  - 设置自定义语言成功后发送
  - 清除自定义语言后发送
- `object` 约定：
  - 设置语言时为 `languageCode`
  - 清除语言时为 `nil`

### 2.5 启动配置与自动恢复

- 入口：`Bundle.st_configureLocalization()`
- 推荐时机：`application(_:didFinishLaunchingWithOptions:)`
- 行为顺序：
  1. 安装 `Bundle.localizedString` 方法替换（仅一次）
  2. 恢复上次保存的自定义语言（若可用）
  3. 若无有效持久化值，则按系统语言匹配可用语言
  4. 若仍未匹配到，则回退到可用语言列表首项

### 2.6 方法替换机制（Swizzle）

- 模块通过 `method_exchangeImplementations` 替换 `Bundle.localizedString(forKey:value:table:)`
- 仅对 `Bundle.main` 生效
- 自定义语言包通过 Associated Object 挂在 `Bundle.main` 上
- 目的：保证包含 `NSLocalizedString` 在内的主 bundle 字符串读取都自动走当前语言包

---

## 功能三：控制器层本地化刷新整合

对应文件：`STViewControllerLocalization.swift`

### 3.1 扩展入口

- 扩展对象：`STBaseViewController`
- 核心方法：`st_updateLocalizedTexts()`
- 刷新内容：
  - 导航标题（`titleLabel.text`）
  - `navigationItem.prompt`
  - 当前页面视图树内所有实现了 `STLocalizable` 的视图

### 3.2 标题 key 保护机制

- 使用 Associated Object 记录原始 key：
  - `st_vcTitleKey`
  - `st_navPromptKey`
- 目的：避免语言切换后把“已翻译字符串”当成下一次翻译 key，导致二次切换失效

### 3.3 视图树递归刷新

- 私有方法 `updateLocalizedTextsInView(_:)` 递归遍历 `view.subviews`
- 对命中 `STLocalizable` 的视图调用 `st_updateLocalizedText()`
- 这样可覆盖页面中已挂载的控件层级

---

## 推荐集成流程

1. 在 App 启动阶段调用 `Bundle.st_configureLocalization()`。
2. 页面继承 `STBaseViewController`，确保接入语言切换通知链路。
3. 自定义控件实现 `STLocalizable`，并在 `st_updateLocalizedText()` 中按 key 刷新文案。
4. 业务切换语言时统一调用 `Bundle.st_setCustomLanguage(_:)` 或 `Bundle.st_setSupportedLanguage(_:)`。
5. 若要恢复系统语言，调用 `Bundle.st_clearCustomLanguage()`。

---

## 边界与注意事项

- `st_setCustomLanguage(_:)` 传入不存在的语言包时会打印告警并直接返回，不会发送变更通知。
- 可用语言扫描依赖 `Bundle.main` 的 `.lproj`，如果业务资源放在其他 bundle，需要额外扩展策略。
- 该模块默认表名是 `Localizable`，如业务使用多表，应显式传入 `tableName`。
- 语言切换后的 UI 刷新依赖页面和控件实现约定；未实现 `STLocalizable` 的视图不会自动更新文本。

