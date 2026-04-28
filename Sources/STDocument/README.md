# STDocument 文档索引

`STDocument` 用于统一管理 `STBaseProject` 的内部使用文档与专题说明。

## 文档列表

- `STHTTPSession.md`  
  网络层使用文档（会话配置、请求、上传下载、流式响应、拦截器、事件监听、SSL Pinning 等）。

- `SourcesModulesUsage.md`  
  `Sources` 目录按文件夹分类的模块使用说明（定位、适用场景、核心文件、使用建议）。

- `BusinessIntegrationGuide.md`  
  面向业务接入的落地指南（启动配置、页面接入、网络接入、Markdown 接入、安全与日志清单）。

- `STSecurity.md`  
  `STSecurity` 目录专题文档（配置中枢、加解密、Keychain、反调试监控与接入建议）。

## 维护约定

- 新增公共能力时，优先评估是否需要补充文档并登记到本索引。
- 文档命名建议采用 `模块名 + Usage/Guide`，便于统一检索。
- 重要模块建议同时提供“快速上手 + 常见问题 + 风险提示”。
