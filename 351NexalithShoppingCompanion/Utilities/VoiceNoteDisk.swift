import AVFoundation
import Combine
import SwiftUI

enum VoiceNoteDisk {
    private static var documentsURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    static func url(for fileName: String) -> URL {
        documentsURL.appendingPathComponent(fileName)
    }

    static func makeFileName() -> String {
        "voice_\(UUID().uuidString).m4a"
    }

    static func delete(_ fileName: String) {
        try? FileManager.default.removeItem(at: url(for: fileName))
    }

    static func deleteAll() {
        let items = (try? FileManager.default.contentsOfDirectory(
            at: documentsURL,
            includingPropertiesForKeys: nil
        )) ?? []
        for item in items where item.pathExtension.lowercased() == "m4a" {
            try? FileManager.default.removeItem(at: item)
        }
    }

    static func exists(_ fileName: String) -> Bool {
        FileManager.default.fileExists(atPath: url(for: fileName).path)
    }
}

@MainActor
final class VoiceNoteController: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var isPlaying = false
    @Published var permissionDenied = false
    @Published var statusText = "Tap record to capture a gift idea"

    private var recorder: AVAudioRecorder?
    private var player: AVAudioPlayer?
    private var activeFileName: String?

    func prepare(existingFileName: String?) {
        activeFileName = existingFileName
        if let existingFileName, VoiceNoteDisk.exists(existingFileName) {
            statusText = "Voice note ready"
        } else {
            statusText = "Tap record to capture a gift idea"
        }
    }

    func toggleRecording(fileNameBinding: Binding<String?>) {
        if isRecording {
            stopRecording(fileNameBinding: fileNameBinding)
            return
        }
        startRecording(fileNameBinding: fileNameBinding)
    }

    func togglePlayback(fileName: String?) {
        if isPlaying {
            stopPlayback()
            return
        }
        guard let fileName, VoiceNoteDisk.exists(fileName) else {
            statusText = "No voice note yet"
            return
        }
        do {
            try configureSession(forRecording: false)
            let player = try AVAudioPlayer(contentsOf: VoiceNoteDisk.url(for: fileName))
            player.delegate = self
            player.prepareToPlay()
            player.play()
            self.player = player
            isPlaying = true
            statusText = "Playing voice note"
        } catch {
            statusText = "Could not play voice note"
        }
    }

    func deleteNote(fileNameBinding: Binding<String?>) {
        stopRecording(fileNameBinding: fileNameBinding)
        stopPlayback()
        if let fileName = fileNameBinding.wrappedValue {
            VoiceNoteDisk.delete(fileName)
        }
        fileNameBinding.wrappedValue = nil
        activeFileName = nil
        statusText = "Tap record to capture a gift idea"
    }

    private func startRecording(fileNameBinding: Binding<String?>) {
        stopPlayback()
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
            Task { @MainActor in
                guard let self else { return }
                guard granted else {
                    self.permissionDenied = true
                    self.statusText = "Microphone access is required"
                    return
                }
                self.beginRecording(fileNameBinding: fileNameBinding)
            }
        }
    }

    private func beginRecording(fileNameBinding: Binding<String?>) {
        do {
            try configureSession(forRecording: true)
            if let previous = fileNameBinding.wrappedValue {
                VoiceNoteDisk.delete(previous)
            }
            let fileName = VoiceNoteDisk.makeFileName()
            let url = VoiceNoteDisk.url(for: fileName)
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44_100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            let recorder = try AVAudioRecorder(url: url, settings: settings)
            recorder.prepareToRecord()
            recorder.record()
            self.recorder = recorder
            activeFileName = fileName
            fileNameBinding.wrappedValue = fileName
            isRecording = true
            statusText = "Recording…"
        } catch {
            statusText = "Could not start recording"
        }
    }

    private func stopRecording(fileNameBinding: Binding<String?>) {
        guard isRecording else { return }
        recorder?.stop()
        recorder = nil
        isRecording = false
        if let fileName = activeFileName ?? fileNameBinding.wrappedValue,
           VoiceNoteDisk.exists(fileName) {
            fileNameBinding.wrappedValue = fileName
            statusText = "Voice note saved"
        } else {
            fileNameBinding.wrappedValue = nil
            statusText = "Tap record to capture a gift idea"
        }
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func stopPlayback() {
        player?.stop()
        player = nil
        isPlaying = false
        if isRecording {
            statusText = "Recording…"
        } else if let fileName = activeFileName, VoiceNoteDisk.exists(fileName) {
            statusText = "Voice note ready"
        } else {
            statusText = "Tap record to capture a gift idea"
        }
    }

    private func configureSession(forRecording: Bool) throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(
            forRecording ? .playAndRecord : .playback,
            mode: .default,
            options: [.defaultToSpeaker]
        )
        try session.setActive(true)
    }
}

extension VoiceNoteController: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            self.isPlaying = false
            self.player = nil
            if let fileName = self.activeFileName, VoiceNoteDisk.exists(fileName) {
                self.statusText = "Voice note ready"
            }
        }
    }
}

struct VoiceNoteControlView: View {
    @Binding var fileName: String?
    @StateObject private var controller = VoiceNoteController()

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            GiftFieldLabel(title: "Voice note")
            Text(controller.statusText)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.86))

            HStack(spacing: 10) {
                Button {
                    controller.toggleRecording(fileNameBinding: $fileName)
                } label: {
                    Label(
                        controller.isRecording ? "Stop" : "Record",
                        systemImage: controller.isRecording ? "stop.circle.fill" : "mic.circle.fill"
                    )
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundColor(Palette.text)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        (controller.isRecording ? Palette.primary : Palette.surface).opacity(0.95),
                        in: Capsule()
                    )
                    .overlay {
                        Capsule().stroke(Palette.accent.opacity(0.65), lineWidth: 1)
                    }
                }
                .buttonStyle(.plain)

                Button {
                    controller.togglePlayback(fileName: fileName)
                } label: {
                    Label(
                        controller.isPlaying ? "Pause" : "Play",
                        systemImage: controller.isPlaying ? "pause.circle.fill" : "play.circle.fill"
                    )
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundColor(Palette.text)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Palette.surface.opacity(0.95), in: Capsule())
                    .overlay {
                        Capsule().stroke(Palette.accent.opacity(0.65), lineWidth: 1)
                    }
                }
                .buttonStyle(.plain)
                .disabled(fileName == nil || controller.isRecording)
                .opacity(fileName == nil || controller.isRecording ? 0.45 : 1)

                if fileName != nil {
                    Button("Delete") {
                        controller.deleteNote(fileNameBinding: $fileName)
                    }
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(Palette.text.opacity(0.9))
                    .buttonStyle(.plain)
                }
            }

            if controller.permissionDenied {
                Text("Enable Microphone in Settings to record gift ideas.")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.9))
            }
        }
        .padding(10)
        .background(Palette.surface.opacity(0.92), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Palette.accent.opacity(0.45), lineWidth: 1)
        }
        .onAppear {
            controller.prepare(existingFileName: fileName)
        }
        .onChange(of: fileName) { newValue in
            controller.prepare(existingFileName: newValue)
        }
    }
}
