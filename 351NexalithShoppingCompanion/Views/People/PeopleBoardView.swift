import SwiftUI

struct PeopleBoardView: View {
    @EnvironmentObject private var store: GiftStore
    @State private var editorExisting: GiftProfile?
    @State private var showCreate = false
    @State private var expandedIDs: Set<UUID> = []
    @State private var pendingDelete: GiftProfile?
    @State private var query = ""
    @State private var typeFilter: OccasionType?

    var body: some View {
        VStack(spacing: 0) {
            RibbonBanner(imageName: "BannerProfiles")
            headerRow
            if !store.giftProfiles.isEmpty {
                GiftFilterBar(query: $query, selectedType: $typeFilter, placeholder: "Search people")
            }
            if store.giftProfiles.isEmpty {
                Spacer(minLength: 12)
                GiftEmptyState(
                    symbol: "gift.fill",
                    message: "No gifts added yet! Start by creating a new profile."
                )
                Spacer()
            } else if visibleProfiles.isEmpty {
                Spacer(minLength: 12)
                GiftEmptyState(symbol: "magnifyingglass", message: "No people match this search.")
                Spacer()
            } else {
                profileList
            }
        }
        .sheet(isPresented: $showCreate) {
            ProfileEditorSheet(store: store)
        }
        .sheet(item: $editorExisting) { profile in
            ProfileEditorSheet(store: store, existing: profile)
        }
        .alert("Remove this profile?", isPresented: Binding(
            get: { pendingDelete != nil },
            set: { if !$0 { pendingDelete = nil } }
        )) {
            Button("Delete", role: .destructive) {
                if let pending = pendingDelete {
                    store.deleteProfile(pending)
                }
                pendingDelete = nil
            }
            Button("Keep", role: .cancel) { pendingDelete = nil }
        } message: {
            Text("Gift ideas and the matching date will be removed.")
        }
        .onAppear {
            if let last = store.lastViewedProfileID {
                expandedIDs.insert(last)
            }
        }
    }

    private var headerRow: some View {
        HStack {
            Text("People")
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundColor(Palette.text)
            Spacer()
            RibbonAddButton(title: "New") { showCreate = true }
        }
        .padding(.horizontal, 18)
        .padding(.bottom, 8)
    }

