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
    @State private var loading = true
    
    @StateObject private var hapticManager = HapticManager()

    let userID = Auth.auth().currentUser?.uid
    
    var body: some View {
        VStack(spacing: 20) {
            if loading {
                Text("Loading...")
            } else {
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
                        Image(uiImage: capturedImage ?? UIImage(named: "water1")!)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 260, height: 370)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.white, lineWidth: 4)
                            )
                            .shadow(radius: 10)
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
        }
        .padding(.vertical, 40)
        .onAppear {
            hapticManager.prepareHaptics()
            fetchUserData()
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(true)
    }
    
    private func fetchUserData() {
        guard let userID = userID else { return }
        let firestore = Firestore.firestore()
        let storage = Storage.storage()
        
        // Fetch username from Firestore
        firestore.collection("users").document(userID).getDocument { document, error in
            if let document = document, document.exists {
                self.username = document.get("username") as? String ?? "User..."
            } else {
                print("Error fetching username: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
        
        // Fetch image URL from Firestore
        firestore.collection("users")
            .document(userID)
            .collection("images")
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching documents: \(error.localizedDescription)")
                    self.loading = false
                    return
                }
                
                guard let documents = snapshot?.documents, !documents.isEmpty else {
                    print("No images found")
                    self.loading = false
                    return
                }
                
                // Assuming you want to fetch the first image URL
                if let document = documents.first, let imageURL = document.get("url") as? String {
                    let imageRef = storage.reference(forURL: imageURL)
                    imageRef.getData(maxSize: 10 * 1024 * 1024) { data, error in
                        if let data = data, let image = UIImage(data: data) {
                            self.capturedImage = image
                        }
                        self.loading = false
                    }
                } else {
                    print("No URL found in the document")
                    self.loading = false
                }
            }
    }
}
