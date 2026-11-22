import Foundation
import SharedDomain

enum MembershipStatus: String, Codable, Hashable {
    case active = "Active"
    case expired = "Expired"

    init(fromShared status: SharedDomain.MembershipStatus) {
        switch status {
        case .active:
            self = .active
        case .expired:
            self = .expired
        default:
            self = .expired
        }
    }
}

extension Date {
    func toSharedLocalDate() -> SharedDomain.LocalDate {
        let calendar = Calendar.current
        let year = Int32(calendar.component(.year, from: self))
        let month = Int32(calendar.component(.month, from: self))
        let day = Int32(calendar.component(.day, from: self))
        return SharedDomain.LocalDate(year: year, monthNumber: month, dayOfMonth: day)
    }
}

extension SharedDomain.LocalDate {
    func toDate() -> Date {
        let components = self.toNSDateComponents()
        return Calendar.current.date(from: components) ?? Date()
    }
}

struct Member: Identifiable, Codable, Equatable, Hashable {
    let id: String
    var name: String
    let startsOn: Date
    let endsOnInclusive: Date
    let createdAt: Date
    var photoFileName: String?

    init(
        id: String = MemberIdGeneratorKt.generateMemberId(),
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
            let startsOnShared = startsOn.toSharedLocalDate()
            let endsOnShared = DateUtilsKt.currentDatePlusMonths(date: startsOnShared, months: 1)
            self.endsOnInclusive = endsOnShared.toDate()
        }
        self.createdAt = createdAt
        self.photoFileName = photoFileName
    }

    func toSharedMember() -> SharedDomain.Member {
        SharedDomain.Member(
            id: id,
            name: name,
            startsOn: startsOn.toSharedLocalDate(),
            endsOnInclusive: endsOnInclusive.toSharedLocalDate(),
            photoFileName: photoFileName
        )
    }

    func status(asOf date: Date = Date()) -> MembershipStatus {
        let sharedMember = toSharedMember()
        let sharedStatus = sharedMember.status(today: date.toSharedLocalDate())
        return MembershipStatus(fromShared: sharedStatus)
    }
}
