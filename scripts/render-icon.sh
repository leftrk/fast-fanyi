#!/bin/bash
# render-icon.sh — 从 assets/icon.svg 重新生成图标（一次性产物，平时不用跑）
# 产出: assets/icon.png (1024) + resources/AppIcon.icns
# 依赖: rsvg-convert (brew librsvg)、iconutil (系统自带)
set -euo pipefail
cd "$(dirname "$0")/.."

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

rsvg-convert -w 1024 -h 1024 assets/icon.svg -o assets/icon.png

ICONSET="$TMP/AppIcon.iconset"
mkdir -p "$ICONSET"
for spec in "16:icon_16x16" "32:icon_16x16@2x" "32:icon_32x32" "64:icon_32x32@2x" \
            "128:icon_128x128" "256:icon_128x128@2x" "256:icon_256x256" "512:icon_256x256@2x" \
            "512:icon_512x512" "1024:icon_512x512@2x"; do
    px="${spec%%:*}"; name="${spec##*:}"
    sips -z "$px" "$px" assets/icon.png --out "$ICONSET/$name.png" >/dev/null
done
mkdir -p resources
iconutil -c icns "$ICONSET" -o resources/AppIcon.icns
echo "已生成 assets/icon.png + resources/AppIcon.icns"
