import SwiftUI

struct ContentView: View {
    @StateObject private var store = GiftStore()
    @State private var tab: BoardTab = .people
    @State private var showSettings = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .bottom, spacing: 8) {
                FolderTabs(selection: $tab, dueSoonCount: store.dueSoonCount)
                Button {
                    showSettings = true
                } label: {
                    HangingGiftTag()
                }
                .buttonStyle(.plain)
                .padding(.trailing, 6)
            }
            .padding(.horizontal, 10)
            .padding(.top, 6)
            .padding(.bottom, 4)

            Group {
                switch tab {
                case .people:
                    PeopleBoardView()
                case .dates:
                    DateRibbonView()
                case .wrap:
                    WrapSummaryView()
                case .stats:
                    GiftStatsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .studioBackdrop()
        .preferredColorScheme(.dark)
        .dismissKeyboardOnTap()
        .environmentObject(store)
        .onAppear {
            _ = store.rollRepeatingDatesIfNeeded()
        }
        .sheet(isPresented: $showSettings) {
            RibbonSettingsView()
                .environmentObject(store)
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("dataReset"))) { _ in
            tab = .people
            showSettings = false
        }
    }
}
