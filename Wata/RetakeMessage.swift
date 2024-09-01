import SwiftUI

struct RetakeMessage: View {
    @Binding var isPresented: Bool
    @Binding var capturedImage: UIImage?

    var body: some View {
        ZStack {
            // Background dimming
            Color.black.opacity(0.5)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    isPresented = false // Dismiss when tapping outside
                }

            // The actual message content
            VStack {
                Spacer() // Push the content to the bottom
                
                VStack(spacing: 20) {
                    // Handle bar
                    Capsule()
                        .fill(Color.gray.opacity(0.5))
                        .frame(width: 40, height: 5)
                        .padding(.top, 10)

                    // Water drop emoji or image
                    Text("💧")
                        .font(.system(size: 50))

                    // Retake photo text
                    Text("Retake photo")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.black)
                        .offset(y: 10)

                    // Take a new photo button
                    Button(action: {
                        isPresented = false // Dismiss the message
                        // Additional action to retake photo can be added here
                    }) {
                        Text("Take a new photo")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.black)
                            .cornerRadius(50)
                            .padding(.horizontal, 50)
                    }
                    .padding(.bottom, 40)
                }
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .cornerRadius(30)
                .shadow(radius: 10)
            }
            .edgesIgnoringSafeArea(.bottom)
            .transition(.move(edge: .bottom)) // Slide in from bottom
        }
    }
}

#Preview {
    RetakeMessage(isPresented: .constant(true), capturedImage: .constant(nil))
}
