import SwiftUI

struct PosterSettingsView: View {
    @ObservedObject var viewModel: PosterViewModel
    @State private var showsAssemblySettings = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 19) {
                    Text("VOTRE POSTER")
                        .font(.system(size: 10, weight: .semibold)).tracking(1.8)
                        .foregroundStyle(.secondary).padding(.top, 6)

                    sourceSection
                    Divider()
                    settingsSection
                }
                .padding(22)
            }
            .scrollIndicators(.visible)
            Divider()
            exportSection.padding(19)
        }
    }

    private var sourceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeading(number: "01", title: "Ajoutez votre document", complete: viewModel.hasDocument)
            Button(action: viewModel.chooseDocument) {
                HStack(spacing: 11) {
                    if let image = viewModel.previewImage {
                        Image(nsImage: image).resizable().scaledToFit()
                            .frame(width: 36, height: 46)
                            .background(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                            .overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(PosterTheme.line))
                    } else {
                        Image(systemName: "doc.badge.plus")
                            .font(.system(size: 22, weight: .light))
                            .foregroundStyle(PosterTheme.accent)
                            .frame(width: 36, height: 46)
                    }
                    VStack(alignment: .leading, spacing: 5) {
                        Text(viewModel.sourceName ?? "PDF ou image")
                            .font(.system(size: 12, weight: .medium)).lineLimit(1).truncationMode(.middle)
                        Text(viewModel.hasDocument ? "Cliquer pour remplacer" : "Choisir un fichier…")
                            .font(.system(size: 11)).foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: viewModel.hasDocument ? "arrow.triangle.2.circlepath" : "plus")
                        .font(.system(size: 11)).foregroundStyle(.secondary)
                }
                .padding(12).frame(maxWidth: .infinity, alignment: .leading)
                .background(PosterTheme.card.opacity(0.65), in: RoundedRectangle(cornerRadius: 11))
                .overlay(RoundedRectangle(cornerRadius: 11).strokeBorder(PosterTheme.line))
                .contentShape(RoundedRectangle(cornerRadius: 11))
            }
            .buttonStyle(.plain).disabled(viewModel.isProcessing)
            .help(viewModel.sourceName ?? "Importer un document (⌘O)")

            if let info = viewModel.pageInfo, info.pageCount > 1 {
                Label("PDF de \(info.pageCount) pages : seule la première sera agrandie.", systemImage: "info.circle")
                    .font(.system(size: 10)).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 17) {
            SectionHeading(number: "02", title: "Choisissez le format")
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 8) {
                    fieldLabel("Papier de votre imprimante")
                    HStack(spacing: 8) {
                        SelectionTile(title: "A4", subtitle: "21 × 29,7 cm", selected: viewModel.settings.paper == .a4) {
                            viewModel.settings.paper = .a4
                        }
                        SelectionTile(title: "A3", subtitle: "29,7 × 42 cm", selected: viewModel.settings.paper == .a3) {
                            viewModel.settings.paper = .a3
                        }
                    }
                }
                VStack(alignment: .leading, spacing: 8) {
                    fieldLabel("Orientation des feuilles")
                    HStack(spacing: 8) {
                        SelectionTile(title: "Portrait", subtitle: "", symbol: "rectangle.portrait", selected: viewModel.settings.orientation == .portrait) {
                            viewModel.settings.orientation = .portrait
                        }
                        SelectionTile(title: "Paysage", subtitle: "", symbol: "rectangle", selected: viewModel.settings.orientation == .landscape) {
                            viewModel.settings.orientation = .landscape
                        }
                    }
                }
                columnsControl
                assemblySettings
            }
            .disabled(!viewModel.hasDocument || viewModel.isProcessing)
            .opacity(viewModel.hasDocument ? 1 : 0.55)
        }
    }

    private var columnsControl: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                fieldLabel("Feuilles en largeur")
                Spacer()
                Text("\(viewModel.settings.columns)")
                    .font(.system(size: 11, weight: .bold, design: .rounded)).monospacedDigit()
                    .foregroundStyle(PosterTheme.accent)
                    .frame(width: 25, height: 22)
                    .background(PosterTheme.accent.opacity(0.10), in: RoundedRectangle(cornerRadius: 6))
            }
            HStack(spacing: 10) {
                columnButton("minus", label: "Réduire la largeur", disabled: viewModel.settings.columns <= 1) {
                    viewModel.settings.columns -= 1
                }
                Slider(value: Binding(get: { Double(viewModel.settings.columns) }, set: { viewModel.settings.columns = Int($0) }), in: 1...12, step: 1)
                    .accessibilityLabel("Nombre de feuilles en largeur")
                    .accessibilityValue("\(viewModel.settings.columns) \(viewModel.settings.columns == 1 ? "feuille" : "feuilles")")
                columnButton("plus", label: "Augmenter la largeur", disabled: viewModel.settings.columns >= 12) {
                    viewModel.settings.columns += 1
                }
            }
            Text("La hauteur s’adapte automatiquement à votre document.")
                .font(.system(size: 10)).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
        }
    }

    private var assemblySettings: some View {
        DisclosureGroup(isExpanded: $showsAssemblySettings) {
            VStack(alignment: .leading, spacing: 15) {
                measurementSlider(title: "Recouvrement", value: $viewModel.settings.overlapMillimeters,
                                  explanation: "Une bande commune pour aligner et coller les feuilles.")
                measurementSlider(title: "Marges d’impression", value: $viewModel.settings.marginMillimeters,
                                  explanation: "Un bord blanc adapté aux imprimantes classiques.")
                Button("Rétablir les réglages conseillés") {
                    viewModel.settings.overlapMillimeters = 6
                    viewModel.settings.marginMillimeters = 5
                }
                .font(.system(size: 10)).buttonStyle(.link)
            }
            .padding(.top, 12).padding(.bottom, 3)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "slider.horizontal.3")
                Text("Réglages d’assemblage")
            }
            .font(.system(size: 11, weight: .medium))
        }
        .padding(11)
        .background(Color.primary.opacity(0.025), in: RoundedRectangle(cornerRadius: 9))
    }

    private var exportSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeading(number: "03", title: "Créez votre poster")
            if let layout = viewModel.layout {
                HStack(alignment: .firstTextBaseline) {
                    Text("\(layout.pageCount)")
                        .font(.system(size: 29, weight: .bold, design: .rounded)).tracking(-1).monospacedDigit()
                    Text("\(layout.pageCount == 1 ? "feuille" : "feuilles") \(viewModel.settings.paper.displayName)")
                        .font(.system(size: 12)).foregroundStyle(.secondary)
                    Spacer()
                    Image(systemName: "printer").foregroundStyle(.secondary)
                }
            } else {
                Text("Importez un fichier pour commencer.")
                    .font(.system(size: 11)).foregroundStyle(.secondary)
            }
            Button(action: viewModel.exportPoster) {
                HStack(spacing: 9) {
                    if viewModel.isProcessing {
                        ProgressView().controlSize(.small)
                    } else {
                        Image(systemName: "arrow.down.document")
                    }
                    Text(viewModel.isProcessing ? "Création en cours…" : "Exporter le poster")
                    Spacer(minLength: 0)
                    if !viewModel.isProcessing { Image(systemName: "arrow.right") }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryActionStyle()).disabled(!viewModel.canExport)
            .help("Enregistrer le poster au format PDF (⇧⌘E)")
            Text("PDF prêt à imprimer · Aucun compte requis")
                .font(.system(size: 10)).foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
        }
    }

    private func fieldLabel(_ text: String) -> some View {
        Text(text).font(.system(size: 11, weight: .medium))
    }

    private func columnButton(_ symbol: String, label: String, disabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol).font(.system(size: 10, weight: .semibold))
                .frame(width: 26, height: 26)
                .background(PosterTheme.card, in: RoundedRectangle(cornerRadius: 7))
                .overlay(RoundedRectangle(cornerRadius: 7).strokeBorder(PosterTheme.line))
        }
        .buttonStyle(.plain).disabled(disabled).accessibilityLabel(label)
    }

    private func measurementSlider(title: String, value: Binding<Double>, explanation: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(title).font(.system(size: 11, weight: .medium))
                Spacer()
                Text(PosterTheme.millimeters(value.wrappedValue)).font(.system(size: 10)).monospacedDigit().foregroundStyle(.secondary)
            }
            Slider(value: value, in: 0...20, step: 0.5).accessibilityLabel(title)
                .accessibilityValue(PosterTheme.millimeters(value.wrappedValue))
            Text(explanation).font(.system(size: 10)).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
        }
    }
}
