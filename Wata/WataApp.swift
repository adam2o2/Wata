//
//  WataApp.swift
//  Wata
//
//  Created by Adam May on 8/2/24.
//

import SwiftUI
import FirebaseCore
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // Initialize Firebase
        FirebaseApp.configure()
        
        // Set the notification delegate to self
        UNUserNotificationCenter.current().delegate = self

        // Request notification permission
        requestNotificationPermission()

        return true
    }
    
    // Request notification permissions from the user
    func requestNotificationPermission() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Error requesting notification authorization: \(error.localizedDescription)")
                return
            }
            if granted {
                print("Notification permission granted.")
                // Manually trigger the notification scheduling if permission is granted
                Notification().scheduleReminderNotifications()
            } else {
                print("Notification permission denied.")
            }
        }
    }
    
    // Handle notifications in the foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .sound])
    }
}

@main
struct WataApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @State private var showSplashScreen = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()  // Your main view

                // Show the splash screen only when showSplashScreen is true
                if showSplashScreen {
                    SplashScreen()
                        .transition(.opacity) // Use a transition for smoother removal
                        .onAppear {
                            // Dismiss the splash screen after a short delay
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                withAnimation {
                                    showSplashScreen = false
                                }
                            }
                        }
                }
            }
            .animation(.easeInOut(duration: 0.5), value: showSplashScreen) // Add smooth fade-out animation
        }
    }
}
