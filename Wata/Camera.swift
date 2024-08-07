import AVFoundation
import UIKit
import SwiftUI

class Camera: UIViewController {
    
    var session: AVCaptureSession?
    let output = AVCapturePhotoOutput()
    let previewLayer = AVCaptureVideoPreviewLayer()
    
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
        
        let imageTapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapImageView))
        imageView.addGestureRecognizer(imageTapGesture)
        
        edgesForExtendedLayout = []
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
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
                guard granted else { return }
                DispatchQueue.main.async {
                    self?.setupCamera()
                }
            }
        case .restricted, .denied:
            break
        case .authorized:
            setupCamera()
        @unknown default:
            break
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
                })
            })
        })
        
        output.capturePhoto(with: AVCapturePhotoSettings(), delegate: self)
    }
    
    @objc private func didTapImageView() {
        imageView.removeFromSuperview()
        session?.startRunning()
        shutterButton.isHidden = false
        UIView.animate(withDuration: 0.3) {
            self.shutterButton.alpha = 1
        }
    }
    
    private func presentConfirmView(with image: UIImage) {
        let confirmView = ConfirmView(
            image: image,
            onRetake: { [weak self] in
                self?.dismiss(animated: true, completion: nil)
            }
        )
        
        let hostingController = UIHostingController(rootView: confirmView)
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

#Preview {
    Camera()
}
