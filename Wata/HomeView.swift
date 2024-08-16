import SwiftUI
import Firebase
import FirebaseStorage
import FirebaseAuth
import CoreHaptics

struct HomeView: View {
    @State private var scale: CGFloat = 1.5
    @State private var offsetX: CGFloat = 110
    @State private var isPressed = false
    @State private var count: Int = 0
    @State private var opacity: Double = 1.0
    
    @State private var username: String = ""
    @State private var capturedImage: UIImage? = nil
    @State private var imageLoaded = false
    
    @StateObject private var hapticManager = HapticManager()

    let userID = Auth.auth().currentUser?.uid
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(alignment: .center, spacing: 5) {
                Text("\(username)'s water bottle")
                    .font(.system(size: 30))
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
            }
            .frame(width: 300, alignment: .center)
            .padding(.horizontal)
            .offset(y: -120)
            
            ZStack {
                GeometryReader { geometry in
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white)
                        .frame(width: 260, height: 370)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white, lineWidth: 4)
                        )
                        .shadow(radius: 10)
                    
                    if let image = capturedImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 260, height: 370)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.white, lineWidth: 4)
                            )
                            .shadow(radius: 10)
                            .transition(.opacity)
                            .animation(.easeInOut(duration: 0.3)) // Faster transition duration
                    }
                }
                .frame(width: 170, height: 230)
                .offset(x: -45, y: -80)
                
                ZStack {
                    Circle()
                        .fill(Color.brown.opacity(0.9))
                        .frame(width: 60, height: 60)
                    
                    HStack(spacing: 1) {
                        Text("\(count)")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .fontWeight(.bold)
                            .opacity(opacity)
                            .onChange(of: count) { _ in
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                                    opacity = 0.6
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    withAnimation {
                                        opacity = 1.0
                                    }
                                }
                            }
                            .offset(x: 3)
                        Text("💧")
                            .font(.system(size: 22))
                    }
                }
                .offset(x: -90, y: 135)
            }
            
            Button(action: {
                count += 1
                saveCountToFirestore() // Save count to Firestore
                print("Fully drank button pressed")
                hapticManager.triggerHapticFeedback()
            }) {
                HStack {
                    Text("Fully drank")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .font(.system(size: 20))
                }
                .padding()
                .frame(width: 291, height: 62)
                .background(Color(hex: "#00ACFF"))
                .cornerRadius(40)
                .scaleEffect(isPressed ? 1.1 : 1.0)
                .shadow(radius: 10)
            }
            .buttonStyle(PlainButtonStyle())
            .onTapGesture {
                withAnimation {
                    isPressed.toggle()
                }
            }
            .padding(.horizontal)
            .offset(y: 120)
            
            HStack {
                Image("house1")
                    .resizable()
                    .frame(width: 38, height: 38)
                    .padding()
                    .offset(x: 20)
                Spacer()
                Image("net")
                    .resizable()
                    .frame(width: 38, height: 38)
                    .padding()
                Spacer()
                NavigationLink(destination: Profile()) {
                    Image("profile2")
                        .resizable()
                        .frame(width: 38, height: 38)
                        .padding()
                        .offset(x: -20)
                }
            }
            .frame(maxWidth: .infinity)
            .offset(y: 150)
        }
        .padding(.vertical, 40)
        .onAppear {
            hapticManager.prepareHaptics()
            fetchUserData()
            fetchCountFromFirestore() // Fetch count from Firestore
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(true)
    }
    
    private func fetchUserData() {
        guard let userID = userID else { return }
        let firestore = Firestore.firestore()
        let storage = Storage.storage()
        
        firestore.collection("users").document(userID).getDocument { document, error in
            if let document = document, document.exists {
                self.username = document.get("username") as? String ?? "User..."
            } else {
                print("Error fetching username: \(error?.localizedDescription ?? "Unknown error")")
            }
        }

        firestore.collection("users")
            .document(userID)
            .collection("images")
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching documents: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents, !documents.isEmpty else {
                    print("No images found")
                    return
                }
                
                if let document = documents.first, let imageURL = document.get("url") as? String {
                    let imageRef = storage.reference(forURL: imageURL)
                    imageRef.getData(maxSize: 10 * 1024 * 1024) { data, error in
                        if let data = data, let image = UIImage(data: data) {
                            withAnimation(.easeInOut(duration: 0.3)) { // Faster transition duration
                                self.capturedImage = image
                            }
                        }
                    }
                } else {
                    print("No URL found in the document")
                }
            }
    }
    
    private func saveCountToFirestore() {
        guard let userID = userID else { return }
        let firestore = Firestore.firestore()
        firestore.collection("users").document(userID).setData(["count": count], merge: true) { error in
            if let error = error {
                print("Error saving count: \(error.localizedDescription)")
            }
        }
    }
    
    private func fetchCountFromFirestore() {
        guard let userID = userID else { return }
        let firestore = Firestore.firestore()
        firestore.collection("users").document(userID).getDocument { document, error in
            if let document = document, document.exists {
                self.count = document.get("count") as? Int ?? 0
            } else {
                print("Error fetching count: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }
}

#Preview {
    HomeView()
}
