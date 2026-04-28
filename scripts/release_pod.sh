#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PODSPEC_PATH="${ROOT_DIR}/STBaseProject.podspec"
CREATE_TAG=false
PUSH_TAG=false
ALLOW_DIRTY=false
SKIP_LINT=false

usage() {
  cat <<'EOF'
用法:
  ./scripts/release_pod.sh <new_version> [--tag] [--push-tag] [--allow-dirty] [--skip-lint]

示例:
  ./scripts/release_pod.sh 1.1.6
  ./scripts/release_pod.sh 1.1.6 --tag --push-tag

参数:
  --tag         自动创建 git tag（同版本号）
  --push-tag    自动推送 tag 到 origin（需搭配 --tag）
  --allow-dirty 允许在非干净工作区执行（默认不允许）
  --skip-lint   跳过 pod spec lint（不建议）
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" || $# -eq 0 ]]; then
  usage
  exit 0
fi

NEW_VERSION="$1"
shift

while [[ $# -gt 0 ]]; do
  case "$1" in
    --tag)
      CREATE_TAG=true
      ;;
    --push-tag)
      PUSH_TAG=true
      ;;
    --allow-dirty)
      ALLOW_DIRTY=true
      ;;
    --skip-lint)
      SKIP_LINT=true
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "错误: 未知参数 $1"
      usage
      exit 1
      ;;
  esac
  shift
done

if [[ "${PUSH_TAG}" == "true" && "${CREATE_TAG}" != "true" ]]; then
  echo "错误: --push-tag 需要与 --tag 一起使用。"
  exit 1
fi

if [[ ! "${NEW_VERSION}" =~ ^[0-9]+\.[0-9]+\.[0-9]+([.-][0-9A-Za-z]+)*$ ]]; then
  echo "错误: 版本号格式不合法: ${NEW_VERSION}"
  echo "示例: 1.2.3 或 1.2.3-beta.1"
  exit 1
fi

if [[ ! -f "${PODSPEC_PATH}" ]]; then
  echo "错误: 找不到 podspec: ${PODSPEC_PATH}"
  exit 1
fi

if ! command -v pod >/dev/null 2>&1; then
  echo "错误: 未检测到 CocoaPods 命令 pod，请先安装 CocoaPods。"
  exit 1
fi

if ! command -v git >/dev/null 2>&1; then
  echo "错误: 未检测到 git 命令。"
  exit 1
fi

if [[ "${ALLOW_DIRTY}" != "true" ]]; then
  if [[ -n "$(git -C "${ROOT_DIR}" status --porcelain)" ]]; then
    echo "错误: 当前工作区不干净，请先提交/暂存变更，或使用 --allow-dirty。"
    exit 1
  fi
fi

CURRENT_VERSION="$(ruby -e "content = File.read('${PODSPEC_PATH}'); puts(content[/s\\.version\\s*=\\s*'([^']+)'/, 1] || '')")"
if [[ -z "${CURRENT_VERSION}" ]]; then
  echo "错误: 无法从 podspec 读取当前版本。"
  exit 1
fi

if [[ "${CURRENT_VERSION}" == "${NEW_VERSION}" ]]; then
  echo "当前版本已是 ${NEW_VERSION}，无需修改。"
else
  ruby -pi -e "gsub(/(s\\.version\\s*=\\s*')[^']+(')/, \"\\\\1${NEW_VERSION}\\\\2\")" "${PODSPEC_PATH}"
  echo "已更新版本: ${CURRENT_VERSION} -> ${NEW_VERSION}"
fi

if [[ "${CREATE_TAG}" == "true" ]]; then
  if git -C "${ROOT_DIR}" rev-parse -q --verify "refs/tags/${NEW_VERSION}" >/dev/null; then
    echo "错误: 本地 tag ${NEW_VERSION} 已存在。"
    exit 1
  fi

  git -C "${ROOT_DIR}" tag "${NEW_VERSION}"
  echo "已创建本地 tag: ${NEW_VERSION}"
else
  if ! git -C "${ROOT_DIR}" rev-parse -q --verify "refs/tags/${NEW_VERSION}" >/dev/null; then
    echo "错误: 缺少本地 tag ${NEW_VERSION}。可添加 --tag 自动创建。"
    exit 1
  fi
  echo "已检测到本地 tag: ${NEW_VERSION}"
fi

if [[ "${PUSH_TAG}" == "true" ]]; then
  git -C "${ROOT_DIR}" push origin "${NEW_VERSION}"
  echo "已推送 tag 到 origin: ${NEW_VERSION}"
else
  if ! git -C "${ROOT_DIR}" ls-remote --exit-code --tags origin "refs/tags/${NEW_VERSION}" >/dev/null 2>&1; then
    echo "错误: origin 不存在 tag ${NEW_VERSION}。可添加 --push-tag 自动推送。"
    exit 1
  fi
  echo "已检测到远端 tag: ${NEW_VERSION}"
fi

TAG_COMMIT="$(git -C "${ROOT_DIR}" rev-list -n 1 "${NEW_VERSION}")"
HEAD_COMMIT="$(git -C "${ROOT_DIR}" rev-parse HEAD)"
if [[ "${TAG_COMMIT}" != "${HEAD_COMMIT}" ]]; then
  echo "错误: tag ${NEW_VERSION} 未指向当前 HEAD。"
  echo "tag:  ${TAG_COMMIT}"
  echo "HEAD: ${HEAD_COMMIT}"
  exit 1
fi
echo "已确认 tag ${NEW_VERSION} 与当前 HEAD 一致。"

if [[ "${SKIP_LINT}" != "true" ]]; then
  echo "开始校验 podspec..."
  pod spec lint "${PODSPEC_PATH}" --allow-warnings
else
  echo "已跳过 podspec 校验。"
fi

echo "开始发布 pod..."
pod trunk push "${PODSPEC_PATH}" --allow-warnings

echo "发布完成: STBaseProject ${NEW_VERSION}"
