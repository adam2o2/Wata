import SwiftUI
import Firebase
import FirebaseStorage
import FirebaseFirestore
import FirebaseAuth

struct FirestoreHelper {
    
    static func uploadImageAndSaveURL(image: UIImage?, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let imageData = image?.jpegData(compressionQuality: 0.5) else {
            completion(.failure(NSError(domain: "ImageError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to JPEG"])))
            return
        }
        
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(.failure(NSError(domain: "AuthError", code: 0, userInfo: [NSLocalizedDescriptionKey: "No user logged in"])))
            return
        }

        let storageRef = Storage.storage().reference()
        let imageName = UUID().uuidString + ".jpg"
        let imageRef = storageRef.child("users/\(userId)/images/\(imageName)")

        print("Starting upload to path: users/\(userId)/images/\(imageName)")
        
        let uploadTask = imageRef.putData(imageData, metadata: nil) { metadata, error in
            if let error = error {
                print("Upload failed with error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }

            imageRef.downloadURL { url, error in
                if let error = error {
                    print("Failed to get download URL: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }

                guard let downloadURL = url else {
                    let error = NSError(domain: "DownloadURLError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to get download URL"])
                    print("Download URL is nil: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }

                print("Successfully got download URL: \(downloadURL.absoluteString)")
                saveImageURLToFirestore(downloadURL.absoluteString, userId: userId) { result in
                    switch result {
                    case .success:
                        completion(.success(()))
                    case .failure(let error):
                        print("Failed to save image URL to Firestore: \(error.localizedDescription)")
                        completion(.failure(error))
                    }
                }
            }
        }

        uploadTask.observe(.progress) { snapshot in
            let percentComplete = Double(snapshot.progress?.completedUnitCount ?? 0) / Double(snapshot.progress?.totalUnitCount ?? 1)
            print("Upload is \(percentComplete * 100)% complete")
        }

        uploadTask.observe(.success) { _ in
            print("Upload completed successfully")
        }

        uploadTask.observe(.failure) { snapshot in
            if let error = snapshot.error {
                print("Upload failed with error: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }

    private static func saveImageURLToFirestore(_ url: String, userId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let firestore = Firestore.firestore()
        let userRef = firestore.collection("users").document(userId)

        userRef.getDocument { document, error in
            if let error = error {
                print("Failed to get user document: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }

            guard document?.exists == true else {
                let error = NSError(domain: "FirestoreError", code: 0, userInfo: [NSLocalizedDescriptionKey: "User document does not exist"])
                print("User document does not exist: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }

            userRef.collection("images").addDocument(data: [
                "url": url,
                "timestamp": FieldValue.serverTimestamp()
            ]) { error in
                if let error = error {
                    print("Failed to save image URL to Firestore: \(error.localizedDescription)")
                    completion(.failure(error))
                } else {
                    print("Image URL successfully saved to Firestore!")
                    completion(.success(()))
                }
            }
        }
    }
}
