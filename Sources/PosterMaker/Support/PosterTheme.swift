import SwiftUI

enum PosterAppearance: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }
    var title: String {
        switch self {
        case .system: "Suivre le système"
        case .light: "Claire"
        case .dark: "Sombre"
        }
    }
    var symbol: String {
        switch self {
        case .system: "circle.lefthalf.filled"
        case .light: "sun.max"
        case .dark: "moon"
        }
    }
    @MainActor func apply() {
        // Set the native application appearance so toolbar, materials and
        // NSColor-backed surfaces switch together, including a return to nil.
        switch self {
        case .system: NSApp.appearance = nil
        case .light: NSApp.appearance = NSAppearance(named: .aqua)
        case .dark: NSApp.appearance = NSAppearance(named: .darkAqua)
        }
    }
}

enum PosterTheme {
    static let accent = Color(nsColor: NSColor(name: nil) { appearance in
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? NSColor(srgbRed: 0.66, green: 0.61, blue: 1, alpha: 1)
            : NSColor(srgbRed: 0.36, green: 0.28, blue: 0.85, alpha: 1)
    })
    static let secondaryAccent = Color(red: 0.35, green: 0.60, blue: 0.96)
    static let line = Color.primary.opacity(0.09)
    static let card = Color(nsColor: .controlBackgroundColor)

    static func centimeters(_ points: CGFloat) -> String {
        let value = Double(points / PosterMath.mmToPoints / 10)
        return value.formatted(.number.locale(Locale(identifier: "fr_FR")).precision(.fractionLength(1)))
    }
    static func dimensions(_ size: CGSize) -> String {
        "\(centimeters(size.width)) × \(centimeters(size.height)) cm"
    }
    static func millimeters(_ value: Double) -> String {
        value.formatted(.number.locale(Locale(identifier: "fr_FR")).precision(.fractionLength(0...1))) + " mm"
    }
}

struct BrandMark: View {
    var size: CGFloat = 32
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.27)
                .fill(LinearGradient(colors: [Color(red: 0.47, green: 0.38, blue: 0.98), Color(red: 0.28, green: 0.22, blue: 0.72)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
            Image(systemName: "square.grid.2x2.fill")
                .font(.system(size: size * 0.5, weight: .medium)).foregroundStyle(.white)
                .rotationEffect(.degrees(-8))
        }
        .frame(width: size, height: size).accessibilityHidden(true)
    }
}

struct PrimaryActionStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(isEnabled ? Color.white : Color.secondary)
            .padding(.horizontal, 18).frame(height: 43)
            .background {
                RoundedRectangle(cornerRadius: 11)
                    .fill(isEnabled
                          ? AnyShapeStyle(LinearGradient(colors: [Color(red: 0.43, green: 0.34, blue: 0.94), Color(red: 0.33, green: 0.26, blue: 0.80)], startPoint: .topLeading, endPoint: .bottomTrailing))
                          : AnyShapeStyle(Color.primary.opacity(0.06)))
            }
            .overlay(RoundedRectangle(cornerRadius: 11).strokeBorder(.white.opacity(isEnabled ? 0.12 : 0)))
            .shadow(color: isEnabled ? PosterTheme.accent.opacity(0.15) : .clear, radius: 8, y: 3)
            .opacity(configuration.isPressed ? 0.82 : 1)
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
    }
}

struct SectionHeading: View {
    let number: String
    let title: String
    var complete = false
    var body: some View {
        HStack(spacing: 9) {
            ZStack {
                RoundedRectangle(cornerRadius: 6).fill(PosterTheme.accent.opacity(0.10))
                if complete {
                    Image(systemName: "checkmark").font(.system(size: 10, weight: .bold))
                } else {
                    Text(number).font(.system(size: 10, weight: .bold, design: .rounded))
                }
            }
            .foregroundStyle(PosterTheme.accent).frame(width: 23, height: 23)
            Text(title).font(.system(size: 13, weight: .semibold))
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }
}

struct SelectionTile: View {
    let title: String
    let subtitle: String
    var symbol: String?
    let selected: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                HStack(spacing: 6) {
                    if let symbol { Image(systemName: symbol).font(.system(size: 13)) }
                    Text(title).font(.system(size: 12, weight: .semibold))
                }
                if !subtitle.isEmpty {
                    Text(subtitle).font(.system(size: 10)).foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity).frame(height: subtitle.isEmpty ? 35 : 54)
            .contentShape(RoundedRectangle(cornerRadius: 9))
            .background(RoundedRectangle(cornerRadius: 9).fill(selected ? PosterTheme.accent.opacity(0.09) : Color.primary.opacity(0.025)))
            .overlay(RoundedRectangle(cornerRadius: 9).strokeBorder(selected ? PosterTheme.accent.opacity(0.65) : PosterTheme.line, lineWidth: selected ? 1.3 : 1))
            .foregroundStyle(selected ? PosterTheme.accent : .primary)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(subtitle.isEmpty ? title : "\(title), \(subtitle)")
        .accessibilityAddTraits(selected ? [.isSelected] : [])
    }
}
