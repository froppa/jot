import Foundation
import UserNotifications

enum ReminderScheduler {
    static func schedule(for note: Note) {
        guard let reminderAt = note.reminderAt else { return }
        let identifier = note.id.uuidString
        let title = note.title
        let body = note.preview

        Task { @MainActor in
            let center = UNUserNotificationCenter.current()
            guard try await center.requestAuthorization(options: [.alert, .sound]) else { return }

            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.sound = .default

            let date = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderAt)
            let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: false)
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            try? await center.add(request)
        }
    }

    static func cancel(for note: Note) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [note.id.uuidString])
    }
}
