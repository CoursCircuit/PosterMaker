import SwiftUI
import AppKit

@main
struct PosterMakerApp: App {
    @NSApplicationDelegateAdaptor(PosterAppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup("PosterMaker") {
            ContentView().frame(minWidth: 1000, minHeight: 720)
        }
        .defaultSize(width: 1180, height: 820)
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified)
        .commands {
            CommandGroup(replacing: .newItem) { PosterFileCommands() }
            CommandGroup(replacing: .help) { PosterHelpCommands() }
        }
    }
}

final class PosterAppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }
}

struct PosterActions {
    let importDocument: () -> Void
    let exportPoster: () -> Void
    let showGuide: () -> Void
    let canExport: Bool
    let canImport: Bool
}

private struct PosterActionsKey: FocusedValueKey { typealias Value = PosterActions }

extension FocusedValues {
    var posterActions: PosterActions? {
        get { self[PosterActionsKey.self] }
        set { self[PosterActionsKey.self] = newValue }
    }
}

private struct PosterFileCommands: View {
    @FocusedValue(\.posterActions) private var actions

    var body: some View {
        Button("Importer un PDF ou une image…") { actions?.importDocument() }
            .keyboardShortcut("o").disabled(actions?.canImport != true)
        Button("Exporter le poster en PDF…") { actions?.exportPoster() }
            .keyboardShortcut("e", modifiers: [.command, .shift]).disabled(actions?.canExport != true)
    }
}

private struct PosterHelpCommands: View {
    @FocusedValue(\.posterActions) private var actions
    var body: some View {
        Button("Créer et imprimer un poster") { actions?.showGuide() }
            .keyboardShortcut("?", modifiers: .command)
    }
}
