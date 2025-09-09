# STBaseProject 开发指南

## 📁 项目结构

```
STBaseProject/
├── Sources/                    # 主要源码目录（SPM 使用）
│   ├── STBaseModule/          # 基础架构模块
│   └── STKit/                 # 专业功能模块
├── STBaseProject/
│   └── Classes/               # CocoaPods 使用（自动同步）
├── sync_sources.sh            # 同步脚本
├── Makefile                   # 构建工具
└── STBaseProject.podspec      # CocoaPods 配置
```

## 🔄 同步机制

为了避免维护两份相同的代码，我们使用自动同步机制：

### 自动同步
- **Git Hook**: 每次 `git commit` 前自动同步
- **手动同步**: 运行 `make sync` 或 `./sync_sources.sh`

### 同步流程
1. 修改 `Sources/` 目录中的代码
2. 运行 `make sync` 同步到 `STBaseProject/Classes/`
3. 提交代码（Git Hook 会自动同步）

## 🛠️ 开发命令

```bash
# 同步源码
make sync

# 测试 CocoaPods
make test-pod

# 测试所有（推荐）
make test

# 清理临时文件
make clean
```

## 📦 包管理器支持

### CocoaPods
```ruby
# Podfile
pod 'STBaseProject', :path => '.'
# 或使用特定模块
pod 'STBaseProject/STBaseModule'
pod 'STBaseProject/STKitLocation'
```

### Swift Package Manager
```swift
// Package.swift
dependencies: [
    .package(path: ".")
]

// 在代码中使用 - 多种导入方式
import STBaseProject        // 所有功能
import STBaseModule         // 基础模块
import STKitLocation        // 位置服务
import STKitScan           // 扫描功能
import STKitMedia          // 媒体处理
import STKitDialog         // 对话框组件
```

**模块化导入**：
- `STBaseProject`：包含所有功能（推荐）
- `STBaseModule`：基础架构模块
- `STKit*`：专业功能模块（按需导入）

## ⚠️ 注意事项

1. **只修改 Sources/ 目录**：所有代码修改都在 `Sources/` 中进行
2. **自动同步**：`STBaseProject/Classes/` 是自动生成的，不要手动修改
3. **Git 提交**：每次提交前会自动同步，确保两个目录一致

## 🔧 故障排除

### 同步失败
```bash
# 手动运行同步脚本
./sync_sources.sh
```

### Git Hook 不工作
```bash
# 重新设置 Git Hook
chmod +x .git/hooks/pre-commit
```

### 清理重新开始
```bash
# 清理并重新同步
make clean
make sync
```
