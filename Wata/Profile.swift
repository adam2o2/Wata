import SwiftUI
import Firebase
import FirebaseStorage
import FirebaseAuth

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
    
    private func fetchDaysWithData() {
        guard let userID = userID else { return }
        let firestore = Firestore.firestore()
        let monthName = DateFormatter().monthSymbols[currentMonth - 1]
        
        firestore.collection("users")
            .document(userID)
            .collection("calendar")
            .document(monthName)
            .collection("days")
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching days with data: \(error.localizedDescription)")
                    return
                }
                
                self.daysWithData = Set(snapshot?.documents.compactMap { document in
                    let dayString = document.documentID.components(separatedBy: " ").last
                    return Int(dayString ?? "")
                } ?? [])
            }
    }
    
    func saveDailyData(count: Int, image: UIImage?, forDay day: Int) {
        guard let userID = userID else { return }
        let firestore = Firestore.firestore()
        let storage = Storage.storage()
        let monthName = DateFormatter().monthSymbols[currentMonth - 1]
        let date = "\(monthName) \(day)"
        
        if let image = image, let imageData = image.jpegData(compressionQuality: 0.8) {
            let imagePath = "calendar/\(userID)/\(monthName)/\(date).jpg"
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
                            .document(monthName)
                            .collection("days")
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
                .document(monthName)
                .collection("days")
                .document(date)
                .setData([
                    "count": count,
                    "timestamp": FieldValue.serverTimestamp()
                ]) { error in
                    if let error = error {
                        print("Error saving daily data: \(error.localizedDescription)")
                    } else {
                        print("Daily data saved successfully for \(date)")
                        self.daysWithData.insert(day)
                    }
                }
        }
    }
    
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
    
    func previousMonth() {
        if currentMonth == 1 {
            currentMonth = 12
            currentYear -= 1
        } else {
            currentMonth -= 1
        }
        fetchDaysWithData()
    }
    
    func nextMonth() {
        if currentMonth == 12 {
            currentMonth = 1
            currentYear += 1
        } else {
            currentMonth += 1
        }
        fetchDaysWithData()
    }
}

struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        let blurEffect = UIBlurEffect(style: .regular)
        let blurView = UIVisualEffectView(effect: blurEffect)
        return blurView
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
    
    static var light: BlurView {
        return BlurView(style: .regular)
    }
    
    static var dark: BlurView {
        return BlurView(style: .regular)
    }
}

struct Profile: View {
    @StateObject private var calendarManager = CalendarManager()
    @State private var username: String = ""
    @State private var capturedImage: UIImage? = nil
    @State private var timer: Timer?
    @State private var selectedDay: Int? = nil
    @State private var showDetailView: Bool = false
    @State private var count: Int? = nil
    @State private var isShowingHome = false
    @State private var isPressed = false
    @State private var noDataMessage: String? = nil
    @StateObject private var hapticManager = HapticManager()
    @State private var scaleEffect: CGFloat = 0.0 // Initial scale effect
    @State private var blurAmount: CGFloat = 0.0 // Initial blur amount for animation
    
