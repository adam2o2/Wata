import SwiftUI
import Firebase
import FirebaseStorage
import FirebaseAuth

struct Profile: View {
    @State private var username: String = "User..."
    @State private var capturedImage: UIImage? = nil
    @State private var count: Int = 0
    @State private var opacity: Double = 1.0
    @State private var timer: Timer?

    let userID = Auth.auth().currentUser?.uid
    let currentDay = Calendar.current.component(.day, from: Date())

    var body: some View {
        VStack {
            VStack(alignment: .center, spacing: 5) {
                Text("\(username)")
                    .font(.system(size: 25))
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text(getCurrentMonth())
                    .font(.system(size: 28))
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .offset(x: -60, y: 30)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 30) {
                        ForEach(1...daysInCurrentMonth(), id: \.self) { day in
                            ZStack {
                                if day == currentDay {
                                    Circle()
                                        .fill(Color.blue)
                                        .frame(width: 40, height: 40)
                                }
                                Text("\(day)")
                                    .font(.system(size: 20))
                                    .fontWeight(.medium)
                                    .foregroundColor(day == currentDay ? .white : .black)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .offset(y: 40) // Center the scroll view
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
                    
                    if let image = capturedImage {
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
                            .animation(.easeInOut(duration: 0.3)) // Faster transition duration
                    }
                }
                .frame(height: 250)
                .offset(x: 67, y: 140)

                // Counter formatted similarly to HomeView
                ZStack {
                    Circle()
                        .fill(Color.brown.opacity(0.9))
                        .frame(width: 60, height: 60)
                    
                    HStack(spacing: 1) {
                        Text("\(count)")
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
            fetchCountFromFirestore() // Fetch the count when the view appears
            scheduleEndOfDaySave() // Schedule save operation at the end of the day
        }
        .onDisappear {
            timer?.invalidate() // Invalidate the timer if the view disappears
        }
    }
    
    private func fetchUserData() {
        guard let userID = userID else { return }
        let firestore = Firestore.firestore()
        let storage = Storage.storage()
        
        firestore.collection("users").document(userID).getDocument { document, error in
            if let document = document, document.exists {
                self.username = document.get("username") as? String ?? "User..."
            } else {
                print("Error fetching username: \(error?.localizedDescription ?? "Unknown error")")
            }
        }

        firestore.collection("users")
            .document(userID)
            .collection("images")
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching documents: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents, !documents.isEmpty else {
                    print("No images found")
                    return
                }
                
                if let document = documents.first, let imageURL = document.get("url") as? String {
                    let imageRef = storage.reference(forURL: imageURL)
                    imageRef.getData(maxSize: 10 * 1024 * 1024) { data, error in
                        if let data = data, let image = UIImage(data: data) {
                            withAnimation(.easeInOut(duration: 0.3)) { // Faster transition duration
                                self.capturedImage = image
                            }
                        }
                    }
                } else {
                    print("No URL found in the document")
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
    
    private func scheduleEndOfDaySave() {
        let now = Date()
        let calendar = Calendar.current
        let midnight = calendar.startOfDay(for: now).addingTimeInterval(24 * 60 * 60)
        
        timer = Timer(fire: midnight, interval: 0, repeats: false) { _ in
            self.saveProfileDataToCalendar()
        }
        
        RunLoop.main.add(timer!, forMode: .common)
    }
    
    private func saveProfileDataToCalendar() {
        guard let userID = userID, let image = renderImageWithCounter() else { return }
        let firestore = Firestore.firestore()
        let storage = Storage.storage()

        // Create a unique filename for the image
        let fileName = UUID().uuidString + ".jpg"
        let storageRef = storage.reference().child("calendar_images/\(userID)/\(fileName)")

        // Convert UIImage to JPEG data
        if let imageData = image.jpegData(compressionQuality: 0.8) {
            // Upload the image to Firebase Storage
            storageRef.putData(imageData, metadata: nil) { metadata, error in
                if let error = error {
                    print("Error uploading image: \(error.localizedDescription)")
                    return
                }

                // Get the download URL of the uploaded image
                storageRef.downloadURL { url, error in
                    if let error = error {
                        print("Error getting download URL: \(error.localizedDescription)")
                        return
                    }

                    if let downloadURL = url {
                        // Save the image URL and count in Firestore under the "calendar" collection
                        let month = self.getCurrentMonth()
                        firestore.collection("users")
                            .document(userID)
                            .collection("calendar")
                            .document(month)
                            .setData(["imageURL": downloadURL.absoluteString, "count": self.count], merge: true) { error in
                                if let error = error {
                                    print("Error saving calendar data: \(error.localizedDescription)")
                                } else {
                                    print("Calendar data successfully saved for \(month)")
                                }
                            }
                    }
                }
            }
        }
    }
    
    private func renderImageWithCounter() -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 280, height: 390))
        return renderer.image { context in
            // Draw the captured image
            capturedImage?.draw(in: CGRect(x: 0, y: 0, width: 280, height: 390))
            
            // Draw the counter
            let circleRect = CGRect(x: 20, y: 330, width: 60, height: 60)
            let circlePath = UIBezierPath(ovalIn: circleRect)
            UIColor.brown.withAlphaComponent(0.9).setFill()
            circlePath.fill()
            
            let countText = "\(count) 💧" as NSString
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 20, weight: .bold),
                .foregroundColor: UIColor.white
            ]
            let textSize = countText.size(withAttributes: attributes)
            let textRect = CGRect(
                x: circleRect.midX - textSize.width / 2,
                y: circleRect.midY - textSize.height / 2,
                width: textSize.width,
                height: textSize.height
            )
            countText.draw(in: textRect, withAttributes: attributes)
        }
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
