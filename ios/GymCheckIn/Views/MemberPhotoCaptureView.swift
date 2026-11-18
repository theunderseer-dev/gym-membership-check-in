import SwiftUI
import AVFoundation
import PhotosUI

struct MemberPhotoCaptureView: View {
    var onPhotoConfirmed: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var capturedImage: UIImage? = nil
    @State private var cameraPermissionStatus: AVAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var cameraPosition: AVCaptureDevice.Position = .back
    @State private var isCameraAvailable: Bool = UIImagePickerController.isSourceTypeAvailable(.camera)

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                if let image = capturedImage {
                    // Preview screen after photo is taken
                    photoPreviewView(image: image)
                } else {
                    // Live camera / capture screen
                    liveCaptureView
                }
            }
            .navigationTitle(capturedImage == nil ? "Member Photo" : "Confirm Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(.white)
                }
            }
            .onChange(of: selectedPhotoItem) { newItem in
                guard let newItem = newItem else { return }
                Task {
                    if let data = try? await newItem.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        await MainActor.run {
                            self.capturedImage = uiImage.fixedOrientation()
                        }
                    }
                    selectedPhotoItem = nil
                }
            }
            .onAppear {
                cameraPermissionStatus = AVCaptureDevice.authorizationStatus(for: .video)
            }
        }
    }

    // MARK: - Live Capture View
    @ViewBuilder
    private var liveCaptureView: some View {
        if cameraPermissionStatus == .authorized && isCameraAvailable {
            ZStack {
                CameraPhotoPreview(cameraPosition: $cameraPosition, onPhotoTaken: { image in
                    self.capturedImage = image
                })
                .ignoresSafeArea(edges: .bottom)

                // Face framing guide
                VStack {
                    Spacer()

                    RoundedRectangle(cornerRadius: 32)
                        .stroke(Color.white.opacity(0.8), style: StrokeStyle(lineWidth: 2, dash: [8, 6]))
                        .frame(width: 240, height: 300)
                        .overlay(
                            Text("Center member's face")
                                .font(.caption.bold())
                                .foregroundStyle(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Capsule())
                                .padding(.top, 12),
                            alignment: .top
                        )

                    Spacer()

                    // Bottom controls (Flip camera + Shutter)
                    HStack {
                        // Flip camera
                        Button {
                            cameraPosition = (cameraPosition == .back) ? .front : .back
                        } label: {
                            Image(systemName: "camera.rotate.fill")
                                .font(.title2)
                                .foregroundStyle(.white)
                                .frame(width: 50, height: 50)
                                .background(Color.white.opacity(0.2))
                                .clipShape(Circle())
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 32)

                        // Shutter button trigger handled by NotificationCenter or representable
                        ShutterButton {
                            NotificationCenter.default.post(name: .takePhotoTriggered, object: nil)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)

                        // Spacer to balance layout
                        Spacer()
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .padding(.trailing, 32)
                    }
                    .padding(.bottom, 36)
                }
            }
        } else if cameraPermissionStatus == .notDetermined {
            VStack(spacing: 20) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.blue)

                Text("Camera Permission Required")
                    .font(.title3.bold())
                    .foregroundStyle(.white)

                Text("Gym Check-in needs camera access to capture member photos for check-in identity verification.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                Button("Grant Camera Access") {
                    AVCaptureDevice.requestAccess(for: .video) { granted in
                        DispatchQueue.main.async {
                            cameraPermissionStatus = granted ? .authorized : .denied
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 8)
            }
            .padding(24)
        } else if !isCameraAvailable {
            // Simulator fallback
            VStack(spacing: 20) {
                Image(systemName: "camera.badge.ellipsis")
                    .font(.system(size: 56))
                    .foregroundStyle(.orange)

                Text("Camera Unavailable (Simulator)")
                    .font(.title3.bold())
                    .foregroundStyle(.white)

                Text("A camera is not available in the iOS Simulator. You can choose a photo from your library or use a sample photo to test the flow.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    Label("Choose from Photo Library", systemImage: "photo.on.rectangle")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 32)

                Button {
                    self.capturedImage = generateSamplePhoto()
                } label: {
                    Label("Use Sample Member Photo", systemImage: "person.crop.circle.badge.plus")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white.opacity(0.15))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 32)
            }
            .padding(24)
        } else {
            // Denied
            VStack(spacing: 20) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.red)

                Text("Camera Access Denied")
                    .font(.title3.bold())
                    .foregroundStyle(.white)

                Text("Camera access has been disabled in iOS Settings. Please enable camera access in Settings to take member photos.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    Label("Choose from Photo Library Instead", systemImage: "photo")
                        .font(.headline)
                        .padding()
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(24)
        }
    }

    // MARK: - Photo Preview View (Retake / Continue)
    @ViewBuilder
    private func photoPreviewView(image: UIImage) -> some View {
        VStack(spacing: 24) {
            Spacer()

            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 280, height: 360)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.4), lineWidth: 2)
                )
                .shadow(color: .black.opacity(0.5), radius: 16, x: 0, y: 8)

            Text("Verify member's face is clearly visible")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.8))

            Spacer()

            // 2 requested buttons: "Retake Photo" and "Continue / Done"
            HStack(spacing: 16) {
                Button {
                    self.capturedImage = nil
                } label: {
                    Label("Retake Photo", systemImage: "arrow.triangle.2.circlepath")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white.opacity(0.2))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                Button {
                    onPhotoConfirmed(image)
                    dismiss()
                } label: {
                    Label("Continue", systemImage: "checkmark")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }

    // MARK: - Sample Photo Generator for Simulator
    private func generateSamplePhoto() -> UIImage {
        let size = CGSize(width: 400, height: 500)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            // Background gradient
            let colors = [UIColor.systemIndigo.cgColor, UIColor.systemBlue.cgColor]
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: [0.0, 1.0])!
            ctx.cgContext.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: 0, y: size.height), options: [])

            // Avatar placeholder silhouette
            ctx.cgContext.setFillColor(UIColor.white.withAlphaComponent(0.9).cgColor)
            // Head
            ctx.cgContext.fillEllipse(in: CGRect(x: 130, y: 120, width: 140, height: 140))
            // Body
            ctx.cgContext.fillEllipse(in: CGRect(x: 70, y: 280, width: 260, height: 260))

            // Label
            let text = "TEST MEMBER"
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 22),
                .foregroundColor: UIColor.white
            ]
            let strSize = text.size(withAttributes: attrs)
            text.draw(at: CGPoint(x: (size.width - strSize.width) / 2, y: 440), withAttributes: attrs)
        }
    }
}

