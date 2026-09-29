import SwiftUI

struct LoadingAmbientField: View {
    @State private var drift = false

    var body: some View {
        Color.appBackground
            .overlay {
                Image("BgGifts")
                    .resizable()
                    .scaledToFill()
                    .opacity(0.26)
                    .allowsHitTesting(false)
            }
            .overlay {
                Image("LoadingGiftHero")
                    .resizable()
                    .scaledToFill()
                    .opacity(0.3)
                    .allowsHitTesting(false)
            }
            .overlay {
                ZStack {
                    LinearGradient(
                        colors: [
                            Color.appBackground.opacity(0.7),
                            Color.appSurface.opacity(0.4),
                            Color.appBackground.opacity(0.8)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    WrappingStripes(opacity: 0.07)

                    RadialGradient(
                        colors: [
                            Color.appPrimary.opacity(0.32),
                            Color.appAccent.opacity(0.1),
                            .clear
                        ],
                        center: UnitPoint(x: drift ? 0.3 : 0.26, y: 0.45),
                        startRadius: 18,
                        endRadius: 420
                    )

                    Ellipse()
                        .fill(Color.appPrimary.opacity(0.16))
                        .frame(width: 300, height: 180)
                        .blur(radius: 70)
                        .offset(x: drift ? -100 : -130, y: drift ? -10 : 12)

                    Ellipse()
                        .fill(Color.appAccent.opacity(0.14))
                        .frame(width: 260, height: 160)
                        .blur(radius: 60)
                        .offset(x: drift ? 130 : 100, y: drift ? 60 : 36)
                }
            }
            .clipped()
            .ignoresSafeArea()
            .allowsHitTesting(false)
            .onAppear {
                withAnimation(.easeInOut(duration: 4.8).repeatForever(autoreverses: true)) {
                    drift = true
                }
            }
    }
}

struct LoadingGiftMark: View {
    @State private var pulse = false
    @State private var sway = false

    var body: some View {
        ZStack {
            GiftTagShape()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.appBackground.opacity(0.96),
                            Color.appSurface.opacity(0.9)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    WrappingStripes(opacity: 0.18)
                        .clipShape(GiftTagShape())
                }
                .overlay {
                    GiftTagShape()
                        .stroke(
                            LinearGradient(
                                colors: [Color.appPrimary, Color.appAccent],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2.2
                        )
                }
                .shadow(color: Color.appPrimary.opacity(pulse ? 0.55 : 0.28), radius: pulse ? 20 : 12, y: 8)

            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.black.opacity(0.22))
                        .frame(width: 58, height: 58)
                    Circle()
                        .strokeBorder(Color.appAccent, lineWidth: 2.2)
                        .frame(width: 58, height: 58)
                    Image(systemName: "gift.fill")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.appPrimary, Color.appAccent],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .rotationEffect(.degrees(sway ? -8 : 8))
                        .scaleEffect(pulse ? 1.06 : 0.96)
                }

                Text("GIFT")
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .tracking(3.4)
                    .foregroundStyle(Color.white)
            }
            .padding(.leading, 8)
        }
        .frame(width: 148, height: 168)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                pulse = true
            }
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                sway = true
            }
        }
    }
}

struct LoadingHeroArt: View {
    var height: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.appSurface.opacity(0.5))
                .overlay {
                    Image("LoadingGiftHero")
                        .resizable()
                        .scaledToFill()
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.appPrimary.opacity(0.85),
                                    Color.appAccent.opacity(0.45)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.6
                        )
                }
                .overlay(alignment: .top) {
                    LinearGradient(
                        colors: [Color.appPrimary, Color.appAccent],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(height: 5)
                    .clipShape(
                        UnevenRoundedRectangle(
                            topLeadingRadius: 18,
                            bottomLeadingRadius: 0,
                            bottomTrailingRadius: 0,
                            topTrailingRadius: 18
                        )
                    )
                }
                .shadow(color: Color.appPrimary.opacity(0.35), radius: 16, y: 8)

            LoadingGiftMark()
        }
        .frame(height: height)
        .frame(maxWidth: .infinity)
        .clipped()
    }
}

