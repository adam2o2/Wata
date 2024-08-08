import SwiftUI
import CoreHaptics

struct Prompt2View: View {
    @State private var isPressed = false
    @State private var isNavigationActive = false
    @State private var count = 1 // State property for the count
    @State private var scale: CGFloat = 1.0 // State property for scale
    @State private var opacity: Double = 1.0 // State property for opacity
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Title and subtitle
                VStack(alignment: .center, spacing: 5) {
                    Text("Track when you finish drinking your bottle")
                        .font(.system(size: 30))
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                }
                .frame(width: 350, alignment: .center)
                .padding(.horizontal)
                .offset(y: -120)
                
                ZStack {
                    GeometryReader { geometry in
                        // Image with corner radius and white border
                        Image("water1")
                            .resizable()
                            .frame(width: 260, height: 370)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.white, lineWidth: 4)
                            )
                            .shadow(radius: 10)
                    }
                    .frame(width: 170, height: 230)
                    .offset(x: -45, y: -50)
                    
                    // Faded black circle with count and water droplet emoji
                    ZStack {
                        Circle()
                            .fill(Color.brown.opacity(0.9))
                            .frame(width: 60, height: 60)
                        
                        HStack(spacing: 1) {
                            Text("\(count)")
                                .font(.system(size: 22))
                                .foregroundColor(.white)
                                .fontWeight(.bold)
                                .scaleEffect(scale)
                                .opacity(opacity)
                                .onChange(of: count) { _ in
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                                        scale = 1.5
                                        opacity = 0.5
                                    }
                                    // Reset the scale and opacity after the animation
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        withAnimation {
                                            scale = 1.0
                                            opacity = 1.0
                                        }
                                    }
                                }
                                .offset(x: 3)
                            Text("💧")
                                .font(.system(size: 22))
                        }
                    }
                    .offset(x: -90, y: 165)
                }
                
                // Button that triggers navigation
                Button(action: {
                    withAnimation {
                        isPressed.toggle()
                    }
                    triggerHapticFeedback()
                    // Set navigation state after animation completes
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        isNavigationActive = true
                    }
                }) {
                    HStack {
                        Text("Take a photo")
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .font(.system(size: 20))
                    }
                    .padding()
                    .frame(width: 291, height: 62)
                    .background(Color.black)
                    .cornerRadius(30)
                    .scaleEffect(isPressed ? 1.1 : 1.0) // Bounce effect
                    .shadow(radius: 10)
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal)
                .offset(y: 150)
                
                // NavigationLink for CameraView
                NavigationLink(
                    destination: CameraView()
                        .edgesIgnoringSafeArea(.all),
                    isActive: $isNavigationActive
                ) {
                    EmptyView() // Empty view to hide the NavigationLink
                }
                .hidden() // Hide the NavigationLink
            }
            .padding(.vertical, 40)
            .onAppear {
                prepareHaptics()
                startCountdown() // Start the countdown animation when view appears
            }
            .navigationBarBackButtonHidden(true) // Hide the back button in Prompt2View
        }
    }
    
    // Function to prepare haptics
    func prepareHaptics() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
    }
    
    // Function to trigger haptic feedback
    func triggerHapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    // Function to start the countdown animation
    func startCountdown() {
        let totalDuration = 10.0 // Total duration for the countdown
        let interval = 1.0 // Update interval
        
        Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { timer in
            if self.count < 20 {
                withAnimation(.linear(duration: interval)) {
                    self.count += 1
                }
            } else {
                timer.invalidate()
            }
        }
    }
}

#Preview {
    Prompt2View()
}
