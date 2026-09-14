import SwiftUI
import UIKit

struct GiftTagShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let tip = min(20, rect.height * 0.32)
        path.move(to: CGPoint(x: tip, y: 0))
        path.addLine(to: CGPoint(x: rect.width - 14, y: 0))
        path.addQuadCurve(
            to: CGPoint(x: rect.width, y: 14),
            control: CGPoint(x: rect.width, y: 0)
        )
        path.addLine(to: CGPoint(x: rect.width, y: rect.height - 14))
        path.addQuadCurve(
            to: CGPoint(x: rect.width - 14, y: rect.height),
            control: CGPoint(x: rect.width, y: rect.height)
        )
        path.addLine(to: CGPoint(x: tip, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height / 2))
        path.closeSubpath()
        return path
    }
}

struct GiftTagCard<Content: View>: View {
    var showsRibbon: Bool = true
    var alertStyle: Bool = false
    @ViewBuilder var content: () -> Content

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Palette.background.opacity(0.55))
                Circle()
                    .strokeBorder(Palette.accent, lineWidth: 2.4)
            }
            .frame(width: 18, height: 18)
            .padding(.top, 4)

            content()
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundColor(Palette.text)
        }
        .padding(.leading, 16)
        .padding(.trailing, 18)
        .padding(.vertical, 14)
        .background {
            ZStack(alignment: .top) {
                LinearGradient(
                    colors: alertStyle
                        ? [Palette.primary.opacity(0.92), Palette.accent]
                        : [Palette.background, Palette.surface.opacity(0.88)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                WrappingStripes(opacity: alertStyle ? 0.1 : 0.05)
                if showsRibbon {
                    LinearGradient(
                        colors: [Palette.primary, Palette.accent],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(height: 5)
                }
            }
        }
        .clipShape(GiftTagShape())
        .overlay {
            GiftTagShape()
                .stroke(alertStyle ? Palette.accent : Palette.primary.opacity(0.55), lineWidth: 1.8)
        }
        .shadow(color: Palette.primary.opacity(alertStyle ? 0.42 : 0.26), radius: 8, x: 0, y: 5)
    }
}

struct HangingGiftTag: View {
    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Palette.primary)
                .frame(width: 3, height: 16)
            ZStack {
                GiftTagShape()
                    .fill(
                        LinearGradient(
                            colors: [Palette.primary, Palette.accent],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 46, height: 54)
                    .shadow(color: Palette.primary.opacity(0.4), radius: 6, x: 0, y: 4)
                Image(systemName: "gift.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Palette.text)
                    .rotationEffect(.degrees(-8))
            }
        }
        .offset(y: 2)
        .accessibilityLabel("Settings")
    }
}

struct GiftEmptyState: View {
    let symbol: String
    let message: String

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 42, weight: .semibold))
                .foregroundColor(Palette.text)
                .shadow(color: Color.black.opacity(0.35), radius: 8, x: 0, y: 4)
            Text(message)
                .font(.system(size: 17, weight: .heavy, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .shadow(color: Palette.primary.opacity(0.45), radius: 6, x: 0, y: 2)
                .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
    }
}

struct GiftFieldLabel: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.system(size: 13, weight: .heavy, design: .rounded))
            .foregroundColor(Palette.text)
    }
}

struct GiftLineField: View {
    let placeholder: String
    @Binding var text: String
    var capitalization: TextInputAutocapitalization = .words
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        TextField(
            "",
            text: $text,
            prompt: Text(placeholder)
                .foregroundColor(.white.opacity(0.78))
                .font(.system(size: 16, weight: .medium, design: .rounded))
        )
        .font(.system(size: 16, weight: .semibold, design: .rounded))
        .foregroundColor(.white)
        .tint(Palette.primary)
        .textInputAutocapitalization(capitalization)
        .keyboardType(keyboardType)
    }
}

struct GiftNoteEditor: View {
    let placeholder: String
    @Binding var text: String
    var minHeight: CGFloat = 80
    var textColor: Color = .white

    var body: some View {
        ZStack(alignment: .topLeading) {
            if text.isEmpty {
                Text(placeholder)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.72))
                    .padding(.top, 8)
                    .padding(.leading, 5)
                    .allowsHitTesting(false)
            }
            TextEditor(text: $text)
                .frame(minHeight: minHeight)
                .scrollContentBackground(.hidden)
                .foregroundColor(textColor)
                .tint(Palette.primary)
                .font(.system(size: 15, weight: .medium, design: .rounded))
        }
    }
}

struct GiftToggleRow: View {
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
            Spacer()
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(Palette.primary)
        }
        .foregroundColor(.white)
    }
}

struct GiftFilterBar: View {
    @Binding var query: String
    @Binding var selectedType: OccasionType?
    var placeholder: String = "Search"

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            GiftLineField(placeholder: placeholder, text: $query, capitalization: .never)
                .padding(10)
                .background(Palette.surface.opacity(0.92), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Palette.accent.opacity(0.45), lineWidth: 1)
                }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    filterChip("All", selected: selectedType == nil) { selectedType = nil }
                    ForEach(OccasionType.allCases) { type in
                        filterChip(type.title, selected: selectedType == type) {
                            selectedType = type
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.bottom, 8)
    }

    private func filterChip(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .foregroundColor(Palette.text)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(selected ? Palette.background : Palette.surface.opacity(0.7), in: Capsule())
                .overlay {
                    Capsule().stroke(Palette.accent.opacity(0.7), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
    }
}

struct GiftChip: View {
    let title: String
    var emphasized: Bool = false

    var body: some View {
        Text(title)
            .font(.system(size: 11, weight: .heavy, design: .rounded))
            .foregroundColor(Palette.text)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule().fill(emphasized ? Color.black.opacity(0.38) : Palette.background.opacity(0.72))
            )
            .overlay {
                Capsule().stroke(Palette.accent.opacity(0.7), lineWidth: 1)
            }
    }
}
