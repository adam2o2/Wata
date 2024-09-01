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
                        // Additional action to retake photo can be added here
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
