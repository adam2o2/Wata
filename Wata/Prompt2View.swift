import SwiftUI
import CoreHaptics

struct Prompt2View: View {
    @State private var isPressed = false
    @State private var isNavigationActive = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Title and subtitle
                VStack(alignment: .center, spacing: 5) {
                    Text("Track when you finish drinking your bottle")
                        .font(.system(size: 30))
                        .fontWeight(.semibold)
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

                    // Faded black circle with 1 and water droplet emoji
                    ZStack {
                        Circle()
                            .fill(Color.brown.opacity(0.9))
                            .frame(width: 60, height: 60)

                        HStack(spacing: 1) {
                            Text("1")
                                .font(.system(size: 22))
                                .foregroundColor(.white)
                                .fontWeight(.bold)
                                .offset(x: 3)
                            Text("💧")
                                .font(.system(size: 28))
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
}

#Preview {
    Prompt2View()
}
