#!/bin/bash
# 构建 fanyi.app：swiftc 直接编译 SwiftUI 源码 + 手写 Info.plist 打成 .app
set -euo pipefail
cd "$(dirname "$0")"

APP="fanyi.app"
BIN="$APP/Contents/MacOS/fanyi"

mkdir -p "$APP/Contents/MacOS"
swiftc -parse-as-library -O Sources/main.swift -o "$BIN"
cp Info.plist "$APP/Contents/Info.plist"

# 有开发者证书就用它签名，没有则 ad-hoc 签名（保证本地可运行）
IDENTITY=$(security find-identity -v -p codesigning 2>/dev/null | grep -o '"[^"]*"' | head -1 | tr -d '"' || true)
if [ -n "$IDENTITY" ]; then
    codesign --force --sign "$IDENTITY" "$APP" 2>/dev/null \
        && echo "已签名: $IDENTITY" \
        || codesign --force --sign - "$APP"
else
    codesign --force --sign - "$APP"
fi

echo "构建完成: $APP"
