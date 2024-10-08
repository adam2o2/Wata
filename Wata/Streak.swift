import Foundation
import FirebaseFirestore

class Streak: ObservableObject {
    @Published var streakCount: Int = 1 // Start from 1

    // Fetch all calendar data from Firestore and calculate streak
    func fetchCalendarData(userID: String) {
        let firestore = Firestore.firestore()
        var daysWithData = Set<Int>() // Mutable set to track days with data

        firestore.collection("users")
            .document(userID)
            .collection("calendar")
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching calendar data: \(error.localizedDescription)")
                    return
                }

                // Collect the unique days with data
                snapshot?.documents.forEach { document in
                    if let timestamp = document.get("timestamp") as? Timestamp {
                        let day = Calendar.current.component(.day, from: timestamp.dateValue())
                        daysWithData.insert(day)
                    }
                }

                // Calculate the total number of days with data
                self.calculateTotalDays(daysWithData: daysWithData)
            }
    }

    // Calculate total days based on the number of unique days with data
    func calculateTotalDays(daysWithData: Set<Int>) {
        // The total streak count is simply the number of unique days stored
        let totalDays = daysWithData.count

        // Update the streak count on the main thread
        DispatchQueue.main.async {
            self.streakCount = totalDays
        }
    }
}
