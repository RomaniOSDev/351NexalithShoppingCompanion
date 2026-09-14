import SwiftUI

struct OccasionEditorSheet: View {
    @ObservedObject var store: GiftStore
    var existing: GiftOccasion?

    @Environment(\.dismiss) private var dismiss
    @State private var contactName: String
    @State private var occasionType: OccasionType
    @State private var date: Date
    @State private var notes: String
    @State private var plannedBudgetText: String
    @State private var repeatsYearly: Bool
    @State private var validationMessage: String?

    init(store: GiftStore, existing: GiftOccasion? = nil) {
        self.store = store
        self.existing = existing
        _contactName = State(initialValue: existing?.contactName ?? "")
        _occasionType = State(initialValue: existing?.occasionType ?? .birthday)
        _date = State(initialValue: existing?.date ?? Date())
        _notes = State(initialValue: existing?.notes ?? "")
        _plannedBudgetText = State(initialValue: existing?.plannedBudget.map { String(format: "%g", $0) } ?? "")
        _repeatsYearly = State(initialValue: existing?.repeatsYearly ?? OccasionType.birthday.repeatsByDefault)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    field("Contact") {
                        GiftLineField(placeholder: "Name", text: $contactName)
                    }
                    field("Occasion") {
                        Picker("Occasion", selection: $occasionType) {
                            ForEach(OccasionType.allCases) { type in
                                Text(type.title).tag(type)
                            }
                        }
                        .pickerStyle(.segmented)
                        .tint(Palette.primary)
                    }
                    field("Date") {
                        DatePicker("Date", selection: $date, displayedComponents: .date)
                            .labelsHidden()
                            .tint(Palette.primary)
                            .colorScheme(.dark)
                    }
                    field("Yearly repeat") {
                        GiftToggleRow(title: "Roll this date forward each year", isOn: $repeatsYearly)
                    }
                    field("Budget") {
                        GiftLineField(
                            placeholder: "Optional planned amount",
                            text: $plannedBudgetText,
                            capitalization: .never,
                            keyboardType: .decimalPad
                        )
                    }
                    field("Notes") {
                        GiftNoteEditor(
                            placeholder: "Optional note",
                            text: $notes,
                            minHeight: 80,
                            textColor: .white.opacity(0.92)
                        )
                    }
                    if let validationMessage = validationMessage {
                        Text(validationMessage)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(Palette.text)
                    }
                }
                .padding(18)
            }
            .studioBackdrop()
            .scrollDismissesKeyboard(.immediately)
            .dismissKeyboardOnTap()
            .preferredColorScheme(.dark)
            .navigationTitle(existing == nil ? "New Date" : "Edit Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Palette.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.white.opacity(0.9))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                        .foregroundColor(Palette.text)
                }
            }
            .onChange(of: occasionType) { type in
                if existing == nil {
                    repeatsYearly = type.repeatsByDefault
                }
            }
        }
        .navigationViewStyle(.stack)
    }

    private func field<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            GiftFieldLabel(title: title)
            content()
                .padding(10)
                .background(Palette.surface.opacity(0.92), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Palette.accent.opacity(0.45), lineWidth: 1)
                }
                .foregroundColor(.white)
        }
    }

    private func save() {
        let occasion = GiftOccasion(
            id: existing?.id ?? UUID(),
            contactName: contactName,
            occasionType: occasionType,
            date: date,
            notes: notes,
            linkedProfileID: existing?.linkedProfileID,
            plannedBudget: plannedBudgetText.giftMoney,
            repeatsYearly: repeatsYearly
        )
        if let message = store.upsertOccasion(occasion) {
            validationMessage = message
            return
        }
        dismiss()
    }
}
