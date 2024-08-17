import SwiftUI
import Firebase
import FirebaseStorage
import FirebaseAuth

struct Profile: View {
    @State private var username: String = "User..."
    @State private var capturedImage: UIImage? = nil
    @State private var count: Int = 0
    @State private var opacity: Double = 1.0
    @State private var selectedDay: Int? = nil
    @State private var selectedImage: UIImage? = nil
    @State private var selectedCount: Int? = nil
    @State private var timer: Timer?

    let userID = Auth.auth().currentUser?.uid
    let currentDay = Calendar.current.component(.day, from: Date())

    @State private var scrollViewProxy: ScrollViewProxy?
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack {
            VStack(alignment: .center, spacing: 5) {
                Text("\(username)")
                    .font(.system(size: 25))
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .foregroundColor(Color.primary)
                
                Text(getCurrentMonth())
                    .font(.system(size: 28))
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .offset(x: -130, y: 30)
                    .foregroundColor(Color.primary)
                
                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 20) {
                            ForEach(1...daysInCurrentMonth(), id: \.self) { day in
                                ZStack {
                                    Circle()
                                        .fill(day == currentDay ? Color.blue : (day == selectedDay ? Color.blue.opacity(0.5) : Color.clear))
                                        .frame(width: 40, height: 40)
                                    
                                    Text("\(day)")
                                        .font(.system(size: 20))
                                        .fontWeight(.medium)
                                        .foregroundColor(day == currentDay || day == selectedDay ? .white : Color.primary)
                                }
                                .id(day)
                                .onTapGesture {
                                    selectedDay = day
                                    fetchImageForDay(day)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .offset(y: 40)
                    .onAppear {
                        scrollViewProxy = proxy
                        scrollToCurrentDay()
                        schedule11PMSave()
                    }
                }
            }
            .offset(y: 50)

            ZStack {
                GeometryReader { geometry in
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white)
                        .frame(width: 280, height: 390)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white, lineWidth: 4)
                        )
                        .shadow(radius: 10)
                    
                    if let image = selectedImage ?? (selectedDay == currentDay ? capturedImage : nil) {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 280, height: 390)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.white, lineWidth: 4)
                            )
                            .shadow(radius: 10)
                            .transition(.opacity)
                            .animation(.easeInOut(duration: 0.3))
                    }
                }
                .frame(height: 250)
                .offset(x: 67, y: 140)

                // Display the count retrieved for the selected day or current day
                ZStack {
                    if selectedDay == currentDay || selectedDay == nil || (selectedDay != nil && selectedCount != nil) {
                        Circle()
                            .fill(Color.brown.opacity(0.9))
                            .frame(width: 60, height: 60)
                        
                        HStack(spacing: 1) {
                            Text("\(selectedCount ?? count)")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .fontWeight(.bold)
                                .opacity(opacity)
                                .onChange(of: count) { _ in
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                                        opacity = 0.6
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        withAnimation {
                                            opacity = 1.0
                                        }
                                    }
                                }
                                .offset(x: 3)
                            Text("💧")
                                .font(.system(size: 22))
                                .foregroundColor(.white)
                        }
                    }
                }
                .offset(x: -95, y: 360)
            }
            
            Spacer()
            
            HStack {
                NavigationLink(destination: HomeView()) {
                    Image("house2")
                        .resizable()
                        .frame(width: 38, height: 38)
                        .padding()
                        .offset(x: 20)
                }
                Spacer()
                Image("net")
                    .resizable()
                    .frame(width: 38, height: 38)
                    .padding()
                Spacer()
                Image("profile1")
                    .resizable()
                    .frame(width: 38, height: 38)
                    .padding()
                    .offset(x: -20)
            }
            .frame(maxWidth: .infinity)
            .offset(y: -30)
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            fetchUserData()
            fetchCountFromFirestore()
            schedule11PMSave()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    private func fetchUserData() {
        guard let userID = userID else { return }
        let firestore = Firestore.firestore()
        
        firestore.collection("users").document(userID).getDocument { document, error in
            if let document = document, document.exists {
                self.username = document.get("username") as? String ?? "User..."
                self.fetchRecentImage()
            } else {
                print("Error fetching username: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }

    private func fetchCountFromFirestore() {
        guard let userID = userID else { return }
        let firestore = Firestore.firestore()
        firestore.collection("users").document(userID).getDocument { document, error in
            if let document = document, document.exists {
                self.count = document.get("count") as? Int ?? 0
            } else {
                print("Error fetching count: \(error?.localizedDescription ?? "Unknown error")")
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
                                self.selectedImage = image // Immediately display the image
                            }
                        }
                    }
                }
            }
    }

    private func fetchImageForDay(_ day: Int) {
        guard let userID = userID else { return }
        let firestore = Firestore.firestore()
        let storage = Storage.storage()
        
        let month = getCurrentMonth()
        let documentID = "\(month)-\(day)"
        
        firestore.collection("users")
            .document(userID)
            .collection("calendar")
            .document(documentID)
            .getDocument { document, error in
                if let document = document, document.exists {
                    if let imageURL = document.get("imageURL") as? String {
                        let imageRef = storage.reference(forURL: imageURL)
                        imageRef.getData(maxSize: 10 * 1024 * 1024) { data, error in
                            if let data = data, let image = UIImage(data: data) {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    self.selectedImage = image
                                    self.selectedCount = document.get("count") as? Int ?? 0
                                }
                            } else {
                                print("Error loading image data: \(error?.localizedDescription ?? "Unknown error")")
                                self.selectedImage = nil
                                self.selectedCount = nil
                            }
                        }
                    } else {
                        print("No image URL found for this day")
                        self.selectedImage = nil
                        self.selectedCount = nil
                    }
                } else {
                    print("No document found for this day")
                    self.selectedImage = nil
                    self.selectedCount = nil
                }
            }
    }

    private func schedule11PMSave() {
        let now = Date()
        let calendar = Calendar.current
        
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.hour = 23
        components.minute = 0
        components.second = 0

        let elevenPM = calendar.date(from: components)!

        let fireDate = elevenPM > now ? elevenPM : calendar.date(byAdding: .day, value: 1, to: elevenPM)!
        
        timer = Timer(fire: fireDate, interval: 0, repeats: false) { _ in
            self.saveProfileDataToCalendar()
        }
        
        RunLoop.main.add(timer!, forMode: .common)
    }
    
    private func saveProfileDataToCalendar() {
        guard let userID = userID, let image = capturedImage else { return }
        let firestore = Firestore.firestore()
        let storage = Storage.storage()

        let fileName = UUID().uuidString + ".jpg"
        let storageRef = storage.reference().child("calendar_images/\(userID)/\(fileName)")

        if let imageData = image.jpegData(compressionQuality: 0.8) {
            storageRef.putData(imageData, metadata: nil) { metadata, error in
                if let error = error {
                    print("Error uploading image: \(error.localizedDescription)")
                    return
                }

                storageRef.downloadURL { url, error in
                    if let error = error {
                        print("Error getting download URL: \(error.localizedDescription)")
                        return
                    }

                    if let downloadURL = url {
                        let month = self.getCurrentMonth()
                        let day = Calendar.current.component(.day, from: Date())
                        let documentID = "\(month)-\(day)"
                        
                        firestore.collection("users")
                            .document(userID)
                            .collection("calendar")
                            .document(documentID)
                            .setData(["imageURL": downloadURL.absoluteString, "count": self.count], merge: true) { error in
                                if let error = error {
                                    print("Error saving calendar data: \(error.localizedDescription)")
                                } else {
                                    print("Calendar data successfully saved for \(documentID)")
                                }
                            }
                    }
                }
            }
        }
    }
    
    private func scrollToCurrentDay() {
        if let proxy = scrollViewProxy {
            DispatchQueue.main.async {
                proxy.scrollTo(currentDay, anchor: .center)
            }
        }
    }
    
    private func scheduleEndOfDayScroll() {
        let now = Date()
        let calendar = Calendar.current
        let midnight = calendar.startOfDay(for: now).addingTimeInterval(24 * 60 * 60)
        
        timer = Timer(fire: midnight, interval: 0, repeats: true) { _ in
            self.scrollToCurrentDay()
        }
        
        RunLoop.main.add(timer!, forMode: .common)
    }
    
    func getCurrentMonth() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM"
        return dateFormatter.string(from: Date())
    }

    func daysInCurrentMonth() -> Int {
        let calendar = Calendar.current
        let range = calendar.range(of: .day, in: .month, for: Date())!
        return range.count
    }
}

#Preview{
    Profile()
}
