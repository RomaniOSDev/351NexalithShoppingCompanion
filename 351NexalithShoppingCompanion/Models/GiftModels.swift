import Foundation
import SwiftUI

enum OccasionType: String, Codable, CaseIterable, Identifiable, Hashable {
    case birthday
    case anniversary
    case holiday
    case thanks

    var id: String { rawValue }

    var title: String {
        switch self {
        case .birthday: return "Birthday"
        case .anniversary: return "Anniversary"
        case .holiday: return "Holiday"
        case .thanks: return "Thanks"
        }
    }

    var symbolName: String {
        switch self {
        case .birthday: return "gift.fill"
        case .anniversary: return "heart.fill"
        case .holiday: return "snowflake"
        case .thanks: return "hand.thumbsup.fill"
        }
    }

    var repeatsByDefault: Bool {
        self == .birthday || self == .anniversary
    }
}

enum GiftPipelineStatus: String, Codable, CaseIterable, Identifiable, Hashable {
    case idea
    case ordered
    case wrapped
    case given

    var id: String { rawValue }

    var title: String {
        switch self {
        case .idea: return "Idea"
        case .ordered: return "Ordered"
        case .wrapped: return "Wrapped"
        case .given: return "Given"
        }
    }

    var next: GiftPipelineStatus? {
        switch self {
        case .idea: return .ordered
        case .ordered: return .wrapped
        case .wrapped: return .given
        case .given: return nil
        }
    }

    var nextActionTitle: String {
        switch next {
        case .ordered: return "Mark Ordered"
        case .wrapped: return "Mark Wrapped"
        case .given: return "Mark Given"
        case .idea, .none: return ""
        }
    }
}

struct GiftChecklistItem: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    var title: String
    var store: String
    var price: Double?
    var isBought: Bool

    var trimmedTitle: String { title.giftTrimmed }
}

struct GiftProfile: Identifiable, Equatable, Hashable {
    var id: UUID
    var recipientName: String
    var occasionDate: Date
    var occasionType: OccasionType
    var giftIdeas: String
    var photoFileName: String?
    var voiceNoteFileName: String?
    var purchasedAt: Date?
    var notes: String
    var plannedBudget: Double?
    var clothingSize: String
    var favoriteColors: String
    var avoidList: String
    var pipelineStatus: GiftPipelineStatus
    var checklist: [GiftChecklistItem]
    var repeatsYearly: Bool

    var isPurchased: Bool { purchasedAt != nil }

