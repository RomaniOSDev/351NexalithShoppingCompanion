import SwiftUI

struct WrapSummaryView: View {
    @EnvironmentObject private var store: GiftStore
    @State private var personFilter: String = ""
    @State private var query = ""
    @State private var typeFilter: OccasionType?
    @State private var ideaPrefill: GiftOccasion?
    @State private var historyPhotoTarget: PurchaseRecord?
    @State private var showHistoryLibraryPicker = false
    @State private var showHistoryCameraPicker = false
    @State private var showHistoryPhotoMenu = false

    var body: some View {
        VStack(spacing: 0) {
            RibbonBanner(imageName: "BannerSummary")
            headerRow
            if !isCompletelyEmpty {
                GiftFilterBar(query: $query, selectedType: $typeFilter, placeholder: "Search wrap")
            }
            if isCompletelyEmpty {
                Spacer(minLength: 12)
                GiftEmptyState(
                    symbol: "gift.fill",
                    message: "Start Planning Your Gifts!"
                )
                Spacer()
            } else {
                summaryList
            }
        }
        .sheet(item: $ideaPrefill) { occasion in
            ProfileEditorSheet(store: store, prefills: occasion)
        }
        .confirmationDialog(
            "Wrapped Gift Photo",
            isPresented: $showHistoryPhotoMenu,
            titleVisibility: .visible
        ) {
            if CameraPickerRepresentable.isCameraAvailable {
                Button("Take Photo") { showHistoryCameraPicker = true }
            }
            Button("Choose Photo") { showHistoryLibraryPicker = true }
            Button("Cancel", role: .cancel) {
                historyPhotoTarget = nil
            }
        }
        .sheet(isPresented: $showHistoryLibraryPicker) {
            PhotoPickerRepresentable { image in
                applyHistoryPhoto(image)
            }
        }
        .fullScreenCover(isPresented: $showHistoryCameraPicker) {
            CameraPickerRepresentable(
                onCapture: { image in
                    applyHistoryPhoto(image)
                },
                onCancel: nil
            )
            .ignoresSafeArea()
        }
    }

    private func applyHistoryPhoto(_ image: UIImage) {
        guard let saved = PhotoDisk.saveJPEG(image), let target = historyPhotoTarget else {
            historyPhotoTarget = nil
            return
        }
        store.setWrappedPhoto(recordID: target.id, fileName: saved)
        historyPhotoTarget = nil
    }

    private var isCompletelyEmpty: Bool {
        store.giftProfiles.isEmpty && store.occasions.isEmpty && store.pastPurchases.isEmpty
    }

