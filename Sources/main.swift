import SwiftUI
import Translation

// fast-fanyi 翻译 - 中英快速互译（端侧离线）
// 语种检测: Unicode 区间确定性判断（中英场景比统计模型可靠）
// 翻译引擎: Translation 框架 (TranslationSession)，模型走系统语言包
// 模型缺失: LanguageAvailability 检测，translationTask 触发系统下载引导

@main
struct FanyiApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .defaultSize(width: 760, height: 480)
    }
}

enum ModelState: Equatable {
    case checking   // 启动检测中
    case ready      // 中英双向模型均已下载
    case missing    // 有方向未下载，需要引导
}

struct ContentView: View {
    @State private var input = ""
    @State private var output = ""
    @State private var statusLine = "正在检测翻译模型…"
    @State private var workItem: Task<Void, Never>?
    @State private var modelState: ModelState = .checking
    @State private var sessions: [String: TranslationSession] = [:]
    // translationTask 的触发器：置为非 nil 即让系统弹出模型下载引导
    @State private var downloadSource: Locale.Language?
    @State private var downloadTarget: Locale.Language?

    private let zhCN = Locale.Language(identifier: "zh-CN")
    private let enUS = Locale.Language(identifier: "en-US")
    private let idleHint = "粘贴或输入中文/英文，自动互译"

