import SwiftUI
import Firebase
import FirebaseStorage
import FirebaseAuth
import CoreHaptics
import UIKit

// A UIViewRepresentable to wrap UIVisualEffectView in SwiftUI
struct CustomBlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style

    func makeUIView(context: Context) -> UIVisualEffectView {
        let blurEffect = UIBlurEffect(style: style)
        let blurView = UIVisualEffectView(effect: blurEffect)
        return blurView
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
}

struct RippleModifier: ViewModifier {
    var origin: CGPoint
    var elapsedTime: TimeInterval
    var duration: TimeInterval
    var amplitude: Double
    var frequency: Double
    var decay: Double
    var speed: Double

    func body(content: Content) -> some View {
        let shader = ShaderLibrary.Ripple(
            .float2(origin),
            .float(elapsedTime),
            .float(amplitude),
            .float(frequency),
            .float(decay),
            .float(speed)
        )

        content.visualEffect { view, _ in
            view.layerEffect(
                shader,
                maxSampleOffset: maxSampleOffset,
                isEnabled: 0 < elapsedTime && elapsedTime < duration
            )
        }
    }

    var maxSampleOffset: CGSize {
        CGSize(width: amplitude, height: amplitude)
    }
}

struct RippleEffect<T: Equatable>: ViewModifier {
    var origin: CGPoint
    var trigger: T
    var amplitude: Double
    var frequency: Double
    var decay: Double
    var speed: Double

    init(at origin: CGPoint, trigger: T, amplitude: Double = 12, frequency: Double = 15, decay: Double = 8, speed: Double = 1200) {
        self.origin = origin
        self.trigger = trigger
        self.amplitude = amplitude
        self.frequency = frequency
        self.decay = decay
        self.speed = speed
    }

    func body(content: Content) -> some View {
        content.keyframeAnimator(
            initialValue: 0,
            trigger: trigger
        ) { view, elapsedTime in
            view.modifier(RippleModifier(
                origin: origin,
                elapsedTime: elapsedTime,
                duration: duration,
                amplitude: amplitude,
                frequency: frequency,
                decay: decay,
                speed: speed
            ))
        } keyframes: { _ in
            MoveKeyframe(0)
            LinearKeyframe(duration, duration: duration)
        }
    }

    var duration: TimeInterval { 3 }
}

struct HomeView: View {
    @State private var count: Int = 0
    @State private var timer: Timer?
    @State private var username: String = "Name"
    @State private var capturedImage: UIImage? = nil
    @StateObject private var hapticManager = HapticManager()
    @State private var isNavigatingToProfile = false
    @State private var isPressed = false // State to control the bounce effect
    @State private var rippleOrigin: CGPoint = .zero
    @State private var rippleTrigger: Int = 0 // Used to trigger the ripple effect
    @State private var backgroundError: String? = nil // Error handling for background loading

    let userID = Auth.auth().currentUser?.uid
    
    var body: some View {
        ZStack {
            // Background Image with Error Handling
            if let image = capturedImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .edgesIgnoringSafeArea(.all)
                } else if let error = backgroundError {
                    Text("Failed to load background: \(error)")
                        .foregroundColor(.red)
                        .background(Color.black.edgesIgnoringSafeArea(.all))
                } else {
                    Color.white.edgesIgnoringSafeArea(.all)
                }

                // Apply the blur effect
                CustomBlurView(style: .regular)
                    .edgesIgnoringSafeArea(.all)

                // Apply ripple effect
                if let image = capturedImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .edgesIgnoringSafeArea(.all)
                        .modifier(RippleEffect(at: rippleOrigin, trigger: rippleTrigger))
                }

