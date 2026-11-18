import SwiftUI

struct RegisterMemberView: View {
    @ObservedObject var repository: GymRepository
    var onRegistered: ((Member) -> Void)? = nil

    @State private var name: String = ""
    @State private var capturedPhoto: UIImage? = nil
    @State private var isShowingCameraSheet: Bool = false
    @State private var errorMessage: String? = nil
    @State private var createdMember: Member? = nil
    @State private var navigateToSuccess: Bool = false
    @FocusState private var isNameFocused: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("New Member Registration")
                        .font(.title2.bold())

                    Text("Fixed tariff: 1 calendar month starting today")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 12)

                // Client Name Field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Client Name")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)

                    TextField("Enter client's full name", text: $name)
                        .textFieldStyle(.plain)
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(errorMessage != nil ? Color.red : Color(.separator), lineWidth: 1)
                        )
                        .focused($isNameFocused)
                        .autocorrectionDisabled()
                        .submitLabel(.done)

                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    } else {
                        Text("Whitespace at start and end will be trimmed")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                // Member Photo Card
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Member Identity Photo")
                                .font(.headline)
                            Text("Displayed during QR check-in to prevent pass sharing")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }

                    if let photo = capturedPhoto {
                        HStack(spacing: 16) {
                            Image(uiImage: photo)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 84, height: 84)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color.green, lineWidth: 2)
                                )

                            VStack(alignment: .leading, spacing: 8) {
                                Label("Photo Attached", systemImage: "checkmark.circle.fill")
                                    .font(.subheadline.bold())
                                    .foregroundStyle(.green)

                                HStack(spacing: 12) {
                                    Button {
                                        isShowingCameraSheet = true
                                    } label: {
                                        Text("Retake")
                                            .font(.caption.bold())
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(Color.blue.opacity(0.12))
                                            .foregroundStyle(.blue)
                                            .clipShape(Capsule())
                                    }

                                    Button {
                                        capturedPhoto = nil
                                    } label: {
                                        Text("Remove")
                                            .font(.caption)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(Color.red.opacity(0.1))
                                            .foregroundStyle(.red)
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                            Spacer()
                        }
                    } else {
                        Button {
                            isNameFocused = false
                            let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                            if trimmed.isEmpty {
                                errorMessage = "Enter client name before taking photo"
                                isNameFocused = true
                            } else {
                                errorMessage = nil
                                isShowingCameraSheet = true
                            }
                        } label: {
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(Color.blue.opacity(0.12))
                                        .frame(width: 52, height: 52)
                                    Image(systemName: "camera.fill")
                                        .font(.title3)
                                        .foregroundStyle(.blue)
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Take Member Photo")
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    Text("Open camera to snap client photo")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.subheadline)
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(14)
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
                .background(Color(.secondarySystemGroupedBackground).opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: 16))

                // Registration Action Buttons
                VStack(spacing: 12) {
                    if capturedPhoto != nil {
                        Button(action: { register(withPhoto: capturedPhoto) }) {
                            Label("Complete Registration & Get QR", systemImage: "qrcode")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    } else {
                        Button {
                            isNameFocused = false
                            let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !trimmed.isEmpty else {
                                errorMessage = "Client name cannot be empty"
                                isNameFocused = true
                                return
                            }
                            errorMessage = nil
                            isShowingCameraSheet = true
                        } label: {
                            Label("Take Photo & Register", systemImage: "camera.fill")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }

                        Button {
                            register(withPhoto: nil)
                        } label: {
                            Text("Register without Photo")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .padding(.vertical, 8)
                        }
                    }
                }
                .padding(.top, 8)

                Spacer()
            }
            .padding(.horizontal, 20)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Register Member")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isShowingCameraSheet) {
            MemberPhotoCaptureView { confirmedImage in
                self.capturedPhoto = confirmedImage
                let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    register(withPhoto: confirmedImage)
                }
            }
        }
        .navigationDestination(isPresented: $navigateToSuccess) {
            if let member = createdMember {
                RegistrationSuccessView(member: member, repository: repository)
            }
        }
    }

    private func register(withPhoto photo: UIImage?) {
        isNameFocused = false
        errorMessage = nil
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            errorMessage = "Client name cannot be empty"
            isNameFocused = true
            return
        }

        do {
            let member = try repository.registerMember(name: trimmed, photo: photo)
            name = ""
            capturedPhoto = nil
            if let onRegistered = onRegistered {
                onRegistered(member)
            } else {
                createdMember = member
                navigateToSuccess = true
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
