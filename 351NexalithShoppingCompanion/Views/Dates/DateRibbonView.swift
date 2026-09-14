import SwiftUI

struct DateRibbonView: View {
    enum Segment: String, CaseIterable {
        case upcoming = "Upcoming"
        case past = "Past"
    }

    @EnvironmentObject private var store: GiftStore
    @State private var segment: Segment = .upcoming
    @State private var showCreate = false
    @State private var editorExisting: GiftOccasion?
    @State private var pendingDelete: GiftOccasion?
    @State private var query = ""
    @State private var typeFilter: OccasionType?

    var body: some View {
        VStack(spacing: 0) {
            RibbonBanner(imageName: "BannerCalendar")
            headerRow
            segmentControl
            if !store.occasions.isEmpty {
                GiftFilterBar(query: $query, selectedType: $typeFilter, placeholder: "Search dates")
            }
            if store.occasions.isEmpty {
                Spacer(minLength: 12)
                GiftEmptyState(
                    symbol: segment == .upcoming ? "calendar.badge.plus" : "calendar",
                    message: segment == .upcoming
                        ? "No upcoming events added yet! Tap '+' to start planning."
                        : "No past occasions yet. Earlier dates will gather here."
                )
                Spacer()
            } else if visibleOccasions.isEmpty {
                Spacer(minLength: 12)
                GiftEmptyState(
                    symbol: segment == .upcoming ? "calendar.badge.plus" : "calendar",
                    message: query.giftTrimmed.isEmpty && typeFilter == nil
                        ? (segment == .upcoming
                            ? "No upcoming events added yet! Tap '+' to start planning."
                            : "No past occasions yet. Earlier dates will gather here.")
                        : "No dates match this search."
                )
                Spacer()
            } else {
                occasionList
            }
        }
        .sheet(isPresented: $showCreate) {
            OccasionEditorSheet(store: store)
        }
        .sheet(item: $editorExisting) { occasion in
            OccasionEditorSheet(store: store, existing: occasion)
        }
        .confirmationDialog(
            "Delete this date?",
            isPresented: Binding(
                get: { pendingDelete != nil },
                set: { if !$0 { pendingDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let pending = pendingDelete {
                    store.deleteOccasion(pending)
                }
                pendingDelete = nil
            }
            Button("Cancel", role: .cancel) { pendingDelete = nil }
        } message: {
            Text("This occasion will be removed from the ribbon.")
        }
    }

    private var headerRow: some View {
        HStack {
            Text("Dates")
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundColor(Palette.text)
            Spacer()
            RibbonAddButton(title: "+") { showCreate = true }
        }
        .padding(.horizontal, 18)
        .padding(.bottom, 8)
    }

    private var segmentControl: some View {
        Picker("Segment", selection: $segment) {
            ForEach(Segment.allCases, id: \.self) { item in
                Text(item.rawValue).tag(item)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 18)
        .padding(.bottom, 8)
        .tint(Palette.primary)
    }

    private var visibleOccasions: [GiftOccasion] {
        let base = segment == .upcoming ? store.upcomingOccasions() : store.pastOccasions()
        return base.filter { occasion in
            if let typeFilter, occasion.occasionType != typeFilter { return false }
            let needle = query.giftTrimmed.lowercased()
            if needle.isEmpty { return true }
            return occasion.contactName.lowercased().contains(needle)
                || occasion.notes.lowercased().contains(needle)
        }
    }

    private var occasionList: some View {
        List {
            ForEach(visibleOccasions) { occasion in
                occasionRow(occasion)
                    .listRowInsets(EdgeInsets(top: 7, leading: 16, bottom: 7, trailing: 16))
                    .listRowBackground(Palette.background.opacity(0))
                    .listRowSeparator(.hidden)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            pendingDelete = occasion
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .scrollDismissesKeyboard(.immediately)
    }

    private func occasionRow(_ occasion: GiftOccasion) -> some View {
        let alert = store.notificationsEnabled && store.needsIdeaAlert(for: occasion)
        return GiftTagCard(alertStyle: alert) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(occasion.contactName)
                            .font(.system(size: 18, weight: .heavy, design: .rounded))
                        HStack(spacing: 6) {
                            Image(systemName: occasion.occasionType.symbolName)
                            Text(occasion.occasionType.title)
                            Text("·")
                            Text(GiftFormatters.day.string(from: occasion.date))
                        }
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        if !occasion.date.giftCountdownTitle.isEmpty && occasion.date.isGiftUpcoming {
                            GiftChip(title: occasion.date.giftCountdownTitle, emphasized: alert)
                        }
                        if alert {
                            GiftChip(title: "Due soon", emphasized: true)
                        }
                    }
                }
                .foregroundColor(Palette.text)

                if occasion.repeatsYearly {
                    Text("Repeats every year")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(Palette.text.opacity(0.88))
                }
                if let budget = occasion.plannedBudget {
                    Text("Budget \(GiftFormatters.money(budget))")
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .foregroundColor(Palette.text)
                }
                if !occasion.notes.giftTrimmed.isEmpty {
                    Text(occasion.notes)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(Palette.text.opacity(0.88))
                }

                HStack(spacing: 12) {
                    Button("Edit") { editorExisting = occasion }
                    Spacer()
                    Button("Delete") { pendingDelete = occasion }
                }
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundColor(Palette.text)
            }
        }
    }
}
