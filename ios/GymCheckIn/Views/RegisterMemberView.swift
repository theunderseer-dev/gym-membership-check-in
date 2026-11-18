import SwiftUI

struct RegisterMemberView: View {
    @ObservedObject var repository: GymRepository
    var onRegistered: ((Member) -> Void)? = nil

    @State private var name: String = ""
    @State private var errorMessage: String? = nil
    @State private var createdMember: Member? = nil
    @State private var navigateToSuccess: Bool = false
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
                    .onSubmit(register)

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

            Button(action: register) {
                Text("Register")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.top, 8)

            Spacer()
        }
        .padding(.horizontal, 20)
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Register Member")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $navigateToSuccess) {
            if let member = createdMember {
                RegistrationSuccessView(member: member)
            }
        }
    }

    private func register() {
        isNameFocused = false
        errorMessage = nil
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            errorMessage = "Client name cannot be empty"
            return
        }

        do {
            let member = try repository.registerMember(name: trimmed)
            name = ""
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
