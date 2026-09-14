import UIKit
import UserNotifications

enum GiftReminders {
    static func requestAccessThenSync(occasions: [GiftOccasion]) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in
            DispatchQueue.main.async {
                sync(occasions: occasions, enabled: true)
            }
        }
    }

    static func sync(occasions: [GiftOccasion], enabled: Bool) {
        let center = UNUserNotificationCenter.current()
        if !enabled {
            center.removeAllPendingNotificationRequests()
            UIApplication.shared.applicationIconBadgeNumber = 0
            return
        }

        center.removeAllPendingNotificationRequests()
        let calendar = Calendar.current
        let now = Date()
        let upcoming = occasions.filter { $0.date.isGiftUpcoming }
        let badge = upcoming.filter { $0.date.isGiftDue(withinDays: 14) }.count
        UIApplication.shared.applicationIconBadgeNumber = badge

        for occasion in upcoming {
            for days in [14, 7, 1] {
                guard let fireDay = calendar.date(byAdding: .day, value: -days, to: occasion.date.giftStartOfDay) else {
                    continue
                }
                var components = calendar.dateComponents([.year, .month, .day], from: fireDay)
                components.hour = 9
                components.minute = 0
                guard let fireDate = calendar.date(from: components), fireDate > now else { continue }

                let content = UNMutableNotificationContent()
                content.title = "Gift due soon"
                content.body = days == 1
                    ? "\(occasion.contactName)'s \(occasion.occasionType.title) is tomorrow."
                    : "\(occasion.contactName)'s \(occasion.occasionType.title) is in \(days) days."
                content.sound = .default

                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                let request = UNNotificationRequest(
                    identifier: "gift.\(occasion.id.uuidString).\(days)",
                    content: content,
                    trigger: trigger
                )
                center.add(request)
            }
        }
    }
}
