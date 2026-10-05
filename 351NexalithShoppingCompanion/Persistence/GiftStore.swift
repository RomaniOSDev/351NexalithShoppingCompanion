import Combine
import Foundation

@MainActor
final class GiftStore: ObservableObject {
    @Published var giftProfiles: [GiftProfile] = []
    @Published var occasions: [GiftOccasion] = []
    @Published var pastPurchases: [PurchaseRecord] = []
    @Published var lastViewedProfileID: UUID?
    @Published var lastSyncDate: Date = Date()
    @Published var notificationsEnabled: Bool = false

    private static let storageKey = "GiftStore.snapshot"
    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let calendar = Calendar.current

    private struct Snapshot: Codable {
        var giftProfiles: [GiftProfile]
        var occasions: [GiftOccasion]
        var pastPurchases: [PurchaseRecord]
        var lastViewedProfileID: UUID?
        var lastSyncDate: Date
        var notificationsEnabled: Bool
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        load()
        if !rollRepeatingDatesIfNeeded() {
            GiftReminders.sync(occasions: occasions, enabled: notificationsEnabled)
        }
    }

    var dueSoonCount: Int {
        guard notificationsEnabled else { return 0 }
        return occasions.filter { $0.date.isGiftDue(withinDays: 14) }.count
    }

