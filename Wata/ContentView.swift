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
    @State private var navigateToPrompt = false // State variable to navigate to Prompt1
    @State private var navigateToCameraView = false // New state variable for CameraViewController navigation
    @StateObject private var signInCoordinator = SignInCoordinator() // Coordinator for sign-in
    private let db = Firestore.firestore() // Firestore instance
    
    // Animation state
    @State private var bounceAnimation = false
    
    // Loading spinner state
    @State private var isLoading = true
    
    @State private var username: String = "Username" // Default value for username
    var capturedImage: UIImage? = UIImage(named: "sample_image") // Optional image
    
    @State private var homeViewID = UUID() // State variable to refresh HomeView
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass // Detect device size class
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background image with blur effect
                Image("water1")
                    .resizable()
                    .aspectRatio(contentMode: .fill)  // Make sure the image fills the frame
                    .frame(width: horizontalSizeClass == .compact ? 500 : 1100, height: horizontalSizeClass == .compact ? 950 : 1500) // Adjust frame size based on device
                    .ignoresSafeArea()
                    .blur(radius: 20) // Applying blur to background
                
                if isLoading {
                    VStack {
                        ProgressView("") // Loading spinner
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(2.0)
                        Text("")
                            .padding(.top, 20)
                    }
                } else {
                    VStack(spacing: 20) {
                        // Title and subtitle
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Watta")
                                .font(.system(size: horizontalSizeClass == .compact ? 36 : 68, weight: .bold, design: .rounded)) // Adjust font size for iPad
                                .frame(width: horizontalSizeClass == .compact ? 350 : 500)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .offset(y: horizontalSizeClass == .compact ? 120 : 180)

                            Text("Helping you stay hydrated")
                                .font(.system(size: horizontalSizeClass == .compact ? 18 : 34, weight: .bold, design: .rounded)) // Adjust font size for iPad
                                .frame(width: horizontalSizeClass == .compact ? 350 : 500)
                                .multilineTextAlignment(.center)
                                .offset(x: horizontalSizeClass == .compact ? 65 : 120, y: horizontalSizeClass == .compact ? 130 : 190)
                                .foregroundColor(.white)
                                .opacity(0.4)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .offset(x: horizontalSizeClass == .compact ? -70 : 50, y: horizontalSizeClass == .compact ? -250 : -350)
                        
                        // Image with corner radius and white border
                        ZStack {
                            imageForIndex(0)
                                .scaleEffect(bounceAnimation ? 1.0 : 0.7) // Scale effect for bounce
                                .animation(
                                    Animation.interpolatingSpring(stiffness: 70, damping: 5)
                                )
                                .onAppear {
                                    bounceAnimation = true
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
                        .frame(width: horizontalSizeClass == .compact ? 170 : 300, height: horizontalSizeClass == .compact ? 230 : 400) // Adjust size for iPad
                        
                        // Sign in button
                        SignInWithAppleButton { request in
                            request.requestedScopes = [.email] // Removed fullName
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
                                    
                                    print("User is signing in") // Print statement added here
                                    
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
                                                    self.checkIfUserHasImage(uid: user.uid) { hasImage in
                                                        if hasImage {
                                                            self.homeViewID = UUID() // Change the ID to refresh HomeView
                                                            self.navigateToHome = true
                                                        } else {
                                                            self.navigateToCameraView = true // Navigate to CameraViewController if no image found
                                                        }
                                                    }
                                                } else {
                                                    saveUserToFirestore(user: user)
                                                    self.navigateToPrompt = true // Navigate to Prompt1 if user is new
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
                        .frame(width: horizontalSizeClass == .compact ? 291 : 500, height: horizontalSizeClass == .compact ? 62 : 100) // Adjust size for iPad
                        .cornerRadius(50)
                        .shadow(radius: 24, x: 0, y: 14)
                        .padding(.bottom, 20)
                        .offset(y: horizontalSizeClass == .compact ? 210 : 240)
                        // End sign in button
                        
                        if let authError = authError {
                            Text("Authorization failed: \(authError)")
                                .foregroundColor(.red)
                        }
                        
                        // NavigationLink to HomeView
                        NavigationLink(destination: HomeView(username: $username)
                                        .navigationBarBackButtonHidden(true)
                                        .id(homeViewID), // Add .id modifier to refresh HomeView
                                       isActive: $navigateToHome) { // Pass username to HomeView
                            EmptyView()
                        }
                        .isDetailLink(false) // Prevent unintended navigation behavior
                        
                        // NavigationLink to Prompt1
                        NavigationLink(destination: Prompt1().navigationBarBackButtonHidden(true), isActive: $navigateToPrompt) { // Changed to Prompt1
                            EmptyView()
                        }
                        .isDetailLink(false) // Prevent unintended navigation behavior
                        
                        // NavigationLink to CameraViewContainer
                        NavigationLink(destination: CameraViewContainer()
                                            .navigationBarBackButtonHidden(true)
                                            .ignoresSafeArea(.all) // Ignore safe area edges
                                       , isActive: $navigateToCameraView) {
                            EmptyView()
                        }
                        .isDetailLink(false) // Prevent unintended navigation behavior

                    }
                    .padding(.vertical, 40)
                }
            }
            .onAppear {
                prepareHaptics()
                checkUserStatus()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private func imageForIndex(_ index: Int) -> some View {
        let images = ["water1"]
        let rotations = [0.0]
        let offsets = horizontalSizeClass == .compact ? [(0, 40)] : [(0, 40)] // Adjust offsets for iPad
        
        return Image(images[index])
            .resizable()
            .aspectRatio(contentMode: .fill) // Ensures the image fills the frame
            .frame(width: horizontalSizeClass == .compact ? 230 : 400, height: horizontalSizeClass == .compact ? 360 : 660) // Adjust frame size for iPad
            .clipShape(RoundedRectangle(cornerRadius: 20))
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
                "email": user.email ?? ""
                // Removed fullName
            ]
            
            db.collection("users").document(user.uid).setData(userData) { error in
                if let error = error {
                    print("Error saving user to Firestore without image: \(error.localizedDescription)")
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
            if let error = error {
                print("Error uploading image: \(error.localizedDescription)")
                return
            }
            print("Image uploaded successfully with metadata: \(metadata.debugDescription)")
            
            // Get the download URL
            imageRef.downloadURL { url, error in
                if let error = error {
                    print("Error getting download URL: \(error.localizedDescription)")
                    return
                }
                
                guard let downloadURL = url else {
                    print("Download URL is nil")
                    return
                }
                
                // Save user data with image URL to Firestore
                let userData: [String: Any] = [
                    "uid": user.uid,
                    "email": user.email ?? "",
                    // Removed fullName
                    "imageURL": downloadURL.absoluteString // Save the image URL to Firestore
                ]
                
                db.collection("users").document(user.uid).setData(userData) { error in
                    if let error = error {
                        print("Error saving user with image URL to Firestore: \(error.localizedDescription)")
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
    
    // New function to check if the user has an image in the "images" subcollection
    private func checkIfUserHasImage(uid: String, completion: @escaping (Bool) -> Void) {
        let imagesRef = db.collection("users").document(uid).collection("images")
        imagesRef.getDocuments { snapshot, error in
            if let snapshot = snapshot, !snapshot.isEmpty {
                completion(true) // Image found, return true
            } else {
                completion(false) // No image found, return false
            }
        }
    }
    
    private func checkUserStatus() {
        if let currentUser = Auth.auth().currentUser {
            print("User is logged in: \(currentUser.uid)")
            checkUserInFirestore(uid: currentUser.uid) { exists in
                if exists {
                    self.checkIfUserHasImage(uid: currentUser.uid) { hasImage in
                        if hasImage {
                            self.navigateToHome = true
                        } else {
                            self.navigateToCameraView = true
                        }
                    }
                }
                self.isLoading = false // Hide spinner once check is done
            }
        } else {
            print("No user is logged in")
            self.isLoading = false // Hide spinner if no user is signed in
        }
    }
}

#Preview {
    ContentView()
}
