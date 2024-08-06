import SwiftUI
import AuthenticationServices
import FirebaseAuth
import CoreHaptics
import LocalAuthentication

struct ContentView: View {
    @State private var hapticEngine: CHHapticEngine?
    @State private var isPressed = false
    @State private var isSignedIn = false // State variable to control navigation

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
                    Image("water1")
                        .resizable()
                        .frame(width: 170, height: 230)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white, lineWidth: 4)
                        )
                        .shadow(radius: 10)
                        .rotationEffect(.degrees(-6))
                        .offset(x: -60)

                    Image("water2")
                        .resizable()
                        .frame(width: 170, height: 230)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white, lineWidth: 4)
                        )
                        .shadow(radius: 10)
                        .rotationEffect(.degrees(9))
                        .offset(x: -194, y: 300)

                    Image("water3")
                        .resizable()
                        .frame(width: 170, height: 230)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white, lineWidth: 4)
                        )
                        .shadow(radius: 10)
                        .rotationEffect(.degrees(-25))
                        .offset(x: 200, y: -70)

                    Image("water4")
                        .resizable()
                        .frame(width: 210, height: 270)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white, lineWidth: 4)
                        )
                        .shadow(radius: 10)
                        .rotationEffect(.degrees(-25))
                        .offset(x: 150, y: 250)
                }
                .frame(width: 170, height: 230)

                // Sign in with Apple Button
                SignInWithAppleButton(
                    onRequest: { request in
                        // Request full name and email from the user
                        request.requestedScopes = [.fullName, .email]
                    },
                    onCompletion: { result in
                        switch result {
                        case .success(let authResults):
                            handleAuthorization(authResults: authResults)
                        case .failure(let error):
                            print("Authorization failed: \(error.localizedDescription)")
                        }
                    }
                )
                .signInWithAppleButtonStyle(.black)
                .frame(width: 291, height: 62)
                .cornerRadius(30)
                .scaleEffect(isPressed ? 1.1 : 1.0) // Bounce effect
                .shadow(radius: 10)
                .onTapGesture {
                    withAnimation {
                        isPressed.toggle()
                    }
                    authenticateWithFaceID()
                }
                .padding(.horizontal)
                .offset(y: 150)
                
                // NavigationLink to PromptView
                NavigationLink(destination: PromptView().navigationBarBackButtonHidden(true), isActive: $isSignedIn) {
                    EmptyView()
                }
            }
            .padding(.vertical, 40)
        }
        .onAppear {
            prepareHaptics()
        }
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
            let authorizationCode = appleIDCredential.authorizationCode
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
                // Navigate to next view
                isSignedIn = true
            }
        default:
            break
        }
    }

    private func authenticateWithFaceID() {
        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Authenticate with Face ID to continue."

            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                DispatchQueue.main.async {
                    if success {
                        // Authentication was successful
                        isSignedIn = true
                    } else {
                        // There was a problem
                        print("Authentication failed: \(authenticationError?.localizedDescription ?? "Unknown error")")
                    }
                }
            }
        } else {
            // No biometric authentication available
            print("Biometric authentication not available")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
