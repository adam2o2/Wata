import SwiftUI
import CoreHaptics

struct HomeView: View {
    @State private var scale: CGFloat = 1.5 // Initial scale for the big size
    @State private var offsetX: CGFloat = 110 // Initial x-offset for the emoji
    @State private var hapticEngine: CHHapticEngine?
    @State private var isPressed = false
    let username: String // Passed username

    var body: some View {
        VStack(spacing: 20) {
            // Title and subtitle
            VStack(alignment: .center, spacing: 5) {
                Text("\(username)'s water bottle") // Display the username
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
                        .frame(width: 220, height: 321)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white, lineWidth: 4)
                        )
                        .shadow(radius: 10)
                }
                .frame(width: 170, height: 230) // Set the frame size to match the images
                .offset(x: -22, y: -50)
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
                .background(Color(hex: "#00ACFF")) // Button color is updated
                .cornerRadius(40)
                .scaleEffect(isPressed ? 1.1 : 1.0) // Bounce effect
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
        HomeView(username: "SampleUser") // Example preview with a username
    }
}
