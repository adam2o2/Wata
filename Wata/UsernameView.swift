import SwiftUI
import Combine
import Firebase
import FirebaseFirestore
import FirebaseAuth

class FirestoreManager {
    private let db = Firestore.firestore()

    func createOrUpdateUser(userID: String, username: String) {
        let userRef = db.collection("users").document(userID)
        let userData: [String: Any] = [
            "username": username,
            "createdAt": Timestamp()
        ]

        userRef.setData(userData, merge: true) { error in
            if let error = error {
                print("Error setting document: \(error)")
            } else {
                print("Document set successfully")
            }
        }
    }
}

class KeyboardObserver: ObservableObject {
    @Published var isKeyboardVisible: Bool = false
    private var cancellables = Set<AnyCancellable>()

    init() {
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .map { _ in true }
            .merge(with: NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
                .map { _ in false })
            .assign(to: \.isKeyboardVisible, on: self)
            .store(in: &cancellables)
    }
}

struct UsernameView: View {
    @State private var isPressed = false
    @State private var username: String = ""
    @State private var isActive = false
    @ObservedObject private var keyboardObserver = KeyboardObserver()
    var capturedImage: UIImage?
    private let firestoreManager = FirestoreManager()

    @Environment(\.colorScheme) var colorScheme
    @Environment(\.horizontalSizeClass) var horizontalSizeClass // Detect the device's size class

    var body: some View {
        NavigationView {
            ZStack {
                // Blurred background image
                if let image = capturedImage {
                    Image(uiImage: image)
                        .resizable()
                        .frame(width: horizontalSizeClass == .compact ? 500 : 1100, height: horizontalSizeClass == .compact ? 950 : 1500) // Adjust frame size for iPad
                        .aspectRatio(contentMode: .fill)
                        .ignoresSafeArea()
                        .blur(radius: 20) // Applying blur to background
                } else {
                    Color.gray // Fallback color if image is nil
                        .ignoresSafeArea()
                }

                VStack {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Create a username")
                            .font(.system(size: horizontalSizeClass == .compact ? 35 : 45, weight: .bold, design: .rounded)) // Adjust font size for iPad
                            .foregroundColor(.white)
                            .fontWeight(.bold)
                            .offset(x: 10)

                        Text("Please make it under 10 characters")
                            .font(.system(size: horizontalSizeClass == .compact ? 20 : 25, weight: .bold, design: .rounded)) // Adjust font size for iPad
                            .foregroundColor(.white)
                            .fontWeight(.bold)
                            .opacity(0.4)
                            .offset(y: -4)
                    }
                    .padding(.horizontal, 10)
                    .padding(.top, horizontalSizeClass == .compact ? 110 : 160) // Adjust top padding for iPad

                    Spacer()

                    VStack {
                        Spacer().frame(height: horizontalSizeClass == .compact ? 230 : 350) // Adjust this value to move the ZStack down

                        ZStack {
                            Rectangle()
                                .fill(Color.white.opacity(0.3)) // Set the opacity level (0.0 to 1.0)
                                .frame(width: horizontalSizeClass == .compact ? 270 : 400, height: horizontalSizeClass == .compact ? 80 : 100) // Adjust size for iPad
                                .cornerRadius(20)

                            TextField("Enter Username", text: $username)
                                .padding()
                                .frame(width: horizontalSizeClass == .compact ? 270 : 400, height: horizontalSizeClass == .compact ? 60 : 80) // Adjust size for iPad
                                .foregroundColor(.white)
                                .cornerRadius(20)
                                .fontWeight(.bold)
                                .multilineTextAlignment(.center)
                                .onChange(of: username) { newValue in
                                    if newValue.count > 10 {
                                        username = String(newValue.prefix(10))
                                    }
                                }
                        }

                        Spacer() // Keeps the ZStack vertically centered if needed
                    }

                    Spacer()
                        .padding(.top) // You can adjust this value to control spacing

                    NavigationLink(destination: HomeView(username: $username).navigationBarBackButtonHidden(true), isActive: $isActive) { // Pass username to HomeView
                        EmptyView()
                    }

                    if !keyboardObserver.isKeyboardVisible {
                        Button(action: {
                            withAnimation {
                                isActive = true
                            }
                            triggerHapticFeedback()
                            saveUserData()
                        }) {
                            HStack {
                                Text("Continue")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .font(.system(size: horizontalSizeClass == .compact ? 20 : 28)) // Adjust font size for iPad
                            }
                            .padding()
                            .frame(width: horizontalSizeClass == .compact ? 291 : 400, height: horizontalSizeClass == .compact ? 62 : 80) // Adjust button size for iPad
                            .background(.black)
                            .cornerRadius(50)
                            .scaleEffect(isPressed ? 1.1 : 1.0)
                            .shadow(radius: 10)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .onTapGesture {
                            withAnimation {
                                isPressed.toggle()
                            }
                        }
                        .offset(y: horizontalSizeClass == .compact ? -90 : -150) // Adjust button position for iPad
                    }
                }
                .onAppear {
                    prepareHaptics()
                }
                .navigationBarBackButtonHidden(true)
                .navigationBarHidden(true)
            }
            .navigationViewStyle(StackNavigationViewStyle())
        }
    }

    private func prepareHaptics() {
        // Prepare haptic feedback
    }

    private func triggerHapticFeedback() {
        // Trigger haptic feedback
    }

    private func saveUserData() {
        if let userID = getUserID() {
            firestoreManager.createOrUpdateUser(userID: userID, username: username)
        } else {
            print("UserID is nil")
        }
    }

    private func getUserID() -> String? {
        return Auth.auth().currentUser?.uid
    }
}

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        scanner.scanLocation = 1
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)

        let red = Double((rgb >> 16) & 0xFF) / 255.0
        let green = Double((rgb >> 8) & 0xFF) / 255.0
        let blue = Double(rgb & 0xFF) / 255.0

        self.init(red: red, green: green, blue: blue)
    }
}

struct UsernameView_Previews: PreviewProvider {
    static var previews: some View {
        UsernameView(capturedImage: UIImage(named: "sample_image"))
            .preferredColorScheme(.dark) // Preview in dark mode
    }
}
