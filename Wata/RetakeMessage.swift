import SwiftUI

struct RetakeMessage: View {
    @Binding var isPresented: Bool
    @Binding var capturedImage: UIImage?
    
    // New completion handler to pass the new image and handle further actions
    var onPhotoRetaken: (UIImage?) -> Void
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass // Detect the device size class

    var body: some View {
        ZStack {
            // Background dimming
            
            VStack {
                Spacer()
                
                VStack(spacing: 20) {
                    // Handle bar
                    Capsule()
                        .fill(Color.gray.opacity(0.4))
                        .frame(width: horizontalSizeClass == .compact ? 50 : 70, height: 7) // Adjust width for iPad
                        .padding(.top, 10)
                        .offset(y: horizontalSizeClass == .compact ? -50 : -50)

                    // Water drop emoji or image
                    Text("💧")
                        .font(.system(size: horizontalSizeClass == .compact ? 50 : 90)) // Adjust size for iPad
                        .offset(y: horizontalSizeClass == .compact ? -0 : -10)

                    // Retake photo text
                    Text("Retake photo")
                        .font(.system(size: horizontalSizeClass == .compact ? 24 : 40, weight: .bold, design: .rounded)) // Adjust font size for iPad
                        .foregroundColor(.black)
                        .offset(y: horizontalSizeClass == .compact ? -0 : -30)

                    // Take a new photo button
                    Button(action: {
                        isPresented = false // Dismiss the message

                        // Present the Camera view controller (in SwiftUI, you may present a full screen CameraView)
                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                           let window = windowScene.windows.first {
                            let cameraVC = Camera()
                            cameraVC.modalPresentationStyle = .fullScreen
                            window.rootViewController?.present(cameraVC, animated: true, completion: {
                                // Simulate taking a new photo, here you'd capture the photo from the camera
                                let newImage = UIImage(named: "new-photo-example") // Replace with the actual captured image
                                
                                // Pass the new image back using the completion handler
                                onPhotoRetaken(newImage)
                            })
                        }
                    }) {
                        Text("Take a new photo")
                            .font(.system(size: horizontalSizeClass == .compact ? 18 : 32, weight: .bold, design: .rounded)) // Adjust font size for iPad
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.black)
                            .cornerRadius(50)
                            .padding(.horizontal, horizontalSizeClass == .compact ? 50 : 200) // Adjust padding for iPad
                            .padding(.bottom, horizontalSizeClass == .compact ? 0 : 400) // 190 for iPhone, 250 for iPad
                            .shadow(color: .black.opacity(0.4), radius: 10, x: 0, y: 5)
                    }

                }
                .frame(maxWidth: horizontalSizeClass == .compact ? 414 : 1110) // Adjust width for iPad
                .frame(height: horizontalSizeClass == .compact ? 350 : 850) // Adjust height for iPad
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
    RetakeMessage(isPresented: .constant(true), capturedImage: .constant(nil), onPhotoRetaken: { _ in })
}
