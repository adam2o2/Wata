import SwiftUI
import Firebase
import FirebaseStorage
import FirebaseAuth
import CoreHaptics
import UIKit
import Pow

class UserDataManager: ObservableObject {
    static let shared = UserDataManager() // Singleton instance
    @Published var daysWithData: Set<Int> = []

    private init() {}

    // Function to update the current day with data
    func markCurrentDay() {
        let today = Calendar.current.component(.day, from: Date())
        daysWithData.insert(today)
    }

    // Function to check if a day has data
    func hasData(forDay day: Int) -> Bool {
        return daysWithData.contains(day)
    }
}

// A UIViewRepresentable to wrap UIVisualEffectView in SwiftUI
struct CustomBlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style

    func makeUIView(context: Context) -> UIVisualEffectView {
        let blurEffect = UIBlurEffect(style: .regular)
        let blurView = UIVisualEffectView(effect: blurEffect)
        return blurView
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
}

struct RippleModifier: ViewModifier {
    var origin: CGPoint
    var elapsedTime: TimeInterval
    var duration: TimeInterval
    var amplitude: Double
    var frequency: Double
    var decay: Double
    var speed: Double

    func body(content: Content) -> some View {
        let shader = ShaderLibrary.Ripple(
            .float2(origin),
            .float(elapsedTime),
            .float(amplitude),
            .float(frequency),
            .float(decay),
            .float(speed)
        )

        content.visualEffect { view, _ in
            view.layerEffect(
                shader,
                maxSampleOffset: maxSampleOffset,
                isEnabled: 0 < elapsedTime && elapsedTime < duration
            )
        }
    }

    var maxSampleOffset: CGSize {
        CGSize(width: amplitude, height: amplitude)
    }
}

struct RippleEffect<T: Equatable>: ViewModifier {
    var origin: CGPoint
    var trigger: T
    var amplitude: Double
    var frequency: Double
    var decay: Double
    var speed: Double

    init(at origin: CGPoint, trigger: T, amplitude: Double = 20, frequency: Double = 20, decay: Double = 8, speed: Double = 1200) {
        self.origin = origin
        self.trigger = trigger
        self.amplitude = amplitude
        self.frequency = frequency
        self.decay = decay
        self.speed = speed
    }

    func body(content: Content) -> some View {
        content.keyframeAnimator(
            initialValue: 0,
            trigger: trigger
        ) { view, elapsedTime in
            view.modifier(RippleModifier(
                origin: origin,
                elapsedTime: elapsedTime,
                duration: duration,
                amplitude: amplitude,
                frequency: frequency,
                decay: decay,
                speed: speed
            ))
        } keyframes: { _ in
            MoveKeyframe(0)
            LinearKeyframe(duration, duration: duration)
        }
    }

    var duration: TimeInterval { 3 }
}

struct SharedBackgroundView: View {
    @Binding var capturedImage: UIImage?
    @Binding var backgroundError: String?
    var rippleOrigin: CGPoint = .zero // Default value
    var rippleTrigger: Int = 0 // Default value

    var body: some View {
        ZStack {
            if let image = capturedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .edgesIgnoringSafeArea(.all)
                    .blur(radius: 17)
                    .modifier(RippleEffect(at: rippleOrigin, trigger: rippleTrigger)) // Apply ripple effect here
            } else if let error = backgroundError {
                Text("Failed to load background: \(error)")
                    .foregroundColor(.red)
                    .background(Color.black.edgesIgnoringSafeArea(.all))
            }
            CustomBlurView(style: .regular)
                .edgesIgnoringSafeArea(.all)
        }
    }
}

struct HomeView: View {
    @State private var count: Int = 0
    @State private var timer: Timer?
    @Binding var username: String // Updated to be a binding
    @State private var capturedImage: UIImage? = nil
    @StateObject private var hapticManager = HapticManager()
    @State private var isShowingProfile = false
    @State private var rippleTrigger: Int = 0
    @State private var backgroundError: String? = nil
    @State private var rippleOrigin: CGPoint = {
        UIScreen.main.bounds.width < 668 ? CGPoint(x: 170, y: 370) : CGPoint(x: 270, y: 870)
    }()
    @State private var isLongPressActivePlus = false
    @State private var isLongPressActiveMinus = false
    @State private var scaleEffect: CGFloat = 0.0
    @State private var isRetakeMessagePresented = false
    @State private var isImageLongPressed = false
    @State private var imageScaleEffect: CGFloat = 0.0
    @State private var contentOpacity: Double = 1.0 // Add state for opacity
    @State private var contentBlur: CGFloat = 0.0 // Add state for blur
    @State private var isLoginDeletePresented = false
    @State private var isSprayActive = false
    @ObservedObject private var userDataManager = UserDataManager.shared

