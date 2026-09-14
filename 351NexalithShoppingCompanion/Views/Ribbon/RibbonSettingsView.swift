import SwiftUI
import UIKit

struct RibbonSettingsView: View {
    @EnvironmentObject private var store: GiftStore
    @Environment(\.dismiss) private var dismiss
    @State private var confirmReset = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 14) {
                    GiftTagCard {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Due soon reminders")
                                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                                Spacer()
                                Toggle("", isOn: Binding(
                                    get: { store.notificationsEnabled },
                                    set: { store.setNotificationsEnabled($0) }
                                ))
                                .labelsHidden()
                                .tint(Palette.primary)
                            }
                            Text("Badges in the app, plus alerts 14, 7, and 1 day before a date.")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.86))
                        }
                        .foregroundColor(Palette.text)
                    }

                    settingsButton(title: "Rate Us", symbol: "star.fill") {
                        AppLinks.rateApp()
                    }
                    settingsButton(title: "Privacy", symbol: "lock.fill") {
                        open(AppLinks.privacy.rawValue)
                    }
                    settingsButton(title: "Terms", symbol: "doc.text.fill") {
                        open(AppLinks.terms.rawValue)
                    }
                    settingsButton(title: "Reset All Data", symbol: "trash.fill") {
                        confirmReset = true
                    }
                }
                .padding(18)
            }
            .studioBackdrop()
            .preferredColorScheme(.dark)
            .navigationTitle("Gift Tag")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Palette.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                        .foregroundColor(Palette.text)
                }
            }
            .alert("Reset all data?", isPresented: $confirmReset) {
                Button("Reset", role: .destructive) { store.resetAll() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Profiles, dates, photos, and history will be cleared.")
            }
        }
        .navigationViewStyle(.stack)
    }

    private func settingsButton(title: String, symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            GiftTagCard {
                HStack {
                    Image(systemName: symbol)
                        .font(.system(size: 16, weight: .bold))
                    Text(title)
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundColor(Palette.text)
            }
        }
        .buttonStyle(.plain)
    }

    private func open(_ value: String) {
        guard let url = URL(string: value) else { return }
        UIApplication.shared.open(url)
    }
}
