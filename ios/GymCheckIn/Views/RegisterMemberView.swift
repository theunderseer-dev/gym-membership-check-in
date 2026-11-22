import SwiftUI

struct RegisterMemberView: View {
    let repository: GymRepository
    var onRegistered: ((Member) -> Void)? = nil

    @State private var name: String = ""
    @State private var isShowingCameraSheet: Bool = false
    @State private var errorMessage: String? = nil
    @FocusState private var isNameFocused: Bool

    var body: some View {
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

                HStack {
                    TextField("Enter client's full name", text: $name)
                        .textFieldStyle(.plain)
                        .frame(minHeight: 24)
                        .focused($isNameFocused)
                        .autocorrectionDisabled()
                        .submitLabel(.done)
                        .onSubmit(openCameraOrRegister)
                }
                .padding()
                .background(
                    Color(.secondarySystemGroupedBackground)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            isNameFocused = true
                        }
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            errorMessage != nil ? Color.red : (isNameFocused ? Color.blue : Color(.separator)),
                            lineWidth: isNameFocused ? 1.5 : 1
                        )
                        .allowsHitTesting(false)
                )

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

            // Registration Action Buttons
            VStack(spacing: 12) {
                Button(action: openCameraOrRegister) {
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
            .padding(.top, 8)

            Spacer()
        }
        .padding(.horizontal, 20)
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Register Member")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isShowingCameraSheet) {
            MemberPhotoCaptureView { confirmedImage in
                register(withPhoto: confirmedImage)
            }
        }
    }

    private func openCameraOrRegister() {
        isNameFocused = false
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            errorMessage = "Client name cannot be empty"
            isNameFocused = true
            return
        }
        errorMessage = nil
        isShowingCameraSheet = true
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
            onRegistered?(member)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
