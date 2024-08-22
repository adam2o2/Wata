import SwiftUI
import UIKit

struct CameraView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> Camera {
        return Camera()
    }

    func updateUIViewController(_ uiViewController: Camera, context: Context) {
        // Update the view controller if needed
    }
}

struct CameraViewContainer: View {
    var body: some View {
        CameraView()
            .navigationBarBackButtonHidden(true) // Hide back button
            .navigationBarHidden(true) // Optionally hide the entire navigation bar
    }
}