    let userID = Auth.auth().currentUser?.uid
    @Environment(\.horizontalSizeClass) var horizontalSizeClass // Detect device size class

    var body: some View {
        ZStack {
            SharedBackgroundView(capturedImage: $capturedImage, backgroundError: $backgroundError, rippleOrigin: rippleOrigin, rippleTrigger: rippleTrigger)

            VStack {
                // UserIcon with long press gesture for LoginDelete
                UserIcon(username: $username, iconName: "calendar") {
                    hapticManager.triggerHapticFeedback()
                    withAnimation(.easeInOut(duration: 0.5)) {
                        contentOpacity = 0.0 // Fade content out
                        contentBlur = 40.0   // Blur content
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.42) {
                        isShowingProfile = true
                    }
                }
                .onLongPressGesture(
                    minimumDuration: 0.5,
                    perform: {
                        hapticManager.triggerHapticFeedback()
                        isLoginDeletePresented = true
                    },
                    onPressingChanged: { isPressing in
                        if isPressing {
                            hapticManager.triggerHapticFeedback()
                        }
                    }
                )

                Spacer()

                // Content that should fade and blur (excluding the username and icon)
                VStack {
                    if let image = capturedImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: horizontalSizeClass == .compact ? 290 : 500, height: horizontalSizeClass == .compact ? 390 : 700) // Adjust frame size for iPad
                            .clipShape(RoundedRectangle(cornerRadius: horizontalSizeClass == .compact ? 20 : 30)) // Adjust corner radius for iPad
                            .shadow(radius: 10)
                            .offset(y: horizontalSizeClass == .compact ? 109 : 400) // Adjust offset for iPad
                            .scaleEffect(imageScaleEffect)
                            .animation(.spring(response: 0.6, dampingFraction: 0.5, blendDuration: 0.3), value: imageScaleEffect)
                            .onAppear {
                                imageScaleEffect = 1.0
                            }
                            .onDisappear {
                                imageScaleEffect = 0.0
                            }
                            .scaleEffect(isImageLongPressed ? 0.9 : 1.0)
                            .animation(.easeInOut(duration: 0.2), value: isImageLongPressed)
                            .onLongPressGesture(
                                minimumDuration: 0.5,
                                perform: {
                                    hapticManager.triggerHapticFeedback()
                                    isRetakeMessagePresented = true
                                },
                                onPressingChanged: { isPressing in
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        isImageLongPressed = isPressing
                                    }
                                    if isPressing {
                                        hapticManager.triggerHapticFeedback()
                                    }
                                }
                            )
                    }

                    Spacer()

                    VStack(spacing: 10) {
                        Text("Finished bottles")
                            .font(.system(size: horizontalSizeClass == .compact ? 20 : 30, weight: .bold, design: .rounded)) // Adjust font size for iPad
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .opacity(0.6)
                            .offset(y: 10)
                            .scaleEffect(scaleEffect)

                        HStack(spacing: horizontalSizeClass == .compact ? 30 : 50) { // Adjust spacing for iPad
                            // Minus button
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    isLongPressActiveMinus = true
                                }
                                if count > 0 {
                                    count -= 1
                                    saveCountToFirestore()
                                    hapticManager.triggerHapticFeedback()
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        isLongPressActiveMinus = false
                                    }
                                }
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(isLongPressActiveMinus ? Color.red : Color.white.opacity(0.2))
                                        .frame(width: horizontalSizeClass == .compact ? 40 : 60, height: horizontalSizeClass == .compact ? 40 : 60) // Adjust size for iPad
                                        .shadow(color: isLongPressActiveMinus ? Color.red.opacity(0.8) : Color.clear, radius: isLongPressActiveMinus ? 10 : 0)
                                    Image(systemName: "minus")
                                        .font(.system(size: horizontalSizeClass == .compact ? 20 : 30)) // Adjust font size for iPad
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                }
                                .scaleEffect(isLongPressActiveMinus ? 1.5 : scaleEffect)
                            }

                            // Count display
                            Text("\(count)")
                                .font(.system(size: horizontalSizeClass == .compact ? 80 : 120, weight: .bold, design: .rounded)) // Adjust font size for iPad
                                .foregroundColor(.white)
                                .fontWeight(.bold)
                                .scaleEffect(scaleEffect)
                                .overlay(
                                    VStack {
                                        Spacer()
                                        Text("\(count)")
                                            .font(.system(size: horizontalSizeClass == .compact ? 80 : 120, weight: .bold, design: .rounded)) // Adjust font size for iPad
                                            .foregroundColor(.white)
                                            .fontWeight(.bold)
                                            .opacity(0.18)
                                            .scaleEffect(x: scaleEffect, y: -scaleEffect)
                                            .mask(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [Color.white.opacity(0.5), Color.clear]),
                                                    startPoint: .top,
                                                    endPoint: .bottom
                                                )
                                            )
                                            .offset(y: horizontalSizeClass == .compact ? 60 : 95)
                                    }
                                )

                            // Plus button
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    isLongPressActivePlus = true
                                    isSprayActive = true // Activate spray animation
                                }
                                count += 1
                                saveCountToFirestore()
                                hapticManager.triggerHapticFeedback()
                                rippleTrigger += 1
                                userDataManager.markCurrentDay()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        isLongPressActivePlus = false
                                        isSprayActive = false // Deactivate spray animation after the action
                                    }
                                }
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(isLongPressActivePlus ? Color.blue : Color.white.opacity(0.2))
                                        .frame(width: horizontalSizeClass == .compact ? 40 : 60, height: horizontalSizeClass == .compact ? 40 : 60) // Adjust size for iPad
                                        .shadow(color: isLongPressActivePlus ? Color.blue.opacity(0.8) : Color.clear, radius: isLongPressActivePlus ? 10 : 0)
                                    Image(systemName: "plus")
                                        .font(.system(size: horizontalSizeClass == .compact ? 20 : 30)) // Adjust font size for iPad
                                        .foregroundColor(.white)
                                        .fontWeight(.bold)
                                }
                                .scaleEffect(isLongPressActivePlus ? 1.5 : scaleEffect)
                                .changeEffect(
                                    .spray(origin: UnitPoint(x: 0.5, y: 0.1)) { // Spray water droplets
                                        Image(systemName: "drop.fill")
                                            .foregroundStyle(.blue)
                                    }, value: isSprayActive) // Trigger based on isSprayActive
                            }
                        }
                    }
                    .offset(y: horizontalSizeClass == .compact ? -50 : -400) // Adjust offset for iPad
                }
                .opacity(contentOpacity) // Apply opacity animation
                .blur(radius: contentBlur) // Apply blur animation
                .animation(.easeInOut(duration: 0.5), value: contentOpacity)
                .animation(.easeInOut(duration: 0.5), value: contentBlur)
            }
            .modifier(RippleEffect(at: rippleOrigin, trigger: rippleTrigger))
            .onAppear {
                hapticManager.prepareHaptics()
                fetchCachedImage()
                fetchUserData()
                fetchCountFromFirestore()
                adjustResetTimeForTimeZone()

                withAnimation(.spring(response: 0.6, dampingFraction: 0.5, blendDuration: 0)) {
                    scaleEffect = 1.0
                }
            }
            .onDisappear {
                timer?.invalidate()
            }
            .navigationBarBackButtonHidden(true)
            .navigationBarHidden(true)

            if isShowingProfile {
                Profile(capturedImage: $capturedImage, backgroundError: $backgroundError, username: $username) // Pass username to Profile
                    .transition(.opacity)
                    .zIndex(1)
            }

            if isRetakeMessagePresented {
                ZStack {
                    Color.black.opacity(0.6)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation {
                                isRetakeMessagePresented = false
                            }
                        }
                        .transition(.opacity)
                        .zIndex(1)

                    RetakeMessage(isPresented: $isRetakeMessagePresented, capturedImage: $capturedImage, onPhotoRetaken: { newImage in
                        if let newImage = newImage {
                            capturedImage = newImage
                            replaceOldImageInFirestore(with: newImage)
                        }
                        isRetakeMessagePresented = false
                    })
                    .transition(.move(edge: .bottom))
                    .zIndex(2)
                }
            }

            // LoginDelete presentation with dark background
            if isLoginDeletePresented {
                ZStack {
                    Color.black.opacity(0.6)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation {
                                isLoginDeletePresented = false
                            }
                        }
                        .transition(.opacity)
                        .zIndex(1)

                    LoginDelete(isPresented: $isLoginDeletePresented, username: $username)
                        .transition(.move(edge: .bottom))
                        .zIndex(2)
                }
            }
        }
    }
    
    // Function to fetch the username from Firestore
    private func fetchUserData() {
        guard let userID = userID else { return }
        let firestore = Firestore.firestore()

        firestore.collection("users").document(userID).getDocument { document, error in
            if let document = document, document.exists {
                self.username = document.get("username") as? String ?? "User..."
            } else {
                print("Error fetching username: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }

    // Function to fetch the image from cache or Firebase if it's not cached
    private func fetchCachedImage() {
        let cacheKey = "\(userID ?? "")-profileImage" as NSString

        // Check if the image is already cached
        if let cachedImage = ImageCache.shared.object(forKey: cacheKey) {
            self.capturedImage = cachedImage
        } else {
            // Fetch from Firebase if not cached
            fetchImageFromFirebase { image in
                self.capturedImage = image
                if let image = image {
                    ImageCache.shared.setObject(image, forKey: cacheKey)
                }
            }
        }
    }

    private func fetchImageFromFirebase(completion: @escaping (UIImage?) -> Void) {
        guard let userID = userID else {
            completion(nil)
            return
        }

        let firestore = Firestore.firestore()
        let storage = Storage.storage()

        firestore.collection("users")
            .document(userID)
            .collection("images")
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching documents: \(error.localizedDescription)")
                    completion(nil)
                    return
                }

                guard let documents = snapshot?.documents, let document = documents.first, let imageURL = document.get("url") as? String else {
                    print("No images found")
                    completion(nil)
                    return
                }

                let imageRef = storage.reference(forURL: imageURL)
                imageRef.getData(maxSize: 10 * 1024 * 1024) { data, error in
                    if let error = error {
                        print("Error loading image: \(error.localizedDescription)")
                        completion(nil)
                    } else if let data = data, let image = UIImage(data: data) {
                        completion(image)
                    }
                }
            }
    }

    private func replaceOldImageInFirestore(with newImage: UIImage) {
        guard let userID = userID else { return }
        let firestore = Firestore.firestore()
        let storage = Storage.storage()

        // Fetch the old image URL
        firestore.collection("users")
            .document(userID)
            .collection("images")
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching documents: \(error.localizedDescription)")
                    return
                }

                guard let documents = snapshot?.documents, let document = documents.first, let oldImageURL = document.get("url") as? String else {
                    print("No images found")
                    return
                }

                // Delete the old image from Firebase Storage
                let oldImageRef = storage.reference(forURL: oldImageURL)
                oldImageRef.delete { error in
                    if let error = error {
                        print("Error deleting old image: \(error.localizedDescription)")
                    } else {
                        print("Old image deleted successfully")

                        // Upload the new image
                        FirestoreHelper.uploadImageAndSaveURL(image: newImage) { result in
                            switch result {
                            case .success:
                                print("New image uploaded and URL saved successfully")
                            case .failure(let error):
                                print("Error uploading new image: \(error.localizedDescription)")
                            }
                        }
                    }
                }
            }
    }

    private func saveCountToFirestore() {
        guard let userID = userID else { return }
        let firestore = Firestore.firestore()

        // Get today's date in a specific format
        let today = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: today)

        // Update both the user's count and the calendar for the current date
        let userRef = firestore.collection("users").document(userID)

        userRef.setData([
            "count": count
        ], merge: true) { error in
            if let error = error {
                print("Error saving user count: \(error.localizedDescription)")
            }
        }

        userRef.collection("calendar").document(dateString)
            .setData([
                "count": count,
                "timestamp": FieldValue.serverTimestamp()
            ], merge: true) { error in
                if let error = error {
                    print("Error saving calendar data: \(error.localizedDescription)")
                }
            }
    }

    private func fetchCountFromFirestore() {
        guard let userID = userID else { return }
        let firestore = Firestore.firestore()
        let today = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let todayString = dateFormatter.string(from: today)

        firestore.collection("users")
            .document(userID)
            .collection("calendar")
            .document(todayString)
            .getDocument { document, error in
                if let document = document, document.exists {
                    self.count = document.get("count") as? Int ?? 0
                } else {
                    print("Error fetching count: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
    }

    private func adjustResetTimeForTimeZone() {
        let calendar = Calendar.current
        let now = Date()

        // Define the target time at midnight
        var targetComponents = calendar.dateComponents([.year, .month, .day], from: now)
        targetComponents.hour = 23
        targetComponents.minute = 59
        targetComponents.second = 59

        // Calculate the next midnight
        let targetDate = calendar.nextDate(after: now, matching: targetComponents, matchingPolicy: .nextTime)!

        // Calculate the time interval until the next midnight
        let timeInterval = targetDate.timeIntervalSince(now)

        // Schedule the timer to reset the counter at the next midnight and then every 24 hours
        timer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: false) { _ in
            self.resetCounter()
            self.timer = Timer.scheduledTimer(withTimeInterval: 24 * 60 * 60, repeats: true) { _ in
                self.resetCounter()
            }
        }

        RunLoop.main.add(timer!, forMode: .common)
    }

    private func resetCounter() {
        count = 0
        saveCountToFirestore()
        print("Counter reset at the specified time")
    }
}

class CalendarManager: ObservableObject {
    let userID = Auth.auth().currentUser?.uid
    @Published var currentMonth: Int
    @Published var currentYear: Int
    @Published var daysWithData: Set<Int> = []
    
    init() {
        self.currentMonth = Calendar.current.component(.month, from: Date())
        self.currentYear = Calendar.current.component(.year, from: Date())
        fetchDaysWithData()
    }
    
    func fetchDaysWithData() {
        guard let userID = userID else { return }
        let firestore = Firestore.firestore()
        
        // Fetch all days with data in the current month
        let startOfMonth = String(format: "%04d-%02d-01", currentYear, currentMonth)
        let endOfMonth = String(format: "%04d-%02d-%02d", currentYear, currentMonth, daysInMonth(for: currentMonth, year: currentYear))
        
        firestore.collection("users")
            .document(userID)
            .collection("calendar")
            .whereField("timestamp", isGreaterThanOrEqualTo: Timestamp(date: dateFromString(startOfMonth)))
            .whereField("timestamp", isLessThanOrEqualTo: Timestamp(date: dateFromString(endOfMonth)))
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching days with data: \(error.localizedDescription)")
                    return
                }
                
                // Update the daysWithData set with days that have data
                self.daysWithData = Set(snapshot?.documents.compactMap { document in
                    let date = (document.get("timestamp") as? Timestamp)?.dateValue()
                    let day = Calendar.current.component(.day, from: date ?? Date())
                    return day
                } ?? [])
            }
    }
    
    // Public method to move to the previous month
    func previousMonth() {
        if currentMonth == 1 {
            currentMonth = 12
            currentYear -= 1
        } else {
            currentMonth -= 1
        }
        fetchDaysWithData()
    }

    // Public method to move to the next month
    func nextMonth() {
        if currentMonth == 12 {
            currentMonth = 1
            currentYear += 1
        } else {
            currentMonth += 1
        }
        fetchDaysWithData()
    }

    // Public method to save data at the end of the day
    func saveDataAtEndOfDay(count: Int, image: UIImage?) {
        let calendar = Calendar.current
        let currentDate = Date()
        
        let endOfDay = calendar.date(bySettingHour: 23, minute: 58, second: 0, of: currentDate) ?? currentDate
        let timeInterval = endOfDay.timeIntervalSinceNow
        
        DispatchQueue.main.asyncAfter(deadline: .now() + timeInterval) {
            let day = calendar.component(.day, from: currentDate)
            self.saveDailyData(count: count, image: image, forDay: day)
        }
    }

    func saveDailyData(count: Int, image: UIImage?, forDay day: Int) {
        guard let userID = userID else { return }
        let firestore = Firestore.firestore()
        let storage = Storage.storage()
        let dateString = String(format: "%04d-%02d-%02d", currentYear, currentMonth, day)
        
        if let image = image, let imageData = image.jpegData(compressionQuality: 0.8) {
            let imagePath = "calendar/\(userID)/\(dateString).jpg"
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
                        firestore.collection("users")
                            .document(userID)
                            .collection("calendar")
                            .document(dateString)
                            .setData([
                                "count": count,
                                "imageUrl": downloadURL,
                                "timestamp": FieldValue.serverTimestamp()
                            ]) { error in
                                if let error = error {
                                    print("Error saving daily data: \(error.localizedDescription)")
                                } else {
                                    print("Daily data saved successfully for \(dateString)")
                                    self.daysWithData.insert(day)
                                }
                            }
                    }
                }
            }
        } else {
            firestore.collection("users")
                .document(userID)
                .collection("calendar")
                .document(dateString)
                .setData([
                    "count": count,
                    "timestamp": FieldValue.serverTimestamp()
                ]) { error in
                    if let error = error {
                        print("Error saving daily data: \(error.localizedDescription)")
                    } else {
                        print("Daily data saved successfully for \(dateString)")
                        self.daysWithData.insert(day)
                    }
                }
        }
    }
    
    func daysInMonth(for month: Int, year: Int) -> Int {
        let dateComponents = DateComponents(year: year, month: month)
        let calendar = Calendar.current
        let date = calendar.date(from: dateComponents)!
        return calendar.range(of: .day, in: .month, for: date)!.count
    }
    
    private func dateFromString(_ dateString: String) -> Date {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter.date(from: dateString) ?? Date()
    }
}

struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        let blurEffect = UIBlurEffect(style: style)
        let blurView = UIVisualEffectView(effect: blurEffect)
        return blurView
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
    
    static var light: BlurView {
        return BlurView(style: .light)
    }
    
    static var dark: BlurView {
        return BlurView(style: .dark)
    }
}

struct Profile: View {
    @Binding var capturedImage: UIImage?
    @Binding var backgroundError: String?
    @Binding var username: String // Binding for username
    @StateObject private var calendarManager = CalendarManager()
    @ObservedObject private var userDataManager = UserDataManager.shared
    @State private var timer: Timer?
    @State private var selectedDay: Int? = nil
    @State private var showDetailView: Bool = false
    @State private var count: Int? = nil
    @State private var isShowingHome = false
    @State private var noDataMessage: String? = nil
    @StateObject private var hapticManager = HapticManager()
    @State private var scaleEffect: CGFloat = 0.0
    @State private var calendarOpacity: Double = 1.0 // Add state for opacity
    @State private var calendarBlur: CGFloat = 0.0   // Add state for blur

    let userID = Auth.auth().currentUser?.uid
    let today = Date()
    let currentDay = Calendar.current.component(.day, from: Date())

    @Environment(\.horizontalSizeClass) var horizontalSizeClass // Detect the device size class

