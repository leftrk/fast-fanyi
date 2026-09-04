// make-icon.swift — 程序化生成 fast-fanyi 应用图标
// 企业孟菲斯风格：扁平亮色 + 几何装饰（圆/半圆/波浪线/圆点阵/十字）
// 主体为两个叠放的对话气泡（A → Z），表达语言转换，无文字依赖具体语种
// 用法: swiftc make-icon.swift -o make-icon && ./make-icon <输出.png>

import AppKit

let size: CGFloat = 1024

// MARK: - 调色板（孟菲斯扁平配色）
let cream  = NSColor(calibratedRed: 1.00, green: 0.95, blue: 0.88, alpha: 1)  // 奶油底
let navy   = NSColor(calibratedRed: 0.11, green: 0.11, blue: 0.24, alpha: 1)  // 深海军蓝（描边/波浪线）
let blue   = NSColor(calibratedRed: 0.18, green: 0.36, blue: 0.96, alpha: 1)  // 亮蓝
let coral  = NSColor(calibratedRed: 1.00, green: 0.42, blue: 0.36, alpha: 1)  // 珊瑚橙
let yellow = NSColor(calibratedRed: 1.00, green: 0.79, blue: 0.24, alpha: 1)  // 明黄

// MARK: - 绘图辅助

/// 绕 center 旋转 angle 度执行 draw
func rotated(_ angle: CGFloat, around center: NSPoint, _ draw: () -> Void) {
    let t = NSAffineTransform()
    t.translateX(by: center.x, yBy: center.y)
    t.rotate(byDegrees: angle)
    t.translateX(by: -center.x, yBy: -center.y)
    t.concat()
    draw()
    t.invert()
    t.concat()
}

/// 对话气泡：圆角矩形 + 底部小尾巴
func bubblePath(rect: NSRect, radius: CGFloat, tailTip: NSPoint) -> NSBezierPath {
    let p = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
    let tail = NSBezierPath()
    tail.move(to: NSPoint(x: rect.midX - 45, y: rect.minY + 4))
    tail.line(to: tailTip)
    tail.line(to: NSPoint(x: rect.midX + 35, y: rect.minY + 4))
    tail.close()
    p.append(tail)
    return p
}

/// 居中绘制单个字符
func drawLetter(_ letter: String, fontSize: CGFloat, color: NSColor, center: NSPoint) {
    let font = NSFont.systemFont(ofSize: fontSize, weight: .black)
    let str = NSAttributedString(string: letter, attributes: [
        .font: font,
        .foregroundColor: color,
    ])
    let b = str.boundingRect(with: NSSize(width: 4096, height: 4096), options: [.usesLineFragmentOrigin])
    str.draw(at: NSPoint(x: center.x - b.width / 2 - b.origin.x,
                         y: center.y - b.height / 2 - b.origin.y))
}

// MARK: - 画布

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

// 背景 squircle（y 轴向上：顶部 = 高 y 值）
let inset = size * 0.02
let rect = NSRect(x: inset, y: inset, width: size - inset * 2, height: size - inset * 2)
let squircle = NSBezierPath(roundedRect: rect, xRadius: size * 0.225, yRadius: size * 0.225)
cream.setFill()
squircle.fill()
squircle.addClip()

// MARK: - 孟菲斯几何装饰

// 左上：珊瑚橙大圆（部分出界）
coral.setFill()
NSBezierPath(ovalIn: NSRect(x: -60, y: 790, width: 340, height: 340)).fill()

// 右下：明黄大圆（部分出界）
yellow.setFill()
NSBezierPath(ovalIn: NSRect(x: 800, y: -80, width: 320, height: 320)).fill()

// 右上：深海军蓝波浪线
let wave = NSBezierPath()
wave.move(to: NSPoint(x: 640, y: 890))
for i in 1...12 {
    wave.line(to: NSPoint(x: 640 + CGFloat(i) * 26,
                          y: 890 + sin(CGFloat(i) * .pi / 1.5) * 42))
}
wave.lineWidth = 20
wave.lineCapStyle = .round
navy.setStroke()
wave.stroke()

// 左下：亮蓝圆点阵 3x3
blue.setFill()
for row in 0..<3 {
    for col in 0..<3 {
        NSBezierPath(ovalIn: NSRect(x: 90 + col * 52, y: 90 + row * 52, width: 24, height: 24)).fill()
    }
}

// 右侧中部：珊瑚橙圆环（空心）
let ring = NSBezierPath(ovalIn: NSRect(x: 830, y: 560, width: 100, height: 100))
ring.lineWidth = 20
coral.setStroke()
ring.stroke()

// 左上偏中：明黄十字
let plus = NSBezierPath()
plus.move(to: NSPoint(x: 330, y: 880)); plus.line(to: NSPoint(x: 330, y: 960))
plus.move(to: NSPoint(x: 290, y: 920)); plus.line(to: NSPoint(x: 370, y: 920))
plus.lineWidth = 18
plus.lineCapStyle = .round
yellow.setStroke()
plus.stroke()

// MARK: - 主体：两个叠放气泡

let outline: CGFloat = 14

// 气泡 A（亮蓝，左下，微左倾）
let rectA = NSRect(x: 235, y: 340, width: 310, height: 250)
rotated(-6, around: NSPoint(x: rectA.midX, y: rectA.midY)) {
    let p = bubblePath(rect: rectA, radius: 44, tailTip: NSPoint(x: 300, y: 250))
    blue.setFill(); p.fill()
    navy.setStroke(); p.lineWidth = outline; p.stroke()
    drawLetter("A", fontSize: 150, color: .white, center: NSPoint(x: rectA.midX, y: rectA.midY + 10))
}

// 气泡 Z（珊瑚橙，右上，微右倾，压在 A 上）
let rectZ = NSRect(x: 500, y: 440, width: 310, height: 250)
rotated(6, around: NSPoint(x: rectZ.midX, y: rectZ.midY)) {
    let p = bubblePath(rect: rectZ, radius: 44, tailTip: NSPoint(x: 720, y: 350))
    coral.setFill(); p.fill()
    navy.setStroke(); p.lineWidth = outline; p.stroke()
    drawLetter("Z", fontSize: 150, color: .white, center: NSPoint(x: rectZ.midX, y: rectZ.midY + 10))
}

NSGraphicsContext.restoreGraphicsState()

guard let png = rep.representation(using: .png, properties: [:]) else { fatalError("png encode failed") }
let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "icon_1024.png"
try png.write(to: URL(fileURLWithPath: out))
print("图标已生成: \(out)")
