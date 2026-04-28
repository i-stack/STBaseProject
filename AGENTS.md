# STBaseProject - Agent 说明

工程：`STBaseProject`（Swift Package + Example iOS 工程）。本文件为仓库级约束；用于 Cursor、Codex、Claude 的统一项目提示。

本文件为仓库级约束；**Swift/iOS 工程纪律以 `ios-engineer` 为准**（入口：`/Users/song/Desktop/github/skills/ios-engineer/SKILL.md`，细则见同目录 `references/`），本文件只写**仓库红线**与**高频入口**，避免重复长文档、省 token。

## 优先级

1. **`ios-engineer`**（路径见上）：术语、排障流程、架构/状态/并发/布局/网络/审查/迁移等完整规则。  
2. **本文件**：仅当与仓库路径、工程边界冲突时，以本文件为准。  
3. 其他 Cursor 规则：若与 `ios-engineer` 冲突，以 `ios-engineer` 为准。

## 根因优先（执行时必遵守）

- 先取证（现象、触发路径、影响范围），再定边界（责任层、状态归属、改动面）。  
- 默认只推进 1 个最高概率根因，最多保留 1 个备选，不并行大范围试错。  
- 输出结构：根因 -> 为何 -> 修法 -> 验证；优先最小可验证改动。  
- 事实不足或需求歧义时，先澄清再改，避免猜测式实现。

## 仓库红线

- 最小改动原则：只改任务相关文件，不做无关重构。  
- 非明确需求下，不修改 `Example/STBaseProject.xcodeproj/project.pbxproj` 的工程结构。  
- 不回滚、不覆盖用户已有本地改动。  
- 不擅自修改依赖产物或生成文件。  
- 影响对外行为（接口、配置、加密/网络策略）时，必须说明兼容性与回滚思路。

## Swift / iOS 实现铁律（速查）

- 语言：默认使用简体中文沟通，描述简洁、可执行。  
- 并发：优先 `async/await`；明确任务的创建、持有、取消与释放。  
- 线程：UI 相关操作必须主线程。  
- 错误：显式处理错误，禁止静默吞错。  
- 可空：避免新增 `!` / `as!`，除非有明确不可变前提。  
- 访问控制：使用最小可见性（`private`/`fileprivate`/`internal`/`public`）。  
- 注释：只为非直观逻辑写注释，不写“翻译代码式”注释。  
- 风格：不做全文件格式化或风格清洗，除非用户明确要求。

## 安全相关附加要求

- `Sources/STSecurity/` 下的改动按高风险处理。  
- 未经用户明确许可，不得弱化密钥管理、加解密、反调试、证书校验等安全默认行为。  
- 安全策略放宽必须是可配置、默认关闭，并写明风险。  
- 安全逻辑应可测试、失败路径明确且可追踪。

## 常用代码入口

| 领域 | 路径 |
|------|------|
| 网络会话 | `Sources/STNetwork/STHTTPSession.swift` |
| SSL Pinning | `Sources/STNetwork/STSSLPinningConfig.swift` |
| 安全总目录 | `Sources/STSecurity/` |
| 设备信息 | `Sources/STTools/STDeviceInfo.swift` |
| 安全集成文档 | `Docs/BusinessIntegrationGuide.md` |
| 模块使用文档 | `Docs/SourcesModulesUsage.md` |
| 安全测试 | `Tests/STBaseProjectTests/STSecurityTests.swift` |

## 验证与交付

- 优先运行与改动直接相关的测试/检查。  
- 若无法执行测试，交付时明确：已验证项、未验证项、残留风险。  
- 涉及 `STSecurity` 或 `STNetwork` 的行为变更，优先补齐或更新对应测试。  
- 仅在用户明确要求时执行 commit；commit 信息聚焦“意图与影响”。

## 快速自检（改前/改后）

- 根因是否明确，是否避免了表象修补？  
- 改动是否最小且边界清晰？  
- 并发生命周期、失败路径、线程约束是否完整？  
- 是否破坏现有 API 或默认安全行为？  
- 是否给出可复现验证步骤与残留风险说明？

