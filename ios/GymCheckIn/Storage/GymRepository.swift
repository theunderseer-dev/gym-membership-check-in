import Foundation

protocol GymRepositoryProtocol {
    func registerMember(name: String, today: Date) throws -> Member
    func getMember(byId id: String) -> Member?
    func getAllMembers() -> [Member]
}

final class GymRepository: ObservableObject, GymRepositoryProtocol {
    static let shared = GymRepository()

    @Published private(set) var members: [Member] = []

    private let fileURL: URL

    init(fileURL: URL? = nil) {
        if let fileURL = fileURL {
            self.fileURL = fileURL
        } else {
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            let gymDir = appSupport.appendingPathComponent("GymCheckIn", isDirectory: true)
            try? FileManager.default.createDirectory(at: gymDir, withIntermediateDirectories: true)
            self.fileURL = gymDir.appendingPathComponent("members.json")
        }
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

    func registerMember(name: String, today: Date = Date()) throws -> Member {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            throw GymError.emptyName
        }

        let calendar = Calendar.current
        let endsOn = calendar.date(byAdding: .month, value: 1, to: today) ?? today

        let member = Member(
            id: UUID().uuidString,
            name: trimmedName,
            startsOn: today,
            endsOnInclusive: endsOn,
            createdAt: Date()
        )

        members.insert(member, at: 0)
        saveMembers()
        return member
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
