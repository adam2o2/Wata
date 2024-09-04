import SwiftUI
import FirebaseStorage
import FirebaseFirestore
import FirebaseAuth

class ImageCache {
    static let shared = NSCache<NSString, UIImage>()
}

struct CachedHomeView: View {
    @State private var capturedImage: UIImage? = nil
    let userID = Auth.auth().currentUser?.uid
    
    var body: some View {
        ZStack {
            if let image = capturedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .edgesIgnoringSafeArea(.all)
            } else {
                Text("No image loaded")
            }
        }
        .onAppear {
            fetchCachedImage()
        }
    }

    private func fetchCachedImage() {
        let cacheKey = "\(userID ?? "")-profileImage" as NSString
        
        // Check if the image is already cached
        if let cachedImage = ImageCache.shared.object(forKey: cacheKey) {
            self.capturedImage = cachedImage
        } else {
            // Fetch from Firebase if not cached
            fetchImageFromFirebase { image in
                self.capturedImage = image
                if let image = image {
                    ImageCache.shared.setObject(image, forKey: cacheKey) // Cache the image
                }
            }
        }
    }

    private func fetchImageFromFirebase(completion: @escaping (UIImage?) -> Void) {
        guard let userID = userID else {
            completion(nil)
            return
        }
        
        let firestore = Firestore.firestore()
        let storage = Storage.storage()

        firestore.collection("users")
            .document(userID)
            .collection("images")
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching documents: \(error.localizedDescription)")
                    completion(nil)
                    return
                }

                guard let documents = snapshot?.documents, let document = documents.first, let imageURL = document.get("url") as? String else {
                    print("No images found")
                    completion(nil)
                    return
                }

                let imageRef = storage.reference(forURL: imageURL)
                imageRef.getData(maxSize: 10 * 1024 * 1024) { data, error in
                    if let error = error {
                        print("Error loading image: \(error.localizedDescription)")
                        completion(nil)
                    } else if let data = data, let image = UIImage(data: data) {
                        completion(image)
                    }
                }
            }
    }
}
