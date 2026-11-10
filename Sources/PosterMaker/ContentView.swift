import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = PosterViewModel()
    @State private var showsGuide = false
    @State private var isDropTargeted = false
    @AppStorage("PosterMaker.appearance") private var appearance: PosterAppearance = .system

    var body: some View {
        HStack(spacing: 0) {
            PosterSettingsView(viewModel: viewModel)
                .frame(width: 306)
                .background(.regularMaterial)
            Divider()
            PosterWorkspaceView(viewModel: viewModel, isDropTargeted: isDropTargeted)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onDrop(of: PosterViewModel.dropTypeIdentifiers, isTargeted: $isDropTargeted) {
                    viewModel.handleDrop(providers: $0)
                }
        }
        .tint(PosterTheme.accent)
        .onAppear { appearance.apply() }
        .onChange(of: appearance) { value in value.apply() }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                HStack(spacing: 9) {
                    BrandMark(size: 29)
                    Text("PosterMaker").font(.system(size: 15, weight: .bold, design: .rounded))
                }
                .padding(.leading, 4)
            }
            ToolbarItem(placement: .principal) {
                Text("Les petites pages font les grandes idées.")
                    .font(.system(size: 12)).foregroundStyle(.secondary)
            }
            ToolbarItemGroup(placement: .primaryAction) {
                Button(action: viewModel.chooseDocument) {
                    Label("Importer", systemImage: "plus")
                }
                .help("Importer un PDF ou une image (⌘O)")
                .disabled(viewModel.isProcessing)
                Menu {
                    Picker("Apparence", selection: $appearance) {
                        ForEach(PosterAppearance.allCases) { option in
                            Label(option.title, systemImage: option.symbol).tag(option)
                        }
                    }
                } label: {
                    Label("Apparence", systemImage: appearance.symbol)
                }
                .help("Apparence : système, claire ou sombre")
                .accessibilityLabel("Apparence")
                Button { showsGuide = true } label: {
                    Label("Mode d’emploi", systemImage: "questionmark.circle")
                }
                .help("Comment créer et imprimer un poster")
            }
        }
        .focusedSceneValue(\.posterActions, PosterActions(
            importDocument: viewModel.chooseDocument,
            exportPoster: viewModel.exportPoster,
            showGuide: { showsGuide = true },
            canExport: viewModel.canExport,
            canImport: !viewModel.isProcessing
        ))
        .sheet(isPresented: $showsGuide) { PosterGuideView() }
        .sheet(item: $viewModel.completedExport) { result in ExportSuccessView(result: result) }
        .alert(item: $viewModel.alert) { alert in
            Alert(title: Text(alert.title), message: Text(alert.message), dismissButton: .default(Text("Compris")))
        }
    }
}
