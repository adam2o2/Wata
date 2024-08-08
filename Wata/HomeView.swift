import SwiftUI
import CoreHaptics

struct HomeView: View {
    @State private var scale: CGFloat = 1.5
    @State private var offsetX: CGFloat = 110
    @State private var hapticEngine: CHHapticEngine?
    @State private var isPressed = false
    @State private var count: Int = 0
    @State private var opacity: Double = 1.0

    let username: String
    let capturedImage: UIImage?

    var body: some View {
        VStack(spacing: 20) {
            // Title and subtitle
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
                    // Use capturedImage if available, otherwise fallback to "water1"
                    Image(uiImage: capturedImage ?? UIImage(named: "water1")!)
                        .resizable()
                        .aspectRatio(contentMode: .fill) // Ensures the image fills the frame
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
                            .font(.system(size: 17))
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
                .offset(x: -90, y: 135)
            }

            // Continue button with haptics and bounce effect
            Button(action: {
                // Add your button action here
                print("Fully drank button pressed")
                triggerHapticFeedback()
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
            .offset(y: 100)
        }
        .padding(.vertical, 40)
        .onAppear {
            prepareHaptics()
        }
    }

    private func prepareHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            hapticEngine = try CHHapticEngine()
            try hapticEngine?.start()
        } catch {
            print("Failed to start haptic engine: \(error.localizedDescription)")
        }
    }

    private func triggerHapticFeedback() {
        guard let hapticEngine = hapticEngine else { return }
        let hapticPattern: CHHapticPattern
        do {
            hapticPattern = try CHHapticPattern(events: [
                CHHapticEvent(eventType: .hapticTransient, parameters: [], relativeTime: 0)
            ], parameters: [])
            let player = try hapticEngine.makePlayer(with: hapticPattern)
            try player.start(atTime: 0)
        } catch {
            print("Failed to play haptic feedback: \(error.localizedDescription)")
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView(username: "SampleUser", capturedImage: UIImage(named: "sample_image"))
    }
}
