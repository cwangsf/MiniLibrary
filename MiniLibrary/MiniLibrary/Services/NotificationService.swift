//
//  NotificationService.swift
//  MiniLibrary
//
//  Created by Cynthia Wang on 2/4/26.
//

import UserNotifications
import os

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "MiniLibrary", category: "NotificationService")

enum NotificationService {
    private static let weeklyExportReminderID = "weekly-export-reminder"

    static func requestAuthorization() {
        let localLogger = logger
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error {
                localLogger.error("Notification authorization error: \(error.localizedDescription)")
                return
            }
            if granted {
                Task { @MainActor in
                    scheduleWeeklyExportReminder()
                }
            }
        }
    }

    static func scheduleWeeklyExportReminder() {
        let center = UNUserNotificationCenter.current()
        let localLogger = logger

        // Remove any existing pending notification with this ID
        center.removePendingNotificationRequests(withIdentifiers: [weeklyExportReminderID])

        let content = UNMutableNotificationContent()
        content.title = String(localized: "Export Reminder")
        content.body = String(localized: "It's been a week! Export your library data to keep a backup.")
        content.sound = .default

        // Tuesday at 9:00 AM
        var dateComponents = DateComponents()
        dateComponents.weekday = 3 // Tuesday
        dateComponents.hour = 9
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: weeklyExportReminderID, content: content, trigger: trigger)

        center.add(request) { error in
            if let error {
                localLogger.error("Failed to schedule export reminder: \(error.localizedDescription)")
            }
        }
    }
}
