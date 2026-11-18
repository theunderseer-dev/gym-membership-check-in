import SwiftUI

enum AppRoute: Hashable {
    case register
    case checkMembership
    case registrationSuccess(Member)
}

struct HomeView: View {
    @ObservedObject var repository: GymRepository
    @State private var navigationPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack(spacing: 24) {
                Spacer()

                VStack(spacing: 8) {
                    Image(systemName: "figure.run.circle.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(.tint)

                    Text("Gym Check-in")
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))

                    Text("Manage memberships and check entry status")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal)

                Spacer()

                VStack(spacing: 16) {
                    NavigationLink(value: AppRoute.register) {
                        HStack(spacing: 16) {
                            Image(systemName: "person.badge.plus")
                                .font(.title)
                                .frame(width: 44, height: 44)
                                .background(Color.blue.opacity(0.15))
                                .foregroundStyle(.blue)
                                .clipShape(Circle())

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Register member")
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                Text("Add a new client with a 1-month pass")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.leading)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)

                            Image(systemName: "chevron.right")
                                .font(.subheadline)
                                .foregroundStyle(.tertiary)
                        }
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
                    }
                    .buttonStyle(.plain)

                    NavigationLink(value: AppRoute.checkMembership) {
                        HStack(spacing: 16) {
                            Image(systemName: "qrcode.viewfinder")
                                .font(.title)
                                .frame(width: 44, height: 44)
                                .background(Color.green.opacity(0.15))
                                .foregroundStyle(.green)
                                .clipShape(Circle())

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Check membership")
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                Text("Camera QR, saved photo, or manual ID")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.leading)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)

                            Image(systemName: "chevron.right")
                                .font(.subheadline)
                                .foregroundStyle(.tertiary)
                        }
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)

                Spacer()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: AppRoute.self) { route in
                switch route {
                case .register:
                    RegisterMemberView(
                        repository: repository,
                        onRegistered: { member in
                            navigationPath.append(AppRoute.registrationSuccess(member))
                        }
                    )
                case .checkMembership:
                    CheckMembershipView(
                        repository: repository,
                        onDoneToRoot: {
                            navigationPath = NavigationPath()
                        }
                    )
                case .registrationSuccess(let member):
                    RegistrationSuccessView(
                        member: member,
                        repository: repository,
                        onDoneToRoot: {
                            navigationPath = NavigationPath()
                        }
                    )
                }
            }
        }
    }
}
