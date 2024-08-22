import SwiftUI
import Firebase
import FirebaseStorage
import FirebaseFirestore
import FirebaseAuth

struct FirestoreHelper {
    
    static func uploadImageAndSaveURL(image: UIImage?, completion: @escaping () -> Void) {
        guard let imageData = image?.jpegData(compressionQuality: 0.75) else {
            print("Failed to convert image to JPEG")
            return
        }
        
        guard let userId = Auth.auth().currentUser?.uid else {
            print("No user logged in")
            return
        }

        let storageRef = Storage.storage().reference()
        let imageName = UUID().uuidString + ".jpg" // Ensure unique image name
        let imageRef = storageRef.child("users/\(userId)/images/\(imageName)")

        print("Starting upload to path: users/\(userId)/images/\(imageName)")
        
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
            }
        }
    }

    private static func saveImageURLToFirestore(_ url: String, userId: String, completion: @escaping () -> Void) {
        let firestore = Firestore.firestore()
        firestore.collection("users").document(userId).collection("images").addDocument(data: [
            "url": url,
            "timestamp": Timestamp()
        ]) { error in
            if let error = error {
                print("Error saving URL to Firestore: \(error.localizedDescription)")
            } else {
                print("Image URL successfully saved to Firestore!")
                completion() // Only call this on success
            }
        }
    }
}
