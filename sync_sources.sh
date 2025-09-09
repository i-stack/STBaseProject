#!/bin/bash

# STBaseProject 源码同步脚本
# 将 Sources/ 目录同步到 STBaseProject/Classes/

echo "🔄 开始同步 Sources/ 到 STBaseProject/Classes/..."

# 删除旧的 Classes 目录
if [ -d "STBaseProject/Classes" ]; then
    rm -rf STBaseProject/Classes
    echo "✅ 已删除旧的 STBaseProject/Classes 目录"
fi

# 复制 Sources 到 Classes
cp -r Sources STBaseProject/Classes
echo "✅ 已复制 Sources/ 到 STBaseProject/Classes/"

# 验证文件数量
sources_count=$(find Sources -name "*.swift" | wc -l)
classes_count=$(find STBaseProject/Classes -name "*.swift" | wc -l)

if [ "$sources_count" -eq "$classes_count" ]; then
    echo "✅ 同步成功！文件数量一致：$sources_count 个 Swift 文件"
else
    echo "❌ 同步失败！文件数量不一致：Sources($sources_count) vs Classes($classes_count)"
    exit 1
fi

echo "🎉 同步完成！"
