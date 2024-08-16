import SwiftUI
import AuthenticationServices
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import CoreHaptics

class SignInCoordinator: NSObject, ASAuthorizationControllerPresentationContextProviding, ObservableObject {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return UIApplication.shared.connectedScenes
            .first { $0 is UIWindowScene }
            .flatMap { $0 as? UIWindowScene }?.windows.first { $0.isKeyWindow } ?? ASPresentationAnchor()
    }
}

struct ContentView: View {
    @State private var hapticEngine: CHHapticEngine?
    @State private var isPressed = false
    @State private var isSignedIn = false // State variable to control navigation
    @State private var authError: String?
    @State private var navigateToHome = false // State variable to navigate to HomeView
    @State private var navigateToPrompt = false // State variable to navigate to PromptView
    @StateObject private var signInCoordinator = SignInCoordinator() // Coordinator for sign-in
    private let db = Firestore.firestore() // Firestore instance
    
    // Animation state
    @State private var bounceAnimation = false
    
    var username: String = "User..." // Default value; adjust as needed
    var capturedImage: UIImage? = UIImage(named: "sample_image") // Optional image
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Title and subtitle
                VStack(alignment: .leading, spacing: 5) {
                    Text("Watta")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text("Helping you stay hydrated")
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .offset(y: -120)
                
                // Images with corner radius and white border
                ZStack {
                    ForEach(0..<4) { index in
                        imageForIndex(index)
                            .scaleEffect(bounceAnimation ? 1.0 : 0.7) // Scale effect for bounce
                            .animation(
                                Animation.interpolatingSpring(stiffness: 70, damping: 5)
                                    .delay(Double(index) * 0.2)
                            )
                            .onAppear {
                                if index == 0 { // Start animation only once for the first image
                                    bounceAnimation = true
                                }
                            }
                            .onTapGesture {
                                triggerHapticFeedback()
                                // Trigger bounce animation on tap
                                bounceAnimation = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    bounceAnimation = true
                                }
                            }
                    }
                }
                .frame(width: 170, height: 230)
                
                // Sign in button
                SignInWithAppleButton { request in
                    request.requestedScopes = [.fullName, .email]
                } onCompletion: { result in
                    switch result {
                    case .success(let authResults):
                        switch authResults.credential {
                        case let appleIDCredential as ASAuthorizationAppleIDCredential:
                            // Extract the token and authenticate with Firebase
                            guard let identityToken = appleIDCredential.identityToken else {
                                print("Unable to fetch identity token")
                                return
                            }
                            let tokenString = String(data: identityToken, encoding: .utf8) ?? ""
                            let firebaseCredential = OAuthProvider.credential(withProviderID: "apple.com", idToken: tokenString, rawNonce: "")
                            
                            Auth.auth().signIn(with: firebaseCredential) { authResult, error in
                                if let error = error {
                                    print("Firebase sign in error: \(error.localizedDescription)")
                                    self.authError = error.localizedDescription
                                    return
                                }
                                // User is signed in
                                if let user = authResult?.user {
                                    checkUserInFirestore(uid: user.uid) { exists in
                                        if exists {
                                            self.navigateToHome = true
                                        } else {
                                            saveUserToFirestore(user: user)
                                            self.navigateToPrompt = true // Navigate to PromptView if user is new
                                        }
                                    }
                                }
                            }
                            
                        default:
                            break
                        }
                    case .failure(let error):
                        authError = error.localizedDescription
                        print("Authorization failed: \(error.localizedDescription)")
                    }
                }
                .signInWithAppleButtonStyle(.black)
                .frame(width: 291, height: 62)
                .cornerRadius(40)
                .shadow(radius: 24, x: 0, y: 14)
                .padding(.bottom, 20)
                .offset(y: 150)
                // End sign in button
                
                if let authError = authError {
                    Text("Authorization failed: \(authError)")
                        .foregroundColor(.red)
                }
                
