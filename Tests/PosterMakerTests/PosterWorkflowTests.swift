import AppKit
import PDFKit
import UniformTypeIdentifiers
import XCTest
@testable import PosterMaker

final class PosterWorkflowTests: XCTestCase {
    @MainActor func testPNGImportKeepsItsNameAndAspectRatio() throws {
        let bitmap = try XCTUnwrap(NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 240, pixelsHigh: 160,
                                                    bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                                                    isPlanar: false, colorSpaceName: .deviceRGB,
                                                    bytesPerRow: 0, bitsPerPixel: 0))
        bitmap.setColor(.systemPurple, atX: 10, y: 10)
        let data = try XCTUnwrap(bitmap.representation(using: .png, properties: [:]))
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let file = folder.appendingPathComponent("Mon image.png")
        try data.write(to: file)
        let model = PosterViewModel()
        model.loadDocument(from: file)
        XCTAssertNil(model.alert)
        XCTAssertTrue(model.canExport)
        XCTAssertEqual(model.sourceName, "Mon image.png")
        let info = try XCTUnwrap(model.pageInfo)
        XCTAssertEqual(info.pageCount, 1)
        XCTAssertEqual(info.size.width / info.size.height, 1.5, accuracy: 0.001)
    }

    @MainActor func testExampleCreatesAUsablePosterAndRecalculatesSettings() throws {
        let model = PosterViewModel()
        XCTAssertFalse(model.canExport)
        model.loadExample()
        XCTAssertEqual(model.sourceName, "Voir plus grand.pdf")
        XCTAssertEqual(model.pageInfo?.pageCount, 1)
        XCTAssertNotNil(model.previewImage)
        XCTAssertTrue(model.canExport)
        let initial = try XCTUnwrap(model.layout)
        model.settings.columns = 2
        let smaller = try XCTUnwrap(model.layout)
        XCTAssertEqual(smaller.columns, 2)
        XCTAssertLessThan(smaller.posterSize.width, initial.posterSize.width)
        XCTAssertLessThan(smaller.pageCount, initial.pageCount)
    }

    @MainActor func testUnreadableImportPreservesTheCurrentDocument() throws {
        let model = PosterViewModel()
        model.loadExample()
        let initial = model.layout
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let file = folder.appendingPathComponent("invalide.pdf")
        try Data("not a PDF".utf8).write(to: file)
        model.loadDocument(from: file)
        XCTAssertNotNil(model.alert)
        XCTAssertEqual(model.sourceName, "Voir plus grand.pdf")
        XCTAssertEqual(model.layout, initial)
        XCTAssertTrue(model.canExport)
    }

    @MainActor func testFinderFileURLDropKeepsTheOriginalFileName() async throws {
        let document = try XCTUnwrap(ExamplePoster.makeDocument())
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let file = folder.appendingPathComponent("Mon affiche.pdf")
        XCTAssertTrue(document.write(to: file))
        let provider = NSItemProvider(item: file as NSURL, typeIdentifier: UTType.fileURL.identifier)
        let model = PosterViewModel()
        XCTAssertTrue(model.handleDrop(providers: [provider]))
        for _ in 0..<100 where !model.hasDocument {
            try await Task.sleep(for: .milliseconds(10))
        }
        XCTAssertEqual(model.sourceName, "Mon affiche.pdf")
        XCTAssertTrue(model.canExport)
    }

    @MainActor func testBackgroundExportWritesEverySheetInTheSelectedPaperSize() async throws {
        let source = try XCTUnwrap(ExamplePoster.makeDocument())
        let page = try XCTUnwrap(source.page(at: 0))
        var settings = PosterSettings()
        settings.paper = .a3
        settings.orientation = .landscape
        settings.columns = 2
        let layout = try PosterGenerator.layout(for: page, settings: settings)
        let output = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("pdf")
        defer { try? FileManager.default.removeItem(at: output) }
        let job = PosterExportJob(page: try XCTUnwrap(page.pageRef), layout: layout, destination: output)
        try await Task.detached { try job.write() }.value
        let result = try XCTUnwrap(PDFDocument(url: output))
        XCTAssertEqual(result.pageCount, layout.pageCount)
        for index in 0..<result.pageCount {
            let size = try XCTUnwrap(result.page(at: index)).bounds(for: .mediaBox).size
            XCTAssertEqual(size.width / PosterMath.mmToPoints, 420, accuracy: 0.001)
            XCTAssertEqual(size.height / PosterMath.mmToPoints, 297, accuracy: 0.001)
        }
    }
}
