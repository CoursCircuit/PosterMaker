import SwiftUI

struct PosterWorkspaceView: View {
    @ObservedObject var viewModel: PosterViewModel
    let isDropTargeted: Bool
    @State private var showsGrid = true

    var body: some View {
        VStack(spacing: 0) {
            workspaceHeader
            ZStack {
                DotGridBackground()
                if let layout = viewModel.layout {
                    PosterPreviewView(layout: layout, previewImage: viewModel.previewImage, showsGrid: showsGrid)
                        .padding(.horizontal, 28).padding(.vertical, 24)
                } else {
                    WelcomePosterView(importDocument: viewModel.chooseDocument, loadExample: viewModel.loadExample)
                        .padding(24)
                }
                if isDropTargeted {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(PosterTheme.accent.opacity(0.10))
                        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(PosterTheme.accent, style: StrokeStyle(lineWidth: 2, dash: [8, 5])))
                        .overlay {
                            Label("Déposez votre document ici", systemImage: "arrow.down.doc")
                                .font(.system(size: 17, weight: .semibold))
                                .padding(22).background(.regularMaterial, in: RoundedRectangle(cornerRadius: 13))
                        }
                        .padding(14).allowsHitTesting(false)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            Divider()
            workspaceFooter
        }
    }

    private var workspaceHeader: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.hasDocument ? "Aperçu du poster" : "Pensez plus grand.")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                Text(viewModel.hasDocument ? "Chaque case correspond à une feuille à imprimer." : "Transformez un PDF ou une image en affiche à assembler.")
                    .font(.system(size: 11)).foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            if viewModel.hasDocument {
                Picker("Affichage de l’aperçu", selection: $showsGrid) {
                    Text("Découpage").tag(true)
                    Text("Affiche seule").tag(false)
                }
                .pickerStyle(.segmented).labelsHidden().frame(width: 190)
            } else {
                Label("100 % local", systemImage: "lock.shield")
                    .font(.system(size: 10, weight: .medium)).foregroundStyle(.secondary)
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(Color.primary.opacity(0.035), in: Capsule())
            }
        }
        .padding(.horizontal, 28).padding(.vertical, 20)
        .background(.bar)
    }

    private var workspaceFooter: some View {
        VStack(spacing: 14) {
            if let layout = viewModel.layout {
                HStack(spacing: 0) {
                    metric(value: PosterTheme.dimensions(layout.posterSize), label: "Surface du poster¹", symbol: "arrow.up.left.and.arrow.down.right")
                    Divider().frame(height: 31).padding(.horizontal, 22)
                    metric(value: "\(layout.columns) × \(layout.rows)", label: "Feuilles en largeur × hauteur", symbol: "square.grid.3x3")
                    Spacer(minLength: 0)
                    Label("Aperçu en direct", systemImage: "circle.fill")
                        .font(.system(size: 10)).foregroundStyle(PosterTheme.accent)
                        .labelStyle(LiveLabelStyle())
                }
                HStack(spacing: 5) {
                    Image(systemName: "info.circle")
                    Text("¹ Hors marges blanches. À l’impression, choisissez « Taille réelle » ou 100 %.")
                    Spacer(minLength: 0)
                }
                .font(.system(size: 10)).foregroundStyle(.secondary)
            } else {
                HStack(spacing: 21) {
                    miniStep("1", "Importez")
                    Image(systemName: "chevron.right").font(.system(size: 8)).foregroundStyle(.tertiary)
                    miniStep("2", "Ajustez")
                    Image(systemName: "chevron.right").font(.system(size: 8)).foregroundStyle(.tertiary)
                    miniStep("3", "Imprimez & assemblez")
                }
                .frame(maxWidth: .infinity).padding(.vertical, 4)
            }
        }
        .padding(.horizontal, 28).padding(.vertical, 19).background(.bar)
    }

    private func metric(value: String, label: String, symbol: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: symbol).font(.system(size: 16, weight: .light)).foregroundStyle(PosterTheme.accent)
            VStack(alignment: .leading, spacing: 4) {
                Text(value).font(.system(size: 16, weight: .semibold, design: .rounded)).monospacedDigit()
                Text(label).font(.system(size: 10)).foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func miniStep(_ number: String, _ title: String) -> some View {
        HStack(spacing: 7) {
            Text(number).font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(PosterTheme.accent).frame(width: 22, height: 22)
                .background(PosterTheme.accent.opacity(0.08), in: Circle())
            Text(title).font(.system(size: 11, weight: .medium)).foregroundStyle(.secondary)
        }
    }
}

private struct LiveLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 5) {
            configuration.icon.font(.system(size: 5))
            configuration.title
        }
    }
}

struct DotGridBackground: View {
    @Environment(\.colorScheme) private var colorScheme
    var body: some View {
        ZStack {
            Color(nsColor: .textBackgroundColor).opacity(colorScheme == .dark ? 0.45 : 0.65)
            RadialGradient(colors: [PosterTheme.accent.opacity(0.055), .clear], center: .center, startRadius: 20, endRadius: 440)
            Canvas { context, size in
                let spacing: CGFloat = 20
                var dots = Path()
                for x in stride(from: CGFloat(10), to: size.width, by: spacing) {
                    for y in stride(from: CGFloat(10), to: size.height, by: spacing) {
                        dots.addEllipse(in: CGRect(x: x, y: y, width: 1.3, height: 1.3))
                    }
                }
                context.fill(dots, with: .color(.primary.opacity(colorScheme == .dark ? 0.11 : 0.09)))
            }
            .accessibilityHidden(true)
        }
    }
}
