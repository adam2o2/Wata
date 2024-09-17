import SwiftUI
import UIKit
import Firebase
import FirebaseStorage
import FirebaseFirestore
import FirebaseAuth

struct ConfirmView: View {
    var image: UIImage?
    var onRetake: () -> Void

    @State private var navigateToUsernameView = false
    @State private var navigateToHomeView = false // State for HomeView navigation
    @State private var isButtonPressed = false
    @State private var isRetakeActive = false
    @State private var isUploading = false // State to manage upload status
    @State private var uploadFailed = false
    @State private var isRetakeProcess = false // Flag for retake process
    @State private var isLoading = false // State for loading
    @State private var username: String = "" // Add state for username
    @State private var isProgressVisible = false // State for showing ProgressView when image is found

    var body: some View {
        NavigationView {
            ZStack {
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill) // Keeps fill but adjusts centering
                        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height) // Ensures it covers the screen
                        .clipped() // Ensures no overflow beyond the screen edges
                        .edgesIgnoringSafeArea(.all)

                } else {
                    Color.black.edgesIgnoringSafeArea(.all)
                }

                VStack {
                    Spacer()
                    HStack {
                        // Button for retaking the photo
                        Button(action: {
                            isRetakeActive = true
                            isRetakeProcess = true // Mark this as a retake process
                        }) {
                            Image(systemName: "arrow.clockwise")
                                .resizable()
                                .frame(width: 32, height: 38)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.black)
                                .clipShape(Circle())
                                .shadow(radius: 5)
                        }
                        .padding(.leading, 40)

                        Spacer()

                        // Looks good button
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            isButtonPressed = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                isButtonPressed = false
                            }
                            if !isUploading && !uploadFailed {
                                isLoading = true // Start loading
                                isUploading = true // Prevent multiple uploads

                                // Fetch existing images to check if an image already exists
                                if let userId = Auth.auth().currentUser?.uid {
                                    FirestoreHelper.fetchUserImages(userId: userId) { result in
                                        isLoading = false // Stop loading when query completes
                                        switch result {
                                        case .success(let urls):
                                            if urls.isEmpty {
                                                // No image found, navigate to UsernameView
                                                FirestoreHelper.uploadImageAndSaveURL(image: image) { result in
                                                    isUploading = false
                                                    switch result {
                                                    case .success:
                                                        navigateToUsernameView = true // Navigate to UsernameView
                                                    case .failure:
                                                        uploadFailed = true
                                                    }
                                                }
                                            } else {
                                                // Image found, show ProgressView and then navigate to HomeView
                                                isProgressVisible = true
                                                FirestoreHelper.uploadImageAndSaveURL(image: image) { result in
                                                    isUploading = false
                                                    switch result {
                                                    case .success:
                                                        // Delay navigation to HomeView to simulate progress completion
                                                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                                            navigateToHomeView = true // Navigate to HomeView
                                                        }
                                                    case .failure:
                                                        uploadFailed = true
                                                    }
                                                }
                                            }
                                        case .failure(let error):
                                            isLoading = false // Stop loading if there's an error
                                            print("Failed to fetch user images: \(error.localizedDescription)")
                                            uploadFailed = true
                                        }
                                    }
                                } else {
                                    uploadFailed = true // If there's no user, fail the upload
                                }
                            }
                        }) {
                            Text("Looks good")
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .frame(width: 230, height: 62)
                                .background(Color.black)
                                .cornerRadius(35)
                                .shadow(radius: 5)
                                .scaleEffect(isButtonPressed ? 0.95 : 1.0) // Scale animation
                                .animation(.spring(response: 0.2, dampingFraction: 0.5, blendDuration: 0), value: isButtonPressed)
                                .padding() // Increase touch area
                        }
                        .padding(.trailing, 40)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 40)
                }

                // Loading indicator or ProgressView
                if isProgressVisible {
                    Color.black.opacity(0.5).edgesIgnoringSafeArea(.all)
                    ProgressView("")
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                        .foregroundColor(.white)
                } else if isLoading {
                    Color.black.opacity(0.5).edgesIgnoringSafeArea(.all)
                    ProgressView("")
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                        .foregroundColor(.white)
                }
            }
            .background(
                // Navigation for retake process to CameraView and later to HomeView
                NavigationLink(destination: CameraView().edgesIgnoringSafeArea(.all), isActive: $isRetakeActive) {
                    EmptyView()
                }
            )
            .background(
                // Navigate to UsernameView
                NavigationLink(destination: UsernameView(capturedImage: image).navigationBarBackButtonHidden(true), isActive: $navigateToUsernameView) {
                    EmptyView()
                }
            )
            .background(
                // Navigate to HomeView after showing progress
                NavigationLink(destination: HomeView(username: $username).navigationBarBackButtonHidden(true), isActive: $navigateToHomeView) { // Pass username to HomeView
                    EmptyView()
                }
            )
            .alert(isPresented: $uploadFailed) {
                Alert(
                    title: Text("Upload Failed"),
                    message: Text("There was an issue uploading your image. Please try again."),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
        .navigationViewStyle(StackNavigationViewStyle()) // Ensure consistent navigation behavior across platforms
    }
}

struct ConfirmView_Previews: PreviewProvider {
    static var previews: some View {
        ConfirmView(
            image: UIImage(named: "placeholder"), // Use a sample or placeholder image
            onRetake: {}
        )
    }
}
