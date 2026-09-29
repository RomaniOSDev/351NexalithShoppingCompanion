import SwiftUI

struct NoInternetView: View {
    var onRetry: () -> Void

    var body: some View {
        ZStack {
            deskBackground

            VStack(spacing: 18) {
                Spacer(minLength: 0)

                ZStack {
                    Circle()
                        .fill(Color.appSurface.opacity(0.95))
                        .frame(width: 108, height: 108)
                        .overlay(
                            Circle()
                                .stroke(Color.appAccent.opacity(0.35), lineWidth: 1.2)
                        )

                    Image(systemName: "wifi.slash")
                        .font(.system(size: 40, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.appPrimary, Color.appAccent],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }

                Text("No Internet Connection")
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundColor(.appPrimary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Please check your connection and try again.")
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundColor(.appPrimary.opacity(0.72))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 12)

                Spacer(minLength: 0)

                Button(action: onRetry) {
                    Text("Retry")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(Color.appBackground)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(Color.appPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 24)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
    }

    private var deskBackground: some View {
        Color.appBackground
            .overlay {
                Image("BgGifts")
                    .resizable()
                    .scaledToFill()
                    .opacity(0.22)
                    .allowsHitTesting(false)
            }
            .overlay {
                LinearGradient(
                    colors: [
                        Color.appBackground.opacity(0.7),
                        Color.appSurface.opacity(0.45),
                        Color.appBackground.opacity(0.85)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .clipped()
            .ignoresSafeArea()
    }
}

#Preview {
    NoInternetView(onRetry: {})
}
