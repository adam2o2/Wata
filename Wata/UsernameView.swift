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

    var body: some View {
        NavigationView {
            VStack {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Create a username")
                        .font(.system(size: 35))
                        .fontWeight(.bold)
                        .offset(x: 10)

                    Text("Please make it under 10 characters")
                        .font(.system(size: 20))
                        .foregroundColor(Color(red: 0.8, green: 0.8, blue: 0.8))
                        .fontWeight(.bold)
                        .offset(y: -4)
                }
                .padding(.horizontal, 10)
                .padding(.top, 70)

                Spacer()

                VStack {
                    Spacer().frame(height: 230) // Adjust this value to move the ZStack down

                    ZStack {
                        Rectangle()
                            .fill(Color(hex: "#EDEDED"))
                            .frame(width: 270, height: 80)
                            .cornerRadius(20)

                        TextField("Enter Username", text: $username)
                            .padding()
                            .frame(width: 270, height: 60)
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

                NavigationLink(destination: HomeView(username: username, capturedImage: capturedImage), isActive: $isActive) {
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
                                .font(.system(size: 20))
                        }
                        .padding()
                        .frame(width: 291, height: 62)
                        .background(Color.black)
                        .cornerRadius(30)
                        .scaleEffect(isPressed ? 1.1 : 1.0)
                        .shadow(radius: 10)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .onTapGesture {
                        withAnimation {
                            isPressed.toggle()
                        }
                    }
                    .offset(y: -30)

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
    }
}
