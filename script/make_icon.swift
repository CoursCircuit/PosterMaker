import AppKit
import ImageIO
import UniformTypeIdentifiers

let output = CommandLine.arguments.dropFirst().first ?? "Resources/AppIcon-1024.png"
let size: CGFloat = 1024
let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 1024, pixelsHigh: 1024,
                             bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                             isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
NSColor.clear.setFill()
NSRect(x: 0, y: 0, width: size, height: size).fill()

let outer = NSBezierPath(roundedRect: NSRect(x: 80, y: 80, width: 864, height: 864), xRadius: 194, yRadius: 194)
NSGraphicsContext.saveGraphicsState()
let shadow = NSShadow()
shadow.shadowColor = NSColor.black.withAlphaComponent(0.26)
shadow.shadowBlurRadius = 26
shadow.shadowOffset = NSSize(width: 0, height: -12)
shadow.set()
NSColor(srgbRed: 0.30, green: 0.21, blue: 0.72, alpha: 1).setFill()
outer.fill()
NSGraphicsContext.restoreGraphicsState()
NSGradient(colors: [NSColor(srgbRed: 0.56, green: 0.46, blue: 1, alpha: 1),
                    NSColor(srgbRed: 0.29, green: 0.20, blue: 0.72, alpha: 1)])!.draw(in: outer, angle: -60)
NSColor.white.withAlphaComponent(0.25).setStroke()
outer.lineWidth = 3
outer.stroke()

NSGraphicsContext.saveGraphicsState()
let transform = AffineTransform(translationByX: 512, byY: 512)
var rotation = transform
rotation.rotate(byDegrees: -8)
(rotation as NSAffineTransform).concat()
for row in 0..<2 {
    for column in 0..<2 {
        let tile = NSRect(x: CGFloat(column) * 248 - 230, y: CGFloat(row) * 248 - 230, width: 212, height: 212)
        let path = NSBezierPath(roundedRect: tile, xRadius: 30, yRadius: 30)
        let base = row == 1 && column == 1
            ? NSColor(srgbRed: 0.86, green: 0.91, blue: 1, alpha: 1) : NSColor.white
        NSGradient(starting: base, ending: base.withAlphaComponent(0.82))!.draw(in: path, angle: -90)
        NSColor.white.withAlphaComponent(0.9).setStroke()
        path.lineWidth = 2
        path.stroke()
    }
}
NSGraphicsContext.restoreGraphicsState()
NSGraphicsContext.restoreGraphicsState()
let data = bitmap.representation(using: .png, properties: [:])!
try data.write(to: URL(fileURLWithPath: output))
