import CoreGraphics
import AppKit
import PDFKit
import XCTest
@testable import PosterMaker

final class PosterMathTests: XCTestCase {
    func testA4PortraitFitsOnTwoA3LandscapeSheets() {
        let source = CGSize(width: 210, height: 297)
        let printable = CGSize(width: 410, height: 287)

        let fit = PosterMath.fit(sourceSize: source,
                                 printableSize: printable,
                                 overlap: 6,
                                 columns: 1)

        XCTAssertEqual(fit.rows, 2)
        XCTAssertLessThanOrEqual(source.height * fit.scale, 568.000_001)
        XCTAssertEqual(source.height * fit.scale, 568, accuracy: 0.000_001)
    }

    func testMeaningfulThirdRowIsNotRemoved() {
        let source = CGSize(width: 210, height: 330)
        let printable = CGSize(width: 410, height: 287)

        let fit = PosterMath.fit(sourceSize: source,
                                 printableSize: printable,
                                 overlap: 6,
                                 columns: 1)

        XCTAssertEqual(fit.rows, 3)
        XCTAssertEqual(fit.scale, 410 / 210, accuracy: 0.000_001)
    }

    func testReportedSourceFitsOnTwoA3LandscapeSheets() {
        let source = CGSize(width: 361, height: 542)
        let printable = CGSize(width: 410, height: 287)

        let fit = PosterMath.fit(sourceSize: source,
                                 printableSize: printable,
                                 overlap: 6,
                                 columns: 1)

        XCTAssertEqual(fit.rows, 2)
        XCTAssertEqual(source.height * fit.scale, 568, accuracy: 0.000_001)
    }

    func testExactBoundaryDoesNotCreateAnExtraRow() {
        let printable = CGSize(width: 410, height: 287)
        let widthScale: CGFloat = 2
        let source = CGSize(width: printable.width / widthScale,
                            height: 568 / widthScale)

        let fit = PosterMath.fit(sourceSize: source,
                                 printableSize: printable,
                                 overlap: 6,
                                 columns: 1)

        XCTAssertEqual(fit.rows, 2)
        XCTAssertEqual(fit.scale, widthScale, accuracy: 0.000_001)
    }

    func testA3LandscapeUsesSwappedPhysicalDimensions() {
        let size = PaperFormat.a3.size(in: .landscape)

        XCTAssertEqual(size.width / PosterMath.mmToPoints, 420, accuracy: 0.000_001)
        XCTAssertEqual(size.height / PosterMath.mmToPoints, 297, accuracy: 0.000_001)
    }

    func testReportedSourceExportsAsTwoRealA3LandscapePDFPages() throws {
        let sourceSize = CGSize(width: 361 * PosterMath.mmToPoints,
                                height: 542 * PosterMath.mmToPoints)
        let image = NSImage(size: sourceSize)
        image.lockFocus()
        NSColor.white.setFill()
        NSRect(origin: .zero, size: sourceSize).fill()
        NSColor.systemBlue.setStroke()
        let diagonal = NSBezierPath()
        diagonal.move(to: .zero)
        diagonal.line(to: CGPoint(x: sourceSize.width, y: sourceSize.height))
        diagonal.lineWidth = 12
        diagonal.stroke()
        image.unlockFocus()

        let sourcePage = try XCTUnwrap(PDFPage(image: image))
        var settings = PosterSettings()
        settings.paper = .a3
        settings.orientation = .landscape
        settings.columns = 1
        settings.marginMillimeters = 5
        settings.overlapMillimeters = 6

        let layout = try PosterGenerator.layout(for: sourcePage, settings: settings)
        let configuredOutput = ProcessInfo.processInfo.environment["POSTERMAKER_QA_OUTPUT"]
        let outputURL = configuredOutput.map(URL.init(fileURLWithPath:))
            ?? FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("pdf")
        defer {
            if configuredOutput == nil {
                try? FileManager.default.removeItem(at: outputURL)
            }
        }

        try PosterGenerator.export(page: sourcePage, layout: layout, destination: outputURL)

        let outputDocument = try XCTUnwrap(PDFDocument(url: outputURL))
        XCTAssertEqual(outputDocument.pageCount, 2)
        for index in 0..<outputDocument.pageCount {
            let pageSize = try XCTUnwrap(outputDocument.page(at: index)).bounds(for: .mediaBox).size
            XCTAssertEqual(pageSize.width / PosterMath.mmToPoints, 420, accuracy: 0.001)
            XCTAssertEqual(pageSize.height / PosterMath.mmToPoints, 297, accuracy: 0.001)
        }
    }
}
