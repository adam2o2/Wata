import SwiftUI
import Firebase
import FirebaseStorage
import FirebaseAuth

// CalendarManager subclass to manage previous counts and images
class CalendarManager: ObservableObject {
    let userID = Auth.auth().currentUser?.uid
    @Published var currentMonth: String
    @Published var currentYear: String

    init() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM"
        self.currentMonth = dateFormatter.string(from: Date())

        let yearFormatter = DateFormatter()
        yearFormatter.dateFormat = "yyyy"
        self.currentYear = yearFormatter.string(from: Date())
    }

    // Function to save count and image at the end of the day
    func saveDailyData(count: Int, image: UIImage?, forDay day: Int) {
        guard let userID = userID else { return }
        let firestore = Firestore.firestore()
        let storage = Storage.storage()
        let date = "\(currentMonth) \(day)"

        // Upload the image to Firebase Storage
        if let image = image, let imageData = image.jpegData(compressionQuality: 0.8) {
            let imagePath = "calendar/\(userID)/\(currentMonth)/\(date).jpg"
            let storageRef = storage.reference().child(imagePath)
            storageRef.putData(imageData, metadata: nil) { (metadata, error) in
                if let error = error {
                    print("Error uploading image: \(error.localizedDescription)")
                    return
                }

                storageRef.downloadURL { (url, error) in
                    if let error = error {
                        print("Error fetching download URL: \(error.localizedDescription)")
                        return
                    }

                    if let downloadURL = url?.absoluteString {
                        // Save the count and image URL to Firestore
                        firestore.collection("users")
                            .document(userID)
                            .collection("calendar")
                            .document(self.currentMonth)
                            .collection(self.currentMonth)
                            .document(date)
                            .setData([
                                "count": count,
                                "imageUrl": downloadURL,
                                "timestamp": FieldValue.serverTimestamp()
                            ]) { error in
                                if let error = error {
                                    print("Error saving daily data: \(error.localizedDescription)")
                                } else {
                                    print("Daily data saved successfully for \(date)")
                                }
                            }
                    }
                }
            }
        } else {
            // Save only the count if there's no image
            firestore.collection("users")
                .document(userID)
                .collection("calendar")
                .document(currentMonth)
                .collection(currentMonth)
                .document(date)
                .setData([
                    "count": count,
                    "timestamp": FieldValue.serverTimestamp()
                ]) { error in
                    if let error = error {
                        print("Error saving daily data: \(error.localizedDescription)")
                    } else {
                        print("Daily data saved successfully for \(date)")
                    }
                }
        }
    }

    // Function to trigger saving data at the end of the day for all time zones
    func saveDataAtEndOfDay(count: Int, image: UIImage?) {
        let calendar = Calendar.current
        let currentDate = Date()

        // Schedule to save data at the end of the day
        let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: currentDate) ?? currentDate
        let timeInterval = endOfDay.timeIntervalSinceNow

        DispatchQueue.main.asyncAfter(deadline: .now() + timeInterval) {
            let day = calendar.component(.day, from: currentDate)
            self.saveDailyData(count: count, image: image, forDay: day)
        }
    }
}

// A UIViewRepresentable to wrap UIVisualEffectView in SwiftUI
struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style

    func makeUIView(context: Context) -> UIVisualEffectView {
        let blurEffect = UIBlurEffect(style: style)
        let blurView = UIVisualEffectView(effect: blurEffect)
        return blurView
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        // Update the blur effect if needed
        uiView.effect = UIBlurEffect(style: style)
    }
}

struct Profile: View {
    @StateObject private var calendarManager = CalendarManager()
    @State private var username: String = "Adam"
    @State private var capturedImage: UIImage? = nil
    @State private var timer: Timer?
    @State private var selectedDay: Int? = nil  // State to track the selected day
    @State private var showDetailView: Bool = false  // State to control the visibility of the detail view
    @State private var count: Int? = nil  // To match the counter from HomeView
    @State private var isNavigatingToHome = false  // State to handle navigation to HomeView
    @State private var isPressed = false // State to control the bounce effect
    @State private var noDataMessage: String? = nil  // State to show message when no data is available
    @StateObject private var hapticManager = HapticManager() // Haptic manager

