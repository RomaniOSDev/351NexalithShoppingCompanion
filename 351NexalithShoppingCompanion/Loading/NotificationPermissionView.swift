import SwiftUI

struct NotificationPermissionView: View {
    var onAccept: () -> Void
    var onDecline: () -> Void

    var body: some View {
        ZStack {
            deskBackground

            VStack(spacing: 20) {
                Spacer(minLength: 0)
                iconSection
                textSection
                buttonsSection
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 24)
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
                        Color.appSurface.opacity(0.4),
                        Color.appBackground.opacity(0.85)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .clipped()
            .ignoresSafeArea()
    }

    private var iconSection: some View {
        ZStack {
            Circle()
                .fill(Color.appSurface.opacity(0.95))
                .frame(width: 112, height: 112)
                .overlay(
                    Circle()
                        .stroke(Color.appAccent.opacity(0.4), lineWidth: 1.2)
                )

            Image(systemName: "bell.badge.fill")
                .font(.system(size: 44, weight: .semibold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.appPrimary, Color.appAccent],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
    }

    private var textSection: some View {
        VStack(spacing: 12) {
            Text("Enable Notifications")
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundColor(.appPrimary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Text("Stay updated with important news and bonus. You can change this later in Settings.")
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .foregroundColor(.appPrimary.opacity(0.72))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
    }

    private var buttonsSection: some View {
        VStack(spacing: 14) {
            Button(action: onAccept) {
                Text("Enable")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(Color.appBackground)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.appPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)

            Button(action: onDecline) {
                Text("Not Now")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.appPrimary.opacity(0.8))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.appSurface.opacity(0.9))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.appAccent.opacity(0.3), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview("Notification Permission") {
    NotificationPermissionView(onAccept: {}, onDecline: {})
}
