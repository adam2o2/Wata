import SwiftUI
import CoreHaptics

struct ContentView: View {
    @State private var hapticEngine: CHHapticEngine?
    @State private var isPressed = false
    
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
                        .rotationEffect(.degrees(9))
                        .offset(x: -194, y: 300)

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
                .frame(width: 170, height: 230)

                // NavigationLink to PromptView
                NavigationLink(destination: PromptView()) {
                    HStack {
                        Image(systemName: "applelogo")
                            .foregroundColor(.white)
                            .font(.system(size: 25))
                            .offset(x: 10)
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
