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

    init(at origin: CGPoint, trigger: T, amplitude: Double = 20, frequency: Double = 20, decay: Double = 8, speed: Double = 1200) {
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
    @State private var isShowingProfile = false // State for showing Profile
    @State private var isPressed = false // State to control the bounce effect
    @State private var rippleTrigger: Int = 0 // Used to trigger the ripple effect
    @State private var backgroundError: String? = nil // Error handling for background loading
    @State private var rippleOrigin: CGPoint = CGPoint(x: 180, y: 390) // Ripple origin point
    @State private var isLongPressActivePlus = false // State to manage the glow effect during long press for the plus button
    @State private var isLongPressActiveMinus = false // State to manage the glow effect during long press for the minus button
    @State private var isLoading = true // State for loading indicator

    let userID = Auth.auth().currentUser?.uid
    
    var body: some View {
        ZStack {
            if let image = capturedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .edgesIgnoringSafeArea(.all)
                    .blur(radius: 4)
                    .modifier(RippleEffect(at: rippleOrigin, trigger: rippleTrigger))
            } else if let error = backgroundError {
                Text("Failed to load background: \(error)")
                    .foregroundColor(.red)
                    .background(Color.black.edgesIgnoringSafeArea(.all))
            } else {
                if isLoading {
                    ProgressView() // Show loading indicator while fetching data
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(2.0)
                }
            }

            CustomBlurView(style: .light)
                .edgesIgnoringSafeArea(.all)

            VStack {
                UserIcon(username: $username, iconName: "calendar") {
                    hapticManager.triggerHapticFeedback()
                    withAnimation {
                        isShowingProfile = true
                    }
                }

                Spacer()
                
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

                VStack(spacing: 10) {
                    Text("Finished bottles")
                        .font(.system(size: 20))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .opacity(0.6)
                        .offset(y: 10)

                    HStack(spacing: 30) {
                        Button(action: {
                            // Do nothing, as action will be handled by the long press gesture
                        }) {
                            ZStack {
                                Circle()
                                    .fill(isLongPressActiveMinus ? Color.red : Color.white.opacity(0.2)) // Change color on long press
                                    .frame(width: 40, height: 40)
                                    .shadow(color: isLongPressActiveMinus ? Color.red.opacity(0.8) : Color.clear, radius: isLongPressActiveMinus ? 10 : 0) // Glow effect
                                Image(systemName: "minus")
                                    .font(.system(size: 20))
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                            .scaleEffect(isLongPressActiveMinus ? 1.5 : 1.0) // Scale up during long press
                        }
                        .highPriorityGesture(
                            LongPressGesture(minimumDuration: 0.5)
                                .onChanged { _ in
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        isLongPressActiveMinus = true
                                    }
                                }
                                .onEnded { _ in
                                    if count > 0 {
                                        count -= 1
                                        saveCountToFirestore()
                                        hapticManager.triggerHapticFeedback()
                                    }
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        isLongPressActiveMinus = false
                                    }
                                }
                        )
                        
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
                                        .opacity(0.18)
                                        .scaleEffect(y: -1)
                                        .mask(
                                            LinearGradient(
                                                gradient: Gradient(colors: [Color.white.opacity(0.5), Color.clear]),
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                        .offset(y: 60)
                                }
                            )
                        
                        Button(action: {
                            // Do nothing, as action will be handled by the long press gesture
                        }) {
                            ZStack {
                                Circle()
                                    .fill(isLongPressActivePlus ? Color.blue : Color.white.opacity(0.2)) // Change color on long press
                                    .frame(width: 40, height: 40)
                                    .shadow(color: isLongPressActivePlus ? Color.blue.opacity(0.8) : Color.clear, radius: isLongPressActivePlus ? 10 : 0) // Glow effect
                                Image(systemName: "plus")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                                    .fontWeight(.bold)
                            }
                            .scaleEffect(isLongPressActivePlus ? 1.5 : 1.0) // Scale up during long press
                        }
                        .highPriorityGesture(
                            LongPressGesture(minimumDuration: 0.5)
                                .onChanged { _ in
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        isLongPressActivePlus = true
                                    }
                                }
                                .onEnded { _ in
                                    count += 1
                                    saveCountToFirestore()
                                    hapticManager.triggerHapticFeedback()
                                    rippleTrigger += 1
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        isLongPressActivePlus = false
                                    }
                                }
                        )
                    }
                }
                .offset(y: -50)
            }
            .modifier(RippleEffect(at: rippleOrigin, trigger: rippleTrigger))
            .onAppear {
                hapticManager.prepareHaptics()
                fetchUserData()
                fetchCountFromFirestore()
                adjustResetTimeForTimeZone()
            }
            .onDisappear {
                timer?.invalidate()
            }
            .navigationBarBackButtonHidden(true)
            .navigationBarHidden(true)

            if isShowingProfile {
                Profile()
                    .transition(.opacity) // Transition effect for showing Profile
                    .zIndex(1) // Ensure Profile is on top
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
                            print("Image successfully loaded")
                            withAnimation(.easeInOut(duration: 0.3)) {
                                self.capturedImage = image
                                self.isLoading = false
                            }
                        }
                    }
                } else {
                    print("No URL found in the document")
                    self.backgroundError = "No URL found in the document"
                    self.isLoading = false
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
    
    private func adjustResetTimeForTimeZone() {
        let timeZone = TimeZone.current
        let secondsFromGMT = timeZone.secondsFromGMT()
        
        // Calculate offset for each time zone
        let secondsForCentral = -6 * 3600
        let secondsForEastern = -5 * 3600
        let secondsForMountain = -7 * 3600
        let secondsForPacific = -8 * 3600
        
        var targetSecondsFromGMT = 0

        // Adjust for Central, Mountain, Pacific, and Eastern time
        if secondsFromGMT == secondsForCentral {
            targetSecondsFromGMT = secondsForCentral
        } else if secondsFromGMT == secondsForEastern {
            targetSecondsFromGMT = secondsForEastern
        } else if secondsFromGMT == secondsForMountain {
            targetSecondsFromGMT = secondsForMountain
        } else if secondsFromGMT == secondsForPacific {
            targetSecondsFromGMT = secondsForPacific
        }

        // Calculate the difference from the current time zone to the target time zone
        let timeDifference = TimeInterval(targetSecondsFromGMT - secondsFromGMT)
        let now = Date()
        let calendar = Calendar.current
        let midnight = calendar.startOfDay(for: now).addingTimeInterval(24 * 60 * 60 + timeDifference)
        
        timer = Timer(fire: midnight, interval: 0, repeats: false) { _ in
            self.resetCounter()
        }
        
        RunLoop.main.add(timer!, forMode: .common)
    }
    
    private func resetCounter() {
        count = 0
        saveCountToFirestore()
        print("Counter reset at the specified time")
    }
}

#Preview {
    HomeView()
}
