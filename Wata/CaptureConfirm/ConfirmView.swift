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

    var body: some View {
        NavigationView {
            ZStack {
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
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

                        // NavigationLink to UsernameView
                        NavigationLink(
                            destination: UsernameView(capturedImage: image).navigationBarBackButtonHidden(true),
                            isActive: $navigateToUsernameView
                        ) {
                            Text("Looks good")
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .font(.system(size: 22))
                                .frame(width: 230, height: 62)
                                .background(Color.black)
                                .cornerRadius(35)
                                .shadow(radius: 5)
                                .scaleEffect(isButtonPressed ? 0.95 : 1.0) // Scale animation
                                .animation(.spring(response: 0.2, dampingFraction: 0.5, blendDuration: 0), value: isButtonPressed)
                                .padding() // Increase touch area
                        }
                        .simultaneousGesture(
                            LongPressGesture(minimumDuration: 0.1)
                                .onChanged { _ in
                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                    isButtonPressed = true
                                }
                                .onEnded { _ in
                                    isButtonPressed = false
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
                                                        // No image found, continue the process to UsernameView
                                                        FirestoreHelper.uploadImageAndSaveURL(image: image) { result in
                                                            isUploading = false
                                                            switch result {
                                                            case .success:
                                                                navigateToUsernameView = true
                                                            case .failure:
                                                                uploadFailed = true
                                                            }
                                                        }
                                                    } else {
                                                        // Image found, navigate to HomeView
                                                        FirestoreHelper.uploadImageAndSaveURL(image: image) { result in
                                                            isUploading = false
                                                            switch result {
                                                            case .success:
                                                                navigateToHomeView = true
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
                                }
                        )
                        .padding(.trailing, 40)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 10)
                }

                // Loading indicator
                if isLoading {
                    Color.black.opacity(0.5).edgesIgnoringSafeArea(.all)
                    ProgressView("Checking for existing images...")
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
                // Navigate to HomeView after retake
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
