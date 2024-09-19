import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage

struct LoginDelete: View {
    @Binding var isPresented: Bool
    @Binding var username: String
    @State private var navigateToContentView = false // State to trigger navigation
    
    @State private var showDeleteConfirmation = false // State to control the confirmation dialog
    
    var body: some View {
        ZStack {
            VStack {
                Spacer()
                
                VStack(spacing: 20) {
                    // Handle bar
                    Capsule()
                        .fill(Color.gray.opacity(0.4))
                        .frame(width: 50, height: 7)
                        .padding(.top, 10)
                        .offset(y: -50)

                    // Log out button
                    Button(action: {
                        logOutUser() // Log out the user and navigate
                    }) {
                        Text("Log out")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.black)
                            .cornerRadius(50)
                            .frame(width: 291, height: 62)
                            .shadow(color: .black.opacity(0.4), radius: 10, x: 0, y: 5)
                            .padding(.horizontal, 40)
                            .offset(y: -20)
                    }

                    // Delete Account button
                    Button(action: {
                        showDeleteConfirmation = true // Show confirmation dialog
                    }) {
                        Text("Delete Account")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.red)
                    }
                    .confirmationDialog("Are you sure you want to delete your account?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
                        Button("Delete", role: .destructive) {
                            deleteUserData() // Call the delete function if the user confirms
                        }
                        Button("Cancel", role: .cancel) {}
                    }

                    // Navigation link to go to ContentView after deletion or logout
                    NavigationLink(destination: ContentView().navigationBarBackButtonHidden(true), isActive: $navigateToContentView) {
                        EmptyView()
                    }
                }
                .frame(maxWidth: 414)
                .frame(height: 260)
                .background(Color.white)
                .cornerRadius(30)
                .shadow(radius: 10)
                .transition(.move(edge: .bottom)) // Slide up from bottom
            }
            .edgesIgnoringSafeArea(.bottom)
        }
        .animation(.linear(duration: 0.4)) // Use linear animation
    }

    // Function to log out the user
    func logOutUser() {
        do {
            try Auth.auth().signOut()
            navigateToContentView = true // Navigate to ContentView after log out
        } catch let signOutError as NSError {
            print("Error signing out: %@", signOutError)
        }
    }

    // Function to delete user data
    func deleteUserData() {
        guard let user = Auth.auth().currentUser else {
            print("No user logged in")
            return
        }

        let uid = user.uid
        let db = Firestore.firestore()
        let storage = Storage.storage()

        // Reference to the user document
        let userRef = db.collection("users").document(uid)

        // Delete Firestore data and subcollections
        deleteSubcollectionsAndDocument(documentRef: userRef) { success in
            if success {
                print("User Firestore data deleted")
                // Delete the user from Firebase Storage (Assuming images are stored under `users/{uid}/`)
                let storageRef = storage.reference().child("users/\(uid)")
                
                // List all files and folders in the user's storage directory
                storageRef.listAll { result, error in
                    if let error = error {
                        print("Error listing storage files: \(error.localizedDescription)")
                        // Even if there is an error, proceed to delete the user account
                        deleteUserAuthentication(user: user)
                        return
                    }

                    guard let result = result else {
                        print("Failed to get storage result.")
                        deleteUserAuthentication(user: user)
                        return
                    }

                    let deleteGroup = DispatchGroup()

                    // Delete all files
                    for item in result.items {
                        deleteGroup.enter()
                        item.delete { error in
                            if let error = error {
                                print("Error deleting file: \(error.localizedDescription)")
                            } else {
                                print("Successfully deleted storage file: \(item.fullPath)")
                            }
                            deleteGroup.leave()
                        }
                    }

                    // Check if there are directories (folders), and handle their deletion if necessary
                    if !result.prefixes.isEmpty {
                        for folder in result.prefixes {
                            deleteGroup.enter()
                            deleteFolderContents(folder) {
                                deleteGroup.leave()
                            }
                        }
                    }

                    // Wait for all storage deletions to complete
                    deleteGroup.notify(queue: .main) {
                        print("All storage files deleted")
                        deleteUserAuthentication(user: user)
                    }
                }
            } else {
                print("Failed to delete Firestore data")
            }
        }
    }

    // Helper function to delete all contents in a Firebase Storage folder
    func deleteFolderContents(_ folderRef: StorageReference, completion: @escaping () -> Void) {
        folderRef.listAll { result, error in
            if let error = error {
                print("Error listing folder contents: \(error.localizedDescription)")
                completion()
                return
            }

            guard let result = result else {
                print("Failed to get folder result.")
                completion()
                return
            }

            let deleteGroup = DispatchGroup()

            // Delete all files inside the folder
            for fileRef in result.items {
                deleteGroup.enter()
                fileRef.delete { error in
                    if let error = error {
                        print("Error deleting file in folder: \(error.localizedDescription)")
                    } else {
                        print("Successfully deleted file in folder: \(fileRef.fullPath)")
                    }
                    deleteGroup.leave()
                }
            }

            // Recursively delete subfolders, if any exist
            if !result.prefixes.isEmpty {
                for subfolder in result.prefixes {
                    deleteGroup.enter()
                    deleteFolderContents(subfolder) {
                        deleteGroup.leave()
                    }
                }
            }

            // Notify when all contents in the folder are deleted
            deleteGroup.notify(queue: .main) {
                completion()
            }
        }
    }

    // Helper function to delete Firestore subcollections and the document itself
    func deleteSubcollectionsAndDocument(documentRef: DocumentReference, completion: @escaping (Bool) -> Void) {
        documentRef.getDocument { documentSnapshot, error in
            guard let documentSnapshot = documentSnapshot, documentSnapshot.exists else {
                completion(false)
                return
            }

            let subcollectionNames = ["calendar", "images"] // Specify subcollections to delete
            let batch = documentRef.firestore.batch()

            // Delete each subcollection's documents
            let deleteGroup = DispatchGroup()
            for subcollection in subcollectionNames {
                deleteGroup.enter()
                documentRef.collection(subcollection).getDocuments { querySnapshot, error in
                    if let querySnapshot = querySnapshot {
                        for document in querySnapshot.documents {
                            batch.deleteDocument(document.reference)
                        }
                        deleteGroup.leave()
                    } else {
                        deleteGroup.leave()
                        print("Error fetching subcollection: \(error?.localizedDescription ?? "Unknown error")")
                    }
                }
            }

            // Once all subcollections are processed, delete the document itself
            deleteGroup.notify(queue: .main) {
                batch.deleteDocument(documentRef)
                batch.commit { error in
                    if let error = error {
                        print("Error deleting document: \(error.localizedDescription)")
                        completion(false)
                    } else {
                        completion(true)
                    }
                }
            }
        }
    }

    // Helper function to delete Firebase Authentication user
    func deleteUserAuthentication(user: User) {
        user.delete { error in
            if let error = error {
                print("Error deleting user: \(error.localizedDescription)")
            } else {
                // After deletion, navigate to ContentView
                navigateToContentView = true
            }
        }
    }
}

#Preview {
    // Preview with constant values (temporary for SwiftUI previews)
    LoginDelete(isPresented: .constant(true), username: .constant("Adam"))
}
