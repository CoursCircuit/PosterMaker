import SwiftUI
import AppKit
import PDFKit
import UniformTypeIdentifiers

@MainActor
final class PosterViewModel: ObservableObject {
    static let supportedContentTypes: [UTType] = [
        .pdf, .png, .jpeg, .tiff, .heic, .heif
    ]
    static let dropTypeIdentifiers: [String] = {
        var ids = supportedContentTypes.map { $0.identifier }
        ids.append(UTType.image.identifier)
        ids.append(UTType.fileURL.identifier)
        return Array(Set(ids))
    }()

    @Published private(set) var sourceDocument: PDFDocument?
    @Published private(set) var previewImage: NSImage?
    @Published private(set) var pageInfo: SourcePageInfo?
    @Published private(set) var sourceName: String?
    @Published var settings = PosterSettings() {
        didSet { recalculateLayout() }
    }
    @Published private(set) var layout: PosterLayout?
    @Published var statusMessage: String = "Importez un document pour démarrer."
    @Published var isProcessing: Bool = false
    @Published var alert: AlertContent?
    @Published var completedExport: CompletedExport?

    var hasDocument: Bool { sourceDocument != nil }
    var canExport: Bool { hasDocument && layout != nil && !isProcessing }

    func chooseDocument() {
        guard !isProcessing else { return }
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.pdf, .image]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.title = "Choisir un PDF ou une image"
        panel.prompt = "Importer"
        panel.message = "Votre document sera agrandi sur plusieurs feuilles. Pour un PDF, seule la première page est utilisée."
        if panel.runModal() == .OK, let url = panel.url {
            loadDocument(from: url)
        }
    }

    func loadDocument(from url: URL) {
        guard !isProcessing else { return }
        guard let document = makeDocument(from: url) else {
            alert = AlertContent(title: "Impossible d’ouvrir ce document", message: "Choisissez un PDF non protégé ou une image (PNG, JPEG, HEIC ou TIFF). Le fichier « \(url.lastPathComponent) » n’a pas pu être lu.")
            return
        }

        guard let firstPage = document.page(at: 0) else {
            alert = AlertContent(title: "PDF vide", message: "Le fichier ne contient aucune page exploitable.")
            return
        }

        applyDocument(document, firstPage: firstPage, name: url.lastPathComponent)
        statusMessage = "Document chargé : \(url.lastPathComponent)"
    }

    func loadExample() {
        guard !isProcessing else { return }
        guard let document = ExamplePoster.makeDocument(), let page = document.page(at: 0) else { return }
        applyDocument(document, firstPage: page, name: "Voir plus grand.pdf")
        statusMessage = "Exemple chargé. Ajustez la largeur pour essayer."
    }

    private func applyDocument(_ document: PDFDocument, firstPage: PDFPage, name: String) {
        sourceDocument = document
        sourceName = name
        previewImage = generateThumbnail(for: firstPage)
        pageInfo = SourcePageInfo(size: firstPage.bounds(for: .mediaBox).size, pageCount: document.pageCount)
        recalculateLayout()
    }

    func exportPoster() {
        guard !isProcessing else { return }
        guard let document = sourceDocument, let page = document.page(at: 0) else {
            alert = AlertContent(title: "Aucun document sélectionné", message: "Ajoutez un fichier avant d'exporter.")
            return
        }
        guard let layout else {
            alert = AlertContent(title: "Paramètres incomplets", message: "Vérifiez les réglages du poster.")
            return
        }

        let panel = NSSavePanel()
        panel.allowedContentTypes = [.pdf]
        panel.canCreateDirectories = true
        panel.isExtensionHidden = false
        panel.title = "Exporter le poster"
        panel.prompt = "Exporter"
        panel.message = "\(layout.pageCount) pages \(settings.paper.displayName). À l’impression, choisissez « Taille réelle » ou 100 %."
        panel.nameFieldStringValue = suggestedFileName(base: sourceName.map { URL(fileURLWithPath: $0).deletingPathExtension().lastPathComponent })

        if panel.runModal() == .OK, let outputURL = panel.url {
            guard let cgPage = page.pageRef else { return }
            let job = PosterExportJob(page: cgPage, layout: layout, destination: outputURL)
            let paper = settings.paper
            isProcessing = true
            statusMessage = "Génération du PDF en cours…"
            Task {
                do {
                    try await Task.detached(priority: .userInitiated) { try job.write() }.value
                    statusMessage = "Poster généré : \(outputURL.lastPathComponent)"
                    completedExport = CompletedExport(url: outputURL, pageCount: layout.pageCount, paper: paper)
                } catch {
                    alert = AlertContent(title: "Le PDF n’a pas pu être créé", message: error.localizedDescription)
                    statusMessage = "L’export a échoué. Vous pouvez réessayer."
                }
                isProcessing = false
            }
        }
    }

    func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard !isProcessing else { return false }
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                provider.loadDataRepresentation(forTypeIdentifier: UTType.fileURL.identifier) { data, _ in
                    guard let data, let url = URL(dataRepresentation: data, relativeTo: nil) else {
                        self.reportDropFailure()
                        return
                    }
                    DispatchQueue.main.async { self.loadDocument(from: url) }
                }
                return true
            }
            if provider.hasItemConformingToTypeIdentifier(UTType.pdf.identifier) {
                importFile(from: provider, type: .pdf)
                return true
            }
            if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                importFile(from: provider, type: .image)
                return true
            }
            for type in PosterViewModel.supportedContentTypes where provider.hasItemConformingToTypeIdentifier(type.identifier) {
                importFile(from: provider, type: type)
                return true
            }
        }
        return false
    }

    private func importFile(from provider: NSItemProvider, type: UTType) {
        let suggestedName = provider.suggestedName
        provider.loadFileRepresentation(forTypeIdentifier: type.identifier) { url, _ in
            guard let url else { self.reportDropFailure(); return }
            guard let tempURL = self.persistTemporaryCopy(of: url, name: suggestedName, proposedExtension: type.preferredFilenameExtension) else {
                self.reportDropFailure()
                return
            }
            DispatchQueue.main.async {
                self.loadDocument(from: tempURL)
            }
        }
    }

    nonisolated private func reportDropFailure() {
        DispatchQueue.main.async {
            self.alert = AlertContent(title: "Import interrompu", message: "Le fichier déposé n’a pas pu être lu. Essayez le bouton « Importer » pour le sélectionner sur votre Mac.")
        }
    }

    nonisolated private func persistTemporaryCopy(of url: URL, name: String?, proposedExtension: String?) -> URL? {
        let fm = FileManager.default
        let originalExtension = url.pathExtension
        let resolvedExtension = originalExtension.isEmpty ? (proposedExtension ?? "tmp") : originalExtension
        let folder = fm.temporaryDirectory.appendingPathComponent("PosterMaker-\(UUID().uuidString)", isDirectory: true)
        var fileName = name.map { URL(fileURLWithPath: $0).lastPathComponent } ?? url.lastPathComponent
        if URL(fileURLWithPath: fileName).pathExtension.isEmpty { fileName += "." + resolvedExtension }
        let tempURL = folder.appendingPathComponent(fileName)
        do {
            try fm.createDirectory(at: folder, withIntermediateDirectories: true)
            try fm.copyItem(at: url, to: tempURL)
        } catch {
            return nil
        }
        return tempURL
    }

    private func recalculateLayout() {
        guard let page = sourceDocument?.page(at: 0) else {
            layout = nil
            return
        }

        do {
            layout = try PosterGenerator.layout(for: page, settings: settings)
        } catch {
            layout = nil
            alert = AlertContent(title: "Erreur", message: error.localizedDescription)
        }
    }

    private func generateThumbnail(for page: PDFPage) -> NSImage {
        let bounds = page.bounds(for: .mediaBox)
        let maxDimension: CGFloat = 1400
        let scale = maxDimension / max(bounds.width, bounds.height)
        let targetSize = CGSize(width: bounds.width * scale, height: bounds.height * scale)
        return page.thumbnail(of: targetSize, for: .mediaBox)
    }

    private func suggestedFileName(base: String?) -> String {
        let baseName = (base?.isEmpty == false ? base! : "Poster")
        return baseName + "-agrandi.pdf"
    }

    private func makeDocument(from url: URL) -> PDFDocument? {
        if let document = PDFDocument(url: url), document.pageCount > 0 {
            return document
        }

        // NSImage may lazily accept a corrupt PDF, then PDFPage(image:) raises
        // an Objective-C exception. Validate the raster before constructing it.
        guard url.pathExtension.lowercased() != "pdf" else { return nil }
        if let image = NSImage(contentsOf: url), image.isValid,
           let raster = image.cgImage(forProposedRect: nil, context: nil, hints: nil),
           let page = PDFPage(image: NSImage(cgImage: raster, size: image.size)) {
            let document = PDFDocument()
            document.insert(page, at: 0)
            return document
        }

        return nil
    }
}

struct SourcePageInfo {
    let size: CGSize
    let pageCount: Int
}

struct AlertContent: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}