// MARK: - Shutter Button
private struct ShutterButton: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .stroke(Color.white, lineWidth: 4)
                    .frame(width: 72, height: 72)

                Circle()
                    .fill(Color.white)
                    .frame(width: 60, height: 60)
            }
        }
    }
}

// MARK: - Camera Notification
extension Notification.Name {
    static let takePhotoTriggered = Notification.Name("takePhotoTriggeredNotification")
}

// MARK: - CameraPhotoPreview Representable
private struct CameraPhotoPreview: UIViewControllerRepresentable {
    @Binding var cameraPosition: AVCaptureDevice.Position
    var onPhotoTaken: (UIImage) -> Void

    func makeUIViewController(context: Context) -> CameraPhotoViewController {
        let controller = CameraPhotoViewController()
        controller.cameraPosition = cameraPosition
        controller.onPhotoTaken = onPhotoTaken
        return controller
    }

    func updateUIViewController(_ uiViewController: CameraPhotoViewController, context: Context) {
        if uiViewController.cameraPosition != cameraPosition {
            uiViewController.switchCamera(to: cameraPosition)
        }
    }
}

// MARK: - CameraPhotoViewController
private final class CameraPhotoViewController: UIViewController, AVCapturePhotoCaptureDelegate {
    var cameraPosition: AVCaptureDevice.Position = .back
    var onPhotoTaken: ((UIImage) -> Void)?

    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var photoOutput: AVCapturePhotoOutput?
    private var currentInput: AVCaptureDeviceInput?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupSession()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleShutter),
            name: .takePhotoTriggered,
            object: nil
        )
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let session = captureSession, !session.isRunning {
            DispatchQueue.global(qos: .userInitiated).async {
                session.startRunning()
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let session = captureSession, session.isRunning {
            session.stopRunning()
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func setupSession() {
        let session = AVCaptureSession()
        session.sessionPreset = .photo

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: cameraPosition),
              let input = try? AVCaptureDeviceInput(device: device) else {
            return
        }

        if session.canAddInput(input) {
            session.addInput(input)
            self.currentInput = input
        }

        let output = AVCapturePhotoOutput()
        if session.canAddOutput(output) {
            session.addOutput(output)
            self.photoOutput = output
        }

        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        preview.frame = view.bounds
        view.layer.addSublayer(preview)

        self.previewLayer = preview
        self.captureSession = session

        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
        }
    }

    func switchCamera(to position: AVCaptureDevice.Position) {
        guard let session = captureSession else { return }
        cameraPosition = position

        session.beginConfiguration()
        if let currentInput = currentInput {
            session.removeInput(currentInput)
        }

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position),
              let input = try? AVCaptureDeviceInput(device: device) else {
            session.commitConfiguration()
            return
        }

        if session.canAddInput(input) {
            session.addInput(input)
            self.currentInput = input
        }
        session.commitConfiguration()
    }

    @objc private func handleShutter() {
        guard let photoOutput = photoOutput else { return }
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error == nil,
              let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data)?.fixedOrientation() else {
            return
        }
        DispatchQueue.main.async {
            self.onPhotoTaken?(image)
        }
    }
}
