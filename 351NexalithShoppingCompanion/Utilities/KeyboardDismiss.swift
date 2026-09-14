import SwiftUI
import UIKit

enum KeyboardDismiss {
    static func hide() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct WindowKeyboardDismiss: UIViewRepresentable {
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.isUserInteractionEnabled = false
        context.coordinator.install(from: view)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.install(from: uiView)
    }

    static func dismantleUIView(_ uiView: UIView, coordinator: Coordinator) {
        coordinator.uninstall()
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        private static var trackedWindows = NSHashTable<UIWindow>.weakObjects()

        private weak var installedWindow: UIWindow?
        private var recognizer: UITapGestureRecognizer?

        func install(from view: UIView) {
            DispatchQueue.main.async { [weak self] in
                guard let self, let window = view.window else { return }
                if self.installedWindow === window { return }
                self.uninstall()
                if Coordinator.trackedWindows.contains(window) {
                    self.installedWindow = window
                    return
                }
                let tap = UITapGestureRecognizer(target: self, action: #selector(self.handleTap))
                tap.cancelsTouchesInView = false
                tap.delegate = self
                window.addGestureRecognizer(tap)
                Coordinator.trackedWindows.add(window)
                self.recognizer = tap
                self.installedWindow = window
            }
        }

        func uninstall() {
            if let recognizer, let window = installedWindow {
                window.removeGestureRecognizer(recognizer)
                Coordinator.trackedWindows.remove(window)
            }
            recognizer = nil
            installedWindow = nil
        }

        @objc func handleTap() {
            KeyboardDismiss.hide()
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
            var view = touch.view
            while let current = view {
                if current is UITextField || current is UITextView {
                    return false
                }
                view = current.superview
            }
            return true
        }

        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer
        ) -> Bool {
            true
        }
    }
}

extension View {
    func dismissKeyboardOnTap() -> some View {
        background(WindowKeyboardDismiss())
    }
}
