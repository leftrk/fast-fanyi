#!/bin/bash
# 构建 fanyi.app：swiftc 直接编译 SwiftUI 源码 + 手写 Info.plist 打成 .app
set -euo pipefail
cd "$(dirname "$0")"

APP="fanyi.app"
BIN="$APP/Contents/MacOS/fanyi"

mkdir -p "$APP/Contents/MacOS"
swiftc -parse-as-library -O Sources/main.swift -o "$BIN"
cp Info.plist "$APP/Contents/Info.plist"

# 应用图标：缺失或源码更新时用 scripts/make-icon.swift 重新生成
ICNS="$APP/Contents/Resources/AppIcon.icns"
mkdir -p "$APP/Contents/Resources"
if [ ! -f "$ICNS" ] || [ scripts/make-icon.swift -nt "$ICNS" ]; then
    [ -x scripts/make-icon ] || swiftc -O scripts/make-icon.swift -o scripts/make-icon
    TMP=$(mktemp -d)
    ./scripts/make-icon "$TMP/icon_1024.png"
    ICONSET="$TMP/AppIcon.iconset"
    mkdir -p "$ICONSET"
    for spec in "16:icon_16x16" "32:icon_16x16@2x" "32:icon_32x32" "64:icon_32x32@2x" \
                "128:icon_128x128" "256:icon_128x128@2x" "256:icon_256x256" "512:icon_256x256@2x" \
                "512:icon_512x512" "1024:icon_512x512@2x"; do
        px="${spec%%:*}"; name="${spec##*:}"
        sips -z "$px" "$px" "$TMP/icon_1024.png" --out "$ICONSET/$name.png" >/dev/null
    done
    iconutil -c icns "$ICONSET" -o "$ICNS"
    rm -rf "$TMP"
    echo "图标已生成: $ICNS"
fi

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
