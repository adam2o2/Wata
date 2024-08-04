import SwiftUI
import AVFoundation

struct CameraView: View {
    @State private var isPressed = false
    @State private var session = AVCaptureSession()
    
    var body: some View {
        ZStack {
            // Camera preview
            CameraPreview(session: $session)
                .edgesIgnoringSafeArea(.all)
            
            // Overlay with Take a photo button
            VStack {
                Spacer()
                HStack {
                    Text("Take a photo")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .font(.system(size: 20))
                }
                .padding()
                .frame(width: 270, height: 60)
                .background(Color.black)
                .cornerRadius(30)
                .scaleEffect(isPressed ? 1.1 : 1.0) // Bounce effect
                .shadow(radius: 10)
                .buttonStyle(PlainButtonStyle())
                .onTapGesture {
                    withAnimation {
                        isPressed.toggle()
                    }
                    triggerHapticFeedback()
                    capturePhoto()
                }
                .padding(.horizontal)
                .offset(y: -20)
            }
        }
        .onAppear {
            prepareHaptics()
            setupCamera()
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
    
    // Function to setup camera
    func setupCamera() {
        session.sessionPreset = .photo
        
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera],
            mediaType: .video,
            position: .back
        )
        
        guard let camera = discoverySession.devices.first else {
            print("No back camera available.")
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: camera)
            if session.canAddInput(input) {
                session.addInput(input)
            }
        } catch {
            print("Error setting up camera: \(error)")
        }
        
        let output = AVCapturePhotoOutput()
        if session.canAddOutput(output) {
            session.addOutput(output)
        }
        
        session.startRunning()
    }
    
    // Function to capture photo
    func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        if let output = session.outputs.first as? AVCapturePhotoOutput {
            output.capturePhoto(with: settings, delegate: PhotoCaptureProcessor())
        }
    }
}

// UIViewRepresentable for camera preview
struct CameraPreview: UIViewRepresentable {
    @Binding var session: AVCaptureSession
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        view.layer.addSublayer(previewLayer)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if let previewLayer = uiView.layer.sublayers?.compactMap({ $0 as? AVCaptureVideoPreviewLayer }).first {
            previewLayer.frame = uiView.bounds
        }
    }
}

// Photo capture delegate
class PhotoCaptureProcessor: NSObject, AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let imageData = photo.fileDataRepresentation() else { return }
        let image = UIImage(data: imageData)
        // Handle the captured photo (e.g., save to photo library)
    }
}

struct CameraView_Previews: PreviewProvider {
    static var previews: some View {
        CameraView()
    }
}
