import AVFoundation
import UIKit
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

class Camera: UIViewController {

    var session: AVCaptureSession?
    let output = AVCapturePhotoOutput()
    let previewLayer = AVCaptureVideoPreviewLayer()
    
    // Track if the user has denied access multiple times
    var deniedCount = 0

    private let shutterButton: UIButton = {
        let outerCircle = UIButton(frame: CGRect(x: 0, y: 0, width: 75, height: 75))
        outerCircle.layer.cornerRadius = 37.5
        outerCircle.layer.borderWidth = 2
        outerCircle.layer.borderColor = UIColor.white.cgColor
        outerCircle.backgroundColor = .clear
        
        let innerCircle = UIView(frame: CGRect(x: 5, y: 5, width: 65, height: 65))
        innerCircle.layer.cornerRadius = 32.5
        innerCircle.backgroundColor = .white
        
        outerCircle.addSubview(innerCircle)
        return outerCircle
    }()
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = .black
        imageView.isUserInteractionEnabled = true
        return imageView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        view.layer.addSublayer(previewLayer)
        view.addSubview(shutterButton)
        checkCameraPermissions()

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapTakePhoto))
        shutterButton.addGestureRecognizer(tapGesture)
        
        // Listen for when the app becomes active again after returning from settings
        NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    @objc private func appDidBecomeActive() {
        // Check camera permissions again when the app becomes active
        checkCameraPermissions()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer.frame = view.bounds
        previewLayer.videoGravity = .resizeAspectFill

        let safeAreaInsets = view.safeAreaInsets
        let shutterButtonY = view.frame.size.height - safeAreaInsets.bottom - 75 / 2
        shutterButton.center = CGPoint(x: view.frame.size.width / 2, y: shutterButtonY)

        view.bringSubviewToFront(shutterButton)
    }

    private func checkCameraPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                guard granted else {
                    DispatchQueue.main.async {
                        self?.showCameraWarning()
                    }
                    return
                }
                DispatchQueue.main.async {
                    self?.setupCamera()
                }
            }
        case .restricted, .denied:
            showCameraWarning()
        case .authorized:
            setupCamera()
        @unknown default:
            break
        }
    }
    
    private func showCameraWarning() {
        deniedCount += 1 // Increment each time the user says no
        
        var message = "Your account will be erased if you don't allow camera access. Do you want to erase your account?"
        
        // If the user has denied access more than once, show an additional message.
        if deniedCount > 1 {
            message += "\n\nPlease enable camera access in your settings to continue using this feature."
        }
        
        let alertController = UIAlertController(title: "Camera Access Required", message: message, preferredStyle: .alert)

        let yesAction = UIAlertAction(title: "Yes", style: .destructive) { [weak self] _ in
            self?.deleteUserAccount { success in
                if success {
                    self?.navigateToContentView()
                }
            }
        }

        let noAction = UIAlertAction(title: "No", style: .cancel) { [weak self] _ in
            self?.askCameraAccessAgain()
        }

        alertController.addAction(yesAction)
        alertController.addAction(noAction)

        present(alertController, animated: true, completion: nil)
    }

    private func askCameraAccessAgain() {
        let currentStatus = AVCaptureDevice.authorizationStatus(for: .video)
        if currentStatus == .denied {
            // Show alert guiding the user to Settings
            let alertController = UIAlertController(
                title: "Camera Access Denied",
                message: "You have denied camera access. Please enable it in your settings to use this feature.",
                preferredStyle: .alert
            )
            
            let settingsAction = UIAlertAction(title: "Go to Settings", style: .default) { _ in
                if let appSettings = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(appSettings)
                }
            }
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            
            alertController.addAction(settingsAction)
            alertController.addAction(cancelAction)
            
            present(alertController, animated: true, completion: nil)
        } else {
            // If permission has not been permanently denied, request access again
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    DispatchQueue.main.async {
                        self?.setupCamera()
                    }
                } else {
                    DispatchQueue.main.async {
                        self?.showCameraWarning()
                    }
                }
            }
        }
    }

    private func setupCamera() {
        let session = AVCaptureSession()
        if let device = AVCaptureDevice.default(for: .video) {
            do {
                let input = try AVCaptureDeviceInput(device: device)
                if session.canAddInput(input) {
                    session.addInput(input)
                }

                if session.canAddOutput(output) {
                    session.addOutput(output)
                }

                previewLayer.videoGravity = .resizeAspectFill
                previewLayer.session = session
                view.layer.addSublayer(previewLayer)

                session.startRunning()
                self.session = session
            } catch {
                print(error)
            }
        }
    }

    @objc private func didTapTakePhoto() {
        UIView.animate(withDuration: 0.1, animations: {
            self.shutterButton.transform = CGAffineTransform(scaleX: 0.6, y: 0.6)
        }, completion: { _ in
            UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 1.5, options: .allowUserInteraction, animations: {
                self.shutterButton.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
            }, completion: { _ in
                UIView.animate(withDuration: 0.1, animations: {
                    self.shutterButton.transform = CGAffineTransform.identity
                    self.shutterButton.alpha = 0
                }, completion: { _ in
                    self.shutterButton.isHidden = true
                    self.output.capturePhoto(with: AVCapturePhotoSettings(), delegate: self)
                })
            })
        })
    }

    private func presentConfirmView(with image: UIImage) {
        let confirmView = ConfirmView(
            image: image,
            onRetake: { [weak self] in
                self?.dismiss(animated: true, completion: nil)
            }
        )

        let hostingController = UIHostingController(rootView: confirmView)
        hostingController.modalPresentationStyle = .overFullScreen
        hostingController.view.backgroundColor = .clear
        present(hostingController, animated: false, completion: nil)
    }

    /// Deletes the Firestore Authentication and Firestore database records for the user.
    private func deleteUserAccount(completion: @escaping (Bool) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(false)
            return
        }
        
        let userId = user.uid
        let firestore = Firestore.firestore()
        
        // Step 1: Delete the Firestore database data for the user.
        firestore.collection("users").document(userId).delete { error in
            if let error = error {
                print("Failed to delete user data from Firestore: \(error)")
                completion(false)
                return
            }
            
            // Step 2: Delete the user's authentication account after deleting the Firestore data.
            user.delete { error in
                if let error = error {
                    print("Failed to delete Firebase authentication user: \(error)")
                    completion(false)
                } else {
                    print("User authentication and data deleted successfully")
                    completion(true)
                }
            }
        }
    }

    /// Navigates the user to the ContentView.
    private func navigateToContentView() {
        let contentView = ContentView() // Replace with your SwiftUI ContentView
        let hostingController = UIHostingController(rootView: contentView)
        hostingController.modalPresentationStyle = .fullScreen
        present(hostingController, animated: true, completion: nil)
    }
}

extension Camera: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation(), let image = UIImage(data: data) else {
            return
        }
        session?.stopRunning()

        presentConfirmView(with: image)
    }
}
