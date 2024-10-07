import Foundation
import FirebaseFirestore

class Streak: ObservableObject {
    @Published var streakCount: Int = 0

    // Fetch calendar data from Firestore and calculate streak
    func fetchCalendarData(userID: String, currentYear: Int, currentMonth: Int) {
        let firestore = Firestore.firestore()
        var daysWithData = Set<Int>() // Change to 'var' to allow modification
        
        firestore.collection("users")
            .document(userID)
            .collection("calendar")
            .whereField("year", isEqualTo: currentYear)
            .whereField("month", isEqualTo: currentMonth)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching calendar data: \(error.localizedDescription)")
                    return
                }

                // Loop through documents and collect the days with data
                snapshot?.documents.forEach { document in
                    if let day = document.get("day") as? Int {
                        daysWithData.insert(day) // Modify the mutable set
                    }
                }

                // Once data is fetched, calculate the total number of dates
                self.calculateStreak(daysWithData: daysWithData)
            }
    }

    // Calculate streak based on the total number of dates with data
    func calculateStreak(daysWithData: Set<Int>) {
        let totalDaysWithData = daysWithData.count

        // Update the streak count to reflect the total number of days with data
        DispatchQueue.main.async {
            self.streakCount = totalDaysWithData
        }
    }
}
