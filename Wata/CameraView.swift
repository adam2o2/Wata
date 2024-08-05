import SwiftUI
import AVFoundation

struct CameraView: View {
    @State private var isPressed = false
    @State private var session = AVCaptureSession()
    @State private var photoOutput = AVCapturePhotoOutput()
    @State private var capturedImage: UIImage? = nil
    @State private var navigateToConfirmView = false

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
            
            // Continue button to navigate to ConfirmView
            if capturedImage != nil {
                VStack {
                    Spacer()
                    Button(action: {
                        navigateToConfirmView = true
                    }) {
                        Text("Continue")
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .font(.system(size: 22))
                            .frame(width: 230, height: 70)
                            .background(Color.black)
                            .cornerRadius(35)
                            .shadow(radius: 5)
                    }
                    .padding(.bottom, 50)
                    .transition(.opacity) // Add a transition to fade in the button
                }
            }
        }
        .onAppear {
            prepareHaptics()
            setupCamera()
        }
        .fullScreenCover(isPresented: $navigateToConfirmView) {
            if let image = capturedImage {
                ConfirmView(image: image, onRetake: {
                    self.navigateToConfirmView = false
                    self.capturedImage = nil // Reset captured image to take a new photo
                }, onConfirm: {
                    // Handle confirmation action
                })
            }
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
            } else {
                print("Unable to add camera input.")
                return
            }
        } catch {
            print("Error setting up camera: \(error)")
            return
        }
        
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
        } else {
            print("Unable to add photo output.")
            return
        }
        
        session.startRunning()
    }
    
    // Function to capture photo
    func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        settings.flashMode = .auto
        
        photoOutput.capturePhoto(with: settings, delegate: PhotoCaptureProcessor { image in
            DispatchQueue.main.async {
                self.capturedImage = image
                // Trigger button display
                withAnimation {
                    self.isPressed = false
                }
            }
        })
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
