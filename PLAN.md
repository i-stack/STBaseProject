# Plan: 移除 2.0 中的 1.x 兼容 API

## Goal
从 feature_2.0.0 删除仅为 1.x 源码兼容保留的公共 API，并把仓库内调用方迁移到 2.0 API。

## Constraints & assumptions
- 保留持久化数据、加密数据、XIB/Storyboard 和系统版本兼容逻辑。
- 保留当前工作区已有的 Dynamic Type 与容器布局改动，不回退或格式化无关代码。
- 旧 API 的识别依据为 deprecated 标记、明确的 legacy/兼容注释及 completion 到 Publisher 的桥接入口。

## Approach
先删除已有等价替代的 deprecated/兼容包装，再迁移 Sources 与 Example 中的调用方和测试。字体与布局旧入口迁移到 Dynamic Type、Typography token 或容器布局 API；网络 completion 入口迁移到 Publisher。最后以残留符号扫描、SwiftPM 构建及可运行测试验证。

## Key decisions & tradeoffs
- 选择在 2.0 直接删除源码兼容包装，不再保留一个额外弃用周期，因为用户已确认接受 breaking changes。
- 不删除运行时数据和资源兼容，因为它们不能靠保留 release_1.3.0 分支恢复。
- 不把仅含 `legacy` 内部命名、但不属于公共兼容 API 的实现当作删除目标。

## Validation plan
- 扫描所有被删除符号，确保 Sources 与 Example 无残留调用。
- 构建 Swift Package，并运行可用测试。
- 检查 diff，确认没有覆盖工作区无关改动。

## Risks / non-blocking open questions
- 仓库外调用方将产生预期的源码不兼容，需要 2.0 migration notes 列出替代关系。
- 当前工作区已有未提交改动，验证结果代表组合后的工作树状态。

## Out of scope
- 删除历史分支或 tag。
- 修改持久化/密文格式、XIB/Storyboard 兼容语义或最低系统版本。
