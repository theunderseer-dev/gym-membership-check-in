import Foundation

enum MembershipStatus: String, Codable, Hashable {
    case active = "Active"
    case expired = "Expired"
}

struct Member: Identifiable, Codable, Equatable, Hashable {
    let id: String
    var name: String
    let startsOn: Date
    let endsOnInclusive: Date
    let createdAt: Date
    var photoFileName: String?

    init(
        id: String = UUID().uuidString,
        name: String,
        startsOn: Date = Date(),
        endsOnInclusive: Date? = nil,
        createdAt: Date = Date(),
        photoFileName: String? = nil
    ) {
        self.id = id
        self.name = name
        self.startsOn = startsOn
        if let endsOn = endsOnInclusive {
            self.endsOnInclusive = endsOn
        } else {
            let calendar = Calendar.current
            self.endsOnInclusive = calendar.date(byAdding: .month, value: 1, to: startsOn) ?? startsOn
        }
        self.createdAt = createdAt
        self.photoFileName = photoFileName
    }

    func status(asOf date: Date = Date()) -> MembershipStatus {
        let calendar = Calendar.current
        let startOfDayToday = calendar.startOfDay(for: date)
        let startOfDayEndsOn = calendar.startOfDay(for: endsOnInclusive)

        // Active through endsOnInclusive inclusive
        if startOfDayToday <= startOfDayEndsOn {
            return .active
        } else {
            return .expired
        }
    }
}