    var trimmedName: String {
        recipientName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var trimmedIdeas: String {
        giftIdeas.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var hasGiftIdea: Bool {
        !trimmedIdeas.isEmpty || checklist.contains { !$0.trimmedTitle.isEmpty }
    }

    var spentTotal: Double {
        checklist.filter(\.isBought).compactMap(\.price).reduce(0, +)
    }

    var hasTasteNotes: Bool {
        !clothingSize.giftTrimmed.isEmpty
            || !favoriteColors.giftTrimmed.isEmpty
            || !avoidList.giftTrimmed.isEmpty
    }
}

struct GiftOccasion: Identifiable, Equatable, Hashable {
    var id: UUID
    var contactName: String
    var occasionType: OccasionType
    var date: Date
    var notes: String
    var linkedProfileID: UUID?
    var plannedBudget: Double?
    var repeatsYearly: Bool

    var trimmedName: String {
        contactName.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

struct PurchaseRecord: Identifiable, Equatable, Hashable {
    var id: UUID
    var name: String
    var date: Date
    var profileID: UUID
    var giftTitle: String
    var wrappedPhotoFileName: String?
    var spentAmount: Double?
}

enum GiftFormatters {
    static let day: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    static let shortDay: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()

    static let month: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter
    }()

    static let monthKey: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return formatter
    }()

    static let currency: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    static func money(_ value: Double) -> String {
        currency.string(from: NSNumber(value: value)) ?? String(format: "%.2f", value)
    }
}

extension Date {
    var giftStartOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    var isGiftUpcoming: Bool {
        giftStartOfDay >= Date().giftStartOfDay
    }

    var giftDaysUntil: Int {
        Calendar.current.dateComponents([.day], from: Date().giftStartOfDay, to: giftStartOfDay).day ?? 0
    }

    var giftCountdownTitle: String {
        switch giftDaysUntil {
        case 0: return "Today"
        case 1: return "Tomorrow"
        case let days where days > 1: return "in \(days) days"
        default: return ""
        }
    }

    func isGiftDue(withinDays days: Int) -> Bool {
        let start = Date().giftStartOfDay
        guard let end = Calendar.current.date(byAdding: .day, value: days, to: start) else {
            return false
        }
        let day = giftStartOfDay
        return day >= start && day <= end
    }

    func giftRolledForward() -> Date {
        let calendar = Calendar.current
        var date = giftStartOfDay
        let today = Date().giftStartOfDay
        while date < today {
            guard let next = calendar.date(byAdding: .year, value: 1, to: date) else { break }
            if next <= date { break }
            date = next
        }
        return date
    }
}

extension String {
    var giftTrimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var giftNormalized: String {
        giftTrimmed.lowercased().filter { $0.isLetter || $0.isNumber || $0.isWhitespace }
            .replacingOccurrences(of: "  ", with: " ")
    }

    var giftMoney: Double? {
        let cleaned = replacingOccurrences(of: ",", with: ".")
            .filter { $0.isNumber || $0 == "." }
        if cleaned.isEmpty { return nil }
        return Double(cleaned)
    }

    func giftSimilar(to other: String) -> Bool {
        let left = giftNormalized
        let right = other.giftNormalized
        if left.isEmpty || right.isEmpty { return false }
        if left == right { return true }
        if left.contains(right) || right.contains(left) { return true }
        let leftTokens = Set(left.split(separator: " ").map(String.init).filter { $0.count >= 4 })
        let rightTokens = Set(right.split(separator: " ").map(String.init).filter { $0.count >= 4 })
        return !leftTokens.isDisjoint(with: rightTokens)
    }
}

extension GiftProfile: Codable {
    enum CodingKeys: String, CodingKey {
        case id, recipientName, occasionDate, occasionType, giftIdeas
        case photoFileName, voiceNoteFileName, purchasedAt, notes, plannedBudget
        case clothingSize, favoriteColors, avoidList, pipelineStatus
        case checklist, repeatsYearly
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        recipientName = try container.decode(String.self, forKey: .recipientName)
        occasionDate = try container.decode(Date.self, forKey: .occasionDate)
        occasionType = try container.decode(OccasionType.self, forKey: .occasionType)
        giftIdeas = try container.decode(String.self, forKey: .giftIdeas)
        photoFileName = try container.decodeIfPresent(String.self, forKey: .photoFileName)
        voiceNoteFileName = try container.decodeIfPresent(String.self, forKey: .voiceNoteFileName)
        purchasedAt = try container.decodeIfPresent(Date.self, forKey: .purchasedAt)
        notes = try container.decodeIfPresent(String.self, forKey: .notes) ?? ""
        plannedBudget = try container.decodeIfPresent(Double.self, forKey: .plannedBudget)
        clothingSize = try container.decodeIfPresent(String.self, forKey: .clothingSize) ?? ""
        favoriteColors = try container.decodeIfPresent(String.self, forKey: .favoriteColors) ?? ""
        avoidList = try container.decodeIfPresent(String.self, forKey: .avoidList) ?? ""
        checklist = try container.decodeIfPresent([GiftChecklistItem].self, forKey: .checklist) ?? []
        if let status = try container.decodeIfPresent(GiftPipelineStatus.self, forKey: .pipelineStatus) {
            pipelineStatus = status
        } else {
            pipelineStatus = purchasedAt == nil ? .idea : .wrapped
        }
        repeatsYearly = try container.decodeIfPresent(Bool.self, forKey: .repeatsYearly) ?? occasionType.repeatsByDefault
    }
}

extension GiftOccasion: Codable {
    enum CodingKeys: String, CodingKey {
        case id, contactName, occasionType, date, notes, linkedProfileID, plannedBudget, repeatsYearly
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        contactName = try container.decode(String.self, forKey: .contactName)
        occasionType = try container.decode(OccasionType.self, forKey: .occasionType)
        date = try container.decode(Date.self, forKey: .date)
        notes = try container.decodeIfPresent(String.self, forKey: .notes) ?? ""
        linkedProfileID = try container.decodeIfPresent(UUID.self, forKey: .linkedProfileID)
        plannedBudget = try container.decodeIfPresent(Double.self, forKey: .plannedBudget)
        repeatsYearly = try container.decodeIfPresent(Bool.self, forKey: .repeatsYearly) ?? occasionType.repeatsByDefault
    }
}

extension PurchaseRecord: Codable {
    enum CodingKeys: String, CodingKey {
        case id, name, date, profileID, giftTitle, wrappedPhotoFileName, spentAmount
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        date = try container.decode(Date.self, forKey: .date)
        profileID = try container.decode(UUID.self, forKey: .profileID)
        giftTitle = try container.decodeIfPresent(String.self, forKey: .giftTitle) ?? ""
        wrappedPhotoFileName = try container.decodeIfPresent(String.self, forKey: .wrappedPhotoFileName)
        spentAmount = try container.decodeIfPresent(Double.self, forKey: .spentAmount)
    }
}
