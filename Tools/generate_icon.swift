#!/usr/bin/env swift
import AppKit

// Renders the Speedread app icon set into
// Speedread/Resources/Assets.xcassets/AppIcon.appiconset/.
//
// Design: gradient (deep-violet → magenta) rounded square with the word
// "read" rendered RSVP-style — ORP character "e" highlighted on a thin
// vertical guide. Mirrors what the reader window itself shows.

let outputDir = "Speedread/Resources/Assets.xcassets/AppIcon.appiconset"
try? FileManager.default.createDirectory(atPath: outputDir, withIntermediateDirectories: true)

func render(size: CGFloat) -> Data {
    let pixelSize = Int(size)
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixelSize,
        pixelsHigh: pixelSize,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bitmapFormat: [],
        bytesPerRow: 0,
        bitsPerPixel: 32
    ) else { fatalError("rep") }

    let ctx = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = ctx

    let rect = NSRect(x: 0, y: 0, width: size, height: size)
    let radius = size * 0.225
    let clip = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
    clip.addClip()

    NSGradient(colors: [
        NSColor(red: 0.36, green: 0.16, blue: 0.78, alpha: 1.0),
        NSColor(red: 0.92, green: 0.27, blue: 0.55, alpha: 1.0)
    ])!.draw(in: rect, angle: -65)

    NSGradient(colors: [
        NSColor.white.withAlphaComponent(0.18),
        NSColor.white.withAlphaComponent(0.0)
    ])!.draw(in: rect, angle: 90)

    let lineWidth = max(size * 0.005, 1)
    let lineRect = NSRect(
        x: rect.midX - lineWidth / 2,
        y: rect.height * 0.18,
        width: lineWidth,
        height: rect.height * 0.64
    )
    NSColor.white.withAlphaComponent(0.22).setFill()
    lineRect.fill()

    let word = "read"
    let orpIndex = 1
    let fontSize = size * 0.36
    let font = NSFont.monospacedSystemFont(ofSize: fontSize, weight: .bold)
    let pivotColor = NSColor(red: 1.0, green: 0.83, blue: 0.40, alpha: 1.0)

    let chars = Array(word)
    let widths: [CGFloat] = chars.enumerated().map { i, ch in
        let color: NSColor = (i == orpIndex) ? pivotColor : .white
        return NSAttributedString(
            string: String(ch),
            attributes: [.font: font, .foregroundColor: color]
        ).size().width
    }

    let leftWidth = widths[0..<orpIndex].reduce(0, +)
    var x = rect.midX - leftWidth - widths[orpIndex] / 2
    let y = rect.midY - fontSize * 0.42

    for (i, ch) in chars.enumerated() {
        let color: NSColor = (i == orpIndex) ? pivotColor : .white
        NSAttributedString(
            string: String(ch),
            attributes: [.font: font, .foregroundColor: color]
        ).draw(at: NSPoint(x: x, y: y))
        x += widths[i]
    }

    NSGraphicsContext.restoreGraphicsState()

    return rep.representation(using: .png, properties: [:])!
}

struct Spec {
    let size: Int
    let scale: Int
    var filename: String { "icon_\(size)x\(size)\(scale == 2 ? "@2x" : "").png" }
    var pixelSize: CGFloat { CGFloat(size * scale) }
}

let specs: [Spec] = [
    Spec(size: 16,  scale: 1),
    Spec(size: 16,  scale: 2),
    Spec(size: 32,  scale: 1),
    Spec(size: 32,  scale: 2),
    Spec(size: 128, scale: 1),
    Spec(size: 128, scale: 2),
    Spec(size: 256, scale: 1),
    Spec(size: 256, scale: 2),
    Spec(size: 512, scale: 1),
    Spec(size: 512, scale: 2),
]

for s in specs {
    let data = render(size: s.pixelSize)
    let url = URL(fileURLWithPath: outputDir).appendingPathComponent(s.filename)
    try data.write(to: url)
    print("✓ \(s.filename) (\(Int(s.pixelSize))px)")
}

let images: [[String: String]] = specs.map { s in
    [
        "size": "\(s.size)x\(s.size)",
        "idiom": "mac",
        "filename": s.filename,
        "scale": "\(s.scale)x"
    ]
}
let contents: [String: Any] = [
    "images": images,
    "info": ["version": 1, "author": "xcode"]
]
let json = try JSONSerialization.data(
    withJSONObject: contents,
    options: [.prettyPrinted, .sortedKeys]
)
try json.write(to: URL(fileURLWithPath: outputDir).appendingPathComponent("Contents.json"))
print("✓ Contents.json")
