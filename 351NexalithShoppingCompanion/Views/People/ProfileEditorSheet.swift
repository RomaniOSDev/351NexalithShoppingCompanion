import SwiftUI

struct ProfileEditorSheet: View {
    @ObservedObject var store: GiftStore
    var existing: GiftProfile?

    @Environment(\.dismiss) private var dismiss

    @State private var recipientName: String
    @State private var occasionDate: Date
    @State private var occasionType: OccasionType
    @State private var giftIdeas: String
    @State private var notes: String
    @State private var photoFileName: String?
    @State private var originalPhotoFileName: String?
    @State private var voiceNoteFileName: String?
    @State private var originalVoiceNoteFileName: String?
    @State private var plannedBudgetText: String
    @State private var clothingSize: String
    @State private var favoriteColors: String
    @State private var avoidList: String
    @State private var repeatsYearly: Bool
    @State private var pipelineStatus: GiftPipelineStatus
    @State private var checklist: [GiftChecklistItem]
    @State private var showLibraryPicker = false
    @State private var showCameraPicker = false
    @State private var validationMessage: String?
    @State private var cameraUnavailableMessage: String?

    init(store: GiftStore, existing: GiftProfile? = nil, prefills: GiftOccasion? = nil) {
        self.store = store
        self.existing = existing
        if let existing = existing {
            _recipientName = State(initialValue: existing.recipientName)
            _occasionDate = State(initialValue: existing.occasionDate)
            _occasionType = State(initialValue: existing.occasionType)
            _giftIdeas = State(initialValue: existing.giftIdeas)
            _notes = State(initialValue: existing.notes)
            _photoFileName = State(initialValue: existing.photoFileName)
            _originalPhotoFileName = State(initialValue: existing.photoFileName)
            _voiceNoteFileName = State(initialValue: existing.voiceNoteFileName)
            _originalVoiceNoteFileName = State(initialValue: existing.voiceNoteFileName)
            _plannedBudgetText = State(initialValue: existing.plannedBudget.map { String(format: "%g", $0) } ?? "")
            _clothingSize = State(initialValue: existing.clothingSize)
            _favoriteColors = State(initialValue: existing.favoriteColors)
            _avoidList = State(initialValue: existing.avoidList)
            _repeatsYearly = State(initialValue: existing.repeatsYearly)
            _pipelineStatus = State(initialValue: existing.pipelineStatus)
            _checklist = State(initialValue: existing.checklist)
        } else if let prefills = prefills {
            _recipientName = State(initialValue: prefills.contactName)
            _occasionDate = State(initialValue: prefills.date)
            _occasionType = State(initialValue: prefills.occasionType)
            _giftIdeas = State(initialValue: "")
            _notes = State(initialValue: prefills.notes)
            _photoFileName = State(initialValue: nil)
            _originalPhotoFileName = State(initialValue: nil)
            _voiceNoteFileName = State(initialValue: nil)
            _originalVoiceNoteFileName = State(initialValue: nil)
            _plannedBudgetText = State(initialValue: prefills.plannedBudget.map { String(format: "%g", $0) } ?? "")
            _clothingSize = State(initialValue: "")
            _favoriteColors = State(initialValue: "")
            _avoidList = State(initialValue: "")
            _repeatsYearly = State(initialValue: prefills.repeatsYearly)
            _pipelineStatus = State(initialValue: .idea)
            _checklist = State(initialValue: [])
        } else {
            _recipientName = State(initialValue: "")
            _occasionDate = State(initialValue: Date())
            _occasionType = State(initialValue: .birthday)
            _giftIdeas = State(initialValue: "")
            _notes = State(initialValue: "")
            _photoFileName = State(initialValue: nil)
            _originalPhotoFileName = State(initialValue: nil)
            _voiceNoteFileName = State(initialValue: nil)
            _originalVoiceNoteFileName = State(initialValue: nil)
            _plannedBudgetText = State(initialValue: "")
            _clothingSize = State(initialValue: "")
            _favoriteColors = State(initialValue: "")
            _avoidList = State(initialValue: "")
            _repeatsYearly = State(initialValue: true)
            _pipelineStatus = State(initialValue: .idea)
            _checklist = State(initialValue: [])
        }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    photoBlock
                    VoiceNoteControlView(fileName: $voiceNoteFileName)
                    labeledField("Recipient") {
                        GiftLineField(placeholder: "Who is this for?", text: $recipientName)
                    }
                    labeledField("Occasion") {
                        Picker("Occasion", selection: $occasionType) {
                            ForEach(OccasionType.allCases) { type in
                                Text(type.title).tag(type)
                            }
                        }
                        .pickerStyle(.segmented)
                        .tint(Palette.primary)
                    }
                    labeledField("Date") {
                        DatePicker(
                            "Date",
                            selection: $occasionDate,
                            displayedComponents: .date
                        )
                        .labelsHidden()
                        .tint(Palette.primary)
                        .colorScheme(.dark)
                    }
                    labeledField("Yearly repeat") {
                        GiftToggleRow(title: "Roll this date forward each year", isOn: $repeatsYearly)
                    }
                    labeledField("Budget") {
                        GiftLineField(
                            placeholder: "Planned amount",
                            text: $plannedBudgetText,
                            capitalization: .never,
                            keyboardType: .decimalPad
                        )
                    }
                    labeledField("Gift ideas") {
                        GiftNoteEditor(
                            placeholder: "What could they love?",
                            text: $giftIdeas,
                            minHeight: 88
                        )
                    }
                    checklistBlock
                    labeledField("Size") {
                        GiftLineField(placeholder: "Shirt, shoes, ring…", text: $clothingSize)
                    }
                    labeledField("Favorite colors") {
                        GiftLineField(placeholder: "Navy, cream, no orange", text: $favoriteColors)
                    }
                    labeledField("Don't buy") {
                        GiftNoteEditor(
                            placeholder: "Scents, brands, or repeats to skip",
                            text: $avoidList,
                            minHeight: 56,
                            textColor: .white.opacity(0.92)
                        )
                    }
                    labeledField("Notes") {
                        GiftNoteEditor(
                            placeholder: "Stores, reminders, wrapping notes",
                            text: $notes,
                            minHeight: 64,
                            textColor: .white.opacity(0.92)
                        )
                    }
                    if let warning = repeatWarning {
                        Text(warning)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    if let validationMessage = validationMessage {
                        Text(validationMessage)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(Palette.text)
                    }
                    if let cameraUnavailableMessage = cameraUnavailableMessage {
                        Text(cameraUnavailableMessage)
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
            .navigationTitle(existing == nil ? "New Profile" : "Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Palette.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { cancel() }
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
        .sheet(isPresented: $showLibraryPicker) {
            PhotoPickerRepresentable { image in
                applyCapturedPhoto(image)
            }
        }
        .fullScreenCover(isPresented: $showCameraPicker) {
            CameraPickerRepresentable(
                onCapture: { image in
                    applyCapturedPhoto(image)
                },
                onCancel: nil
            )
            .ignoresSafeArea()
        }
    }

    private var repeatWarning: String? {
        let phrases = [giftIdeas] + checklist.map(\.title)
        let matches = store.similarHistory(
            name: recipientName,
            phrases: phrases,
            excludingProfileID: existing?.id
        )
        guard let first = matches.first else { return nil }
        let title = first.giftTitle.isEmpty ? "a similar gift" : first.giftTitle
        return "You already wrapped \(title) for this person on \(GiftFormatters.day.string(from: first.date))."
    }

    private var photoBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            GiftFieldLabel(title: "Snapshot")
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Palette.surface)
                    if photoFileName != nil {
                        DiskPhoto(fileName: photoFileName)
                            .frame(width: 76, height: 76)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    } else {
                        Image(systemName: "camera.fill")
                            .foregroundColor(Palette.text.opacity(0.9))
                    }
                }
                .frame(width: 76, height: 76)
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Palette.primary.opacity(0.5), lineWidth: 1.4)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Button("Take Photo") {
                        if CameraPickerRepresentable.isCameraAvailable {
                            showCameraPicker = true
                        } else {
                            cameraUnavailableMessage = "Camera is not available on this device."
                            showLibraryPicker = true
                        }
                    }
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundColor(Palette.text)

