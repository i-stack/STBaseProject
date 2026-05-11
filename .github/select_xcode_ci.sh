#!/usr/bin/env bash
# 在 Runner / 本机上选择 /Applications 里「版本号最高」的 Xcode（读 Info.plist），
# 不绑定 26 / 27 / 28：镜像侧载命名 Xcode_16.x / Xcode_26.x / Xcode_27.x 或仅 Xcode.app 均可自动跟上。
set -euo pipefail
shopt -s nullglob

bundle_short_version() {
  local app="$1"
  /usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$app/Contents/Info.plist" 2>/dev/null || true
}

declare -a candidates=(/Applications/Xcode_[0-9]*.app)
[[ -d /Applications/Xcode.app ]] && candidates+=(/Applications/Xcode.app)

best_app=""
best_ver="0.0.0"

for app in "${candidates[@]}"; do
  [[ -d "$app" ]] || continue
  ver="$(bundle_short_version "$app")"
  [[ -n "$ver" ]] || continue
  hi="$(printf '%s\n' "$best_ver" "$ver" | sort -V | tail -n 1)"
  if [[ "$hi" == "$ver" ]]; then
    best_ver="$ver"
    best_app="$app"
  fi
done

if [[ -z "$best_app" ]]; then
  echo "::error::No usable Xcode under /Applications (need Xcode_[0-9]*.app or Xcode.app with Info.plist)."
  ls -la /Applications/Xcode*.app 2>/dev/null || true
  exit 1
fi

echo "Using: $best_app (CFBundleShortVersionString=$best_ver)"
sudo xcode-select -s "$best_app"
xcodebuild -version
