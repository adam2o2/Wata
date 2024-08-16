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
    @State private var isButtonPressed = false
    @State private var isRetakeActive = false

    private let storage = Storage.storage()
    private let firestore = Firestore.firestore()

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
                                    uploadImageAndSaveURL() // Upload image when button is pressed
                                    navigateToUsernameView = true
                                }
                        )
                        .padding(.trailing, 40)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 10)
                }
            }
            .background(
                NavigationLink(destination: CameraView(), isActive: $isRetakeActive) {
                    EmptyView()
                }
            )
        }
        .navigationViewStyle(StackNavigationViewStyle()) // Ensure consistent navigation behavior across platforms
    }

    private func uploadImageAndSaveURL() {
        guard let imageData = image?.jpegData(compressionQuality: 0.75) else { return }
        
        guard let userId = Auth.auth().currentUser?.uid else {
            print("No user logged in")
            return
        }

        let storageRef = storage.reference()
        let imageName = UUID().uuidString + ".jpg" // Ensure unique image name
        let imageRef = storageRef.child("users/\(userId)/images/\(imageName)")

        let uploadTask = imageRef.putData(imageData, metadata: nil) { metadata, error in
            guard let _ = metadata, error == nil else {
                print("Upload error: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            imageRef.downloadURL { url, error in
                guard let downloadURL = url, error == nil else {
                    print("Error fetching download URL: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }

                // Save the image URL to Firestore
                firestore.collection("users").document(userId).collection("images").addDocument(data: [
                    "url": downloadURL.absoluteString,
                    "timestamp": Timestamp()
                ]) { error in
                    if let error = error {
                        print("Error saving URL to Firestore: \(error.localizedDescription)")
                    } else {
                        print("Image URL successfully saved to Firestore!")
                    }
                }
            }
        }
    }
}

// Preview for ConfirmView
struct ConfirmView_Previews: PreviewProvider {
    static var previews: some View {
        ConfirmView(
            image: UIImage(named: "sample_image"),
            onRetake: { print("Retake action") }
        )
    }
}
