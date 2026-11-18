import Foundation
import UIKit

protocol GymRepositoryProtocol {
    func registerMember(name: String, today: Date, photo: UIImage?) throws -> Member
    func getMember(byId id: String) -> Member?
    func getAllMembers() -> [Member]
    func getPhoto(for member: Member) -> UIImage?
}

final class GymRepository: ObservableObject, GymRepositoryProtocol {
    static let shared = GymRepository()

    @Published private(set) var members: [Member] = []

    let fileURL: URL
    let photosDirectory: URL

    init(fileURL: URL? = nil, photosDirectory: URL? = nil) {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let gymDir = appSupport.appendingPathComponent("GymCheckIn", isDirectory: true)
        try? FileManager.default.createDirectory(at: gymDir, withIntermediateDirectories: true)

        if let fileURL = fileURL {
            self.fileURL = fileURL
        } else {
            self.fileURL = gymDir.appendingPathComponent("members.json")
        }

        if let photosDirectory = photosDirectory {
            self.photosDirectory = photosDirectory
        } else {
            self.photosDirectory = gymDir.appendingPathComponent("photos", isDirectory: true)
        }
        try? FileManager.default.createDirectory(at: self.photosDirectory, withIntermediateDirectories: true)

        loadMembers()
    }

    func loadMembers() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            members = try decoder.decode([Member].self, from: data)
        } catch {
            print("Failed to load members: \(error)")
        }
    }

    private func saveMembers() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(members)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("Failed to save members: \(error)")
        }
    }

    func registerMember(name: String, today: Date = Date(), photo: UIImage? = nil) throws -> Member {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            throw GymError.emptyName
        }

        let calendar = Calendar.current
        let endsOn = calendar.date(byAdding: .month, value: 1, to: today) ?? today
        let memberId = UUID().uuidString

        var photoFileName: String? = nil
        if let photo = photo {
            photoFileName = savePhoto(photo, memberId: memberId)
        }

        let member = Member(
            id: memberId,
            name: trimmedName,
            startsOn: today,
            endsOnInclusive: endsOn,
            createdAt: Date(),
            photoFileName: photoFileName
        )

        members.insert(member, at: 0)
        saveMembers()
        return member
    }

    func savePhoto(_ image: UIImage, memberId: String) -> String? {
        let fileName = "\(memberId).jpg"
        let photoURL = photosDirectory.appendingPathComponent(fileName)

        // Normalize image orientation and resize if larger than 800px to conserve disk space
        let normalized = image.fixedOrientation()
        let resized = normalized.resized(maxDimension: 800)

        guard let data = resized.jpegData(compressionQuality: 0.8) else { return nil }
        do {
            try data.write(to: photoURL, options: .atomic)
            return fileName
        } catch {
            print("Failed to save member photo: \(error)")
            return nil
        }
    }

    func getPhoto(for member: Member) -> UIImage? {
        guard let fileName = member.photoFileName else { return nil }
        return getPhoto(fileName: fileName)
    }

    func getPhoto(fileName: String) -> UIImage? {
        let photoURL = photosDirectory.appendingPathComponent(fileName)
        guard FileManager.default.fileExists(atPath: photoURL.path) else { return nil }
        return UIImage(contentsOfFile: photoURL.path)
    }

    func deletePhoto(for member: Member) {
        guard let fileName = member.photoFileName else { return }
        let photoURL = photosDirectory.appendingPathComponent(fileName)
        try? FileManager.default.removeItem(at: photoURL)
    }

    func getMember(byId id: String) -> Member? {
        let trimmed = id.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return members.first { $0.id.caseInsensitiveCompare(trimmed) == .orderedSame }
    }

    func getAllMembers() -> [Member] {
        return members
    }
}

enum GymError: LocalizedError {
    case emptyName

    var errorDescription: String? {
        switch self {
        case .emptyName:
            return "Client name cannot be empty"
        }
    }
}

// MARK: - UIImage Helpers
extension UIImage {
    func fixedOrientation() -> UIImage {
        if imageOrientation == .up { return self }
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(in: CGRect(origin: .zero, size: size))
        let normalized = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return normalized ?? self
    }

    func resized(maxDimension: CGFloat) -> UIImage {
        let currentMax = max(size.width, size.height)
        guard currentMax > maxDimension else { return self }

        let ratio = maxDimension / currentMax
        let targetSize = CGSize(width: size.width * ratio, height: size.height * ratio)

        UIGraphicsBeginImageContextWithOptions(targetSize, false, scale)
        draw(in: CGRect(origin: .zero, size: targetSize))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return scaledImage ?? self
    }
}