    let userID = Auth.auth().currentUser?.uid
    let today = Date()
    let currentDay = Calendar.current.component(.day, from: Date())
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            
            if let image = capturedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .edgesIgnoringSafeArea(.all)
            }
            
            BlurView(style: .regular)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                UserIcon(username: $username, iconName: "home") {
                    hapticManager.triggerHapticFeedback()
                    withAnimation(.easeInOut(duration: 0.5)) {
                        blurAmount = 100 // Blur the calendar when transitioning to HomeView
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
                                .font(.system(size: 25))
                                .foregroundColor(.white)
                                .padding(.leading, 20)
                                .fontWeight(.bold)
                                .opacity(0.4)
                        }
                        .offset(x: 35)
                        
                        Spacer()
                        
                        Text("\(monthName(for: calendarManager.currentMonth)) \(String(calendarManager.currentYear))")
                            .font(.system(size: 30, weight: .bold))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Button(action: {
                            calendarManager.nextMonth()
                        }) {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 25))
                                .foregroundColor(.white)
                                .padding(.trailing, 20)
                                .fontWeight(.bold)
                                .opacity(0.4)
                        }
                        .offset(x: -35)
                    }
                    .padding(.top, 160)
                    
                    // Calendar grid
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: -80), count: 7), spacing: 20) {
                        ForEach(1...daysInMonth(for: calendarManager.currentMonth, year: calendarManager.currentYear), id: \.self) { day in
                            Text("\(day)")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(calendarManager.daysWithData.contains(day) || isCurrentDay(day: day) ? .white : Color.white.opacity(0.3))
                                .frame(width: 32, height: 40)
                                .lineLimit(1)
                                .scaleEffect(day == selectedDay ? 1.2 : 1.0)
                                .onTapGesture {
                                    if calendarManager.daysWithData.contains(day) || isCurrentDay(day: day) {
                                        selectedDay = day
                                        hapticManager.triggerHapticFeedback()
                                        
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            selectedDay = day
                                        }
                                        
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
                    .padding(.top, 5)
                }
                .scaleEffect(scaleEffect) // Apply the scale effect to the calendar content
                .blur(radius: blurAmount) // Apply blur effect to the calendar content
                .onAppear {
                    // Delay the scale animation to avoid flicker
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.spring(response: 0.7, dampingFraction: 0.5, blendDuration: 0)) {
                            scaleEffect = 1.0 // Animate to full size
                        }
                    }
                }
                
                Spacer()
            }
            
            if showDetailView {
                ZStack {
                    BlurView(style: .regular)
                        .edgesIgnoringSafeArea(.all)
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showDetailView = false
                            }
                        }
                    
                    VStack {
                        Spacer()
                        
                        if let image = capturedImage {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 290, height: 390)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                .shadow(radius: 10)
                                .offset(y: 5)
                        }
                        
                        if let count = count {
                            if count > 0 {
                                Text("Finished bottles")
                                    .font(.system(size: 20))
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .opacity(0.6)
                                    .offset(y: 70)
                                
                                Text("\(count)")
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
                                                .opacity(0.18)
                                                .scaleEffect(y: -1)
                                                .mask(
                                                    LinearGradient(
                                                        gradient: Gradient(colors: [Color.white.opacity(0.5), Color.clear]),
                                                        startPoint: .top,
                                                        endPoint: .bottom
                                                    )
                                                )
                                                .offset(y: 170)
                                        }
                                    )
                                    .offset(y: -40)
                            } else {
                                Text("Nothing drank")
                                    .font(.system(size: 40))
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
            
            if isShowingHome {
                HomeView()
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
        .gesture(DragGesture().onEnded({ value in
            if value.translation.width < 0 {
                calendarManager.nextMonth()
            } else if value.translation.width > 0 {
                calendarManager.previousMonth()
            }
        }))
    }
    
    private func monthName(for month: Int) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM"
        return dateFormatter.monthSymbols[month - 1]
    }
    
    private func daysInMonth(for month: Int, year: Int) -> Int {
        let dateComponents = DateComponents(year: year, month: month)
        let calendar = Calendar.current
        let date = calendar.date(from: dateComponents)!
        return calendar.range(of: .day, in: .month, for: date)!.count
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
                self.noDataMessage = nil
            } else {
                print("Error fetching count: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }
    
    private func fetchCountFromFirestore(for day: Int) {
        guard let userID = userID else { return }
        let firestore = Firestore.firestore()
        let monthName = DateFormatter().monthSymbols[calendarManager.currentMonth - 1]
        
        firestore.collection("users")
            .document(userID)
            .collection("calendar")
            .document(monthName)
            .collection("days")
            .document("\(monthName) \(day)")
            .getDocument { document, error in
                if let document = document, document.exists {
                    self.count = document.get("count") as? Int
                    self.noDataMessage = nil
                } else {
                    self.count = 0
                    self.noDataMessage = "Nothing drank"
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
    
    private func isSelectedDateValid() -> Bool {
        let calendar = Calendar.current
        return selectedDay != nil && calendarManager.currentMonth == calendar.component(.month, from: today) && calendarManager.currentYear == calendar.component(.year, from: today)
    }
}

#Preview {
    Profile() // Initialize without arguments
}
