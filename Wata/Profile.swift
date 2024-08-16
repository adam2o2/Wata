import SwiftUI
import Firebase
import FirebaseStorage
import FirebaseAuth

struct Profile: View {
    @State private var username: String = "User..."
    @State private var capturedImage: UIImage? = nil
    @State private var loading = true

    let userID = Auth.auth().currentUser?.uid

    var body: some View {
        VStack {
            if loading {
                Text("Loading...")
            } else {
                VStack(alignment: .center, spacing: 5) {
                    Text("\(username)")
                        .font(.system(size: 25))
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text(getCurrentMonth())
                        .font(.system(size: 28))
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .offset(x: -60, y: 30)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 30) {
                            ForEach(1...daysInCurrentMonth(), id: \.self) { day in
                                Text("\(day)")
                                    .font(.system(size: 20))
                                    .fontWeight(.medium)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .offset(x: 60, y: 40)
                }
                .offset(x: -60, y: 50)

                ZStack {
                    GeometryReader { geometry in
                        Image(uiImage: capturedImage ?? UIImage(named: "water1")!)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 280, height: 390)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.white, lineWidth: 4)
                            )
                            .shadow(radius: 10)
                    }
                    .frame(height: 250)
                    .offset(x: 67, y: 140)
                }
            }
            
            Spacer()
            
            HStack {
                NavigationLink(destination: HomeView()) {
                    Image("house2")
                        .resizable()
                        .frame(width: 38, height: 38)
                        .padding()
                        .offset(x: 20)
                }
                Spacer()
                Image("net")
                    .resizable()
                    .frame(width: 38, height: 38)
                    .padding()
                Spacer()
                Image("profile1")
                    .resizable()
                    .frame(width: 38, height: 38)
                    .padding()
                    .offset(x: -20)
            }
            .frame(maxWidth: .infinity)
            .offset(y: -30)
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            fetchUserData()
        }
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
    
    func getCurrentMonth() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM"
        return dateFormatter.string(from: Date())
    }

    func daysInCurrentMonth() -> Int {
        let calendar = Calendar.current
        let range = calendar.range(of: .day, in: .month, for: Date())!
        return range.count
    }
}