    let userID = Auth.auth().currentUser?.uid
    let daysInMonth = Calendar.current.range(of: .day, in: .month, for: Date())!.count
    let currentMonth = Calendar.current.component(.month, from: Date())
    let currentYear = Calendar.current.component(.year, from: Date())
    let currentDay = Calendar.current.component(.day, from: Date())

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack {
            // Background Image with Placeholder
            Color.gray.edgesIgnoringSafeArea(.all) // Placeholder color

            if let image = capturedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .edgesIgnoringSafeArea(.all)
            }

            // Apply the blur effect over the background image
            BlurView(style: .regular)
                .edgesIgnoringSafeArea(.all)

            VStack {
                // Top section with username and home icon
                HStack(spacing: 180) {
                    Text(username)
                        .font(.system(size: 35))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.leading, 20)
                        .padding(.top, 20)
                        .offset(x: -10)  // Adjust to move the text to the left

                    // Home icon with haptics, bounce effect, and navigation to HomeView
                    Button(action: {
                        hapticManager.triggerHapticFeedback()
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isPressed = true
                        }
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.5, blendDuration: 0)) {
                            isPressed = false
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            self.isNavigatingToHome = true
                        }
                    }) {
                        Image("home")  // Use your home image
                            .resizable()
                            .foregroundColor(.white)
                            .padding(.trailing, 20)
                            .padding(.top, 20)
                            .frame(width: 53, height: 50)
                            .offset(x: 10)  // Adjust to move the button to the right
                            .scaleEffect(isPressed ? 0.8 : 1.0) // Bounce effect
                    }
                }
                .padding(.top, 16)


                // Month and Year Display
                HStack {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 25))
                        .foregroundColor(.white)
                        .padding(.leading, 20)
                        .fontWeight(.bold)
                        .opacity(0.4)
                        .offset(x: -1)

                    Text("\(monthName(for: currentMonth)) \(String(currentYear))")
                        .font(.system(size: 35, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.top, 90)
                .offset(x: -20)

                // Calendar grid with selectable dates
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: -80), count: 7), spacing: 20) {  // Reduced spacing between columns
                    ForEach(1...daysInMonth, id: \.self) { day in
                        Text("\(day)")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(day == currentDay || day == selectedDay ? .white : Color.white.opacity(0.3))
                            .frame(width: 32, height: 40)  // Keep the original width for the numbers
                            .lineLimit(1)  // Ensures the text stays on one line
                            .scaleEffect(day == selectedDay ? 1.2 : 1.0)  // Scale effect when the day is selected
                            .onTapGesture {
                                selectedDay = day
                                hapticManager.triggerHapticFeedback()  // Trigger haptic feedback

                                withAnimation(.easeInOut(duration: 0.2)) {
                                    // Temporary scale animation
                                    selectedDay = day
                                }
                                
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    // Reset scale animation after a short delay
                                    selectedDay = day
                                }

                                if day != currentDay {  // Only fetch data for past days
                                    fetchCountFromFirestore(for: day)
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        showDetailView = true
                                    }
                                } else {
                                    // Handle the current day as usual
                                    fetchCountForCurrentDay()
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        showDetailView = true
                                    }
                                }
                            }
                    }
                }

                .padding(.top, 5)

                Spacer()
            }

            if showDetailView {
                // Full-screen Detail view with animation
                ZStack {
                    // Background blur and dim effect
                    BlurView(style: .regular)
                        .edgesIgnoringSafeArea(.all)
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showDetailView = false
                            }
                        }

                    VStack {
                        Spacer()
                        
                        // Display the captured image in the center
                        if let image = capturedImage {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 290, height: 390)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                .shadow(radius: 10)
                                .offset(y: 5)
                        }
                        
                        // Display "Finished bottles" label and count or "Nothing drank"
                        if let count = count {
                            if count > 0 {
                                Text("Finished bottles")
                                    .font(.system(size: 20))
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .opacity(0.6)
                                    .offset(y: 70)
                                
                                Text("\(count)")  // Display the dynamic count
                                    .font(.system(size: 80))
                                    .foregroundColor(.white)
                                    .fontWeight(.bold)
                                    .offset(y: 110)
                                    .overlay(
                                        VStack {
                                            Spacer()
                                            Text("\(count)")
                                                .font(.system(size: 80))
                                                .foregroundColor(.white)
                                                .fontWeight(.bold)
                                                .opacity(0.18) // Adjust the opacity of the reflection
                                                .scaleEffect(y: -1) // Flip the text vertically
                                                .mask(
                                                    LinearGradient(
                                                        gradient: Gradient(colors: [Color.white.opacity(0.5), Color.clear]),
                                                        startPoint: .top,
                                                        endPoint: .bottom
                                                    )
                                                )
                                                .offset(y: 170) // Adjust position if needed
                                        }
                                    )
                                    .offset(y: -40)
                            } else {
                                Text("Nothing drank")
                                    .font(.system(size: 30))
                                    .foregroundColor(.white)
                                    .fontWeight(.bold)
                                    .offset(y: 110)
                            }
                        }
                        
                        Spacer()
                    }
                }
                .transition(.opacity)
            }
            
            // Navigation link to HomeView with back button hidden
            NavigationLink(destination: HomeView().navigationBarBackButtonHidden(true), isActive: $isNavigatingToHome) {
                EmptyView()
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            hapticManager.prepareHaptics()
            fetchUserData()
            fetchCountForCurrentDay()
            calendarManager.saveDataAtEndOfDay(count: count ?? 0, image: capturedImage)  // Schedule the save operation
        }
        .onDisappear {
            timer?.invalidate()
        }
    }

    private func monthName(for month: Int) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM"
        return dateFormatter.monthSymbols[month - 1]
    }

    private func fetchUserData() {
        guard let userID = userID else { return }
        let firestore = Firestore.firestore()
        
        firestore.collection("users").document(userID).getDocument { document, error in
            if let document = document, document.exists {
                self.username = document.get("username") as? String ?? "Adam"
                self.fetchRecentImage()
            } else {
                print("Error fetching username: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }

    private func fetchCountForCurrentDay() {
        guard let userID = userID else { return }
        let firestore = Firestore.firestore()
        firestore.collection("users").document(userID).getDocument { document, error in
            if let document = document, document.exists {
                self.count = document.get("count") as? Int
                self.noDataMessage = nil  // Clear the no data message if data exists
            } else {
                print("Error fetching count: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }

    private func fetchCountFromFirestore(for day: Int) {
        guard let userID = userID else { return }
        let firestore = Firestore.firestore()
        firestore.collection("users").document(userID).collection("days").document("\(day)").getDocument { document, error in
            if let document = document, document.exists {
                self.count = document.get("count") as? Int
                self.noDataMessage = nil  // Clear the no data message if data exists
            } else {
                self.count = 0  // Assume count is 0 if no data exists
                self.noDataMessage = "Nothing drank"
                print("No data for day \(day)")
            }
        }
    }

    private func fetchRecentImage() {
        guard let userID = userID else { return }
        let firestore = Firestore.firestore()
        let storage = Storage.storage()
        
        firestore.collection("users")
            .document(userID)
            .collection("images")
            .order(by: "timestamp", descending: true)
            .limit(to: 1)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching documents: \(error.localizedDescription)")
                    return
                }
                
                guard let document = snapshot?.documents.first else {
                    print("No recent image found")
                    return
                }
                
                if let imageURL = document.get("url") as? String {
                    let imageRef = storage.reference(forURL: imageURL)
                    imageRef.getData(maxSize: 10 * 1024 * 1024) { data, error in
                        if let data = data, let image = UIImage(data: data) {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                self.capturedImage = image
                            }
                        }
                    }
                }
            }
    }
}

#Preview {
    Profile()
}
