import AppKit
import PDFKit

enum ExamplePoster {
    @MainActor static func makeDocument() -> PDFDocument? {
        let data = NSMutableData()
        var rect = CGRect(x: 0, y: 0, width: 595, height: 842)
        guard let consumer = CGDataConsumer(data: data), let context = CGContext(consumer: consumer, mediaBox: &rect, nil) else { return nil }
        context.beginPDFPage(nil)
        context.setFillColor(NSColor(srgbRed: 0.17, green: 0.13, blue: 0.36, alpha: 1).cgColor)
        context.fill(rect)

        context.saveGState()
        context.addEllipse(in: CGRect(x: 135, y: 68, width: 620, height: 620))
        context.clip()
        let colors = [NSColor(srgbRed: 0.66, green: 0.52, blue: 0.99, alpha: 1).cgColor,
                      NSColor(srgbRed: 1, green: 0.70, blue: 0.47, alpha: 1).cgColor] as CFArray
        if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1]) {
            context.drawLinearGradient(gradient, start: CGPoint(x: 590, y: 80), end: CGPoint(x: 150, y: 690), options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
        }
        context.restoreGState()
        context.setStrokeColor(NSColor.white.withAlphaComponent(0.45).cgColor)
        context.setLineWidth(1)
        context.strokeEllipse(in: CGRect(x: 60, y: 30, width: 700, height: 700))
        context.strokeEllipse(in: CGRect(x: 80, y: 50, width: 660, height: 660))

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
        draw("LES IDÉES PRENNENT LE LARGE", at: CGPoint(x: 47, y: 776), size: 11, weight: .medium, tracking: 2)
        draw("VOIR", at: CGPoint(x: 40, y: 570), size: 115, weight: .black, tracking: -5)
        draw("PLUS", at: CGPoint(x: 40, y: 457), size: 115, weight: .black, tracking: -5)
        draw("GRAND.", at: CGPoint(x: 40, y: 344), size: 115, weight: .black, tracking: -5)
        draw("Votre prochaine grande idée\ncommence sur une petite page.", at: CGPoint(x: 47, y: 203), size: 18, weight: .medium, tracking: 0)
        draw("POSTERMAKER    /    STUDIO 01", at: CGPoint(x: 47, y: 46), size: 10, weight: .medium, tracking: 2)
        NSGraphicsContext.restoreGraphicsState()

        context.endPDFPage()
        context.closePDF()
        return PDFDocument(data: data as Data)
    }

    private static func draw(_ text: String, at point: CGPoint, size: CGFloat, weight: NSFont.Weight, tracking: CGFloat) {
        let base = NSFont.systemFont(ofSize: size, weight: weight)
        let font = base.fontDescriptor.withDesign(.rounded).flatMap { NSFont(descriptor: $0, size: size) } ?? base
        (text as NSString).draw(at: point, withAttributes: [.font: font, .foregroundColor: NSColor.white, .kern: tracking])
    }
}
