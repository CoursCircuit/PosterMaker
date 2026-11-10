import Foundation
import CoreGraphics
import PDFKit

struct PosterSettings: Equatable {
    var paper: PaperFormat = .a4
    var orientation: PageOrientation = .portrait
    var columns: Int = 3
    var overlapMillimeters: Double = 6
    var marginMillimeters: Double = 5
}

enum PaperFormat: String, CaseIterable, Identifiable {
    case a4
    case a3

    var id: String { rawValue }

    var displayName: String {
        rawValue.uppercased()
    }

    var baseSizeInMillimeters: CGSize {
        switch self {
        case .a4:
            return CGSize(width: 210, height: 297)
        case .a3:
            return CGSize(width: 297, height: 420)
        }
    }

    func size(in orientation: PageOrientation) -> CGSize {
        let mmSize = baseSizeInMillimeters
        let pointSize = CGSize(width: mmSize.width * PosterMath.mmToPoints,
                               height: mmSize.height * PosterMath.mmToPoints)
        switch orientation {
        case .portrait:
            return pointSize
        case .landscape:
            return CGSize(width: pointSize.height, height: pointSize.width)
        }
    }
}

enum PageOrientation: String, CaseIterable, Identifiable {
    case portrait
    case landscape

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .portrait:
            return "Portrait"
        case .landscape:
            return "Paysage"
        }
    }
}

struct PosterLayout: Equatable {
    let sourceBounds: CGRect
    let tileSize: CGSize
    let printableSize: CGSize
    let margin: CGFloat
    let overlap: CGFloat
    let rows: Int
    let columns: Int
    let scale: CGFloat

    var horizontalStep: CGFloat { printableSize.width - overlap }
    var verticalStep: CGFloat { printableSize.height - overlap }

    var scaledSourceSize: CGSize {
        CGSize(width: sourceBounds.width * scale, height: sourceBounds.height * scale)
    }

    var contentOrigin: CGPoint {
        CGPoint(x: max(0, (posterSize.width - scaledSourceSize.width) / 2),
                y: 0)
    }

    var posterSize: CGSize {
        CGSize(width: printableSize.width * CGFloat(columns) - overlap * CGFloat(max(0, columns - 1)),
               height: printableSize.height * CGFloat(rows) - overlap * CGFloat(max(0, rows - 1)))
    }

    var assembledPaperSize: CGSize {
        CGSize(width: tileSize.width * CGFloat(columns) - overlap * CGFloat(max(0, columns - 1)),
               height: tileSize.height * CGFloat(rows) - overlap * CGFloat(max(0, rows - 1)))
    }

    var marginMillimeters: Double {
        Double(margin / PosterMath.mmToPoints)
    }

    var pageCount: Int { rows * columns }
}

enum PosterGeneratorError: LocalizedError {
    case invalidSource
    case consumerCreationFailed
    case contextCreationFailed
    case missingCorePage

    var errorDescription: String? {
        switch self {
        case .invalidSource:
            return "Impossible de lire la page PDF fournie."
        case .consumerCreationFailed:
            return "Création du fichier de sortie impossible."
        case .contextCreationFailed:
            return "Impossible d'initialiser le contexte PDF."
        case .missingCorePage:
            return "Impossible d'accéder au contenu brut de la page PDF."
        }
    }
}

struct PosterGenerator {
    static func layout(for page: PDFPage, settings: PosterSettings) throws -> PosterLayout {
        let bounds = page.bounds(for: .mediaBox)
        guard bounds.width > 0, bounds.height > 0 else {
            throw PosterGeneratorError.invalidSource
        }

        let clampedColumns = max(1, min(settings.columns, 24))
        let tileSize = settings.paper.size(in: settings.orientation)
        let requestedMargin = CGFloat(settings.marginMillimeters) * PosterMath.mmToPoints
        let marginPoints = PosterMath.sanitizedMargin(points: requestedMargin, tileSize: tileSize)

        let printableWidth = max(tileSize.width - marginPoints * 2, 1)
        let printableHeight = max(tileSize.height - marginPoints * 2, 1)
        let printableSize = CGSize(width: printableWidth, height: printableHeight)

        let overlapPoints = PosterMath.sanitizedOverlap(points: CGFloat(settings.overlapMillimeters) * PosterMath.mmToPoints,
                                                        printableSize: printableSize)

        let fit = PosterMath.fit(sourceSize: bounds.size,
                                 printableSize: printableSize,
                                 overlap: overlapPoints,
                                 columns: clampedColumns)

        return PosterLayout(sourceBounds: bounds,
                            tileSize: tileSize,
                            printableSize: printableSize,
                            margin: marginPoints,
                            overlap: overlapPoints,
                            rows: fit.rows,
                            columns: clampedColumns,
                            scale: fit.scale)
    }

    static func export(page: PDFPage, layout: PosterLayout, destination: URL) throws {
        guard let cgPage = page.pageRef else { throw PosterGeneratorError.missingCorePage }
        try export(cgPage: cgPage, layout: layout, destination: destination)
    }