            VStack {
                // Username at the top left
                HStack(spacing: 180) {
                    Text(username)
                        .font(.system(size: 35))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.leading, 20)
                        .padding(.top, 20)
                        .offset(x: -30)

                    Button(action: {
                        hapticManager.triggerHapticFeedback()
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isPressed = true
                        }
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.5, blendDuration: 0)) {
                            isPressed = false
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            self.isNavigatingToProfile = true
                        }
                    }) {
                        Image("calendar")
                            .resizable()
                            .foregroundColor(.white)
                            .padding(.trailing, 20)
                            .padding(.top, 20)
                            .offset(x: 20)
                            .frame(width: 53, height: 50)
                            .scaleEffect(isPressed ? 0.8 : 1.0) // Bounce effect
                    }
                }
                
                Spacer()
                
                // Centered image
                if let image = capturedImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 290, height: 390)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(radius: 10)
                        .offset(y: 5)
                } else {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.gray.opacity(0.5))
                        .frame(width: 250, height: 350)
                        .shadow(radius: 10)
                }
                
                Spacer()

                // Counter and Buttons at the bottom
                VStack(spacing: 10) {
                    Text("Finished bottles")
                        .font(.system(size: 20))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .opacity(0.6)
                        .offset(y: 10)

                    HStack(spacing: 30) {
                        Button(action: {
                            if count > 0 {
                                count -= 1
                                saveCountToFirestore()
                                hapticManager.triggerHapticFeedback()  // Trigger haptic feedback on minus button press
                            }
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.2)) // Circle with low opacity
                                    .frame(width: 40, height: 40) // Adjust the size as needed
                                Image(systemName: "minus")
                                    .font(.system(size: 20))
                                    .fontWeight(.bold)
                                    .foregroundColor(.white) // Minus sign with full opacity
                            }
                        }
                        
                        // Counter with reflection effect
                        Text("\(count)")
                            .font(.system(size: 80))
                            .foregroundColor(.white)
                            .fontWeight(.bold)
                            .overlay(
                                VStack {
                                    Spacer()
                                    Text("\(count)")
                                        .font(.system(size: 80))
                                        .foregroundColor(.white)
                                        .fontWeight(.bold)
                                        .opacity(0.18) // Adjust the opacity of the reflection
                                        .scaleEffect(y: -1) // Flip the text vertically
                                        .mask(
                                            LinearGradient(
                                                gradient: Gradient(colors: [Color.white.opacity(0.5), Color.clear]),
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                        .offset(y: 60) // Adjust position if needed
                                }
                            )
                        
                        Button(action: {
                            count += 1
                            saveCountToFirestore()
                            hapticManager.triggerHapticFeedback()  // Trigger haptic feedback on plus button press

                            // Trigger the ripple effect
                            rippleOrigin = CGPoint(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY)
                            rippleTrigger += 1
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.2)) // Circle with low opacity
                                    .frame(width: 40, height: 40) // Adjust the size as needed
                                Image(systemName: "plus")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                                    .fontWeight(.bold)
                            }
                        }
                    }

                }
                .offset(y: -50)
            }
            .onAppear {
                hapticManager.prepareHaptics()
                fetchUserData()
                fetchCountFromFirestore()
                scheduleEndOfDayReset()
            }
            .onDisappear {
                timer?.invalidate()
            }
            .navigationBarBackButtonHidden(true)
            .navigationBarHidden(true)
            
            // Navigation link to Profile with back button hidden
            NavigationLink(destination: Profile().navigationBarBackButtonHidden(true), isActive: $isNavigatingToProfile) {
                EmptyView()
            }
        }
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
                    self.backgroundError = error.localizedDescription
                    return
                }
                
                guard let documents = snapshot?.documents, !documents.isEmpty else {
                    print("No images found")
                    self.backgroundError = "No images found"
                    return
                }
                
                if let document = documents.first, let imageURL = document.get("url") as? String {
                    let imageRef = storage.reference(forURL: imageURL)
                    imageRef.getData(maxSize: 10 * 1024 * 1024) { data, error in
                        if let error = error {
                            print("Error loading image: \(error.localizedDescription)")
                            self.backgroundError = error.localizedDescription
                        } else if let data = data, let image = UIImage(data: data) {
                            print("Image successfully loaded") // Debug print
                            withAnimation(.easeInOut(duration: 0.3)) {
                                self.capturedImage = image
                            }
                        }
                    }
                } else {
                    print("No URL found in the document")
                    self.backgroundError = "No URL found in the document"
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
    
    private func scheduleEndOfDayReset() {
        let now = Date()
        let calendar = Calendar.current
        let midnight = calendar.startOfDay(for: now).addingTimeInterval(24 * 60 * 60)
        
        timer = Timer(fire: midnight, interval: 0, repeats: false) { _ in
            self.resetCounter()
        }
        
        RunLoop.main.add(timer!, forMode: .common)
    }
    
    private func resetCounter() {
        count = 0
        saveCountToFirestore()
        print("Counter reset at the end of the day")
    }
}

#Preview {
    HomeView()
}