                // NavigationLink to HomeView
                NavigationLink(destination: HomeView().navigationBarBackButtonHidden(true), isActive: $navigateToHome) {
                    EmptyView()
                }
                .isDetailLink(false) // Prevent unintended navigation behavior
                
                // NavigationLink to PromptView
                NavigationLink(destination: PromptView().navigationBarBackButtonHidden(true), isActive: $navigateToPrompt) {
                    EmptyView()
                }
                .isDetailLink(false) // Prevent unintended navigation behavior
            }
            .padding(.vertical, 40)
            .onAppear {
                prepareHaptics()
                checkUserStatus()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private func imageForIndex(_ index: Int) -> some View {
        let images = ["water1", "water2", "water3", "water4"]
        let rotations = [-6.0, 9.0, -25.0, -25.0]
        let offsets = [(-60, 0), (-194, 300), (200, -70), (150, 250)]
        
        return Image(images[index])
            .resizable()
            .frame(width: index == 3 ? 210 : 170, height: index == 3 ? 270 : 230)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white, lineWidth: 4)
            )
            .shadow(radius: 10)
            .rotationEffect(.degrees(rotations[index]))
            .offset(x: CGFloat(offsets[index].0), y: CGFloat(offsets[index].1))
    }
    
    private func prepareHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            hapticEngine = try CHHapticEngine()
            try hapticEngine?.start()
        } catch {
            print("Failed to start haptic engine: \(error.localizedDescription)")
        }
    }
    
    private func triggerHapticFeedback() {
        guard let hapticEngine = hapticEngine else { return }
        let hapticPattern: CHHapticPattern
        do {
            hapticPattern = try CHHapticPattern(events: [
                CHHapticEvent(eventType: .hapticTransient, parameters: [], relativeTime: 0)
            ], parameters: [])
            let player = try hapticEngine.makePlayer(with: hapticPattern)
            try player.start(atTime: 0)
        } catch {
            print("Failed to play haptic feedback: \(error.localizedDescription)")
        }
    }
    
    private func saveUserToFirestore(user: User) {
        guard let imageData = capturedImage?.jpegData(compressionQuality: 0.75) else {
            // No image data, just save user info without image URL
            let userData: [String: Any] = [
                "uid": user.uid,
                "email": user.email ?? "",
                "fullName": user.displayName ?? ""
            ]
            
            db.collection("users").document(user.uid).setData(userData) { error in
                if let error = error {
                    print("Error saving user to Firestore: \(error.localizedDescription)")
                } else {
                    print("User successfully saved to Firestore")
                }
            }
            return
        }

        // Firebase Storage reference
        let storageRef = Storage.storage().reference()
        let imageRef = storageRef.child("users/\(user.uid)/profile.jpg")
        
        // Upload image to Firebase Storage
        imageRef.putData(imageData, metadata: nil) { metadata, error in
            guard metadata != nil else {
                print("Error uploading image: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            // Get the download URL
            imageRef.downloadURL { url, error in
                guard let downloadURL = url else {
                    print("Error getting download URL: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                // Save user data with image URL to Firestore
                let userData: [String: Any] = [
                    "uid": user.uid,
                    "email": user.email ?? "",
                    "fullName": user.displayName ?? "",
                    "imageURL": downloadURL.absoluteString // Save the image URL to Firestore
                ]
                
                db.collection("users").document(user.uid).setData(userData) { error in
                    if let error = error {
                        print("Error saving user to Firestore: \(error.localizedDescription)")
                    } else {
                        print("User and image URL successfully saved to Firestore")
                    }
                }
            }
        }
    }
    
    private func checkUserInFirestore(uid: String, completion: @escaping (Bool) -> Void) {
        let usersRef = db.collection("users").document(uid)
        usersRef.getDocument { document, error in
            if let document = document, document.exists {
                completion(true)
            } else {
                completion(false)
            }
        }
    }
    
    private func checkUserStatus() {
        if let currentUser = Auth.auth().currentUser {
            checkUserInFirestore(uid: currentUser.uid) { exists in
                if exists {
                    self.navigateToHome = true
                }
            }
        }
    }
}
