import StoreKit
import UIKit

enum AppLinks: String {
    case privacy = "https://nexalithshopping351companion.site/privacy/463"
    case terms = "https://nexalithshopping351companion.site/terms/463"

    static func rateApp() {
        let scenes = UIApplication.shared.connectedScenes.compactMap { scene in
            scene as? UIWindowScene
        }
        let windowScene = scenes.first(where: { scene in
            scene.activationState == .foregroundActive
        }) ?? scenes.first
        if let windowScene {
            SKStoreReviewController.requestReview(in: windowScene)
        }
    }
}
