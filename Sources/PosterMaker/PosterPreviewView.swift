import SwiftUI
import AppKit

struct PosterPreviewView: View {
    let layout: PosterLayout
    let previewImage: NSImage?
    var showsGrid = true

    var body: some View {
        GeometryReader { proxy in
            let inset: CGFloat = 42
            let scale = min(max(1, proxy.size.width - inset * 2) / layout.posterSize.width,
                            max(1, proxy.size.height - inset * 2) / layout.posterSize.height)
            let size = CGSize(width: layout.posterSize.width * scale, height: layout.posterSize.height * scale)
            let origin = CGPoint(x: (proxy.size.width - size.width) / 2, y: (proxy.size.height - size.height) / 2)
            ZStack(alignment: .topLeading) {
                Rectangle().fill(.white).frame(width: size.width, height: size.height)
                    .shadow(color: .black.opacity(0.13), radius: 20, y: 8)
                    .position(x: origin.x + size.width / 2, y: origin.y + size.height / 2)
                Canvas { context, _ in
                    let rect = CGRect(origin: origin, size: size)
                    if let previewImage {
                        let contentSize = CGSize(width: layout.scaledSourceSize.width * scale, height: layout.scaledSourceSize.height * scale)
                        let contentRect = CGRect(x: origin.x + layout.contentOrigin.x * scale,
                                                 y: origin.y + (layout.posterSize.height - layout.scaledSourceSize.height - layout.contentOrigin.y) * scale,
                                                 width: contentSize.width, height: contentSize.height)
                        var imageContext = context
                        imageContext.clip(to: Path(rect))
                        imageContext.draw(Image(nsImage: previewImage), in: contentRect)
                    }
                    context.stroke(Path(rect), with: .color(.black.opacity(0.12)), lineWidth: 0.7)
                    if showsGrid { drawTiles(context: &context, origin: origin, scale: scale) }
                    drawDimensions(context: &context, rect: rect)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Aperçu : \(layout.pageCount) feuilles, \(layout.columns) en largeur et \(layout.rows) en hauteur. Surface du poster hors marges : \(PosterTheme.dimensions(layout.posterSize)).")
    }

    private func drawTiles(context: inout GraphicsContext, origin: CGPoint, scale: CGFloat) {
        let width = layout.printableSize.width * scale
        let height = layout.printableSize.height * scale
        let overlap = layout.overlap * scale
        for row in 0..<layout.rows {
            for column in 0..<layout.columns {
                let rect = CGRect(x: origin.x + CGFloat(column) * layout.horizontalStep * scale,
                                  y: origin.y + CGFloat(row) * layout.verticalStep * scale,
                                  width: width, height: height)
                if column > 0, overlap > 0 {
                    context.fill(Path(CGRect(x: rect.minX, y: rect.minY, width: overlap, height: rect.height)), with: .color(PosterTheme.accent.opacity(0.14)))
                }
                if row > 0, overlap > 0 {
                    context.fill(Path(CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: overlap)), with: .color(PosterTheme.accent.opacity(0.14)))
                }
                context.stroke(Path(rect), with: .color(PosterTheme.accent.opacity(0.75)), style: StrokeStyle(lineWidth: 0.8, dash: [5, 3]))
                if width >= 38, height >= 28 {
                    let badge = CGRect(x: rect.minX + 6, y: rect.minY + 6, width: 23, height: 19)
                    context.fill(Path(roundedRect: badge, cornerRadius: 4), with: .color(Color(red: 0.31, green: 0.25, blue: 0.66).opacity(0.94)))
                    let number = Text(String(format: "%02d", row * layout.columns + column + 1))
                        .font(.system(size: 9, weight: .semibold, design: .monospaced)).foregroundColor(.white)
                    context.draw(number, at: CGPoint(x: badge.midX, y: badge.midY))
                }
            }
        }
    }

    private func drawDimensions(context: inout GraphicsContext, rect: CGRect) {
        var horizontal = Path()
        let y = rect.minY - 21
        horizontal.move(to: CGPoint(x: rect.minX, y: y)); horizontal.addLine(to: CGPoint(x: rect.maxX, y: y))
        for x in [rect.minX, rect.maxX] {
            horizontal.move(to: CGPoint(x: x, y: y - 3)); horizontal.addLine(to: CGPoint(x: x, y: y + 3))
        }
        context.stroke(horizontal, with: .color(.secondary.opacity(0.35)), lineWidth: 0.7)
        let widthText = Text("\(PosterTheme.centimeters(layout.posterSize.width)) cm")
            .font(.system(size: 10, weight: .medium, design: .monospaced)).foregroundColor(.secondary)
        context.draw(widthText, at: CGPoint(x: rect.midX, y: y - 10))
        var vertical = Path()
        let x = rect.maxX + 17
        vertical.move(to: CGPoint(x: x, y: rect.minY)); vertical.addLine(to: CGPoint(x: x, y: rect.maxY))
        for y in [rect.minY, rect.maxY] {
            vertical.move(to: CGPoint(x: x - 3, y: y)); vertical.addLine(to: CGPoint(x: x + 3, y: y))
        }
        context.stroke(vertical, with: .color(.secondary.opacity(0.35)), lineWidth: 0.7)
        var rotated = context
        rotated.translateBy(x: x + 12, y: rect.midY)
        rotated.rotate(by: .degrees(90))
        let heightText = Text("\(PosterTheme.centimeters(layout.posterSize.height)) cm")
            .font(.system(size: 10, weight: .medium, design: .monospaced)).foregroundColor(.secondary)
        rotated.draw(heightText, at: .zero)
    }
}
