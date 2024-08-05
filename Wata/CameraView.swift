import SwiftUI
import AVFoundation

struct CameraView: View {
    @State private var session = AVCaptureSession()
    @State private var photoOutput = AVCapturePhotoOutput()
    @State private var capturedImage: UIImage?
    @State private var isPressed = false

    var body: some View {
        ZStack {
            // Camera preview
            CameraPreview(session: $session)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                Spacer()
                Button(action: {
                    capturePhoto()
                }) {
                    Text("Take a Photo")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .font(.system(size: 20))
                        .padding()
                        .frame(width: 270, height: 60)
                        .background(Color.black)
                        .cornerRadius(30)
                        .scaleEffect(isPressed ? 1.1 : 1.0) // Bounce effect
                        .shadow(radius: 10)
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
                .padding(.bottom, 50)
            }
        }
        .onAppear {
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
    
    // Setup camera session
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
            print("Error setting up camera input: \(error)")
        }
        
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
        }
        
        // Start running the session on a background thread
        DispatchQueue.global(qos: .background).async {
            self.session.startRunning()
        }
    }

    // Capture photo
    func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        
        let processor = PhotoCaptureProcessor { image in
            DispatchQueue.main.async {
                self.capturedImage = image
            }
        }
        
        photoOutput.capturePhoto(with: settings, delegate: processor)
    }
}

struct CameraPreview: UIViewRepresentable {
    @Binding var session: AVCaptureSession
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            if let previewLayer = uiView.layer.sublayers?.compactMap({ $0 as? AVCaptureVideoPreviewLayer }).first {
                previewLayer.frame = uiView.bounds
            }
        }
    }
}

class PhotoCaptureProcessor: NSObject, AVCapturePhotoCaptureDelegate {
    let onPhotoCaptured: (UIImage?) -> Void

    init(onPhotoCaptured: @escaping (UIImage?) -> Void) {
        self.onPhotoCaptured = onPhotoCaptured
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error == nil else {
            print("Error capturing photo: \(String(describing: error))")
            onPhotoCaptured(nil)
            return
        }
        guard let imageData = photo.fileDataRepresentation() else {
            print("No image data captured")
            onPhotoCaptured(nil)
            return
        }
        let image = UIImage(data: imageData)
        onPhotoCaptured(image)
    }
}

#Preview {
    CameraView()
}
