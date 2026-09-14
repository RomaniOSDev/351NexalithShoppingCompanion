import SwiftUI

enum BoardTab: String, CaseIterable, Identifiable {
    case people = "People"
    case dates = "Dates"
    case wrap = "Wrap"
    case stats = "Stats"

    var id: String { rawValue }

    var symbolName: String {
        switch self {
        case .people: return "person.2.fill"
        case .dates: return "calendar"
        case .wrap: return "shippingbox.fill"
        case .stats: return "chart.bar.fill"
        }
    }
}

struct FolderTabs: View {
    @Binding var selection: BoardTab
    var dueSoonCount: Int

    var body: some View {
        HStack(alignment: .bottom, spacing: 4) {
            ForEach(BoardTab.allCases) { tab in
                Button {
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.72)) {
                        selection = tab
                    }
                } label: {
                    tabStub(tab)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func tabStub(_ tab: BoardTab) -> some View {
        let selected = selection == tab
        return VStack(spacing: 5) {
            Image(systemName: tab.symbolName)
                .font(.system(size: selected ? 15 : 13, weight: .bold))
            Text(tab.rawValue)
                .font(.system(size: selected ? 13 : 12, weight: .heavy, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .foregroundColor(Palette.text)
        .frame(maxWidth: .infinity)
        .padding(.top, selected ? 12 : 8)
        .padding(.bottom, 14)
        .background {
            ZStack {
                LinearGradient(
                    colors: selected
                        ? [Palette.primary, Palette.accent]
                        : [Palette.surface, Palette.background],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                WrappingStripes(opacity: selected ? 0.28 : 0.16)
            }
            .clipShape(TicketStubShape())
            .overlay {
                TicketStubShape()
                    .stroke(selected ? Palette.accent : Palette.primary.opacity(0.45), lineWidth: 1.6)
            }
            .compositingGroup()
            .shadow(color: Palette.primary.opacity(selected ? 0.45 : 0.18), radius: selected ? 8 : 3, x: 0, y: 3)
        }
        .overlay(alignment: .topTrailing) {
            if tab == .dates && dueSoonCount > 0 {
                Text(dueSoonCount > 9 ? "9+" : "\(dueSoonCount)")
                    .font(.system(size: 9, weight: .heavy, design: .rounded))
                    .foregroundColor(Palette.text)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Color.black.opacity(0.45), in: Capsule())
                    .shadow(color: Palette.primary.opacity(0.4), radius: 3, x: 0, y: 1)
                    .offset(x: 2, y: -4)
            }
        }
        .offset(y: selected ? 0 : 6)
    }
}

struct TicketStubShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let inset: CGFloat = 7
        let crown: CGFloat = 9
        let hole: CGFloat = 3.4
        let spacing: CGFloat = 11

        path.move(to: CGPoint(x: inset, y: crown))
        path.addQuadCurve(
            to: CGPoint(x: inset + 8, y: 0),
            control: CGPoint(x: inset, y: 0)
        )
        path.addLine(to: CGPoint(x: rect.width - inset - 8, y: 0))
        path.addQuadCurve(
            to: CGPoint(x: rect.width - inset, y: crown),
            control: CGPoint(x: rect.width - inset, y: 0)
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.height - hole))

        var x = rect.maxX - spacing * 0.35
        while x > 0 {
            path.addArc(
                center: CGPoint(x: x, y: rect.maxY),
                radius: hole,
                startAngle: .degrees(0),
                endAngle: .degrees(180),
                clockwise: false
            )
            x -= spacing
        }

        path.addLine(to: CGPoint(x: 0, y: rect.height - hole))
        path.closeSubpath()
        return path
    }
}

struct WrappingStripes: View {
    var opacity: CGFloat = 0.2

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height
            Path { path in
                var x: CGFloat = -height
                while x < width + height {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x + height, y: height))
                    path.addLine(to: CGPoint(x: x + height + 6, y: height))
                    path.addLine(to: CGPoint(x: x + 6, y: 0))
                    path.closeSubpath()
                    x += 14
                }
            }
            .fill(Palette.accent.opacity(opacity))
        }
        .allowsHitTesting(false)
    }
}
