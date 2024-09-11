import SwiftUI
import Firebase
import FirebaseStorage
import FirebaseFirestore
import FirebaseAuth

struct FirestoreHelper {

    static func uploadImageAndSaveURL(image: UIImage?, completion: @escaping (Result<Void, Error>) -> Void) {
        // Ensure the image is valid
        guard let imageData = image?.jpegData(compressionQuality: 0.5) else {
            completion(.failure(NSError(domain: "ImageError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to JPEG"])))
            return
        }

        // Ensure the user is authenticated
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(.failure(NSError(domain: "AuthError", code: 0, userInfo: [NSLocalizedDescriptionKey: "No user logged in"])))
            return
        }

        // Reference to Firebase Storage
        let storageRef = Storage.storage().reference()
        let imageName = "profileImage.jpg" // Use a consistent image name
        let imageRef = storageRef.child("users/\(userId)/images/\(imageName)")

        print("Starting upload to path: users/\(userId)/images/\(imageName)")

        // Start uploading the image
        let uploadTask = imageRef.putData(imageData, metadata: nil) { metadata, error in
            if let error = error {
                print("Upload failed with error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }

            // Get the download URL once the upload completes
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
                
                // Save the image URL to Firestore, replace any existing image for this user
                saveImageURLToFirestore(downloadURL.absoluteString, userId: userId, completion: completion)
            }
        }

        // Observe upload progress
        uploadTask.observe(.progress) { snapshot in
            let percentComplete = Double(snapshot.progress?.completedUnitCount ?? 0) / Double(snapshot.progress?.totalUnitCount ?? 1)
            print("Upload is \(percentComplete * 100)% complete")
        }

        // Handle successful upload
        uploadTask.observe(.success) { _ in
            print("Upload completed successfully")
        }

        // Handle upload failure
        uploadTask.observe(.failure) { snapshot in
            if let error = snapshot.error {
                print("Upload failed with error: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }

    // Function to save the image URL to Firestore, replace old image if it exists
    private static func saveImageURLToFirestore(_ url: String, userId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let firestore = Firestore.firestore()
        let userRef = firestore.collection("users").document(userId)
        let imageDocRef = userRef.collection("images").document("profileImage") // Store at a fixed document

        // Ensure the user document exists, or create it if it doesn't
        userRef.setData(["createdAt": FieldValue.serverTimestamp()], merge: true) { error in
            if let error = error {
                print("Failed to create user document: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }

            // Set or update the image document with the new URL
            imageDocRef.setData([
                "url": url,
                "timestamp": FieldValue.serverTimestamp()
            ]) { error in
                if let error = error {
                    print("Failed to save/update image URL: \(error.localizedDescription)")
                    completion(.failure(error))
                } else {
                    print("Image URL successfully saved/updated in Firestore!")
                    completion(.success(()))
                }
            }
        }
    }

    // Function to fetch images for the user
    static func fetchUserImages(userId: String, completion: @escaping (Result<[String], Error>) -> Void) {
        let firestore = Firestore.firestore()
        let userRef = firestore.collection("users").document(userId)

        userRef.collection("images").order(by: "timestamp", descending: true).getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error fetching images: \(error.localizedDescription)")
                completion(.failure(error))
            } else if let snapshot = querySnapshot {
                if snapshot.documents.isEmpty {
                    print("No images found.")
                    completion(.success([]))
                } else {
                    let urls = snapshot.documents.compactMap { document in
                        document["url"] as? String
                    }
                    completion(.success(urls))
                }
            }
        }
    }
}
