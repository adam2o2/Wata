import SwiftUI
import Firebase
import FirebaseStorage
import FirebaseAuth

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
    @State private var username: String = "Adam"
    @State private var capturedImage: UIImage? = nil
    @State private var timer: Timer?
    @State private var selectedDay: Int? = nil  // State to track the selected day
    @State private var showDetailView: Bool = false  // State to control the visibility of the detail view
    @State private var count: Int = 0  // To match the counter from HomeView
    @State private var isNavigatingToHome = false  // State to handle navigation to HomeView
    @State private var isPressed = false // State to control the bounce effect
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
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 20) {  // Reduced spacing between columns
                    ForEach(1...daysInMonth, id: \.self) { day in
                        Text("\(day)")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(day == currentDay || day == selectedDay ? .white : Color.white.opacity(0.3))
                            .frame(width: 32, height: 40)  // Keep the original width for the numbers
                            .lineLimit(1)  // Ensures the text stays on one line
                            .onTapGesture {
                                selectedDay = day
                                if day == currentDay {  // Check if the current date is selected
                                    fetchCountFromFirestore() // Fetch the latest count
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
                    BlurView(style: .systemMaterialDark)
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
                                .aspectRatio(contentMode: .fit)
                                .cornerRadius(20)
                                .frame(width: 250, height: 300)
                                .padding()
                        }
                        
                        // Display "Finished bottles" label and count
                        Text("Finished bottles")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.top, 20)
                        
                        Text("\(count)")  // Display the dynamic count
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.bottom, 20)
                        
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
            fetchCountFromFirestore()
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