    var peopleNames: [String] {
        var seen = Set<String>()
        var names: [String] = []
        let raw = giftProfiles.map { $0.trimmedName } + occasions.map { $0.trimmedName }
        for name in raw {
            let key = name.lowercased()
            if name.isEmpty || seen.contains(key) { continue }
            seen.insert(key)
            names.append(name)
        }
        return names.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    func plannedBudgetTotal(matching name: String = "") -> Double {
        giftProfiles
            .filter { matchesPerson($0.recipientName, filter: name) }
            .compactMap(\.plannedBudget)
            .reduce(0, +)
    }

    func spentBudgetTotal(matching name: String = "") -> Double {
        let fromOpen = giftProfiles
            .filter { matchesPerson($0.recipientName, filter: name) && !$0.isPurchased }
            .map(\.spentTotal)
            .reduce(0, +)
        let fromHistory = pastPurchases
            .filter { record in
                if matchesPerson(record.name, filter: name) { return true }
                if let profile = profile(id: record.profileID) {
                    return matchesPerson(profile.recipientName, filter: name)
                }
                return name.giftTrimmed.isEmpty
            }
            .compactMap(\.spentAmount)
            .reduce(0, +)
        return fromOpen + fromHistory
    }

    func upcomingOccasions() -> [GiftOccasion] {
        occasions
            .filter { $0.date.isGiftUpcoming }
            .sorted { $0.date < $1.date }
    }

    func pastOccasions() -> [GiftOccasion] {
        occasions
            .filter { !$0.date.isGiftUpcoming }
            .sorted { $0.date > $1.date }
    }

    func profile(id: UUID) -> GiftProfile? {
        giftProfiles.first { $0.id == id }
    }

    func profileMatching(name: String) -> GiftProfile? {
        let key = name.giftTrimmed.lowercased()
        return giftProfiles.first { $0.trimmedName.lowercased() == key }
    }

    func hasGiftIdea(for occasion: GiftOccasion) -> Bool {
        if let linked = occasion.linkedProfileID, let profile = profile(id: linked) {
            return profile.hasGiftIdea
        }
        if let profile = profileMatching(name: occasion.contactName) {
            return profile.hasGiftIdea
        }
        return false
    }

    func needsIdeaAlert(for occasion: GiftOccasion) -> Bool {
        occasion.date.isGiftDue(withinDays: 14) && !hasGiftIdea(for: occasion)
    }

    func similarHistory(name: String, phrases: [String], excludingProfileID: UUID? = nil) -> [PurchaseRecord] {
        let keys = phrases.map(\.giftNormalized).filter { !$0.isEmpty }
        guard !keys.isEmpty else { return [] }
        let person = name.giftTrimmed.lowercased()
        return pastPurchases.filter { record in
            if record.name.giftTrimmed.lowercased() != person { return false }
            if let excludingProfileID, record.profileID == excludingProfileID,
               calendar.isDate(record.date, inSameDayAs: Date()) {
                return false
            }
            let haystack = (record.giftTitle.isEmpty ? record.name : record.giftTitle)
            return keys.contains { haystack.giftSimilar(to: $0) }
        }
    }

    func upsertProfile(_ profile: GiftProfile) -> String? {
        let name = profile.trimmedName
        if name.isEmpty {
            return "A recipient name is required."
        }
        if !profile.hasGiftIdea {
            return "Add at least one gift idea before saving."
        }
        var stored = profile
        stored.recipientName = name
        stored.giftIdeas = profile.trimmedIdeas
        stored.notes = profile.notes.giftTrimmed
        stored.clothingSize = profile.clothingSize.giftTrimmed
        stored.favoriteColors = profile.favoriteColors.giftTrimmed
        stored.avoidList = profile.avoidList.giftTrimmed
        stored.checklist = profile.checklist
            .map { item in
                var copy = item
                copy.title = item.title.giftTrimmed
                copy.store = item.store.giftTrimmed
                return copy
            }
            .filter { !$0.title.isEmpty }

        if let index = giftProfiles.firstIndex(where: { $0.id == stored.id }) {
            giftProfiles[index] = stored
        } else {
            giftProfiles.append(stored)
        }
        lastViewedProfileID = stored.id
        syncOccasion(from: stored)
        persist()
        return nil
    }

    func deleteProfile(_ profile: GiftProfile) {
        if let fileName = profile.photoFileName {
            PhotoDisk.delete(fileName)
        }
        if let voice = profile.voiceNoteFileName {
            VoiceNoteDisk.delete(voice)
        }
        giftProfiles.removeAll { $0.id == profile.id }
        occasions.removeAll { $0.linkedProfileID == profile.id }
        if lastViewedProfileID == profile.id {
            lastViewedProfileID = giftProfiles.first?.id
        }
        persist()
    }

    func upsertOccasion(_ occasion: GiftOccasion) -> String? {
        let name = occasion.trimmedName
        if name.isEmpty {
            return "A contact name is required."
        }
        var stored = occasion
        stored.contactName = name
        stored.notes = occasion.notes.giftTrimmed
        if isDuplicate(stored) {
            return "That contact already has this occasion on the same day."
        }
        if let index = occasions.firstIndex(where: { $0.id == stored.id }) {
            occasions[index] = stored
        } else {
            occasions.append(stored)
        }
        if let profileID = stored.linkedProfileID,
           let profileIndex = giftProfiles.firstIndex(where: { $0.id == profileID }) {
            giftProfiles[profileIndex].recipientName = stored.contactName
            giftProfiles[profileIndex].occasionType = stored.occasionType
            giftProfiles[profileIndex].occasionDate = stored.date
            giftProfiles[profileIndex].notes = stored.notes
            giftProfiles[profileIndex].repeatsYearly = stored.repeatsYearly
            if let budget = stored.plannedBudget {
                giftProfiles[profileIndex].plannedBudget = budget
            }
        }
        persist()
        return nil
    }

    func deleteOccasion(_ occasion: GiftOccasion) {
        occasions.removeAll { $0.id == occasion.id }
        persist()
    }

    func advancePipeline(profileID: UUID) {
        guard let index = giftProfiles.firstIndex(where: { $0.id == profileID }) else { return }
        guard let next = giftProfiles[index].pipelineStatus.next else { return }
        setPipeline(profileID: profileID, status: next)
    }

    func setPipeline(profileID: UUID, status: GiftPipelineStatus) {
        guard let index = giftProfiles.firstIndex(where: { $0.id == profileID }) else { return }
        if status == .wrapped || status == .given {
            recordPurchaseIfNeeded(at: index)
        }
        giftProfiles[index].pipelineStatus = status
        persist()
    }

    func markPurchased(profileID: UUID) {
        setPipeline(profileID: profileID, status: .wrapped)
    }

    func toggleChecklistItem(profileID: UUID, itemID: UUID) {
        guard let index = giftProfiles.firstIndex(where: { $0.id == profileID }) else { return }
        guard let itemIndex = giftProfiles[index].checklist.firstIndex(where: { $0.id == itemID }) else { return }
        giftProfiles[index].checklist[itemIndex].isBought.toggle()
        persist()
    }

    func setWrappedPhoto(recordID: UUID, fileName: String?) {
        guard let index = pastPurchases.firstIndex(where: { $0.id == recordID }) else { return }
        if let previous = pastPurchases[index].wrappedPhotoFileName, previous != fileName {
            PhotoDisk.delete(previous)
        }
        pastPurchases[index].wrappedPhotoFileName = fileName
        persist()
    }

    func rememberViewedProfile(_ id: UUID) {
        lastViewedProfileID = id
        persist()
    }

    func setNotificationsEnabled(_ enabled: Bool) {
        notificationsEnabled = enabled
        persist()
        if enabled {
            GiftReminders.requestAccessThenSync(occasions: occasions)
        } else {
            GiftReminders.sync(occasions: occasions, enabled: false)
        }
    }

    func resetAll() {
        let photos = giftProfiles.compactMap { $0.photoFileName }
            + pastPurchases.compactMap { $0.wrappedPhotoFileName }
        for fileName in photos {
            PhotoDisk.delete(fileName)
        }
        for voice in giftProfiles.compactMap(\.voiceNoteFileName) {
            VoiceNoteDisk.delete(voice)
        }
        PhotoDisk.deleteAllJPEGs()
        VoiceNoteDisk.deleteAll()
        giftProfiles = []
        occasions = []
        pastPurchases = []
        lastViewedProfileID = nil
        notificationsEnabled = false
        persist()
        NotificationCenter.default.post(name: Notification.Name("dataReset"), object: nil)
    }

    @discardableResult
    func rollRepeatingDatesIfNeeded() -> Bool {
        var changed = false
        for index in giftProfiles.indices {
            guard giftProfiles[index].repeatsYearly else { continue }
            let rolled = giftProfiles[index].occasionDate.giftRolledForward()
            if rolled != giftProfiles[index].occasionDate.giftStartOfDay {
                giftProfiles[index].occasionDate = rolled
                giftProfiles[index].purchasedAt = nil
                giftProfiles[index].pipelineStatus = .idea
                for itemIndex in giftProfiles[index].checklist.indices {
                    giftProfiles[index].checklist[itemIndex].isBought = false
                }
                syncOccasion(from: giftProfiles[index])
                changed = true
            }
        }
        for index in occasions.indices {
            guard occasions[index].repeatsYearly else { continue }
            let rolled = occasions[index].date.giftRolledForward()
            if rolled != occasions[index].date.giftStartOfDay {
                occasions[index].date = rolled
                changed = true
            }
        }
        if changed {
            persist()
        }
        return changed
    }

    private func recordPurchaseIfNeeded(at index: Int) {
        if giftProfiles[index].purchasedAt != nil { return }
        let now = Date()
        giftProfiles[index].purchasedAt = now
        let profile = giftProfiles[index]
        let titles = [profile.trimmedIdeas] + profile.checklist.map(\.trimmedTitle)
        let record = PurchaseRecord(
            id: UUID(),
            name: profile.recipientName,
            date: now,
            profileID: profile.id,
            giftTitle: titles.filter { !$0.isEmpty }.joined(separator: " · "),
            wrappedPhotoFileName: nil,
            spentAmount: profile.spentTotal > 0 ? profile.spentTotal : nil
        )
        pastPurchases.insert(record, at: 0)
    }

    private func matchesPerson(_ name: String, filter: String) -> Bool {
        if filter.giftTrimmed.isEmpty { return true }
        return name.giftTrimmed.lowercased() == filter.giftTrimmed.lowercased()
    }

    private func isDuplicate(_ occasion: GiftOccasion) -> Bool {
        occasions.contains { other in
            other.id != occasion.id
                && other.trimmedName.lowercased() == occasion.trimmedName.lowercased()
                && other.occasionType == occasion.occasionType
                && calendar.isDate(other.date, inSameDayAs: occasion.date)
        }
    }

    private func syncOccasion(from profile: GiftProfile) {
        if let index = occasions.firstIndex(where: { $0.linkedProfileID == profile.id }) {
            occasions[index].contactName = profile.recipientName
            occasions[index].occasionType = profile.occasionType
            occasions[index].date = profile.occasionDate
            occasions[index].notes = profile.notes
            occasions[index].repeatsYearly = profile.repeatsYearly
            occasions[index].plannedBudget = profile.plannedBudget
            return
        }
        if let index = occasions.firstIndex(where: { other in
            other.linkedProfileID == nil
                && other.trimmedName.lowercased() == profile.trimmedName.lowercased()
                && other.occasionType == profile.occasionType
                && calendar.isDate(other.date, inSameDayAs: profile.occasionDate)
        }) {
            occasions[index].linkedProfileID = profile.id
            occasions[index].contactName = profile.recipientName
            occasions[index].occasionType = profile.occasionType
            occasions[index].date = profile.occasionDate
            occasions[index].notes = profile.notes
            occasions[index].repeatsYearly = profile.repeatsYearly
            occasions[index].plannedBudget = profile.plannedBudget
            return
        }
        let occasion = GiftOccasion(
            id: UUID(),
            contactName: profile.recipientName,
            occasionType: profile.occasionType,
            date: profile.occasionDate,
            notes: profile.notes,
            linkedProfileID: profile.id,
            plannedBudget: profile.plannedBudget,
            repeatsYearly: profile.repeatsYearly
        )
        occasions.append(occasion)
    }

    private func load() {
        guard let data = defaults.data(forKey: Self.storageKey) else { return }
        guard let snapshot = try? decoder.decode(Snapshot.self, from: data) else { return }
        giftProfiles = snapshot.giftProfiles
        occasions = snapshot.occasions
        pastPurchases = snapshot.pastPurchases
        lastViewedProfileID = snapshot.lastViewedProfileID
        lastSyncDate = snapshot.lastSyncDate
        notificationsEnabled = snapshot.notificationsEnabled
    }

    private func persist() {
        lastSyncDate = Date()
        let snapshot = Snapshot(
            giftProfiles: giftProfiles,
            occasions: occasions,
            pastPurchases: pastPurchases,
            lastViewedProfileID: lastViewedProfileID,
            lastSyncDate: lastSyncDate,
            notificationsEnabled: notificationsEnabled
        )
        if let data = try? encoder.encode(snapshot) {
            defaults.set(data, forKey: Self.storageKey)
        }
        GiftReminders.sync(occasions: occasions, enabled: notificationsEnabled)
    }
}
