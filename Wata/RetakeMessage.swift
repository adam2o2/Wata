import SwiftUI

struct RetakeMessage: View {
    @Binding var isPresented: Bool
    @Binding var capturedImage: UIImage?

    var body: some View {
        ZStack {
            // Background dimming
             // Fade in transition

            // The actual message content
            VStack {
                Spacer() // Push the content to the bottom
                
                VStack(spacing: 20) {
                    // Handle bar
                    Capsule()
                        .fill(Color.gray.opacity(0.4))
                        .frame(width: 50, height: 7)
                        .padding(.top, 10)
                        .offset(y: -50)

                    // Water drop emoji or image
                    Text("💧")
                        .font(.system(size: 50))

                    // Retake photo text
                    Text("Retake photo")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.black)

                    // Take a new photo button
                    Button(action: {
                        isPresented = false // Dismiss the message

                            // Present the Camera view controller
                            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                               let window = windowScene.windows.first {
                                let cameraVC = Camera()
                                cameraVC.modalPresentationStyle = .fullScreen // Set the presentation style to full screen
                                window.rootViewController?.present(cameraVC, animated: true, completion: nil)
                            }
                    }) {
                        Text("Take a new photo")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.black)
                            .cornerRadius(50)
                            .padding(.horizontal, 50)
                    }

                }
                .frame(maxWidth: 414)
                .frame(height: 350) // Set the height of the white box
                .background(Color.white)
                .cornerRadius(30)
                .shadow(radius: 10)
                .transition(.move(edge: .bottom)) // Slide up from bottom
            }
            .edgesIgnoringSafeArea(.bottom)
        }
        .animation(.linear(duration: 0.4)) // Use linear animation
    }
}

#Preview {
    RetakeMessage(isPresented: .constant(true), capturedImage: .constant(nil))
}
