import SwiftUI
import AppKit

struct CompletedExport: Identifiable {
    let id = UUID()
    let url: URL
    let pageCount: Int
    let paper: PaperFormat
}

struct ExportSuccessView: View {
    let result: CompletedExport
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark")
                .font(.system(size: 24, weight: .semibold)).foregroundStyle(PosterTheme.accent)
                .frame(width: 64, height: 64).background(PosterTheme.accent.opacity(0.10), in: Circle())
            VStack(spacing: 8) {
                Text("Votre poster est prêt.").font(.system(size: 25, weight: .bold, design: .rounded))
                Text("\(result.pageCount) \(result.pageCount > 1 ? "pages" : "page") \(result.paper.displayName) · \(result.url.lastPathComponent)")
                    .font(.system(size: 12)).foregroundStyle(.secondary).lineLimit(2).truncationMode(.middle)
                    .multilineTextAlignment(.center).textSelection(.enabled)
            }
            VStack(alignment: .leading, spacing: 8) {
                Label("Imprimez à 100 % ou en « Taille réelle ».", systemImage: "printer")
                    .font(.system(size: 12, weight: .semibold))
                Text("Assemblez les pages de gauche à droite, puis de haut en bas. Superposez les bandes communes pour aligner le motif.")
                    .font(.system(size: 12)).foregroundStyle(.secondary).lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16).frame(maxWidth: .infinity, alignment: .leading)
            .background(PosterTheme.accent.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
            HStack(spacing: 12) {
                Button("Afficher dans le Finder") { NSWorkspace.shared.activateFileViewerSelecting([result.url]) }
                    .buttonStyle(.bordered)
                Button { NSWorkspace.shared.open(result.url) } label: {
                    Label("Ouvrir le PDF", systemImage: "arrow.up.right")
                }
                .buttonStyle(PrimaryActionStyle())
            }
            Button("Terminé") { dismiss() }.buttonStyle(.link).keyboardShortcut(.defaultAction)
        }
        .padding(32).frame(width: 480).tint(PosterTheme.accent)
    }
}
