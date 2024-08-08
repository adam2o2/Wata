import SwiftUI
import AuthenticationServices
import Firebase
import FirebaseAuth
import FirebaseFirestore
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
    @StateObject private var signInCoordinator = SignInCoordinator() // Coordinator for sign-in
    private let db = Firestore.firestore() // Firestore instance
    
    // Animation state
    @State private var bounceAnimation = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Title and subtitle
                VStack(alignment: .leading, spacing: 5) {
                    Text("Wata")
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
                                self.isSignedIn = true
                                
                                if let user = authResult?.user {
                                    // Save the user to Firestore
                                    saveUserToFirestore(user: user)
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
                // NavigationLink to PromptView
                NavigationLink(destination: PromptView().navigationBarBackButtonHidden(true), isActive: $isSignedIn) {
                    EmptyView()
                }
            }
            .padding(.vertical, 40)
            .onAppear {
                prepareHaptics()
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
    
    private func handleAuthorization(authResults: ASAuthorization) {
        switch authResults.credential {
        case let appleIDCredential as ASAuthorizationAppleIDCredential:
            let userID = appleIDCredential.user
            let identityToken = appleIDCredential.identityToken
            let email = appleIDCredential.email
            
            // Send these to Firebase
            let idTokenString = String(data: identityToken ?? Data(), encoding: .utf8) ?? ""
            let authCredential = OAuthProvider.credential(withProviderID: "apple.com", idToken: idTokenString, rawNonce: "")
            
            Auth.auth().signIn(with: authCredential) { (authResult, error) in
                if let error = error {
                    print("Firebase sign-in error: \(error.localizedDescription)")
                    return
                }
                // User is signed in
                guard let user = Auth.auth().currentUser else {
                    print("No authenticated user found.")
                    return
                }
                
                // Save user data to Firestore
                let userData: [String: Any] = [
                    "userID": userID,
                    "email": email ?? "",
                    "displayName": user.displayName ?? ""
                ]
                
                db.collection("users").document(user.uid).setData(userData) { err in
                    if let err = err {
                        print("Error adding document: \(err)")
                    } else {
                        print("Document successfully written!")
                    }
                }
                
                // Navigate to the next view
                isSignedIn = true
            }
        default:
            break
        }
        
    }
}
private func saveUserToFirestore(user: User) {
    let db = Firestore.firestore()
    let usersRef = db.collection("users")
    
    let userData: [String: Any] = [
        "uid": user.uid,
        "email": user.email ?? "",
        "fullName": user.displayName ?? ""
    ]
    
    usersRef.document(user.uid).setData(userData) { error in
        if let error = error {
            print("Error saving user to Firestore: \(error.localizedDescription)")
        } else {
            print("User successfully saved to Firestore")
        }
    }
}

#Preview{
    ContentView()
}