    private var profileList: some View {
        List {
            ForEach(visibleProfiles) { profile in
                profileBlock(profile)
                    .listRowInsets(EdgeInsets(top: 7, leading: 16, bottom: 7, trailing: 16))
                    .listRowBackground(Palette.background.opacity(0))
                    .listRowSeparator(.hidden)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            pendingDelete = profile
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

    private var visibleProfiles: [GiftProfile] {
        store.giftProfiles
            .filter { profile in
                if let typeFilter, profile.occasionType != typeFilter { return false }
                let needle = query.giftTrimmed.lowercased()
                if needle.isEmpty { return true }
                return profile.recipientName.lowercased().contains(needle)
                    || profile.giftIdeas.lowercased().contains(needle)
                    || profile.checklist.contains { $0.title.lowercased().contains(needle) }
            }
            .sorted { lhs, rhs in
                if lhs.occasionDate != rhs.occasionDate {
                    return lhs.occasionDate < rhs.occasionDate
                }
                return lhs.trimmedName.localizedCaseInsensitiveCompare(rhs.trimmedName) == .orderedAscending
            }
    }

    private func profileBlock(_ profile: GiftProfile) -> some View {
        let expanded = expandedIDs.contains(profile.id)
        let dueSoon = store.notificationsEnabled && profile.occasionDate.isGiftDue(withinDays: 14) && !profile.isPurchased
        let repeats = store.similarHistory(
            name: profile.recipientName,
            phrases: [profile.giftIdeas] + profile.checklist.map(\.title),
            excludingProfileID: profile.id
        )
        return GiftTagCard(alertStyle: dueSoon) {
            VStack(alignment: .leading, spacing: 10) {
                Button {
                    toggle(profile)
                } label: {
                    HStack(alignment: .top, spacing: 10) {
                        if profile.photoFileName != nil {
                            DiskPhoto(fileName: profile.photoFileName)
                                .frame(width: 52, height: 52)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(profile.recipientName)
                                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                                Spacer()
                                Image(systemName: expanded ? "chevron.up" : "chevron.down")
                                    .font(.system(size: 12, weight: .bold))
                            }
                            HStack(spacing: 6) {
                                GiftChip(title: profile.occasionType.title, emphasized: dueSoon)
                                Text(GiftFormatters.day.string(from: profile.occasionDate))
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                            }
                            HStack(spacing: 6) {
                                if !profile.occasionDate.giftCountdownTitle.isEmpty && !profile.isPurchased {
                                    GiftChip(title: profile.occasionDate.giftCountdownTitle, emphasized: dueSoon)
                                }
                                GiftChip(title: profile.pipelineStatus.title, emphasized: dueSoon || profile.isPurchased)
                                if dueSoon {
                                    GiftChip(title: "Due soon", emphasized: true)
                                }
                            }
                        }
                    }
                    .foregroundColor(Palette.text)
                }
                .buttonStyle(.plain)

                if expanded {
                    if let planned = profile.plannedBudget {
                        Text("Budget \(GiftFormatters.money(planned)) · spent \(GiftFormatters.money(profile.spentTotal))")
                            .font(.system(size: 13, weight: .heavy, design: .rounded))
                            .foregroundColor(Palette.text)
                    }
                    Text(profile.giftIdeas)
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundColor(Palette.text.opacity(0.92))
                    if profile.hasTasteNotes {
                        tasteBlock(profile, alert: dueSoon)
                    }
                    if !profile.checklist.isEmpty {
                        checklistBlock(profile, alert: dueSoon)
                    }
                    if let first = repeats.first {
                        Text("Similar gift last time: \(first.giftTitle.isEmpty ? "wrapped already" : first.giftTitle)")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(Palette.text)
                    }
                    if !profile.notes.giftTrimmed.isEmpty {
                        Text(profile.notes)
                            .font(.system(size: 13, weight: .regular, design: .rounded))
                            .foregroundColor(Palette.text.opacity(0.88))
                    }
                    HStack(spacing: 10) {
                        Button("Edit") { editorExisting = profile }
                        if let title = pipelineButtonTitle(profile) {
                            Button(title) { store.advancePipeline(profileID: profile.id) }
                        }
                        if profile.pipelineStatus == .idea {
                            Button("Mark Wrapped") { store.markPurchased(profileID: profile.id) }
                        }
                        Spacer()
                        Button("Delete") { pendingDelete = profile }
                    }
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundColor(Palette.text)
                }
            }
        }
    }

    private func tasteBlock(_ profile: GiftProfile, alert: Bool) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            if !profile.clothingSize.giftTrimmed.isEmpty {
                Text("Size · \(profile.clothingSize)")
            }
            if !profile.favoriteColors.giftTrimmed.isEmpty {
                Text("Colors · \(profile.favoriteColors)")
            }
            if !profile.avoidList.giftTrimmed.isEmpty {
                Text("Don't buy · \(profile.avoidList)")
            }
        }
        .font(.system(size: 13, weight: .semibold, design: .rounded))
        .foregroundColor(Palette.text.opacity(0.92))
    }

    private func checklistBlock(_ profile: GiftProfile, alert: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(profile.checklist) { item in
                Button {
                    store.toggleChecklistItem(profileID: profile.id, itemID: item.id)
                } label: {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: item.isBought ? "checkmark.circle.fill" : "circle")
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.title)
                            HStack(spacing: 6) {
                                if !item.store.giftTrimmed.isEmpty {
                                    Text(item.store)
                                }
                                if let price = item.price {
                                    Text(GiftFormatters.money(price))
                                }
                            }
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .font(.system(size: 13, weight: .medium, design: .rounded))
        .foregroundColor(Palette.text.opacity(0.92))
    }

    private func pipelineButtonTitle(_ profile: GiftProfile) -> String? {
        let title = profile.pipelineStatus.nextActionTitle
        return title.isEmpty ? nil : title
    }

    private func toggle(_ profile: GiftProfile) {
        if expandedIDs.contains(profile.id) {
            expandedIDs.remove(profile.id)
        } else {
            expandedIDs.insert(profile.id)
            store.rememberViewedProfile(profile.id)
        }
    }
}
