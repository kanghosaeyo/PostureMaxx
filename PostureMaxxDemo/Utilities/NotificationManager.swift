//
//  NotificationManager.swift
//  PostureMaxxDemo
//
//  Created by Kangho Ji on 3/28/25.
//

import UserNotifications

class NotificationManager: ObservableObject {
    private var notificationCount = 0
    
    func scheduleNotification() {
        notificationCount += 1
        
        let content = UNMutableNotificationContent()
        content.title = "Posture Alert"
        content.body = "Please adjust your sitting position"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 10, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString,
                                          content: content,
                                          trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
        
        // Reset counter after 1 hour
        DispatchQueue.main.asyncAfter(deadline: .now() + 3600) {
            self.notificationCount = 0
        }
    }
    
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { success, _ in
            guard success else { return }
        }
    }
}
