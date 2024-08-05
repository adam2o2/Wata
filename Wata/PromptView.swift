import SwiftUI
import CoreHaptics

struct PromptView: View {
    @State private var scale: CGFloat = 1.5 // Initial scale for the big size
    @State private var offsetX: CGFloat = 110 // Initial x-offset for the emoji
    @State private var hapticEngine: CHHapticEngine?
    @State private var isPressed = false

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Title and subtitle
                VStack(alignment: .center, spacing: 5) {
                    Text("Take a photo of your main water bottle")
                        .font(.system(size: 30)) // Use your desired font size
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center) // Center-align the text
                }
                .frame(width: 300, alignment: .center) // Set a fixed width for the VStack
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
                    .frame(width: 170, height: 230) // Set the frame size to match the images
                    .offset(x: -45, y: -50)

                    // Water droplet emoji with scale animation
                    Text("💧")
                        .font(.system(size: 50)) // Adjust the size as needed
                        .scaleEffect(scale) // Apply scaling effect
                        .offset(x: offsetX, y: 200) // Adjust x-offset
                        .onAppear {
                            // Animate the scale effect
                            withAnimation(Animation.easeInOut(duration: 1.0)) {
                                scale = 1.0
                            }
                            // Animate the x-offset change
                            withAnimation(Animation.easeInOut(duration: 1.0)) {
                                offsetX = 110
                            }
                        }
                }

                // Continue button with navigation, haptics, and bounce effect
                NavigationLink(destination: Prompt2View().navigationBarBackButtonHidden(true)) {
                    HStack {
                        Text("Continue")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .font(.system(size: 20))
                    }
                    .padding()
                    .frame(width: 291, height: 62)
                    .background(Color.black) // Button color is black
                    .cornerRadius(30)
                    .scaleEffect(isPressed ? 1.1 : 1.0) // Bounce effect
                    .shadow(radius: 10)
                }
                .buttonStyle(PlainButtonStyle())
                .onTapGesture {
                    withAnimation {
                        isPressed.toggle()
                    }
                    triggerHapticFeedback()
                }
                .padding(.horizontal)
                .offset(y: 150)
            }
            .padding(.vertical, 40)
        }
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

struct PromptView_Previews: PreviewProvider {
    static var previews: some View {
        PromptView()
    }
}
