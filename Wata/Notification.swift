import Firebase
import FirebaseMessaging
import UserNotifications
import UIKit

class Notification: UIViewController, UNUserNotificationCenterDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the delegate for UNUserNotificationCenter
        UNUserNotificationCenter.current().delegate = self
        
        // Check for notification permissions and schedule notifications if granted
        checkForPermission { granted in
            if granted {
                self.scheduleReminderNotifications()
            } else {
                print("Notification permission denied.")
            }
        }
    }
    
    // Method to check and request notification permissions
    func checkForPermission(completion: @escaping (Bool) -> Void) {
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .authorized:
                completion(true)
            case .denied:
                completion(false)
            case .notDetermined:
                notificationCenter.requestAuthorization(options: [.alert, .sound]) { didAllow, error in
                    completion(didAllow)
                }
            default:
                completion(false)
            }
        }
    }
    
    // Schedule reminder notifications every 3 hours starting at 8 AM
    func scheduleReminderNotifications() {
        let times = [
            (identifier: "hydration-8am-notification", hour: 8, minute: 0),
            (identifier: "hydration-11am-notification", hour: 11, minute: 0),
            (identifier: "hydration-2pm-notification", hour: 14, minute: 0),
            (identifier: "hydration-5pm-notification", hour: 17, minute: 0),
            (identifier: "hydration-8pm-notification", hour: 20, minute: 0),
            (identifier: "hydration-11pm-notification", hour: 23, minute: 0)
        ]
        
        let title = "Stay Hydrated!"
        let body = "It's time to take a water break and refresh yourself!"
        let notificationCenter = UNUserNotificationCenter.current()

        for time in times {
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.sound = .default
            
            var dateComponents = DateComponents()
            dateComponents.hour = time.hour
            dateComponents.minute = time.minute
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let request = UNNotificationRequest(identifier: time.identifier, content: content, trigger: trigger)
            
            notificationCenter.add(request) { error in
                if let error = error {
                    print("Error scheduling \(time.identifier): \(error.localizedDescription)")
                } else {
                    print("\(time.identifier) scheduled successfully at \(time.hour):\(time.minute).")
                }
            }
        }
    }
    
    // Handle notification while the app is in the foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .sound])
    }
    
    // Handle notification actions and responses
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // Handle the notification action (if needed)
        print("User interacted with notification: \(response.notification.request.identifier)")
        completionHandler()
    }
}
