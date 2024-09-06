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
    @State private var navigateToHomeView = false // New state for HomeView navigation
    @State private var isButtonPressed = false
    @State private var isRetakeActive = false
    @State private var isUploading = false // State to manage upload status
    @State private var uploadFailed = false
    @State private var isRetakeProcess = false // New flag for retake process

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
                                        isUploading = true // Prevent multiple uploads
                                        FirestoreHelper.uploadImageAndSaveURL(image: image) { result in
                                            isUploading = false
                                            switch result {
                                            case .success:
                                                if isRetakeProcess {
                                                    navigateToHomeView = true // Navigate to HomeView for retake process
                                                } else {
                                                    navigateToUsernameView = true // Navigate to UsernameView for new user
                                                }
                                            case .failure:
                                                uploadFailed = true
                                            }
                                        }
                                    }
                                }
                        )
                        .padding(.trailing, 40)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 10)
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
                NavigationLink(destination: HomeView().navigationBarBackButtonHidden(true), isActive: $navigateToHomeView) {
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
