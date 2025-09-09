# STBaseProject Makefile

.PHONY: sync test-pod test-spm clean

# 同步 Sources 到 STBaseProject/Classes
sync:
	@echo "🔄 同步 Sources/ 到 STBaseProject/Classes/..."
	@./sync_sources.sh

# 测试 CocoaPods
test-pod: sync
	@echo "🧪 测试 CocoaPods..."
	@pod lib lint STBaseProject.podspec --allow-warnings --quick

# 测试 SPM
test-spm:
	@echo "🧪 测试 SPM..."
	@swift package resolve
	@swift build

# 测试所有包管理器
test: test-pod
	@echo "✅ CocoaPods 测试通过！"
	@echo "ℹ️  SPM 测试需要在 iOS 项目中进行"

# 清理
clean:
	@echo "🧹 清理临时文件..."
	@rm -rf STBaseProject/Classes
	@echo "✅ 清理完成"

# 默认目标
all: sync test