    var body: some View {
        ZStack {
            SharedBackgroundView(capturedImage: $capturedImage, backgroundError: $backgroundError)

            VStack {
                UserIcon(username: $username, iconName: "home") {
                    hapticManager.triggerHapticFeedback()
                    withAnimation(.easeInOut(duration: 0.2)) { // Speed up the animation
                        calendarOpacity = 0.0 // Fade out calendar
                        calendarBlur = 20.0   // Blur calendar
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { // Speed up the navigation
                        self.isShowingHome = true
                    }
                }

                VStack {
                    // Calendar UI
                    HStack {
                        Button(action: {
                            calendarManager.previousMonth()
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: horizontalSizeClass == .compact ? 25 : 40)) // Adjust size for iPad
                                .foregroundColor(.white)
                                .padding(.leading, 20)
                                .fontWeight(.bold)
                                .opacity(0.4)
                        }
                        .offset(x: horizontalSizeClass == .compact ? 35 : 50) // Adjust offset for iPad

                        Spacer()

                        Text("\(monthName(for: calendarManager.currentMonth)) \(String(calendarManager.currentYear))")
                            .font(.system(size: horizontalSizeClass == .compact ? 30 : 45, weight: .bold)) // Adjust font size for iPad
                            .foregroundColor(.white)

                        Spacer()

                        Button(action: {
                            calendarManager.nextMonth() // Move to the next month
                        }) {
                            Image(systemName: "chevron.right")
                                .font(.system(size: horizontalSizeClass == .compact ? 25 : 40)) // Adjust size for iPad
                                .foregroundColor(.white)
                                .padding(.trailing, 20)
                                .fontWeight(.bold)
                                .opacity(0.4)
                        }
                        .offset(x: horizontalSizeClass == .compact ? -35 : -50) // Adjust offset for iPad
                    }
                    .padding(.top, horizontalSizeClass == .compact ? 160 : 200) // Adjust top padding for iPad

                    // Calendar grid
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: -80), count: 7), spacing: 20) {
                        ForEach(1...calendarManager.daysInMonth(for: calendarManager.currentMonth, year: calendarManager.currentYear), id: \.self) { day in
                            Text("\(day)")
                                .font(.system(size: horizontalSizeClass == .compact ? 24 : 36, weight: .bold, design: .rounded)) // Adjust font size for iPad
                                .foregroundColor(calendarManager.daysWithData.contains(day) || isCurrentDay(day: day) ? .white : Color.white.opacity(0.3))
                                .frame(width: horizontalSizeClass == .compact ? 32 : 48, height: horizontalSizeClass == .compact ? 40 : 60) // Adjust size for iPad
                                .lineLimit(1)
                                .scaleEffect(day == selectedDay ? 1.2 : 1.0)
                                .onTapGesture {
                                    if calendarManager.daysWithData.contains(day) || isCurrentDay(day: day) {
                                        selectedDay = day
                                        hapticManager.triggerHapticFeedback()

                                        if (!isCurrentDay(day: day)) {
                                            fetchCountFromFirestore(for: day)
                                            withAnimation(.easeInOut(duration: 0.3)) {
                                                showDetailView = true
                                            }
                                        } else {
                                            fetchCountForCurrentDay()
                                            withAnimation(.easeInOut(duration: 0.3)) {
                                                showDetailView = true
                                            }
                                        }
                                    }
                                }
                                .disabled(!calendarManager.daysWithData.contains(day) && !isCurrentDay(day: day))
                        }
                    }
                    .padding(.top, horizontalSizeClass == .compact ? 5 : -20)
                }
                .offset(y: horizontalSizeClass == .compact ? 20 : 400)
                .opacity(calendarOpacity) // Apply opacity animation
                .blur(radius: calendarBlur) // Apply blur animation
                .animation(.easeInOut(duration: 0.2), value: calendarOpacity) // Faster opacity animation
                .animation(.easeInOut(duration: 0.2), value: calendarBlur)    // Faster blur animation
                .scaleEffect(scaleEffect)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.spring(response: 0.7, dampingFraction: 0.5, blendDuration: 0)) {
                            scaleEffect = 1.0
                        }
                    }
                }

                Spacer()
            }

            if showDetailView {
                ZStack {
                    SharedBackgroundView(capturedImage: $capturedImage, backgroundError: $backgroundError)
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showDetailView = false
                            }
                        }

                    VStack {
                        Spacer()

                        // Display the selected month and day
                        if let selectedDay = selectedDay {
                            Text(" \(formattedDate(for: selectedDay))")
                                .font(.system(size: horizontalSizeClass == .compact ? 35 : 50, weight: .bold, design: .rounded)) // Adjust font size for iPad
                                .foregroundColor(.white)
                                .padding(.bottom, horizontalSizeClass == .compact ? 90 : 120) // Adjust padding for iPad
                        }

                        if let image = capturedImage {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: horizontalSizeClass == .compact ? 290 : 450, height: horizontalSizeClass == .compact ? 390 : 600) // Adjust size for iPad
                                .clipShape(RoundedRectangle(cornerRadius: horizontalSizeClass == .compact ? 20 : 30)) // Adjust corner radius for iPad
                                .shadow(radius: 10)
                                .offset(y: horizontalSizeClass == .compact ? -40 : -60) // Adjust offset for iPad
                        }

                        if let count = count {
                            if count > 0 {
                                Text("Finished bottles")
                                    .font(.system(size: horizontalSizeClass == .compact ? 20 : 30, weight: .bold, design: .rounded)) // Adjust font size for iPad
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .opacity(0.6)
                                    .offset(y: horizontalSizeClass == .compact ? 20 : 40) // Adjust offset for iPad

                                Text("\(count)")
                                    .font(.system(size: horizontalSizeClass == .compact ? 80 : 120, weight: .bold, design: .rounded)) // Adjust font size for iPad
                                    .foregroundColor(.white)
                                    .fontWeight(.bold)
                                    .offset(y: horizontalSizeClass == .compact ? 110 : 150) // Adjust offset for iPad
                                    .overlay(
                                        VStack {
                                            Spacer()
                                            Text("\(count)")
                                                .font(.system(size: horizontalSizeClass == .compact ? 80 : 120, weight: .bold, design: .rounded)) // Adjust font size for iPad
                                                .foregroundColor(.white)
                                                .fontWeight(.bold)
                                                .opacity(0.18)
                                                .scaleEffect(y: -1)
                                                .mask(
                                                    LinearGradient(
                                                        gradient: Gradient(colors: [Color.white.opacity(0.5), Color.clear]),
                                                        startPoint: .top,
                                                        endPoint: .bottom
                                                    )
                                                )
                                                .offset(y: horizontalSizeClass == .compact ? 170 : 250) // Adjust offset for iPad
                                        }
                                    )
                                    .offset(y: horizontalSizeClass == .compact ? -90 : -120) // Adjust offset for iPad
                            } else {
                                Text("Nothing drank")
                                    .font(.system(size: horizontalSizeClass == .compact ? 40 : 60, weight: .bold, design: .rounded)) // Adjust font size for iPad
                                    .foregroundColor(.white)
                                    .fontWeight(.bold)
                                    .offset(y: horizontalSizeClass == .compact ? 90 : 120) // Adjust offset for iPad
                            }
                        }

                        Spacer()
                    }
                }
                .transition(.opacity)
            }

            if isShowingHome {
                HomeView(username: $username) // Pass username to HomeView
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            hapticManager.prepareHaptics()
            fetchUserData()
            fetchCountForCurrentDay()
            calendarManager.saveDataAtEndOfDay(count: count ?? 0, image: capturedImage)
        }
        .onDisappear {
            timer?.invalidate()
        }
    }

    // Helper function to format the selected date
    private func formattedDate(for day: Int) -> String {
        let monthName = monthName(for: calendarManager.currentMonth)
        return "\(monthName) \(day)"
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
            } else {
                print("Error fetching count: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }

    private func fetchCountFromFirestore(for day: Int) {
        guard let userID = userID else { return }
        let firestore = Firestore.firestore()
        let dateString = String(format: "%04d-%02d-%02d", calendarManager.currentYear, calendarManager.currentMonth, day)

        firestore.collection("users")
            .document(userID)
            .collection("calendar")
            .document(dateString)
            .getDocument { document, error in
                if let document = document, document.exists {
                    self.count = document.get("count") as? Int
                } else {
                    self.count = 0
                    print("No data for day \(day)")
                }
            }
    }

    private func fetchRecentImage() {
        guard let userID = userID else { return }
        let cacheKey = "\(userID)-profileImage" as NSString

        // Check if the image is cached first
        if let cachedImage = ImageCache.shared.object(forKey: cacheKey) {
            self.capturedImage = cachedImage
        } else {
            // Fetch from Firebase if not cached
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
                                    // Cache the image
                                    ImageCache.shared.setObject(image, forKey: cacheKey)
                                }
                            }
                        }
                    }
                }
        }
    }

    private func isCurrentDay(day: Int) -> Bool {
        let today = Date()
        let calendar = Calendar.current
        let currentDay = calendar.component(.day, from: today)
        let currentMonth = calendar.component(.month, from: today)
        let currentYear = calendar.component(.year, from: today)

        return day == currentDay && calendarManager.currentMonth == currentMonth && calendarManager.currentYear == currentYear
    }
}

#Preview {
    HomeView(username: .constant("")) // Provide a constant username for the preview
}
