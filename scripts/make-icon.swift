// make-icon.swift — 程序化生成 fast-fanyi 应用图标
// 蓝渐变圆角方块（macOS squircle）+ 白色「译」字，输出 1024x1024 PNG
// 用法: swiftc make-icon.swift -o make-icon && ./make-icon <输出.png>

import AppKit

let size: CGFloat = 1024

guard let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: Int(size), pixelsHigh: Int(size),
    bitsPerSample: 8, samplesPerPixel: 4,
    hasAlpha: true, isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0, bitsPerPixel: 0
) else { fatalError("bitmap alloc failed") }
rep.size = NSSize(width: size, height: size)

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

// macOS 圆角方块：留约 2% 透明边，圆角半径约 22.5%
let inset = size * 0.02
let rect = NSRect(x: inset, y: inset, width: size - inset * 2, height: size - inset * 2)
let path = NSBezierPath(roundedRect: rect, xRadius: size * 0.225, yRadius: size * 0.225)

// 蓝紫渐变，左上 → 右下
let gradient = NSGradient(colors: [
    NSColor(calibratedRed: 0.20, green: 0.50, blue: 0.98, alpha: 1),  // 亮蓝
    NSColor(calibratedRed: 0.35, green: 0.30, blue: 0.90, alpha: 1),  // 蓝紫
])!
path.addClip()
gradient.draw(in: rect, angle: -45)

// 中央白色「译」字
let text = "译"
let font = NSFont(name: "PingFangSC-Semibold", size: size * 0.56)
    ?? NSFont.systemFont(ofSize: size * 0.56, weight: .semibold)
let attrs: [NSAttributedString.Key: Any] = [
    .font: font,
    .foregroundColor: NSColor.white,
]
let str = NSAttributedString(string: text, attributes: attrs)
let ts = str.size()
// 按字形包围盒居中（比按 size 更准，避免字面框偏移）
let bounds = str.boundingRect(with: NSSize(width: 4096, height: 4096), options: [.usesLineFragmentOrigin])
let origin = NSPoint(
    x: (size - bounds.width) / 2 - bounds.origin.x,
    y: (size - bounds.height) / 2 - bounds.origin.y
)
str.draw(at: origin)

NSGraphicsContext.restoreGraphicsState()

guard let png = rep.representation(using: .png, properties: [:]) else { fatalError("png encode failed") }
let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "icon_1024.png"
try png.write(to: URL(fileURLWithPath: out))
print("图标已生成: \(out)")
