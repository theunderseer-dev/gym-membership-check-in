import SwiftUI
import PhotosUI
import AVFoundation

enum CheckResultState {
    case found(Member, MembershipStatus)
    case notFound(String)
}

struct CheckMembershipView: View {
    @ObservedObject var repository: GymRepository
    var onDoneToRoot: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss

    @State private var selectedTab: Int = 0 // 0 = Camera, 1 = Manual ID
    @State private var manualIdInput: String = ""
    @State private var checkResult: CheckResultState? = nil
    @State private var imageErrorMessage: String? = nil

    // Photo selection
    @State private var selectedPhotoItem: PhotosPickerItem? = nil

    // Camera permission
    @State private var cameraPermissionStatus: AVAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    var body: some View {
        VStack(spacing: 0) {
            if let result = checkResult {
                resultView(result: result)
            } else {
                // Top persistent action: "Scan QR from image"
                VStack(spacing: 8) {
                    PhotosPicker(
                        selection: $selectedPhotoItem,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        HStack {
                            Image(systemName: "photo.on.rectangle.angled")
                            Text("Scan QR from image")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(.secondarySystemGroupedBackground))
                        .foregroundStyle(.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                        )
                    }

                    if let error = imageErrorMessage {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.red)
                            Text(error)
                                .font(.subheadline)
                                .foregroundStyle(.red)
                            Spacer()
                            Button {
                                imageErrorMessage = nil
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.red.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)

                // Tabs: Scan Camera vs Enter ID
                Picker("Check Method", selection: $selectedTab) {
                    Text("Scan QR").tag(0)
                    Text("Enter ID").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)

                if selectedTab == 0 {
                    cameraTab
                } else {
                    manualIdTab
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Check Membership")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: selectedPhotoItem) { newItem in
            guard let newItem = newItem else { return }
            imageErrorMessage = nil
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    await MainActor.run {
                        handleImageScanned(uiImage)
                    }
                } else {
                    await MainActor.run {
                        imageErrorMessage = "Could not read image"
                    }
                }
                selectedPhotoItem = nil
            }
        }
        .onAppear {
            cameraPermissionStatus = AVCaptureDevice.authorizationStatus(for: .video)
        }
    }

    // MARK: - Camera Tab
    @ViewBuilder
    private var cameraTab: some View {
        ZStack {
            if cameraPermissionStatus == .authorized {
                ZStack {
                    CameraScannerView { scannedCode in
                        checkMember(byId: scannedCode)
                    }
                    .ignoresSafeArea(edges: .bottom)

                    // Target viewfinder box
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.green, lineWidth: 3)
                        .frame(width: 240, height: 240)
                        .shadow(color: .black.opacity(0.4), radius: 4)
                }
            } else if cameraPermissionStatus == .notDetermined {
                VStack(spacing: 16) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.blue)

                    Text("Camera Access Required")
                        .font(.headline)

                    Text("Please grant camera permission to scan client QR cards.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    Button("Grant Camera Permission") {
                        AVCaptureDevice.requestAccess(for: .video) { granted in
                            DispatchQueue.main.async {
                                cameraPermissionStatus = granted ? .authorized : .denied
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Use Manual ID Instead") {
                        selectedTab = 1
                    }
                    .buttonStyle(.borderless)
                }
                .padding(32)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "camera.badge.ellipsis")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)

                    Text("Camera Unavailable or Denied")
                        .font(.headline)

                    Text("Camera access is disabled or unavailable. You can still scan from photos above or enter the ID manually below.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    Button("Use Manual ID Entry") {
                        selectedTab = 1
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(32)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    // MARK: - Manual ID Tab
    @ViewBuilder
    private var manualIdTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Manual ID Verification")
                        .font(.headline)

                    Text("Enter or paste the client's unique member ID.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 16)

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        TextField("Enter member ID", text: $manualIdInput)
                            .textFieldStyle(.plain)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)

                        if !manualIdInput.isEmpty {
                            Button {
                                manualIdInput = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(.separator), lineWidth: 1)
                    )
                }

                Button {
                    checkMember(byId: manualIdInput)
                } label: {
                    Label("Check", systemImage: "magnifyingglass")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(manualIdInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                Spacer()
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Result View
    @ViewBuilder
    private func resultView(result: CheckResultState) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                switch result {
                case .found(let member, let status):
                    let isActive = status == .active
                    let statusColor: Color = isActive ? .green : .red

                    VStack(spacing: 12) {
                        Image(systemName: isActive ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                            .font(.system(size: 64))
                            .foregroundStyle(statusColor)

                        Text(isActive ? "ACTIVE" : "EXPIRED")
                            .font(.system(.title, design: .rounded, weight: .bold))
                            .foregroundStyle(statusColor)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 6)
                            .background(statusColor.opacity(0.12))
                            .clipShape(Capsule())
                    }
                    .padding(.top, 16)

                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Client Name:")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(member.name)
                                .font(.title3.bold())
                        }

                        Divider()

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Valid until:")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(Self.dateFormatter.string(from: member.endsOnInclusive))
                                .font(.headline)
                                .foregroundStyle(statusColor)
                        }

                        Divider()

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Member ID:")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(member.id)
                                .font(.system(.caption, design: .monospaced))
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                case .notFound(let searchedId):
                    VStack(spacing: 12) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 64))
                            .foregroundStyle(.red)

                        Text("NOT FOUND")
                            .font(.system(.title, design: .rounded, weight: .bold))
                            .foregroundStyle(.red)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 6)
                            .background(Color.red.opacity(0.12))
                            .clipShape(Capsule())

                        VStack(spacing: 8) {
                            Text("No member found for ID:")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            Text(searchedId)
                                .font(.system(.subheadline, design: .monospaced, weight: .semibold))
                                .foregroundStyle(.primary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding(.top, 8)
                    }
                    .padding(.top, 16)
                }

                VStack(spacing: 12) {
                    Button {
                        checkResult = nil
                        manualIdInput = ""
                        imageErrorMessage = nil
                    } label: {
                        Text("Check Another Member")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    Button {
                        if let onDoneToRoot = onDoneToRoot {
                            onDoneToRoot()
                        } else {
                            dismiss()
                        }
                    } label: {
                        Text("To Main Screen")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.secondarySystemGroupedBackground))
                            .foregroundStyle(.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
                .padding(.top, 16)
            }
            .padding(20)
        }
    }

    // MARK: - Actions
    private func handleImageScanned(_ image: UIImage) {
        let result = QRCodeHelper.decodeQRCode(from: image)
        switch result {
        case .success(let code):
            imageErrorMessage = nil
            checkMember(byId: code)
        case .noQRCodeFound:
            imageErrorMessage = "No QR code found"
        case .couldNotReadImage:
            imageErrorMessage = "Could not read image"
        }
    }

    private func checkMember(byId id: String) {
        let trimmed = id.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if let member = repository.getMember(byId: trimmed) {
            let status = member.status()
            checkResult = .found(member, status)
        } else {
            checkResult = .notFound(trimmed)
        }
    }
}
