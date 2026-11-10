import SwiftUI

struct PosterGuideView: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack(spacing: 13) {
                BrandMark(size: 44)
                VStack(alignment: .leading, spacing: 4) {
                    Text("De l’écran au grand format.").font(.system(size: 23, weight: .bold, design: .rounded))
                    Text("Votre premier poster en quelques minutes.").font(.system(size: 12)).foregroundStyle(.secondary)
                }
            }
            VStack(alignment: .leading, spacing: 23) {
                guideStep("01", title: "Importez votre document", description: "Choisissez un PDF ou une image, ou glissez le fichier sur l’aperçu. Pour un PDF de plusieurs pages, la première page est utilisée.", symbol: "doc.badge.plus")
                guideStep("02", title: "Choisissez la taille", description: "Sélectionnez le papier de votre imprimante (A4 ou A3), son orientation et le nombre de feuilles en largeur. La hauteur est calculée automatiquement.", symbol: "square.grid.3x3")
                guideStep("03", title: "Exportez et imprimez à 100 %", description: "Enregistrez le PDF, puis imprimez toutes ses pages en « Taille réelle » ou à 100 %. Désactivez l’ajustement automatique à la page.", symbol: "printer")
                guideStep("04", title: "Assemblez votre poster", description: "Suivez l’ordre des pages : de gauche à droite, puis de haut en bas. Découpez les bords blancs nécessaires et superposez les bandes communes avant de coller.", symbol: "square.on.square")
            }
            Label("Vos documents restent sur votre Mac. Tout fonctionne hors ligne.", systemImage: "lock.shield")
                .font(.system(size: 11)).foregroundStyle(.secondary)
                .padding(13).frame(maxWidth: .infinity, alignment: .leading)
                .background(PosterTheme.accent.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
            HStack {
                Spacer()
                Button("C’est parti") { dismiss() }.buttonStyle(PrimaryActionStyle()).keyboardShortcut(.defaultAction)
            }
        }
        .padding(30).frame(width: 550).tint(PosterTheme.accent)
    }
    private func guideStep(_ number: String, title: String, description: String, symbol: String) -> some View {
        HStack(alignment: .top, spacing: 15) {
            Image(systemName: symbol).font(.system(size: 18, weight: .light)).foregroundStyle(PosterTheme.accent)
                .frame(width: 38, height: 38).background(PosterTheme.accent.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 6) {
                Text("\(number)  \(title)").font(.system(size: 13, weight: .semibold))
                Text(description).font(.system(size: 12)).foregroundStyle(.secondary)
                    .lineSpacing(3).fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
