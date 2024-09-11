//
//  WataApp.swift
//  Wata
//
//  Created by Adam May on 8/2/24.
//

import SwiftUI
import FirebaseCore
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // Initialize Firebase
        FirebaseApp.configure()

        // Manually trigger the notification scheduling or logic for testing purposes
        Notification().scheduleReminderNotifications() // Trigger your notification method

        return true
    }
}

@main
struct WataApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()  // Your main view
        }
    }
}
