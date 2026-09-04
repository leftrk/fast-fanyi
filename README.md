# fast-fanyi 翻译

<p><img src="assets/icon.png" width="128" alt="fast-fanyi icon"></p>

macOS 快速中英互译工具：粘贴即译，端侧离线。

A fast Chinese ⇄ English translator for macOS. Paste text, get instant translation — fully on-device and offline.

## 特性

- **粘贴即译**：输入停止约 350ms 后自动翻译，不用点任何按钮
- **自动检测语种**：中文译成英文、英文译成中文，基于 Unicode 区间的确定性判断，短文本和中英混排也不会判错
- **端侧离线**：基于 Apple Translation 框架，翻译不上传任何服务器
- **模型缺失自动引导**：启动时检测翻译模型，未下载时一键触发系统下载引导
- **快**：启动时预热双向翻译会话，首次翻译也秒出

## 系统要求

- macOS 15 及以上（开发测试于 macOS 26）
- 中英翻译模型：App 内可一键引导下载（约 300MB，下载一次永久离线可用）；也可手动在 系统设置 → 通用 → 语言与地区 → 翻译语言 中下载

## 构建

不需要 Xcode 工程，`swiftc` 直接编译打包：

```bash
./build.sh        # 产出 fanyi.app，有开发者证书则自动签名
open fanyi.app
```

## 技术说明

- UI：SwiftUI 单窗口，左输入右输出
- 翻译：`TranslationSession(installedSource:target:)`，会话按方向缓存复用
- 模型检测：`LanguageAvailability.status(from:to:)`；未安装时通过 `.translationTask` 让系统弹出官方下载引导

## License

MIT