    var body: some View {
        HSplitView {
            // 左：输入框（占位提示 + 右下角清空按钮）
            ZStack(alignment: .topLeading) {
                TextEditor(text: $input)
                    .font(.system(size: 16))
                    .scrollContentBackground(.hidden)
                    .padding(8)
                if input.isEmpty {
                    Text(idleHint)
                        .font(.system(size: 16))
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 13)
                        .padding(.vertical, 16)
                        .allowsHitTesting(false)
                }
            }
            .frame(minWidth: 240)
            .overlay(alignment: .bottomTrailing) {
                if !input.isEmpty {
                    Button {
                        input = ""
                        output = ""
                        statusLine = modelState == .ready ? "" : statusLine
                    } label: {
                        Image(systemName: "eraser")
                    }
                    .buttonStyle(.borderless)
                    .foregroundStyle(.secondary)
                    .padding(10)
                    .help("清空")
                }
            }

            // 右：输出框（左下角状态文字，右下角复制按钮，模型缺失时露出下载按钮）
            ScrollView {
                Text(output.isEmpty && modelState == .missing ? downloadGuide : (output.isEmpty ? " " : output))
                    .font(.system(size: 16))
                    .foregroundStyle(output.isEmpty ? .secondary : .primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
                    .padding(12)
            }
            .frame(minWidth: 240)
            .overlay(alignment: .bottom) {
                HStack(spacing: 8) {
                    if !statusLine.isEmpty {
                        Circle()
                            .fill(statusColor)
                            .frame(width: 7, height: 7)
                        Text(statusLine)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                    }
                    Spacer()
                    if modelState == .missing {
                        Button("下载翻译模型") { startModelDownload() }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                        Button("系统设置") { openSystemSettings() }
                            .controlSize(.small)
                    }
                    if !output.isEmpty {
                        Button {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(output, forType: .string)
                        } label: {
                            Image(systemName: "doc.on.doc")
                        }
                        .buttonStyle(.borderless)
                        .foregroundStyle(.secondary)
                        .help("复制译文 (⇧⌘C)")
                        .keyboardShortcut("c", modifiers: [.command, .shift])
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
            }
        }
        .frame(minWidth: 560, minHeight: 320)
        .onChange(of: input) { _, newValue in
            scheduleTranslate(newValue)
        }
        .task {
            await prepareModels()
        }
        // 模型未下载时由系统弹窗引导下载；完成后重新检测
        .translationTask(source: downloadSource, target: downloadTarget) { _ in
            downloadSource = nil
            downloadTarget = nil
            Task { await prepareModels() }
        }
    }

    private var statusColor: Color {
        switch modelState {
        case .ready: return .green
        case .missing: return .orange
        case .checking: return .gray
        }
    }

    // MARK: - 模型检测 / 预热 / 下载引导

    /// 启动时检测中英双向模型；已下载则预热会话，让首次翻译也秒出
    private func prepareModels() async {
        let availability = LanguageAvailability()
        let zh2en = await availability.status(from: zhCN, to: enUS)
        let en2zh = await availability.status(from: enUS, to: zhCN)

        if zh2en == .installed && en2zh == .installed {
            modelState = .ready
            statusLine = ""
            for (from, to) in [(zhCN, enUS), (enUS, zhCN)] {
                let session = getSession(from: from, to: to)
                try? await session.prepareTranslation()
            }
        } else {
            modelState = .missing
            statusLine = "中英翻译模型未下载，下载方式见上方说明"
        }
    }

    /// 模型缺失时显示在输出区的下载指引
    private var downloadGuide: String {
        """
        尚未下载中英翻译模型，两种方式任选：

        方式一（推荐）：点下方「下载翻译模型」，按系统弹窗提示下载

        方式二（手动）：系统设置 → 通用 → 语言与地区 → 翻译语言，下载「中文（普通话）」和「英语（美国）」

        模型约 300MB，下载一次即可永久离线使用。
        """
    }

    private func startModelDownload() {
        // 触发 translationTask，系统自动弹出下载确认窗口
        downloadSource = zhCN
        downloadTarget = enUS
    }

    private func openSystemSettings() {
        // 系统设置 → 通用 → 语言与地区（翻译语言在那里下载）
        let url = URL(string: "x-apple.systempreferences:com.apple.Localization-Settings.extension")
            ?? URL(fileURLWithPath: "/System/Applications/System Settings.app")
        NSWorkspace.shared.open(url)
    }

    private func getSession(from: Locale.Language, to: Locale.Language) -> TranslationSession {
        let key = "\(from.minimalIdentifier)->\(to.minimalIdentifier)"
        if let cached = sessions[key] { return cached }
        let session = TranslationSession(installedSource: from, target: to)
        sessions[key] = session
        return session
    }

    // MARK: - 翻译

    private func scheduleTranslate(_ text: String) {
        workItem?.cancel()
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            output = ""
            statusLine = modelState == .ready ? "" : statusLine
            return
        }
        workItem = Task {
            try? await Task.sleep(for: .milliseconds(350))
            guard !Task.isCancelled else { return }
            await translateNow(trimmed)
        }
    }

    private func translateNow(_ text: String) async {
        guard modelState == .ready else {
            output = ""
            statusLine = "翻译模型未就绪，请先下载模型"
            return
        }
        guard let (source, target) = detectDirection(text) else {
            output = ""
            statusLine = "未识别出中文或英文，暂只支持中英互译"
            return
        }
        let srcName = source == zhCN ? "中文" : "英语"
        let dstName = target == zhCN ? "中文" : "英语"
        statusLine = "检测到\(srcName) → 翻译成\(dstName)"
        do {
            let response = try await getSession(from: source, to: target).translate(text)
            guard !Task.isCancelled else { return }
            output = response.targetText
        } catch {
            guard !Task.isCancelled else { return }
            statusLine = "翻译失败：\(error.localizedDescription)"
        }
    }

    /// 返回 (源语言, 目标语言)；非中英文返回 nil。
    /// 场景限定中英互译，用 Unicode 区间做确定性判断：含 CJK 表意文字即判中文，
    /// 否则含拉丁字母即判英文。比 NLLanguageRecognizer 在短文本/混排上更可靠。
    private func detectDirection(_ text: String) -> (Locale.Language, Locale.Language)? {
        var hasCJK = false
        var hasLatin = false
        for scalar in text.unicodeScalars {
            switch scalar.value {
            case 0x4E00...0x9FFF, 0x3400...0x4DBF, 0xF900...0xFAFF:
                hasCJK = true
            case 0x0041...0x005A, 0x0061...0x007A, 0x00C0...0x024F:
                hasLatin = true
            default:
                break
            }
            if hasCJK { break }
        }
        if hasCJK { return (zhCN, enUS) }
        if hasLatin { return (enUS, zhCN) }
        return nil
    }
}
