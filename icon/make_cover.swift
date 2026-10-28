// Draws the LayoutFixer cover image (README hero and GitHub social preview).
// Usage: swift icon/make_cover.swift <output dir>   (run from the repo root; needs icon/icon_1024.png)
// Writes cover.png (1920x960, for the README) and social-preview.png (1280x640, for GitHub).

import AppKit

let out = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : ".")
let appIcon = NSImage(contentsOfFile: "icon/icon_1024.png")!

func color(_ hex: UInt32, _ a: CGFloat = 1) -> NSColor {
    NSColor(srgbRed: CGFloat(hex >> 16 & 0xFF) / 255, green: CGFloat(hex >> 8 & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255, alpha: a)
}

func rounded(_ r: NSRect, _ radius: CGFloat) -> NSBezierPath {
    NSBezierPath(roundedRect: r, xRadius: radius, yRadius: radius)
}

func persianFont(_ size: CGFloat, heavy: Bool = false) -> NSFont {
    for name in heavy ? ["SFArabic-Heavy", "SFArabic-Bold"] : ["SFArabic-Medium", "SFArabic-Regular"] {
        if let f = NSFont(name: name, size: size) { return f }
    }
    return .systemFont(ofSize: size, weight: heavy ? .heavy : .medium)
}

func attributed(_ s: String, _ font: NSFont, _ c: NSColor, kern: CGFloat = 0) -> NSAttributedString {
    NSAttributedString(string: s, attributes: [.font: font, .foregroundColor: c, .kern: kern])
}

/// Draws text with its visual left edge at x and its glyph box vertically centred on y.
@discardableResult
func draw(_ str: NSAttributedString, left x: CGFloat, centerY y: CGFloat) -> NSRect {
    let b = str.boundingRect(with: .zero, options: [.usesLineFragmentOrigin, .usesDeviceMetrics])
    str.draw(at: NSPoint(x: x - b.minX, y: y - b.midY))
    return NSRect(x: x, y: y - b.height / 2, width: b.width, height: b.height)
}

@discardableResult
func draw(_ str: NSAttributedString, right x: CGFloat, centerY y: CGFloat) -> NSRect {
    let b = str.boundingRect(with: .zero, options: [.usesLineFragmentOrigin, .usesDeviceMetrics])
    return draw(str, left: x - b.width, centerY: y)
}

func withShadow(_ c: NSColor, blur: CGFloat, y: CGFloat, _ body: () -> Void) {
    NSGraphicsContext.saveGraphicsState()
    let s = NSShadow()
    s.shadowColor = c
    s.shadowBlurRadius = blur
    s.shadowOffset = NSSize(width: 0, height: y)
    s.set()
    body()
    NSGraphicsContext.restoreGraphicsState()
}

/// A Tab-key glyph: arrow into a bar.
func tabGlyph(in r: NSRect, color c: NSColor, width: CGFloat) {
    let p = NSBezierPath()
    let midY = r.midY, head = r.height * 0.42
    p.move(to: NSPoint(x: r.minX, y: midY))
    p.line(to: NSPoint(x: r.maxX - width * 2.2, y: midY))
    p.move(to: NSPoint(x: r.maxX - width * 2.2 - head, y: midY + head))
    p.line(to: NSPoint(x: r.maxX - width * 2.2, y: midY))
    p.line(to: NSPoint(x: r.maxX - width * 2.2 - head, y: midY - head))
    p.move(to: NSPoint(x: r.maxX, y: r.minY))
    p.line(to: NSPoint(x: r.maxX, y: r.maxY))
    p.lineWidth = width
    p.lineCapStyle = .round
    p.lineJoinStyle = .round
    c.setStroke()
    p.stroke()
}

// MARK: - Scene (1280 x 640, y up)

let W: CGFloat = 1280, H: CGFloat = 640
let deep = color(0x062925), teal = color(0x0F5E57), mint = color(0x5EEAD4), aqua = color(0x14B8A6)

func drawCover() {
    // Background: deep teal, lit from the right where the product moment sits.
    NSGradient(colors: [color(0x04211E), color(0x0A3F39), color(0x0F5E57)])!
        .draw(in: NSRect(x: 0, y: 0, width: W, height: H), angle: 20)
    let glow = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB),
                          colors: [aqua.withAlphaComponent(0.34).cgColor, aqua.withAlphaComponent(0.12).cgColor,
                                   aqua.withAlphaComponent(0).cgColor] as CFArray,
                          locations: [0, 0.45, 1])!
    NSGraphicsContext.current!.cgContext.drawRadialGradient(
        glow, startCenter: CGPoint(x: 960, y: 300), startRadius: 0,
        endCenter: CGPoint(x: 960, y: 300), endRadius: 560, options: [])

    // Faint dot grid, fading toward the left so the type stays clean.
    for gx in stride(from: CGFloat(24), to: W, by: 32) {
        for gy in stride(from: CGFloat(24), to: H, by: 32) {
            let a = max(0, min(1, (gx - 420) / 700)) * 0.09
            guard a > 0.005 else { continue }
            NSColor.white.withAlphaComponent(a).setFill()
            NSBezierPath(ovalIn: NSRect(x: gx - 1.2, y: gy - 1.2, width: 2.4, height: 2.4)).fill()
        }
    }

    // MARK: Left: brand
    let left: CGFloat = 92
    withShadow(.black.withAlphaComponent(0.35), blur: 30, y: -12) {
        appIcon.draw(in: NSRect(x: left - 22, y: 400, width: 176, height: 176))
    }
    draw(attributed("LayoutFixer", .systemFont(ofSize: 86, weight: .bold), .white, kern: -2.2),
         left: left, centerY: 338)
    draw(attributed("Typed in the wrong layout?", .systemFont(ofSize: 33, weight: .medium),
                    .white.withAlphaComponent(0.88), kern: -0.4), left: left, centerY: 258)
    draw(attributed("Just press Tab.", .systemFont(ofSize: 33, weight: .semibold), mint, kern: -0.4),
         left: left, centerY: 214)

    // Pills.
    var x = left
    for label in ["macOS & Windows", "English ⇄ فارسی", "Free & open source"] {
        let str = NSMutableAttributedString(attributedString:
            attributed(label, .systemFont(ofSize: 17, weight: .medium), .white.withAlphaComponent(0.82)))
        if let r = label.range(of: "فارسی") {
            str.addAttribute(.font, value: persianFont(18), range: NSRange(r, in: label))
        }
        let b = str.boundingRect(with: .zero, options: [.usesLineFragmentOrigin])
        let pill = NSRect(x: x, y: 112, width: b.width + 32, height: 40)
        NSColor.white.withAlphaComponent(0.07).setFill()
        rounded(pill, 20).fill()
        let border = rounded(pill.insetBy(dx: 0.5, dy: 0.5), 19.5)
        border.lineWidth = 1
        NSColor.white.withAlphaComponent(0.18).setStroke()
        border.stroke()
        str.draw(at: NSPoint(x: pill.minX + 16, y: pill.midY - b.height / 2 - 1))
        x = pill.maxX + 10
    }

    // MARK: Right: the product moment
    // Text field card.
    let card = NSRect(x: 640, y: 318, width: 552, height: 196)
    withShadow(.black.withAlphaComponent(0.4), blur: 60, y: -26) {
        color(0xFBFBFA).setFill()
        rounded(card, 24).fill()
    }
    // Window chrome dots.
    for (i, c) in [color(0xFF5F57), color(0xFEBC2E), color(0x28C840)].enumerated() {
        c.setFill()
        NSBezierPath(ovalIn: NSRect(x: card.minX + 24 + CGFloat(i) * 22, y: card.maxY - 34, width: 12, height: 12)).fill()
    }
    color(0x000000, 0.06).setFill()
    NSRect(x: card.minX, y: card.maxY - 54, width: card.width, height: 1).fill()

    // The mistyped text, right-aligned like Persian, with the caret at its end.
    let typed = draw(attributed("فاهس هدسفثشی", persianFont(46), color(0x1C1C1E)),
                     right: card.maxX - 40, centerY: 404)
    // Red squiggle under the mistake.
    let squiggle = NSBezierPath()
    squiggle.move(to: NSPoint(x: typed.minX, y: 362))
    var sx = typed.minX
    var up = true
    while sx < typed.maxX {
        sx += 6
        squiggle.line(to: NSPoint(x: min(sx, typed.maxX), y: up ? 366 : 362))
        up.toggle()
    }
    squiggle.lineWidth = 2
    color(0xF0503C).setStroke()
    squiggle.stroke()
    let caret = NSRect(x: typed.minX - 14, y: 376, width: 3, height: 56)
    aqua.setFill()
    rounded(caret, 1.5).fill()

    // Suggestion popup, hanging from the caret.
    let popup = NSRect(x: caret.minX - 40, y: 168, width: 430, height: 132)
    withShadow(.black.withAlphaComponent(0.5), blur: 40, y: -18) {
        color(0x10201E).setFill()
        rounded(popup, 20).fill()
    }
    let edge = rounded(popup.insetBy(dx: 0.5, dy: 0.5), 19.5)
    edge.lineWidth = 1
    NSColor.white.withAlphaComponent(0.12).setStroke()
    edge.stroke()
    // Little pointer up to the caret.
    let tip = NSBezierPath()
    tip.move(to: NSPoint(x: caret.midX - 13, y: popup.maxY - 1))
    tip.line(to: NSPoint(x: caret.midX, y: popup.maxY + 13))
    tip.line(to: NSPoint(x: caret.midX + 13, y: popup.maxY - 1))
    tip.close()
    color(0x10201E).setFill()
    tip.fill()

    draw(attributed("this instead", .systemFont(ofSize: 38, weight: .semibold), .white, kern: -0.6),
         left: popup.minX + 28, centerY: popup.maxY - 44)
    // Hint row: [⇥ tab] fix & switch to English
    let kbd = NSRect(x: popup.minX + 28, y: popup.minY + 24, width: 82, height: 32)
    mint.withAlphaComponent(0.16).setFill()
    rounded(kbd, 8).fill()
    tabGlyph(in: NSRect(x: kbd.minX + 13, y: kbd.minY + 10, width: 18, height: 12), color: mint, width: 2.2)
    draw(attributed("tab", .systemFont(ofSize: 15, weight: .semibold), mint), left: kbd.minX + 43, centerY: kbd.midY - 2)
    draw(attributed("fix & switch to English", .systemFont(ofSize: 17, weight: .regular),
                    .white.withAlphaComponent(0.66)), left: kbd.maxX + 14, centerY: kbd.midY)

    // A real Tab key, mid-press, just below the popup's corner.
    NSGraphicsContext.saveGraphicsState()
    let t = NSAffineTransform()
    t.translateX(by: 1150, yBy: 98)
    t.rotate(byDegrees: -8)
    t.concat()
    let face = NSRect(x: -80, y: -42, width: 160, height: 84)
    withShadow(.black.withAlphaComponent(0.45), blur: 30, y: -16) {
        color(0x0B3B36).setFill()
        rounded(face.offsetBy(dx: 0, dy: -12), 20).fill()
    }
    NSGradient(starting: .white, ending: color(0xE6F7F4))!.draw(in: rounded(face, 20), angle: -90)
    draw(attributed("tab", .systemFont(ofSize: 22, weight: .semibold), teal), left: face.minX + 20, centerY: face.maxY - 26)
    tabGlyph(in: NSRect(x: face.minX + 20, y: face.minY + 18, width: 60, height: 26), color: teal, width: 5)
    NSGraphicsContext.restoreGraphicsState()
}

func render(scale: CGFloat) -> NSBitmapImageRep {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(W * scale), pixelsHigh: Int(H * scale),
                               bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                               colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    NSGraphicsContext.current!.imageInterpolation = .high
    NSGraphicsContext.current!.cgContext.scaleBy(x: scale, y: scale)
    drawCover()
    NSGraphicsContext.restoreGraphicsState()
    return rep
}

try! FileManager.default.createDirectory(at: out, withIntermediateDirectories: true)
for (scale, name) in [(CGFloat(1.5), "cover.png"), (CGFloat(1), "social-preview.png")] {
    try! render(scale: scale).representation(using: .png, properties: [:])!.write(to: out.appendingPathComponent(name))
}
print("wrote cover.png and social-preview.png to \(out.path)")
