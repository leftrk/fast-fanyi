# AGENTS.md

## 项目
fast-fanyi：macOS 快速中英互译工具（SwiftUI 单窗口 App，端侧离线，MIT 开源）。
GitHub: leftrk/fast-fanyi（公开仓库）。

## 构建与运行
```bash
./build.sh        # swiftc 直接编译 Sources/main.swift → fanyi.app，自动用开发者证书签名
open fanyi.app
```
- 无 Xcode 工程，不要引入 project.pbxproj；改代码 = 改 `Sources/main.swift` + 跑 `./build.sh`
- `Info.plist` 由 build.sh 拷入 bundle
- 签名证书：`Developer ID Application: Hua Guan (PP9XRDW4F5)`（build.sh 自动探测，找不到则 ad-hoc）

## 技术要点
- 翻译：Apple Translation 框架 `TranslationSession(installedSource:target:)`，语言标识用 `zh-CN`/`en-US`（语言包注册在 `zh-CN` 下，用 `zh-Hans` 查状态会误报 supported）
- 语种检测：Unicode 区间确定性判断（含 CJK → 中文），不要换 NLLanguageRecognizer——短文本/混排不可靠
- 模型缺失：`LanguageAvailability.status` 检测，`.translationTask` 触发系统下载引导
- 会话按方向缓存在 `sessions` 字典，启动时预热双向

## 约定
- 定位「快速翻译」，加功能前先想是否拖慢/复杂化核心路径
- 全端侧离线，不接任何云端翻译 API
- commit 用简洁中文描述