    private var headerRow: some View {
        HStack {
            Text("Wrap")
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundColor(Palette.text)
            Spacer()
            Menu {
                Button("Everyone") { personFilter = "" }
                ForEach(store.peopleNames, id: \.self) { name in
                    Button(name) { personFilter = name }
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "line.3.horizontal.decrease.circle.fill")
                    Text(personFilter.isEmpty ? "Everyone" : personFilter)
                        .lineLimit(1)
                }
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundColor(Palette.text)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    LinearGradient(
                        colors: [Palette.accent, Palette.primary],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    in: Capsule()
                )
                .shadow(color: Palette.primary.opacity(0.3), radius: 4, x: 0, y: 2)
            }
        }
        .padding(.horizontal, 18)
        .padding(.bottom, 8)
    }

    private var summaryList: some View {
        List {
            if plannedTotal > 0 || spentTotal > 0 {
                Section {
                    budgetRow
                        .listRowInsets(sectionInsets)
                        .listRowBackground(Palette.background.opacity(0))
                        .listRowSeparator(.hidden)
                }
            }

            if !alertOccasions.isEmpty {
                Section {
                    ForEach(alertOccasions) { occasion in
                        alertRow(occasion)
                            .listRowInsets(sectionInsets)
                            .listRowBackground(Palette.background.opacity(0))
                            .listRowSeparator(.hidden)
                    }
                } header: {
                    sectionTitle("Due Soon")
                }
            }

            Section {
                if upcomingItems.isEmpty {
                    mutedNote("Nothing upcoming for this filter.")
                } else {
                    ForEach(upcomingItems) { occasion in
                        upcomingRow(occasion)
                            .listRowInsets(sectionInsets)
                            .listRowBackground(Palette.background.opacity(0))
                            .listRowSeparator(.hidden)
                    }
                }
            } header: {
                sectionTitle("Upcoming")
            }

            Section {
                if ideaProfiles.isEmpty {
                    mutedNote("No open ideas for this filter.")
                } else {
                    ForEach(ideaProfiles) { profile in
                        ideaRow(profile)
                            .listRowInsets(sectionInsets)
                            .listRowBackground(Palette.background.opacity(0))
                            .listRowSeparator(.hidden)
                    }
                }
            } header: {
                sectionTitle("Ideas")
            }

            Section {
                if historyItems.isEmpty {
                    mutedNote("Purchases will land here.")
                } else {
                    ForEach(historyItems) { record in
                        historyRow(record)
                            .listRowInsets(sectionInsets)
                            .listRowBackground(Palette.background.opacity(0))
                            .listRowSeparator(.hidden)
                    }
                }
            } header: {
                sectionTitle("History")
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .scrollDismissesKeyboard(.immediately)
    }

    private var sectionInsets: EdgeInsets {
        EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16)
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 14, weight: .heavy, design: .rounded))
            .foregroundColor(Palette.text)
            .textCase(.none)
    }

    private func mutedNote(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .medium, design: .rounded))
            .foregroundColor(.white.opacity(0.86))
            .listRowBackground(Palette.background.opacity(0))
            .listRowSeparator(.hidden)
    }

    private var plannedTotal: Double {
        store.plannedBudgetTotal(matching: personFilter)
    }

    private var spentTotal: Double {
        store.spentBudgetTotal(matching: personFilter)
    }

    private var budgetRow: some View {
        GiftTagCard {
            VStack(alignment: .leading, spacing: 6) {
                Text("Season budget")
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundColor(Palette.text)
                Text("Planned \(GiftFormatters.money(plannedTotal)) · spent \(GiftFormatters.money(spentTotal))")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
            }
        }
    }

    private var filteredOccasions: [GiftOccasion] {
        store.occasions.filter { matches($0.contactName, type: $0.occasionType, extra: $0.notes) }
    }

    private var filteredProfiles: [GiftProfile] {
        store.giftProfiles.filter { profile in
            matches(
                profile.recipientName,
                type: profile.occasionType,
                extra: profile.giftIdeas
            )
        }
    }

    private var upcomingItems: [GiftOccasion] {
        filteredOccasions
            .filter { $0.date.isGiftUpcoming }
            .filter { occasion in
                if let linked = occasion.linkedProfileID, let profile = store.profile(id: linked) {
                    return !profile.isPurchased
                }
                return true
            }
            .sorted { $0.date < $1.date }
    }

    private var ideaProfiles: [GiftProfile] {
        filteredProfiles
            .filter { $0.hasGiftIdea && $0.pipelineStatus != .given }
            .filter { $0.pipelineStatus == .idea || $0.pipelineStatus == .ordered || !$0.isPurchased }
            .sorted { $0.occasionDate < $1.occasionDate }
    }

    private var historyItems: [PurchaseRecord] {
        store.pastPurchases
            .filter { record in
                let profile = store.profile(id: record.profileID)
                if let typeFilter {
                    if let profile, profile.occasionType != typeFilter { return false }
                    if profile == nil { return false }
                }
                if !matchesPerson(record.name) {
                    if let profile = profile, matchesPerson(profile.recipientName) {
                        return matchesQuery(record.name + " " + record.giftTitle)
                    }
                    return false
                }
                return matchesQuery(record.name + " " + record.giftTitle)
            }
            .sorted { $0.date > $1.date }
    }

    private var alertOccasions: [GiftOccasion] {
        filteredOccasions
            .filter { store.needsIdeaAlert(for: $0) }
            .sorted { $0.date < $1.date }
    }

    private func matchesPerson(_ name: String) -> Bool {
        if personFilter.isEmpty { return true }
        return name.giftTrimmed.lowercased() == personFilter.lowercased()
    }

    private func matchesQuery(_ text: String) -> Bool {
        let needle = query.giftTrimmed.lowercased()
        if needle.isEmpty { return true }
        return text.lowercased().contains(needle)
    }

    private func matches(_ name: String, type: OccasionType, extra: String) -> Bool {
        if let typeFilter, type != typeFilter { return false }
        if !matchesPerson(name) { return false }
        return matchesQuery(name + " " + extra)
    }

    private func alertRow(_ occasion: GiftOccasion) -> some View {
        GiftTagCard(alertStyle: true) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Needs an idea")
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                Text(occasion.contactName)
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                Text("\(occasion.occasionType.title) · \(GiftFormatters.day.string(from: occasion.date))")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                if !occasion.date.giftCountdownTitle.isEmpty {
                    Text(occasion.date.giftCountdownTitle)
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                }
                Button("Add Idea") { ideaPrefill = occasion }
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
            }
            .foregroundColor(Palette.text)
        }
    }

    private func upcomingRow(_ occasion: GiftOccasion) -> some View {
        let profile = occasion.linkedProfileID.flatMap { store.profile(id: $0) }
            ?? store.profileMatching(name: occasion.contactName)
        return GiftTagCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(occasion.contactName)
                        .font(.system(size: 17, weight: .heavy, design: .rounded))
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(GiftFormatters.shortDay.string(from: occasion.date))
                            .font(.system(size: 12, weight: .heavy, design: .rounded))
                        if !occasion.date.giftCountdownTitle.isEmpty {
                            Text(occasion.date.giftCountdownTitle)
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                        }
                    }
                }
                .foregroundColor(Palette.text)
                Text(occasion.occasionType.title)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.86))
                if let profile = profile {
                    GiftChip(title: profile.pipelineStatus.title)
                    if let planned = profile.plannedBudget {
                        Text("Budget \(GiftFormatters.money(planned)) · spent \(GiftFormatters.money(profile.spentTotal))")
                            .font(.system(size: 12, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                    }
                    if profile.hasGiftIdea {
                        Text(profile.giftIdeas)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.92))
                    }
                    if !profile.isPurchased {
                        Button("Mark Wrapped") {
                            store.markPurchased(profileID: profile.id)
                        }
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .foregroundColor(Palette.text)
                    }
                }
            }
        }
    }

    private func ideaRow(_ profile: GiftProfile) -> some View {
        let repeats = store.similarHistory(
            name: profile.recipientName,
            phrases: [profile.giftIdeas] + profile.checklist.map(\.title),
            excludingProfileID: profile.id
        )
        return GiftTagCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(profile.recipientName)
                        .font(.system(size: 17, weight: .heavy, design: .rounded))
                        .foregroundColor(Palette.text)
                    Spacer()
                    GiftChip(title: profile.pipelineStatus.title)
                }
                if !profile.occasionDate.giftCountdownTitle.isEmpty && !profile.isPurchased {
                    Text(profile.occasionDate.giftCountdownTitle)
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                }
                Text(profile.giftIdeas)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.92))
                if let first = repeats.first {
                    Text("Similar to \(first.giftTitle.isEmpty ? "a past gift" : first.giftTitle)")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                }
                HStack {
                    Text(profile.occasionType.title)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.82))
                    Spacer()
                    if profile.pipelineStatus.next != nil {
                        Button(profile.pipelineStatus.nextActionTitle) {
                            store.advancePipeline(profileID: profile.id)
                        }
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .foregroundColor(Palette.text)
                    }
                }
            }
        }
    }

    private func historyRow(_ record: PurchaseRecord) -> some View {
        GiftTagCard(showsRibbon: true) {
            HStack(alignment: .top, spacing: 10) {
                if record.wrappedPhotoFileName != nil {
                    DiskPhoto(fileName: record.wrappedPhotoFileName)
                        .frame(width: 52, height: 52)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text(record.name)
                        .font(.system(size: 17, weight: .heavy, design: .rounded))
                        .foregroundColor(Palette.text)
                    if !record.giftTitle.giftTrimmed.isEmpty {
                        Text(record.giftTitle)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    Text("Wrapped \(GiftFormatters.day.string(from: record.date))")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.82))
                    if let spent = record.spentAmount {
                        Text(GiftFormatters.money(spent))
                            .font(.system(size: 12, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                    }
                    Button(record.wrappedPhotoFileName == nil ? "Add photo" : "Change photo") {
                        historyPhotoTarget = record
                        showHistoryPhotoMenu = true
                    }
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundColor(Palette.text)
                }
            }
        }
    }
}