    static func export(cgPage: CGPDFPage, layout: PosterLayout, destination: URL) throws {
        guard let consumer = CGDataConsumer(url: destination as CFURL) else { throw PosterGeneratorError.consumerCreationFailed }
        var mediaBox = CGRect(origin: .zero, size: layout.tileSize)
        guard let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else { throw PosterGeneratorError.contextCreationFailed }
        defer { context.closePDF() }

        let rows = layout.rows
        let columns = layout.columns
        let stepX = layout.horizontalStep
        let stepY = layout.verticalStep
        let printableSize = layout.printableSize

        for row in stride(from: rows - 1, through: 0, by: -1) {
            for column in 0..<columns {
                context.beginPDFPage(nil)

                let originX = CGFloat(column) * stepX
                let originY = CGFloat(row) * stepY
                let printableRect = CGRect(x: originX, y: originY, width: printableSize.width, height: printableSize.height)

                context.saveGState()
                context.setFillColor(gray: 1, alpha: 1)
                context.fill(CGRect(origin: .zero, size: layout.tileSize))
                context.restoreGState()

                context.saveGState()
                context.translateBy(x: layout.margin, y: layout.margin)
                let clipRect = CGRect(origin: .zero, size: printableSize)
                context.clip(to: clipRect)
                context.translateBy(x: -printableRect.minX + layout.contentOrigin.x,
                                    y: -printableRect.minY + layout.contentOrigin.y)
                context.scaleBy(x: layout.scale, y: layout.scale)
                context.translateBy(x: -layout.sourceBounds.minX, y: -layout.sourceBounds.minY)
                context.drawPDFPage(cgPage)
                context.restoreGState()

                context.endPDFPage()
            }
        }
    }
}

// The job retains one immutable Core Graphics page and value-only layout data.
// Its PDF context is created and consumed entirely on the export worker.
struct PosterExportJob: @unchecked Sendable {
    let page: CGPDFPage
    let layout: PosterLayout
    let destination: URL

    func write() throws {
        try PosterGenerator.export(cgPage: page, layout: layout, destination: destination)
    }
}

enum PosterMath {
    static let mmToPoints: CGFloat = 72.0 / 25.4
    // Avoid wasting a whole sheet on a very small overflow. The image may be
    // reduced by at most 10%, and only when the final row contains at most 25%
    // of a row of unique content.
    static let maximumSnapScaleReduction: CGFloat = 0.10
    static let maximumLastRowUniqueFraction: CGFloat = 0.25

    static func fit(sourceSize: CGSize,
                    printableSize: CGSize,
                    overlap: CGFloat,
                    columns: Int) -> (scale: CGFloat, rows: Int) {
        let safeColumns = max(1, columns)
        let horizontalStep = printableSize.width - overlap
        let verticalStep = printableSize.height - overlap
        let effectiveWidth = printableSize.width + CGFloat(safeColumns - 1) * horizontalStep
        let widthScale = effectiveWidth / sourceSize.width
        let widthFittedHeight = sourceSize.height * widthScale
        let strictRows = rowsRequired(totalHeight: widthFittedHeight,
                                      tileHeight: printableSize.height,
                                      step: verticalStep)

        guard strictRows > 1, verticalStep > 0 else {
            return (widthScale, strictRows)
        }

        let compactRows = strictRows - 1
        let compactHeight = printableSize.height + CGFloat(compactRows - 1) * verticalStep
        let compactScale = min(widthScale, compactHeight / sourceSize.height)
        let scaleReduction = 1 - compactScale / widthScale
        let uniqueHeightOnLastRow = widthFittedHeight - compactHeight
        let lastRowUniqueFraction = uniqueHeightOnLastRow / verticalStep

        if scaleReduction <= maximumSnapScaleReduction,
           lastRowUniqueFraction <= maximumLastRowUniqueFraction {
            return (compactScale, compactRows)
        }

        return (widthScale, strictRows)
    }

    static func sanitizedOverlap(points: CGFloat, printableSize: CGSize) -> CGFloat {
        guard points > 0 else { return 0 }
        let maxAllowed = min(printableSize.width, printableSize.height) * 0.8
        return min(points, maxAllowed)
    }

    static func sanitizedMargin(points: CGFloat, tileSize: CGSize) -> CGFloat {
        guard points > 0 else { return 0 }
        let maxPossible = max(0, min(tileSize.width, tileSize.height) / 2 - 1)
        return min(points, maxPossible)
    }

    static func rowsRequired(totalHeight: CGFloat, tileHeight: CGFloat, step: CGFloat) -> Int {
        guard totalHeight > 0 else { return 1 }
        let tolerance = max(totalHeight, tileHeight, step, 1) * 1e-9
        if totalHeight <= tileHeight + tolerance || step <= 0 {
            return 1
        }
        let remaining = totalHeight - tileHeight
        return Int(ceil((remaining - tolerance) / step)) + 1
    }
}
