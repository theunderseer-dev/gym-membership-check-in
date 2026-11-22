import SwiftUI
import SharedDomain

struct RegisterMemberView: View {
    @ObservedObject var repository: GymRepository
    var onRegistered: ((Member) -> Void)? = nil

    @State private var name: String = ""
    @State private var selectedPlan: SharedDomain.MembershipPlan = .oneMonth
    @State private var isShowingCameraSheet: Bool = false
    @State private var errorMessage: String? = nil
    @State private var createdMember: Member? = nil
    @State private var navigateToSuccess: Bool = false
    @FocusState private var isNameFocused: Bool

    private static let availablePlans: [SharedDomain.MembershipPlan] = [
        .oneMonth,
        .threeMonths,
        .sixMonths,
        .twelveMonths
    ]

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    private static let gridColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    private var previewExpirationDate: Date {
        selectedPlan.calculateEndDate(startDate: Date().toSharedLocalDate()).toDate()
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("New Member Registration")
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, alignment: .center)
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
                        .onSubmit(openCameraOrRegister)

                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }

                // Membership Plan Selection (2x2 Single-Select Cards)
                VStack(alignment: .leading, spacing: 10) {
                    Text("Membership Plan")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)

                    LazyVGrid(columns: Self.gridColumns, spacing: 12) {
                        ForEach(Self.availablePlans, id: \.months) { plan in
                            let isSelected = plan == selectedPlan
                            Button {
                                selectedPlan = plan
                            } label: {
                                HStack {
                                    Text(plan.displayName)
                                        .font(.subheadline.weight(isSelected ? .bold : .medium))
                                        .foregroundStyle(isSelected ? .blue : .primary)

                                    Spacer()

                                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(isSelected ? .blue : .secondary.opacity(0.5))
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 14)
                                .frame(maxWidth: .infinity)
                                .background(
                                    isSelected
                                        ? Color.blue.opacity(0.1)
                                        : Color(.secondarySystemGroupedBackground)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(
                                            isSelected ? Color.blue : Color(.separator),
                                            lineWidth: isSelected ? 2 : 1
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                            .accessibilityAddTraits(isSelected ? .isSelected : [])
                        }
                    }

                    // Expiration Date Preview
                    HStack {
                        Label("Expiration date", systemImage: "calendar")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Spacer()

                        Text(Self.dateFormatter.string(from: previewExpirationDate))
                            .font(.subheadline.bold())
                            .foregroundStyle(.blue)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.top, 4)
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
                .padding(.top, 4)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Register Member")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isShowingCameraSheet) {
            MemberPhotoCaptureView { confirmedImage in
                register(withPhoto: confirmedImage)
            }
        }
        .navigationDestination(isPresented: $navigateToSuccess) {
            if let member = createdMember {
                RegistrationSuccessView(member: member, repository: repository)
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
            let member = try repository.registerMember(name: trimmed, plan: selectedPlan, photo: photo)
            name = ""
            selectedPlan = .oneMonth
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
