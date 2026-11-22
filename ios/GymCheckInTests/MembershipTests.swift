import XCTest
import SharedDomain
@testable import GymCheckIn

final class MembershipTests: XCTestCase {

    func testDateCalculation_standardDate() {
        // 2 February 2026 -> 2 March 2026
        var components = DateComponents()
        components.year = 2026
        components.month = 2
        components.day = 2
        let calendar = Calendar.current
        guard let startsOn = calendar.date(from: components) else {
            XCTFail("Failed to create date")
            return
        }

        let endsOn = calendar.date(byAdding: .month, value: 1, to: startsOn)
        let expectedComponents = DateComponents(year: 2026, month: 3, day: 2)
        let expectedDate = calendar.date(from: expectedComponents)

        XCTAssertEqual(endsOn, expectedDate)
    }

    func testDateCalculation_endOfMonth_nonLeapYear() {
        // 31 January 2026 -> 28 February 2026 (non-leap)
        var components = DateComponents()
        components.year = 2026
        components.month = 1
        components.day = 31
        let calendar = Calendar.current
        guard let startsOn = calendar.date(from: components) else {
            XCTFail("Failed to create date")
            return
        }

        let endsOn = calendar.date(byAdding: .month, value: 1, to: startsOn)
        let expectedComponents = DateComponents(year: 2026, month: 2, day: 28)
        let expectedDate = calendar.date(from: expectedComponents)

        XCTAssertEqual(endsOn, expectedDate)
    }

    func testDateCalculation_endOfMonth_leapYear() {
        // 31 January 2024 -> 29 February 2024 (leap year)
        var components = DateComponents()
        components.year = 2024
        components.month = 1
        components.day = 31
        let calendar = Calendar.current
        guard let startsOn = calendar.date(from: components) else {
            XCTFail("Failed to create date")
            return
        }

        let endsOn = calendar.date(byAdding: .month, value: 1, to: startsOn)
        let expectedComponents = DateComponents(year: 2024, month: 2, day: 29)
        let expectedDate = calendar.date(from: expectedComponents)

        XCTAssertEqual(endsOn, expectedDate)
    }

    func testMembershipStatus_inclusiveExpiration() {
        let calendar = Calendar.current
        var startComponents = DateComponents()
        startComponents.year = 2026
        startComponents.month = 2
        startComponents.day = 2
        let startsOn = calendar.date(from: startComponents)!

        var endComponents = DateComponents()
        endComponents.year = 2026
        endComponents.month = 3
        endComponents.day = 2
        let endsOn = calendar.date(from: endComponents)!

        let member = Member(
            id: "test-id",
            name: "Test Client",
            startsOn: startsOn,
            endsOnInclusive: endsOn
        )

        // Day before -> Active
        let dayBefore = calendar.date(byAdding: .day, value: -1, to: endsOn)!
        XCTAssertEqual(member.status(asOf: dayBefore), .active)

        // Exact day of expiration (inclusive) -> Active
        XCTAssertEqual(member.status(asOf: endsOn), .active)

        // Day after expiration -> Expired
        let dayAfter = calendar.date(byAdding: .day, value: 1, to: endsOn)!
        XCTAssertEqual(member.status(asOf: dayAfter), .expired)
    }

    func testNameTrimmingAndValidation() {
        let rawName = "   John Doe   "
        let trimmed = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        XCTAssertEqual(trimmed, "John Doe")

        let emptyName = "    "
        let trimmedEmpty = emptyName.trimmingCharacters(in: .whitespacesAndNewlines)
        XCTAssertTrue(trimmedEmpty.isEmpty)
    }

    func testQRCodeRoundTrip() {
        let testId = "K7X-9M2"
        guard let qrImage = QRCodeHelper.generateQRCode(from: testId) else {
            XCTFail("Failed to generate QR image")
            return
        }

        let decodeResult = QRCodeHelper.decodeQRCode(from: qrImage)
        XCTAssertEqual(decodeResult, .success(testId))
    }

    func testMemberPhotoPersistenceAndRetrieval() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let repo = GymRepository(
            fileURL: tempDir.appendingPathComponent("test_members.json"),
            photosDirectory: tempDir.appendingPathComponent("photos")
        )

        // Create a simple test image
        let size = CGSize(width: 100, height: 100)
        let renderer = UIGraphicsImageRenderer(size: size)
        let testImage = renderer.image { ctx in
            ctx.cgContext.setFillColor(UIColor.blue.cgColor)
            ctx.cgContext.fill(CGRect(origin: .zero, size: size))
        }