                    Button("Choose Photo") { showLibraryPicker = true }
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .foregroundColor(Palette.text)

                    if photoFileName != nil {
                        Button("Remove Photo") {
                            if let current = photoFileName, current != originalPhotoFileName {
                                PhotoDisk.delete(current)
                            }
                            photoFileName = nil
                        }
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(Palette.text.opacity(0.9))
                    }
                }
            }
        }
    }

    private func applyCapturedPhoto(_ image: UIImage) {
        if let saved = PhotoDisk.saveJPEG(image) {
            if let current = photoFileName, current != originalPhotoFileName {
                PhotoDisk.delete(current)
            }
            photoFileName = saved
            cameraUnavailableMessage = nil
        }
    }

    private var checklistBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                GiftFieldLabel(title: "Shopping list")
                Spacer()
                Button("Add item") {
                    checklist.append(
                        GiftChecklistItem(id: UUID(), title: "", store: "", price: nil, isBought: false)
                    )
                }
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundColor(Palette.text)
            }
            if checklist.isEmpty {
                Text("Split the idea into store, price, and bought checkboxes.")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
            }
            ForEach($checklist) { $item in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        GiftLineField(placeholder: "Item", text: $item.title)
                        Button {
                            checklist.removeAll { $0.id == item.id }
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(Palette.text)
                        }
                        .buttonStyle(.plain)
                    }
                    GiftLineField(placeholder: "Store", text: $item.store, capitalization: .words)
                    HStack {
                        GiftLineField(
                            placeholder: "Price",
                            text: Binding(
                                get: { item.price.map { String(format: "%g", $0) } ?? "" },
                                set: { item.price = $0.giftMoney }
                            ),
                            capitalization: .never,
                            keyboardType: .decimalPad
                        )
                        Toggle("Bought", isOn: $item.isBought)
                            .font(.system(size: 12, weight: .heavy, design: .rounded))
                            .tint(Palette.primary)
                    }
                }
                .padding(10)
                .background(Palette.surface.opacity(0.92), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Palette.accent.opacity(0.45), lineWidth: 1)
                }
            }
        }
    }

    private func labeledField<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
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
        let profile = GiftProfile(
            id: existing?.id ?? UUID(),
            recipientName: recipientName,
            occasionDate: occasionDate,
            occasionType: occasionType,
            giftIdeas: giftIdeas,
            photoFileName: photoFileName,
            voiceNoteFileName: voiceNoteFileName,
            purchasedAt: existing?.purchasedAt,
            notes: notes,
            plannedBudget: plannedBudgetText.giftMoney,
            clothingSize: clothingSize,
            favoriteColors: favoriteColors,
            avoidList: avoidList,
            pipelineStatus: pipelineStatus,
            checklist: checklist,
            repeatsYearly: repeatsYearly
        )
        if let message = store.upsertProfile(profile) {
            validationMessage = message
            return
        }
        if let original = originalPhotoFileName, original != photoFileName {
            PhotoDisk.delete(original)
        }
        if let originalVoice = originalVoiceNoteFileName, originalVoice != voiceNoteFileName {
            VoiceNoteDisk.delete(originalVoice)
        }
        dismiss()
    }

    private func cancel() {
        if let current = photoFileName, current != originalPhotoFileName {
            PhotoDisk.delete(current)
        }
        if let currentVoice = voiceNoteFileName, currentVoice != originalVoiceNoteFileName {
            VoiceNoteDisk.delete(currentVoice)
        }
        dismiss()
    }
}
