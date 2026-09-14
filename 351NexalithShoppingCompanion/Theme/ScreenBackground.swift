import SwiftUI

struct ScreenBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                Color("AppBackground")
                    .overlay {
                        Image("BgGifts")
                            .resizable()
                            .scaledToFill()
                            .opacity(0.22)
                    }
                    .clipped()
                    .ignoresSafeArea()
            }
    }
}

extension View {
    func studioBackdrop() -> some View {
        modifier(ScreenBackground())
    }
}
