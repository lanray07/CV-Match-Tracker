import Foundation
import UserNotifications

enum LocalNotificationScheduler {
    static func schedule(reminder: Reminder) {
        guard reminder.dueDate > .now else { return }

        let identifier = reminder.id.uuidString
        let title = reminder.title
        let body = reminder.applicationTitle.isEmpty ? reminder.detail : reminder.applicationTitle
        let dueDate = reminder.dueDate

        Task {
            let center = UNUserNotificationCenter.current()
            let granted = (try? await center.requestAuthorization(options: [.alert, .badge, .sound])) ?? false
            guard granted else { return }

            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.sound = .default

            let components = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: dueDate
            )
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(
                identifier: identifier,
                content: content,
                trigger: trigger
            )
            try? await center.add(request)
        }
    }
}
