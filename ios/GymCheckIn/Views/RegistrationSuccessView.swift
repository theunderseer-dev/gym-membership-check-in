import SwiftUI

struct RegistrationSuccessView: View {
    let member: Member
    var repository: GymRepository? = nil
    var onDoneToRoot: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @State private var qrImage: UIImage? = nil
    @State private var isShowingShareSheet = false
    @State private var copyFeedback = false

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(.green)

                    Text("Member Registered!")
                        .font(.title2.bold())
                }
                .padding(.top, 8)

                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 16) {
                        if let photo = (repository ?? GymRepository.shared).getPhoto(for: member) {
                            Image(uiImage: photo)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 64, height: 64)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.green.opacity(0.6), lineWidth: 2)
                                )
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Name:")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(member.name)
                                .font(.title3.bold())
                        }
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Valid until:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(Self.dateFormatter.string(from: member.endsOnInclusive))
                            .font(.headline)
                            .foregroundStyle(.green)
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Unique ID:")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        HStack {
                            Text(member.id)
                                .font(.system(.caption, design: .monospaced))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)

                            Spacer()

                            Button {
                                UIPasteboard.general.string = member.id
                                copyFeedback = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    copyFeedback = false
                                }
                            } label: {
                                Label(copyFeedback ? "Copied" : "Copy ID", systemImage: copyFeedback ? "checkmark" : "doc.on.doc")
                                    .font(.caption.bold())
                            }
                            .buttonStyle(.bordered)
                            .tint(copyFeedback ? .green : .blue)
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))

                VStack(spacing: 12) {
                    Text("Member Pass QR")
                        .font(.headline)

                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white)
                            .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)

                        if let qrImage = qrImage {
                            Image(uiImage: qrImage)
                                .interpolation(.none)
                                .resizable()
                                .scaledToFit()
                                .padding(16)
                        } else {
                            ProgressView()
                        }
                    }
                    .frame(width: 240, height: 240)
                }

                VStack(spacing: 12) {
                    Button {
                        isShowingShareSheet = true
                    } label: {
                        Label("Share QR", systemImage: "square.and.arrow.up")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(qrImage == nil)

                    Button {
                        if let onDoneToRoot = onDoneToRoot {
                            onDoneToRoot()
                        } else {
                            dismiss()
                        }
                    } label: {
                        Text("Done")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.secondarySystemGroupedBackground))
                            .foregroundStyle(.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
            }
            .padding(20)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Registration Complete")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if qrImage == nil {
                qrImage = QRCodeHelper.generateQRCode(from: member.id)
            }
        }
        .sheet(isPresented: $isShowingShareSheet) {
            if let qrImage = qrImage {
                ShareSheet(items: [
                    "Gym Pass: \(member.name)\nID: \(member.id)",
                    qrImage
                ])
            }
        }
    }
}