        // Register member with photo
        let member = try repo.registerMember(name: "Photo Member", photo: testImage)
        XCTAssertNotNil(member.photoFileName)

        // Retrieve photo
        let retrieved = repo.getPhoto(for: member)
        XCTAssertNotNil(retrieved)

        // Register member without photo
        let memberNoPhoto = try repo.registerMember(name: "No Photo Member", photo: nil)
        XCTAssertNil(memberNoPhoto.photoFileName)
        XCTAssertNil(repo.getPhoto(for: memberNoPhoto))
    }

    func testSharedDomain_validationAndCalculation() throws {
        let validName = try MemberValidation.shared.validateName(name: "  Sarah Connor  ")
        XCTAssertEqual(validName, "Sarah Connor")

        XCTAssertThrowsError(try MemberValidation.shared.validateName(name: "   "))

        let startLocalDate = SharedDomain.LocalDate(year: 2026, monthNumber: 1, dayOfMonth: 31)
        let plusMonth = DateUtilsKt.currentDatePlusMonths(date: startLocalDate, months: 1)
        XCTAssertEqual(plusMonth.year, 2026)
        XCTAssertEqual(plusMonth.monthNumber, 2)
        XCTAssertEqual(plusMonth.dayOfMonth, 28)

        let member = SharedDomain.Member(
            id: "shared-test-id",
            name: "Shared Member",
            startsOn: SharedDomain.LocalDate(year: 2026, monthNumber: 2, dayOfMonth: 2),
            endsOnInclusive: SharedDomain.LocalDate(year: 2026, monthNumber: 3, dayOfMonth: 2),
            photoFileName: nil
        )
        XCTAssertEqual(member.status(today: SharedDomain.LocalDate(year: 2026, monthNumber: 3, dayOfMonth: 2)), .active)
        XCTAssertEqual(member.status(today: SharedDomain.LocalDate(year: 2026, monthNumber: 3, dayOfMonth: 3)), .expired)
    }

    func testShortMemberId_generationAndNormalization() {
        let generated = MemberIdGeneratorKt.generateMemberId()
        XCTAssertEqual(generated.count, 7)
        XCTAssertEqual(generated[generated.index(generated.startIndex, offsetBy: 3)], "-")

        let normalized = MemberIdGeneratorKt.normalizeMemberId(input: "k7x9m2")
        XCTAssertEqual(normalized, "K7X-9M2")

        let normalizedWithSpaces = MemberIdGeneratorKt.normalizeMemberId(input: "  k7x 9m2  ")
        XCTAssertEqual(normalizedWithSpaces, "K7X-9M2")

        let normalizedTolerance = MemberIdGeneratorKt.normalizeMemberId(input: "kol-9im")
        XCTAssertEqual(normalizedTolerance, "K01-91M")
    }

    func testMembershipPlans_expirationDates() throws {
        let start = SharedDomain.LocalDate(year: 2026, monthNumber: 2, dayOfMonth: 15)
        XCTAssertEqual(SharedDomain.MembershipPlan.oneMonth.calculateEndDate(startDate: start), SharedDomain.LocalDate(year: 2026, monthNumber: 3, dayOfMonth: 15))
        XCTAssertEqual(SharedDomain.MembershipPlan.threeMonths.calculateEndDate(startDate: start), SharedDomain.LocalDate(year: 2026, monthNumber: 5, dayOfMonth: 15))
        XCTAssertEqual(SharedDomain.MembershipPlan.sixMonths.calculateEndDate(startDate: start), SharedDomain.LocalDate(year: 2026, monthNumber: 8, dayOfMonth: 15))
        XCTAssertEqual(SharedDomain.MembershipPlan.twelveMonths.calculateEndDate(startDate: start), SharedDomain.LocalDate(year: 2027, monthNumber: 2, dayOfMonth: 15))

        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let repo = GymRepository(
            fileURL: tempDir.appendingPathComponent("test_plans.json"),
            photosDirectory: tempDir.appendingPathComponent("photos")
        )

        let calendar = Calendar.current
        let startDate = calendar.date(from: DateComponents(year: 2026, month: 2, day: 15))!
        let sixMonthMember = try repo.registerMember(name: "Plan Member", plan: .sixMonths, today: startDate, photo: nil)
        let expectedEndDate = calendar.date(from: DateComponents(year: 2026, month: 8, day: 15))!
        XCTAssertEqual(calendar.startOfDay(for: sixMonthMember.endsOnInclusive), calendar.startOfDay(for: expectedEndDate))
    }
}