struct LoadingCopyBlock: View {
    var centered: Bool
    var titleSize: CGFloat

    var body: some View {
        VStack(alignment: centered ? .center : .leading, spacing: 8) {
            Text("NEXALITH")
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .tracking(4)
                .foregroundStyle(Color.appAccent)

            Text("Shopping Companion")
                .font(.system(size: titleSize, weight: .heavy, design: .rounded))
                .tracking(0.5)
                .foregroundStyle(Color.white)
                .minimumScaleFactor(0.7)
                .lineLimit(1)

            Text("Gift ideas, dates, and wrap-ready plans.")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.84))
                .multilineTextAlignment(centered ? .center : .leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: centered ? .center : .leading)
    }
}

struct LoadingProgressBar: View {
    @State private var phase: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.appSurface.opacity(0.92))
                    .overlay(
                        Capsule()
                            .stroke(Color.appAccent.opacity(0.45), lineWidth: 1)
                    )

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color.appPrimary, Color.appAccent, Color.appPrimary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(width * 0.34, 40))
                    .offset(x: phase * (width * 0.66))
                    .shadow(color: Color.appPrimary.opacity(0.55), radius: 8, y: 0)
            }
        }
        .frame(height: 7)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.25).repeatForever(autoreverses: true)) {
                phase = 1
            }
        }
    }
}

struct LoadingStatusLine: View {
    @State private var step = 0

    private let lines = [
        "Tying the gift ribbon",
        "Sorting occasion dates",
        "Warming up wrap ideas"
    ]

    var body: some View {
        Text(lines[step % lines.count])
            .font(.system(size: 14, weight: .heavy, design: .rounded))
            .tracking(0.4)
            .foregroundStyle(Color.white.opacity(0.86))
            .multilineTextAlignment(.center)
            .id(step)
            .transition(.opacity.combined(with: .move(edge: .bottom)))
            .task {
                while !Task.isCancelled {
                    try? await Task.sleep(nanoseconds: 1_700_000_000)
                    guard !Task.isCancelled else { return }
                    withAnimation(.easeInOut(duration: 0.32)) {
                        step = (step + 1) % lines.count
                    }
                }
            }
    }
}

struct LoadingView: View {
    @State private var appeared = false

    var body: some View {
        GeometryReader { geo in
            let landscape = geo.size.width > geo.size.height

            ZStack {
                LoadingAmbientField()

                Group {
                    if landscape {
                        landscapeContent(height: geo.size.height)
                    } else {
                        portraitContent
                    }
                }
                .padding(.horizontal, landscape ? 40 : 24)
                .padding(.vertical, landscape ? 20 : 12)
                .opacity(appeared ? 1 : 0)
                .scaleEffect(appeared ? 1 : 0.94)
                .offset(y: appeared ? 0 : 12)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
        .onAppear {
            withAnimation(.spring(response: 0.72, dampingFraction: 0.82)) {
                appeared = true
            }
        }
    }

    private func landscapeContent(height: CGFloat) -> some View {
        HStack(alignment: .center, spacing: 32) {
            LoadingHeroArt(height: min(max(height - 56, 160), 240))
                .frame(maxWidth: 420)

            VStack(alignment: .leading, spacing: 18) {
                LoadingCopyBlock(centered: false, titleSize: 26)
                LoadingProgressBar()
                    .frame(maxWidth: 240)
                LoadingStatusLine()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: 360, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var portraitContent: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            LoadingHeroArt(height: 220)
                .padding(.bottom, 18)
            LoadingCopyBlock(centered: true, titleSize: 28)
            VStack(spacing: 14) {
                LoadingProgressBar()
                    .frame(maxWidth: 180)
                LoadingStatusLine()
            }
            .padding(.top, 22)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview("Landscape") {
    LoadingView()
        .previewInterfaceOrientation(.landscapeLeft)
}

#Preview("Portrait") {
    LoadingView()
}
