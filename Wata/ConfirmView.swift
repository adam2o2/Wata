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
    @State private var isUploading = false // State to manage upload status
    @State private var uploadFailed = false

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
                                    if !isUploading && !uploadFailed {
                                        isUploading = true // Prevent multiple uploads
                                        uploadImageAndSaveURL {
                                            navigateToUsernameView = true
                                            isUploading = false
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
                NavigationLink(destination: CameraView(), isActive: $isRetakeActive) {
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

    private func uploadImageAndSaveURL(completion: @escaping () -> Void) {
        guard let imageData = image?.jpegData(compressionQuality: 0.75) else {
            print("Failed to convert image to JPEG")
            uploadFailed = true
            return
        }
        
        guard let userId = Auth.auth().currentUser?.uid else {
            print("No user logged in")
            uploadFailed = true
            return
        }

        let storageRef = storage.reference()
        let imageName = UUID().uuidString + ".jpg" // Ensure unique image name
        let imageRef = storageRef.child("users/\(userId)/images/\(imageName)")

        print("Starting upload to path: users/\(userId)/images/\(imageName)")
        
        let uploadTask = imageRef.putData(imageData, metadata: nil) { metadata, error in
            guard let _ = metadata, error == nil else {
                print("Upload error: \(error?.localizedDescription ?? "Unknown error")")
                uploadFailed = true
                isUploading = false
                return
            }

            imageRef.downloadURL { url, error in
                guard let downloadURL = url, error == nil else {
                    print("Error fetching download URL: \(error?.localizedDescription ?? "Unknown error")")
                    uploadFailed = true
                    isUploading = false
                    return
                }

                saveImageURLToFirestore(downloadURL.absoluteString, userId: userId, completion: completion)
            }
        }

        uploadTask.observe(.progress) { snapshot in
            let percentComplete = Double(snapshot.progress!.completedUnitCount) / Double(snapshot.progress!.totalUnitCount)
            print("Upload is \(percentComplete * 100)% complete")
        }

        uploadTask.observe(.success) { snapshot in
            print("Upload completed successfully")
        }

        uploadTask.observe(.failure) { snapshot in
            if let error = snapshot.error {
                print("Upload failed with error: \(error.localizedDescription)")
                uploadFailed = true
                isUploading = false
            }
        }
    }

    private func saveImageURLToFirestore(_ url: String, userId: String, completion: @escaping () -> Void) {
        firestore.collection("users").document(userId).collection("images").addDocument(data: [
            "url": url,
            "timestamp": Timestamp()
        ]) { error in
            if let error = error {
                print("Error saving URL to Firestore: \(error.localizedDescription)")
                uploadFailed = true
            } else {
                print("Image URL successfully saved to Firestore!")
                completion() // Only call this on success
            }
            isUploading = false // Reset isUploading state regardless of success or failure
        }
    }
}
