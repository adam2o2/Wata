import SwiftUI

struct RetakeMessage: View {
    @Binding var isPresented: Bool // Binding to control the presentation of this view
    @Binding var capturedImage: UIImage?

    var body: some View {
        ZStack {
            // Dimming the background
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    withAnimation {
                        isPresented = false // Dismiss the view when tapping outside
                    }
                }

            VStack(spacing: 20) {
                Image(systemName: "drop.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.blue)
                
                Text("Retake photo")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                
                Button(action: {
                    withAnimation {
                        isPresented = false // Dismiss the view
                    }
                    // Add logic to retake a new photo, e.g., navigate to camera view
                    capturedImage = nil
                }) {
                    Text("Take a new photo")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.black)
                        .cornerRadius(10)
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(20)
            .shadow(radius: 20)
            .frame(width: 300)
            .onTapGesture { } // Prevent tap propagation to the background
        }
    }
}
