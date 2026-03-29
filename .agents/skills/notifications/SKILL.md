---
name: "notifications"
description: "Use when implementing notification features. Covers UNUserNotificationCenter permission flow, scheduling, badge count, foreground handling."
---

# Local Notifications

Use this guide when implementing or modifying notification features.

## Framework
`UserNotifications` — `UNUserNotificationCenter.current()`

## Permission States (CRITICAL — handle ALL four)
1. **Not Determined** — Call `.requestAuthorization(options: [.alert, .badge, .sound])`. System shows dialog.
2. **Authorized** — Schedule notifications normally.
3. **Denied** — App CANNOT re-request. Must redirect user to System Settings.
4. **Provisional** — Quiet notifications. Treat as authorized.

## Permission Is System-Controlled
- Once denied, the app has NO way to re-request — only the user can re-enable in System Settings.
- To open Settings: `UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)`

## UI Rules for Notification Status
- `.notDetermined` — Show "Enable Notifications" button that calls `requestAuthorization`. After dialog, re-check and update UI.
- `.authorized` / `.provisional` — Show enabled state (bell icon). Read-only — user disables in Settings.
- `.denied` — Show "bell.slash" icon + "Open Settings" button. Show helper text explaining system control.
- **NEVER use a writable Toggle** for notification permission — the app cannot grant/revoke it. Use buttons with state-specific actions.

## Re-Check on Foreground (CRITICAL)
Any view displaying notification status MUST re-check when app returns to foreground:
```swift
.onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
    Task {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        isEnabled = (settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional)
    }
}
```

## Scheduling
```swift
let content = UNMutableNotificationContent()
content.title = "Reminder"
content.body = "Time to check in"
content.sound = .default

// Time-based
let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3600, repeats: false)

// Calendar-based (daily at specific time)
var dateComponents = DateComponents()
dateComponents.hour = 20
dateComponents.minute = 0
let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

let request = UNNotificationRequest(identifier: "reminder", content: content, trigger: trigger)
try await UNUserNotificationCenter.current().add(request)
```

## Badge Count
- Set: `UNMutableNotificationContent().badge = NSNumber(value: count)`
- Clear on app open: `UIApplication.shared.applicationIconBadgeNumber = 0`
