import SwiftUI

struct RibbonBanner: View {
    let imageName: String

    var body: some View {
        Color.clear
            .frame(maxWidth: .infinity)
            .frame(height: 148)
            .background {
                Palette.surface
                    .overlay {
                        Image(imageName)
                            .resizable()
                            .scaledToFill()
                    }
                    .clipped()
            }
            .overlay(alignment: .bottom) {
                DiagonalRibbonBar()
                    .frame(height: 22)
                    .padding(.bottom, 18)
            }
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Palette.primary, Palette.accent, Palette.primary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2.4
                )
        }
        .shadow(color: Palette.primary.opacity(0.32), radius: 12, x: 0, y: 7)
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 6)
    }
}

struct DiagonalRibbonBar: View {
    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = max(proxy.size.height, 16)
            Path { path in
                path.move(to: CGPoint(x: -12, y: height * 0.15))
                path.addLine(to: CGPoint(x: width + 12, y: height * 0.05))
                path.addLine(to: CGPoint(x: width + 12, y: height * 0.95))
                path.addLine(to: CGPoint(x: -12, y: height))
                path.closeSubpath()
            }
            .fill(
                LinearGradient(
                    colors: [Palette.primary, Palette.accent, Palette.primary],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .overlay {
                Path { path in
                    path.move(to: CGPoint(x: -12, y: height * 0.38))
                    path.addLine(to: CGPoint(x: width + 12, y: height * 0.28))
                    path.addLine(to: CGPoint(x: width + 12, y: height * 0.42))
                    path.addLine(to: CGPoint(x: -12, y: height * 0.52))
                    path.closeSubpath()
                }
                .fill(Palette.accent.opacity(0.55))
            }
            .shadow(color: Palette.primary.opacity(0.28), radius: 3, x: 0, y: 2)
        }
        .allowsHitTesting(false)
    }
}

struct RibbonAddButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: "plus")
                    .font(.system(size: 13, weight: .heavy))
                Text(title)
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
            }
            .foregroundColor(Palette.text)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                LinearGradient(
                    colors: [Palette.primary, Palette.accent],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: Capsule()
            )
            .shadow(color: Palette.primary.opacity(0.35), radius: 5, x: 0, y: 3)
        }
        .buttonStyle(.plain)
    }
}
