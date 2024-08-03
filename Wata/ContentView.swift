import SwiftUI
import CoreHaptics

struct ContentView: View {
    @State private var hapticEngine: CHHapticEngine?

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Title and subtitle
                VStack(alignment: .leading, spacing: 5) {
                    Text("Wata")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text("Helping you stay hydrated")
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .offset(y: -120)

                // Image with corner radius and white border
                ZStack {
                    Image("water1")
                        .resizable()
                        .frame(width: 170, height: 230)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white, lineWidth: 4)
                        )
                        .shadow(radius: 10)
                        .rotationEffect(.degrees(-6))
                        .offset(x: -60)

                    Image("water2")
                        .resizable()
                        .frame(width: 170, height: 230)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white, lineWidth: 4)
                        )
                        .shadow(radius: 10)
                        .rotationEffect(.degrees(9)) // Rotate as needed
                        .offset(x: -194, y: 300) // Adjust the offset to position it without affecting water1

                    Image("water3")
                        .resizable()
                        .frame(width: 170, height: 230)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white, lineWidth: 4)
                        )
                        .shadow(radius: 10)
                        .rotationEffect(.degrees(-25))
                        .offset(x: 200, y: -70)

                    Image("water4")
                        .resizable()
                        .frame(width: 210, height: 270)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white, lineWidth: 4)
                        )
                        .shadow(radius: 10)
                        .rotationEffect(.degrees(-25))
                        .offset(x: 150, y: 250)
                }
                .frame(width: 170, height: 230) // Set the frame size to match the images

                // NavigationLink to PromptView
                NavigationLink(destination: PromptView()) {
                    HStack {
                        Image(systemName: "applelogo")
                            .foregroundColor(.white)
                            .font(.system(size: 25)) // Adjust the size value as needed
                            .offset(x: 10) // Adjust position of the icon
                        Spacer()
                        Text("Sign in with Apple")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .offset(x: -35)
                    }
                    .padding()
                    .frame(width: 270, height: 60)
                    .background(Color.black)
                    .cornerRadius(30)
                    .scaleEffect(1.1) // Bounce effect
                    .shadow(radius: 10) // Add shadow to ensure it's visible
                    .onTapGesture {
                        triggerHapticFeedback()
                    }
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
