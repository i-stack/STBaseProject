#!/bin/bash

# STBaseProject 源码同步脚本
# 将 Sources/ 目录同步到 STBaseProjectCocoaPods/Classes/

echo "🔄 开始同步 Sources/ 到 STBaseProjectCocoaPods/Classes/..."

# 删除旧的 Classes 目录
if [ -d "STBaseProjectCocoaPods/Classes" ]; then
    rm -rf STBaseProjectCocoaPods/Classes
    echo "✅ 已删除旧的 STBaseProjectCocoaPods/Classes 目录"
fi

# 复制 Sources 到 Classes
cp -r Sources STBaseProjectCocoaPods/Classes
echo "✅ 已复制 Sources/ 到 STBaseProjectCocoaPods/Classes/"

# 验证文件数量
sources_count=$(find Sources -name "*.swift" | wc -l)
classes_count=$(find STBaseProjectCocoaPods/Classes -name "*.swift" | wc -l)

if [ "$sources_count" -eq "$classes_count" ]; then
    echo "✅ 同步成功！文件数量一致：$sources_count 个 Swift 文件"
else
    echo "❌ 同步失败！文件数量不一致：Sources($sources_count) vs Classes($classes_count)"
    exit 1
fi

echo "🎉 同步完成！"
