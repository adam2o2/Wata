import SwiftUI
import AVFoundation
import FirebaseStorage

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
                        .frame(width: 291, height: 62)
                        .background(Color.black)
                        .cornerRadius(30)
                        .scaleEffect(isPressed ? 1.1 : 1.0) // Bounce effect
                        .shadow(radius: 10)
                }
                .padding(.horizontal)
                .offset(y: -20)
                .onTapGesture {
                    withAnimation {
                        isPressed.toggle()
                    }
                }
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            setupCamera()
        }
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
                if let image = image {
                    uploadImageToFirebase(image: image)
                }
            }
        }
        
        photoOutput.capturePhoto(with: settings, delegate: processor)
    }

    // Upload image to Firebase Storage
    func uploadImageToFirebase(image: UIImage) {
        let storage = Storage.storage()
        let storageRef = storage.reference()
        let imagesRef = storageRef.child("images/\(UUID().uuidString).jpg")
        
        guard let imageData = image.jpegData(compressionQuality: 0.75) else { return }
        
        let uploadTask = imagesRef.putData(imageData, metadata: nil) { (metadata, error) in
            guard let metadata = metadata else {
                print("Error uploading image: \(String(describing: error))")
                return
            }
            let size = metadata.size
            print("Uploaded image with size: \(size)")
        }
        
        uploadTask.observe(.success) { snapshot in
            print("Image upload successful.")
        }
        
        uploadTask.observe(.failure) { snapshot in
            print("Image upload failed: \(String(describing: snapshot.error))")
        }
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

struct CameraView_Previews: PreviewProvider {
    static var previews: some View {
        CameraView()
    }
}
