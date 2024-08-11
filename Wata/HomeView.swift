import SwiftUI
import CoreHaptics

struct HomeView: View {
    @State private var scale: CGFloat = 1.5
    @State private var offsetX: CGFloat = 110
    @State private var hapticEngine: CHHapticEngine?
    @State private var isPressed = false
    @State private var count: Int = 0
    @State private var opacity: Double = 1.0
    @State private var capturedImage: UIImage?
    
    let username: String

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
                triggerHapticFeedback()
                saveCapturedImage()
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
                NavigationLink(destination: Profile(username: username, capturedImage: capturedImage)) {
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
        .padding(.vertical, 40)
        .onAppear {
            prepareHaptics()
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(true)
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

    private func saveCapturedImage() {
        guard let image = capturedImage else { return }
        
        let fileManager = FileManager.default
        let calendarDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("calendar")

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMMyyyy"
        let monthDirectory = calendarDirectory.appendingPathComponent(dateFormatter.string(from: Date()))

        dateFormatter.dateFormat = "MMMMdd"
        let dayDirectory = monthDirectory.appendingPathComponent(dateFormatter.string(from: Date()))

        do {
            // Create directories if they do not exist
            if !fileManager.fileExists(atPath: monthDirectory.path) {
                try fileManager.createDirectory(at: monthDirectory, withIntermediateDirectories: true, attributes: nil)
            }
            if !fileManager.fileExists(atPath: dayDirectory.path) {
                try fileManager.createDirectory(at: dayDirectory, withIntermediateDirectories: true, attributes: nil)
            }

            // Save the image to the directory
            if let data = image.jpegData(compressionQuality: 1.0) {
                let imageURL = dayDirectory.appendingPathComponent("capturedImage.jpg")
                try data.write(to: imageURL)
                print("Image saved to \(imageURL.path)")
            }
        } catch {
            print("Error saving image: \(error.localizedDescription)")
        }
    }
}
