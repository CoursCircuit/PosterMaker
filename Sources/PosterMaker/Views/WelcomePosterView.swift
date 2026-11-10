import SwiftUI

struct WelcomePosterView: View {
    let importDocument: () -> Void
    let loadExample: () -> Void

    var body: some View {
        ViewThatFits(in: .vertical) {
            welcomeContent(artHeight: 220, spacing: 22)
            welcomeContent(artHeight: 150, spacing: 15)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func welcomeContent(artHeight: CGFloat, spacing: CGFloat) -> some View {
        VStack(spacing: spacing) {
            PosterIllustration().frame(width: 300, height: artHeight)
            VStack(spacing: 11) {
                Text("Un petit fichier.\nUn grand poster.")
                    .font(.system(size: 31, weight: .bold, design: .rounded)).tracking(-0.9)
                    .multilineTextAlignment(.center)
                Text("Déposez votre document ici.\nPosterMaker le répartit sur plusieurs feuilles à assembler.")
                    .font(.system(size: 12)).foregroundStyle(.secondary)
                    .multilineTextAlignment(.center).lineSpacing(4)
            }
            VStack(spacing: 12) {
                Button(action: importDocument) {
                    Label("Choisir un PDF ou une image", systemImage: "plus")
                }
                .buttonStyle(PrimaryActionStyle())
                Button("Essayer avec un exemple", action: loadExample)
                    .buttonStyle(.link).font(.system(size: 11))
            }
            Text("PDF · PNG · JPEG · HEIC · TIFF")
                .font(.system(size: 9, weight: .medium)).tracking(1.2).foregroundStyle(.secondary)
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}

private struct PosterIllustration: View {
    var body: some View {
        GeometryReader { proxy in
            let height = proxy.size.height * 0.91
            let width = height * 0.76
            ZStack {
                Circle().fill(PosterTheme.accent.opacity(0.055)).frame(width: height * 1.15)
                RoundedRectangle(cornerRadius: 4)
                    .fill(PosterTheme.card).frame(width: width, height: height)
                    .overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(PosterTheme.line))
                    .rotationEffect(.degrees(11)).offset(x: 20, y: 1)
                RoundedRectangle(cornerRadius: 4)
                    .fill(PosterTheme.accent.opacity(0.09)).frame(width: width, height: height)
                    .rotationEffect(.degrees(-12)).offset(x: -16, y: 2)
                ZStack(alignment: .topLeading) {
                    Rectangle().fill(Color(red: 0.17, green: 0.13, blue: 0.36))
                    Circle()
                        .fill(LinearGradient(colors: [Color(red: 0.99, green: 0.68, blue: 0.48), Color(red: 0.65, green: 0.53, blue: 0.97)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: width * 0.94, height: width * 0.94)
                        .offset(x: width * 0.32, y: height * 0.33)
                    Circle().strokeBorder(.white.opacity(0.35), lineWidth: 0.8)
                        .frame(width: width * 1.15, height: width * 1.15)
                        .offset(x: width * 0.12, y: height * 0.29)
                    VStack(alignment: .leading, spacing: 0) {
                        Text("LES IDÉES PRENNENT LE LARGE")
                            .font(.system(size: height * 0.025, weight: .semibold)).tracking(1)
                            .padding(.bottom, height * 0.12)
                        Text("VOIR\nPLUS\nGRAND.")
                            .font(.system(size: height * 0.15, weight: .black, design: .rounded))
                            .tracking(-height * 0.007).lineSpacing(-height * 0.018)
                        Spacer()
                        Text("POSTERMAKER  /  STUDIO 01")
                            .font(.system(size: height * 0.025, weight: .medium)).tracking(0.8)
                    }
                    .foregroundStyle(.white).padding(height * 0.08)
                    Canvas { context, size in
                        var lines = Path()
                        for col in 1...2 {
                            let x = size.width * CGFloat(col) / 3
                            lines.move(to: CGPoint(x: x, y: 0)); lines.addLine(to: CGPoint(x: x, y: size.height))
                        }
                        for row in 1...2 {
                            let y = size.height * CGFloat(row) / 3
                            lines.move(to: CGPoint(x: 0, y: y)); lines.addLine(to: CGPoint(x: size.width, y: y))
                        }
                        context.stroke(lines, with: .color(.white.opacity(0.55)), style: StrokeStyle(lineWidth: 0.7, dash: [3, 3]))
                    }
                }
                .frame(width: width, height: height).clipped()
                .overlay(Rectangle().strokeBorder(.white.opacity(0.4), lineWidth: 0.7))
                .shadow(color: .black.opacity(0.20), radius: 17, y: 10)
                .rotationEffect(.degrees(-5))
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 15, weight: .medium)).foregroundStyle(PosterTheme.accent)
                    .frame(width: 38, height: 38).background(PosterTheme.card, in: RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(PosterTheme.line))
                    .shadow(color: .black.opacity(0.06), radius: 8, y: 3)
                    .offset(x: width * 0.68, y: -height * 0.31)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .accessibilityHidden(true)
    }
}
